/**
 * Database types for Supabase
 * This file defines the TypeScript types that match the database schema
 */

// Row types for each table
export interface FamilyRow {
  id: string
  name: string
  created_at: string
}

export interface UserRow {
  id: string
  family_id: string | null
  auth_id: string | null
  email: string | null
  display_name: string
  role: 'parent' | 'child'
  coins: number
  pin_hash: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface ModuleProgressRow {
  id: string
  user_id: string
  module_id: string
  data: Record<string, unknown>
  created_at: string
  updated_at: string
}

export interface ActivityLogRow {
  id: string
  user_id: string
  module_id: string
  session_start: string
  session_end: string | null
  duration_seconds: number
  games_played: number
  correct_answers: number
  mistakes: number
  coins_earned: number
}

// Insert types
export interface FamilyInsert {
  id?: string
  name: string
  created_at?: string
}

export interface UserInsert {
  id?: string
  family_id?: string | null
  auth_id?: string | null
  email?: string | null
  display_name: string
  role: 'parent' | 'child'
  coins?: number
  pin_hash?: string | null
  is_active?: boolean
}

export interface ModuleProgressInsert {
  id?: string
  user_id: string
  module_id: string
  data?: Record<string, unknown>
}

export interface ActivityLogInsert {
  id?: string
  user_id: string
  module_id: string
  session_start?: string
  session_end?: string | null
  duration_seconds?: number
  games_played?: number
  correct_answers?: number
  mistakes?: number
  coins_earned?: number
}

// Update types
export interface UserUpdate {
  display_name?: string
  coins?: number
  pin_hash?: string | null
  is_active?: boolean
}

export interface ModuleProgressUpdate {
  data?: Record<string, unknown>
  updated_at?: string
}

export interface ActivityLogUpdate {
  session_end?: string | null
  duration_seconds?: number
  games_played?: number
  correct_answers?: number
  mistakes?: number
  coins_earned?: number
}

// Full database schema type for Supabase client
export interface Database {
  public: {
    Tables: {
      families: {
        Row: FamilyRow
        Insert: FamilyInsert
        Update: Partial<FamilyInsert>
      }
      users: {
        Row: UserRow
        Insert: UserInsert
        Update: UserUpdate
      }
      module_progress: {
        Row: ModuleProgressRow
        Insert: ModuleProgressInsert
        Update: ModuleProgressUpdate
      }
      activity_log: {
        Row: ActivityLogRow
        Insert: ActivityLogInsert
        Update: ActivityLogUpdate
      }
    }
    Functions: {
      add_coins: {
        Args: { p_user_id: string; p_amount: number }
        Returns: number
      }
    }
  }
}
