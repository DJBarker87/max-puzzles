import { useOnlineStatus } from '../hooks/useOnlineStatus'

/**
 * Shows a banner when the app is offline.
 */
export function OfflineBanner() {
  const isOnline = useOnlineStatus()

  if (isOnline) {
    return null
  }

  return (
    <div className="fixed top-0 left-0 right-0 z-50 bg-yellow-600 text-black text-center py-2 text-sm font-medium">
      You're offline. Some features may be limited.
    </div>
  )
}

export default OfflineBanner
