/**
 * Environment configuration with type safety.
 */

export const config = {
  // Supabase
  supabase: {
    url: import.meta.env.VITE_SUPABASE_URL || '',
    anonKey: import.meta.env.VITE_SUPABASE_ANON_KEY || '',
  },

  // Analytics
  analytics: {
    enabled: import.meta.env.VITE_ANALYTICS_ENABLED === 'true',
  },

  // Feature flags
  features: {
    progressionMode: import.meta.env.VITE_FEATURE_PROGRESSION_MODE === 'true',
    shop: import.meta.env.VITE_FEATURE_SHOP === 'true',
    avatars: import.meta.env.VITE_FEATURE_AVATARS === 'true',
  },

  // App info
  app: {
    version: import.meta.env.VITE_APP_VERSION || '1.0.0',
    buildDate:
      import.meta.env.VITE_APP_BUILD_DATE || new Date().toISOString().split('T')[0],
    isDev: import.meta.env.DEV,
    isProd: import.meta.env.PROD,
  },
} as const

/**
 * Check if a feature is enabled.
 */
export function isFeatureEnabled(feature: keyof typeof config.features): boolean {
  return config.features[feature]
}

/**
 * Log configuration on startup (dev only).
 */
export function logConfig(): void {
  if (config.app.isDev) {
    console.log('[Config] Environment:', config)
  }
}
