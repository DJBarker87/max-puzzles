import { supabase } from './supabase'
import * as localDB from './indexedDB'
import type { ModuleProgressInsert, UserUpdate } from './database.types'

// ============================================
// Types for Circuit Challenge Progress
// ============================================

interface DifficultyStats {
  played: number
  won: number
  bestTimeMs: number | null
}

interface QuickPlayProgress {
  gamesPlayed: number
  gamesWon: number
  totalCoinsEarned: number
  bestStreak: number
  currentStreak: number
  lastPlayedAt: string | null
  difficultyStats: Record<number, DifficultyStats>
}

interface ProgressionProgress {
  // V2 - placeholder
  completedLevels: string[]
  starsByLevel: Record<string, number>
}

export interface CircuitChallengeProgress {
  quickPlay: QuickPlayProgress
  progression: ProgressionProgress
}

const DEFAULT_CC_PROGRESS: CircuitChallengeProgress = {
  quickPlay: {
    gamesPlayed: 0,
    gamesWon: 0,
    totalCoinsEarned: 0,
    bestStreak: 0,
    currentStreak: 0,
    lastPlayedAt: null,
    difficultyStats: {},
  },
  progression: {
    completedLevels: [],
    starsByLevel: {},
  },
}

// ============================================
// Get Progress
// ============================================

export async function getProgress(
  userId: string | null,
  moduleId: string,
  isGuest: boolean
): Promise<Record<string, unknown>> {
  if (isGuest || !userId) {
    // Load from IndexedDB
    const local = await localDB.getModuleProgress(moduleId)
    return local?.data || getDefaultProgress(moduleId)
  }

  // Load from Supabase
  if (!supabase) {
    const local = await localDB.getModuleProgress(moduleId)
    return local?.data || getDefaultProgress(moduleId)
  }

  const { data, error } = await supabase
    .from('module_progress')
    .select('data')
    .eq('user_id', userId)
    .eq('module_id', moduleId)
    .single()

  if (error || !data) {
    return getDefaultProgress(moduleId)
  }

  return data.data as Record<string, unknown>
}

function getDefaultProgress(moduleId: string): Record<string, unknown> {
  switch (moduleId) {
    case 'circuit-challenge':
      return { ...DEFAULT_CC_PROGRESS } as unknown as Record<string, unknown>
    default:
      return {}
  }
}

// ============================================
// Save Progress
// ============================================

export async function saveProgress(
  userId: string | null,
  moduleId: string,
  data: Record<string, unknown>,
  isGuest: boolean
): Promise<boolean> {
  // Always save locally first
  await localDB.setModuleProgress(moduleId, data)

  if (isGuest || !userId || !supabase) {
    // Queue for sync when user creates account
    if (isGuest) {
      await localDB.addToSyncQueue('progress', { moduleId, data })
    }
    return true
  }

  // Save to Supabase (upsert)
  const insertData: ModuleProgressInsert = {
    user_id: userId,
    module_id: moduleId,
    data,
  }

  const { error } = await supabase.from('module_progress').upsert(insertData, {
    onConflict: 'user_id,module_id',
  })

  return !error
}

// ============================================
// Update Quick Play Stats
// ============================================

export async function recordQuickPlayResult(
  userId: string | null,
  isGuest: boolean,
  result: {
    won: boolean
    difficultyLevel: number
    timeMs: number
    coinsEarned: number
  }
): Promise<void> {
  const rawProgress = await getProgress(userId, 'circuit-challenge', isGuest)
  const progress = rawProgress as unknown as CircuitChallengeProgress

  // Ensure structure exists
  if (!progress.quickPlay) {
    progress.quickPlay = { ...DEFAULT_CC_PROGRESS.quickPlay }
  }

  const qp = progress.quickPlay

  // Update general stats
  qp.gamesPlayed++
  if (result.won) {
    qp.gamesWon++
    qp.currentStreak++
    qp.bestStreak = Math.max(qp.bestStreak, qp.currentStreak)
  } else {
    qp.currentStreak = 0
  }
  qp.totalCoinsEarned += result.coinsEarned
  qp.lastPlayedAt = new Date().toISOString()

  // Update difficulty-specific stats
  if (!qp.difficultyStats) {
    qp.difficultyStats = {}
  }
  const diffStats = qp.difficultyStats[result.difficultyLevel] || {
    played: 0,
    won: 0,
    bestTimeMs: null,
  }
  diffStats.played++
  if (result.won) {
    diffStats.won++
    if (diffStats.bestTimeMs === null || result.timeMs < diffStats.bestTimeMs) {
      diffStats.bestTimeMs = result.timeMs
    }
  }
  qp.difficultyStats[result.difficultyLevel] = diffStats

  // Save updated progress
  await saveProgress(
    userId,
    'circuit-challenge',
    progress as unknown as Record<string, unknown>,
    isGuest
  )
}

// ============================================
// Coins Management
// ============================================

export async function addCoins(
  userId: string | null,
  amount: number,
  isGuest: boolean
): Promise<number> {
  if (isGuest) {
    const profile = await localDB.updateGuestCoins(amount)
    return profile?.coins || 0
  }

  if (!supabase || !userId) return 0

  // Try to use RPC for atomic update, fallback to regular update
  try {
    const { data, error } = await supabase.rpc('add_coins', {
      p_user_id: userId,
      p_amount: amount,
    })

    if (!error && data !== null) {
      return data as number
    }
  } catch {
    // RPC not available, use regular update
  }

  // Fallback: read-modify-write (not atomic, but works without RPC)
  const { data: userData } = await supabase
    .from('users')
    .select('coins')
    .eq('id', userId)
    .single()

  if (!userData) return 0

  const newCoins = Math.max(0, userData.coins + amount)
  const updateData: UserUpdate = { coins: newCoins }
  await supabase.from('users').update(updateData).eq('id', userId)

  return newCoins
}

export async function getCoins(userId: string | null, isGuest: boolean): Promise<number> {
  if (isGuest) {
    const profile = await localDB.getGuestProfile()
    return profile?.coins || 0
  }

  if (!supabase || !userId) return 0

  const { data } = await supabase.from('users').select('coins').eq('id', userId).single()

  return data?.coins || 0
}

// ============================================
// Progress Summary
// ============================================

export async function getProgressSummary(
  userId: string | null,
  moduleId: string,
  isGuest: boolean
): Promise<{
  gamesPlayed: number
  gamesWon: number
  winRate: number
  totalCoins: number
  bestStreak: number
}> {
  const rawProgress = await getProgress(userId, moduleId, isGuest)
  const progress = rawProgress as unknown as CircuitChallengeProgress

  const qp = progress.quickPlay || DEFAULT_CC_PROGRESS.quickPlay
  const winRate = qp.gamesPlayed > 0 ? Math.round((qp.gamesWon / qp.gamesPlayed) * 100) : 0

  return {
    gamesPlayed: qp.gamesPlayed,
    gamesWon: qp.gamesWon,
    winRate,
    totalCoins: qp.totalCoinsEarned,
    bestStreak: qp.bestStreak,
  }
}
