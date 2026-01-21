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

// Parent dashboard screens
const ParentDashboard = lazy(() => import('@/hub/screens/ParentDashboard'))
const ChildDetailScreen = lazy(() => import('@/hub/screens/ChildDetailScreen'))
const ActivityHistoryScreen = lazy(() => import('@/hub/screens/ActivityHistoryScreen'))
const AddChildScreen = lazy(() => import('@/hub/screens/AddChildScreen'))
const EditChildScreen = lazy(() => import('@/hub/screens/EditChildScreen'))
const ResetPinScreen = lazy(() => import('@/hub/screens/ResetPinScreen'))
const ParentSettingsScreen = lazy(() => import('@/hub/screens/ParentSettingsScreen'))
const PrivacyPolicyScreen = lazy(() => import('@/hub/screens/PrivacyPolicyScreen'))

// Circuit Challenge screens
const ModuleMenu = lazy(() => import('@/modules/circuit-challenge/screens/ModuleMenu'))
const QuickPlaySetup = lazy(() => import('@/modules/circuit-challenge/screens/QuickPlaySetup'))
const GameScreen = lazy(() => import('@/modules/circuit-challenge/screens/GameScreen'))
const SummaryScreen = lazy(() => import('@/modules/circuit-challenge/screens/SummaryScreen'))
const PuzzleMakerScreen = lazy(() => import('@/modules/circuit-challenge/screens/PuzzleMakerScreen'))
const ChapterSelect = lazy(() => import('@/modules/circuit-challenge/screens/ChapterSelect'))
const LevelSelect = lazy(() => import('@/modules/circuit-challenge/screens/LevelSelect'))
const StoryGameScreen = lazy(() => import('@/modules/circuit-challenge/screens/StoryGameScreen'))

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
  // Landing page redirects to play
  {
    path: '/',
    element: <Navigate to="/play/circuit-challenge" replace />,
  },

  // Keep splash screen accessible if needed
  {
    path: '/splash',
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
  {
    path: '/privacy',
    element: (
      <LazyRoute>
        <PrivacyPolicyScreen />
      </LazyRoute>
    ),
  },

  // Parent dashboard routes
  {
    path: '/parent/dashboard',
    element: (
      <LazyRoute>
        <ParentDashboard />
      </LazyRoute>
    ),
  },
  {
    path: '/parent/child/:childId',
    element: (
      <LazyRoute>
        <ChildDetailScreen />
      </LazyRoute>
    ),
  },
  {
    path: '/parent/child/:childId/activity',
    element: (
      <LazyRoute>
        <ActivityHistoryScreen />
      </LazyRoute>
    ),
  },
  {
    path: '/parent/child/:childId/edit',
    element: (
      <LazyRoute>
        <EditChildScreen />
      </LazyRoute>
    ),
  },
  {
    path: '/parent/child/:childId/reset-pin',
    element: (
      <LazyRoute>
        <ResetPinScreen />
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
  {
    path: '/parent/settings',
    element: (
      <LazyRoute>
        <ParentSettingsScreen />
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
  {
    path: '/play/circuit-challenge/maker',
    element: (
      <LazyRoute>
        <PuzzleMakerScreen />
      </LazyRoute>
    ),
  },

  // Story Mode routes
  {
    path: '/play/circuit-challenge/story',
    element: (
      <LazyRoute>
        <ChapterSelect />
      </LazyRoute>
    ),
  },
  {
    path: '/play/circuit-challenge/story/:chapterId',
    element: (
      <LazyRoute>
        <LevelSelect />
      </LazyRoute>
    ),
  },
  {
    path: '/play/circuit-challenge/story/:chapterId/:levelId',
    element: (
      <LazyRoute>
        <StoryGameScreen />
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
