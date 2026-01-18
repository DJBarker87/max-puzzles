interface TimerDisplayProps {
  elapsedMs: number
  thresholdMs?: number
  isRunning: boolean
  size?: 'sm' | 'md' | 'lg'
  className?: string
}

const sizes = {
  sm: 'text-lg',
  md: 'text-2xl',
  lg: 'text-3xl',
}

function formatTime(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000)
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}

/**
 * Timer display with color coding based on threshold
 */
export default function TimerDisplay({
  elapsedMs,
  thresholdMs,
  isRunning,
  size = 'md',
  className = '',
}: TimerDisplayProps) {
  const getTimerColor = (): string => {
    if (!thresholdMs) return 'text-white'

    const ratio = elapsedMs / thresholdMs

    if (ratio < 0.7) return 'text-accent-primary'
    if (ratio < 1.0) return 'text-yellow-400'
    return 'text-text-secondary'
  }

  return (
    <div
      className={`
        font-mono font-bold tabular-nums
        ${sizes[size]}
        ${getTimerColor()}
        ${isRunning ? '' : 'opacity-70'}
        transition-colors duration-300
        ${className}
      `}
      role="timer"
      aria-label={`Time elapsed: ${formatTime(elapsedMs)}`}
    >
      {formatTime(elapsedMs)}
    </div>
  )
}
