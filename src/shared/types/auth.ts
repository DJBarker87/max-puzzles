/**
 * User role types
 */
export type UserRole = 'parent' | 'child'

/**
 * User profile information
 */
export interface User {
  /** Unique user identifier */
  id: string
  /** Family this user belongs to (null for guest users) */
  familyId: string | null
  /** Email address (parents only) */
  email: string | null
  /** Display name shown in the app */
  displayName: string
  /** User role (parent or child) */
  role: UserRole
  /** Current coin balance */
  coins: number
  /** Whether the user account is active */
  isActive: boolean
}

/**
 * Family group containing parents and children
 */
export interface Family {
  /** Unique family identifier */
  id: string
  /** Family display name */
  name: string
  /** When the family was created */
  createdAt: Date
}

/**
 * Current authentication state
 */
export interface AuthState {
  /** Current user (null if not logged in) */
  user: User | null
  /** Whether using guest mode (no account) */
  isGuest: boolean
  /** Whether auth state is loading */
  isLoading: boolean
}

/**
 * Child session for PIN-based sub-authentication
 */
export interface ChildSession {
  /** Child's user ID */
  childId: string
  /** Child's display name */
  displayName: string
  /** Family this child belongs to */
  familyId: string
}

/**
 * Parent session with full account access
 */
export interface ParentSession {
  /** Parent's user ID */
  userId: string
  /** Parent's email */
  email: string
  /** Family ID */
  familyId: string
  /** Session token */
  token: string
}
