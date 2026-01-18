/**
 * Format a time in milliseconds to a display string (MM:SS)
 */
export function formatTime(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000)
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}

/**
 * Format a number with commas (e.g., 1,234)
 */
export function formatNumber(num: number): string {
  return num.toLocaleString()
}

/**
 * Format a date as a relative time string
 */
export function formatRelativeTime(date: Date): string {
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffSecs = Math.floor(diffMs / 1000)
  const diffMins = Math.floor(diffSecs / 60)
  const diffHours = Math.floor(diffMins / 60)
  const diffDays = Math.floor(diffHours / 24)

  if (diffSecs < 60) return 'just now'
  if (diffMins < 60) return `${diffMins}m ago`
  if (diffHours < 24) return `${diffHours}h ago`
  if (diffDays < 7) return `${diffDays}d ago`
  return date.toLocaleDateString()
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
