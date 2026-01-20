import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import { useSound } from '@/app/providers/SoundProvider'
import Button from '@/ui/Button'
import Header from '../components/Header'

/**
 * Main hub screen - the central navigation point
 * Shows user greeting, play button, and navigation options
 */
export default function MainHubScreen() {
  const navigate = useNavigate()
  const { user, isGuest, isDemoMode } = useAuth()
  const { playMusic } = useSound()

  const displayName = user?.displayName || 'Guest'
  const coins = user?.coins || 0

  // Play hub music on mount
  useEffect(() => {
    playMusic('hub', true)
  }, [playMusic])

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      {/* Header */}
      <Header
        showMenu
        showCoins={!isDemoMode}
        coins={coins}
      />

      {/* Main content */}
      <main className="flex-1 flex flex-col items-center justify-center p-4">
        {/* Avatar and greeting */}
        <div className="text-center mb-8">
          <div
            className="text-7xl mb-4 cursor-pointer hover:scale-110 transition-transform"
            onClick={() => !isDemoMode && navigate('/shop')}
            title={isDemoMode ? undefined : 'Customise your alien!'}
          >
            👽
          </div>
          <h1 className="text-2xl font-display font-bold">
            Hi, {displayName}!
          </h1>
          {isDemoMode && (
            <p className="text-text-secondary text-sm mt-1">
              Demo Mode - Progress not saved
            </p>
          )}
        </div>

        {/* Main action - Play */}
        <Button
          variant="primary"
          size="lg"
          className="mb-6 px-12"
          onClick={() => navigate('/modules')}
        >
          PLAY
        </Button>

        {/* Secondary actions */}
        <div className="flex gap-4">
          {!isDemoMode && (
            <Button
              variant="secondary"
              onClick={() => navigate('/shop')}
            >
              Shop
            </Button>
          )}
          <Button
            variant="ghost"
            onClick={() => navigate('/settings')}
          >
            Settings
          </Button>
        </div>
      </main>

      {/* Guest prompt */}
      {isGuest && (
        <div className="p-4 text-center bg-background-mid/50">
          <p className="text-text-secondary mb-2">
            Playing as guest - progress saved locally
          </p>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => navigate('/login')}
          >
            Create Account to Save Progress
          </Button>
        </div>
      )}
    </div>
  )
}
