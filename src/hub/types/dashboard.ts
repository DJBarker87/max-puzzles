/**
 * Parent Dashboard Types
 * Types for the parent dashboard data structures.
 */

// ============================================
// Child Summary Types
// ============================================

/**
 * Placeholder for V3 avatar customisation.
 */
export interface AvatarConfig {
  baseColor: string
  accessories: string[]
  expression: string
}

/**
 * Summary data for a child displayed on the parent dashboard.
 * Shows key metrics for the current week plus lifetime coins.
 */
export interface ChildSummary {
  id: string
  displayName: string
  avatarConfig: AvatarConfig | null // V3 - for now just null
  coins: number // Lifetime total
  lastPlayedAt: string | null // ISO timestamp

  thisWeekStats: {
    gamesPlayed: number
    timePlayedMinutes: number
    coinsEarned: number
    accuracy: number // 0-100 percentage
  }
}

// ============================================
// Child Detail Types
// ============================================

/**
 * Statistics for a specific difficulty level.
 */
export interface DifficultyLevelStats {
  levelNumber: number
  levelName: string
  played: number
  won: number
  winRate: number // 0-100
  bestTimeMs: number | null
  averageTimeMs: number | null
}

/**
 * Statistics for a specific puzzle module.
 */
export interface ModuleStats {
  moduleId: string
  moduleName: string

  // Activity counts
  gamesPlayed: number
  gamesWon: number
  timePlayed: number // Seconds
  coinsEarned: number
  accuracy: number // 0-100

  // Recency
  lastPlayedAt: string | null

  // Circuit Challenge specific (for progression - V2)
  levelsCompleted?: number
  totalLevels?: number
  totalStars?: number
  maxStars?: number

  // Difficulty breakdown for Quick Play
  difficultyStats?: Record<number, DifficultyLevelStats>
}

/**
 * Comprehensive statistics for a single child.
 * Used on the child detail screen.
 */
export interface ChildDetailStats {
  // Lifetime totals
  totalGamesPlayed: number
  totalTimePlayed: number // In seconds
  totalCoinsEarned: number
  overallAccuracy: number // 0-100 percentage

  // Streaks
  currentStreak: number // Consecutive wins
  bestStreak: number

  // Account info
  memberSince: string // ISO timestamp

  // Per-module breakdown
  moduleStats: Record<string, ModuleStats>
}

// ============================================
// Activity Types
// ============================================

/**
 * A single activity session entry.
 * Represents one play session from start to end.
 */
export interface ActivityEntry {
  id: string
  moduleId: string
  moduleName: string
  moduleIcon: string

  // Timing
  date: string // ISO timestamp of session start
  duration: number // Seconds

  // Performance
  gamesPlayed: number
  correctAnswers: number
  mistakes: number
  accuracy: number // 0-100

  // Rewards
  coinsEarned: number
}

/**
 * Activities grouped by date for display.
 */
export interface ActivityGroup {
  dateLabel: string // e.g., "Monday, 15 January"
  activities: ActivityEntry[]
  totalGames: number
  totalTime: number
  totalCoins: number
}

// ============================================
// Filter and Chart Types
// ============================================

/**
 * Time period options for filtering activity data.
 */
export type TimePeriod = 'today' | 'week' | 'month' | 'all'

/**
 * Metric options for activity charts.
 */
export type ChartMetric = 'games' | 'time' | 'accuracy' | 'coins'

/**
 * A single data point for charts.
 */
export interface ChartDataPoint {
  date: string // YYYY-MM-DD
  dateLabel: string // e.g., "Mon", "15 Jan"
  value: number
}

/**
 * Complete chart data with metadata.
 */
export interface ChartData {
  metric: ChartMetric
  period: TimePeriod
  points: ChartDataPoint[]
  maxValue: number
  total: number
  average: number
}

// ============================================
// Module Metadata
// ============================================

/**
 * Static metadata for puzzle modules.
 */
export const MODULE_METADATA: Record<string, { name: string; icon: string }> = {
  'circuit-challenge': {
    name: 'Circuit Challenge',
    icon: '⚡',
  },
  // Add more modules here as they're created
}

export function getModuleMeta(moduleId: string): { name: string; icon: string } {
  return MODULE_METADATA[moduleId] || { name: moduleId, icon: '🧩' }
}
