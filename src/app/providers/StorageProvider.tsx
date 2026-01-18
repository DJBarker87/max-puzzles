import { createContext, useContext, useEffect, useState, useCallback, ReactNode } from 'react'
import { storageService } from '@/shared/services/storage'

interface StorageContextValue {
  /** Whether storage is initialized */
  isReady: boolean
  /** Save a value to storage */
  save: <T>(key: string, value: T) => Promise<void>
  /** Load a value from storage */
  load: <T>(key: string) => Promise<T | undefined>
  /** Clear all stored data */
  clear: () => Promise<void>
}

const StorageContext = createContext<StorageContextValue | null>(null)

interface StorageProviderProps {
  children: ReactNode
}

/**
 * Storage provider
 * Manages IndexedDB persistence
 */
export function StorageProvider({ children }: StorageProviderProps) {
  const [isReady, setIsReady] = useState(false)

  // Initialize database on mount
  useEffect(() => {
    storageService
      .init()
      .then(() => {
        setIsReady(true)
      })
      .catch((err) => {
        console.error('Failed to initialize storage:', err)
        // Still mark as ready to allow app to function
        setIsReady(true)
      })
  }, [])

  const save = useCallback(async <T,>(key: string, value: T): Promise<void> => {
    await storageService.saveSetting(key, value)
  }, [])

  const load = useCallback(async <T,>(key: string): Promise<T | undefined> => {
    return storageService.loadSetting<T>(key)
  }, [])

  const clear = useCallback(async (): Promise<void> => {
    await storageService.clear()
  }, [])

  const value: StorageContextValue = {
    isReady,
    save,
    load,
    clear,
  }

  return (
    <StorageContext.Provider value={value}>{children}</StorageContext.Provider>
  )
}

/**
 * Hook to access storage methods
 */
export function useStorageContext(): StorageContextValue {
  const context = useContext(StorageContext)
  if (!context) {
    throw new Error('useStorageContext must be used within a StorageProvider')
  }
  return context
}
