import { ReactNode } from 'react'
import { AuthProvider } from './AuthProvider'
import { StorageProvider } from './StorageProvider'
import { SoundProvider } from './SoundProvider'

interface AppProvidersProps {
  children: ReactNode
}

/**
 * Wraps the app with all required providers in correct order
 */
export function AppProviders({ children }: AppProvidersProps) {
  return (
    <StorageProvider>
      <AuthProvider>
        <SoundProvider>{children}</SoundProvider>
      </AuthProvider>
    </StorageProvider>
  )
}

// Re-export providers and hooks
export { AuthProvider, useAuth } from './AuthProvider'
export { StorageProvider, useStorageContext, useStorage } from './StorageProvider'
export { SoundProvider, useSound } from './SoundProvider'
