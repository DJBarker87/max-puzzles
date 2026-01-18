import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import { useSound } from '@/app/providers/SoundProvider'
import Button from '@/ui/Button'
import Card from '@/ui/Card'
import Toggle from '@/ui/Toggle'
import Header from '../components/Header'

type AnimationSetting = 'full' | 'reduced'

/**
 * Settings screen for app preferences
 */
export default function SettingsScreen() {
  const navigate = useNavigate()
  const { user, isGuest, logout } = useAuth()
  const { isMuted, toggleMute } = useSound()

  const [settings, setSettings] = useState({
    soundEffects: !isMuted,
    music: true, // Placeholder for future music feature
    animations: 'full' as AnimationSetting,
  })

  const handleSoundToggle = (checked: boolean) => {
    setSettings(s => ({ ...s, soundEffects: checked }))
    if (isMuted !== !checked) {
      toggleMute()
    }
  }

  const handleLogout = async () => {
    await logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Settings" showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-md mx-auto space-y-6">
          {/* Audio Settings */}
          <Card className="p-4">
            <h2 className="text-lg font-bold mb-4">Audio</h2>

            <div className="space-y-4">
              <Toggle
                label="Sound Effects"
                checked={settings.soundEffects}
                onChange={handleSoundToggle}
              />

              <Toggle
                label="Music"
                checked={settings.music}
                onChange={(checked) => setSettings(s => ({ ...s, music: checked }))}
              />
            </div>
          </Card>

          {/* Display Settings */}
          <Card className="p-4">
            <h2 className="text-lg font-bold mb-4">Display</h2>

            <div>
              <label className="text-sm text-text-secondary mb-2 block">
                Animations
              </label>
              <div className="flex gap-2">
                <Button
                  variant={settings.animations === 'full' ? 'primary' : 'ghost'}
                  size="sm"
                  onClick={() => setSettings(s => ({ ...s, animations: 'full' }))}
                >
                  Full
                </Button>
                <Button
                  variant={settings.animations === 'reduced' ? 'primary' : 'ghost'}
                  size="sm"
                  onClick={() => setSettings(s => ({ ...s, animations: 'reduced' }))}
                >
                  Reduced
                </Button>
              </div>
            </div>
          </Card>

          {/* Account Section */}
          <Card className="p-4">
            <h2 className="text-lg font-bold mb-4">Account</h2>

            {isGuest ? (
              <div className="space-y-3">
                <p className="text-text-secondary text-sm">
                  Playing as guest. Create an account to save your progress!
                </p>
                <Button
                  variant="secondary"
                  fullWidth
                  onClick={() => navigate('/login')}
                >
                  Create Account
                </Button>
              </div>
            ) : (
              <div className="space-y-3">
                <p className="text-text-secondary text-sm">
                  Logged in as {user?.email || user?.displayName}
                </p>
                <Button
                  variant="ghost"
                  fullWidth
                  onClick={() => navigate('/family-select')}
                >
                  Switch User
                </Button>
                <Button
                  variant="ghost"
                  fullWidth
                  onClick={handleLogout}
                >
                  Log Out
                </Button>
              </div>
            )}
          </Card>

          {/* About Section */}
          <Card className="p-4">
            <h2 className="text-lg font-bold mb-2">About</h2>
            <p className="text-text-secondary text-sm">
              Max's Puzzles v1.0.0
            </p>
            <p className="text-text-secondary text-sm mt-1">
              Made with love for Max
            </p>
          </Card>
        </div>
      </main>
    </div>
  )
}
