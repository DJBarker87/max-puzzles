# Phase 7.1: Parent Dashboard - Types, Service & Overview

**Goal:** Create the data layer for the parent dashboard - types, Supabase queries, and the main dashboard screen with child summary cards.

---

## Subphase 7.1: Parent Dashboard Types

### Prompt for Claude Code:

```
Create comprehensive types for the parent dashboard data structures.

File: src/hub/types/dashboard.ts

1. Child summary for dashboard overview:

```typescript
/**
 * Summary data for a child displayed on the parent dashboard.
 * Shows key metrics for the current week plus lifetime coins.
 */
export interface ChildSummary {
  id: string;
  displayName: string;
  avatarConfig: AvatarConfig | null; // V3 - for now just null
  coins: number; // Lifetime total
  lastPlayedAt: string | null; // ISO timestamp
  
  thisWeekStats: {
    gamesPlayed: number;
    timePlayedMinutes: number;
    coinsEarned: number;
    accuracy: number; // 0-100 percentage
  };
}

/**
 * Placeholder for V3 avatar customisation.
 */
export interface AvatarConfig {
  baseColor: string;
  accessories: string[];
  expression: string;
}
```

2. Detailed child statistics:

```typescript
/**
 * Comprehensive statistics for a single child.
 * Used on the child detail screen.
 */
export interface ChildDetailStats {
  // Lifetime totals
  totalGamesPlayed: number;
  totalTimePlayed: number; // In seconds
  totalCoinsEarned: number;
  overallAccuracy: number; // 0-100 percentage
  
  // Streaks
  currentStreak: number; // Consecutive wins
  bestStreak: number;
  
  // Account info
  memberSince: string; // ISO timestamp
  
  // Per-module breakdown
  moduleStats: Record<string, ModuleStats>;
}

/**
 * Statistics for a specific puzzle module.
 */
export interface ModuleStats {
  moduleId: string;
  moduleName: string;
  
  // Activity counts
  gamesPlayed: number;
  gamesWon: number;
  timePlayed: number; // Seconds
  coinsEarned: number;
  accuracy: number; // 0-100
  
  // Recency
  lastPlayedAt: string | null;
  
  // Circuit Challenge specific (for progression - V2)
  levelsCompleted?: number;
  totalLevels?: number;
  totalStars?: number;
  maxStars?: number;
  
  // Difficulty breakdown for Quick Play
  difficultyStats?: Record<number, DifficultyLevelStats>;
}

/**
 * Stats for a specific difficulty level.
 */
export interface DifficultyLevelStats {
  levelNumber: number;
  levelName: string;
  played: number;
  won: number;
  winRate: number; // 0-100
  bestTimeMs: number | null;
  averageTimeMs: number | null;
}
```

3. Activity log types:

```typescript
/**
 * A single activity session entry.
 * Represents one play session from start to end.
 */
export interface ActivityEntry {
  id: string;
  moduleId: string;
  moduleName: string;
  moduleIcon: string;
  
  // Timing
  date: string; // ISO timestamp of session start
  duration: number; // Seconds
  
  // Performance
  gamesPlayed: number;
  correctAnswers: number;
  mistakes: number;
  accuracy: number; // 0-100
  
  // Rewards
  coinsEarned: number;
}

/**
 * Activities grouped by date for display.
 */
export interface ActivityGroup {
  dateLabel: string; // e.g., "Monday, 15 January"
  activities: ActivityEntry[];
  totalGames: number;
  totalTime: number;
  totalCoins: number;
}
```

4. Filter and chart types:

```typescript
/**
 * Time period options for filtering activity data.
 */
export type TimePeriod = 'today' | 'week' | 'month' | 'all';

/**
 * Metric options for activity charts.
 */
export type ChartMetric = 'games' | 'time' | 'accuracy' | 'coins';

/**
 * A single data point for charts.
 */
export interface ChartDataPoint {
  date: string; // YYYY-MM-DD
  dateLabel: string; // e.g., "Mon", "15 Jan"
  value: number;
}

/**
 * Complete chart data with metadata.
 */
export interface ChartData {
  metric: ChartMetric;
  period: TimePeriod;
  points: ChartDataPoint[];
  maxValue: number;
  total: number;
  average: number;
}
```

5. Module metadata helper:

```typescript
/**
 * Static metadata for puzzle modules.
 */
export const MODULE_METADATA: Record<string, { name: string; icon: string }> = {
  'circuit-challenge': {
    name: 'Circuit Challenge',
    icon: '⚡',
  },
  // Add more modules here as they're created
};

export function getModuleMeta(moduleId: string): { name: string; icon: string } {
  return MODULE_METADATA[moduleId] || { name: moduleId, icon: '🧩' };
}
```

Export all types and helpers.
```

---

## Subphase 7.2: Dashboard Data Service

### Prompt for Claude Code:

```
Create the service for fetching and computing parent dashboard data.

File: src/shared/services/dashboard.ts

Import:
- supabase from './supabase'
- All types from '@/hub/types/dashboard'

```typescript
import { supabase } from './supabase';
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
} from '@/hub/types/dashboard';
import { getModuleMeta } from '@/hub/types/dashboard';

// ============================================
// FAMILY OVERVIEW
// ============================================

/**
 * Fetches summary data for all children in a family.
 * Used on the main parent dashboard.
 */
export async function getChildrenSummaries(
  familyId: string
): Promise<ChildSummary[]> {
  if (!supabase) {
    console.warn('Supabase not configured, returning empty summaries');
    return [];
  }

  // 1. Fetch all active children in the family
  const { data: children, error: childError } = await supabase
    .from('users')
    .select('id, display_name, coins, created_at')
    .eq('family_id', familyId)
    .eq('role', 'child')
    .eq('is_active', true)
    .order('created_at', { ascending: true });

  if (childError) {
    console.error('Error fetching children:', childError);
    return [];
  }

  if (!children || children.length === 0) {
    return [];
  }

  // 2. Calculate the start of "this week" (Monday 00:00:00)
  const weekStart = getStartOfWeek(new Date());

  // 3. Build summaries for each child
  const summaries: ChildSummary[] = await Promise.all(
    children.map(async (child) => {
      // Fetch this week's activity
      const weekStats = await getChildWeekStats(child.id, weekStart);
      
      // Fetch last played timestamp
      const lastPlayedAt = await getChildLastPlayed(child.id);

      return {
        id: child.id,
        displayName: child.display_name,
        avatarConfig: null, // V3
        coins: child.coins || 0,
        lastPlayedAt,
        thisWeekStats: weekStats,
      };
    })
  );

  return summaries;
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
  };

  if (!supabase) return defaultStats;

  const { data, error } = await supabase
    .from('activity_log')
    .select('games_played, duration_seconds, coins_earned, correct_answers, mistakes')
    .eq('user_id', childId)
    .gte('session_start', since.toISOString());

  if (error || !data || data.length === 0) {
    return defaultStats;
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
  );

  return {
    gamesPlayed: totals.games,
    timePlayedMinutes: Math.round(totals.seconds / 60),
    coinsEarned: totals.coins,
    accuracy: totals.total > 0 
      ? Math.round((totals.correct / totals.total) * 100) 
      : 0,
  };
}

/**
 * Gets the most recent play session timestamp for a child.
 */
async function getChildLastPlayed(childId: string): Promise<string | null> {
  if (!supabase) return null;

  const { data, error } = await supabase
    .from('activity_log')
    .select('session_start')
    .eq('user_id', childId)
    .order('session_start', { ascending: false })
    .limit(1)
    .single();

  if (error || !data) return null;
  return data.session_start;
}

// ============================================
// CHILD DETAIL STATS
// ============================================

/**
 * Fetches comprehensive statistics for a single child.
 * Used on the child detail screen.
 */
export async function getChildDetailStats(
  childId: string
): Promise<ChildDetailStats | null> {
  if (!supabase) return null;

  // 1. Get user creation date
  const { data: user, error: userError } = await supabase
    .from('users')
    .select('created_at')
    .eq('id', childId)
    .single();

  if (userError || !user) {
    console.error('Error fetching user:', userError);
    return null;
  }

  // 2. Get all activity logs for this child
  const { data: activities, error: actError } = await supabase
    .from('activity_log')
    .select('*')
    .eq('user_id', childId)
    .order('session_start', { ascending: false });

  if (actError) {
    console.error('Error fetching activities:', actError);
  }

  // 3. Get module progress data
  const { data: progressRecords, error: progError } = await supabase
    .from('module_progress')
    .select('*')
    .eq('user_id', childId);

  if (progError) {
    console.error('Error fetching progress:', progError);
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
  );

  // 5. Build per-module stats
  const moduleStats = buildModuleStats(activities || [], progressRecords || []);

  // 6. Extract streak data from Circuit Challenge progress
  const ccProgress = progressRecords?.find(p => p.module_id === 'circuit-challenge');
  const ccData = ccProgress?.data as any;
  const currentStreak = ccData?.quickPlay?.currentStreak || 0;
  const bestStreak = ccData?.quickPlay?.bestStreak || 0;

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
  };
}

/**
 * Builds per-module statistics from activity logs and progress records.
 */
function buildModuleStats(
  activities: any[],
  progressRecords: any[]
): Record<string, ModuleStats> {
  const stats: Record<string, ModuleStats> = {};

  // Group activities by module
  const actByModule: Record<string, any[]> = {};
  for (const act of activities) {
    const mid = act.module_id;
    if (!actByModule[mid]) actByModule[mid] = [];
    actByModule[mid].push(act);
  }

  // Build stats for each module
  for (const [moduleId, moduleActs] of Object.entries(actByModule)) {
    const meta = getModuleMeta(moduleId);
    
    // Aggregate activity data
    const totals = moduleActs.reduce(
      (acc, a) => ({
        games: acc.games + (a.games_played || 0),
        time: acc.time + (a.duration_seconds || 0),
        coins: acc.coins + (a.coins_earned || 0),
        correct: acc.correct + (a.correct_answers || 0),
        mistakes: acc.mistakes + (a.mistakes || 0),
      }),
      { games: 0, time: 0, coins: 0, correct: 0, mistakes: 0 }
    );

    // Find corresponding progress record
    const progress = progressRecords.find(p => p.module_id === moduleId);
    const progressData = progress?.data as any;

    // Get wins from progress data
    const gamesWon = progressData?.quickPlay?.gamesWon || 0;

    // Get last played from most recent activity
    const sortedActs = [...moduleActs].sort(
      (a, b) => new Date(b.session_start).getTime() - new Date(a.session_start).getTime()
    );
    const lastPlayedAt = sortedActs[0]?.session_start || null;

    // Build difficulty stats if available
    const difficultyStats = progressData?.quickPlay?.difficultyStats
      ? buildDifficultyStats(progressData.quickPlay.difficultyStats)
      : undefined;

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
    };
  }

  return stats;
}

/**
 * Transforms raw difficulty stats into typed format.
 */
function buildDifficultyStats(
  raw: Record<number, any>
): Record<number, import('@/hub/types/dashboard').DifficultyLevelStats> {
  const result: Record<number, any> = {};

  for (const [level, data] of Object.entries(raw)) {
    const levelNum = Number(level);
    result[levelNum] = {
      levelNumber: levelNum,
      levelName: `Level ${levelNum + 1}`,
      played: data.played || 0,
      won: data.won || 0,
      winRate: data.played > 0 ? Math.round((data.won / data.played) * 100) : 0,
      bestTimeMs: data.bestTimeMs || null,
      averageTimeMs: null, // Not tracked currently
    };
  }

  return result;
}

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Gets the start of the current week (Monday 00:00:00).
 */
function getStartOfWeek(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1); // Adjust for Sunday
  d.setDate(diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

/**
 * Gets the start of today (00:00:00).
 */
function getStartOfDay(date: Date): Date {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

/**
 * Gets a date N days ago.
 */
function getDaysAgo(days: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - days);
  d.setHours(0, 0, 0, 0);
  return d;
}

export { getStartOfWeek, getStartOfDay, getDaysAgo };
```

Export all functions.
```

---

## Subphase 7.3: Parent Dashboard Screen

### Prompt for Claude Code:

```
Create the main parent dashboard screen showing all children.

File: src/hub/screens/ParentDashboard.tsx

Import:
- useState, useEffect, useCallback from 'react'
- useNavigate from 'react-router-dom'
- useAuth from '@/app/providers/AuthProvider'
- Button, Card from '@/ui'
- Header from '../components'
- ChildSummaryCard from '../components/ChildSummaryCard'
- getChildrenSummaries from '@/shared/services/dashboard'
- ChildSummary from '../types/dashboard'

```typescript
import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/app/providers/AuthProvider';
import { Button, Card } from '@/ui';
import { Header } from '../components';
import { ChildSummaryCard } from '../components/ChildSummaryCard';
import { getChildrenSummaries } from '@/shared/services/dashboard';
import type { ChildSummary } from '../types/dashboard';

export function ParentDashboard() {
  const navigate = useNavigate();
  const { family } = useAuth();

  // State
  const [summaries, setSummaries] = useState<ChildSummary[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Load children summaries
  const loadSummaries = useCallback(async () => {
    if (!family?.id) {
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const data = await getChildrenSummaries(family.id);
      setSummaries(data);
    } catch (err) {
      console.error('Failed to load children summaries:', err);
      setError('Failed to load data. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }, [family?.id]);

  // Load on mount and when family changes
  useEffect(() => {
    loadSummaries();
  }, [loadSummaries]);

  // Calculate family totals for header
  const familyTotals = summaries.reduce(
    (acc, child) => ({
      totalCoins: acc.totalCoins + child.coins,
      weekGames: acc.weekGames + child.thisWeekStats.gamesPlayed,
      weekTime: acc.weekTime + child.thisWeekStats.timePlayedMinutes,
    }),
    { totalCoins: 0, weekGames: 0, weekTime: 0 }
  );

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
                Add a child to start tracking their maths puzzle progress. 
                Each child gets their own profile with a simple PIN for login.
              </p>
              <Button
                variant="primary"
                size="lg"
                onClick={() => navigate('/parent/add-child')}
              >
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
              <Button
                variant="secondary"
                fullWidth
                onClick={() => navigate('/parent/add-child')}
              >
                + Add Child
              </Button>
            )}

            <Button
              variant="ghost"
              fullWidth
              onClick={() => navigate('/parent/settings')}
            >
              ⚙️ Family Settings
            </Button>

            <Button
              variant="ghost"
              fullWidth
              onClick={() => navigate('/family-select')}
            >
              ← Back to Family Select
            </Button>
          </div>

        </div>
      </main>
    </div>
  );
}
```

Export ParentDashboard component.
```

---

## Subphase 7.4: Child Summary Card Component

### Prompt for Claude Code:

```
Create the child summary card component for the dashboard.

File: src/hub/components/ChildSummaryCard.tsx

Import:
- Card from '@/ui'
- ChildSummary from '../types/dashboard'
- formatRelativeTime from '@/shared/utils/formatters'

```typescript
import React from 'react';
import { Card } from '@/ui';
import type { ChildSummary } from '../types/dashboard';
import { formatRelativeTime } from '@/shared/utils/formatters';

interface ChildSummaryCardProps {
  summary: ChildSummary;
  onClick: () => void;
}

export function ChildSummaryCard({ summary, onClick }: ChildSummaryCardProps) {
  const { thisWeekStats } = summary;
  
  // Determine activity status for visual indicator
  const hasPlayedThisWeek = thisWeekStats.gamesPlayed > 0;
  const hasPlayedRecently = summary.lastPlayedAt && 
    (Date.now() - new Date(summary.lastPlayedAt).getTime()) < 24 * 60 * 60 * 1000;

  return (
    <Card
      variant="interactive"
      className="p-4 hover:border-accent-primary/50 transition-colors"
      onClick={onClick}
    >
      <div className="flex items-center gap-4">
        
        {/* Avatar */}
        <div className="relative">
          <div className="text-5xl">
            👽
          </div>
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
          <h3 className="text-lg font-bold truncate">
            {summary.displayName}
          </h3>

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
        <div className="text-2xl text-text-secondary flex-shrink-0">
          →
        </div>
      </div>

      {/* No activity this week banner */}
      {!hasPlayedThisWeek && summary.lastPlayedAt && (
        <div className="mt-3 pt-3 border-t border-white/5">
          <p className="text-sm text-text-secondary text-center">
            💤 No activity this week
          </p>
        </div>
      )}
    </Card>
  );
}

/**
 * Small stat badge component for the week stats row.
 */
interface StatBadgeProps {
  icon: string;
  value: string | number;
  label: string;
  color: string;
  highlight?: boolean;
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
  );
}
```

Export ChildSummaryCard component.
```

---

## Subphase 7.4b: Formatter Utilities

### Prompt for Claude Code:

```
Create shared formatter utility functions.

File: src/shared/utils/formatters.ts

```typescript
/**
 * Formats an ISO timestamp as a relative time string.
 * e.g., "just now", "5m ago", "2h ago", "yesterday", "3 days ago"
 */
export function formatRelativeTime(isoString: string): string {
  const date = new Date(isoString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  
  const diffSeconds = Math.floor(diffMs / 1000);
  const diffMinutes = Math.floor(diffMs / (1000 * 60));
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  if (diffSeconds < 60) {
    return 'just now';
  }
  
  if (diffMinutes < 60) {
    return `${diffMinutes}m ago`;
  }
  
  if (diffHours < 24) {
    return `${diffHours}h ago`;
  }
  
  if (diffDays === 1) {
    return 'yesterday';
  }
  
  if (diffDays < 7) {
    return `${diffDays} days ago`;
  }
  
  if (diffDays < 30) {
    const weeks = Math.floor(diffDays / 7);
    return weeks === 1 ? '1 week ago' : `${weeks} weeks ago`;
  }

  // Older than a month - show actual date
  return formatShortDate(isoString);
}

/**
 * Formats seconds as a human-readable duration.
 * e.g., "5m", "1h 30m", "2h"
 */
export function formatDuration(seconds: number): string {
  if (seconds < 60) {
    return '<1m';
  }

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);

  if (hours === 0) {
    return `${minutes}m`;
  }

  if (minutes === 0) {
    return `${hours}h`;
  }

  return `${hours}h ${minutes}m`;
}

/**
 * Formats milliseconds as MM:SS or H:MM:SS.
 */
export function formatTime(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  const pad = (n: number) => n.toString().padStart(2, '0');

  if (hours > 0) {
    return `${hours}:${pad(minutes)}:${pad(seconds)}`;
  }

  return `${minutes}:${pad(seconds)}`;
}

/**
 * Formats a date as "15 Jan 2025".
 */
export function formatDate(isoString: string): string {
  return new Date(isoString).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
}

/**
 * Formats a date as "15 Jan" (no year).
 */
export function formatShortDate(isoString: string): string {
  return new Date(isoString).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
  });
}

/**
 * Formats a date as "Monday, 15 January".
 */
export function formatLongDate(isoString: string): string {
  return new Date(isoString).toLocaleDateString('en-GB', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  });
}

/**
 * Formats a date as "Mon" (short weekday).
 */
export function formatWeekday(isoString: string): string {
  return new Date(isoString).toLocaleDateString('en-GB', {
    weekday: 'short',
  });
}

/**
 * Formats a time as "14:30".
 */
export function formatTimeOfDay(isoString: string): string {
  return new Date(isoString).toLocaleTimeString('en-GB', {
    hour: '2-digit',
    minute: '2-digit',
  });
}

/**
 * Formats a number with thousands separators.
 */
export function formatNumber(n: number): string {
  return n.toLocaleString('en-GB');
}

/**
 * Formats a percentage (0-100 input, returns "85%").
 */
export function formatPercentage(value: number): string {
  return `${Math.round(value)}%`;
}
```

Export all functions.
```

---

## Phase 7.1 Completion Checklist

After completing all subphases, verify:

- [ ] Dashboard types compile without errors
- [ ] getChildrenSummaries returns correct data structure
- [ ] getChildDetailStats returns correct data structure  
- [ ] Parent dashboard loads and displays family info
- [ ] Loading state shows while fetching data
- [ ] Empty state shows when no children
- [ ] Error state shows when fetch fails
- [ ] Child summary cards display all stats
- [ ] Week stats show games, coins, time, accuracy
- [ ] Last played shows relative time
- [ ] Activity indicator shows for recent play
- [ ] Clicking a card navigates to child detail
- [ ] Add Child button appears (when under limit)
- [ ] Family Settings button works

---

## Files Created in Phase 7.1

```
src/hub/
├── types/
│   └── dashboard.ts
├── screens/
│   └── ParentDashboard.tsx
└── components/
    └── ChildSummaryCard.tsx

src/shared/
├── services/
│   └── dashboard.ts
└── utils/
    └── formatters.ts
```

---

*End of Phase 7.1*
