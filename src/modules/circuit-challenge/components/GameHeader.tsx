import { Button } from '@/ui'
import LivesDisplay from './LivesDisplay'
import TimerDisplay from './TimerDisplay'
import GameCoinDisplay from './GameCoinDisplay'
import { MusicToggleButton } from './MusicToggleButton'

interface GameHeaderProps {
  title?: string
  lives: number
  maxLives?: number
  elapsedMs: number
  isTimerRunning: boolean
  timeThresholdMs?: number
  coins: number
  coinChange?: { value: number; type: 'earn' | 'penalty' }
  isHiddenMode: boolean
  onBackClick: () => void
  className?: string
}

/**
 * Game header with all status displays
 */
export default function GameHeader({
  title,
  lives,
  maxLives = 5,
  elapsedMs,
  isTimerRunning,
  timeThresholdMs,
  coins,
  coinChange,
  isHiddenMode,
  onBackClick,
  className = '',
}: GameHeaderProps) {
  return (
    <header
      className={`
        flex flex-wrap items-center justify-between
        px-4 md:px-8 py-4
        bg-gradient-to-b from-black/50 to-transparent
        ${className}
      `}
    >
      {/* Left section: Back + Music + Title */}
      <div className="flex items-center gap-4">
        <Button
          variant="ghost"
          size="sm"
          onClick={onBackClick}
          className="w-11 h-11 rounded-xl !p-0 flex items-center justify-center"
          aria-label="Go back"
        >
          <span className="text-xl">←</span>
        </Button>

        <MusicToggleButton size="sm" />

        {title && (
          <h1 className="text-xl md:text-2xl font-display font-bold text-white">
            {title}
          </h1>
        )}
      </div>

      {/* Right section: Status displays */}
      <div className="flex items-center gap-4 md:gap-6">
        {!isHiddenMode && (
          <LivesDisplay
            lives={lives}
            maxLives={maxLives}
            size="md"
            className="hidden md:flex"
          />
        )}

        <TimerDisplay
          elapsedMs={elapsedMs}
          thresholdMs={isHiddenMode ? undefined : timeThresholdMs}
          isRunning={isTimerRunning}
          size="md"
        />

        <GameCoinDisplay
          amount={coins}
          showChange={isHiddenMode ? undefined : coinChange}
          size="md"
        />
      </div>

      {/* Mobile-only second row for lives */}
      {!isHiddenMode && (
        <div className="w-full flex justify-center mt-2 md:hidden">
          <LivesDisplay
            lives={lives}
            maxLives={maxLives}
            size="sm"
          />
        </div>
      )}
    </header>
  )
}
