/// <reference types="vite/client" />
/// <reference types="vite-plugin-pwa/react" />

interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL: string
  readonly VITE_SUPABASE_ANON_KEY: string
  readonly VITE_ANALYTICS_ENABLED: string
  readonly VITE_FEATURE_PROGRESSION_MODE: string
  readonly VITE_FEATURE_SHOP: string
  readonly VITE_FEATURE_AVATARS: string
  readonly VITE_APP_VERSION: string
  readonly VITE_APP_BUILD_DATE: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
