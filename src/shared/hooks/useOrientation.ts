import { useState, useEffect } from 'react'

interface OrientationState {
  isLandscape: boolean
  isMobileLandscape: boolean
  isPortrait: boolean
}

/**
 * Hook to detect device orientation
 * - isLandscape: true when orientation is landscape
 * - isMobileLandscape: true when landscape AND height is limited (phone in landscape)
 * - isPortrait: true when orientation is portrait
 */
export function useOrientation(): OrientationState {
  const [state, setState] = useState<OrientationState>(() => getOrientationState())

  useEffect(() => {
    const handleResize = () => {
      setState(getOrientationState())
    }

    // Listen for both resize and orientation change events
    window.addEventListener('resize', handleResize)
    window.addEventListener('orientationchange', handleResize)

    // Also listen to media query changes for more accurate detection
    const mediaQuery = window.matchMedia('(orientation: landscape) and (max-height: 500px)')
    const handleMediaChange = () => handleResize()

    if (mediaQuery.addEventListener) {
      mediaQuery.addEventListener('change', handleMediaChange)
    } else {
      // Fallback for older browsers
      mediaQuery.addListener(handleMediaChange)
    }

    return () => {
      window.removeEventListener('resize', handleResize)
      window.removeEventListener('orientationchange', handleResize)
      if (mediaQuery.removeEventListener) {
        mediaQuery.removeEventListener('change', handleMediaChange)
      } else {
        mediaQuery.removeListener(handleMediaChange)
      }
    }
  }, [])

  return state
}

function getOrientationState(): OrientationState {
  const isLandscape = window.innerWidth > window.innerHeight
  const isMobileLandscape = isLandscape && window.innerHeight <= 500
  const isPortrait = !isLandscape

  return {
    isLandscape,
    isMobileLandscape,
    isPortrait,
  }
}

export default useOrientation
