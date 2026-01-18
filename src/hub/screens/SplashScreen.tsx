import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'

/**
 * Splash screen displayed briefly when the app loads
 * Handles navigation based on auth state
 */
export default function SplashScreen() {
  const navigate = useNavigate()
  const { user, isGuest, isLoading } = useAuth()
  const [minTimeElapsed, setMinTimeElapsed] = useState(false)

  // Minimum display time for branding
  useEffect(() => {
    const timer = setTimeout(() => {
      setMinTimeElapsed(true)
    }, 1500)

    return () => clearTimeout(timer)
  }, [])

  // Navigate when ready
  useEffect(() => {
    if (!minTimeElapsed || isLoading) return

    if (user && user.role === 'parent') {
      // Logged in parent goes to family select
      navigate('/family-select', { replace: true })
    } else if (isGuest) {
      // Guest goes to login to choose
      navigate('/login', { replace: true })
    } else {
      // Fallback to hub
      navigate('/hub', { replace: true })
    }
  }, [minTimeElapsed, isLoading, user, isGuest, navigate])

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-background-dark">
      {/* Logo and Title */}
      <div className="text-center animate-fade-in">
        {/* Alien mascot */}
        <div className="text-8xl mb-6 animate-bounce-slow">
          👽
        </div>

        <h1 className="text-4xl md:text-5xl font-display font-bold mb-2">
          <span className="text-accent-primary">Max's</span>{' '}
          <span className="text-white">Puzzles</span>
        </h1>

        <p className="text-text-secondary text-lg">
          Fun maths adventures!
        </p>
      </div>

      {/* Loading indicator */}
      <div className="mt-12">
        <div className="flex gap-2">
          {[0, 1, 2].map(i => (
            <div
              key={i}
              className="w-3 h-3 rounded-full bg-accent-primary animate-pulse"
              style={{ animationDelay: `${i * 0.2}s` }}
            />
          ))}
        </div>
      </div>
    </div>
  )
}
