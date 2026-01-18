import { useState, useEffect, useCallback } from 'react'
import { useParams } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import Card from '@/ui/Card'
import Header from '../components/Header'
import { getActivityHistory, groupActivitiesByDate } from '@/shared/services/dashboard'
import { formatTimeOfDay, formatDuration } from '@/shared/utils/formatters'
import type { ActivityEntry, ActivityGroup, TimePeriod } from '../types/dashboard'

/**
 * Activity History Screen - Full activity log for a child
 */
export default function ActivityHistoryScreen() {
  const { childId } = useParams<{ childId: string }>()
  const { children } = useAuth()

  // Find child
  const child = children.find((c) => c.id === childId)

  // State
  const [activities, setActivities] = useState<ActivityEntry[]>([])
  const [groupedActivities, setGroupedActivities] = useState<ActivityGroup[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [period, setPeriod] = useState<TimePeriod>('week')

  // Load activities
  const loadActivities = useCallback(async () => {
    if (!childId) return

    setIsLoading(true)

    try {
      const data = await getActivityHistory(childId, period, 100)
      setActivities(data)
      setGroupedActivities(groupActivitiesByDate(data))
    } catch (err) {
      console.error('Failed to load activity history:', err)
    } finally {
      setIsLoading(false)
    }
  }, [childId, period])

  useEffect(() => {
    loadActivities()
  }, [loadActivities])

  // Calculate totals for the period
  const periodTotals = activities.reduce(
    (acc, a) => ({
      games: acc.games + a.gamesPlayed,
      time: acc.time + a.duration,
      coins: acc.coins + a.coinsEarned,
      correct: acc.correct + a.correctAnswers,
      total: acc.total + a.correctAnswers + a.mistakes,
    }),
    { games: 0, time: 0, coins: 0, correct: 0, total: 0 }
  )

  const periodAccuracy =
    periodTotals.total > 0 ? Math.round((periodTotals.correct / periodTotals.total) * 100) : 0

  // Child not found
  if (!child) {
    return (
      <div className="min-h-screen flex flex-col bg-background-dark">
        <Header title="Activity History" showBack />
        <main className="flex-1 flex items-center justify-center">
          <p className="text-text-secondary">Child not found</p>
        </main>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      {/* Header */}
      <Header title={`${child.displayName}'s Activity`} showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-2xl mx-auto">
          {/* Period Filter Pills */}
          <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
            {(
              [
                { key: 'today', label: 'Today' },
                { key: 'week', label: 'This Week' },
                { key: 'month', label: 'This Month' },
                { key: 'all', label: 'All Time' },
              ] as { key: TimePeriod; label: string }[]
            ).map((p) => (
              <button
                key={p.key}
                onClick={() => setPeriod(p.key)}
                className={`
                  px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all
                  ${
                    period === p.key
                      ? 'bg-accent-primary text-black'
                      : 'bg-background-mid text-text-secondary hover:bg-background-light'
                  }
                `}
              >
                {p.label}
              </button>
            ))}
          </div>

          {/* Period Summary Card */}
          {!isLoading && activities.length > 0 && (
            <Card className="p-4 mb-6">
              <div className="grid grid-cols-4 gap-4 text-center">
                <div>
                  <div className="text-xl font-bold">{periodTotals.games}</div>
                  <div className="text-xs text-text-secondary">Games</div>
                </div>
                <div>
                  <div className="text-xl font-bold">{formatDuration(periodTotals.time)}</div>
                  <div className="text-xs text-text-secondary">Time</div>
                </div>
                <div>
                  <div className="text-xl font-bold">{periodAccuracy}%</div>
                  <div className="text-xs text-text-secondary">Accuracy</div>
                </div>
                <div>
                  <div className="text-xl font-bold text-accent-tertiary">
                    +{periodTotals.coins}
                  </div>
                  <div className="text-xs text-text-secondary">Coins</div>
                </div>
              </div>
            </Card>
          )}

          {/* Loading State */}
          {isLoading && (
            <div className="text-center py-16">
              <div className="text-5xl mb-4 animate-pulse">📋</div>
              <p className="text-text-secondary">Loading activity...</p>
            </div>
          )}

          {/* Empty State */}
          {!isLoading && activities.length === 0 && (
            <Card className="p-8 text-center">
              <div className="text-5xl mb-4">📭</div>
              <h3 className="text-xl font-bold mb-2">No Activity</h3>
              <p className="text-text-secondary">No play sessions recorded for this period.</p>
            </Card>
          )}

          {/* Activity Groups */}
          {!isLoading && groupedActivities.length > 0 && (
            <div className="space-y-8">
              {groupedActivities.map((group) => (
                <div key={group.dateLabel}>
                  {/* Date Header */}
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="text-sm font-bold text-text-secondary uppercase tracking-wider">
                      {group.dateLabel}
                    </h3>
                    <span className="text-xs text-text-secondary">
                      {group.totalGames} games • {formatDuration(group.totalTime)}
                    </span>
                  </div>

                  {/* Activity Cards */}
                  <div className="space-y-2">
                    {group.activities.map((activity) => (
                      <ActivityCard key={activity.id} activity={activity} />
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  )
}

// ============================================
// Activity Card Component
// ============================================

interface ActivityCardProps {
  activity: ActivityEntry
}

function ActivityCard({ activity }: ActivityCardProps) {
  const time = formatTimeOfDay(activity.date)

  return (
    <Card className="p-4">
      <div className="flex items-center gap-3">
        {/* Module Icon */}
        <span className="text-3xl">{activity.moduleIcon}</span>

        {/* Activity Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="font-medium">{activity.moduleName}</span>
            <span className="text-sm text-text-secondary">• {time}</span>
          </div>

          {/* Stats Row */}
          <div className="flex flex-wrap gap-x-3 gap-y-1 mt-1 text-sm">
            <span className="text-text-secondary">
              {activity.gamesPlayed} {activity.gamesPlayed === 1 ? 'game' : 'games'}
            </span>
            <span className="text-text-secondary">{formatDuration(activity.duration)}</span>
            <span
              className={activity.accuracy >= 80 ? 'text-accent-primary' : 'text-text-secondary'}
            >
              {activity.accuracy}% accuracy
            </span>
          </div>

          {/* Correct/Mistakes breakdown */}
          <div className="flex gap-3 mt-1 text-xs">
            <span className="text-green-400">✓ {activity.correctAnswers} correct</span>
            {activity.mistakes > 0 && (
              <span className="text-error">✗ {activity.mistakes} mistakes</span>
            )}
          </div>
        </div>

        {/* Coins Earned */}
        <div className="text-right flex-shrink-0">
          <div
            className={`font-bold ${activity.coinsEarned > 0 ? 'text-accent-tertiary' : 'text-text-secondary'}`}
          >
            {activity.coinsEarned > 0 ? `+${activity.coinsEarned}` : '0'}
          </div>
          <div className="text-xs text-text-secondary">coins</div>
        </div>
      </div>
    </Card>
  )
}
