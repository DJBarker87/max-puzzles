# Phase 9: Polish, PWA & Deployment

**Goal:** Transform the app into a production-ready Progressive Web App with offline support, performance optimisation, and deployment to Vercel. This phase covers the final polish needed before launch.

---

## Subphase 9.1: PWA Configuration

### Prompt for Claude Code:

```
Set up Progressive Web App configuration with Vite PWA plugin.

1. Install the PWA plugin:

```bash
npm install vite-plugin-pwa -D
```

2. Update vite.config.ts:

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';
import path from 'path';

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.ico', 'apple-touch-icon.png', 'robots.txt'],
      manifest: {
        name: "Max's Puzzles",
        short_name: 'MaxPuzzles',
        description: 'Fun maths puzzles for children aged 5-11',
        theme_color: '#0a0a1a',
        background_color: '#0a0a1a',
        display: 'standalone',
        orientation: 'portrait',
        scope: '/',
        start_url: '/',
        icons: [
          {
            src: '/icons/icon-72x72.png',
            sizes: '72x72',
            type: 'image/png',
          },
          {
            src: '/icons/icon-96x96.png',
            sizes: '96x96',
            type: 'image/png',
          },
          {
            src: '/icons/icon-128x128.png',
            sizes: '128x128',
            type: 'image/png',
          },
          {
            src: '/icons/icon-144x144.png',
            sizes: '144x144',
            type: 'image/png',
          },
          {
            src: '/icons/icon-152x152.png',
            sizes: '152x152',
            type: 'image/png',
          },
          {
            src: '/icons/icon-192x192.png',
            sizes: '192x192',
            type: 'image/png',
            purpose: 'any maskable',
          },
          {
            src: '/icons/icon-384x384.png',
            sizes: '384x384',
            type: 'image/png',
          },
          {
            src: '/icons/icon-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'any maskable',
          },
        ],
        categories: ['education', 'games', 'kids'],
      },
      workbox: {
        // Cache strategies
        runtimeCaching: [
          {
            // Cache Google Fonts
            urlPattern: /^https:\/\/fonts\.googleapis\.com\/.*/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'google-fonts-cache',
              expiration: {
                maxEntries: 10,
                maxAgeSeconds: 60 * 60 * 24 * 365, // 1 year
              },
              cacheableResponse: {
                statuses: [0, 200],
              },
            },
          },
          {
            // Cache font files
            urlPattern: /^https:\/\/fonts\.gstatic\.com\/.*/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'gstatic-fonts-cache',
              expiration: {
                maxEntries: 10,
                maxAgeSeconds: 60 * 60 * 24 * 365, // 1 year
              },
              cacheableResponse: {
                statuses: [0, 200],
              },
            },
          },
          {
            // Cache images
            urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp)$/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'images-cache',
              expiration: {
                maxEntries: 50,
                maxAgeSeconds: 60 * 60 * 24 * 30, // 30 days
              },
            },
          },
          {
            // Cache audio files
            urlPattern: /\.(?:mp3|wav|ogg)$/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'audio-cache',
              expiration: {
                maxEntries: 20,
                maxAgeSeconds: 60 * 60 * 24 * 30, // 30 days
              },
            },
          },
        ],
        // Pre-cache critical assets
        globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
        // Skip waiting for faster updates
        skipWaiting: true,
        clientsClaim: true,
      },
      devOptions: {
        enabled: true, // Enable in dev for testing
      },
    }),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    // Optimise chunk splitting
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-supabase': ['@supabase/supabase-js'],
          'vendor-pdf': ['jspdf', 'svg2pdf.js'],
        },
      },
    },
    // Generate source maps for production debugging
    sourcemap: true,
  },
});
```

3. Create PWA icons directory structure:

```
public/
├── icons/
│   ├── icon-72x72.png
│   ├── icon-96x96.png
│   ├── icon-128x128.png
│   ├── icon-144x144.png
│   ├── icon-152x152.png
│   ├── icon-192x192.png
│   ├── icon-384x384.png
│   └── icon-512x512.png
├── apple-touch-icon.png (180x180)
├── favicon.ico
└── robots.txt
```

4. Create robots.txt:

```
User-agent: *
Allow: /

Sitemap: https://maxpuzzles.app/sitemap.xml
```

Note: You'll need to generate the actual icon images. Use a tool like:
- https://realfavicongenerator.net/
- Or create a simple icon with the alien emoji 👽 on a dark background
```

---

## Subphase 9.2: Service Worker Registration & Update Prompt

### Prompt for Claude Code:

```
Create a component to handle PWA updates and offline status.

File: src/shared/components/PWAUpdatePrompt.tsx

```typescript
import React, { useEffect, useState } from 'react';
import { useRegisterSW } from 'virtual:pwa-register/react';
import { Button, Card } from '@/ui';

/**
 * Handles PWA service worker registration and update prompts.
 * Shows a banner when a new version is available.
 */
export function PWAUpdatePrompt() {
  const [showUpdateBanner, setShowUpdateBanner] = useState(false);
  
  const {
    needRefresh: [needRefresh, setNeedRefresh],
    offlineReady: [offlineReady, setOfflineReady],
    updateServiceWorker,
  } = useRegisterSW({
    onRegistered(registration) {
      console.log('SW registered:', registration);
      
      // Check for updates every hour
      if (registration) {
        setInterval(() => {
          registration.update();
        }, 60 * 60 * 1000);
      }
    },
    onRegisterError(error) {
      console.error('SW registration error:', error);
    },
  });
  
  // Show update banner when new version available
  useEffect(() => {
    if (needRefresh) {
      setShowUpdateBanner(true);
    }
  }, [needRefresh]);
  
  // Handle update
  const handleUpdate = () => {
    updateServiceWorker(true);
    setShowUpdateBanner(false);
  };
  
  // Handle dismiss
  const handleDismiss = () => {
    setShowUpdateBanner(false);
    setNeedRefresh(false);
  };
  
  // Show offline ready toast briefly
  useEffect(() => {
    if (offlineReady) {
      // Could show a toast here
      console.log('App ready for offline use');
      
      // Auto-dismiss after 3 seconds
      const timer = setTimeout(() => {
        setOfflineReady(false);
      }, 3000);
      
      return () => clearTimeout(timer);
    }
  }, [offlineReady, setOfflineReady]);
  
  if (!showUpdateBanner && !offlineReady) {
    return null;
  }
  
  return (
    <div className="fixed bottom-4 left-4 right-4 z-50 md:left-auto md:right-4 md:w-96">
      {/* Offline Ready Toast */}
      {offlineReady && (
        <Card className="p-4 bg-accent-primary/20 border-accent-primary mb-2">
          <div className="flex items-center gap-3">
            <span className="text-2xl">✓</span>
            <div className="flex-1">
              <p className="font-medium">Ready to play offline!</p>
              <p className="text-sm text-text-secondary">
                The app is now available without internet.
              </p>
            </div>
          </div>
        </Card>
      )}
      
      {/* Update Available Banner */}
      {showUpdateBanner && (
        <Card className="p-4 bg-accent-secondary/20 border-accent-secondary">
          <div className="flex items-start gap-3">
            <span className="text-2xl">🆕</span>
            <div className="flex-1">
              <p className="font-medium">Update available!</p>
              <p className="text-sm text-text-secondary mb-3">
                A new version of Max's Puzzles is ready.
              </p>
              <div className="flex gap-2">
                <Button
                  variant="primary"
                  size="sm"
                  onClick={handleUpdate}
                >
                  Update Now
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleDismiss}
                >
                  Later
                </Button>
              </div>
            </div>
          </div>
        </Card>
      )}
    </div>
  );
}

export default PWAUpdatePrompt;
```

File: src/shared/hooks/useOnlineStatus.ts

```typescript
import { useState, useEffect } from 'react';

/**
 * Hook to track online/offline status.
 */
export function useOnlineStatus(): boolean {
  const [isOnline, setIsOnline] = useState(
    typeof navigator !== 'undefined' ? navigator.onLine : true
  );
  
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);
  
  return isOnline;
}
```

File: src/shared/components/OfflineBanner.tsx

```typescript
import React from 'react';
import { useOnlineStatus } from '../hooks/useOnlineStatus';

/**
 * Shows a banner when the app is offline.
 */
export function OfflineBanner() {
  const isOnline = useOnlineStatus();
  
  if (isOnline) {
    return null;
  }
  
  return (
    <div className="fixed top-0 left-0 right-0 z-50 bg-yellow-600 text-black text-center py-2 text-sm font-medium">
      📡 You're offline. Some features may be limited.
    </div>
  );
}

export default OfflineBanner;
```

Add these components to App.tsx:

```typescript
import { PWAUpdatePrompt } from '@/shared/components/PWAUpdatePrompt';
import { OfflineBanner } from '@/shared/components/OfflineBanner';

function App() {
  return (
    <AppProviders>
      <OfflineBanner />
      <RouterProvider router={router} />
      <PWAUpdatePrompt />
    </AppProviders>
  );
}
```
```

---

## Subphase 9.3: Install Prompt Component

### Prompt for Claude Code:

```
Create a component to prompt users to install the PWA.

File: src/shared/components/InstallPrompt.tsx

```typescript
import React, { useState, useEffect } from 'react';
import { Button, Card, Modal } from '@/ui';

// Store the deferred prompt event
let deferredPrompt: BeforeInstallPromptEvent | null = null;

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

/**
 * Prompts users to install the PWA on supported devices.
 */
export function InstallPrompt() {
  const [showPrompt, setShowPrompt] = useState(false);
  const [isInstalled, setIsInstalled] = useState(false);
  
  useEffect(() => {
    // Check if already installed
    if (window.matchMedia('(display-mode: standalone)').matches) {
      setIsInstalled(true);
      return;
    }
    
    // Listen for the beforeinstallprompt event
    const handler = (e: Event) => {
      e.preventDefault();
      deferredPrompt = e as BeforeInstallPromptEvent;
      
      // Show prompt after a delay (don't interrupt immediately)
      setTimeout(() => {
        // Only show if user has played at least one game
        const hasPlayed = localStorage.getItem('hasPlayedGame');
        if (hasPlayed) {
          setShowPrompt(true);
        }
      }, 30000); // 30 seconds
    };
    
    window.addEventListener('beforeinstallprompt', handler);
    
    // Listen for successful installation
    window.addEventListener('appinstalled', () => {
      setIsInstalled(true);
      setShowPrompt(false);
      deferredPrompt = null;
    });
    
    return () => {
      window.removeEventListener('beforeinstallprompt', handler);
    };
  }, []);
  
  const handleInstall = async () => {
    if (!deferredPrompt) return;
    
    // Show the install prompt
    await deferredPrompt.prompt();
    
    // Wait for the user's response
    const { outcome } = await deferredPrompt.userChoice;
    
    if (outcome === 'accepted') {
      console.log('User accepted install prompt');
    } else {
      console.log('User dismissed install prompt');
    }
    
    // Clear the prompt
    deferredPrompt = null;
    setShowPrompt(false);
  };
  
  const handleDismiss = () => {
    setShowPrompt(false);
    // Don't show again for 7 days
    localStorage.setItem('installPromptDismissed', Date.now().toString());
  };
  
  // Don't show if already installed or recently dismissed
  if (isInstalled) return null;
  
  const dismissedAt = localStorage.getItem('installPromptDismissed');
  if (dismissedAt) {
    const dismissedTime = parseInt(dismissedAt, 10);
    const sevenDays = 7 * 24 * 60 * 60 * 1000;
    if (Date.now() - dismissedTime < sevenDays) {
      return null;
    }
  }
  
  if (!showPrompt) return null;
  
  return (
    <Modal
      isOpen={showPrompt}
      onClose={handleDismiss}
      title="Install Max's Puzzles"
    >
      <div className="text-center">
        <div className="text-6xl mb-4">👽</div>
        <p className="mb-4">
          Install Max's Puzzles on your device for the best experience:
        </p>
        <ul className="text-sm text-text-secondary text-left mb-6 space-y-2">
          <li>✓ Play offline anytime</li>
          <li>✓ Faster loading</li>
          <li>✓ Full-screen experience</li>
          <li>✓ Easy access from home screen</li>
        </ul>
        
        <div className="flex gap-3">
          <Button
            variant="ghost"
            fullWidth
            onClick={handleDismiss}
          >
            Maybe Later
          </Button>
          <Button
            variant="primary"
            fullWidth
            onClick={handleInstall}
          >
            Install
          </Button>
        </div>
      </div>
    </Modal>
  );
}

export default InstallPrompt;
```

Add to App.tsx:

```typescript
import { InstallPrompt } from '@/shared/components/InstallPrompt';

// Inside the App component, add:
<InstallPrompt />
```
```

---

## Subphase 9.4: Performance Optimisation

### Prompt for Claude Code:

```
Implement performance optimisations for the app.

1. Create lazy loading for routes:

File: src/app/routes.tsx

```typescript
import React, { Suspense, lazy } from 'react';
import { createBrowserRouter } from 'react-router-dom';
import { LoadingScreen } from '@/shared/components/LoadingScreen';

// Eager load critical screens
import { SplashScreen } from '@/hub/screens/SplashScreen';
import { LoginScreen } from '@/hub/screens/LoginScreen';

// Lazy load other screens
const FamilySelectScreen = lazy(() => import('@/hub/screens/FamilySelectScreen'));
const MainHubScreen = lazy(() => import('@/hub/screens/MainHubScreen'));
const ModuleSelectScreen = lazy(() => import('@/hub/screens/ModuleSelectScreen'));
const SettingsScreen = lazy(() => import('@/hub/screens/SettingsScreen'));

// Parent screens (lazy)
const ParentDashboard = lazy(() => import('@/hub/screens/ParentDashboard'));
const ChildDetailScreen = lazy(() => import('@/hub/screens/ChildDetailScreen'));
const ActivityHistoryScreen = lazy(() => import('@/hub/screens/ActivityHistoryScreen'));
const AddChildScreen = lazy(() => import('@/hub/screens/AddChildScreen'));
const EditChildScreen = lazy(() => import('@/hub/screens/EditChildScreen'));
const ResetPinScreen = lazy(() => import('@/hub/screens/ResetPinScreen'));
const ParentSettingsScreen = lazy(() => import('@/hub/screens/ParentSettingsScreen'));

// Game screens (lazy)
const GameScreen = lazy(() => import('@/modules/circuit-challenge/screens/GameScreen'));
const PuzzleMakerScreen = lazy(() => import('@/modules/circuit-challenge/screens/PuzzleMakerScreen'));

// Wrap lazy components
function withSuspense(Component: React.LazyExoticComponent<any>) {
  return (
    <Suspense fallback={<LoadingScreen />}>
      <Component />
    </Suspense>
  );
}

export const router = createBrowserRouter([
  { path: '/', element: <SplashScreen /> },
  { path: '/login', element: <LoginScreen /> },
  { path: '/family-select', element: withSuspense(FamilySelectScreen) },
  { path: '/hub', element: withSuspense(MainHubScreen) },
  { path: '/modules', element: withSuspense(ModuleSelectScreen) },
  { path: '/settings', element: withSuspense(SettingsScreen) },
  
  // Parent routes
  { path: '/parent/dashboard', element: withSuspense(ParentDashboard) },
  { path: '/parent/child/:childId', element: withSuspense(ChildDetailScreen) },
  { path: '/parent/child/:childId/activity', element: withSuspense(ActivityHistoryScreen) },
  { path: '/parent/child/:childId/edit', element: withSuspense(EditChildScreen) },
  { path: '/parent/child/:childId/reset-pin', element: withSuspense(ResetPinScreen) },
  { path: '/parent/add-child', element: withSuspense(AddChildScreen) },
  { path: '/parent/settings', element: withSuspense(ParentSettingsScreen) },
  
  // Game routes
  { path: '/circuit-challenge/play', element: withSuspense(GameScreen) },
  { path: '/circuit-challenge/maker', element: withSuspense(PuzzleMakerScreen) },
]);
```

2. Create loading screen component:

File: src/shared/components/LoadingScreen.tsx

```typescript
import React from 'react';

export function LoadingScreen() {
  return (
    <div className="min-h-screen bg-background-dark flex items-center justify-center">
      <div className="text-center">
        <div className="text-6xl mb-4 animate-bounce">👽</div>
        <p className="text-text-secondary animate-pulse">Loading...</p>
      </div>
    </div>
  );
}
```

3. Implement memo for expensive components:

File: src/modules/circuit-challenge/components/HexGrid.tsx (update)

```typescript
import React, { memo, useMemo } from 'react';
// ... existing imports

// Memoize individual cells
const MemoizedHexCell = memo(HexCell);

export const HexGrid = memo(function HexGrid({ 
  cells, 
  onCellClick, 
  selectedPath 
}: HexGridProps) {
  // Memoize selected set
  const selectedSet = useMemo(
    () => new Set(selectedPath),
    [selectedPath]
  );
  
  // Memoize cell render
  const renderedCells = useMemo(() => {
    return cells.map((cell) => (
      <MemoizedHexCell
        key={cell.index}
        {...cell}
        isSelected={selectedSet.has(cell.index)}
        onClick={() => onCellClick(cell.index)}
      />
    ));
  }, [cells, selectedSet, onCellClick]);
  
  return (
    <div className="hex-grid">
      {renderedCells}
    </div>
  );
});
```

4. Add image optimisation:

File: src/shared/components/OptimisedImage.tsx

```typescript
import React, { useState } from 'react';

interface OptimisedImageProps {
  src: string;
  alt: string;
  className?: string;
  width?: number;
  height?: number;
}

export function OptimisedImage({
  src,
  alt,
  className,
  width,
  height,
}: OptimisedImageProps) {
  const [isLoaded, setIsLoaded] = useState(false);
  const [hasError, setHasError] = useState(false);
  
  return (
    <div className={`relative ${className}`}>
      {/* Placeholder while loading */}
      {!isLoaded && !hasError && (
        <div 
          className="absolute inset-0 bg-background-mid animate-pulse rounded"
          style={{ width, height }}
        />
      )}
      
      {/* Actual image */}
      <img
        src={src}
        alt={alt}
        width={width}
        height={height}
        loading="lazy"
        decoding="async"
        onLoad={() => setIsLoaded(true)}
        onError={() => setHasError(true)}
        className={`${isLoaded ? 'opacity-100' : 'opacity-0'} transition-opacity duration-300`}
      />
      
      {/* Error fallback */}
      {hasError && (
        <div 
          className="flex items-center justify-center bg-background-mid rounded text-2xl"
          style={{ width, height }}
        >
          🖼️
        </div>
      )}
    </div>
  );
}
```

5. Add performance monitoring hook:

File: src/shared/hooks/usePerformance.ts

```typescript
import { useEffect } from 'react';

/**
 * Reports Core Web Vitals metrics.
 */
export function usePerformanceMonitoring() {
  useEffect(() => {
    // Only in production
    if (import.meta.env.DEV) return;
    
    // Report metrics using web-vitals library if available
    const reportMetric = (metric: { name: string; value: number }) => {
      console.log(`[Performance] ${metric.name}:`, metric.value);
      
      // Could send to analytics here
      // analytics.track('web_vital', metric);
    };
    
    // Use Performance Observer for LCP, FID, CLS
    if ('PerformanceObserver' in window) {
      // Largest Contentful Paint
      const lcpObserver = new PerformanceObserver((list) => {
        const entries = list.getEntries();
        const lastEntry = entries[entries.length - 1];
        reportMetric({ name: 'LCP', value: lastEntry.startTime });
      });
      lcpObserver.observe({ type: 'largest-contentful-paint', buffered: true });
      
      // First Input Delay
      const fidObserver = new PerformanceObserver((list) => {
        const entries = list.getEntries();
        entries.forEach((entry: any) => {
          reportMetric({ name: 'FID', value: entry.processingStart - entry.startTime });
        });
      });
      fidObserver.observe({ type: 'first-input', buffered: true });
      
      // Cumulative Layout Shift
      let clsValue = 0;
      const clsObserver = new PerformanceObserver((list) => {
        for (const entry of list.getEntries() as any[]) {
          if (!entry.hadRecentInput) {
            clsValue += entry.value;
          }
        }
        reportMetric({ name: 'CLS', value: clsValue });
      });
      clsObserver.observe({ type: 'layout-shift', buffered: true });
      
      return () => {
        lcpObserver.disconnect();
        fidObserver.disconnect();
        clsObserver.disconnect();
      };
    }
  }, []);
}
```
```

---

## Subphase 9.5: Error Boundary & Crash Recovery

### Prompt for Claude Code:

```
Implement error boundaries and crash recovery.

File: src/shared/components/ErrorBoundary.tsx

```typescript
import React, { Component, ErrorInfo, ReactNode } from 'react';
import { Button, Card } from '@/ui';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

/**
 * Catches JavaScript errors in child components and displays a fallback UI.
 */
export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null,
    };
  }
  
  static getDerivedStateFromError(error: Error): Partial<State> {
    return { hasError: true, error };
  }
  
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    // Log error to console
    console.error('Error caught by boundary:', error, errorInfo);
    
    this.setState({ errorInfo });
    
    // Could send to error tracking service
    // errorTracking.captureException(error, { extra: errorInfo });
  }
  
  handleReset = () => {
    this.setState({ hasError: false, error: null, errorInfo: null });
  };
  
  handleReload = () => {
    window.location.reload();
  };
  
  handleGoHome = () => {
    window.location.href = '/';
  };
  
  render() {
    if (this.state.hasError) {
      // Custom fallback if provided
      if (this.props.fallback) {
        return this.props.fallback;
      }
      
      // Default error UI
      return (
        <div className="min-h-screen bg-background-dark flex items-center justify-center p-4">
          <Card className="max-w-md w-full p-6 text-center">
            <div className="text-6xl mb-4">😵</div>
            <h1 className="text-2xl font-bold mb-2">Oops! Something went wrong</h1>
            <p className="text-text-secondary mb-6">
              Don't worry, your progress has been saved. Try refreshing the page.
            </p>
            
            {/* Error details (dev only) */}
            {import.meta.env.DEV && this.state.error && (
              <details className="mb-6 text-left">
                <summary className="cursor-pointer text-sm text-text-secondary">
                  Error details
                </summary>
                <pre className="mt-2 p-2 bg-background-dark rounded text-xs overflow-auto">
                  {this.state.error.toString()}
                  {this.state.errorInfo?.componentStack}
                </pre>
              </details>
            )}
            
            <div className="space-y-3">
              <Button
                variant="primary"
                fullWidth
                onClick={this.handleReload}
              >
                🔄 Refresh Page
              </Button>
              <Button
                variant="secondary"
                fullWidth
                onClick={this.handleGoHome}
              >
                🏠 Go to Home
              </Button>
              <Button
                variant="ghost"
                fullWidth
                onClick={this.handleReset}
              >
                Try Again
              </Button>
            </div>
          </Card>
        </div>
      );
    }
    
    return this.props.children;
  }
}

/**
 * Hook to manually trigger error boundary.
 */
export function useErrorHandler() {
  const [, setError] = React.useState<Error | null>(null);
  
  return React.useCallback((error: Error) => {
    setError(() => {
      throw error;
    });
  }, []);
}
```

File: src/shared/components/GameErrorBoundary.tsx

```typescript
import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Card } from '@/ui';
import { ErrorBoundary } from './ErrorBoundary';

/**
 * Specialised error boundary for game screens.
 * Offers option to restart the game or return to hub.
 */
export function GameErrorBoundary({ children }: { children: React.ReactNode }) {
  return (
    <ErrorBoundary fallback={<GameErrorFallback />}>
      {children}
    </ErrorBoundary>
  );
}

function GameErrorFallback() {
  const navigate = useNavigate();
  
  return (
    <div className="min-h-screen bg-background-dark flex items-center justify-center p-4">
      <Card className="max-w-md w-full p-6 text-center">
        <div className="text-6xl mb-4">🎮💥</div>
        <h1 className="text-2xl font-bold mb-2">Game Crashed!</h1>
        <p className="text-text-secondary mb-6">
          Something went wrong with the puzzle. Your coins are safe!
        </p>
        
        <div className="space-y-3">
          <Button
            variant="primary"
            fullWidth
            onClick={() => window.location.reload()}
          >
            🔄 Try Again
          </Button>
          <Button
            variant="secondary"
            fullWidth
            onClick={() => navigate('/hub')}
          >
            🏠 Back to Hub
          </Button>
        </div>
      </Card>
    </div>
  );
}
```

Wrap the app in error boundaries:

File: src/App.tsx (update)

```typescript
import { ErrorBoundary } from '@/shared/components/ErrorBoundary';

function App() {
  return (
    <ErrorBoundary>
      <AppProviders>
        <OfflineBanner />
        <RouterProvider router={router} />
        <PWAUpdatePrompt />
        <InstallPrompt />
      </AppProviders>
    </ErrorBoundary>
  );
}
```

Wrap game screens with GameErrorBoundary in routes.
```

---

## Subphase 9.6: Analytics & Event Tracking (Optional)

### Prompt for Claude Code:

```
Create an analytics abstraction layer (privacy-respecting, optional).

File: src/shared/services/analytics.ts

```typescript
/**
 * Simple analytics abstraction.
 * Can be connected to any analytics provider or disabled entirely.
 */

// Check if analytics is enabled
const ANALYTICS_ENABLED = import.meta.env.VITE_ANALYTICS_ENABLED === 'true';

// Event types
export type AnalyticsEvent =
  | { name: 'game_started'; properties: { difficulty: number; mode: 'quickPlay' | 'progression' } }
  | { name: 'game_completed'; properties: { difficulty: number; won: boolean; timeMs: number; coinsEarned: number } }
  | { name: 'game_abandoned'; properties: { difficulty: number; reason: 'quit' | 'timeout' | 'error' } }
  | { name: 'puzzle_solved'; properties: { difficulty: number; timeMs: number; mistakes: number } }
  | { name: 'pdf_generated'; properties: { puzzleCount: number; difficulty: number } }
  | { name: 'child_added'; properties: Record<string, never> }
  | { name: 'pwa_installed'; properties: Record<string, never> }
  | { name: 'page_view'; properties: { path: string } };

/**
 * Track an analytics event.
 */
export function trackEvent(event: AnalyticsEvent): void {
  if (!ANALYTICS_ENABLED) return;
  
  // Log in development
  if (import.meta.env.DEV) {
    console.log('[Analytics]', event.name, event.properties);
    return;
  }
  
  // Send to analytics provider
  // Example: Google Analytics 4
  if (typeof gtag !== 'undefined') {
    gtag('event', event.name, event.properties);
  }
  
  // Example: Plausible
  if (typeof plausible !== 'undefined') {
    plausible(event.name, { props: event.properties });
  }
  
  // Example: Simple custom endpoint
  // fetch('/api/analytics', {
  //   method: 'POST',
  //   body: JSON.stringify(event),
  // });
}

/**
 * Track a page view.
 */
export function trackPageView(path: string): void {
  trackEvent({ name: 'page_view', properties: { path } });
}

/**
 * Hook to track page views on route changes.
 */
export function usePageTracking(): void {
  // Implementation would use useLocation from react-router
  // and call trackPageView on changes
}

// Type declarations for analytics libraries
declare global {
  function gtag(command: string, eventName: string, params?: Record<string, any>): void;
  function plausible(eventName: string, options?: { props?: Record<string, any> }): void;
}
```

Usage in game hook:

```typescript
import { trackEvent } from '@/shared/services/analytics';

// In useGame hook:
function handleGameComplete(won: boolean) {
  trackEvent({
    name: 'game_completed',
    properties: {
      difficulty: currentDifficulty,
      won,
      timeMs: elapsedTime,
      coinsEarned: won ? calculateCoins() : 0,
    },
  });
}
```
```

---

## Subphase 9.7: Environment Configuration

### Prompt for Claude Code:

```
Set up environment configuration for different environments.

1. Create environment files:

File: .env.example

```
# Supabase
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key

# Analytics (optional)
VITE_ANALYTICS_ENABLED=false

# Feature flags
VITE_FEATURE_PROGRESSION_MODE=false
VITE_FEATURE_SHOP=false
VITE_FEATURE_AVATARS=false

# App info
VITE_APP_VERSION=1.0.0
VITE_APP_BUILD_DATE=2025-01-18
```

File: .env.development

```
VITE_SUPABASE_URL=http://localhost:54321
VITE_SUPABASE_ANON_KEY=your_local_anon_key
VITE_ANALYTICS_ENABLED=false
VITE_FEATURE_PROGRESSION_MODE=true
VITE_FEATURE_SHOP=true
VITE_FEATURE_AVATARS=true
```

File: .env.production

```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_production_anon_key
VITE_ANALYTICS_ENABLED=true
VITE_FEATURE_PROGRESSION_MODE=false
VITE_FEATURE_SHOP=false
VITE_FEATURE_AVATARS=false
```

2. Create config helper:

File: src/shared/config/env.ts

```typescript
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
    buildDate: import.meta.env.VITE_APP_BUILD_DATE || new Date().toISOString().split('T')[0],
    isDev: import.meta.env.DEV,
    isProd: import.meta.env.PROD,
  },
} as const;

/**
 * Check if a feature is enabled.
 */
export function isFeatureEnabled(feature: keyof typeof config.features): boolean {
  return config.features[feature];
}

/**
 * Log configuration on startup (dev only).
 */
export function logConfig(): void {
  if (config.app.isDev) {
    console.log('[Config] Environment:', config);
  }
}
```

3. Create TypeScript definitions for env:

File: src/vite-env.d.ts

```typescript
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL: string;
  readonly VITE_SUPABASE_ANON_KEY: string;
  readonly VITE_ANALYTICS_ENABLED: string;
  readonly VITE_FEATURE_PROGRESSION_MODE: string;
  readonly VITE_FEATURE_SHOP: string;
  readonly VITE_FEATURE_AVATARS: string;
  readonly VITE_APP_VERSION: string;
  readonly VITE_APP_BUILD_DATE: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

4. Add .env files to .gitignore:

```
# Environment files
.env
.env.local
.env.production.local

# Keep examples
!.env.example
```
```

---

## Subphase 9.8: Vercel Deployment Configuration

### Prompt for Claude Code:

```
Set up Vercel deployment configuration.

1. Create vercel.json:

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "framework": "vite",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/icons/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/(.*).js",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/(.*).css",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/sw.js",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=0, must-revalidate"
        }
      ]
    },
    {
      "source": "/manifest.webmanifest",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=0, must-revalidate"
        },
        {
          "key": "Content-Type",
          "value": "application/manifest+json"
        }
      ]
    }
  ]
}
```

2. Update package.json scripts:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "type-check": "tsc --noEmit",
    "test": "vitest",
    "deploy": "vercel --prod"
  }
}
```

3. Create deployment checklist document:

File: DEPLOYMENT.md

```markdown
# Deployment Checklist

## Pre-Deployment

- [ ] All tests passing: `npm test`
- [ ] Type check passing: `npm run type-check`
- [ ] Lint check passing: `npm run lint`
- [ ] Build succeeds: `npm run build`
- [ ] Preview build locally: `npm run preview`

## Environment Variables (Vercel Dashboard)

Set these in Vercel project settings:

### Required
- `VITE_SUPABASE_URL` - Your Supabase project URL
- `VITE_SUPABASE_ANON_KEY` - Your Supabase anon key

### Optional
- `VITE_ANALYTICS_ENABLED` - Set to "true" to enable analytics
- `VITE_APP_VERSION` - App version string

## Supabase Setup

1. Create a new Supabase project
2. Run migrations from `supabase/migrations/`
3. Enable Row Level Security on all tables
4. Copy URL and anon key to Vercel

## Domain Setup

1. Add custom domain in Vercel
2. Configure DNS (CNAME or A record)
3. SSL certificate auto-provisioned

## Post-Deployment

- [ ] Test PWA installation on mobile
- [ ] Test offline functionality
- [ ] Test guest mode
- [ ] Test account creation
- [ ] Test puzzle generation
- [ ] Test print/PDF export
- [ ] Monitor error logs

## Rollback

If issues are found:
1. Go to Vercel dashboard
2. Select previous deployment
3. Click "Promote to Production"
```

4. Create GitHub Actions workflow (optional):

File: .github/workflows/deploy.yml

```yaml
name: Deploy to Vercel

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Type check
        run: npm run type-check
      
      - name: Lint
        run: npm run lint
      
      - name: Build
        run: npm run build
        env:
          VITE_SUPABASE_URL: ${{ secrets.VITE_SUPABASE_URL }}
          VITE_SUPABASE_ANON_KEY: ${{ secrets.VITE_SUPABASE_ANON_KEY }}
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
```
```

---

## Subphase 9.9: Final Polish & Testing

### Prompt for Claude Code:

```
Final polish items and testing checklist.

1. Add meta tags to index.html:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    
    <!-- Primary Meta Tags -->
    <title>Max's Puzzles - Fun Maths Games for Kids</title>
    <meta name="title" content="Max's Puzzles - Fun Maths Games for Kids" />
    <meta name="description" content="Educational maths puzzles for children aged 5-11. Practice addition and subtraction with Circuit Challenge!" />
    
    <!-- Theme -->
    <meta name="theme-color" content="#0a0a1a" />
    <meta name="color-scheme" content="dark" />
    
    <!-- iOS -->
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
    <meta name="apple-mobile-web-app-title" content="Max's Puzzles" />
    <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
    
    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="/favicon.ico" />
    <link rel="icon" type="image/png" sizes="32x32" href="/icons/icon-32x32.png" />
    <link rel="icon" type="image/png" sizes="16x16" href="/icons/icon-16x16.png" />
    
    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website" />
    <meta property="og:url" content="https://maxpuzzles.app/" />
    <meta property="og:title" content="Max's Puzzles - Fun Maths Games for Kids" />
    <meta property="og:description" content="Educational maths puzzles for children aged 5-11." />
    <meta property="og:image" content="https://maxpuzzles.app/og-image.png" />
    
    <!-- Twitter -->
    <meta property="twitter:card" content="summary_large_image" />
    <meta property="twitter:url" content="https://maxpuzzles.app/" />
    <meta property="twitter:title" content="Max's Puzzles - Fun Maths Games for Kids" />
    <meta property="twitter:description" content="Educational maths puzzles for children aged 5-11." />
    <meta property="twitter:image" content="https://maxpuzzles.app/og-image.png" />
    
    <!-- Prevent phone number detection -->
    <meta name="format-detection" content="telephone=no" />
    
    <!-- Preconnect to external domains -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

2. Create testing checklist:

File: TESTING.md

```markdown
# Testing Checklist

## Guest Mode
- [ ] Can play without account
- [ ] Progress saves to IndexedDB
- [ ] Coins accumulate correctly
- [ ] Can upgrade to account (data merges)

## Authentication
- [ ] Parent signup works
- [ ] Parent login works
- [ ] Password reset works
- [ ] Session persists across refresh
- [ ] Logout clears session

## Family Management
- [ ] Can add children (up to 5)
- [ ] Child PIN login works
- [ ] PIN reset works
- [ ] Can edit child name
- [ ] Can remove child (with confirmation)

## Gameplay
- [ ] Puzzles generate correctly at all 10 difficulties
- [ ] Start/end cells always connected
- [ ] Path selection works (tap cells)
- [ ] Path validation correct (connected, uses start/end)
- [ ] Win detection works (sum matches target)
- [ ] Lose detection works (wrong sum)
- [ ] Coins awarded on win
- [ ] Timer works
- [ ] Quit confirmation shows

## Parent Dashboard
- [ ] Shows all children
- [ ] Weekly stats calculate correctly
- [ ] Child detail screen loads
- [ ] Activity chart displays
- [ ] Activity history shows

## Puzzle Maker
- [ ] Difficulty selector works
- [ ] Puzzle count slider works
- [ ] Generate creates puzzles
- [ ] Preview displays correctly
- [ ] PDF downloads
- [ ] PDF prints correctly (black & white)
- [ ] Answer key included when selected

## PWA
- [ ] Install prompt shows (after engagement)
- [ ] App installs correctly
- [ ] Works offline (gameplay)
- [ ] Update prompt shows for new versions
- [ ] Service worker caches assets

## Responsive Design
- [ ] Mobile (320px - 480px)
- [ ] Tablet (768px - 1024px)
- [ ] Desktop (1024px+)
- [ ] Landscape orientation

## Accessibility
- [ ] Keyboard navigation works
- [ ] Focus indicators visible
- [ ] Touch targets large enough (44px minimum)
- [ ] Color contrast sufficient
- [ ] Screen reader announces game state

## Performance
- [ ] Initial load < 3 seconds
- [ ] Puzzle generation < 100ms
- [ ] Smooth animations (60fps)
- [ ] No memory leaks in long sessions

## Edge Cases
- [ ] Very long child names truncate
- [ ] Network error during save shows message
- [ ] Concurrent sessions handled
- [ ] Browser back button works
```

3. Add console welcome message:

File: src/main.tsx (update)

```typescript
// Add at the start of main.tsx
if (import.meta.env.PROD) {
  console.log(
    `%c🧩 Max's Puzzles v${import.meta.env.VITE_APP_VERSION || '1.0.0'}`,
    'color: #00ff88; font-size: 16px; font-weight: bold;'
  );
  console.log(
    '%cMade with ❤️ for Max',
    'color: #888; font-size: 12px;'
  );
}
```
```

---

## Subphase 9.10: Documentation

### Prompt for Claude Code:

```
Create essential documentation files.

File: README.md

```markdown
# Max's Puzzles 🧩

Educational maths puzzle games for children aged 5-11.

## Features

- **Circuit Challenge**: Find paths through number grids that sum to a target
- 10 difficulty levels from Beginner to Master
- Guest mode for instant play
- Family accounts with parent dashboard
- Progress tracking and statistics
- Printable worksheets for classroom use
- Works offline as a PWA

## Tech Stack

- React 18 + TypeScript
- Vite + PWA
- Tailwind CSS
- Supabase (Auth + Database)
- IndexedDB (offline storage)
- jsPDF (print generation)

## Getting Started

### Prerequisites

- Node.js 18+
- npm 9+
- Supabase account (for backend)

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/max-puzzles.git
cd max-puzzles

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Add your Supabase credentials to .env

# Start development server
npm run dev
```

### Development

```bash
# Run dev server
npm run dev

# Type check
npm run type-check

# Lint
npm run lint

# Build for production
npm run build

# Preview production build
npm run preview
```

## Project Structure

```
src/
├── app/                 # App-level setup (routes, providers)
├── hub/                 # Hub screens (login, family, settings)
├── modules/             # Game modules
│   └── circuit-challenge/
│       ├── components/  # Game UI components
│       ├── engine/      # Puzzle generation
│       ├── hooks/       # Game logic hooks
│       ├── screens/     # Game screens
│       └── services/    # Print services
├── shared/              # Shared utilities
│   ├── components/      # Common components
│   ├── hooks/           # Common hooks
│   ├── services/        # Data services
│   └── utils/           # Utility functions
└── ui/                  # Design system components
```

## Deployment

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions.

## License

Private - All rights reserved.
```

File: CHANGELOG.md

```markdown
# Changelog

All notable changes to Max's Puzzles will be documented in this file.

## [1.0.0] - 2025-XX-XX

### Added
- Circuit Challenge puzzle game
- 10 difficulty levels
- Guest mode with local progress
- Family accounts (parent + up to 5 children)
- Parent dashboard with child statistics
- Activity tracking and charts
- Printable worksheet generator
- PWA support with offline play
- Coin reward system

### Technical
- React 18 + TypeScript
- Vite build system
- Supabase backend
- IndexedDB for offline storage
- Tailwind CSS styling
```

File: CONTRIBUTING.md (if open source)

```markdown
# Contributing to Max's Puzzles

Thank you for your interest in contributing!

## Development Setup

1. Fork the repository
2. Clone your fork
3. Install dependencies: `npm install`
4. Create a branch: `git checkout -b feature/your-feature`
5. Make your changes
6. Run tests: `npm test`
7. Commit: `git commit -m "Add your feature"`
8. Push: `git push origin feature/your-feature`
9. Open a Pull Request

## Code Style

- Use TypeScript for all new code
- Follow existing patterns
- Add types for all functions
- Write meaningful commit messages

## Reporting Issues

Please include:
- Browser and version
- Steps to reproduce
- Expected vs actual behaviour
- Screenshots if relevant
```
```

---

## Phase 9 Completion Checklist

After completing all subphases, verify:

- [ ] PWA manifest configured correctly
- [ ] Service worker caches assets
- [ ] Offline mode works
- [ ] Update prompt shows for new versions
- [ ] Install prompt shows on supported devices
- [ ] App installs correctly on mobile
- [ ] Lazy loading reduces initial bundle
- [ ] Error boundaries catch crashes
- [ ] Performance monitoring active
- [ ] Environment variables configured
- [ ] Vercel deployment works
- [ ] Custom domain configured (if applicable)
- [ ] Meta tags for SEO/sharing
- [ ] Documentation complete

---

## Files Created in Phase 9

```
├── vite.config.ts (updated)
├── vercel.json
├── .env.example
├── .env.development
├── .env.production
├── DEPLOYMENT.md
├── TESTING.md
├── README.md
├── CHANGELOG.md
├── index.html (updated)
├── public/
│   ├── icons/
│   │   └── (PWA icons)
│   ├── apple-touch-icon.png
│   ├── favicon.ico
│   └── robots.txt
└── src/
    ├── main.tsx (updated)
    ├── App.tsx (updated)
    ├── vite-env.d.ts
    └── shared/
        ├── components/
        │   ├── PWAUpdatePrompt.tsx
        │   ├── OfflineBanner.tsx
        │   ├── InstallPrompt.tsx
        │   ├── LoadingScreen.tsx
        │   ├── ErrorBoundary.tsx
        │   ├── GameErrorBoundary.tsx
        │   └── OptimisedImage.tsx
        ├── hooks/
        │   ├── useOnlineStatus.ts
        │   └── usePerformance.ts
        ├── services/
        │   └── analytics.ts
        └── config/
            └── env.ts
```

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         VERCEL                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                    CDN / Edge                        │    │
│  │  • Static assets (JS, CSS, images)                  │    │
│  │  • Service worker                                    │    │
│  │  • PWA manifest                                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                            │                                 │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                 React SPA                            │    │
│  │  • Client-side routing                              │    │
│  │  • Lazy-loaded modules                              │    │
│  │  • IndexedDB for offline                            │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                       SUPABASE                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │     Auth     │  │   Database   │  │   Storage    │      │
│  │              │  │              │  │  (Future)    │      │
│  │ • Email/Pass │  │ • Users      │  │              │      │
│  │ • Sessions   │  │ • Families   │  │ • Avatars    │      │
│  │              │  │ • Progress   │  │ • Assets     │      │
│  │              │  │ • Activity   │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

---

*End of Phase 9 - Ready for Production! 🚀*
