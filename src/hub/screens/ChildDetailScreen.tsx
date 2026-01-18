import { useState, useEffect, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import Button from '@/ui/Button'
import Card from '@/ui/Card'
import Modal from '@/ui/Modal'
import Header from '../components/Header'
import ActivityChart from '../components/ActivityChart'
import { getChildDetailStats } from '@/shared/services/dashboard'
import { formatDate, formatDuration, formatRelativeTime } from '@/shared/utils/formatters'
import type { ChildDetailStats, TimePeriod, ModuleStats } from '../types/dashboard'

/**
 * Child Detail Screen - Shows comprehensive stats for a single child
 */
export default function ChildDetailScreen() {
  const { childId } = useParams<{ childId: string }>()
  const navigate = useNavigate()
  const { children, removeChild } = useAuth()

  // Find the child in auth context
  const child = children.find((c) => c.id === childId)

  // State
  const [stats, setStats] = useState<ChildDetailStats | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [chartPeriod, setChartPeriod] = useState<TimePeriod>('week')
  const [showRemoveModal, setShowRemoveModal] = useState(false)
  const [isRemoving, setIsRemoving] = useState(false)

  // Load stats
  const loadStats = useCallback(async () => {
    if (!childId) return

    setIsLoading(true)
    setError(null)

    try {
      const data = await getChildDetailStats(childId)
      setStats(data)
    } catch (err) {
      console.error('Failed to load child stats:', err)
      setError('Failed to load statistics.')
    } finally {
      setIsLoading(false)
    }
  }, [childId])

  useEffect(() => {
    loadStats()
  }, [loadStats])

  // Handle child removal
  const handleRemoveChild = async () => {
    if (!childId) return

    setIsRemoving(true)
    try {
      await removeChild(childId)
      navigate('/parent/dashboard')
    } catch (err) {
      console.error('Failed to remove child:', err)
      setError('Failed to remove child. Please try again.')
    } finally {
      setIsRemoving(false)
      setShowRemoveModal(false)
    }
  }

  // Child not found state
  if (!child) {
    return (
      <div className="min-h-screen flex flex-col bg-background-dark">
        <Header title="Child Not Found" showBack />
        <main className="flex-1 flex items-center justify-center p-4">
          <Card className="p-8 text-center max-w-md">
            <div className="text-5xl mb-4">🔍</div>
            <h2 className="text-xl font-bold mb-2">Child Not Found</h2>
            <p className="text-text-secondary mb-4">
              This child profile doesn't exist or has been removed.
            </p>
            <Button variant="primary" onClick={() => navigate('/parent/dashboard')}>
              Back to Dashboard
            </Button>
          </Card>
        </main>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      {/* Header */}
      <Header title={child.displayName} showBack />

      <main className="flex-1 p-4 md:p-8 pb-24">
        <div className="max-w-4xl mx-auto">
          {/* Profile Header Card */}
          <Card className="p-6 mb-6">
            <div className="flex flex-col sm:flex-row sm:items-center gap-4">
              {/* Avatar */}
              <div className="text-7xl">👽</div>

              {/* Name and member since */}
              <div className="flex-1">
                <h1 className="text-2xl md:text-3xl font-display font-bold">{child.displayName}</h1>
                <p className="text-text-secondary">
                  {stats ? `Member since ${formatDate(stats.memberSince)}` : 'Loading...'}
                </p>
              </div>

              {/* Total Coins */}
              <div className="text-center sm:text-right">
                <div className="text-4xl font-bold text-accent-tertiary tabular-nums">
                  {(child.coins || 0).toLocaleString()}
                </div>
                <div className="text-sm text-text-secondary">Total Coins</div>
              </div>
            </div>
          </Card>

          {/* Loading State */}
          {isLoading && (
            <div className="text-center py-16">
              <div className="text-5xl mb-4 animate-pulse">📊</div>
              <p className="text-text-secondary">Loading statistics...</p>
            </div>
          )}

          {/* Error State */}
          {error && !isLoading && (
            <Card className="p-8 text-center mb-6">
              <div className="text-5xl mb-4">⚠️</div>
              <h3 className="text-xl font-bold mb-2">Error Loading Stats</h3>
              <p className="text-text-secondary mb-4">{error}</p>
              <Button variant="secondary" onClick={loadStats}>
                Try Again
              </Button>
            </Card>
          )}

          {/* Stats Content */}
          {stats && !isLoading && (
            <>
              {/* Quick Stats Grid */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                <QuickStatCard icon="🎮" value={stats.totalGamesPlayed} label="Games Played" />
                <QuickStatCard
                  icon="⏱️"
                  value={formatDuration(stats.totalTimePlayed)}
                  label="Time Played"
                />
                <QuickStatCard
                  icon="✓"
                  value={`${stats.overallAccuracy}%`}
                  label="Accuracy"
                  highlight={stats.overallAccuracy >= 80}
                />
                <QuickStatCard
                  icon="🔥"
                  value={stats.bestStreak}
                  label="Best Streak"
                  subtitle={stats.currentStreak > 0 ? `Current: ${stats.currentStreak}` : undefined}
                />
              </div>

              {/* Activity Chart */}
              <Card className="p-4 mb-6">
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-4">
                  <h2 className="text-lg font-bold">Activity Over Time</h2>

                  {/* Period Selector */}
                  <div className="flex gap-2">
                    {(['week', 'month'] as TimePeriod[]).map((period) => (
                      <button
                        key={period}
                        onClick={() => setChartPeriod(period)}
                        className={`
                          px-4 py-2 rounded-lg text-sm font-medium transition-colors
                          ${
                            chartPeriod === period
                              ? 'bg-accent-primary text-black'
                              : 'bg-background-dark text-text-secondary hover:bg-background-light'
                          }
                        `}
                      >
                        {period === 'week' ? 'Week' : 'Month'}
                      </button>
                    ))}
                  </div>
                </div>

                <ActivityChart childId={childId!} period={chartPeriod} />
              </Card>

              {/* Module Progress */}
              <Card className="p-4 mb-6">
                <h2 className="text-lg font-bold mb-4">Progress by Game</h2>

                {Object.keys(stats.moduleStats).length === 0 ? (
                  <p className="text-text-secondary text-center py-8">No games played yet</p>
                ) : (
                  <div className="space-y-1">
                    {Object.values(stats.moduleStats).map((module) => (
                      <ModuleProgressRow key={module.moduleId} stats={module} />
                    ))}
                  </div>
                )}
              </Card>

              {/* View Full History Button */}
              <Button
                variant="secondary"
                fullWidth
                onClick={() => navigate(`/parent/child/${childId}/activity`)}
                className="mb-6"
              >
                📋 View Full Activity History
              </Button>

              {/* Divider */}
              <div className="border-t border-white/10 my-8" />

              {/* Management Section */}
              <div>
                <h2 className="text-lg font-bold mb-4 text-text-secondary">Manage Profile</h2>

                <div className="space-y-3">
                  <Button
                    variant="ghost"
                    fullWidth
                    onClick={() => navigate(`/parent/child/${childId}/edit`)}
                  >
                    ✏️ Edit Display Name
                  </Button>

                  <Button
                    variant="ghost"
                    fullWidth
                    onClick={() => navigate(`/parent/child/${childId}/reset-pin`)}
                  >
                    🔑 Reset PIN
                  </Button>

                  <Button
                    variant="ghost"
                    fullWidth
                    className="text-error hover:bg-error/10"
                    onClick={() => setShowRemoveModal(true)}
                  >
                    🗑️ Remove Child
                  </Button>
                </div>
              </div>
            </>
          )}
        </div>
      </main>

      {/* Remove Child Confirmation Modal */}
      <Modal isOpen={showRemoveModal} onClose={() => setShowRemoveModal(false)} title="Remove Child?">
        <div className="text-center">
          <div className="text-5xl mb-4">⚠️</div>
          <p className="mb-2">
            Are you sure you want to remove <strong>{child.displayName}</strong>?
          </p>
          <p className="text-text-secondary text-sm mb-6">
            This will permanently delete all their progress, stats, and earned coins. This action
            cannot be undone.
          </p>

          <div className="flex gap-3">
            <Button
              variant="ghost"
              fullWidth
              onClick={() => setShowRemoveModal(false)}
              disabled={isRemoving}
            >
              Cancel
            </Button>
            <Button
              variant="secondary"
              fullWidth
              className="bg-error hover:bg-error/80"
              onClick={handleRemoveChild}
              loading={isRemoving}
            >
              Remove Forever
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}

// ============================================
// Helper Components
// ============================================

interface QuickStatCardProps {
  icon: string
  value: string | number
  label: string
  subtitle?: string
  highlight?: boolean
}

function QuickStatCard({ icon, value, label, subtitle, highlight }: QuickStatCardProps) {
  return (
    <Card className="p-4 text-center">
      <div className="text-2xl mb-1">{icon}</div>
      <div className={`text-2xl font-bold ${highlight ? 'text-accent-primary' : ''}`}>{value}</div>
      <div className="text-xs text-text-secondary">{label}</div>
      {subtitle && <div className="text-xs text-accent-secondary mt-1">{subtitle}</div>}
    </Card>
  )
}

interface ModuleProgressRowProps {
  stats: ModuleStats
}

function ModuleProgressRow({ stats }: ModuleProgressRowProps) {
  const winRate = stats.gamesPlayed > 0 ? Math.round((stats.gamesWon / stats.gamesPlayed) * 100) : 0

  return (
    <div className="flex items-center gap-4 py-4 border-b border-white/5 last:border-0">
      {/* Module Icon */}
      <span className="text-3xl">⚡</span>

      {/* Module Info */}
      <div className="flex-1 min-w-0">
        <div className="font-bold">{stats.moduleName}</div>
        <div className="text-sm text-text-secondary">
          {stats.gamesPlayed} games played • {stats.accuracy}% accuracy
        </div>

        {/* Progress bar (win rate) */}
        <div className="mt-2 h-2 bg-background-dark rounded-full overflow-hidden">
          <div
            className="h-full bg-accent-primary rounded-full transition-all duration-500"
            style={{ width: `${winRate}%` }}
          />
        </div>
        <div className="text-xs text-text-secondary mt-1">
          {stats.gamesWon} / {stats.gamesPlayed} won ({winRate}%)
        </div>
      </div>

      {/* Last Played */}
      <div className="text-right text-sm text-text-secondary flex-shrink-0">
        {stats.lastPlayedAt ? formatRelativeTime(stats.lastPlayedAt) : 'Never'}
      </div>
    </div>
  )
}
