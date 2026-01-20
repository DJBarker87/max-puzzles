import { useState, useEffect, useMemo } from 'react'
import { useParams, useNavigate, useLocation } from 'react-router-dom'
import { StarryBackground } from '../components'
import { chapterAliens, type ChapterAlien } from '@/shared/types/chapterAlien'
import { getStoryDifficulty, type StoryLevel } from '../engine/storyDifficulty'
import GameScreen from './GameScreen'

/**
 * Story mode game screen with level intro overlay
 * Shows alien with speech bubble before starting the level
 */
export default function StoryGameScreen() {
  const { chapterId, levelId } = useParams<{ chapterId: string; levelId: string }>()
  const navigate = useNavigate()
  const location = useLocation()

  const chapter = parseInt(chapterId || '1', 10)
  const level = parseInt(levelId || '1', 10)

  const alien = chapterAliens.find((a) => a.chapter === chapter)
  const [showIntro, setShowIntro] = useState(true)
  const [introVisible, setIntroVisible] = useState(false)

  // Check if coming back from summary (skip intro)
  const skipIntro = location.state?.skipIntro === true

  // Get a random intro message once on mount (use alien's unique messages)
  const introMessage = useMemo(() => {
    if (!alien) return "Good luck!"
    return alien.introMessages[Math.floor(Math.random() * alien.introMessages.length)]
  }, [alien])

  useEffect(() => {
    if (skipIntro) {
      setShowIntro(false)
      return
    }

    // Animate intro in
    setTimeout(() => setIntroVisible(true), 100)

    // Auto-dismiss after delay
    const timer = setTimeout(() => {
      dismissIntro()
    }, 2500)

    return () => clearTimeout(timer)
  }, [skipIntro])

  if (!alien) {
    navigate('/play/circuit-challenge/story')
    return null
  }

  const storyLevel: StoryLevel = { chapter, level }
  const difficulty = getStoryDifficulty(storyLevel)
  const levelLetter = ['A', 'B', 'C', 'D', 'E'][level - 1]

  const dismissIntro = () => {
    setIntroVisible(false)
    setTimeout(() => setShowIntro(false), 300)
  }

  return (
    <div className="relative h-screen">
      {/* Game screen underneath */}
      <GameScreen
        storyAlien={alien}
        storyChapter={chapter}
        storyLevel={level}
      />

      {/* Level intro overlay */}
      {showIntro && (
        <div
          className={`absolute inset-0 z-50 bg-black/90 flex flex-col items-center justify-center transition-all duration-300 ${
            introVisible ? 'opacity-100 scale-100' : 'opacity-0 scale-95'
          }`}
          onClick={dismissIntro}
        >
          {/* Alien image */}
          <img
            src={alien.imagePath}
            alt={alien.name}
            className="w-48 h-48 object-contain mb-6"
          />

          {/* Speech bubble */}
          <div className="relative bg-white rounded-2xl px-6 py-4 mx-8 max-w-xs">
            <p className="text-background-dark text-lg font-medium text-center">
              {introMessage}
            </p>
            {/* Bubble tail */}
            <div
              className="absolute -bottom-3 left-1/2 -translate-x-1/2 w-0 h-0"
              style={{
                borderLeft: '12px solid transparent',
                borderRight: '12px solid transparent',
                borderTop: '12px solid white',
              }}
            />
          </div>

          {/* Level info */}
          <p className="text-white text-2xl font-bold mt-8">
            Level {chapter}-{levelLetter}
          </p>

          {/* Tap hint */}
          <p className="text-text-secondary text-sm mt-8 animate-pulse">
            Tap to start
          </p>
        </div>
      )}
    </div>
  )
}
