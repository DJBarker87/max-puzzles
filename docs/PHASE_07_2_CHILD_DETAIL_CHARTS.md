# Phase 7.2: Child Detail, Charts & Activity History

**Goal:** Build the detailed child statistics screen with activity charts and the full activity history view. These screens let parents drill down into individual child performance.

---

## Subphase 7.5: Activity History Service Functions

### Prompt for Claude Code:

```
Add activity history and chart data functions to the dashboard service.

File: src/shared/services/dashboard.ts (additions)

Add these functions to the existing dashboard.ts file:

```typescript
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
  if (!supabase) return [];

  // Build the query
  let query = supabase
    .from('activity_log')
    .select('*')
    .eq('user_id', childId)
    .order('session_start', { ascending: false })
    .limit(limit);

  // Apply time filter based on period
  if (period !== 'all') {
    const since = getPeriodStartDate(period);
    query = query.gte('session_start', since.toISOString());
  }

  const { data, error } = await query;

  if (error) {
    console.error('Error fetching activity history:', error);
    return [];
  }

  if (!data) return [];

  // Transform to ActivityEntry format
  return data.map((row) => {
    const meta = getModuleMeta(row.module_id);
    const correct = row.correct_answers || 0;
    const mistakes = row.mistakes || 0;
    const total = correct + mistakes;

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
    };
  });
}

/**
 * Groups activity entries by date for display.
 */
export function groupActivitiesByDate(
  activities: ActivityEntry[]
): ActivityGroup[] {
  const groups: Map<string, ActivityEntry[]> = new Map();

  for (const activity of activities) {
    // Create a date key (YYYY-MM-DD)
    const dateKey = activity.date.split('T')[0];
    
    if (!groups.has(dateKey)) {
      groups.set(dateKey, []);
    }
    groups.get(dateKey)!.push(activity);
  }

  // Convert to array and calculate totals
  const result: ActivityGroup[] = [];

  for (const [dateKey, entries] of groups) {
    // Create human-readable date label
    const date = new Date(dateKey);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    let dateLabel: string;
    if (dateKey === today.toISOString().split('T')[0]) {
      dateLabel = 'Today';
    } else if (dateKey === yesterday.toISOString().split('T')[0]) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = date.toLocaleDateString('en-GB', {
        weekday: 'long',
        day: 'numeric',
        month: 'short',
      });
    }

    // Calculate totals for the day
    const totalGames = entries.reduce((sum, e) => sum + e.gamesPlayed, 0);
    const totalTime = entries.reduce((sum, e) => sum + e.duration, 0);
    const totalCoins = entries.reduce((sum, e) => sum + e.coinsEarned, 0);

    result.push({
      dateLabel,
      activities: entries,
      totalGames,
      totalTime,
      totalCoins,
    });
  }

  return result;
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
  const days = getPeriodDays(period);
  const since = getDaysAgo(days);

  // Initialize result structure
  const result: ChartData = {
    metric,
    period,
    points: [],
    maxValue: 0,
    total: 0,
    average: 0,
  };

  if (!supabase) return result;

  // Fetch activity data
  const { data, error } = await supabase
    .from('activity_log')
    .select('session_start, games_played, duration_seconds, correct_answers, mistakes, coins_earned')
    .eq('user_id', childId)
    .gte('session_start', since.toISOString())
    .order('session_start', { ascending: true });

  if (error) {
    console.error('Error fetching chart data:', error);
    return result;
  }

  // Initialize all days in the range (even if no activity)
  const dayMap: Map<string, { 
    games: number; 
    seconds: number; 
    correct: number; 
    total: number;
    coins: number;
  }> = new Map();

  for (let i = days - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const key = d.toISOString().split('T')[0];
    dayMap.set(key, { games: 0, seconds: 0, correct: 0, total: 0, coins: 0 });
  }

  // Aggregate activity data by day
  for (const row of data || []) {
    const dayKey = row.session_start.split('T')[0];
    const existing = dayMap.get(dayKey);
    
    if (existing) {
      existing.games += row.games_played || 0;
      existing.seconds += row.duration_seconds || 0;
      existing.correct += row.correct_answers || 0;
      existing.total += (row.correct_answers || 0) + (row.mistakes || 0);
      existing.coins += row.coins_earned || 0;
    }
  }

  // Convert to chart points
  const points: ChartDataPoint[] = [];
  let total = 0;
  let maxValue = 0;
  let daysWithData = 0;

  for (const [dateKey, dayData] of dayMap) {
    let value: number;

    switch (metric) {
      case 'games':
        value = dayData.games;
        break;
      case 'time':
        value = Math.round(dayData.seconds / 60); // Convert to minutes
        break;
      case 'accuracy':
        value = dayData.total > 0 
          ? Math.round((dayData.correct / dayData.total) * 100)
          : 0;
        break;
      case 'coins':
        value = dayData.coins;
        break;
      default:
        value = 0;
    }

    // Create date label based on period
    const date = new Date(dateKey);
    let dateLabel: string;
    
    if (days <= 7) {
      // Show weekday for week view
      dateLabel = date.toLocaleDateString('en-GB', { weekday: 'short' });
    } else {
      // Show date for month view
      dateLabel = date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' });
    }

    points.push({
      date: dateKey,
      dateLabel,
      value,
    });

    // Track totals
    total += value;
    if (value > maxValue) maxValue = value;
    if (value > 0 || metric !== 'accuracy') daysWithData++;
  }

  result.points = points;
  result.maxValue = maxValue;
  result.total = total;
  result.average = daysWithData > 0 ? Math.round(total / daysWithData) : 0;

  return result;
}

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Gets the start date for a time period.
 */
function getPeriodStartDate(period: TimePeriod): Date {
  const now = new Date();
  
  switch (period) {
    case 'today':
      return getStartOfDay(now);
    case 'week':
      return getStartOfWeek(now);
    case 'month':
      const monthAgo = new Date(now);
      monthAgo.setMonth(monthAgo.getMonth() - 1);
      return monthAgo;
    case 'all':
    default:
      return new Date(0); // Beginning of time
  }
}

/**
 * Gets the number of days for a time period.
 */
function getPeriodDays(period: TimePeriod): number {
  switch (period) {
    case 'today':
      return 1;
    case 'week':
      return 7;
    case 'month':
      return 30;
    case 'all':
      return 90; // Cap at 90 days for charts
    default:
      return 7;
  }
}
```

Export all new functions.
```

---

## Subphase 7.6: Child Detail Screen

### Prompt for Claude Code:

```
Create the detailed child statistics screen.

File: src/hub/screens/ChildDetailScreen.tsx

```typescript
import React, { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@/app/providers/AuthProvider';
import { Button, Card, Modal } from '@/ui';
import { Header } from '../components';
import { ActivityChart } from '../components/ActivityChart';
import { getChildDetailStats } from '@/shared/services/dashboard';
import { formatDate, formatDuration, formatRelativeTime } from '@/shared/utils/formatters';
import type { ChildDetailStats, TimePeriod } from '../types/dashboard';

export function ChildDetailScreen() {
  const { childId } = useParams<{ childId: string }>();
  const navigate = useNavigate();
  const { children, removeChild } = useAuth();

  // Find the child in auth context
  const child = children.find((c) => c.id === childId);

  // State
  const [stats, setStats] = useState<ChildDetailStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [chartPeriod, setChartPeriod] = useState<TimePeriod>('week');
  const [showRemoveModal, setShowRemoveModal] = useState(false);
  const [isRemoving, setIsRemoving] = useState(false);

  // Load stats
  const loadStats = useCallback(async () => {
    if (!childId) return;

    setIsLoading(true);
    setError(null);

    try {
      const data = await getChildDetailStats(childId);
      setStats(data);
    } catch (err) {
      console.error('Failed to load child stats:', err);
      setError('Failed to load statistics.');
    } finally {
      setIsLoading(false);
    }
  }, [childId]);

  useEffect(() => {
    loadStats();
  }, [loadStats]);

  // Handle child removal
  const handleRemoveChild = async () => {
    if (!childId) return;

    setIsRemoving(true);
    try {
      await removeChild(childId);
      navigate('/parent/dashboard');
    } catch (err) {
      console.error('Failed to remove child:', err);
      setError('Failed to remove child. Please try again.');
    } finally {
      setIsRemoving(false);
      setShowRemoveModal(false);
    }
  };

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
    );
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
                <h1 className="text-2xl md:text-3xl font-display font-bold">
                  {child.displayName}
                </h1>
                <p className="text-text-secondary">
                  {stats 
                    ? `Member since ${formatDate(stats.memberSince)}`
                    : 'Loading...'}
                </p>
              </div>

              {/* Total Coins */}
              <div className="text-center sm:text-right">
                <div className="text-4xl font-bold text-accent-tertiary tabular-nums">
                  {child.coins.toLocaleString()}
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
                <QuickStatCard
                  icon="🎮"
                  value={stats.totalGamesPlayed}
                  label="Games Played"
                />
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
                          ${chartPeriod === period
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
                  <p className="text-text-secondary text-center py-8">
                    No games played yet
                  </p>
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
                <h2 className="text-lg font-bold mb-4 text-text-secondary">
                  Manage Profile
                </h2>
                
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
      <Modal
        isOpen={showRemoveModal}
        onClose={() => setShowRemoveModal(false)}
        title="Remove Child?"
      >
        <div className="text-center">
          <div className="text-5xl mb-4">⚠️</div>
          <p className="mb-2">
            Are you sure you want to remove <strong>{child.displayName}</strong>?
          </p>
          <p className="text-text-secondary text-sm mb-6">
            This will permanently delete all their progress, stats, and earned coins. 
            This action cannot be undone.
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
  );
}

// ============================================
// Helper Components
// ============================================

interface QuickStatCardProps {
  icon: string;
  value: string | number;
  label: string;
  subtitle?: string;
  highlight?: boolean;
}

function QuickStatCard({ icon, value, label, subtitle, highlight }: QuickStatCardProps) {
  return (
    <Card className="p-4 text-center">
      <div className="text-2xl mb-1">{icon}</div>
      <div className={`text-2xl font-bold ${highlight ? 'text-accent-primary' : ''}`}>
        {value}
      </div>
      <div className="text-xs text-text-secondary">{label}</div>
      {subtitle && (
        <div className="text-xs text-accent-secondary mt-1">{subtitle}</div>
      )}
    </Card>
  );
}

interface ModuleProgressRowProps {
  stats: import('../types/dashboard').ModuleStats;
}

function ModuleProgressRow({ stats }: ModuleProgressRowProps) {
  const winRate = stats.gamesPlayed > 0 
    ? Math.round((stats.gamesWon / stats.gamesPlayed) * 100) 
    : 0;

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
        {stats.lastPlayedAt 
          ? formatRelativeTime(stats.lastPlayedAt)
          : 'Never'}
      </div>
    </div>
  );
}

export default ChildDetailScreen;
```

Export ChildDetailScreen component.
```

---

## Subphase 7.7a: Activity Chart Component

### Prompt for Claude Code:

```
Create the activity chart component with metric selection.

File: src/hub/components/ActivityChart.tsx

```typescript
import React, { useState, useEffect } from 'react';
import { getActivityChartData } from '@/shared/services/dashboard';
import type { TimePeriod, ChartMetric, ChartData } from '../types/dashboard';

interface ActivityChartProps {
  childId: string;
  period: TimePeriod;
}

export function ActivityChart({ childId, period }: ActivityChartProps) {
  const [metric, setMetric] = useState<ChartMetric>('games');
  const [chartData, setChartData] = useState<ChartData | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Load chart data when childId, period, or metric changes
  useEffect(() => {
    let cancelled = false;

    async function loadData() {
      setIsLoading(true);
      
      try {
        const data = await getActivityChartData(childId, metric, period);
        if (!cancelled) {
          setChartData(data);
        }
      } catch (err) {
        console.error('Failed to load chart data:', err);
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    }

    loadData();

    return () => {
      cancelled = true;
    };
  }, [childId, period, metric]);

  // Metric configuration
  const metrics: { key: ChartMetric; label: string; unit: string; color: string }[] = [
    { key: 'games', label: 'Games', unit: '', color: 'bg-accent-primary' },
    { key: 'time', label: 'Time', unit: 'min', color: 'bg-accent-secondary' },
    { key: 'accuracy', label: 'Accuracy', unit: '%', color: 'bg-green-500' },
    { key: 'coins', label: 'Coins', unit: '', color: 'bg-accent-tertiary' },
  ];

  const currentMetricConfig = metrics.find((m) => m.key === metric)!;

  // Calculate display values
  const maxValue = chartData?.maxValue || 1;
  const hasData = chartData?.points.some((p) => p.value > 0) || false;

  return (
    <div>
      {/* Metric Selector Tabs */}
      <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
        {metrics.map((m) => (
          <button
            key={m.key}
            onClick={() => setMetric(m.key)}
            className={`
              px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-all
              ${metric === m.key
                ? `${m.color} text-black`
                : 'bg-background-dark text-text-secondary hover:bg-background-light'
              }
            `}
          >
            {m.label}
          </button>
        ))}
      </div>

      {/* Loading State */}
      {isLoading && (
        <div className="h-48 flex items-center justify-center">
          <div className="text-text-secondary animate-pulse">Loading chart...</div>
        </div>
      )}

      {/* Chart */}
      {!isLoading && chartData && (
        <>
          {/* Summary Stats */}
          <div className="flex justify-between items-center mb-4 text-sm">
            <div className="text-text-secondary">
              Total: <span className="font-bold text-white">
                {chartData.total}{currentMetricConfig.unit}
              </span>
            </div>
            <div className="text-text-secondary">
              Average: <span className="font-bold text-white">
                {chartData.average}{currentMetricConfig.unit}/day
              </span>
            </div>
          </div>

          {/* Bar Chart */}
          <div className="relative h-48">
            {!hasData ? (
              /* No Data State */
              <div className="absolute inset-0 flex items-center justify-center">
                <p className="text-text-secondary">No activity for this period</p>
              </div>
            ) : (
              /* Bars */
              <div className="h-full flex items-end gap-1">
                {chartData.points.map((point, index) => {
                  const heightPercent = maxValue > 0 
                    ? (point.value / maxValue) * 100 
                    : 0;
                  
                  // Ensure minimum visible height if there's any value
                  const displayHeight = point.value > 0 
                    ? Math.max(heightPercent, 8) 
                    : 0;

                  return (
                    <div
                      key={point.date}
                      className="flex-1 flex flex-col items-center justify-end h-full"
                    >
                      {/* Value Label (only show if non-zero and enough space) */}
                      {point.value > 0 && (
                        <span className="text-xs text-text-secondary mb-1 tabular-nums">
                          {point.value}
                          {metric === 'accuracy' && '%'}
                        </span>
                      )}

                      {/* Bar */}
                      <div
                        className={`
                          w-full rounded-t-sm transition-all duration-300 ease-out
                          ${currentMetricConfig.color}
                          ${point.value === 0 ? 'bg-background-light' : ''}
                        `}
                        style={{ 
                          height: point.value > 0 ? `${displayHeight}%` : '2px',
                          minHeight: point.value > 0 ? '8px' : '2px',
                        }}
                        title={`${point.dateLabel}: ${point.value}${currentMetricConfig.unit}`}
                      />

                      {/* Date Label */}
                      <span className="text-xs text-text-secondary mt-2 truncate w-full text-center">
                        {point.dateLabel}
                      </span>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Y-axis reference line (optional) */}
          {hasData && (
            <div className="flex justify-between text-xs text-text-secondary mt-2 px-1">
              <span>0</span>
              <span>{maxValue}{currentMetricConfig.unit}</span>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default ActivityChart;
```

Export ActivityChart component.
```

---

## Subphase 7.7b: Activity History Screen

### Prompt for Claude Code:

```
Create the full activity history screen.

File: src/hub/screens/ActivityHistoryScreen.tsx

```typescript
import React, { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@/app/providers/AuthProvider';
import { Card } from '@/ui';
import { Header } from '../components';
import { 
  getActivityHistory, 
  groupActivitiesByDate 
} from '@/shared/services/dashboard';
import { formatTimeOfDay, formatDuration } from '@/shared/utils/formatters';
import type { ActivityEntry, ActivityGroup, TimePeriod } from '../types/dashboard';

export function ActivityHistoryScreen() {
  const { childId } = useParams<{ childId: string }>();
  const navigate = useNavigate();
  const { children } = useAuth();

  // Find child
  const child = children.find((c) => c.id === childId);

  // State
  const [activities, setActivities] = useState<ActivityEntry[]>([]);
  const [groupedActivities, setGroupedActivities] = useState<ActivityGroup[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [period, setPeriod] = useState<TimePeriod>('week');

  // Load activities
  const loadActivities = useCallback(async () => {
    if (!childId) return;

    setIsLoading(true);

    try {
      const data = await getActivityHistory(childId, period, 100);
      setActivities(data);
      setGroupedActivities(groupActivitiesByDate(data));
    } catch (err) {
      console.error('Failed to load activity history:', err);
    } finally {
      setIsLoading(false);
    }
  }, [childId, period]);

  useEffect(() => {
    loadActivities();
  }, [loadActivities]);

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
  );

  const periodAccuracy = periodTotals.total > 0
    ? Math.round((periodTotals.correct / periodTotals.total) * 100)
    : 0;

  // Child not found
  if (!child) {
    return (
      <div className="min-h-screen flex flex-col bg-background-dark">
        <Header title="Activity History" showBack />
        <main className="flex-1 flex items-center justify-center">
          <p className="text-text-secondary">Child not found</p>
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      {/* Header */}
      <Header 
        title={`${child.displayName}'s Activity`} 
        showBack 
      />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-2xl mx-auto">

          {/* Period Filter Pills */}
          <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
            {([
              { key: 'today', label: 'Today' },
              { key: 'week', label: 'This Week' },
              { key: 'month', label: 'This Month' },
              { key: 'all', label: 'All Time' },
            ] as { key: TimePeriod; label: string }[]).map((p) => (
              <button
                key={p.key}
                onClick={() => setPeriod(p.key)}
                className={`
                  px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all
                  ${period === p.key
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
              <p className="text-text-secondary">
                No play sessions recorded for this period.
              </p>
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
  );
}

// ============================================
// Activity Card Component
// ============================================

interface ActivityCardProps {
  activity: ActivityEntry;
}

function ActivityCard({ activity }: ActivityCardProps) {
  const time = formatTimeOfDay(activity.date);

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
            <span className="text-text-secondary">
              {formatDuration(activity.duration)}
            </span>
            <span className={activity.accuracy >= 80 ? 'text-accent-primary' : 'text-text-secondary'}>
              {activity.accuracy}% accuracy
            </span>
          </div>

          {/* Correct/Mistakes breakdown */}
          <div className="flex gap-3 mt-1 text-xs">
            <span className="text-green-400">
              ✓ {activity.correctAnswers} correct
            </span>
            {activity.mistakes > 0 && (
              <span className="text-error">
                ✗ {activity.mistakes} mistakes
              </span>
            )}
          </div>
        </div>

        {/* Coins Earned */}
        <div className="text-right flex-shrink-0">
          <div className={`font-bold ${activity.coinsEarned > 0 ? 'text-accent-tertiary' : 'text-text-secondary'}`}>
            {activity.coinsEarned > 0 ? `+${activity.coinsEarned}` : '0'}
          </div>
          <div className="text-xs text-text-secondary">coins</div>
        </div>
      </div>
    </Card>
  );
}

export default ActivityHistoryScreen;
```

Export ActivityHistoryScreen component.
```

---

## Phase 7.2 Completion Checklist

After completing all subphases, verify:

- [ ] getActivityHistory returns correctly formatted entries
- [ ] groupActivitiesByDate groups by date with totals
- [ ] getActivityChartData returns daily aggregated points
- [ ] Chart shows all days in period (including zeros)
- [ ] Child detail screen loads all statistics
- [ ] Quick stat cards display correctly
- [ ] Activity chart renders with metric selection
- [ ] Chart metric tabs switch correctly (games/time/accuracy/coins)
- [ ] Chart handles empty data gracefully
- [ ] Module progress rows show win rate bar
- [ ] Remove child modal confirms before deletion
- [ ] Activity history screen loads with period filter
- [ ] Period pills filter correctly (today/week/month/all)
- [ ] Period summary shows totals
- [ ] Activities grouped by date with headers
- [ ] Activity cards show full breakdown

---

## Files Created/Modified in Phase 7.2

```
src/shared/services/
└── dashboard.ts (additions: getActivityHistory, groupActivitiesByDate, getActivityChartData)

src/hub/
├── screens/
│   ├── ChildDetailScreen.tsx
│   └── ActivityHistoryScreen.tsx
└── components/
    └── ActivityChart.tsx
```

---

## Screen Flow

```
[Parent Dashboard]
       │
       └── Click Child Card
              │
              ▼
       [Child Detail Screen]
              │
              ├── Activity Chart (embedded)
              │     └── Metric tabs: Games | Time | Accuracy | Coins
              │
              ├── Module Progress (embedded)
              │
              ├── View Full History ──► [Activity History Screen]
              │                               │
              │                               └── Period: Today | Week | Month | All
              │
              ├── Edit Display Name ──► [Edit Child Screen] (Phase 7.3)
              │
              ├── Reset PIN ──► [Reset PIN Screen] (Phase 7.3)
              │
              └── Remove Child ──► Confirmation Modal ──► Delete
```

---

*End of Phase 7.2*
