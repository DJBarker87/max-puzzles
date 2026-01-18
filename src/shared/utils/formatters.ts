/**
 * Format a time in milliseconds to a display string (MM:SS or H:MM:SS)
 */
export function formatTime(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000)
  const hours = Math.floor(totalSeconds / 3600)
  const minutes = Math.floor((totalSeconds % 3600) / 60)
  const seconds = totalSeconds % 60

  const pad = (n: number) => n.toString().padStart(2, '0')

  if (hours > 0) {
    return `${hours}:${pad(minutes)}:${pad(seconds)}`
  }

  return `${minutes}:${pad(seconds)}`
}

/**
 * Format a number with commas (e.g., 1,234)
 */
export function formatNumber(num: number): string {
  return num.toLocaleString('en-GB')
}

/**
 * Format seconds as a human-readable duration.
 * e.g., "5m", "1h 30m", "2h"
 */
export function formatDuration(seconds: number): string {
  if (seconds < 60) {
    return '<1m'
  }

  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)

  if (hours === 0) {
    return `${minutes}m`
  }

  if (minutes === 0) {
    return `${hours}h`
  }

  return `${hours}h ${minutes}m`
}

/**
 * Formats an ISO timestamp as a relative time string.
 * e.g., "just now", "5m ago", "2h ago", "yesterday", "3 days ago"
 * Accepts both ISO string and Date object.
 */
export function formatRelativeTime(input: string | Date): string {
  const date = typeof input === 'string' ? new Date(input) : input
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()

  const diffSeconds = Math.floor(diffMs / 1000)
  const diffMinutes = Math.floor(diffMs / (1000 * 60))
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

  if (diffSeconds < 60) {
    return 'just now'
  }

  if (diffMinutes < 60) {
    return `${diffMinutes}m ago`
  }

  if (diffHours < 24) {
    return `${diffHours}h ago`
  }

  if (diffDays === 1) {
    return 'yesterday'
  }

  if (diffDays < 7) {
    return `${diffDays} days ago`
  }

  if (diffDays < 30) {
    const weeks = Math.floor(diffDays / 7)
    return weeks === 1 ? '1 week ago' : `${weeks} weeks ago`
  }

  // Older than a month - show actual date
  return formatShortDate(date)
}

/**
 * Formats a date as "15 Jan 2025".
 */
export function formatDate(input: string | Date): string {
  const date = typeof input === 'string' ? new Date(input) : input
  return date.toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

/**
 * Formats a date as "15 Jan" (no year).
 */
export function formatShortDate(input: string | Date): string {
  const date = typeof input === 'string' ? new Date(input) : input
  return date.toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
  })
}

/**
 * Formats a date as "Monday, 15 January".
 */
export function formatLongDate(input: string | Date): string {
  const date = typeof input === 'string' ? new Date(input) : input
  return date.toLocaleDateString('en-GB', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  })
}

/**
 * Formats a date as "Mon" (short weekday).
 */
export function formatWeekday(input: string | Date): string {
  const date = typeof input === 'string' ? new Date(input) : input
  return date.toLocaleDateString('en-GB', {
    weekday: 'short',
  })
}

/**
 * Formats a time as "14:30".
 */
export function formatTimeOfDay(input: string | Date): string {
  const date = typeof input === 'string' ? new Date(input) : input
  return date.toLocaleTimeString('en-GB', {
    hour: '2-digit',
    minute: '2-digit',
  })
}

/**
 * Formats a percentage (0-100 input, returns "85%").
 */
export function formatPercentage(value: number): string {
  return `${Math.round(value)}%`
}

/**
 * Format a level ID (e.g., "1-A", "2-B")
 */
export function formatLevelId(level: number, sublevel: 'A' | 'B' | 'C'): string {
  return `${level}-${sublevel}`
}

/**
 * Parse a level ID back to its components
 */
export function parseLevelId(levelId: string): { level: number; sublevel: 'A' | 'B' | 'C' } | null {
  const match = levelId.match(/^(\d+)-([ABC])$/)
  if (!match) return null
  return {
    level: parseInt(match[1], 10),
    sublevel: match[2] as 'A' | 'B' | 'C',
  }
}
