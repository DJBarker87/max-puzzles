import { openDB, IDBPDatabase } from 'idb'

interface MaxPuzzlesDB {
  settings: {
    key: string
    value: unknown
  }
  progress: {
    key: string
    value: {
      id: string
      moduleId: string
      userId: string
      data: unknown
      updatedAt: number
    }
    indexes: { 'by-user': string; 'by-module': string }
  }
  activity: {
    key: string
    value: {
      id: string
      userId: string
      moduleId: string
      timestamp: number
      data: unknown
    }
    indexes: { 'by-user': string; 'by-timestamp': number }
  }
}

const DB_NAME = 'max-puzzles'
const DB_VERSION = 1

let db: IDBPDatabase<MaxPuzzlesDB> | null = null

/**
 * Initialize the IndexedDB database
 */
export async function initDatabase(): Promise<IDBPDatabase<MaxPuzzlesDB>> {
  if (db) return db

  db = await openDB<MaxPuzzlesDB>(DB_NAME, DB_VERSION, {
    upgrade(database) {
      // Settings store
      if (!database.objectStoreNames.contains('settings')) {
        database.createObjectStore('settings')
      }

      // Progress store
      if (!database.objectStoreNames.contains('progress')) {
        const progressStore = database.createObjectStore('progress', { keyPath: 'id' })
        progressStore.createIndex('by-user', 'userId')
        progressStore.createIndex('by-module', 'moduleId')
      }

      // Activity store
      if (!database.objectStoreNames.contains('activity')) {
        const activityStore = database.createObjectStore('activity', { keyPath: 'id' })
        activityStore.createIndex('by-user', 'userId')
        activityStore.createIndex('by-timestamp', 'timestamp')
      }
    },
  })

  return db
}

/**
 * Save a value to the settings store
 */
export async function saveSetting(key: string, value: unknown): Promise<void> {
  const database = await initDatabase()
  await database.put('settings', value, key)
}

/**
 * Load a value from the settings store
 */
export async function loadSetting<T>(key: string): Promise<T | undefined> {
  const database = await initDatabase()
  return database.get('settings', key) as Promise<T | undefined>
}

/**
 * Clear all data from the database
 */
export async function clearDatabase(): Promise<void> {
  const database = await initDatabase()
  const tx = database.transaction(['settings', 'progress', 'activity'], 'readwrite')
  await Promise.all([
    tx.objectStore('settings').clear(),
    tx.objectStore('progress').clear(),
    tx.objectStore('activity').clear(),
    tx.done,
  ])
}

export const storageService = {
  init: initDatabase,
  saveSetting,
  loadSetting,
  clear: clearDatabase,
}
