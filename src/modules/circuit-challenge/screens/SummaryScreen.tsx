import { useLocation, useNavigate } from 'react-router-dom'
import { Button, Card } from '@/ui'
import { StarryBackground } from '../components'
import type { Puzzle } from '../types'
import type { DifficultySettings } from '../engine/types'
import type { GameMoveResult, HiddenModeResults } from '../types/gameState'

interface SummaryData {
  won: boolean
  isHiddenMode: boolean
  elapsedMs: number
  puzzleCoins: number
  moveHistory: GameMoveResult[]
  hiddenModeResults?: HiddenModeResults
  difficulty: DifficultySettings
  puzzle: Puzzle
}

/**
 * Format milliseconds to MM:SS display
 */
function formatTime(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000)
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}

/**
 * Summary screen shown after completing or losing a puzzle
 */
export default function SummaryScreen() {
  const location = useLocation()
  const navigate = useNavigate()
  const data = location.state as SummaryData | null

  // Redirect if no data
  if (!data) {
    navigate('/play/circuit-challenge')
    return null
  }

  // Calculate statistics
  const totalMoves = data.moveHistory.length
  const correctMoves = data.moveHistory.filter((m) => m.correct).length
  const mistakes = totalMoves - correctMoves
  const accuracy = totalMoves > 0 ? Math.round((correctMoves / totalMoves) * 100) : 0
  const timeFormatted = formatTime(data.elapsedMs)

  const handlePlayAgain = () => {
    navigate('/play/circuit-challenge/game', {
      state: { difficulty: data.difficulty },
    })
  }

  const handleChangeDifficulty = () => {
    navigate('/play/circuit-challenge/quick')
  }

  const handleExit = () => {
    navigate('/play/circuit-challenge')
  }

  const handleViewSolution = () => {
    navigate('/play/circuit-challenge/game', {
      state: {
        difficulty: data.difficulty,
        showSolution: true,
      },
    })
  }

  // Hidden mode win
  if (data.isHiddenMode && data.hiddenModeResults) {
    const { correctCount, mistakeCount } = data.hiddenModeResults

    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-4 relative">
        <StarryBackground />

        <Card className="w-full max-w-md text-center relative z-10 p-6">
          <h1 className="text-2xl font-display font-bold mb-4">
            Puzzle Complete!
          </h1>

          <h2 className="text-lg font-medium mb-4">Results:</h2>

          <div className="space-y-3 mb-6">
            <p className="flex justify-between items-center px-4">
              <span className="flex items-center gap-2">
                <span className="text-accent-primary">✓</span> Correct:
              </span>
              <span className="font-bold text-accent-primary text-xl">
                {correctCount}
              </span>
            </p>
            <p className="flex justify-between items-center px-4">
              <span className="flex items-center gap-2">
                <span className="text-error">✗</span> Mistakes:
              </span>
              <span className="font-bold text-error text-xl">{mistakeCount}</span>
            </p>
            <p className="flex justify-between items-center px-4">
              <span>Accuracy:</span>
              <span className="font-bold text-xl">{accuracy}%</span>
            </p>
            <p className="flex justify-between items-center px-4">
              <span>Time:</span>
              <span className="font-bold text-xl">{timeFormatted}</span>
            </p>
          </div>

          <div className="border-t border-white/10 pt-4 mb-6">
            <p className="text-lg">
              Coins:{' '}
              <span className="font-bold text-accent-tertiary">
                +{data.puzzleCoins}
              </span>
            </p>
            <p className="text-sm text-text-secondary mt-1">
              ({correctCount * 10} earned − {mistakeCount * 30} penalty)
            </p>
          </div>

          <div className="space-y-3">
            <Button variant="primary" fullWidth onClick={handlePlayAgain}>
              Play Again
            </Button>
            <Button variant="ghost" fullWidth onClick={handleChangeDifficulty}>
              Change Difficulty
            </Button>
            <Button variant="ghost" fullWidth onClick={handleExit}>
              Exit
            </Button>
          </div>
        </Card>
      </div>
    )
  }

  // Standard mode win
  if (data.won) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-4 relative">
        <StarryBackground />

        <Card className="w-full max-w-md text-center relative z-10 p-6">
          {/* Celebration */}
          <div className="text-6xl mb-4">🎉</div>
          <h1 className="text-3xl font-display font-bold mb-2">
            Puzzle Complete!
          </h1>

          {/* Stars (V2 - placeholder for now) */}
          <div className="text-4xl mb-6">⭐ ⭐ ⭐</div>

          {/* Stats */}
          <div className="space-y-2 mb-6 text-lg">
            <p>
              Time: <span className="font-bold">{timeFormatted}</span>
            </p>
            <p>
              Coins:{' '}
              <span className="font-bold text-accent-tertiary">
                +{data.puzzleCoins}
              </span>
            </p>
            <p>
              Mistakes: <span className="font-bold">{mistakes}</span>
            </p>
          </div>

          {/* Actions */}
          <div className="space-y-3">
            <Button variant="primary" fullWidth onClick={handlePlayAgain}>
              Play Again
            </Button>
            <Button variant="ghost" fullWidth onClick={handleChangeDifficulty}>
              Change Difficulty
            </Button>
            <Button variant="ghost" fullWidth onClick={handleExit}>
              Exit
            </Button>
          </div>
        </Card>
      </div>
    )
  }

  // Game Over (Lost)
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-4 relative">
      <StarryBackground />

      <Card className="w-full max-w-md text-center relative z-10 p-6">
        <div className="text-6xl mb-4">💔</div>
        <h1 className="text-2xl font-display font-bold mb-4">Out of Lives</h1>

        <p className="text-text-secondary mb-6">
          You made {correctMoves} correct moves before running out of lives.
        </p>

        <p className="text-lg mb-6">
          Coins:{' '}
          <span className="font-bold text-accent-tertiary">
            +{data.puzzleCoins}
          </span>
        </p>

        <div className="space-y-3">
          <Button variant="primary" fullWidth onClick={handlePlayAgain}>
            Try Again
          </Button>
          <Button variant="secondary" fullWidth onClick={handleViewSolution}>
            See Solution
          </Button>
          <Button variant="ghost" fullWidth onClick={handleExit}>
            Exit
          </Button>
        </div>
      </Card>
    </div>
  )
}
