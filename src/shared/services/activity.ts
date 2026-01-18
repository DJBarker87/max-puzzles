import { supabase } from './supabase'
import * as localDB from './indexedDB'
import type { ActivityLogInsert, ActivityLogUpdate, ActivityLogRow } from './database.types'

// ============================================
// Types
// ============================================

export interface ActivitySession {
  id: string
  moduleId: string
  sessionStart: string
  sessionEnd: string | null
  durationSeconds: number
  gamesPlayed: number
  correctAnswers: number
  mistakes: number
  coinsEarned: number
}

interface CurrentSession {
  id: string
  moduleId: string
  startTime: number
  gamesPlayed: number
  correctAnswers: number
  mistakes: number
  coinsEarned: number
}

let currentSession: CurrentSession | null = null

// ============================================
// Helper Functions
// ============================================

function mapRowToSession(row: ActivityLogRow): ActivitySession {
  return {
    id: row.id,
    moduleId: row.module_id,
    sessionStart: row.session_start,
    sessionEnd: row.session_end,
    durationSeconds: row.duration_seconds,
    gamesPlayed: row.games_played,
    correctAnswers: row.correct_answers,
    mistakes: row.mistakes,
    coinsEarned: row.coins_earned,
  }
}

// ============================================
// Session Management
// ============================================

export async function startSession(
  userId: string | null,
  moduleId: string,
  isGuest: boolean
): Promise<string> {
  const sessionStart = new Date().toISOString()

  // End any existing session first
  if (currentSession) {
    await endSession(userId, isGuest)
  }

  const sessionData = {
    moduleId,
    sessionStart,
    sessionEnd: null,
    durationSeconds: 0,
    gamesPlayed: 0,
    correctAnswers: 0,
    mistakes: 0,
    coinsEarned: 0,
  }

  let sessionId: string

  if (isGuest || !userId || !supabase) {
    // Store locally
    sessionId = await localDB.logActivity(sessionData)
  } else {
    // Store in Supabase
    const insertData: ActivityLogInsert = {
      user_id: userId,
      module_id: moduleId,
      session_start: sessionStart,
      session_end: null,
      duration_seconds: 0,
      games_played: 0,
      correct_answers: 0,
      mistakes: 0,
      coins_earned: 0,
    }

    const { data, error } = await supabase
      .from('activity_log')
      .insert(insertData)
      .select('id')
      .single()

    if (error || !data) {
      // Fallback to local
      sessionId = await localDB.logActivity(sessionData)
    } else {
      sessionId = data.id
    }
  }

  // Track in memory
  currentSession = {
    id: sessionId,
    moduleId,
    startTime: Date.now(),
    gamesPlayed: 0,
    correctAnswers: 0,
    mistakes: 0,
    coinsEarned: 0,
  }

  return sessionId
}

export async function endSession(userId: string | null, isGuest: boolean): Promise<void> {
  if (!currentSession) return

  const durationSeconds = Math.floor((Date.now() - currentSession.startTime) / 1000)
  const sessionEnd = new Date().toISOString()

  if (isGuest || !userId || !supabase) {
    await localDB.updateActivity(currentSession.id, {
      sessionEnd,
      durationSeconds,
      gamesPlayed: currentSession.gamesPlayed,
      correctAnswers: currentSession.correctAnswers,
      mistakes: currentSession.mistakes,
      coinsEarned: currentSession.coinsEarned,
    })
  } else {
    const updateData: ActivityLogUpdate = {
      session_end: sessionEnd,
      duration_seconds: durationSeconds,
      games_played: currentSession.gamesPlayed,
      correct_answers: currentSession.correctAnswers,
      mistakes: currentSession.mistakes,
      coins_earned: currentSession.coinsEarned,
    }

    await supabase.from('activity_log').update(updateData).eq('id', currentSession.id)
  }

  currentSession = null
}

export function recordGameInSession(result: {
  correct: number
  mistakes: number
  coinsEarned: number
}): void {
  if (!currentSession) return

  currentSession.gamesPlayed++
  currentSession.correctAnswers += result.correct
  currentSession.mistakes += result.mistakes
  currentSession.coinsEarned += result.coinsEarned
}

export function getCurrentSession(): CurrentSession | null {
  return currentSession
}

// ============================================
// Activity Queries
// ============================================

export async function getRecentActivity(
  userId: string | null,
  isGuest: boolean,
  limit: number = 20
): Promise<ActivitySession[]> {
  if (isGuest || !userId || !supabase) {
    const local = await localDB.getRecentActivity(limit)
    return local.map((a) => ({
      id: a.id,
      moduleId: a.moduleId,
      sessionStart: a.sessionStart,
      sessionEnd: a.sessionEnd,
      durationSeconds: a.durationSeconds,
      gamesPlayed: a.gamesPlayed,
      correctAnswers: a.correctAnswers,
      mistakes: a.mistakes,
      coinsEarned: a.coinsEarned,
    }))
  }

  const { data, error } = await supabase
    .from('activity_log')
    .select('*')
    .eq('user_id', userId)
    .order('session_start', { ascending: false })
    .limit(limit)

  if (error || !data) return []

  return data.map(mapRowToSession)
}

export async function getActivityForChild(
  childId: string,
  limit: number = 50
): Promise<ActivitySession[]> {
  if (!supabase) return []

  const { data, error } = await supabase
    .from('activity_log')
    .select('*')
    .eq('user_id', childId)
    .order('session_start', { ascending: false })
    .limit(limit)

  if (error || !data) return []

  return data.map(mapRowToSession)
}

export async function getActivitySummary(
  userId: string | null,
  isGuest: boolean,
  days: number = 7
): Promise<{
  totalGames: number
  totalTime: number
  totalCoins: number
  accuracy: number
}> {
  const cutoff = new Date()
  cutoff.setDate(cutoff.getDate() - days)

  const activities = await getRecentActivity(userId, isGuest, 100)
  const recent = activities.filter((a) => new Date(a.sessionStart) >= cutoff)

  const totals = recent.reduce(
    (acc, a) => ({
      games: acc.games + a.gamesPlayed,
      time: acc.time + a.durationSeconds,
      coins: acc.coins + a.coinsEarned,
      correct: acc.correct + a.correctAnswers,
      total: acc.total + a.correctAnswers + a.mistakes,
    }),
    { games: 0, time: 0, coins: 0, correct: 0, total: 0 }
  )

  return {
    totalGames: totals.games,
    totalTime: totals.time,
    totalCoins: totals.coins,
    accuracy: totals.total > 0 ? Math.round((totals.correct / totals.total) * 100) : 0,
  }
}

// ============================================
// Inactivity Detection
// ============================================

let inactivityTimer: ReturnType<typeof setTimeout> | null = null
const INACTIVITY_TIMEOUT = 5 * 60 * 1000 // 5 minutes

export function resetInactivityTimer(userId: string | null, isGuest: boolean): void {
  if (inactivityTimer) {
    clearTimeout(inactivityTimer)
  }

  inactivityTimer = setTimeout(() => {
    endSession(userId, isGuest)
  }, INACTIVITY_TIMEOUT)
}

export function clearInactivityTimer(): void {
  if (inactivityTimer) {
    clearTimeout(inactivityTimer)
    inactivityTimer = null
  }
}
