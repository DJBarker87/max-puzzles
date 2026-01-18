import { supabase } from './supabase'
import * as localDB from './indexedDB'
import type { UserUpdate, ModuleProgressInsert } from './database.types'

// ============================================
// Types
// ============================================

export interface SyncResult {
  success: boolean
  merged: {
    progress: boolean
    activity: boolean
    coins: boolean
  }
  errors: string[]
}

// ============================================
// Main Sync Function
// ============================================

export async function syncGuestDataToAccount(userId: string): Promise<SyncResult> {
  const result: SyncResult = {
    success: true,
    merged: { progress: false, activity: false, coins: false },
    errors: [],
  }

  if (!supabase) {
    result.success = false
    result.errors.push('Supabase not configured')
    return result
  }

  try {
    // 1. Sync coins (use higher value)
    const guestProfile = await localDB.getGuestProfile()
    if (guestProfile && guestProfile.coins > 0) {
      const merged = await mergeCoins(userId, guestProfile.coins)
      result.merged.coins = merged
    }

    // 2. Sync module progress
    const localProgress = await localDB.getAllModuleProgress()
    for (const progress of localProgress) {
      const merged = await mergeModuleProgress(userId, progress.moduleId, progress.data)
      if (merged) result.merged.progress = true
    }

    // 3. Process sync queue
    const queue = await localDB.getSyncQueue()
    for (const item of queue) {
      try {
        await processSyncItem(userId, item)
        await localDB.removeSyncItem(item.id)
      } catch (err) {
        result.errors.push(`Failed to sync ${item.type}: ${err}`)
      }
    }

    // 4. Clear local guest data after successful sync
    if (result.errors.length === 0) {
      await localDB.clearAllData()
    }
  } catch (err) {
    result.success = false
    result.errors.push(`Sync failed: ${err}`)
  }

  return result
}

// ============================================
// Merge Strategies
// ============================================

async function mergeCoins(userId: string, localCoins: number): Promise<boolean> {
  if (!supabase) return false

  // Get current cloud coins
  const { data: userData } = await supabase
    .from('users')
    .select('coins')
    .eq('id', userId)
    .single()

  const cloudCoins = userData?.coins || 0

  // Use higher value (best outcome for player)
  if (localCoins > cloudCoins) {
    const updateData: UserUpdate = { coins: localCoins }
    const { error } = await supabase.from('users').update(updateData).eq('id', userId)

    return !error
  }

  return true // No update needed, cloud has more
}

async function mergeModuleProgress(
  userId: string,
  moduleId: string,
  localData: Record<string, unknown>
): Promise<boolean> {
  if (!supabase) return false

  // Get current cloud progress
  const { data: cloudProgress } = await supabase
    .from('module_progress')
    .select('data')
    .eq('user_id', userId)
    .eq('module_id', moduleId)
    .single()

  const cloudData = (cloudProgress?.data || {}) as Record<string, unknown>

  // Merge based on module-specific rules
  const mergedData = mergeProgressData(moduleId, localData, cloudData)

  // Save merged data
  const insertData: ModuleProgressInsert = {
    user_id: userId,
    module_id: moduleId,
    data: mergedData,
  }

  const { error } = await supabase.from('module_progress').upsert(insertData, {
    onConflict: 'user_id,module_id',
  })

  return !error
}

function mergeProgressData(
  moduleId: string,
  local: Record<string, unknown>,
  cloud: Record<string, unknown>
): Record<string, unknown> {
  // Circuit Challenge specific merge
  if (moduleId === 'circuit-challenge') {
    return mergeCircuitChallengeProgress(local, cloud)
  }

  // Default: last-write-wins with local taking precedence for ties
  return { ...cloud, ...local }
}

/* eslint-disable @typescript-eslint/no-explicit-any */
function mergeCircuitChallengeProgress(
  local: Record<string, unknown>,
  cloud: Record<string, unknown>
): Record<string, unknown> {
  const localQP = (local as any).quickPlay || {}
  const cloudQP = (cloud as any).quickPlay || {}

  return {
    quickPlay: {
      // Higher wins
      gamesPlayed: Math.max(localQP.gamesPlayed || 0, cloudQP.gamesPlayed || 0),
      gamesWon: Math.max(localQP.gamesWon || 0, cloudQP.gamesWon || 0),
      totalCoinsEarned: Math.max(
        localQP.totalCoinsEarned || 0,
        cloudQP.totalCoinsEarned || 0
      ),
      bestStreak: Math.max(localQP.bestStreak || 0, cloudQP.bestStreak || 0),
      currentStreak: Math.max(localQP.currentStreak || 0, cloudQP.currentStreak || 0),

      // Most recent wins
      lastPlayedAt: getMoreRecent(localQP.lastPlayedAt, cloudQP.lastPlayedAt),

      // Merge difficulty stats (best times win)
      difficultyStats: mergeDifficultyStats(
        localQP.difficultyStats || {},
        cloudQP.difficultyStats || {}
      ),
    },
    progression: {
      // Union of completed levels
      completedLevels: [
        ...new Set([
          ...((local as any).progression?.completedLevels || []),
          ...((cloud as any).progression?.completedLevels || []),
        ]),
      ],
      // Higher stars win
      starsByLevel: mergeStarsByLevel(
        (local as any).progression?.starsByLevel || {},
        (cloud as any).progression?.starsByLevel || {}
      ),
    },
  }
}
/* eslint-enable @typescript-eslint/no-explicit-any */

function getMoreRecent(a: string | null, b: string | null): string | null {
  if (!a) return b
  if (!b) return a
  return new Date(a) > new Date(b) ? a : b
}

function mergeDifficultyStats(
  local: Record<number, { played: number; won: number; bestTimeMs: number | null }>,
  cloud: Record<number, { played: number; won: number; bestTimeMs: number | null }>
): Record<number, { played: number; won: number; bestTimeMs: number | null }> {
  const merged: Record<number, { played: number; won: number; bestTimeMs: number | null }> =
    { ...cloud }

  for (const [level, stats] of Object.entries(local)) {
    const cloudStats = merged[Number(level)] || { played: 0, won: 0, bestTimeMs: null }
    merged[Number(level)] = {
      played: Math.max(stats.played || 0, cloudStats.played || 0),
      won: Math.max(stats.won || 0, cloudStats.won || 0),
      bestTimeMs: getBetterTime(stats.bestTimeMs, cloudStats.bestTimeMs),
    }
  }

  return merged
}

function getBetterTime(a: number | null, b: number | null): number | null {
  if (a === null) return b
  if (b === null) return a
  return Math.min(a, b) // Lower is better
}

function mergeStarsByLevel(
  local: Record<string, number>,
  cloud: Record<string, number>
): Record<string, number> {
  const merged: Record<string, number> = { ...cloud }

  for (const [level, stars] of Object.entries(local)) {
    merged[level] = Math.max(stars, merged[level] || 0)
  }

  return merged
}

async function processSyncItem(
  userId: string,
  item: { type: string; data: unknown }
): Promise<void> {
  // Process based on type
  switch (item.type) {
    case 'progress': {
      const { moduleId, data } = item.data as { moduleId: string; data: Record<string, unknown> }
      await mergeModuleProgress(userId, moduleId, data)
      break
    }
    case 'activity':
      // Activity logs don't need merging, could upload if needed
      break
    case 'profile':
      // Profile data (like name) - last-write-wins
      break
  }
}

// ============================================
// Check Sync Status
// ============================================

export async function hasPendingSyncData(): Promise<boolean> {
  const queue = await localDB.getSyncQueue()
  const progress = await localDB.getAllModuleProgress()
  const profile = await localDB.getGuestProfile()

  return queue.length > 0 || progress.length > 0 || (profile?.coins ?? 0) > 0
}
