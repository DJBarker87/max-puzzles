import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string | undefined
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase credentials not configured. Running in offline mode only.')
}

// Create client only if credentials are available
// Using loose typing to avoid strict type inference issues
const client =
  supabaseUrl && supabaseAnonKey
    ? createClient(supabaseUrl, supabaseAnonKey, {
        auth: {
          autoRefreshToken: true,
          persistSession: true,
          detectSessionInUrl: true,
        },
      })
    : null

/**
 * Supabase client instance
 * Will be null if credentials are not configured (offline mode)
 */
export const supabase = client

/**
 * Check if Supabase is configured and available
 */
export function isSupabaseConfigured(): boolean {
  return client !== null
}
