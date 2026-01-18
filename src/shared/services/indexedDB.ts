import { openDB, DBSchema, IDBPDatabase } from 'idb'

/**
 * IndexedDB Schema for Max's Puzzles
 */
interface MaxPuzzlesDB extends DBSchema {
  // Guest user profile
  guestProfile: {
    key: 'profile'
    value: {
      id: string
      displayName: string
      coins: number
      createdAt: string
      updatedAt: string
    }
  }

  // Module progress (keyed by moduleId)
  moduleProgress: {
    key: string // moduleId
    value: {
      moduleId: string
      data: Record<string, unknown>
      updatedAt: string
    }
  }

  // Activity sessions
  activityLog: {
    key: string // sessionId
    value: {
      id: string
      moduleId: string
      sessionStart: string
      sessionEnd: string | null
      durationSeconds: number
      gamesPlayed: number
      correctAnswers: number
      mistakes: number
      coinsEarned: number
    }
    indexes: {
      'by-module': string
      'by-date': string
    }
  }

  // Settings
  settings: {
    key: string
    value: unknown
  }

  // Pending sync queue (for when user creates account)
  syncQueue: {
    key: string
    value: {
      id: string
      type: 'progress' | 'activity' | 'profile'
      data: unknown
      createdAt: string
    }
  }
}

const DB_NAME = 'max-puzzles'
const DB_VERSION = 2

let dbInstance: IDBPDatabase<MaxPuzzlesDB> | null = null

/**
 * Get or create the database instance
 */
export async function getDB(): Promise<IDBPDatabase<MaxPuzzlesDB>> {
  if (dbInstance) return dbInstance

  dbInstance = await openDB<MaxPuzzlesDB>(DB_NAME, DB_VERSION, {
    upgrade(db, oldVersion) {
      // Guest profile store
      if (!db.objectStoreNames.contains('guestProfile')) {
        db.createObjectStore('guestProfile')
      }

      // Module progress store
      if (!db.objectStoreNames.contains('moduleProgress')) {
        db.createObjectStore('moduleProgress')
      }

      // Activity log store with indexes
      if (!db.objectStoreNames.contains('activityLog')) {
        const activityStore = db.createObjectStore('activityLog', { keyPath: 'id' })
        activityStore.createIndex('by-module', 'moduleId')
        activityStore.createIndex('by-date', 'sessionStart')
      }

      // Settings store
      if (!db.objectStoreNames.contains('settings')) {
        db.createObjectStore('settings')
      }

      // Sync queue store
      if (!db.objectStoreNames.contains('syncQueue')) {
        db.createObjectStore('syncQueue', { keyPath: 'id' })
      }

      // Handle migrations from older versions
      if (oldVersion < 2) {
        // Migration from v1 to v2 if needed
        console.log('Migrated database from v1 to v2')
      }
    },
  })

  return dbInstance
}

// ============================================
// Guest Profile Operations
// ============================================

export type GuestProfile = MaxPuzzlesDB['guestProfile']['value']

export async function getGuestProfile(): Promise<GuestProfile | undefined> {
  const db = await getDB()
  return db.get('guestProfile', 'profile')
}

export async function setGuestProfile(profile: GuestProfile): Promise<void> {
  const db = await getDB()
  await db.put('guestProfile', profile, 'profile')
}

export async function updateGuestCoins(delta: number): Promise<GuestProfile | undefined> {
  const profile = await getGuestProfile()
  if (profile) {
    profile.coins = Math.max(0, profile.coins + delta)
    profile.updatedAt = new Date().toISOString()
    await setGuestProfile(profile)
  }
  return profile
}

// ============================================
// Module Progress Operations
// ============================================

export type ModuleProgressEntry = MaxPuzzlesDB['moduleProgress']['value']

export async function getModuleProgress(moduleId: string): Promise<ModuleProgressEntry | undefined> {
  const db = await getDB()
  return db.get('moduleProgress', moduleId)
}

export async function setModuleProgress(
  moduleId: string,
  data: Record<string, unknown>
): Promise<void> {
  const db = await getDB()
  await db.put(
    'moduleProgress',
    {
      moduleId,
      data,
      updatedAt: new Date().toISOString(),
    },
    moduleId
  )
}

export async function getAllModuleProgress(): Promise<ModuleProgressEntry[]> {
  const db = await getDB()
  return db.getAll('moduleProgress')
}

// ============================================
// Activity Log Operations
// ============================================

export type ActivityLogEntry = MaxPuzzlesDB['activityLog']['value']

export async function logActivity(
  activity: Omit<ActivityLogEntry, 'id'>
): Promise<string> {
  const db = await getDB()
  const id = `activity-${Date.now()}-${Math.random().toString(36).slice(2)}`
  await db.add('activityLog', { ...activity, id })
  return id
}

export async function updateActivity(
  id: string,
  updates: Partial<ActivityLogEntry>
): Promise<void> {
  const db = await getDB()
  const activity = await db.get('activityLog', id)
  if (activity) {
    await db.put('activityLog', { ...activity, ...updates })
  }
}

export async function getRecentActivity(limit: number = 20): Promise<ActivityLogEntry[]> {
  const db = await getDB()
  const all = await db.getAllFromIndex('activityLog', 'by-date')
  return all.reverse().slice(0, limit)
}

export async function getActivityByModule(moduleId: string): Promise<ActivityLogEntry[]> {
  const db = await getDB()
  return db.getAllFromIndex('activityLog', 'by-module', moduleId)
}

// ============================================
// Settings Operations
// ============================================

export async function getSetting<T>(key: string, defaultValue: T): Promise<T> {
  const db = await getDB()
  const value = await db.get('settings', key)
  return (value as T) ?? defaultValue
}

export async function setSetting(key: string, value: unknown): Promise<void> {
  const db = await getDB()
  await db.put('settings', value, key)
}

// ============================================
// Sync Queue Operations
// ============================================

export type SyncQueueEntry = MaxPuzzlesDB['syncQueue']['value']

export async function addToSyncQueue(
  type: 'progress' | 'activity' | 'profile',
  data: unknown
): Promise<void> {
  const db = await getDB()
  const id = `sync-${Date.now()}-${Math.random().toString(36).slice(2)}`
  await db.add('syncQueue', {
    id,
    type,
    data,
    createdAt: new Date().toISOString(),
  })
}

export async function getSyncQueue(): Promise<SyncQueueEntry[]> {
  const db = await getDB()
  return db.getAll('syncQueue')
}

export async function clearSyncQueue(): Promise<void> {
  const db = await getDB()
  await db.clear('syncQueue')
}

export async function removeSyncItem(id: string): Promise<void> {
  const db = await getDB()
  await db.delete('syncQueue', id)
}

// ============================================
// Database Management
// ============================================

export async function clearAllData(): Promise<void> {
  const db = await getDB()
  await db.clear('guestProfile')
  await db.clear('moduleProgress')
  await db.clear('activityLog')
  await db.clear('settings')
  await db.clear('syncQueue')
}

export async function closeDB(): Promise<void> {
  if (dbInstance) {
    dbInstance.close()
    dbInstance = null
  }
}
