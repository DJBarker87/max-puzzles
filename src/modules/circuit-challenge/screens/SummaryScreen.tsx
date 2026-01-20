import { useState, useEffect } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { Button, Card } from '@/ui'
import { StarryBackground } from '../components'
import type { Puzzle } from '../types'
import type { DifficultySettings } from '../engine/types'
import type { GameMoveResult, HiddenModeResults } from '../types/gameState'
import type { ChapterAlien } from '@/shared/types/chapterAlien'

interface SummaryData {
  won: boolean
  isHiddenMode: boolean
  elapsedMs: number
  puzzleCoins: number
  moveHistory: GameMoveResult[]
  hiddenModeResults?: HiddenModeResults
  difficulty: DifficultySettings
  puzzle: Puzzle
  // Story mode
  storyAlien?: ChapterAlien
  storyChapter?: number
  storyLevel?: number
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

// Win messages for story mode
const winMessages = [
  "Amazing work! You did it!",
  "Fantastic! You're a star!",
  "Woohoo! Great job!",
  "You're incredible!",
  "That was awesome!",
]

// Lose/encourage messages for story mode
const loseMessages = [
  "Don't give up! Try again!",
  "You've got this! One more try!",
  "Almost there! Keep going!",
  "You're doing great! Try again!",
  "Practice makes perfect!",
]

/**
 * Summary screen shown after completing or losing a puzzle
 */
export default function SummaryScreen() {
  const location = useLocation()
  const navigate = useNavigate()
  const data = location.state as SummaryData | null

  // State for character reveal animation
  const [showingCharacter, setShowingCharacter] = useState(true)
  const [characterVisible, setCharacterVisible] = useState(false)

  // Redirect if no data
  if (!data) {
    navigate('/play/circuit-challenge')
    return null
  }

  const isStoryMode = !!data.storyAlien

  // Character reveal animation for non-hidden mode
  useEffect(() => {
    if (data.isHiddenMode) {
      setShowingCharacter(false)
      return
    }

    // Animate in
    setTimeout(() => setCharacterVisible(true), 100)

    // Auto-dismiss after delay
    const timer = setTimeout(() => {
      dismissCharacter()
    }, 2000)

    return () => clearTimeout(timer)
  }, [data.isHiddenMode])

  const dismissCharacter = () => {
    setCharacterVisible(false)
    setTimeout(() => setShowingCharacter(false), 300)
  }

  // Calculate statistics
  const totalMoves = data.moveHistory.length
  const correctMoves = data.moveHistory.filter((m) => m.correct).length
  const mistakes = totalMoves - correctMoves
  const accuracy = totalMoves > 0 ? Math.round((correctMoves / totalMoves) * 100) : 0
  const timeFormatted = formatTime(data.elapsedMs)

  const handlePlayAgain = () => {
    if (isStoryMode && data.storyChapter && data.storyLevel) {
      // Go back to story game with skip intro
      navigate(`/play/circuit-challenge/story/${data.storyChapter}/${data.storyLevel}`, {
        state: { skipIntro: true },
      })
    } else {
      navigate('/play/circuit-challenge/game', {
        state: { difficulty: data.difficulty },
      })
    }
  }

  const handleChangeDifficulty = () => {
    if (isStoryMode && data.storyChapter) {
      // Go back to level select
      navigate(`/play/circuit-challenge/story/${data.storyChapter}`)
    } else {
      navigate('/play/circuit-challenge/quick')
    }
  }

  const handleExit = () => {
    if (isStoryMode) {
      navigate('/play/circuit-challenge/story')
    } else {
      navigate('/play/circuit-challenge')
    }
  }

  const handleViewSolution = () => {
    navigate('/play/circuit-challenge/game', {
      state: {
        difficulty: data.difficulty,
        showSolution: true,
      },
    })
  }

  // Get random message
  const alienMessage = data.won
    ? winMessages[Math.floor(Math.random() * winMessages.length)]
    : loseMessages[Math.floor(Math.random() * loseMessages.length)]

  // Character reveal screen (for non-hidden mode)
  if (showingCharacter && !data.isHiddenMode) {
    return (
      <div
        className={`min-h-screen flex flex-col items-center justify-center p-4 relative transition-all duration-300 ${
          characterVisible ? 'opacity-100 scale-100' : 'opacity-0 scale-95'
        }`}
        onClick={dismissCharacter}
      >
        <StarryBackground />

        {/* Confetti for wins */}
        {data.won && (
          <div className="absolute inset-0 overflow-hidden pointer-events-none z-10">
            {Array.from({ length: 30 }).map((_, i) => (
              <div
                key={i}
                className="absolute animate-bounce"
                style={{
                  left: `${Math.random() * 100}%`,
                  top: `${Math.random() * 100}%`,
                  animationDelay: `${Math.random() * 2}s`,
                  animationDuration: `${1 + Math.random()}s`,
                }}
              >
                {['🎉', '⭐', '✨', '🎊'][Math.floor(Math.random() * 4)]}
              </div>
            ))}
          </div>
        )}

        <div className="relative z-20 flex flex-col items-center">
          {/* Character image */}
          {isStoryMode && data.storyAlien ? (
            <>
              <img
                src={data.storyAlien.imagePath}
                alt={data.storyAlien.name}
                className="w-48 h-48 md:w-64 md:h-64 object-contain"
              />

              {/* Speech bubble */}
              <div className="relative bg-white rounded-2xl px-6 py-4 mx-8 max-w-xs mt-6">
                <p className="text-background-dark text-lg font-medium text-center">
                  {alienMessage}
                </p>
                <div
                  className="absolute -top-3 left-1/2 -translate-x-1/2 w-0 h-0 rotate-180"
                  style={{
                    borderLeft: '12px solid transparent',
                    borderRight: '12px solid transparent',
                    borderTop: '12px solid white',
                  }}
                />
              </div>
            </>
          ) : (
            // Quick play: show emoji
            <div className="text-[150px] md:text-[200px]">
              {data.won ? '🎉' : '💔'}
            </div>
          )}
        </div>
      </div>
    )
  }

  // Hidden mode win
  if (data.isHiddenMode && data.hiddenModeResults) {
    const { correctCount, mistakeCount } = data.hiddenModeResults

    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-4 relative">
        <StarryBackground />

        <Card className="w-full max-w-md text-center relative z-10 p-6">
          {/* Show alien for story mode */}
          {isStoryMode && data.storyAlien && (
            <img
              src={data.storyAlien.imagePath}
              alt={data.storyAlien.name}
              className="w-24 h-24 mx-auto object-contain mb-4"
            />
          )}
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
          {/* Celebration - show alien for story mode */}
          {isStoryMode && data.storyAlien ? (
            <img
              src={data.storyAlien.imagePath}
              alt={data.storyAlien.name}
              className="w-24 h-24 mx-auto object-contain mb-4"
            />
          ) : (
            <div className="text-6xl mb-4">🎉</div>
          )}
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
        {/* Sad display - show alien for story mode */}
        {isStoryMode && data.storyAlien ? (
          <img
            src={data.storyAlien.imagePath}
            alt={data.storyAlien.name}
            className="w-24 h-24 mx-auto object-contain mb-4"
          />
        ) : (
          <div className="text-6xl mb-4">💔</div>
        )}
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
