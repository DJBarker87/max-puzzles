import type { AuthState } from './auth'

/**
 * Services provided by the hub to puzzle modules
 */
export interface HubServices {
  /** Authentication service */
  auth: AuthState
  /** Coin management service (V3 - stub for now) */
  coins: CoinService
  /** Storage/persistence service */
  storage: StorageService
  /** Avatar service (V3 - stub for now) */
  avatar: AvatarService
  /** Sound effects service */
  sound: SoundService
}

/**
 * Coin service interface (V3)
 */
export interface CoinService {
  /** Get current coin balance */
  getBalance(): number
  /** Add coins (returns new balance) */
  add(amount: number): Promise<number>
  /** Spend coins (returns false if insufficient) */
  spend(amount: number): Promise<boolean>
}

/**
 * Storage service interface
 */
export interface StorageService {
  /** Save data to storage */
  save<T>(key: string, value: T): Promise<void>
  /** Load data from storage */
  load<T>(key: string): Promise<T | null>
  /** Clear specific key */
  clear(key: string): Promise<void>
}

/**
 * Avatar service interface (V3)
 */
export interface AvatarService {
  /** Get current avatar configuration */
  getConfig(): AvatarConfig | null
  /** Update avatar configuration */
  setConfig(config: AvatarConfig): Promise<void>
}

/**
 * Avatar configuration (V3)
 */
export interface AvatarConfig {
  bodyColor: string
  headItem: string | null
  faceItem: string | null
  accessoryItem: string | null
}

/**
 * Sound service interface
 */
export interface SoundService {
  /** Play a sound effect */
  play(sound: string): void
  /** Check if muted */
  isMuted(): boolean
  /** Toggle mute */
  toggleMute(): boolean
}

/**
 * Game mode types
 */
export type GameMode = 'quickplay' | 'progression'

/**
 * Game configuration passed to modules
 */
export interface GameConfig {
  /** Difficulty level (1-10 or 'custom') */
  difficulty: number | 'custom'
  /** Game mode */
  mode: GameMode
  /** Specific level ID for progression mode */
  levelId?: string
  /** Custom difficulty settings */
  customSettings?: Record<string, unknown>
}

/**
 * Progress summary for a module
 */
export interface ModuleProgress {
  /** Total levels in the module */
  totalLevels: number
  /** Completed levels */
  completedLevels: number
  /** Total possible stars */
  totalStars: number
  /** Stars earned */
  earnedStars: number
  /** Last played timestamp */
  lastPlayed: Date | null
}

/**
 * Interface that all puzzle modules must implement
 */
export interface PuzzleModule {
  /** Unique module identifier */
  id: string
  /** Display name */
  name: string
  /** Short description */
  description: string
  /** Emoji or icon identifier */
  icon: string

  /**
   * Initialize the module with hub services
   */
  init(hub: HubServices): void

  /**
   * Cleanup when module is unloaded
   */
  destroy(): void

  /**
   * Get the module's menu component
   */
  renderMenu(): React.ComponentType | (() => Promise<{ default: React.ComponentType }>)

  /**
   * Get the game component for the specified config
   */
  renderGame(config: GameConfig): React.ComponentType | (() => Promise<{ default: React.ComponentType }>)

  /**
   * Get progress summary for a user
   */
  getProgressSummary(userId: string): ModuleProgress
}
