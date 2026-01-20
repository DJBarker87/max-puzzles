import { useState, useEffect } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useSound } from '@/app/providers/SoundProvider'
import { Button, Card } from '@/ui'
import { StarryBackground, AnimatedStarReveal, Confetti } from '../components'
import { chapterAliens, getRandomWinMessage, type ChapterAlien } from '@/shared/types/chapterAlien'
import {
  getStoryProgress,
  isChapterCompleted,
  recordLevelAttempt,
} from '@/shared/types/storyProgress'
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
  const { playMusic, playSound } = useSound()
  const data = location.state as SummaryData | null

  // State for character reveal animation
  const [showingCharacter, setShowingCharacter] = useState(true)
  const [characterVisible, setCharacterVisible] = useState(false)

  // State for chapter unlock celebration
  const [showChapterUnlock, setShowChapterUnlock] = useState(false)
  const [unlockedAlien, setUnlockedAlien] = useState<ChapterAlien | null>(null)
  const [chapterUnlockVisible, setChapterUnlockVisible] = useState(false)

  // Redirect if no data
  if (!data) {
    navigate('/play/circuit-challenge')
    return null
  }

  const isStoryMode = !!data.storyAlien

  // Check if this completion unlocks a new chapter
  useEffect(() => {
    if (data.won && isStoryMode && data.storyChapter && data.storyLevel === 5) {
      // Check if this is the level that completes the chapter
      const progress = getStoryProgress()
      const wasChapterCompletedBefore = isChapterCompleted(data.storyChapter, progress)

      // Record this level completion
      const timeSeconds = Math.floor(data.elapsedMs / 1000)
      const correctMoves = data.moveHistory.filter(m => m.correct).length
      const livesLost = data.moveHistory.filter(m => !m.correct).length
      recordLevelAttempt(data.storyChapter, data.storyLevel, true, livesLost, timeSeconds, correctMoves)

      // If chapter wasn't completed before but would be now, show unlock celebration
      if (!wasChapterCompletedBefore && data.storyChapter < 10) {
        const nextChapter = data.storyChapter + 1
        const nextAlien = chapterAliens.find(a => a.chapter === nextChapter)
        if (nextAlien) {
          setUnlockedAlien(nextAlien)
        }
      }
    }
  }, [data.won, isStoryMode, data.storyChapter, data.storyLevel, data.elapsedMs, data.moveHistory])

  // Play victory or defeat stinger on mount
  useEffect(() => {
    if (data.won) {
      playMusic('victory', false) // Play victory stinger once (no loop)
      playSound('complete')
    } else {
      playMusic('lose', false) // Play defeat stinger once (no loop)
      playSound('gameOver')
    }
  }, [data.won, playMusic, playSound])

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
    setTimeout(() => {
      setShowingCharacter(false)
      // If we have an unlocked alien, show the unlock celebration
      if (unlockedAlien) {
        setShowChapterUnlock(true)
        setTimeout(() => setChapterUnlockVisible(true), 100)
      }
    }, 300)
  }

  const dismissChapterUnlock = () => {
    setChapterUnlockVisible(false)
    setTimeout(() => {
      setShowChapterUnlock(false)
      setUnlockedAlien(null)
    }, 300)
  }

  // Calculate statistics
  const totalMoves = data.moveHistory.length
  const correctMoves = data.moveHistory.filter((m) => m.correct).length
  const mistakes = totalMoves - correctMoves
  const accuracy = totalMoves > 0 ? Math.round((correctMoves / totalMoves) * 100) : 0
  const timeFormatted = formatTime(data.elapsedMs)

  // Calculate stars earned
  // - 1 star: Completed the puzzle
  // - 2 stars: Completed with no lives lost (no mistakes)
  // - 3 stars: Completed with no lives lost AND average tile time < 5 seconds
  const averageTileTimeMs = correctMoves > 0 ? data.elapsedMs / correctMoves : 0
  const starsEarned = (() => {
    if (!data.won) return 0
    let stars = 1 // 1 star for completing
    if (mistakes === 0) {
      stars = 2 // 2 stars for no mistakes
      if (averageTileTimeMs < 5000) {
        stars = 3 // 3 stars for no mistakes AND fast
      }
    }
    return stars
  })()

  const handlePlayAgain = () => {
    if (isStoryMode && data.storyChapter && data.storyLevel) {
      // Retry the same level with skip intro
      navigate(`/play/circuit-challenge/story/${data.storyChapter}/${data.storyLevel}`, {
        state: { skipIntro: true },
      })
    } else {
      navigate('/play/circuit-challenge/game', {
        state: { difficulty: data.difficulty },
      })
    }
  }

  const handleNextLevel = () => {
    if (!isStoryMode || !data.storyChapter || !data.storyLevel) return

    const currentLevel = data.storyLevel
    const currentChapter = data.storyChapter

    if (currentLevel < 5) {
      // Go to next level in same chapter
      navigate(`/play/circuit-challenge/story/${currentChapter}/${currentLevel + 1}`)
    } else if (currentChapter < 10) {
      // Go to first level of next chapter
      navigate(`/play/circuit-challenge/story/${currentChapter + 1}/1`)
    } else {
      // Completed all chapters, go back to chapter select
      navigate('/play/circuit-challenge/story')
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

  // Get random message - use alien-specific messages for story mode wins
  const alienMessage = data.won
    ? (data.storyAlien ? getRandomWinMessage(data.storyAlien) : winMessages[Math.floor(Math.random() * winMessages.length)])
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

        {/* Confetti celebration for wins */}
        {data.won && <Confetti particleCount={80} />}

        {/* Sparkle effect for wins */}
        {data.won && (
          <div className="absolute inset-0 overflow-hidden pointer-events-none z-10">
            {Array.from({ length: 20 }).map((_, i) => (
              <div
                key={i}
                className="absolute w-2 h-2 rounded-full bg-accent-tertiary animate-ping"
                style={{
                  left: `${Math.random() * 100}%`,
                  top: `${Math.random() * 100}%`,
                  animationDelay: `${Math.random() * 2}s`,
                  animationDuration: `${1.5 + Math.random()}s`,
                  opacity: 0.6,
                }}
              />
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
          ) : null}
        </div>
      </div>
    )
  }

  // Chapter unlock celebration screen
  if (showChapterUnlock && unlockedAlien) {
    return (
      <div
        className={`min-h-screen flex flex-col items-center justify-center p-4 relative transition-all duration-500 ${
          chapterUnlockVisible ? 'opacity-100 scale-100' : 'opacity-0 scale-90'
        }`}
        onClick={dismissChapterUnlock}
      >
        <StarryBackground />

        {/* Epic confetti burst */}
        <Confetti particleCount={120} />

        {/* Glow effect behind alien */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <div
            className="w-96 h-96 rounded-full animate-pulse"
            style={{
              background: 'radial-gradient(circle, rgba(34,197,94,0.4) 0%, transparent 70%)',
              filter: 'blur(40px)',
            }}
          />
        </div>

        <div className="relative z-20 flex flex-col items-center">
          {/* "New Chapter Unlocked!" title */}
          <h1 className="text-3xl md:text-4xl font-display font-bold text-accent-primary mb-4 animate-pulse">
            New Chapter Unlocked!
          </h1>

          {/* Alien image with dramatic entrance */}
          <div className="relative">
            {/* Spinning glow ring */}
            <div
              className="absolute inset-[-20%] rounded-full animate-spin"
              style={{
                background: 'conic-gradient(from 0deg, transparent, rgba(34,197,94,0.3), transparent)',
                animationDuration: '3s',
              }}
            />
            <img
              src={unlockedAlien.imagePath}
              alt={unlockedAlien.name}
              className="w-56 h-56 md:w-72 md:h-72 object-contain relative z-10"
              style={{
                filter: 'drop-shadow(0 0 30px rgba(34,197,94,0.5))',
              }}
            />
          </div>

          {/* Alien name and chapter */}
          <div className="mt-6 text-center">
            <p className="text-text-secondary text-lg">Chapter {unlockedAlien.chapter}</p>
            <h2 className="text-4xl font-display font-black text-white mt-1">
              {unlockedAlien.name}
            </h2>
            <p className="text-accent-primary/90 mt-2">
              {unlockedAlien.words.join(' • ')}
            </p>
          </div>

          {/* Tap hint */}
          <p className="text-text-secondary text-sm mt-8 animate-pulse">
            Tap to continue
          </p>
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
            {isStoryMode ? (
              <>
                {/* Story mode hidden: Next Level + Retry */}
                <Button variant="primary" fullWidth onClick={handleNextLevel}>
                  Next Level
                </Button>
                <Button variant="secondary" fullWidth onClick={handlePlayAgain}>
                  Retry
                </Button>
              </>
            ) : (
              <>
                {/* Quick play: Play Again + Change Difficulty */}
                <Button variant="primary" fullWidth onClick={handlePlayAgain}>
                  Play Again
                </Button>
                <Button variant="ghost" fullWidth onClick={handleChangeDifficulty}>
                  Change Difficulty
                </Button>
              </>
            )}
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
          ) : null}
          <h1 className="text-3xl font-display font-bold mb-2">
            Puzzle Complete!
          </h1>

          {/* Animated stars reveal */}
          <div className="mb-6">
            <AnimatedStarReveal starsEarned={starsEarned} delay={300} />
          </div>

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
            {isStoryMode ? (
              <>
                {/* Story mode: Next Level + Retry */}
                <Button variant="primary" fullWidth onClick={handleNextLevel}>
                  Next Level
                </Button>
                <Button variant="secondary" fullWidth onClick={handlePlayAgain}>
                  Retry
                </Button>
              </>
            ) : (
              <>
                {/* Quick play: Play Again + Change Difficulty */}
                <Button variant="primary" fullWidth onClick={handlePlayAgain}>
                  Play Again
                </Button>
                <Button variant="ghost" fullWidth onClick={handleChangeDifficulty}>
                  Change Difficulty
                </Button>
              </>
            )}
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
          <div className="text-6xl mb-4 text-accent-secondary">X</div>
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
