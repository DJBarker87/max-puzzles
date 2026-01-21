import { useState, useEffect, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { SplashBackground, AnimatedAlien } from '@/modules/circuit-challenge/components'
import { chapterAliens, ChapterAlien } from '@/shared/types/chapterAlien'

/**
 * First run welcome screen where an alien rises up and asks for the player's name
 */
export default function FirstRunScreen() {
  const navigate = useNavigate()

  const [playerName, setPlayerName] = useState('')
  const [alienOffset, setAlienOffset] = useState(400) // Start below screen
  const [bubbleOpacity, setBubbleOpacity] = useState(0)
  const [inputOpacity, setInputOpacity] = useState(0)
  const [alienArrived, setAlienArrived] = useState(false)
  const [isExiting, setIsExiting] = useState(false)
  const [isTextFieldFocused, setIsTextFieldFocused] = useState(false)

  // Pick a random welcome alien (computed once)
  const welcomeAlien = useMemo<ChapterAlien>(
    () => chapterAliens[Math.floor(Math.random() * chapterAliens.length)],
    []
  )

  // Start animations on mount
  useEffect(() => {
    // Alien rises up from bottom with spring animation (0.8s delay)
    const riseTimer = setTimeout(() => {
      setAlienOffset(0)
    }, 300)

    // Mark alien as arrived after animation
    const arrivedTimer = setTimeout(() => {
      setAlienArrived(true)
    }, 1000)

    // Speech bubble fades in after alien arrives
    const bubbleTimer = setTimeout(() => {
      setBubbleOpacity(1)
    }, 900)

    // Input field fades in
    const inputTimer = setTimeout(() => {
      setInputOpacity(1)
    }, 1300)

    return () => {
      clearTimeout(riseTimer)
      clearTimeout(arrivedTimer)
      clearTimeout(bubbleTimer)
      clearTimeout(inputTimer)
    }
  }, [])

  const handleComplete = () => {
    // Save the player name
    const nameToSave = playerName.trim()
    localStorage.setItem('playerName', nameToSave)
    localStorage.setItem('hasCompletedFirstRun', 'true')

    // Exit animation - alien drops back down
    setAlienOffset(400)
    setBubbleOpacity(0)
    setInputOpacity(0)

    // Fade out whole view and navigate
    setTimeout(() => {
      setIsExiting(true)
    }, 200)

    setTimeout(() => {
      navigate('/hub', { replace: true })
    }, 500)
  }

  return (
    <div
      className="min-h-screen flex flex-col relative overflow-hidden transition-opacity duration-300"
      style={{ opacity: isExiting ? 0 : 1 }}
      onClick={() => setIsTextFieldFocused(false)}
    >
      <SplashBackground overlayOpacity={0.4} />

      <div className="flex-1 flex flex-col items-center justify-end pb-0 relative z-10">
        {/* Name input field */}
        <div
          className="w-full max-w-md px-6 flex flex-col gap-4 transition-opacity duration-400"
          style={{ opacity: inputOpacity }}
          onClick={(e) => e.stopPropagation()}
        >
          <input
            type="text"
            value={playerName}
            onChange={(e) => setPlayerName(e.target.value)}
            onFocus={() => setIsTextFieldFocused(true)}
            placeholder="Your name"
            className="w-full text-center text-xl font-medium py-4 px-6 rounded-2xl bg-background-mid text-white placeholder-text-secondary outline-none transition-all"
            style={{
              border: isTextFieldFocused
                ? '3px solid #22c55e'
                : '2px solid rgba(34, 197, 94, 0.5)',
            }}
            autoComplete="off"
          />

          {/* Continue button */}
          <button
            onClick={handleComplete}
            className="w-full py-4 px-8 rounded-xl font-bold text-lg text-white transition-all flex items-center justify-center gap-2"
            style={{
              backgroundColor: playerName.trim() ? '#22c55e' : '#1a1a3e',
              boxShadow: playerName.trim()
                ? '0 0 12px rgba(34, 197, 94, 0.4)'
                : 'none',
            }}
          >
            <span>{playerName.trim() ? "Let's Play!" : 'Skip'}</span>
            <span>→</span>
          </button>
        </div>

        {/* Speech bubble */}
        <div
          className="px-12 my-4 transition-opacity duration-400"
          style={{ opacity: bubbleOpacity }}
        >
          <div className="relative bg-white rounded-2xl px-6 py-4 shadow-lg">
            {/* Triangle pointing down */}
            <div
              className="absolute left-1/2 -bottom-3 w-0 h-0 -translate-x-1/2"
              style={{
                borderLeft: '12px solid transparent',
                borderRight: '12px solid transparent',
                borderTop: '12px solid white',
              }}
            />
            <p className="text-center font-bold text-background-dark text-lg">
              Hi there! I'm {welcomeAlien.name}!
            </p>
            <p className="text-center text-background-dark/80 text-base">
              What's your name?
            </p>
          </div>
        </div>

        {/* Alien image rising from bottom */}
        <div
          className="transition-transform duration-700"
          style={{
            transform: `translateY(${alienOffset}px)`,
            transitionTimingFunction: 'cubic-bezier(0.34, 1.56, 0.64, 1)', // Spring effect
          }}
        >
          {alienArrived ? (
            <AnimatedAlien
              src={welcomeAlien.imagePath}
              alt={welcomeAlien.name}
              style="bounce"
              className="w-48 h-48 object-contain"
            />
          ) : (
            <img
              src={welcomeAlien.imagePath}
              alt={welcomeAlien.name}
              className="w-48 h-48 object-contain"
            />
          )}
        </div>
      </div>
    </div>
  )
}
