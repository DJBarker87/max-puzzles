import { useState, useCallback } from 'react'

/**
 * Return type for useFeedback hook
 */
export interface UseFeedbackReturn {
  /** Whether screen is currently shaking */
  isShaking: boolean
  /** Trigger screen shake animation */
  triggerShake: () => void
  /** CSS class name for shake animation */
  shakeClassName: string
}

/**
 * Hook for managing visual feedback like screen shake
 */
export function useFeedback(): UseFeedbackReturn {
  const [isShaking, setIsShaking] = useState(false)

  const triggerShake = useCallback(() => {
    setIsShaking(true)
    setTimeout(() => setIsShaking(false), 300)
  }, [])

  const shakeClassName = isShaking ? 'animate-shake' : ''

  return { isShaking, triggerShake, shakeClassName }
}

/**
 * Hook for game sounds (placeholder - V1 stretch goal)
 */
export function useGameSounds() {
  const playCorrect = useCallback(() => {
    // TODO: Implement sound effects in V1 stretch goal
    // playSound('correct')
  }, [])

  const playWrong = useCallback(() => {
    // TODO: Implement sound effects in V1 stretch goal
    // playSound('wrong')
  }, [])

  const playWin = useCallback(() => {
    // TODO: Implement sound effects in V1 stretch goal
    // playSound('win')
  }, [])

  const playLose = useCallback(() => {
    // TODO: Implement sound effects in V1 stretch goal
    // playSound('lose')
  }, [])

  return { playCorrect, playWrong, playWin, playLose }
}
