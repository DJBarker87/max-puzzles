import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom'
import { lazy, Suspense } from 'react'

// Lazy load hub screens
const SplashScreen = lazy(() => import('@/hub/screens/SplashScreen'))
const LoginScreen = lazy(() => import('@/hub/screens/LoginScreen'))
const FamilySelectScreen = lazy(() => import('@/hub/screens/FamilySelectScreen'))
const MainHubScreen = lazy(() => import('@/hub/screens/MainHubScreen'))
const ModuleSelectScreen = lazy(() => import('@/hub/screens/ModuleSelectScreen'))
const SettingsScreen = lazy(() => import('@/hub/screens/SettingsScreen'))
const ShopScreen = lazy(() => import('@/hub/screens/ShopScreen'))
const AddChildScreen = lazy(() => import('@/hub/screens/AddChildScreen'))
const ParentDashboard = lazy(() => import('@/hub/screens/ParentDashboard'))

// Circuit Challenge screens
const ModuleMenu = lazy(() => import('@/modules/circuit-challenge/screens/ModuleMenu'))
const QuickPlaySetup = lazy(() => import('@/modules/circuit-challenge/screens/QuickPlaySetup'))
const GameScreen = lazy(() => import('@/modules/circuit-challenge/screens/GameScreen'))
const SummaryScreen = lazy(() => import('@/modules/circuit-challenge/screens/SummaryScreen'))

/**
 * Loading spinner for route transitions
 */
function RouteLoading() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-background-dark">
      <div className="text-center">
        <div className="w-12 h-12 border-4 border-accent-primary border-t-transparent rounded-full animate-spin mx-auto" />
        <p className="mt-4 text-text-secondary font-display">Loading...</p>
      </div>
    </div>
  )
}

/**
 * Wrap lazy components with Suspense
 */
function LazyRoute({ children }: { children: React.ReactNode }) {
  return <Suspense fallback={<RouteLoading />}>{children}</Suspense>
}

/**
 * Application routes
 */
const router = createBrowserRouter([
  // Splash
  {
    path: '/',
    element: (
      <LazyRoute>
        <SplashScreen />
      </LazyRoute>
    ),
  },

  // Auth
  {
    path: '/login',
    element: (
      <LazyRoute>
        <LoginScreen />
      </LazyRoute>
    ),
  },
  {
    path: '/family-select',
    element: (
      <LazyRoute>
        <FamilySelectScreen />
      </LazyRoute>
    ),
  },

  // Hub
  {
    path: '/hub',
    element: (
      <LazyRoute>
        <MainHubScreen />
      </LazyRoute>
    ),
  },
  {
    path: '/modules',
    element: (
      <LazyRoute>
        <ModuleSelectScreen />
      </LazyRoute>
    ),
  },
  {
    path: '/settings',
    element: (
      <LazyRoute>
        <SettingsScreen />
      </LazyRoute>
    ),
  },
  {
    path: '/shop',
    element: (
      <LazyRoute>
        <ShopScreen />
      </LazyRoute>
    ),
  },

  // Parent routes
  {
    path: '/parent/dashboard',
    element: (
      <LazyRoute>
        <ParentDashboard />
      </LazyRoute>
    ),
  },
  {
    path: '/parent/add-child',
    element: (
      <LazyRoute>
        <AddChildScreen />
      </LazyRoute>
    ),
  },

  // Circuit Challenge routes
  {
    path: '/play/circuit-challenge',
    element: (
      <LazyRoute>
        <ModuleMenu />
      </LazyRoute>
    ),
  },
  {
    path: '/play/circuit-challenge/quick',
    element: (
      <LazyRoute>
        <QuickPlaySetup />
      </LazyRoute>
    ),
  },
  {
    path: '/play/circuit-challenge/game',
    element: (
      <LazyRoute>
        <GameScreen />
      </LazyRoute>
    ),
  },
  {
    path: '/play/circuit-challenge/summary',
    element: (
      <LazyRoute>
        <SummaryScreen />
      </LazyRoute>
    ),
  },

  // Fallback - redirect to splash
  {
    path: '*',
    element: <Navigate to="/" replace />,
  },
])

/**
 * Router component to be used in App
 */
export function AppRouter() {
  return <RouterProvider router={router} />
}

export default router
