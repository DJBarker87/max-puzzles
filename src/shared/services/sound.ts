/**
 * Sound effect types for the game
 */
export type SoundEffect =
  | 'tap'
  | 'correct'
  | 'wrong'
  | 'complete'
  | 'coin'
  | 'levelUp'
  | 'gameOver'

/**
 * Music track types
 */
export type MusicTrack = 'hub' | 'game' | 'victory' | 'lose'

// Map of music tracks to their file paths
const MUSIC_FILES: Record<MusicTrack, string> = {
  hub: '/Galactic Menu Theme.wav',
  game: '/Starlit Circuits (Loop).wav',
  victory: '/Spark Buzz Reward.wav',
  lose: '/Galactic Shutdown (Stinger).wav',
}

// Map of sound effects to their file paths (using victory sound for now)
const SFX_FILES: Partial<Record<SoundEffect, string>> = {
  complete: '/Spark Buzz Reward.wav',
  gameOver: '/Galactic Shutdown (Stinger).wav',
}

/**
 * Sound service for playing music and sound effects
 */
class SoundService {
  private muted = false
  private volume = 0.3
  private musicVolume = 0.2
  private musicPlayer: HTMLAudioElement | null = null
  private currentTrack: MusicTrack | null = null
  private sfxCache: Map<string, HTMLAudioElement> = new Map()

  constructor() {
    // Load saved preferences
    if (typeof window !== 'undefined') {
      const savedMuted = localStorage.getItem('sound_muted')
      if (savedMuted !== null) {
        this.muted = savedMuted === 'true'
      }
      const savedVolume = localStorage.getItem('music_volume')
      if (savedVolume !== null) {
        this.musicVolume = parseFloat(savedVolume)
      }
    }
  }

  // MARK: - Sound Effects

  /**
   * Play a sound effect
   */
  play(effect: SoundEffect): void {
    if (this.muted) return

    const filePath = SFX_FILES[effect]
    if (!filePath) {
      // No file for this effect - just log it
      console.log(`[Sound] Effect: ${effect}`)
      return
    }

    try {
      // Use cached audio or create new
      let audio = this.sfxCache.get(filePath)
      if (!audio) {
        audio = new Audio(filePath)
        this.sfxCache.set(filePath, audio)
      }

      // Clone for overlapping plays
      const clone = audio.cloneNode() as HTMLAudioElement
      clone.volume = this.volume
      clone.play().catch((e) => console.log('SFX play failed:', e))
    } catch (e) {
      console.log('SFX error:', e)
    }
  }

  // MARK: - Music

  /**
   * Play background music
   */
  playMusic(track: MusicTrack, loop: boolean = true): void {
    // If same track is already playing (and not ended), don't restart it
    if (
      this.currentTrack === track &&
      this.musicPlayer &&
      !this.musicPlayer.paused &&
      !this.musicPlayer.ended
    ) {
      return
    }

    // Always stop current music first (even if muted, to clean up)
    this.stopMusic()

    if (this.muted) return

    const filePath = MUSIC_FILES[track]
    if (!filePath) return

    try {
      this.musicPlayer = new Audio(filePath)
      this.musicPlayer.volume = this.musicVolume
      this.musicPlayer.loop = loop
      this.currentTrack = track

      // Clean up reference when non-looping track ends
      if (!loop) {
        this.musicPlayer.addEventListener('ended', () => {
          this.currentTrack = null
          this.musicPlayer = null
        })
      }

      this.musicPlayer.play().catch((e) => {
        console.log('Music play failed (user interaction required?):', e)
      })
    } catch (e) {
      console.log('Music error:', e)
    }
  }

  /**
   * Stop background music
   */
  stopMusic(): void {
    if (this.musicPlayer) {
      this.musicPlayer.pause()
      this.musicPlayer.currentTime = 0
      // Remove event listeners and clear src to fully release audio
      this.musicPlayer.src = ''
      this.musicPlayer.load()
      this.musicPlayer = null
      this.currentTrack = null
    }
  }

  /**
   * Pause background music
   */
  pauseMusic(): void {
    this.musicPlayer?.pause()
  }

  /**
   * Resume background music
   */
  resumeMusic(): void {
    if (this.muted) return
    this.musicPlayer?.play().catch(() => {})
  }

  /**
   * Get current track
   */
  getCurrentTrack(): MusicTrack | null {
    return this.currentTrack
  }

  // MARK: - Settings

  /**
   * Set the mute state
   */
  setMuted(muted: boolean): void {
    this.muted = muted
    if (typeof window !== 'undefined') {
      localStorage.setItem('sound_muted', String(muted))
    }
    if (muted) {
      this.pauseMusic()
    } else {
      this.resumeMusic()
    }
  }

  /**
   * Get the mute state
   */
  isMuted(): boolean {
    return this.muted
  }

  /**
   * Toggle mute state
   */
  toggleMute(): boolean {
    this.setMuted(!this.muted)
    return this.muted
  }

  /**
   * Set the SFX volume (0.0 - 1.0)
   */
  setVolume(volume: number): void {
    this.volume = Math.max(0, Math.min(1, volume))
  }

  /**
   * Get the current SFX volume
   */
  getVolume(): number {
    return this.volume
  }

  /**
   * Set music volume (0.0 - 1.0)
   */
  setMusicVolume(volume: number): void {
    this.musicVolume = Math.max(0, Math.min(1, volume))
    if (this.musicPlayer) {
      this.musicPlayer.volume = this.musicVolume
    }
    if (typeof window !== 'undefined') {
      localStorage.setItem('music_volume', String(this.musicVolume))
    }
  }

  /**
   * Get music volume
   */
  getMusicVolume(): number {
    return this.musicVolume
  }
}

export const soundService = new SoundService()
