import { useState, useEffect } from 'react'
import { Button, Modal } from '@/ui'

// Store the deferred prompt event
let deferredPrompt: BeforeInstallPromptEvent | null = null

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

/**
 * Prompts users to install the PWA on supported devices.
 */
export function InstallPrompt() {
  const [showPrompt, setShowPrompt] = useState(false)
  const [isInstalled, setIsInstalled] = useState(false)

  useEffect(() => {
    // Check if already installed
    if (window.matchMedia('(display-mode: standalone)').matches) {
      setIsInstalled(true)
      return
    }

    // Listen for the beforeinstallprompt event
    const handler = (e: Event) => {
      e.preventDefault()
      deferredPrompt = e as BeforeInstallPromptEvent

      // Show prompt after a delay (don't interrupt immediately)
      setTimeout(() => {
        // Only show if user has played at least one game
        const hasPlayed = localStorage.getItem('hasPlayedGame')
        if (hasPlayed) {
          setShowPrompt(true)
        }
      }, 30000) // 30 seconds
    }

    window.addEventListener('beforeinstallprompt', handler)

    // Listen for successful installation
    window.addEventListener('appinstalled', () => {
      setIsInstalled(true)
      setShowPrompt(false)
      deferredPrompt = null
    })

    return () => {
      window.removeEventListener('beforeinstallprompt', handler)
    }
  }, [])

  const handleInstall = async () => {
    if (!deferredPrompt) return

    // Show the install prompt
    await deferredPrompt.prompt()

    // Wait for the user's response
    const { outcome } = await deferredPrompt.userChoice

    if (outcome === 'accepted') {
      console.log('User accepted install prompt')
    } else {
      console.log('User dismissed install prompt')
    }

    // Clear the prompt
    deferredPrompt = null
    setShowPrompt(false)
  }

  const handleDismiss = () => {
    setShowPrompt(false)
    // Don't show again for 7 days
    localStorage.setItem('installPromptDismissed', Date.now().toString())
  }

  // Don't show if already installed or recently dismissed
  if (isInstalled) return null

  const dismissedAt = localStorage.getItem('installPromptDismissed')
  if (dismissedAt) {
    const dismissedTime = parseInt(dismissedAt, 10)
    const sevenDays = 7 * 24 * 60 * 60 * 1000
    if (Date.now() - dismissedTime < sevenDays) {
      return null
    }
  }

  if (!showPrompt) return null

  return (
    <Modal isOpen={showPrompt} onClose={handleDismiss} title="Install Max's Puzzles">
      <div className="text-center">
        <div className="text-6xl mb-4">⚡</div>
        <p className="mb-4">
          Install Max's Puzzles on your device for the best experience:
        </p>
        <ul className="text-sm text-text-secondary text-left mb-6 space-y-2">
          <li>✓ Play offline anytime</li>
          <li>✓ Faster loading</li>
          <li>✓ Full-screen experience</li>
          <li>✓ Easy access from home screen</li>
        </ul>

        <div className="flex gap-3">
          <Button variant="ghost" fullWidth onClick={handleDismiss}>
            Maybe Later
          </Button>
          <Button variant="primary" fullWidth onClick={handleInstall}>
            Install
          </Button>
        </div>
      </div>
    </Modal>
  )
}

export default InstallPrompt
