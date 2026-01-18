# Max's Puzzles - Database Schema

**Version:** 1.1  
**Last Updated:** January 2025  
**Author:** Dom Barker

---

## Overview

This document specifies the Supabase database schema for Max's Puzzles. The schema supports family accounts, coin economy, avatar customisation, module progress tracking, and activity logging.

---

## Design Principles

1. **Hybrid approach** - Normalized tables for queryable data, JSONB for flexible module-specific data
2. **Soft deletes** - Children are deactivated, not deleted, allowing restoration
3. **Audit trail** - Coin transactions logged separately from balance
4. **Offline-first friendly** - Schema supports merge-based sync strategy

---

## Authentication

Uses **Supabase Auth** for parent accounts:
- Email/password authentication
- JWT tokens for session management
- Child authentication is a sub-session (PIN verified against our `users` table)

---

## Tables

### families

Represents a family unit containing parents and children.

```sql
CREATE TABLE families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| name | TEXT | Family display name (e.g., "The Barker Family") |
| created_at | TIMESTAMPTZ | When family was created |

---

### users

All users (parents and children) in the system.

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID REFERENCES families(id),
  email TEXT UNIQUE,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('parent', 'child')),
  pin_hash TEXT,
  is_primary_parent BOOLEAN DEFAULT FALSE,
  coins INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

CREATE INDEX idx_users_family ON users(family_id);
CREATE INDEX idx_users_email ON users(email);
```

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| family_id | UUID | FK to families (nullable for guests) |
| email | TEXT | Email for parents only (nullable) |
| display_name | TEXT | Name shown in UI |
| role | TEXT | 'parent' or 'child' |
| pin_hash | TEXT | Hashed 4-digit PIN for children |
| is_primary_parent | BOOLEAN | True for family creator |
| coins | INTEGER | Current coin balance (denormalized for fast reads) |
| is_active | BOOLEAN | Soft delete flag |
| created_at | TIMESTAMPTZ | Account creation time |
| last_login_at | TIMESTAMPTZ | Last login timestamp |

**Notes:**
- `email` links to Supabase Auth for parents
- `coins` is denormalized; `coin_transactions` is the source of truth
- `is_active = FALSE` for soft-deleted children

---

### avatar_items

Reference table of all available avatar customisation items.

```sql
CREATE TABLE avatar_items (
  id TEXT PRIMARY KEY,
  slot TEXT NOT NULL CHECK (slot IN ('head', 'eyes', 'antenna', 'body', 'arm', 'leg', 'accessory')),
  name TEXT NOT NULL,
  price INTEGER NOT NULL,
  rarity TEXT NOT NULL CHECK (rarity IN ('common', 'uncommon', 'rare', 'legendary')),
  preview_url TEXT,
  is_default BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_avatar_items_slot ON avatar_items(slot);
```

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | Unique identifier (e.g., "head_round", "eyes_happy") |
| slot | TEXT | Which slot this item fills |
| name | TEXT | Display name |
| price | INTEGER | Cost in coins |
| rarity | TEXT | Rarity tier |
| preview_url | TEXT | Image URL for shop display |
| is_default | BOOLEAN | True for starter items (owned by all) |

---

### avatar_configs

Current avatar configuration for each user.

```sql
CREATE TABLE avatar_configs (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  skin_color TEXT NOT NULL DEFAULT '#22c55e',
  head TEXT NOT NULL DEFAULT 'head_round' REFERENCES avatar_items(id),
  eyes TEXT NOT NULL DEFAULT 'eyes_simple' REFERENCES avatar_items(id),
  antenna TEXT REFERENCES avatar_items(id),
  body TEXT NOT NULL DEFAULT 'body_basic' REFERENCES avatar_items(id),
  left_arm TEXT NOT NULL DEFAULT 'arm_simple' REFERENCES avatar_items(id),
  right_arm TEXT NOT NULL DEFAULT 'arm_simple' REFERENCES avatar_items(id),
  left_leg TEXT NOT NULL DEFAULT 'leg_simple' REFERENCES avatar_items(id),
  right_leg TEXT NOT NULL DEFAULT 'leg_simple' REFERENCES avatar_items(id),
  accessories TEXT[] DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

| Column | Type | Description |
|--------|------|-------------|
| user_id | UUID | FK to users (one config per user) |
| skin_color | TEXT | Hex colour code |
| head | TEXT | FK to avatar_items |
| eyes | TEXT | FK to avatar_items |
| antenna | TEXT | FK to avatar_items (nullable) |
| body | TEXT | FK to avatar_items |
| left_arm | TEXT | FK to avatar_items |
| right_arm | TEXT | FK to avatar_items |
| left_leg | TEXT | FK to avatar_items |
| right_leg | TEXT | FK to avatar_items |
| accessories | TEXT[] | Array of item IDs |
| updated_at | TIMESTAMPTZ | Last modification time |

---

### avatar_purchases

Record of items each user has purchased/owns.

```sql
CREATE TABLE avatar_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES avatar_items(id),
  purchased_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, item_id)
);

CREATE INDEX idx_avatar_purchases_user ON avatar_purchases(user_id);
```

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users |
| item_id | TEXT | FK to avatar_items |
| purchased_at | TIMESTAMPTZ | When purchased |

**Note:** Default items are NOT stored here; they're implicitly owned via `avatar_items.is_default`.

---

### coin_transactions

Complete audit trail of all coin changes.

```sql
CREATE TABLE coin_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('earned', 'spent', 'penalty')),
  source TEXT NOT NULL,
  module_id TEXT,
  puzzle_id TEXT,
  item_id TEXT REFERENCES avatar_items(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_coin_transactions_user ON coin_transactions(user_id);
CREATE INDEX idx_coin_transactions_created ON coin_transactions(created_at);
```

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users |
| amount | INTEGER | Change amount (positive or negative) |
| type | TEXT | 'earned', 'spent', or 'penalty' |
| source | TEXT | Module ID or 'shop' |
| module_id | TEXT | Which module (for gameplay) |
| puzzle_id | TEXT | Specific puzzle ID (optional) |
| item_id | TEXT | FK to avatar_items (for purchases) |
| created_at | TIMESTAMPTZ | When transaction occurred |

---

### progression_levels

Normalized table for level completion data (queryable for parent dashboard).

```sql
CREATE TABLE progression_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  module_id TEXT NOT NULL,
  level_id TEXT NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  stars INTEGER DEFAULT 0 CHECK (stars >= 0 AND stars <= 3),
  best_time_ms INTEGER,
  attempts INTEGER DEFAULT 0,
  first_completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, module_id, level_id)
);

CREATE INDEX idx_progression_user_module ON progression_levels(user_id, module_id);
CREATE INDEX idx_progression_level ON progression_levels(level_id);
```

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users |
| module_id | TEXT | Module identifier (e.g., "circuit-challenge") |
| level_id | TEXT | Level identifier (e.g., "1-A", "5-C") |
| completed | BOOLEAN | Whether level has been completed |
| stars | INTEGER | Best star rating (0-3) |
| best_time_ms | INTEGER | Best completion time in milliseconds |
| attempts | INTEGER | Number of attempts |
| first_completed_at | TIMESTAMPTZ | When first completed |
| updated_at | TIMESTAMPTZ | Last update time |

---

### module_progress

Flexible JSONB storage for module-specific data (quick play stats, settings).

```sql
CREATE TABLE module_progress (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  module_id TEXT NOT NULL,
  quick_play_stats JSONB DEFAULT '{}',
  settings JSONB DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, module_id)
);
```

| Column | Type | Description |
|--------|------|-------------|
| user_id | UUID | FK to users |
| module_id | TEXT | Module identifier |
| quick_play_stats | JSONB | Module-specific quick play statistics |
| settings | JSONB | Module-specific user settings |
| updated_at | TIMESTAMPTZ | Last update time |

**Circuit Challenge quick_play_stats structure:**
```json
{
  "gamesPlayed": 47,
  "totalCorrect": 523,
  "totalMistakes": 87,
  "bestStreak": 12
}
```

**Circuit Challenge settings structure:**
```json
{
  "lastDifficulty": {
    "preset": "level-5",
    "operations": ["+", "-", "×"],
    "gridRows": 4,
    "gridCols": 5
  },
  "hiddenModeDefault": false
}
```

---

### activity_log

Records play sessions for parent dashboard.

```sql
CREATE TABLE activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  module_id TEXT NOT NULL,
  session_started_at TIMESTAMPTZ NOT NULL,
  session_ended_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  coins_earned INTEGER DEFAULT 0,
  stars_earned INTEGER DEFAULT 0,
  games_played INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  mistakes INTEGER DEFAULT 0
);

CREATE INDEX idx_activity_user ON activity_log(user_id);
CREATE INDEX idx_activity_started ON activity_log(session_started_at);
```

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users |
| module_id | TEXT | Which module was played |
| session_started_at | TIMESTAMPTZ | When session began |
| session_ended_at | TIMESTAMPTZ | When session ended |
| duration_seconds | INTEGER | Total play time |
| coins_earned | INTEGER | Net coins this session |
| stars_earned | INTEGER | Stars earned this session |
| games_played | INTEGER | Puzzles played |
| correct_answers | INTEGER | Total correct |
| mistakes | INTEGER | Total mistakes |

---

### user_settings

Global user preferences (not module-specific).

```sql
CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  sound_effects BOOLEAN DEFAULT TRUE,
  music BOOLEAN DEFAULT TRUE,
  animations TEXT DEFAULT 'full' CHECK (animations IN ('full', 'reduced')),
  daily_time_limit_minutes INTEGER,
  require_parent_pin_to_exit BOOLEAN DEFAULT FALSE
);
```

| Column | Type | Description |
|--------|------|-------------|
| user_id | UUID | FK to users |
| sound_effects | BOOLEAN | Sound effects enabled |
| music | BOOLEAN | Music enabled |
| animations | TEXT | 'full' or 'reduced' |
| daily_time_limit_minutes | INTEGER | Parent-set time limit (nullable) |
| require_parent_pin_to_exit | BOOLEAN | Parental control |

---

## Row Level Security (RLS)

All tables have RLS enabled. Policies ensure:

1. **Users can only access their own data**
2. **Parents can access their children's data**
3. **Children cannot access other children's data**

### Example Policies

```sql
-- Users can read their own profile
CREATE POLICY users_read_own ON users
  FOR SELECT USING (auth.uid() = id);

-- Parents can read their children's profiles
CREATE POLICY users_parent_read_children ON users
  FOR SELECT USING (
    family_id IN (
      SELECT family_id FROM users WHERE id = auth.uid() AND role = 'parent'
    )
  );

-- Users can update their own coin balance
CREATE POLICY users_update_own_coins ON users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
```

Full RLS policies will be defined during implementation.

---

## Sync Strategy

### Client-Side Merge Rules

When syncing offline changes, use these merge rules for conflict resolution:

| Data | Merge Rule |
|------|------------|
| coins (users.coins) | Take higher value |
| progression_levels.stars | Take higher value |
| progression_levels.best_time_ms | Take lower value (faster is better) |
| progression_levels.completed | `true` wins over `false` |
| progression_levels.first_completed_at | Take earliest timestamp |
| progression_levels.attempts | Take higher value |
| module_progress.quick_play_stats | Merge each field with "higher wins" |
| avatar_configs | Last-write-wins (by updated_at) |
| avatar_purchases | Union of both sets |
| user_settings | Last-write-wins (by updated_at) |

### Sync Endpoint

The `/sync` endpoint accepts:
- Client's last sync timestamp
- Changed records with timestamps

Returns:
- Server's current state for changed records
- Merged result based on rules above

---

## Indexes Summary

| Table | Index | Purpose |
|-------|-------|---------|
| users | family_id | Family member queries |
| users | email | Login lookup |
| avatar_items | slot | Shop category filtering |
| avatar_purchases | user_id | User's owned items |
| coin_transactions | user_id | User's transaction history |
| coin_transactions | created_at | Recent transactions |
| progression_levels | user_id, module_id | User's progress in module |
| progression_levels | level_id | Analytics queries |
| activity_log | user_id | User's play history |
| activity_log | session_started_at | Recent activity |

---

## Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────┐
│  families   │───1:N─│    users    │
└─────────────┘       └──────┬──────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ avatar_configs│   │avatar_purchases│  │coin_transactions│
└───────────────┘   └───────┬───────┘   └───────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  avatar_items │ (reference)
                    └───────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│progression_ │     │  module_    │     │ activity_   │
│   levels    │     │  progress   │     │    log      │
└─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │
      └───────────────────┴───────────────────┘
                          │
                    (all FK to users)
```

---

## Migrations

Migrations will be managed via Supabase CLI. Each schema change will be versioned.

Initial migration: `001_initial_schema.sql`

---

*End of Document 9*
