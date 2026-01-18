import { createContext, useContext, useState, useCallback, ReactNode } from 'react'
import { soundService, SoundEffect } from '@/shared/services/sound'

interface SoundContextValue {
  /** Play a sound effect */
  playSound: (sound: SoundEffect) => void
  /** Whether sound is muted */
  isMuted: boolean
  /** Toggle mute state */
  toggleMute: () => void
  /** Set mute state */
  setMuted: (muted: boolean) => void
  /** Current volume (0-1) */
  volume: number
  /** Set volume */
  setVolume: (volume: number) => void
}

const SoundContext = createContext<SoundContextValue | null>(null)

interface SoundProviderProps {
  children: ReactNode
}

/**
 * Sound provider
 * Manages sound effects and mute state
 */
export function SoundProvider({ children }: SoundProviderProps) {
  const [isMuted, setIsMuted] = useState(soundService.isMuted())
  const [volume, setVolumeState] = useState(soundService.getVolume())

  const playSound = useCallback((sound: SoundEffect) => {
    soundService.play(sound)
  }, [])

  const toggleMute = useCallback(() => {
    const newMuted = soundService.toggleMute()
    setIsMuted(newMuted)
  }, [])

  const setMuted = useCallback((muted: boolean) => {
    soundService.setMuted(muted)
    setIsMuted(muted)
  }, [])

  const setVolume = useCallback((vol: number) => {
    soundService.setVolume(vol)
    setVolumeState(vol)
  }, [])

  const value: SoundContextValue = {
    playSound,
    isMuted,
    toggleMute,
    setMuted,
    volume,
    setVolume,
  }

  return <SoundContext.Provider value={value}>{children}</SoundContext.Provider>
}

/**
 * Hook to access sound methods
 */
export function useSound(): SoundContextValue {
  const context = useContext(SoundContext)
  if (!context) {
    throw new Error('useSound must be used within a SoundProvider')
  }
  return context
}
