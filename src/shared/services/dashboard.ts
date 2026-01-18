/**
 * Dashboard Service
 * Fetches and computes data for the parent dashboard.
 */

import { supabase } from './supabase'
import type {
  ChildSummary,
  ChildDetailStats,
  ModuleStats,
  ActivityEntry,
  ActivityGroup,
  TimePeriod,
  ChartMetric,
  ChartData,
  ChartDataPoint,
  DifficultyLevelStats,
} from '@/hub/types/dashboard'
import { getModuleMeta } from '@/hub/types/dashboard'

// ============================================
// FAMILY OVERVIEW
// ============================================

/**
 * Fetches summary data for all children in a family.
 * Used on the main parent dashboard.
 */
export async function getChildrenSummaries(familyId: string): Promise<ChildSummary[]> {
  if (!supabase) {
    console.warn('Supabase not configured, returning empty summaries')
    return []
  }

  // 1. Fetch all active children in the family
  const { data: children, error: childError } = await supabase
    .from('users')
    .select('id, display_name, coins, created_at')
    .eq('family_id', familyId)
    .eq('role', 'child')
    .eq('is_active', true)
    .order('created_at', { ascending: true })

  if (childError) {
    console.error('Error fetching children:', childError)
    return []
  }

  if (!children || children.length === 0) {
    return []
  }

  // 2. Calculate the start of "this week" (Monday 00:00:00)
  const weekStart = getStartOfWeek(new Date())

  // 3. Build summaries for each child
  const summaries: ChildSummary[] = await Promise.all(
    children.map(async (child) => {
      // Fetch this week's activity
      const weekStats = await getChildWeekStats(child.id, weekStart)

      // Fetch last played timestamp
      const lastPlayedAt = await getChildLastPlayed(child.id)

      return {
        id: child.id,
        displayName: child.display_name,
        avatarConfig: null, // V3
        coins: child.coins || 0,
        lastPlayedAt,
        thisWeekStats: weekStats,
      }
    })
  )

  return summaries
}

/**
 * Gets activity stats for a child since a given date.
 */
async function getChildWeekStats(
  childId: string,
  since: Date
): Promise<ChildSummary['thisWeekStats']> {
  const defaultStats = {
    gamesPlayed: 0,
    timePlayedMinutes: 0,
    coinsEarned: 0,
    accuracy: 0,
  }

  if (!supabase) return defaultStats

  const { data, error } = await supabase
    .from('activity_log')
    .select('games_played, duration_seconds, coins_earned, correct_answers, mistakes')
    .eq('user_id', childId)
    .gte('session_start', since.toISOString())

  if (error || !data || data.length === 0) {
    return defaultStats
  }

  // Aggregate the data
  const totals = data.reduce(
    (acc, row) => ({
      games: acc.games + (row.games_played || 0),
      seconds: acc.seconds + (row.duration_seconds || 0),
      coins: acc.coins + (row.coins_earned || 0),
      correct: acc.correct + (row.correct_answers || 0),
      total: acc.total + (row.correct_answers || 0) + (row.mistakes || 0),
    }),
    { games: 0, seconds: 0, coins: 0, correct: 0, total: 0 }
  )

  return {
    gamesPlayed: totals.games,
    timePlayedMinutes: Math.round(totals.seconds / 60),
    coinsEarned: totals.coins,
    accuracy: totals.total > 0 ? Math.round((totals.correct / totals.total) * 100) : 0,
  }
}

/**
 * Gets the most recent play session timestamp for a child.
 */
async function getChildLastPlayed(childId: string): Promise<string | null> {
  if (!supabase) return null

  const { data, error } = await supabase
    .from('activity_log')
    .select('session_start')
    .eq('user_id', childId)
    .order('session_start', { ascending: false })
    .limit(1)
    .single()

  if (error || !data) return null
  return data.session_start
}

// ============================================
// CHILD DETAIL STATS
// ============================================

/**
 * Fetches comprehensive statistics for a single child.
 * Used on the child detail screen.
 */
export async function getChildDetailStats(childId: string): Promise<ChildDetailStats | null> {
  if (!supabase) return null

  // 1. Get user creation date
  const { data: user, error: userError } = await supabase
    .from('users')
    .select('created_at')
    .eq('id', childId)
    .single()

  if (userError || !user) {
    console.error('Error fetching user:', userError)
    return null
  }

  // 2. Get all activity logs for this child
  const { data: activities, error: actError } = await supabase
    .from('activity_log')
    .select('*')
    .eq('user_id', childId)
    .order('session_start', { ascending: false })

  if (actError) {
    console.error('Error fetching activities:', actError)
  }

  // 3. Get module progress data
  const { data: progressRecords, error: progError } = await supabase
    .from('module_progress')
    .select('*')
    .eq('user_id', childId)

  if (progError) {
    console.error('Error fetching progress:', progError)
  }

  // 4. Calculate lifetime totals
  const lifetimeTotals = (activities || []).reduce(
    (acc, a) => ({
      games: acc.games + (a.games_played || 0),
      time: acc.time + (a.duration_seconds || 0),
      coins: acc.coins + (a.coins_earned || 0),
      correct: acc.correct + (a.correct_answers || 0),
      mistakes: acc.mistakes + (a.mistakes || 0),
    }),
    { games: 0, time: 0, coins: 0, correct: 0, mistakes: 0 }
  )

  // 5. Build per-module stats
  const moduleStats = buildModuleStats(activities || [], progressRecords || [])

  // 6. Extract streak data from Circuit Challenge progress
  const ccProgress = progressRecords?.find((p) => p.module_id === 'circuit-challenge')
  const ccData = ccProgress?.data as Record<string, unknown> | undefined
  const quickPlayData = ccData?.quickPlay as Record<string, unknown> | undefined
  const currentStreak = (quickPlayData?.currentStreak as number) || 0
  const bestStreak = (quickPlayData?.bestStreak as number) || 0

  return {
    totalGamesPlayed: lifetimeTotals.games,
    totalTimePlayed: lifetimeTotals.time,
    totalCoinsEarned: lifetimeTotals.coins,
    overallAccuracy:
      lifetimeTotals.correct + lifetimeTotals.mistakes > 0
        ? Math.round(
            (lifetimeTotals.correct / (lifetimeTotals.correct + lifetimeTotals.mistakes)) * 100
          )
        : 0,
    currentStreak,
    bestStreak,
    memberSince: user.created_at,
    moduleStats,
  }
}

/**
 * Builds per-module statistics from activity logs and progress records.
 */
function buildModuleStats(
  activities: Record<string, unknown>[],
  progressRecords: Record<string, unknown>[]
): Record<string, ModuleStats> {
  const stats: Record<string, ModuleStats> = {}

  // Group activities by module
  const actByModule: Record<string, Record<string, unknown>[]> = {}
  for (const act of activities) {
    const mid = act.module_id as string
    if (!actByModule[mid]) actByModule[mid] = []
    actByModule[mid].push(act)
  }

  // Build stats for each module
  for (const [moduleId, moduleActs] of Object.entries(actByModule)) {
    const meta = getModuleMeta(moduleId)

    // Aggregate activity data
    const totals = moduleActs.reduce<{
      games: number
      time: number
      coins: number
      correct: number
      mistakes: number
    }>(
      (acc, a) => ({
        games: acc.games + ((a.games_played as number) || 0),
        time: acc.time + ((a.duration_seconds as number) || 0),
        coins: acc.coins + ((a.coins_earned as number) || 0),
        correct: acc.correct + ((a.correct_answers as number) || 0),
        mistakes: acc.mistakes + ((a.mistakes as number) || 0),
      }),
      { games: 0, time: 0, coins: 0, correct: 0, mistakes: 0 }
    )

    // Find corresponding progress record
    const progress = progressRecords.find((p) => p.module_id === moduleId)
    const progressData = progress?.data as Record<string, unknown> | undefined
    const quickPlayData = progressData?.quickPlay as Record<string, unknown> | undefined

    // Get wins from progress data
    const gamesWon = (quickPlayData?.gamesWon as number) || 0

    // Get last played from most recent activity
    const sortedActs = [...moduleActs].sort(
      (a, b) =>
        new Date(b.session_start as string).getTime() -
        new Date(a.session_start as string).getTime()
    )
    const lastPlayedAt = (sortedActs[0]?.session_start as string) || null

    // Build difficulty stats if available
    const difficultyStatsRaw = quickPlayData?.difficultyStats as
      | Record<number, unknown>
      | undefined
    const difficultyStats = difficultyStatsRaw
      ? buildDifficultyStats(difficultyStatsRaw)
      : undefined

    stats[moduleId] = {
      moduleId,
      moduleName: meta.name,
      gamesPlayed: totals.games,
      gamesWon,
      timePlayed: totals.time,
      coinsEarned: totals.coins,
      accuracy:
        totals.correct + totals.mistakes > 0
          ? Math.round((totals.correct / (totals.correct + totals.mistakes)) * 100)
          : 0,
      lastPlayedAt,
      difficultyStats,
    }
  }

  return stats
}

/**
 * Transforms raw difficulty stats into typed format.
 */
function buildDifficultyStats(
  raw: Record<number, unknown>
): Record<number, DifficultyLevelStats> {
  const result: Record<number, DifficultyLevelStats> = {}

  for (const [level, data] of Object.entries(raw)) {
    const levelNum = Number(level)
    const d = data as Record<string, unknown>
    const played = (d.played as number) || 0
    const won = (d.won as number) || 0

    result[levelNum] = {
      levelNumber: levelNum,
      levelName: `Level ${levelNum + 1}`,
      played,
      won,
      winRate: played > 0 ? Math.round((won / played) * 100) : 0,
      bestTimeMs: (d.bestTimeMs as number) || null,
      averageTimeMs: null, // Not tracked currently
    }
  }

  return result
}

// ============================================
// ACTIVITY HISTORY
// ============================================

/**
 * Fetches activity history for a child with optional time filtering.
 * Returns entries sorted by most recent first.
 */
export async function getActivityHistory(
  childId: string,
  period: TimePeriod = 'week',
  limit: number = 50
): Promise<ActivityEntry[]> {
  if (!supabase) return []

  // Build the query
  let query = supabase
    .from('activity_log')
    .select('*')
    .eq('user_id', childId)
    .order('session_start', { ascending: false })
    .limit(limit)

  // Apply time filter based on period
  if (period !== 'all') {
    const since = getPeriodStartDate(period)
    query = query.gte('session_start', since.toISOString())
  }

  const { data, error } = await query

  if (error) {
    console.error('Error fetching activity history:', error)
    return []
  }

  if (!data) return []

  // Transform to ActivityEntry format
  return data.map((row) => {
    const meta = getModuleMeta(row.module_id)
    const correct = row.correct_answers || 0
    const mistakes = row.mistakes || 0
    const total = correct + mistakes

    return {
      id: row.id,
      moduleId: row.module_id,
      moduleName: meta.name,
      moduleIcon: meta.icon,
      date: row.session_start,
      duration: row.duration_seconds || 0,
      gamesPlayed: row.games_played || 0,
      correctAnswers: correct,
      mistakes: mistakes,
      accuracy: total > 0 ? Math.round((correct / total) * 100) : 0,
      coinsEarned: row.coins_earned || 0,
    }
  })
}

/**
 * Groups activity entries by date for display.
 */
export function groupActivitiesByDate(activities: ActivityEntry[]): ActivityGroup[] {
  const groups: Map<string, ActivityEntry[]> = new Map()

  for (const activity of activities) {
    // Create a date key (YYYY-MM-DD)
    const dateKey = activity.date.split('T')[0]

    if (!groups.has(dateKey)) {
      groups.set(dateKey, [])
    }
    groups.get(dateKey)!.push(activity)
  }

  // Convert to array and calculate totals
  const result: ActivityGroup[] = []

  for (const [dateKey, entries] of groups) {
    // Create human-readable date label
    const date = new Date(dateKey)
    const today = new Date()
    const yesterday = new Date(today)
    yesterday.setDate(yesterday.getDate() - 1)

    let dateLabel: string
    if (dateKey === today.toISOString().split('T')[0]) {
      dateLabel = 'Today'
    } else if (dateKey === yesterday.toISOString().split('T')[0]) {
      dateLabel = 'Yesterday'
    } else {
      dateLabel = date.toLocaleDateString('en-GB', {
        weekday: 'long',
        day: 'numeric',
        month: 'short',
      })
    }

    // Calculate totals for the day
    const totalGames = entries.reduce((sum, e) => sum + e.gamesPlayed, 0)
    const totalTime = entries.reduce((sum, e) => sum + e.duration, 0)
    const totalCoins = entries.reduce((sum, e) => sum + e.coinsEarned, 0)

    result.push({
      dateLabel,
      activities: entries,
      totalGames,
      totalTime,
      totalCoins,
    })
  }

  return result
}

// ============================================
// CHART DATA
// ============================================

/**
 * Fetches data for activity charts.
 * Returns daily aggregated data points for the specified metric and period.
 */
export async function getActivityChartData(
  childId: string,
  metric: ChartMetric,
  period: TimePeriod
): Promise<ChartData> {
  const days = getPeriodDays(period)
  const since = getDaysAgo(days)

  // Initialize result structure
  const result: ChartData = {
    metric,
    period,
    points: [],
    maxValue: 0,
    total: 0,
    average: 0,
  }

  if (!supabase) return result

  // Fetch activity data
  const { data, error } = await supabase
    .from('activity_log')
    .select('session_start, games_played, duration_seconds, correct_answers, mistakes, coins_earned')
    .eq('user_id', childId)
    .gte('session_start', since.toISOString())
    .order('session_start', { ascending: true })

  if (error) {
    console.error('Error fetching chart data:', error)
    return result
  }

  // Initialize all days in the range (even if no activity)
  const dayMap: Map<
    string,
    {
      games: number
      seconds: number
      correct: number
      total: number
      coins: number
    }
  > = new Map()

  for (let i = days - 1; i >= 0; i--) {
    const d = new Date()
    d.setDate(d.getDate() - i)
    const key = d.toISOString().split('T')[0]
    dayMap.set(key, { games: 0, seconds: 0, correct: 0, total: 0, coins: 0 })
  }

  // Aggregate activity data by day
  for (const row of data || []) {
    const dayKey = row.session_start.split('T')[0]
    const existing = dayMap.get(dayKey)

    if (existing) {
      existing.games += row.games_played || 0
      existing.seconds += row.duration_seconds || 0
      existing.correct += row.correct_answers || 0
      existing.total += (row.correct_answers || 0) + (row.mistakes || 0)
      existing.coins += row.coins_earned || 0
    }
  }

  // Convert to chart points
  const points: ChartDataPoint[] = []
  let total = 0
  let maxValue = 0
  let daysWithData = 0

  for (const [dateKey, dayData] of dayMap) {
    let value: number

    switch (metric) {
      case 'games':
        value = dayData.games
        break
      case 'time':
        value = Math.round(dayData.seconds / 60) // Convert to minutes
        break
      case 'accuracy':
        value = dayData.total > 0 ? Math.round((dayData.correct / dayData.total) * 100) : 0
        break
      case 'coins':
        value = dayData.coins
        break
      default:
        value = 0
    }

    // Create date label based on period
    const date = new Date(dateKey)
    let dateLabel: string

    if (days <= 7) {
      // Show weekday for week view
      dateLabel = date.toLocaleDateString('en-GB', { weekday: 'short' })
    } else {
      // Show date for month view
      dateLabel = date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })
    }

    points.push({
      date: dateKey,
      dateLabel,
      value,
    })

    // Track totals
    total += value
    if (value > maxValue) maxValue = value
    if (value > 0 || metric !== 'accuracy') daysWithData++
  }

  result.points = points
  result.maxValue = maxValue
  result.total = total
  result.average = daysWithData > 0 ? Math.round(total / daysWithData) : 0

  return result
}

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Gets the start of the current week (Monday 00:00:00).
 */
export function getStartOfWeek(date: Date): Date {
  const d = new Date(date)
  const day = d.getDay()
  const diff = d.getDate() - day + (day === 0 ? -6 : 1) // Adjust for Sunday
  d.setDate(diff)
  d.setHours(0, 0, 0, 0)
  return d
}

/**
 * Gets the start of today (00:00:00).
 */
export function getStartOfDay(date: Date): Date {
  const d = new Date(date)
  d.setHours(0, 0, 0, 0)
  return d
}

/**
 * Gets a date N days ago.
 */
export function getDaysAgo(days: number): Date {
  const d = new Date()
  d.setDate(d.getDate() - days)
  d.setHours(0, 0, 0, 0)
  return d
}

/**
 * Gets the start date for a time period.
 */
function getPeriodStartDate(period: TimePeriod): Date {
  const now = new Date()

  switch (period) {
    case 'today':
      return getStartOfDay(now)
    case 'week':
      return getStartOfWeek(now)
    case 'month': {
      const monthAgo = new Date(now)
      monthAgo.setMonth(monthAgo.getMonth() - 1)
      return monthAgo
    }
    case 'all':
    default:
      return new Date(0) // Beginning of time
  }
}

/**
 * Gets the number of days for a time period.
 */
function getPeriodDays(period: TimePeriod): number {
  switch (period) {
    case 'today':
      return 1
    case 'week':
      return 7
    case 'month':
      return 30
    case 'all':
      return 90 // Cap at 90 days for charts
    default:
      return 7
  }
}
