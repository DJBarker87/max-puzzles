import { createContext, useContext, useState, useCallback, ReactNode } from 'react'
import { soundService, SoundEffect, MusicTrack } from '@/shared/services/sound'

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
  /** Play background music */
  playMusic: (track: MusicTrack, loop?: boolean) => void
  /** Stop background music */
  stopMusic: () => void
  /** Music volume */
  musicVolume: number
  /** Set music volume */
  setMusicVolume: (volume: number) => void
}

const SoundContext = createContext<SoundContextValue | null>(null)

interface SoundProviderProps {
  children: ReactNode
}

/**
 * Sound provider
 * Manages sound effects, music, and mute state
 */
export function SoundProvider({ children }: SoundProviderProps) {
  const [isMuted, setIsMuted] = useState(soundService.isMuted())
  const [volume, setVolumeState] = useState(soundService.getVolume())
  const [musicVolume, setMusicVolumeState] = useState(soundService.getMusicVolume())

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

  const playMusic = useCallback((track: MusicTrack, loop: boolean = true) => {
    soundService.playMusic(track, loop)
  }, [])

  const stopMusic = useCallback(() => {
    soundService.stopMusic()
  }, [])

  const setMusicVolume = useCallback((vol: number) => {
    soundService.setMusicVolume(vol)
    setMusicVolumeState(vol)
  }, [])

  const value: SoundContextValue = {
    playSound,
    isMuted,
    toggleMute,
    setMuted,
    volume,
    setVolume,
    playMusic,
    stopMusic,
    musicVolume,
    setMusicVolume,
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
