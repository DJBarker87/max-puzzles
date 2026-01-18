import { useState, useEffect, useCallback } from 'react'
import { saveSetting, loadSetting } from '../services/storage'

/**
 * Hook for persisting state to IndexedDB
 * @param key - The storage key
 * @param initialValue - The initial value if nothing is stored
 */
export function useStorage<T>(
  key: string,
  initialValue: T
): [T, (value: T | ((prev: T) => T)) => void, boolean] {
  const [storedValue, setStoredValue] = useState<T>(initialValue)
  const [isLoading, setIsLoading] = useState(true)

  // Load initial value from storage
  useEffect(() => {
    let mounted = true

    loadSetting<T>(key)
      .then((value) => {
        if (mounted && value !== undefined) {
          setStoredValue(value)
        }
      })
      .finally(() => {
        if (mounted) {
          setIsLoading(false)
        }
      })

    return () => {
      mounted = false
    }
  }, [key])

  // Update function that persists to storage
  const setValue = useCallback(
    (value: T | ((prev: T) => T)) => {
      setStoredValue((prev) => {
        const newValue = value instanceof Function ? value(prev) : value
        saveSetting(key, newValue).catch((err) => {
          console.error(`Failed to save ${key} to storage:`, err)
        })
        return newValue
      })
    },
    [key]
  )

  return [storedValue, setValue, isLoading]
}
