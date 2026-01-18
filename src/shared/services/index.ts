// Supabase client
export { supabase, isSupabaseConfigured } from './supabase'
export type { Database } from './database.types'

// IndexedDB storage
export {
  getDB,
  getGuestProfile,
  setGuestProfile,
  updateGuestCoins,
  getModuleProgress,
  setModuleProgress,
  getAllModuleProgress,
  logActivity,
  updateActivity,
  getRecentActivity as getRecentLocalActivity,
  getActivityByModule,
  getSetting,
  setSetting,
  addToSyncQueue,
  getSyncQueue,
  clearSyncQueue,
  removeSyncItem,
  clearAllData,
  closeDB,
} from './indexedDB'
export type {
  GuestProfile,
  ModuleProgressEntry,
  ActivityLogEntry,
  SyncQueueEntry,
} from './indexedDB'

// Auth service
export {
  signUp,
  signIn,
  signOut,
  getCurrentSession,
  getCurrentUser,
  fetchUserById,
  fetchFamily,
  fetchFamilyChildren,
  verifyChildPin,
  setChildPin,
  addChild,
  updateChild,
  removeChild,
  initGuestProfile,
  updateGuestDisplayName,
  getGuestCoins,
} from './auth'

// Progress service
export {
  getProgress,
  saveProgress,
  recordQuickPlayResult,
  addCoins,
  getCoins,
  getProgressSummary,
} from './progress'
export type { CircuitChallengeProgress } from './progress'

// Activity tracking
export {
  startSession,
  endSession,
  recordGameInSession,
  getCurrentSession as getActiveSession,
  getRecentActivity,
  getActivityForChild,
  getActivitySummary,
  resetInactivityTimer,
  clearInactivityTimer,
} from './activity'
export type { ActivitySession } from './activity'

// Data sync
export { syncGuestDataToAccount, hasPendingSyncData } from './sync'
export type { SyncResult } from './sync'

// Sound service
export * from './sound'

// Legacy storage (kept for compatibility)
export { storageService } from './storage'
