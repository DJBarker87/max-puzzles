import { createContext, useContext, useState, useCallback, ReactNode } from 'react'
import type { User, Family, AuthState } from '@/shared/types/auth'

/** Child user info for family selection */
export interface Child {
  id: string
  displayName: string
  avatarEmoji?: string
}

interface AuthContextValue extends AuthState {
  /** The current family (if logged in) */
  family: Family | null
  /** Children in the family */
  children: Child[]
  /** Currently selected child */
  selectedChild: Child | null
  /** Whether in parent demo mode */
  isDemoMode: boolean
  /** Log in a user */
  login: (email: string, password: string) => Promise<void>
  /** Sign up a new user */
  signup: (email: string, password: string, displayName: string) => Promise<void>
  /** Log out the current user */
  logout: () => Promise<void>
  /** Switch to guest mode */
  setGuestMode: () => void
  /** Select a child and verify PIN */
  selectChild: (childId: string, pin: string) => Promise<void>
  /** Enter parent demo mode */
  enterDemoMode: () => void
  /** Exit demo mode */
  exitDemoMode: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

interface AuthProviderProps {
  children: ReactNode
}

/**
 * Authentication provider
 * Manages user authentication state
 */
export function AuthProvider({ children: childrenProp }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null)
  const [family, setFamily] = useState<Family | null>(null)
  const [children, setChildren] = useState<Child[]>([])
  const [selectedChild, setSelectedChild] = useState<Child | null>(null)
  const [isGuest, setIsGuest] = useState(true)
  const [isDemoMode, setIsDemoMode] = useState(false)
  const [isLoading, setIsLoading] = useState(false)

  const login = useCallback(async (email: string, password: string) => {
    setIsLoading(true)
    try {
      // TODO: Implement actual login with Supabase
      console.log('Login attempt:', email, password)
      // Stub implementation - simulate a parent login
      setUser({
        id: 'user-1',
        familyId: 'family-1',
        email,
        displayName: email.split('@')[0],
        role: 'parent',
        coins: 0,
        isActive: true,
      })
      setFamily({
        id: 'family-1',
        name: `${email.split('@')[0]}'s Family`,
        createdAt: new Date(),
      })
      // Stub children data
      setChildren([
        { id: 'child-1', displayName: 'Max', avatarEmoji: '👽' },
        { id: 'child-2', displayName: 'Sophie', avatarEmoji: '👽' },
      ])
      setIsGuest(false)
      setIsDemoMode(false)
      setSelectedChild(null)
    } finally {
      setIsLoading(false)
    }
  }, [])

  const signup = useCallback(async (email: string, password: string, displayName: string) => {
    setIsLoading(true)
    try {
      // TODO: Implement actual signup with Supabase
      console.log('Signup attempt:', email, password, displayName)
      // Stub implementation
      setUser({
        id: 'user-1',
        familyId: 'family-1',
        email,
        displayName,
        role: 'parent',
        coins: 0,
        isActive: true,
      })
      setFamily({
        id: 'family-1',
        name: `${displayName}'s Family`,
        createdAt: new Date(),
      })
      // New account starts with no children
      setChildren([])
      setIsGuest(false)
      setIsDemoMode(false)
      setSelectedChild(null)
    } finally {
      setIsLoading(false)
    }
  }, [])

  const logout = useCallback(async () => {
    setIsLoading(true)
    try {
      // TODO: Implement actual logout with Supabase
      console.log('Logout')
      setUser(null)
      setFamily(null)
      setChildren([])
      setSelectedChild(null)
      setIsGuest(true)
      setIsDemoMode(false)
    } finally {
      setIsLoading(false)
    }
  }, [])

  const setGuestMode = useCallback(() => {
    setUser(null)
    setFamily(null)
    setChildren([])
    setSelectedChild(null)
    setIsGuest(true)
    setIsDemoMode(false)
  }, [])

  const selectChild = useCallback(async (childId: string, pin: string) => {
    // TODO: Implement actual PIN verification with backend
    console.log('Select child:', childId, 'with PIN:', pin)

    // Stub: Accept any 4-digit PIN for now
    if (pin.length !== 4) {
      throw new Error('Invalid PIN')
    }

    // For demo, accept PIN "1234" for any child
    if (pin !== '1234') {
      throw new Error('Wrong PIN')
    }

    const child = children.find(c => c.id === childId)
    if (!child) {
      throw new Error('Child not found')
    }

    setSelectedChild(child)
    // Update user to reflect child session
    setUser({
      id: childId,
      familyId: family?.id || null,
      email: null,
      displayName: child.displayName,
      role: 'child',
      coins: 150, // Stub: child has some coins
      isActive: true,
    })
    setIsDemoMode(false)
  }, [children, family])

  const enterDemoMode = useCallback(() => {
    setIsDemoMode(true)
    setSelectedChild(null)
    // In demo mode, parent plays but nothing is tracked
    if (user && user.role === 'parent') {
      // Keep parent user but set demo flag
      setUser({
        ...user,
        displayName: `${user.displayName} (Demo)`,
      })
    }
  }, [user])

  const exitDemoMode = useCallback(() => {
    setIsDemoMode(false)
    // Restore original parent user
    if (user && user.role === 'parent') {
      const originalName = user.displayName.replace(' (Demo)', '')
      setUser({
        ...user,
        displayName: originalName,
      })
    }
  }, [user])

  const value: AuthContextValue = {
    user,
    family,
    children,
    selectedChild,
    isGuest,
    isDemoMode,
    isLoading,
    login,
    signup,
    logout,
    setGuestMode,
    selectChild,
    enterDemoMode,
    exitDemoMode,
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
