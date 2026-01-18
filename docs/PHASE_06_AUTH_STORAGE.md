# Phase 6: Authentication & Storage

**Goal:** Implement the complete data layer - Supabase for authenticated users, IndexedDB for offline/guest mode, the auth provider with real functionality, and sync service for merging local and cloud data.

---

## Subphase 6.1: Supabase Project Setup

### Prompt for Claude Code:

```
Set up Supabase configuration and client initialization.

1. Create environment files:

File: .env.example
```
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

File: .env.local (add to .gitignore)
```
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

2. Create Supabase client:

File: src/shared/services/supabase.ts

```typescript
import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase credentials not configured. Running in offline mode only.');
}

export const supabase = supabaseUrl && supabaseAnonKey
  ? createClient<Database>(supabaseUrl, supabaseAnonKey, {
      auth: {
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: true,
      },
    })
  : null;

export const isSupabaseConfigured = () => supabase !== null;
```

3. Create database types file (placeholder - will be generated from Supabase):

File: src/shared/services/database.types.ts

```typescript
export interface Database {
  public: {
    Tables: {
      families: {
        Row: {
          id: string;
          name: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          created_at?: string;
        };
        Update: {
          name?: string;
        };
      };
      users: {
        Row: {
          id: string;
          family_id: string | null;
          email: string | null;
          display_name: string;
          role: 'parent' | 'child';
          coins: number;
          pin_hash: string | null;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          family_id?: string | null;
          email?: string | null;
          display_name: string;
          role: 'parent' | 'child';
          coins?: number;
          pin_hash?: string | null;
          is_active?: boolean;
        };
        Update: {
          display_name?: string;
          coins?: number;
          pin_hash?: string | null;
          is_active?: boolean;
        };
      };
      module_progress: {
        Row: {
          id: string;
          user_id: string;
          module_id: string;
          data: Record<string, unknown>;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          module_id: string;
          data?: Record<string, unknown>;
        };
        Update: {
          data?: Record<string, unknown>;
          updated_at?: string;
        };
      };
      activity_log: {
        Row: {
          id: string;
          user_id: string;
          module_id: string;
          session_start: string;
          session_end: string | null;
          duration_seconds: number;
          games_played: number;
          correct_answers: number;
          mistakes: number;
          coins_earned: number;
        };
        Insert: {
          id?: string;
          user_id: string;
          module_id: string;
          session_start?: string;
          session_end?: string | null;
          duration_seconds?: number;
          games_played?: number;
          correct_answers?: number;
          mistakes?: number;
          coins_earned?: number;
        };
        Update: {
          session_end?: string | null;
          duration_seconds?: number;
          games_played?: number;
          correct_answers?: number;
          mistakes?: number;
          coins_earned?: number;
        };
      };
    };
  };
}
```

4. Update vite.config.ts to handle env variables if needed.

Export supabase client and helper functions.
```

---

## Subphase 6.2: Supabase Database Migrations

### Prompt for Claude Code:

```
Create Supabase database migrations for all required tables.

File: supabase/migrations/001_initial_schema.sql

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- FAMILIES TABLE
-- ============================================
CREATE TABLE families (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- USERS TABLE (Parents and Children)
-- ============================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  auth_id UUID UNIQUE, -- Links to Supabase auth.users for parents
  email VARCHAR(255) UNIQUE,
  display_name VARCHAR(50) NOT NULL,
  role VARCHAR(10) NOT NULL CHECK (role IN ('parent', 'child')),
  coins INTEGER DEFAULT 0 CHECK (coins >= 0),
  pin_hash VARCHAR(255), -- For children only, hashed 4-digit PIN
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for family lookups
CREATE INDEX idx_users_family_id ON users(family_id);

-- ============================================
-- MODULE PROGRESS TABLE
-- ============================================
CREATE TABLE module_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  module_id VARCHAR(50) NOT NULL,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, module_id)
);

-- Index for user progress lookups
CREATE INDEX idx_module_progress_user ON module_progress(user_id);

-- ============================================
-- ACTIVITY LOG TABLE
-- ============================================
CREATE TABLE activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  module_id VARCHAR(50) NOT NULL,
  session_start TIMESTAMPTZ DEFAULT NOW(),
  session_end TIMESTAMPTZ,
  duration_seconds INTEGER DEFAULT 0,
  games_played INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  mistakes INTEGER DEFAULT 0,
  coins_earned INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for activity lookups
CREATE INDEX idx_activity_log_user ON activity_log(user_id);
CREATE INDEX idx_activity_log_date ON activity_log(session_start);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- Families: Users can read their own family
CREATE POLICY "Users can view own family"
  ON families FOR SELECT
  USING (
    id IN (
      SELECT family_id FROM users WHERE auth_id = auth.uid()
    )
  );

-- Users: Can read self and children in same family
CREATE POLICY "Users can view self and family members"
  ON users FOR SELECT
  USING (
    auth_id = auth.uid()
    OR 
    family_id IN (
      SELECT family_id FROM users WHERE auth_id = auth.uid()
    )
  );

-- Users: Parents can update children in their family
CREATE POLICY "Parents can update family children"
  ON users FOR UPDATE
  USING (
    auth_id = auth.uid()
    OR (
      role = 'child' AND
      family_id IN (
        SELECT family_id FROM users WHERE auth_id = auth.uid() AND role = 'parent'
      )
    )
  );

-- Module Progress: Users can read/write their own
CREATE POLICY "Users can manage own progress"
  ON module_progress FOR ALL
  USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
    OR
    user_id IN (
      SELECT id FROM users 
      WHERE family_id IN (
        SELECT family_id FROM users WHERE auth_id = auth.uid() AND role = 'parent'
      )
    )
  );

-- Activity Log: Same as module progress
CREATE POLICY "Users can manage own activity"
  ON activity_log FOR ALL
  USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
    OR
    user_id IN (
      SELECT id FROM users 
      WHERE family_id IN (
        SELECT family_id FROM users WHERE auth_id = auth.uid() AND role = 'parent'
      )
    )
  );

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER module_progress_updated_at
  BEFORE UPDATE ON module_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Function to create family and parent user on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_family_id UUID;
BEGIN
  -- Create a new family for the user
  INSERT INTO families (name)
  VALUES (COALESCE(NEW.raw_user_meta_data->>'display_name', 'My Family') || '''s Family')
  RETURNING id INTO new_family_id;
  
  -- Create the parent user record
  INSERT INTO users (auth_id, family_id, email, display_name, role)
  VALUES (
    NEW.id,
    new_family_id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', 'Parent'),
    'parent'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users insert
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

Instructions for applying:
1. Go to Supabase dashboard → SQL Editor
2. Paste and run this migration
3. Or use Supabase CLI: supabase db push
```

---

## Subphase 6.3: IndexedDB Storage Service

### Prompt for Claude Code:

```
Create the IndexedDB storage service for offline/guest mode.

File: src/shared/services/indexedDB.ts

Import: openDB, DBSchema from 'idb'

1. Define database schema:

```typescript
import { openDB, DBSchema, IDBPDatabase } from 'idb';

interface MaxPuzzlesDB extends DBSchema {
  // Guest user profile
  guestProfile: {
    key: 'profile';
    value: {
      id: string;
      displayName: string;
      coins: number;
      createdAt: string;
      updatedAt: string;
    };
  };
  
  // Module progress (keyed by moduleId)
  moduleProgress: {
    key: string; // moduleId
    value: {
      moduleId: string;
      data: Record<string, unknown>;
      updatedAt: string;
    };
  };
  
  // Activity sessions
  activityLog: {
    key: string; // sessionId
    value: {
      id: string;
      moduleId: string;
      sessionStart: string;
      sessionEnd: string | null;
      durationSeconds: number;
      gamesPlayed: number;
      correctAnswers: number;
      mistakes: number;
      coinsEarned: number;
    };
    indexes: {
      'by-module': string;
      'by-date': string;
    };
  };
  
  // Settings
  settings: {
    key: string;
    value: unknown;
  };
  
  // Pending sync queue (for when user creates account)
  syncQueue: {
    key: string;
    value: {
      id: string;
      type: 'progress' | 'activity' | 'profile';
      data: unknown;
      createdAt: string;
    };
  };
}

const DB_NAME = 'max-puzzles';
const DB_VERSION = 1;

let dbInstance: IDBPDatabase<MaxPuzzlesDB> | null = null;

export async function getDB(): Promise<IDBPDatabase<MaxPuzzlesDB>> {
  if (dbInstance) return dbInstance;
  
  dbInstance = await openDB<MaxPuzzlesDB>(DB_NAME, DB_VERSION, {
    upgrade(db) {
      // Guest profile store
      if (!db.objectStoreNames.contains('guestProfile')) {
        db.createObjectStore('guestProfile');
      }
      
      // Module progress store
      if (!db.objectStoreNames.contains('moduleProgress')) {
        db.createObjectStore('moduleProgress');
      }
      
      // Activity log store with indexes
      if (!db.objectStoreNames.contains('activityLog')) {
        const activityStore = db.createObjectStore('activityLog', { keyPath: 'id' });
        activityStore.createIndex('by-module', 'moduleId');
        activityStore.createIndex('by-date', 'sessionStart');
      }
      
      // Settings store
      if (!db.objectStoreNames.contains('settings')) {
        db.createObjectStore('settings');
      }
      
      // Sync queue store
      if (!db.objectStoreNames.contains('syncQueue')) {
        db.createObjectStore('syncQueue', { keyPath: 'id' });
      }
    },
  });
  
  return dbInstance;
}
```

2. Guest profile operations:

```typescript
export async function getGuestProfile() {
  const db = await getDB();
  return db.get('guestProfile', 'profile');
}

export async function setGuestProfile(profile: MaxPuzzlesDB['guestProfile']['value']) {
  const db = await getDB();
  await db.put('guestProfile', profile, 'profile');
}

export async function updateGuestCoins(delta: number) {
  const db = await getDB();
  const profile = await getGuestProfile();
  if (profile) {
    profile.coins = Math.max(0, profile.coins + delta);
    profile.updatedAt = new Date().toISOString();
    await setGuestProfile(profile);
  }
  return profile;
}
```

3. Module progress operations:

```typescript
export async function getModuleProgress(moduleId: string) {
  const db = await getDB();
  return db.get('moduleProgress', moduleId);
}

export async function setModuleProgress(
  moduleId: string, 
  data: Record<string, unknown>
) {
  const db = await getDB();
  await db.put('moduleProgress', {
    moduleId,
    data,
    updatedAt: new Date().toISOString(),
  }, moduleId);
}

export async function getAllModuleProgress() {
  const db = await getDB();
  return db.getAll('moduleProgress');
}
```

4. Activity log operations:

```typescript
export async function logActivity(
  activity: Omit<MaxPuzzlesDB['activityLog']['value'], 'id'>
) {
  const db = await getDB();
  const id = `activity-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  await db.add('activityLog', { ...activity, id });
  return id;
}

export async function updateActivity(
  id: string, 
  updates: Partial<MaxPuzzlesDB['activityLog']['value']>
) {
  const db = await getDB();
  const activity = await db.get('activityLog', id);
  if (activity) {
    await db.put('activityLog', { ...activity, ...updates });
  }
}

export async function getRecentActivity(limit: number = 20) {
  const db = await getDB();
  const all = await db.getAllFromIndex('activityLog', 'by-date');
  return all.reverse().slice(0, limit);
}
```

5. Settings operations:

```typescript
export async function getSetting<T>(key: string, defaultValue: T): Promise<T> {
  const db = await getDB();
  const value = await db.get('settings', key);
  return (value as T) ?? defaultValue;
}

export async function setSetting(key: string, value: unknown) {
  const db = await getDB();
  await db.put('settings', value, key);
}
```

6. Sync queue operations:

```typescript
export async function addToSyncQueue(
  type: 'progress' | 'activity' | 'profile',
  data: unknown
) {
  const db = await getDB();
  const id = `sync-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  await db.add('syncQueue', {
    id,
    type,
    data,
    createdAt: new Date().toISOString(),
  });
}

export async function getSyncQueue() {
  const db = await getDB();
  return db.getAll('syncQueue');
}

export async function clearSyncQueue() {
  const db = await getDB();
  await db.clear('syncQueue');
}

export async function removeSyncItem(id: string) {
  const db = await getDB();
  await db.delete('syncQueue', id);
}
```

7. Full database clear:

```typescript
export async function clearAllData() {
  const db = await getDB();
  await db.clear('guestProfile');
  await db.clear('moduleProgress');
  await db.clear('activityLog');
  await db.clear('settings');
  await db.clear('syncQueue');
}
```

Export all functions.
```

---

## Subphase 6.4: Auth Service

### Prompt for Claude Code:

```
Create the authentication service that wraps Supabase auth.

File: src/shared/services/auth.ts

Import:
- supabase, isSupabaseConfigured from './supabase'
- * as db from './indexedDB'
- User, Family, Child from '@/shared/types/auth'

```typescript
import { supabase, isSupabaseConfigured } from './supabase';
import * as localDB from './indexedDB';
import { User, Family } from '@/shared/types/auth';

// ============================================
// Authentication Functions
// ============================================

export async function signUp(
  email: string, 
  password: string, 
  displayName: string
): Promise<{ user: User | null; error: string | null }> {
  if (!supabase) {
    return { user: null, error: 'Supabase not configured' };
  }
  
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { display_name: displayName },
    },
  });
  
  if (error) {
    return { user: null, error: error.message };
  }
  
  // The database trigger will create the user record
  // Fetch the created user
  if (data.user) {
    const user = await fetchUserByAuthId(data.user.id);
    return { user, error: null };
  }
  
  return { user: null, error: 'Signup succeeded but user not found' };
}

export async function signIn(
  email: string, 
  password: string
): Promise<{ user: User | null; error: string | null }> {
  if (!supabase) {
    return { user: null, error: 'Supabase not configured' };
  }
  
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });
  
  if (error) {
    return { user: null, error: error.message };
  }
  
  if (data.user) {
    const user = await fetchUserByAuthId(data.user.id);
    return { user, error: null };
  }
  
  return { user: null, error: 'Login succeeded but user not found' };
}

export async function signOut(): Promise<void> {
  if (supabase) {
    await supabase.auth.signOut();
  }
}

export async function getCurrentSession() {
  if (!supabase) return null;
  
  const { data: { session } } = await supabase.auth.getSession();
  return session;
}

export async function getCurrentUser(): Promise<User | null> {
  const session = await getCurrentSession();
  if (!session) return null;
  
  return fetchUserByAuthId(session.user.id);
}

// ============================================
// User Data Functions
// ============================================

async function fetchUserByAuthId(authId: string): Promise<User | null> {
  if (!supabase) return null;
  
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('auth_id', authId)
    .single();
  
  if (error || !data) return null;
  
  return {
    id: data.id,
    familyId: data.family_id,
    email: data.email,
    displayName: data.display_name,
    role: data.role as 'parent' | 'child',
    coins: data.coins,
    isActive: data.is_active,
  };
}

export async function fetchFamily(familyId: string): Promise<Family | null> {
  if (!supabase) return null;
  
  const { data, error } = await supabase
    .from('families')
    .select('*')
    .eq('id', familyId)
    .single();
  
  if (error || !data) return null;
  
  return {
    id: data.id,
    name: data.name,
    createdAt: data.created_at,
  };
}

export async function fetchFamilyChildren(familyId: string): Promise<User[]> {
  if (!supabase) return [];
  
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('family_id', familyId)
    .eq('role', 'child')
    .eq('is_active', true);
  
  if (error || !data) return [];
  
  return data.map(child => ({
    id: child.id,
    familyId: child.family_id,
    email: child.email,
    displayName: child.display_name,
    role: child.role as 'parent' | 'child',
    coins: child.coins,
    isActive: child.is_active,
  }));
}

// ============================================
// Child PIN Functions
// ============================================

// Simple hash for PIN (use bcrypt in production)
function hashPin(pin: string): string {
  // For V1, we'll use a simple approach
  // In production, use bcrypt or similar
  return btoa(pin + 'max-puzzles-salt');
}

export async function verifyChildPin(
  childId: string, 
  pin: string
): Promise<boolean> {
  if (!supabase) return false;
  
  const { data, error } = await supabase
    .from('users')
    .select('pin_hash')
    .eq('id', childId)
    .single();
  
  if (error || !data) return false;
  
  return data.pin_hash === hashPin(pin);
}

export async function setChildPin(
  childId: string, 
  pin: string
): Promise<boolean> {
  if (!supabase) return false;
  
  const { error } = await supabase
    .from('users')
    .update({ pin_hash: hashPin(pin) })
    .eq('id', childId);
  
  return !error;
}

export async function addChild(
  familyId: string,
  displayName: string,
  pin: string
): Promise<User | null> {
  if (!supabase) return null;
  
  const { data, error } = await supabase
    .from('users')
    .insert({
      family_id: familyId,
      display_name: displayName,
      role: 'child',
      pin_hash: hashPin(pin),
      coins: 0,
    })
    .select()
    .single();
  
  if (error || !data) return null;
  
  return {
    id: data.id,
    familyId: data.family_id,
    email: data.email,
    displayName: data.display_name,
    role: 'child',
    coins: data.coins,
    isActive: data.is_active,
  };
}

export async function removeChild(childId: string): Promise<boolean> {
  if (!supabase) return false;
  
  // Soft delete
  const { error } = await supabase
    .from('users')
    .update({ is_active: false })
    .eq('id', childId);
  
  return !error;
}

// ============================================
// Guest Mode Functions
// ============================================

export async function initGuestProfile(): Promise<User> {
  let profile = await localDB.getGuestProfile();
  
  if (!profile) {
    profile = {
      id: `guest-${Date.now()}`,
      displayName: 'Guest',
      coins: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    await localDB.setGuestProfile(profile);
  }
  
  return {
    id: profile.id,
    familyId: null,
    email: null,
    displayName: profile.displayName,
    role: 'child', // Guests play as children
    coins: profile.coins,
    isActive: true,
  };
}

export async function updateGuestDisplayName(name: string): Promise<void> {
  const profile = await localDB.getGuestProfile();
  if (profile) {
    profile.displayName = name;
    profile.updatedAt = new Date().toISOString();
    await localDB.setGuestProfile(profile);
  }
}
```

Export all functions.
```

---

## Subphase 6.5: Progress Service

### Prompt for Claude Code:

```
Create the progress service for saving and loading game progress.

File: src/shared/services/progress.ts

Import:
- supabase from './supabase'
- * as localDB from './indexedDB'

```typescript
import { supabase } from './supabase';
import * as localDB from './indexedDB';

// Types for Circuit Challenge progress
interface CircuitChallengeProgress {
  quickPlay: {
    gamesPlayed: number;
    gamesWon: number;
    totalCoinsEarned: number;
    bestStreak: number;
    currentStreak: number;
    lastPlayedAt: string | null;
    difficultyStats: Record<number, {
      played: number;
      won: number;
      bestTimeMs: number | null;
    }>;
  };
  progression: {
    // V2 - placeholder
    completedLevels: string[];
    starsByLevel: Record<string, number>;
  };
}

const DEFAULT_CC_PROGRESS: CircuitChallengeProgress = {
  quickPlay: {
    gamesPlayed: 0,
    gamesWon: 0,
    totalCoinsEarned: 0,
    bestStreak: 0,
    currentStreak: 0,
    lastPlayedAt: null,
    difficultyStats: {},
  },
  progression: {
    completedLevels: [],
    starsByLevel: {},
  },
};

// ============================================
// Get Progress
// ============================================

export async function getProgress(
  userId: string | null,
  moduleId: string,
  isGuest: boolean
): Promise<Record<string, unknown>> {
  if (isGuest || !userId) {
    // Load from IndexedDB
    const local = await localDB.getModuleProgress(moduleId);
    return local?.data || getDefaultProgress(moduleId);
  }
  
  // Load from Supabase
  if (!supabase) {
    const local = await localDB.getModuleProgress(moduleId);
    return local?.data || getDefaultProgress(moduleId);
  }
  
  const { data, error } = await supabase
    .from('module_progress')
    .select('data')
    .eq('user_id', userId)
    .eq('module_id', moduleId)
    .single();
  
  if (error || !data) {
    return getDefaultProgress(moduleId);
  }
  
  return data.data as Record<string, unknown>;
}

function getDefaultProgress(moduleId: string): Record<string, unknown> {
  switch (moduleId) {
    case 'circuit-challenge':
      return DEFAULT_CC_PROGRESS;
    default:
      return {};
  }
}

// ============================================
// Save Progress
// ============================================

export async function saveProgress(
  userId: string | null,
  moduleId: string,
  data: Record<string, unknown>,
  isGuest: boolean
): Promise<boolean> {
  // Always save locally first
  await localDB.setModuleProgress(moduleId, data);
  
  if (isGuest || !userId || !supabase) {
    // Queue for sync when user creates account
    if (isGuest) {
      await localDB.addToSyncQueue('progress', { moduleId, data });
    }
    return true;
  }
  
  // Save to Supabase (upsert)
  const { error } = await supabase
    .from('module_progress')
    .upsert({
      user_id: userId,
      module_id: moduleId,
      data,
      updated_at: new Date().toISOString(),
    }, {
      onConflict: 'user_id,module_id',
    });
  
  return !error;
}

// ============================================
// Update Quick Play Stats
// ============================================

export async function recordQuickPlayResult(
  userId: string | null,
  isGuest: boolean,
  result: {
    won: boolean;
    difficultyLevel: number;
    timeMs: number;
    coinsEarned: number;
  }
): Promise<void> {
  const progress = await getProgress(userId, 'circuit-challenge', isGuest) as CircuitChallengeProgress;
  
  const qp = progress.quickPlay;
  
  // Update general stats
  qp.gamesPlayed++;
  if (result.won) {
    qp.gamesWon++;
    qp.currentStreak++;
    qp.bestStreak = Math.max(qp.bestStreak, qp.currentStreak);
  } else {
    qp.currentStreak = 0;
  }
  qp.totalCoinsEarned += result.coinsEarned;
  qp.lastPlayedAt = new Date().toISOString();
  
  // Update difficulty-specific stats
  const diffStats = qp.difficultyStats[result.difficultyLevel] || {
    played: 0,
    won: 0,
    bestTimeMs: null,
  };
  diffStats.played++;
  if (result.won) {
    diffStats.won++;
    if (diffStats.bestTimeMs === null || result.timeMs < diffStats.bestTimeMs) {
      diffStats.bestTimeMs = result.timeMs;
    }
  }
  qp.difficultyStats[result.difficultyLevel] = diffStats;
  
  // Save updated progress
  await saveProgress(userId, 'circuit-challenge', progress, isGuest);
}

// ============================================
// Coins Management
// ============================================

export async function addCoins(
  userId: string | null,
  amount: number,
  isGuest: boolean
): Promise<number> {
  if (isGuest) {
    const profile = await localDB.updateGuestCoins(amount);
    return profile?.coins || 0;
  }
  
  if (!supabase || !userId) return 0;
  
  // Use Supabase RPC for atomic update
  const { data, error } = await supabase.rpc('add_coins', {
    user_id: userId,
    amount: amount,
  });
  
  if (error) {
    console.error('Failed to add coins:', error);
    return 0;
  }
  
  return data as number;
}

// Add this RPC function to Supabase:
/*
CREATE OR REPLACE FUNCTION add_coins(user_id UUID, amount INTEGER)
RETURNS INTEGER AS $$
DECLARE
  new_coins INTEGER;
BEGIN
  UPDATE users 
  SET coins = GREATEST(0, coins + amount)
  WHERE id = user_id
  RETURNING coins INTO new_coins;
  
  RETURN new_coins;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
*/
```

Export all functions.
```

---

## Subphase 6.6: Activity Tracking Service

### Prompt for Claude Code:

```
Create the activity tracking service for session logging.

File: src/shared/services/activity.ts

Import:
- supabase from './supabase'
- * as localDB from './indexedDB'

```typescript
import { supabase } from './supabase';
import * as localDB from './indexedDB';

interface ActivitySession {
  id: string;
  moduleId: string;
  sessionStart: string;
  sessionEnd: string | null;
  durationSeconds: number;
  gamesPlayed: number;
  correctAnswers: number;
  mistakes: number;
  coinsEarned: number;
}

let currentSession: {
  id: string;
  moduleId: string;
  startTime: number;
  gamesPlayed: number;
  correctAnswers: number;
  mistakes: number;
  coinsEarned: number;
} | null = null;

// ============================================
// Session Management
// ============================================

export async function startSession(
  userId: string | null,
  moduleId: string,
  isGuest: boolean
): Promise<string> {
  const sessionStart = new Date().toISOString();
  
  // End any existing session first
  if (currentSession) {
    await endSession(userId, isGuest);
  }
  
  const sessionData = {
    moduleId,
    sessionStart,
    sessionEnd: null,
    durationSeconds: 0,
    gamesPlayed: 0,
    correctAnswers: 0,
    mistakes: 0,
    coinsEarned: 0,
  };
  
  let sessionId: string;
  
  if (isGuest || !userId || !supabase) {
    // Store locally
    sessionId = await localDB.logActivity(sessionData);
  } else {
    // Store in Supabase
    const { data, error } = await supabase
      .from('activity_log')
      .insert({
        user_id: userId,
        ...sessionData,
      })
      .select('id')
      .single();
    
    if (error || !data) {
      // Fallback to local
      sessionId = await localDB.logActivity(sessionData);
    } else {
      sessionId = data.id;
    }
  }
  
  // Track in memory
  currentSession = {
    id: sessionId,
    moduleId,
    startTime: Date.now(),
    gamesPlayed: 0,
    correctAnswers: 0,
    mistakes: 0,
    coinsEarned: 0,
  };
  
  return sessionId;
}

export async function endSession(
  userId: string | null,
  isGuest: boolean
): Promise<void> {
  if (!currentSession) return;
  
  const durationSeconds = Math.floor((Date.now() - currentSession.startTime) / 1000);
  const sessionEnd = new Date().toISOString();
  
  const updates = {
    sessionEnd,
    durationSeconds,
    gamesPlayed: currentSession.gamesPlayed,
    correctAnswers: currentSession.correctAnswers,
    mistakes: currentSession.mistakes,
    coinsEarned: currentSession.coinsEarned,
  };
  
  if (isGuest || !userId || !supabase) {
    await localDB.updateActivity(currentSession.id, {
      session_end: sessionEnd,
      duration_seconds: durationSeconds,
      games_played: currentSession.gamesPlayed,
      correct_answers: currentSession.correctAnswers,
      mistakes: currentSession.mistakes,
      coins_earned: currentSession.coinsEarned,
    });
  } else {
    await supabase
      .from('activity_log')
      .update({
        session_end: sessionEnd,
        duration_seconds: durationSeconds,
        games_played: currentSession.gamesPlayed,
        correct_answers: currentSession.correctAnswers,
        mistakes: currentSession.mistakes,
        coins_earned: currentSession.coinsEarned,
      })
      .eq('id', currentSession.id);
  }
  
  currentSession = null;
}

export function recordGameInSession(result: {
  correct: number;
  mistakes: number;
  coinsEarned: number;
}): void {
  if (!currentSession) return;
  
  currentSession.gamesPlayed++;
  currentSession.correctAnswers += result.correct;
  currentSession.mistakes += result.mistakes;
  currentSession.coinsEarned += result.coinsEarned;
}

// ============================================
// Activity Queries
// ============================================

export async function getRecentActivity(
  userId: string | null,
  isGuest: boolean,
  limit: number = 20
): Promise<ActivitySession[]> {
  if (isGuest || !userId || !supabase) {
    const local = await localDB.getRecentActivity(limit);
    return local.map(a => ({
      id: a.id,
      moduleId: a.moduleId,
      sessionStart: a.sessionStart,
      sessionEnd: a.sessionEnd,
      durationSeconds: a.durationSeconds,
      gamesPlayed: a.gamesPlayed,
      correctAnswers: a.correctAnswers,
      mistakes: a.mistakes,
      coinsEarned: a.coinsEarned,
    }));
  }
  
  const { data, error } = await supabase
    .from('activity_log')
    .select('*')
    .eq('user_id', userId)
    .order('session_start', { ascending: false })
    .limit(limit);
  
  if (error || !data) return [];
  
  return data.map(a => ({
    id: a.id,
    moduleId: a.module_id,
    sessionStart: a.session_start,
    sessionEnd: a.session_end,
    durationSeconds: a.duration_seconds,
    gamesPlayed: a.games_played,
    correctAnswers: a.correct_answers,
    mistakes: a.mistakes,
    coinsEarned: a.coins_earned,
  }));
}

export async function getActivitySummary(
  userId: string | null,
  isGuest: boolean,
  days: number = 7
): Promise<{
  totalGames: number;
  totalTime: number;
  totalCoins: number;
  accuracy: number;
}> {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - days);
  
  const activities = await getRecentActivity(userId, isGuest, 100);
  const recent = activities.filter(a => 
    new Date(a.sessionStart) >= cutoff
  );
  
  const totals = recent.reduce((acc, a) => ({
    games: acc.games + a.gamesPlayed,
    time: acc.time + a.durationSeconds,
    coins: acc.coins + a.coinsEarned,
    correct: acc.correct + a.correctAnswers,
    total: acc.total + a.correctAnswers + a.mistakes,
  }), { games: 0, time: 0, coins: 0, correct: 0, total: 0 });
  
  return {
    totalGames: totals.games,
    totalTime: totals.time,
    totalCoins: totals.coins,
    accuracy: totals.total > 0 ? Math.round((totals.correct / totals.total) * 100) : 0,
  };
}

// ============================================
// Inactivity Detection
// ============================================

let inactivityTimer: number | null = null;
const INACTIVITY_TIMEOUT = 5 * 60 * 1000; // 5 minutes

export function resetInactivityTimer(
  userId: string | null,
  isGuest: boolean
): void {
  if (inactivityTimer) {
    clearTimeout(inactivityTimer);
  }
  
  inactivityTimer = window.setTimeout(() => {
    endSession(userId, isGuest);
  }, INACTIVITY_TIMEOUT);
}

export function clearInactivityTimer(): void {
  if (inactivityTimer) {
    clearTimeout(inactivityTimer);
    inactivityTimer = null;
  }
}
```

Export all functions.
```

---

## Subphase 6.7: Sync Service

### Prompt for Claude Code:

```
Create the sync service for merging local and cloud data.

File: src/shared/services/sync.ts

Import:
- supabase from './supabase'
- * as localDB from './indexedDB'
- * as progress from './progress'

```typescript
import { supabase } from './supabase';
import * as localDB from './indexedDB';

interface SyncResult {
  success: boolean;
  merged: {
    progress: boolean;
    activity: boolean;
    coins: boolean;
  };
  errors: string[];
}

// ============================================
// Main Sync Function
// ============================================

export async function syncGuestDataToAccount(
  userId: string
): Promise<SyncResult> {
  const result: SyncResult = {
    success: true,
    merged: { progress: false, activity: false, coins: false },
    errors: [],
  };
  
  if (!supabase) {
    result.success = false;
    result.errors.push('Supabase not configured');
    return result;
  }
  
  try {
    // 1. Sync coins (use higher value)
    const guestProfile = await localDB.getGuestProfile();
    if (guestProfile && guestProfile.coins > 0) {
      const merged = await mergeCoins(userId, guestProfile.coins);
      result.merged.coins = merged;
    }
    
    // 2. Sync module progress
    const localProgress = await localDB.getAllModuleProgress();
    for (const progress of localProgress) {
      const merged = await mergeModuleProgress(
        userId, 
        progress.moduleId, 
        progress.data
      );
      if (merged) result.merged.progress = true;
    }
    
    // 3. Process sync queue
    const queue = await localDB.getSyncQueue();
    for (const item of queue) {
      try {
        await processSyncItem(userId, item);
        await localDB.removeSyncItem(item.id);
      } catch (err) {
        result.errors.push(`Failed to sync ${item.type}: ${err}`);
      }
    }
    
    // 4. Clear local guest data after successful sync
    if (result.errors.length === 0) {
      await localDB.clearAllData();
    }
    
  } catch (err) {
    result.success = false;
    result.errors.push(`Sync failed: ${err}`);
  }
  
  return result;
}

// ============================================
// Merge Strategies
// ============================================

async function mergeCoins(
  userId: string, 
  localCoins: number
): Promise<boolean> {
  if (!supabase) return false;
  
  // Get current cloud coins
  const { data: userData } = await supabase
    .from('users')
    .select('coins')
    .eq('id', userId)
    .single();
  
  const cloudCoins = userData?.coins || 0;
  
  // Use higher value (best outcome for player)
  if (localCoins > cloudCoins) {
    const { error } = await supabase
      .from('users')
      .update({ coins: localCoins })
      .eq('id', userId);
    
    return !error;
  }
  
  return true; // No update needed, cloud has more
}

async function mergeModuleProgress(
  userId: string,
  moduleId: string,
  localData: Record<string, unknown>
): Promise<boolean> {
  if (!supabase) return false;
  
  // Get current cloud progress
  const { data: cloudProgress } = await supabase
    .from('module_progress')
    .select('data')
    .eq('user_id', userId)
    .eq('module_id', moduleId)
    .single();
  
  const cloudData = (cloudProgress?.data || {}) as Record<string, unknown>;
  
  // Merge based on module-specific rules
  const mergedData = mergeProgressData(moduleId, localData, cloudData);
  
  // Save merged data
  const { error } = await supabase
    .from('module_progress')
    .upsert({
      user_id: userId,
      module_id: moduleId,
      data: mergedData,
      updated_at: new Date().toISOString(),
    }, {
      onConflict: 'user_id,module_id',
    });
  
  return !error;
}

function mergeProgressData(
  moduleId: string,
  local: Record<string, unknown>,
  cloud: Record<string, unknown>
): Record<string, unknown> {
  // Circuit Challenge specific merge
  if (moduleId === 'circuit-challenge') {
    return mergeCircuitChallengeProgress(local, cloud);
  }
  
  // Default: last-write-wins with local taking precedence for ties
  return { ...cloud, ...local };
}

function mergeCircuitChallengeProgress(
  local: Record<string, unknown>,
  cloud: Record<string, unknown>
): Record<string, unknown> {
  const localQP = (local as any).quickPlay || {};
  const cloudQP = (cloud as any).quickPlay || {};
  
  return {
    quickPlay: {
      // Higher wins
      gamesPlayed: Math.max(localQP.gamesPlayed || 0, cloudQP.gamesPlayed || 0),
      gamesWon: Math.max(localQP.gamesWon || 0, cloudQP.gamesWon || 0),
      totalCoinsEarned: Math.max(localQP.totalCoinsEarned || 0, cloudQP.totalCoinsEarned || 0),
      bestStreak: Math.max(localQP.bestStreak || 0, cloudQP.bestStreak || 0),
      currentStreak: Math.max(localQP.currentStreak || 0, cloudQP.currentStreak || 0),
      
      // Most recent wins
      lastPlayedAt: getMoreRecent(localQP.lastPlayedAt, cloudQP.lastPlayedAt),
      
      // Merge difficulty stats (best times win)
      difficultyStats: mergeDifficultyStats(
        localQP.difficultyStats || {},
        cloudQP.difficultyStats || {}
      ),
    },
    progression: {
      // Union of completed levels
      completedLevels: [...new Set([
        ...((local as any).progression?.completedLevels || []),
        ...((cloud as any).progression?.completedLevels || []),
      ])],
      // Higher stars win
      starsByLevel: mergeStarsByLevel(
        (local as any).progression?.starsByLevel || {},
        (cloud as any).progression?.starsByLevel || {}
      ),
    },
  };
}

function getMoreRecent(a: string | null, b: string | null): string | null {
  if (!a) return b;
  if (!b) return a;
  return new Date(a) > new Date(b) ? a : b;
}

function mergeDifficultyStats(
  local: Record<number, any>,
  cloud: Record<number, any>
): Record<number, any> {
  const merged: Record<number, any> = { ...cloud };
  
  for (const [level, stats] of Object.entries(local)) {
    const cloudStats = merged[Number(level)] || { played: 0, won: 0, bestTimeMs: null };
    merged[Number(level)] = {
      played: Math.max(stats.played || 0, cloudStats.played || 0),
      won: Math.max(stats.won || 0, cloudStats.won || 0),
      bestTimeMs: getBetterTime(stats.bestTimeMs, cloudStats.bestTimeMs),
    };
  }
  
  return merged;
}

function getBetterTime(a: number | null, b: number | null): number | null {
  if (a === null) return b;
  if (b === null) return a;
  return Math.min(a, b); // Lower is better
}

function mergeStarsByLevel(
  local: Record<string, number>,
  cloud: Record<string, number>
): Record<string, number> {
  const merged: Record<string, number> = { ...cloud };
  
  for (const [level, stars] of Object.entries(local)) {
    merged[level] = Math.max(stars, merged[level] || 0);
  }
  
  return merged;
}

async function processSyncItem(
  userId: string,
  item: { type: string; data: unknown }
): Promise<void> {
  // Process based on type
  switch (item.type) {
    case 'progress':
      const { moduleId, data } = item.data as { moduleId: string; data: any };
      await mergeModuleProgress(userId, moduleId, data);
      break;
    case 'activity':
      // Activity logs don't need merging, just upload
      // (Could be implemented if needed)
      break;
    case 'profile':
      // Profile data (like name) - last-write-wins
      break;
  }
}
```

Export all functions.
```

---

## Subphase 6.8: Auth Provider Implementation

### Prompt for Claude Code:

```
Update the AuthProvider with full functionality.

File: src/app/providers/AuthProvider.tsx

```typescript
import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { User, Family } from '@/shared/types/auth';
import * as authService from '@/shared/services/auth';
import * as syncService from '@/shared/services/sync';
import * as activityService from '@/shared/services/activity';
import { supabase } from '@/shared/services/supabase';

interface AuthState {
  user: User | null;
  family: Family | null;
  children: User[];
  isGuest: boolean;
  isDemoMode: boolean;
  isLoading: boolean;
  activeChildId: string | null;
}

interface AuthContextValue extends AuthState {
  // Auth actions
  signUp: (email: string, password: string, displayName: string) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  
  // Guest mode
  setGuestMode: () => Promise<void>;
  
  // Family actions
  selectChild: (childId: string, pin: string) => Promise<void>;
  enterDemoMode: () => void;
  exitDemoMode: () => void;
  addChild: (displayName: string, pin: string) => Promise<User | null>;
  removeChild: (childId: string) => Promise<void>;
  
  // Data sync
  syncGuestToAccount: () => Promise<boolean>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({
    user: null,
    family: null,
    children: [],
    isGuest: false,
    isDemoMode: false,
    isLoading: true,
    activeChildId: null,
  });
  
  // Initialize on mount
  useEffect(() => {
    initializeAuth();
  }, []);
  
  // Listen for auth state changes
  useEffect(() => {
    if (!supabase) return;
    
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (event === 'SIGNED_IN' && session?.user) {
          await loadUserData(session.user.id);
        } else if (event === 'SIGNED_OUT') {
          setState(prev => ({
            ...prev,
            user: null,
            family: null,
            children: [],
            isGuest: false,
            isDemoMode: false,
            activeChildId: null,
          }));
        }
      }
    );
    
    return () => subscription.unsubscribe();
  }, []);
  
  async function initializeAuth() {
    try {
      // Check for existing session
      const user = await authService.getCurrentUser();
      
      if (user) {
        await loadUserData(user.id);
      } else {
        // Check for guest profile
        const guestProfile = await authService.initGuestProfile();
        // Don't auto-enable guest mode, let user choose
      }
    } catch (err) {
      console.error('Auth initialization error:', err);
    } finally {
      setState(prev => ({ ...prev, isLoading: false }));
    }
  }
  
  async function loadUserData(authId: string) {
    const user = await authService.getCurrentUser();
    if (!user || !user.familyId) return;
    
    const family = await authService.fetchFamily(user.familyId);
    const familyChildren = await authService.fetchFamilyChildren(user.familyId);
    
    setState(prev => ({
      ...prev,
      user,
      family,
      children: familyChildren,
      isGuest: false,
      isDemoMode: false,
      isLoading: false,
    }));
  }
  
  // ============================================
  // Auth Actions
  // ============================================
  
  const signUp = useCallback(async (
    email: string, 
    password: string, 
    displayName: string
  ) => {
    setState(prev => ({ ...prev, isLoading: true }));
    
    const { user, error } = await authService.signUp(email, password, displayName);
    
    if (error) {
      setState(prev => ({ ...prev, isLoading: false }));
      throw new Error(error);
    }
    
    // User data will be loaded via auth state change listener
  }, []);
  
  const signIn = useCallback(async (email: string, password: string) => {
    setState(prev => ({ ...prev, isLoading: true }));
    
    const { user, error } = await authService.signIn(email, password);
    
    if (error) {
      setState(prev => ({ ...prev, isLoading: false }));
      throw new Error(error);
    }
    
    // User data will be loaded via auth state change listener
  }, []);
  
  const signOut = useCallback(async () => {
    await activityService.endSession(state.user?.id || null, state.isGuest);
    await authService.signOut();
    
    setState(prev => ({
      ...prev,
      user: null,
      family: null,
      children: [],
      isGuest: false,
      isDemoMode: false,
      activeChildId: null,
    }));
  }, [state.user?.id, state.isGuest]);
  
  // ============================================
  // Guest Mode
  // ============================================
  
  const setGuestMode = useCallback(async () => {
    const guestUser = await authService.initGuestProfile();
    
    setState(prev => ({
      ...prev,
      user: guestUser,
      family: null,
      children: [],
      isGuest: true,
      isDemoMode: false,
      isLoading: false,
    }));
  }, []);
  
  // ============================================
  // Family Actions
  // ============================================
  
  const selectChild = useCallback(async (childId: string, pin: string) => {
    const isValid = await authService.verifyChildPin(childId, pin);
    
    if (!isValid) {
      throw new Error('Invalid PIN');
    }
    
    const child = state.children.find(c => c.id === childId);
    if (!child) {
      throw new Error('Child not found');
    }
    
    setState(prev => ({
      ...prev,
      user: child,
      activeChildId: childId,
      isDemoMode: false,
    }));
  }, [state.children]);
  
  const enterDemoMode = useCallback(() => {
    if (!state.family) return;
    
    // Create a temporary demo user
    const demoUser: User = {
      id: 'demo',
      familyId: state.family.id,
      email: null,
      displayName: 'Demo',
      role: 'parent',
      coins: 0,
      isActive: true,
    };
    
    setState(prev => ({
      ...prev,
      user: demoUser,
      isDemoMode: true,
      activeChildId: null,
    }));
  }, [state.family]);
  
  const exitDemoMode = useCallback(() => {
    // Return to parent selection
    setState(prev => ({
      ...prev,
      user: null,
      isDemoMode: false,
      activeChildId: null,
    }));
  }, []);
  
  const addChild = useCallback(async (
    displayName: string, 
    pin: string
  ): Promise<User | null> => {
    if (!state.family?.id) return null;
    
    const newChild = await authService.addChild(
      state.family.id,
      displayName,
      pin
    );
    
    if (newChild) {
      setState(prev => ({
        ...prev,
        children: [...prev.children, newChild],
      }));
    }
    
    return newChild;
  }, [state.family?.id]);
  
  const removeChild = useCallback(async (childId: string) => {
    const success = await authService.removeChild(childId);
    
    if (success) {
      setState(prev => ({
        ...prev,
        children: prev.children.filter(c => c.id !== childId),
      }));
    }
  }, []);
  
  // ============================================
  // Data Sync
  // ============================================
  
  const syncGuestToAccount = useCallback(async (): Promise<boolean> => {
    if (!state.user?.id || state.isGuest) return false;
    
    const result = await syncService.syncGuestDataToAccount(state.user.id);
    return result.success;
  }, [state.user?.id, state.isGuest]);
  
  // ============================================
  // Context Value
  // ============================================
  
  const value: AuthContextValue = {
    ...state,
    signUp,
    signIn,
    signOut,
    setGuestMode,
    selectChild,
    enterDemoMode,
    exitDemoMode,
    addChild,
    removeChild,
    syncGuestToAccount,
  };
  
  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
```

Export AuthProvider and useAuth.
```

---

## Subphase 6.9: Storage Provider Implementation

### Prompt for Claude Code:

```
Update the StorageProvider for seamless local/cloud data access.

File: src/app/providers/StorageProvider.tsx

```typescript
import React, { createContext, useContext, useCallback } from 'react';
import { useAuth } from './AuthProvider';
import * as progressService from '@/shared/services/progress';
import * as activityService from '@/shared/services/activity';

interface StorageContextValue {
  // Progress
  getProgress: (moduleId: string) => Promise<Record<string, unknown>>;
  saveProgress: (moduleId: string, data: Record<string, unknown>) => Promise<boolean>;
  
  // Activity
  startSession: (moduleId: string) => Promise<string>;
  endSession: () => Promise<void>;
  recordGame: (result: { correct: number; mistakes: number; coinsEarned: number }) => void;
  
  // Quick helpers
  recordQuickPlayResult: (result: {
    won: boolean;
    difficultyLevel: number;
    timeMs: number;
    coinsEarned: number;
  }) => Promise<void>;
  
  addCoins: (amount: number) => Promise<number>;
}

const StorageContext = createContext<StorageContextValue | null>(null);

export function StorageProvider({ children }: { children: React.ReactNode }) {
  const { user, isGuest, isDemoMode } = useAuth();
  
  const userId = user?.id || null;
  
  // ============================================
  // Progress
  // ============================================
  
  const getProgress = useCallback(async (moduleId: string) => {
    if (isDemoMode) {
      // Demo mode: return empty progress
      return {};
    }
    return progressService.getProgress(userId, moduleId, isGuest);
  }, [userId, isGuest, isDemoMode]);
  
  const saveProgress = useCallback(async (
    moduleId: string, 
    data: Record<string, unknown>
  ) => {
    if (isDemoMode) {
      // Demo mode: don't save
      return true;
    }
    return progressService.saveProgress(userId, moduleId, data, isGuest);
  }, [userId, isGuest, isDemoMode]);
  
  // ============================================
  // Activity
  // ============================================
  
  const startSession = useCallback(async (moduleId: string) => {
    if (isDemoMode) {
      return 'demo-session';
    }
    return activityService.startSession(userId, moduleId, isGuest);
  }, [userId, isGuest, isDemoMode]);
  
  const endSession = useCallback(async () => {
    if (isDemoMode) return;
    return activityService.endSession(userId, isGuest);
  }, [userId, isGuest, isDemoMode]);
  
  const recordGame = useCallback((result: {
    correct: number;
    mistakes: number;
    coinsEarned: number;
  }) => {
    if (isDemoMode) return;
    activityService.recordGameInSession(result);
  }, [isDemoMode]);
  
  // ============================================
  // Quick Helpers
  // ============================================
  
  const recordQuickPlayResult = useCallback(async (result: {
    won: boolean;
    difficultyLevel: number;
    timeMs: number;
    coinsEarned: number;
  }) => {
    if (isDemoMode) return;
    
    await progressService.recordQuickPlayResult(userId, isGuest, result);
  }, [userId, isGuest, isDemoMode]);
  
  const addCoins = useCallback(async (amount: number) => {
    if (isDemoMode) return 0;
    return progressService.addCoins(userId, amount, isGuest);
  }, [userId, isGuest, isDemoMode]);
  
  // ============================================
  // Context Value
  // ============================================
  
  const value: StorageContextValue = {
    getProgress,
    saveProgress,
    startSession,
    endSession,
    recordGame,
    recordQuickPlayResult,
    addCoins,
  };
  
  return (
    <StorageContext.Provider value={value}>
      {children}
    </StorageContext.Provider>
  );
}

export function useStorage(): StorageContextValue {
  const context = useContext(StorageContext);
  if (!context) {
    throw new Error('useStorage must be used within StorageProvider');
  }
  return context;
}
```

Export StorageProvider and useStorage.
```

---

## Subphase 6.10: Integration with Game Flow

### Prompt for Claude Code:

```
Integrate storage and auth with the game flow.

1. Update useGame hook to use storage:

File: src/modules/circuit-challenge/hooks/useGame.ts (additions)

```typescript
import { useStorage } from '@/app/providers/StorageProvider';
import { useAuth } from '@/app/providers/AuthProvider';

// Inside useGame hook:

const { recordQuickPlayResult, addCoins, startSession, endSession, recordGame } = useStorage();
const { user, isDemoMode } = useAuth();

// Start session when game begins
useEffect(() => {
  startSession('circuit-challenge');
  
  return () => {
    endSession();
  };
}, []);

// When game ends (won or lost):
useEffect(() => {
  if (state.status === 'won' || state.status === 'lost') {
    const won = state.status === 'won';
    const correctMoves = state.moveHistory.filter(m => m.correct).length;
    const mistakes = state.moveHistory.filter(m => !m.correct).length;
    
    // Record game in session
    recordGame({
      correct: correctMoves,
      mistakes,
      coinsEarned: state.puzzleCoins,
    });
    
    // Record quick play result
    recordQuickPlayResult({
      won,
      difficultyLevel: getDifficultyLevel(state.difficulty),
      timeMs: state.elapsedMs,
      coinsEarned: state.puzzleCoins,
    });
    
    // Add coins to user account
    if (state.puzzleCoins > 0) {
      addCoins(state.puzzleCoins);
    }
  }
}, [state.status]);
```

2. Update GameScreen to show loading states:

```typescript
// In GameScreen.tsx

const { isLoading } = useAuth();

if (isLoading) {
  return <LoadingScreen />;
}
```

3. Create shared services index:

File: src/shared/services/index.ts

```typescript
export * from './supabase';
export * from './indexedDB';
export * from './auth';
export * from './progress';
export * from './activity';
export * from './sync';
```

4. Update providers index:

File: src/app/providers/index.ts

```typescript
import React from 'react';
import { AuthProvider } from './AuthProvider';
import { StorageProvider } from './StorageProvider';
import { SoundProvider } from './SoundProvider';

export function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <StorageProvider>
        <SoundProvider>
          {children}
        </SoundProvider>
      </StorageProvider>
    </AuthProvider>
  );
}

export { useAuth } from './AuthProvider';
export { useStorage } from './StorageProvider';
export { useSound } from './SoundProvider';
```

5. Test the complete flow:
   - Guest mode: data saves to IndexedDB
   - Logged in: data saves to Supabase
   - Demo mode: nothing saves
   - Creating account: guest data syncs to cloud
```

---

## Phase 6 Completion Checklist

After completing all subphases, verify:

- [ ] Supabase client initializes correctly
- [ ] Database tables created with migrations
- [ ] RLS policies work correctly
- [ ] IndexedDB stores and retrieves data
- [ ] Guest profile persists across sessions
- [ ] Auth signup creates family and user
- [ ] Auth login loads user data
- [ ] Child PIN verification works
- [ ] Progress saves locally for guests
- [ ] Progress saves to Supabase for logged-in users
- [ ] Activity sessions track correctly
- [ ] Demo mode doesn't save any data
- [ ] Sync merges guest data to account
- [ ] Merge strategies favor the player

---

## Files Created in This Phase

```
src/shared/services/
├── index.ts
├── supabase.ts
├── database.types.ts
├── indexedDB.ts
├── auth.ts
├── progress.ts
├── activity.ts
└── sync.ts

src/app/providers/
├── index.ts (updated)
├── AuthProvider.tsx (updated)
└── StorageProvider.tsx (updated)

supabase/
└── migrations/
    └── 001_initial_schema.sql

.env.example
.env.local (gitignored)
```

---

## Data Flow Diagram

```
[User Action]
     │
     ▼
[useStorage Hook]
     │
     ├── Guest? ──────► [IndexedDB]
     │                       │
     │                       └── Queue for sync
     │
     └── Logged In? ──► [Supabase]
                             │
                             └── Also cache locally
                             
[Guest Creates Account]
     │
     ▼
[syncGuestToAccount]
     │
     ├── Merge coins (higher wins)
     ├── Merge progress (best outcomes)
     └── Clear local data
```

---

*End of Phase 6*
