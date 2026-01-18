import Card from '@/ui/Card'
import type { ChildSummary } from '../types/dashboard'
import { formatRelativeTime } from '@/shared/utils/formatters'

interface ChildSummaryCardProps {
  summary: ChildSummary
  onClick: () => void
}

/**
 * Child summary card component for the parent dashboard.
 * Shows weekly stats and lifetime coins for a child.
 */
export default function ChildSummaryCard({ summary, onClick }: ChildSummaryCardProps) {
  const { thisWeekStats } = summary

  // Determine activity status for visual indicator
  const hasPlayedThisWeek = thisWeekStats.gamesPlayed > 0
  const hasPlayedRecently =
    summary.lastPlayedAt &&
    Date.now() - new Date(summary.lastPlayedAt).getTime() < 24 * 60 * 60 * 1000

  return (
    <Card
      variant="interactive"
      className="p-4 hover:border-accent-primary/50 transition-colors cursor-pointer"
      onClick={onClick}
    >
      <div className="flex items-center gap-4">
        {/* Avatar */}
        <div className="relative">
          <div className="text-5xl">👽</div>
          {/* Activity indicator dot */}
          {hasPlayedRecently && (
            <div
              className="absolute -top-1 -right-1 w-3 h-3 bg-accent-primary rounded-full border-2 border-background-mid"
              title="Played today"
            />
          )}
        </div>

        {/* Main Info */}
        <div className="flex-1 min-w-0">
          {/* Name */}
          <h3 className="text-lg font-bold truncate">{summary.displayName}</h3>

          {/* Last played */}
          <p className="text-sm text-text-secondary">
            {summary.lastPlayedAt
              ? `Last played ${formatRelativeTime(summary.lastPlayedAt)}`
              : 'Not played yet'}
          </p>

          {/* This Week Stats Row */}
          <div className="flex flex-wrap gap-x-4 gap-y-1 mt-2">
            {/* Games */}
            <StatBadge
              icon="🎮"
              value={thisWeekStats.gamesPlayed}
              label="games"
              color="text-accent-primary"
              highlight={thisWeekStats.gamesPlayed > 0}
            />

            {/* Coins earned this week */}
            <StatBadge
              icon="🪙"
              value={thisWeekStats.coinsEarned}
              label="coins"
              color="text-accent-tertiary"
              highlight={thisWeekStats.coinsEarned > 0}
            />

            {/* Time played */}
            <StatBadge
              icon="⏱️"
              value={`${thisWeekStats.timePlayedMinutes}m`}
              label=""
              color="text-accent-secondary"
              highlight={thisWeekStats.timePlayedMinutes > 0}
            />

            {/* Accuracy (only show if games played) */}
            {thisWeekStats.gamesPlayed > 0 && (
              <StatBadge
                icon="✓"
                value={`${thisWeekStats.accuracy}%`}
                label=""
                color={thisWeekStats.accuracy >= 80 ? 'text-green-400' : 'text-text-secondary'}
                highlight={thisWeekStats.accuracy >= 80}
              />
            )}
          </div>
        </div>

        {/* Lifetime Coins Badge */}
        <div className="text-right flex-shrink-0">
          <div className="text-2xl font-bold text-accent-tertiary tabular-nums">
            {summary.coins.toLocaleString()}
          </div>
          <div className="text-xs text-text-secondary">total coins</div>
        </div>

        {/* Arrow indicator */}
        <div className="text-2xl text-text-secondary flex-shrink-0">→</div>
      </div>

      {/* No activity this week banner */}
      {!hasPlayedThisWeek && summary.lastPlayedAt && (
        <div className="mt-3 pt-3 border-t border-white/5">
          <p className="text-sm text-text-secondary text-center">💤 No activity this week</p>
        </div>
      )}
    </Card>
  )
}

/**
 * Small stat badge component for the week stats row.
 */
interface StatBadgeProps {
  icon: string
  value: string | number
  label: string
  color: string
  highlight?: boolean
}

function StatBadge({ icon, value, label, color, highlight }: StatBadgeProps) {
  return (
    <span
      className={`
        flex items-center gap-1 text-sm
        ${highlight ? color : 'text-text-secondary'}
      `}
    >
      <span>{icon}</span>
      <span className={highlight ? 'font-medium' : ''}>
        {value}
        {label && <span className="ml-0.5">{label}</span>}
      </span>
    </span>
  )
}
