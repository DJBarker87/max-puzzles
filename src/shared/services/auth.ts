import { supabase, isSupabaseConfigured } from './supabase'
import * as localDB from './indexedDB'
import type { User, Family } from '@/shared/types/auth'
import type { UserRow, UserInsert, UserUpdate } from './database.types'

// ============================================
// Authentication Functions
// ============================================

export async function signUp(
  email: string,
  password: string,
  displayName: string
): Promise<{ user: User | null; error: string | null }> {
  if (!supabase) {
    return { user: null, error: 'Supabase not configured. Please use guest mode.' }
  }

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { display_name: displayName },
    },
  })

  if (error) {
    return { user: null, error: error.message }
  }

  // The database trigger will create the user record
  // Fetch the created user after a short delay to allow trigger to complete
  if (data.user) {
    // Wait briefly for the trigger to create the user record
    await new Promise((resolve) => setTimeout(resolve, 500))
    const user = await fetchUserByAuthId(data.user.id)
    return { user, error: null }
  }

  return { user: null, error: 'Signup succeeded but user not found' }
}

export async function signIn(
  email: string,
  password: string
): Promise<{ user: User | null; error: string | null }> {
  if (!supabase) {
    return { user: null, error: 'Supabase not configured. Please use guest mode.' }
  }

  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (error) {
    return { user: null, error: error.message }
  }

  if (data.user) {
    const user = await fetchUserByAuthId(data.user.id)
    return { user, error: null }
  }

  return { user: null, error: 'Login succeeded but user not found' }
}

export async function signOut(): Promise<void> {
  if (supabase) {
    await supabase.auth.signOut()
  }
}

export async function getCurrentSession() {
  if (!supabase) return null

  const {
    data: { session },
  } = await supabase.auth.getSession()
  return session
}

export async function getCurrentUser(): Promise<User | null> {
  const session = await getCurrentSession()
  if (!session) return null

  return fetchUserByAuthId(session.user.id)
}

// ============================================
// User Data Functions
// ============================================

function mapRowToUser(row: UserRow): User {
  return {
    id: row.id,
    familyId: row.family_id,
    email: row.email,
    displayName: row.display_name,
    role: row.role,
    coins: row.coins,
    isActive: row.is_active,
  }
}

async function fetchUserByAuthId(authId: string): Promise<User | null> {
  if (!supabase) return null

  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('auth_id', authId)
    .single()

  if (error || !data) return null

  return mapRowToUser(data)
}

export async function fetchUserById(userId: string): Promise<User | null> {
  if (!supabase) return null

  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single()

  if (error || !data) return null

  return mapRowToUser(data)
}

export async function fetchFamily(familyId: string): Promise<Family | null> {
  if (!supabase) return null

  const { data, error } = await supabase
    .from('families')
    .select('*')
    .eq('id', familyId)
    .single()

  if (error || !data) return null

  return {
    id: data.id,
    name: data.name,
    createdAt: new Date(data.created_at),
  }
}

export async function fetchFamilyChildren(familyId: string): Promise<User[]> {
  if (!supabase) return []

  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('family_id', familyId)
    .eq('role', 'child')
    .eq('is_active', true)

  if (error || !data) return []

  return data.map(mapRowToUser)
}

// ============================================
// Child PIN Functions
// ============================================

// Simple hash for PIN (using base64 encoding with salt)
// In production, use bcrypt or similar on the server side
function hashPin(pin: string): string {
  return btoa(pin + 'max-puzzles-salt-v1')
}

export async function verifyChildPin(childId: string, pin: string): Promise<boolean> {
  if (!supabase) return false

  const { data, error } = await supabase
    .from('users')
    .select('pin_hash')
    .eq('id', childId)
    .single()

  if (error || !data) return false

  return data.pin_hash === hashPin(pin)
}

export async function setChildPin(childId: string, pin: string): Promise<boolean> {
  if (!supabase) return false

  const updateData: UserUpdate = { pin_hash: hashPin(pin) }
  const { error } = await supabase
    .from('users')
    .update(updateData)
    .eq('id', childId)

  return !error
}

export async function addChild(
  familyId: string,
  displayName: string,
  pin: string
): Promise<User | null> {
  if (!supabase) return null

  const insertData: UserInsert = {
    family_id: familyId,
    display_name: displayName,
    role: 'child',
    pin_hash: hashPin(pin),
    coins: 0,
  }

  const { data, error } = await supabase
    .from('users')
    .insert(insertData)
    .select()
    .single()

  if (error || !data) return null

  return mapRowToUser(data)
}

export async function updateChild(
  childId: string,
  updates: { displayName?: string; pin?: string }
): Promise<boolean> {
  if (!supabase) return false

  const updateData: UserUpdate = {}
  if (updates.displayName) {
    updateData.display_name = updates.displayName
  }
  if (updates.pin) {
    updateData.pin_hash = hashPin(updates.pin)
  }

  const { error } = await supabase.from('users').update(updateData).eq('id', childId)

  return !error
}

export async function removeChild(childId: string): Promise<boolean> {
  if (!supabase) return false

  // Soft delete
  const updateData: UserUpdate = { is_active: false }
  const { error } = await supabase
    .from('users')
    .update(updateData)
    .eq('id', childId)

  return !error
}

// ============================================
// Guest Mode Functions
// ============================================

export async function initGuestProfile(): Promise<User> {
  let profile = await localDB.getGuestProfile()

  if (!profile) {
    profile = {
      id: `guest-${Date.now()}`,
      displayName: 'Guest',
      coins: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }
    await localDB.setGuestProfile(profile)
  }

  return {
    id: profile.id,
    familyId: null,
    email: null,
    displayName: profile.displayName,
    role: 'child', // Guests play as children
    coins: profile.coins,
    isActive: true,
  }
}

export async function updateGuestDisplayName(name: string): Promise<void> {
  const profile = await localDB.getGuestProfile()
  if (profile) {
    profile.displayName = name
    profile.updatedAt = new Date().toISOString()
    await localDB.setGuestProfile(profile)
  }
}

export async function getGuestCoins(): Promise<number> {
  const profile = await localDB.getGuestProfile()
  return profile?.coins ?? 0
}

export { isSupabaseConfigured }
