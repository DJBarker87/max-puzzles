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
 * Sound service stub (V1 stretch goal)
 * Currently logs sound events for development
 */
class SoundService {
  private muted = false
  private volume = 1.0

  /**
   * Play a sound effect
   */
  play(effect: SoundEffect): void {
    if (this.muted) return
    console.log(`[Sound] Playing: ${effect} at volume ${this.volume}`)
    // TODO: Implement actual sound playback
  }

  /**
   * Set the mute state
   */
  setMuted(muted: boolean): void {
    this.muted = muted
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
    this.muted = !this.muted
    return this.muted
  }

  /**
   * Set the volume (0.0 - 1.0)
   */
  setVolume(volume: number): void {
    this.volume = Math.max(0, Math.min(1, volume))
  }

  /**
   * Get the current volume
   */
  getVolume(): number {
    return this.volume
  }
}

export const soundService = new SoundService()
