import { useEffect, useState } from 'react'
import { useRegisterSW } from 'virtual:pwa-register/react'
import { Button, Card } from '@/ui'

/**
 * Handles PWA service worker registration and update prompts.
 * Shows a banner when a new version is available.
 */
export function PWAUpdatePrompt() {
  const [showUpdateBanner, setShowUpdateBanner] = useState(false)

  const {
    needRefresh: [needRefresh, setNeedRefresh],
    offlineReady: [offlineReady, setOfflineReady],
    updateServiceWorker,
  } = useRegisterSW({
    onRegistered(registration) {
      console.log('SW registered:', registration)

      // Check for updates every hour
      if (registration) {
        setInterval(
          () => {
            registration.update()
          },
          60 * 60 * 1000
        )
      }
    },
    onRegisterError(error) {
      console.error('SW registration error:', error)
    },
  })

  // Show update banner when new version available
  useEffect(() => {
    if (needRefresh) {
      setShowUpdateBanner(true)
    }
  }, [needRefresh])

  // Handle update
  const handleUpdate = () => {
    updateServiceWorker(true)
    setShowUpdateBanner(false)
  }

  // Handle dismiss
  const handleDismiss = () => {
    setShowUpdateBanner(false)
    setNeedRefresh(false)
  }

  // Show offline ready toast briefly
  useEffect(() => {
    if (offlineReady) {
      console.log('App ready for offline use')

      // Auto-dismiss after 3 seconds
      const timer = setTimeout(() => {
        setOfflineReady(false)
      }, 3000)

      return () => clearTimeout(timer)
    }
  }, [offlineReady, setOfflineReady])

  if (!showUpdateBanner && !offlineReady) {
    return null
  }

  return (
    <div className="fixed bottom-4 left-4 right-4 z-50 md:left-auto md:right-4 md:w-96">
      {/* Offline Ready Toast */}
      {offlineReady && (
        <Card className="p-4 bg-accent-primary/20 border-accent-primary mb-2">
          <div className="flex items-center gap-3">
            <span className="text-2xl">✓</span>
            <div className="flex-1">
              <p className="font-medium">Ready to play offline!</p>
              <p className="text-sm text-text-secondary">
                The app is now available without internet.
              </p>
            </div>
          </div>
        </Card>
      )}

      {/* Update Available Banner */}
      {showUpdateBanner && (
        <Card className="p-4 bg-accent-secondary/20 border-accent-secondary">
          <div className="flex items-start gap-3">
            <span className="text-2xl">🆕</span>
            <div className="flex-1">
              <p className="font-medium">Update available!</p>
              <p className="text-sm text-text-secondary mb-3">
                A new version of Max's Puzzles is ready.
              </p>
              <div className="flex gap-2">
                <Button variant="primary" size="sm" onClick={handleUpdate}>
                  Update Now
                </Button>
                <Button variant="ghost" size="sm" onClick={handleDismiss}>
                  Later
                </Button>
              </div>
            </div>
          </div>
        </Card>
      )}
    </div>
  )
}

export default PWAUpdatePrompt
