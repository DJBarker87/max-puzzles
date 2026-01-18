import { createContext, useContext, useEffect, useState, useCallback, ReactNode } from 'react'
import type { User, Family } from '@/shared/types/auth'
import * as authService from '@/shared/services/auth'
import * as syncService from '@/shared/services/sync'
import * as activityService from '@/shared/services/activity'
import { supabase } from '@/shared/services/supabase'

/** Child user info for family selection */
export interface Child {
  id: string
  displayName: string
  avatarEmoji?: string
  coins?: number
}

interface AuthState {
  user: User | null
  family: Family | null
  children: Child[]
  isGuest: boolean
  isDemoMode: boolean
  isLoading: boolean
  activeChildId: string | null
}

interface AuthContextValue extends AuthState {
  /** The currently selected child */
  selectedChild: Child | null
  /** Log in a user */
  login: (email: string, password: string) => Promise<void>
  /** Sign up a new user */
  signup: (email: string, password: string, displayName: string) => Promise<void>
  /** Log out the current user */
  logout: () => Promise<void>
  /** Switch to guest mode */
  setGuestMode: () => Promise<void>
  /** Select a child and verify PIN */
  selectChild: (childId: string, pin: string) => Promise<void>
  /** Enter parent demo mode */
  enterDemoMode: () => void
  /** Exit demo mode */
  exitDemoMode: () => void
  /** Add a new child to the family */
  addChild: (displayName: string, pin: string) => Promise<User | null>
  /** Remove a child from the family */
  removeChild: (childId: string) => Promise<void>
  /** Sync guest data to account */
  syncGuestToAccount: () => Promise<boolean>
  /** Check if Supabase is available */
  isOnline: boolean
}

const AuthContext = createContext<AuthContextValue | null>(null)

interface AuthProviderProps {
  children: ReactNode
}

/**
 * Authentication provider
 * Manages user authentication state with Supabase and offline support
 */
export function AuthProvider({ children: childrenProp }: AuthProviderProps) {
  const [state, setState] = useState<AuthState>({
    user: null,
    family: null,
    children: [],
    isGuest: false,
    isDemoMode: false,
    isLoading: true,
    activeChildId: null,
  })

  const isOnline = authService.isSupabaseConfigured()

  // Initialize on mount
  useEffect(() => {
    initializeAuth()
  }, [])

  // Listen for auth state changes
  useEffect(() => {
    if (!supabase) return

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN' && session?.user) {
        await loadUserData(session.user.id)
      } else if (event === 'SIGNED_OUT') {
        setState((prev) => ({
          ...prev,
          user: null,
          family: null,
          children: [],
          isGuest: false,
          isDemoMode: false,
          activeChildId: null,
        }))
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  async function initializeAuth() {
    try {
      // Check for existing session
      const user = await authService.getCurrentUser()

      if (user && user.familyId) {
        await loadUserData(user.id)
      }
    } catch (err) {
      console.error('Auth initialization error:', err)
    } finally {
      setState((prev) => ({ ...prev, isLoading: false }))
    }
  }

  async function loadUserData(userId: string) {
    const user = await authService.fetchUserById(userId)
    if (!user || !user.familyId) {
      // Try fetching by auth_id if direct user lookup failed
      const currentUser = await authService.getCurrentUser()
      if (!currentUser || !currentUser.familyId) return
      await loadUserDataInternal(currentUser)
      return
    }
    await loadUserDataInternal(user)
  }

  async function loadUserDataInternal(user: User) {
    if (!user.familyId) return

    const family = await authService.fetchFamily(user.familyId)
    const familyChildren = await authService.fetchFamilyChildren(user.familyId)

    setState((prev) => ({
      ...prev,
      user,
      family,
      children: familyChildren.map((c) => ({
        id: c.id,
        displayName: c.displayName,
        avatarEmoji: '👽',
        coins: c.coins,
      })),
      isGuest: false,
      isDemoMode: false,
      isLoading: false,
    }))
  }

  // ============================================
  // Auth Actions
  // ============================================

  const signup = useCallback(async (email: string, password: string, displayName: string) => {
    setState((prev) => ({ ...prev, isLoading: true }))

    const { user, error } = await authService.signUp(email, password, displayName)

    if (error) {
      setState((prev) => ({ ...prev, isLoading: false }))
      throw new Error(error)
    }

    if (user && user.familyId) {
      await loadUserDataInternal(user)
    }
  }, [])

  const login = useCallback(async (email: string, password: string) => {
    setState((prev) => ({ ...prev, isLoading: true }))

    const { user, error } = await authService.signIn(email, password)

    if (error) {
      setState((prev) => ({ ...prev, isLoading: false }))
      throw new Error(error)
    }

    if (user && user.familyId) {
      await loadUserDataInternal(user)
    }
  }, [])

  const logout = useCallback(async () => {
    await activityService.endSession(state.user?.id || null, state.isGuest)
    await authService.signOut()

    setState((prev) => ({
      ...prev,
      user: null,
      family: null,
      children: [],
      isGuest: false,
      isDemoMode: false,
      activeChildId: null,
    }))
  }, [state.user?.id, state.isGuest])

  // ============================================
  // Guest Mode
  // ============================================

  const setGuestMode = useCallback(async () => {
    const guestUser = await authService.initGuestProfile()

    setState((prev) => ({
      ...prev,
      user: guestUser,
      family: null,
      children: [],
      isGuest: true,
      isDemoMode: false,
      isLoading: false,
      activeChildId: null,
    }))
  }, [])

  // ============================================
  // Family Actions
  // ============================================

  const selectChild = useCallback(
    async (childId: string, pin: string) => {
      const isValid = await authService.verifyChildPin(childId, pin)

      if (!isValid) {
        throw new Error('Invalid PIN')
      }

      const child = state.children.find((c) => c.id === childId)
      if (!child) {
        throw new Error('Child not found')
      }

      // Fetch full child user data
      const childUser = await authService.fetchUserById(childId)
      if (!childUser) {
        throw new Error('Could not load child data')
      }

      setState((prev) => ({
        ...prev,
        user: childUser,
        activeChildId: childId,
        isDemoMode: false,
      }))
    },
    [state.children]
  )

  const enterDemoMode = useCallback(() => {
    if (!state.family) return

    // Create a temporary demo user
    const demoUser: User = {
      id: 'demo',
      familyId: state.family.id,
      email: null,
      displayName: 'Demo',
      role: 'parent',
      coins: 0,
      isActive: true,
    }

    setState((prev) => ({
      ...prev,
      user: demoUser,
      isDemoMode: true,
      activeChildId: null,
    }))
  }, [state.family])

  const exitDemoMode = useCallback(() => {
    // Return to parent selection
    setState((prev) => ({
      ...prev,
      user: null,
      isDemoMode: false,
      activeChildId: null,
    }))
  }, [])

  const addChild = useCallback(
    async (displayName: string, pin: string): Promise<User | null> => {
      if (!state.family?.id) return null

      const newChild = await authService.addChild(state.family.id, displayName, pin)

      if (newChild) {
        setState((prev) => ({
          ...prev,
          children: [
            ...prev.children,
            {
              id: newChild.id,
              displayName: newChild.displayName,
              avatarEmoji: '👽',
              coins: newChild.coins,
            },
          ],
        }))
      }

      return newChild
    },
    [state.family?.id]
  )

  const removeChild = useCallback(async (childId: string) => {
    const success = await authService.removeChild(childId)

    if (success) {
      setState((prev) => ({
        ...prev,
        children: prev.children.filter((c) => c.id !== childId),
      }))
    }
  }, [])

  // ============================================
  // Data Sync
  // ============================================

  const syncGuestToAccount = useCallback(async (): Promise<boolean> => {
    if (!state.user?.id || state.isGuest) return false

    const result = await syncService.syncGuestDataToAccount(state.user.id)
    return result.success
  }, [state.user?.id, state.isGuest])

  // ============================================
  // Context Value
  // ============================================

  const selectedChild = state.activeChildId
    ? state.children.find((c) => c.id === state.activeChildId) || null
    : null

  const value: AuthContextValue = {
    ...state,
    selectedChild,
    isOnline,
    login,
    signup,
    logout,
    setGuestMode,
    selectChild,
    enterDemoMode,
    exitDemoMode,
    addChild,
    removeChild,
    syncGuestToAccount,
  }

  return <AuthContext.Provider value={value}>{childrenProp}</AuthContext.Provider>
}

/**
 * Hook to access authentication state and methods
 */
export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
