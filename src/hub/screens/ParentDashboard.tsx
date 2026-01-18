import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import Button from '@/ui/Button'
import Card from '@/ui/Card'
import Header from '../components/Header'
import ChildSummaryCard from '../components/ChildSummaryCard'
import { getChildrenSummaries } from '@/shared/services/dashboard'
import type { ChildSummary } from '../types/dashboard'

/**
 * Parent Dashboard - Main screen showing all children
 * Displays family overview with weekly stats for each child
 */
export default function ParentDashboard() {
  const navigate = useNavigate()
  const { family } = useAuth()

  // State
  const [summaries, setSummaries] = useState<ChildSummary[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Load children summaries
  const loadSummaries = useCallback(async () => {
    if (!family?.id) {
      setIsLoading(false)
      return
    }

    setIsLoading(true)
    setError(null)

    try {
      const data = await getChildrenSummaries(family.id)
      setSummaries(data)
    } catch (err) {
      console.error('Failed to load children summaries:', err)
      setError('Failed to load data. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }, [family?.id])

  // Load on mount and when family changes
  useEffect(() => {
    loadSummaries()
  }, [loadSummaries])

  // Calculate family totals for header
  const familyTotals = summaries.reduce(
    (acc, child) => ({
      totalCoins: acc.totalCoins + child.coins,
      weekGames: acc.weekGames + child.thisWeekStats.gamesPlayed,
      weekTime: acc.weekTime + child.thisWeekStats.timePlayedMinutes,
    }),
    { totalCoins: 0, weekGames: 0, weekTime: 0 }
  )

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      {/* Header */}
      <Header title="Parent Dashboard" showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-4xl mx-auto">
          {/* Family Header Card */}
          <Card className="p-6 mb-8">
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <div>
                <h1 className="text-2xl md:text-3xl font-display font-bold mb-1">
                  {family?.name || 'Your Family'}
                </h1>
                <p className="text-text-secondary">
                  {summaries.length === 0
                    ? 'No children added yet'
                    : `${summaries.length} ${summaries.length === 1 ? 'child' : 'children'}`}
                </p>
              </div>

              {/* Family totals (only show if there are children) */}
              {summaries.length > 0 && (
                <div className="flex gap-6 text-center">
                  <div>
                    <div className="text-2xl font-bold text-accent-tertiary">
                      {familyTotals.totalCoins.toLocaleString()}
                    </div>
                    <div className="text-xs text-text-secondary">Total Coins</div>
                  </div>
                  <div>
                    <div className="text-2xl font-bold text-accent-primary">
                      {familyTotals.weekGames}
                    </div>
                    <div className="text-xs text-text-secondary">Games This Week</div>
                  </div>
                  <div>
                    <div className="text-2xl font-bold text-accent-secondary">
                      {familyTotals.weekTime}m
                    </div>
                    <div className="text-xs text-text-secondary">Time This Week</div>
                  </div>
                </div>
              )}
            </div>
          </Card>

          {/* Loading State */}
          {isLoading && (
            <div className="text-center py-16">
              <div className="text-5xl mb-4 animate-bounce">📊</div>
              <p className="text-text-secondary">Loading family data...</p>
            </div>
          )}

          {/* Error State */}
          {error && !isLoading && (
            <Card className="p-8 text-center">
              <div className="text-5xl mb-4">⚠️</div>
              <h3 className="text-xl font-bold mb-2">Something went wrong</h3>
              <p className="text-text-secondary mb-4">{error}</p>
              <Button variant="secondary" onClick={loadSummaries}>
                Try Again
              </Button>
            </Card>
          )}

          {/* Empty State */}
          {!isLoading && !error && summaries.length === 0 && (
            <Card className="p-8 text-center">
              <div className="text-6xl mb-4">👶</div>
              <h3 className="text-2xl font-bold mb-2">No Children Yet</h3>
              <p className="text-text-secondary mb-6 max-w-md mx-auto">
                Add a child to start tracking their maths puzzle progress. Each child gets their own
                profile with a simple PIN for login.
              </p>
              <Button variant="primary" size="lg" onClick={() => navigate('/parent/add-child')}>
                + Add Your First Child
              </Button>
            </Card>
          )}

          {/* Children List */}
          {!isLoading && !error && summaries.length > 0 && (
            <div className="space-y-4">
              <h2 className="text-lg font-bold text-text-secondary uppercase tracking-wider">
                Children
              </h2>

              {summaries.map((child) => (
                <ChildSummaryCard
                  key={child.id}
                  summary={child}
                  onClick={() => navigate(`/parent/child/${child.id}`)}
                />
              ))}
            </div>
          )}

          {/* Action Buttons */}
          <div className="mt-8 space-y-3">
            {/* Only show Add Child if under the limit (5) */}
            {summaries.length < 5 && (
              <Button variant="secondary" fullWidth onClick={() => navigate('/parent/add-child')}>
                + Add Child
              </Button>
            )}

            <Button variant="ghost" fullWidth onClick={() => navigate('/parent/settings')}>
              ⚙️ Family Settings
            </Button>

            <Button variant="ghost" fullWidth onClick={() => navigate('/family-select')}>
              ← Back to Family Select
            </Button>
          </div>
        </div>
      </main>
    </div>
  )
}
