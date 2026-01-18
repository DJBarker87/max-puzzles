import { createContext, useContext, useEffect, useState, useCallback, ReactNode } from 'react'
import { useAuth } from './AuthProvider'
import * as progressService from '@/shared/services/progress'
import * as activityService from '@/shared/services/activity'
import { getDB } from '@/shared/services/indexedDB'

interface StorageContextValue {
  /** Whether storage is initialized */
  isReady: boolean

  // Progress
  /** Get progress data for a module */
  getProgress: (moduleId: string) => Promise<Record<string, unknown>>
  /** Save progress data for a module */
  saveProgress: (moduleId: string, data: Record<string, unknown>) => Promise<boolean>

  // Activity
  /** Start a new activity session */
  startSession: (moduleId: string) => Promise<string>
  /** End the current activity session */
  endSession: () => Promise<void>
  /** Record game results in the current session */
  recordGame: (result: { correct: number; mistakes: number; coinsEarned: number }) => void

  // Quick helpers
  /** Record a Quick Play result */
  recordQuickPlayResult: (result: {
    won: boolean
    difficultyLevel: number
    timeMs: number
    coinsEarned: number
  }) => Promise<void>

  /** Add coins to the user's balance */
  addCoins: (amount: number) => Promise<number>

  /** Get current coin balance */
  getCoins: () => Promise<number>

  // Activity queries
  /** Get recent activity sessions */
  getRecentActivity: (limit?: number) => Promise<activityService.ActivitySession[]>
  /** Get activity summary */
  getActivitySummary: (days?: number) => Promise<{
    totalGames: number
    totalTime: number
    totalCoins: number
    accuracy: number
  }>

  // Progress summary
  /** Get progress summary for a module */
  getProgressSummary: (moduleId: string) => Promise<{
    gamesPlayed: number
    gamesWon: number
    winRate: number
    totalCoins: number
    bestStreak: number
  }>
}

const StorageContext = createContext<StorageContextValue | null>(null)

interface StorageProviderProps {
  children: ReactNode
}

/**
 * Storage provider
 * Manages data persistence with IndexedDB and Supabase
 */
export function StorageProvider({ children }: StorageProviderProps) {
  const [isReady, setIsReady] = useState(false)

  // We can't use useAuth here directly since AuthProvider is nested inside StorageProvider
  // So we'll create a wrapper that accesses auth state lazily

  // Initialize database on mount
  useEffect(() => {
    getDB()
      .then(() => {
        setIsReady(true)
      })
      .catch((err) => {
        console.error('Failed to initialize storage:', err)
        // Still mark as ready to allow app to function
        setIsReady(true)
      })
  }, [])

  const value: StorageContextValue = {
    isReady,
    getProgress: async () => ({}),
    saveProgress: async () => true,
    startSession: async () => '',
    endSession: async () => {},
    recordGame: () => {},
    recordQuickPlayResult: async () => {},
    addCoins: async () => 0,
    getCoins: async () => 0,
    getRecentActivity: async () => [],
    getActivitySummary: async () => ({
      totalGames: 0,
      totalTime: 0,
      totalCoins: 0,
      accuracy: 0,
    }),
    getProgressSummary: async () => ({
      gamesPlayed: 0,
      gamesWon: 0,
      winRate: 0,
      totalCoins: 0,
      bestStreak: 0,
    }),
  }

  return <StorageContext.Provider value={value}>{children}</StorageContext.Provider>
}

/**
 * Hook to access storage methods with auth context
 * This hook provides the full storage functionality with auth awareness
 */
export function useStorage(): StorageContextValue {
  const baseContext = useContext(StorageContext)
  const { user, isGuest, isDemoMode } = useAuth()

  if (!baseContext) {
    throw new Error('useStorage must be used within a StorageProvider')
  }

  const userId = user?.id || null

  // ============================================
  // Progress
  // ============================================

  const getProgress = useCallback(
    async (moduleId: string) => {
      if (isDemoMode) {
        // Demo mode: return empty progress
        return {}
      }
      return progressService.getProgress(userId, moduleId, isGuest)
    },
    [userId, isGuest, isDemoMode]
  )

  const saveProgress = useCallback(
    async (moduleId: string, data: Record<string, unknown>) => {
      if (isDemoMode) {
        // Demo mode: don't save
        return true
      }
      return progressService.saveProgress(userId, moduleId, data, isGuest)
    },
    [userId, isGuest, isDemoMode]
  )

  // ============================================
  // Activity
  // ============================================

  const startSession = useCallback(
    async (moduleId: string) => {
      if (isDemoMode) {
        return 'demo-session'
      }
      return activityService.startSession(userId, moduleId, isGuest)
    },
    [userId, isGuest, isDemoMode]
  )

  const endSession = useCallback(async () => {
    if (isDemoMode) return
    return activityService.endSession(userId, isGuest)
  }, [userId, isGuest, isDemoMode])

  const recordGame = useCallback(
    (result: { correct: number; mistakes: number; coinsEarned: number }) => {
      if (isDemoMode) return
      activityService.recordGameInSession(result)
    },
    [isDemoMode]
  )

  // ============================================
  // Quick Helpers
  // ============================================

  const recordQuickPlayResult = useCallback(
    async (result: {
      won: boolean
      difficultyLevel: number
      timeMs: number
      coinsEarned: number
    }) => {
      if (isDemoMode) return

      await progressService.recordQuickPlayResult(userId, isGuest, result)
    },
    [userId, isGuest, isDemoMode]
  )

  const addCoins = useCallback(
    async (amount: number) => {
      if (isDemoMode) return 0
      return progressService.addCoins(userId, amount, isGuest)
    },
    [userId, isGuest, isDemoMode]
  )

  const getCoins = useCallback(async () => {
    if (isDemoMode) return 0
    return progressService.getCoins(userId, isGuest)
  }, [userId, isGuest, isDemoMode])

  // ============================================
  // Activity Queries
  // ============================================

  const getRecentActivity = useCallback(
    async (limit: number = 20) => {
      if (isDemoMode) return []
      return activityService.getRecentActivity(userId, isGuest, limit)
    },
    [userId, isGuest, isDemoMode]
  )

  const getActivitySummary = useCallback(
    async (days: number = 7) => {
      if (isDemoMode) {
        return { totalGames: 0, totalTime: 0, totalCoins: 0, accuracy: 0 }
      }
      return activityService.getActivitySummary(userId, isGuest, days)
    },
    [userId, isGuest, isDemoMode]
  )

  // ============================================
  // Progress Summary
  // ============================================

  const getProgressSummary = useCallback(
    async (moduleId: string) => {
      if (isDemoMode) {
        return { gamesPlayed: 0, gamesWon: 0, winRate: 0, totalCoins: 0, bestStreak: 0 }
      }
      return progressService.getProgressSummary(userId, moduleId, isGuest)
    },
    [userId, isGuest, isDemoMode]
  )

  return {
    isReady: baseContext.isReady,
    getProgress,
    saveProgress,
    startSession,
    endSession,
    recordGame,
    recordQuickPlayResult,
    addCoins,
    getCoins,
    getRecentActivity,
    getActivitySummary,
    getProgressSummary,
  }
}

/**
 * Hook to access raw storage context (without auth)
 * Use useStorage() for full functionality
 */
export function useStorageContext(): StorageContextValue {
  const context = useContext(StorageContext)
  if (!context) {
    throw new Error('useStorageContext must be used within a StorageProvider')
  }
  return context
}
