# Max's Puzzles - Shared Systems Specification

**Version:** 1.2  
**Last Updated:** January 2025  
**Author:** Dom Barker

---

## Overview

This document specifies the shared systems that live in the hub and are used by all puzzle modules: accounts, coins, avatars, and the parent dashboard.

**Version notes:**
- Coin economy: Database schema in V1, exposed to users in V3
- Avatar system: Database schema in V1, exposed to users in V3
- Daily time limits: V2

---

## 1. Account System

### Account Types

| Type | Description | Storage | Sync |
|------|-------------|---------|------|
| Guest | No account, play immediately | Local only | None |
| Child | Part of a family, limited permissions | Server | Yes |
| Parent | Family admin, full access + demo mode | Server | Yes |

### Guest Mode

- No signup required
- Progress stored in browser's IndexedDB
- Prompt to create account periodically (non-intrusive)
- Can transfer progress to new account (client-side migration)

### Family Accounts

A family account consists of:
- One primary parent (account creator)
- Optional second parent
- One or more child profiles

```
Family
├── Parent 1 (primary) - email/password login (Supabase Auth)
├── Parent 2 (optional) - email/password login (Supabase Auth)
└── Children
    ├── Child 1 - name + PIN (4 digits, sub-session of parent)
    ├── Child 2 - name + PIN
    └── Child 3 - name + PIN
```

### Child Login Flow

1. Parent logs in with email/password (Supabase Auth)
2. App shows "Who's playing?" with child avatars
3. Child taps their avatar
4. Child enters 4-digit PIN
5. PIN verified against our users table
6. Child session created as sub-session of parent

### Parent Login Flow

1. Enter email and password
2. Option to stay logged in (remember device)
3. See family dashboard or select "Play as Parent" (demo mode)

### Parent Demo Mode

When a parent selects "Play as Parent":
- Can access Quick Play only
- Coins start at 0 each puzzle, +10/-30 animations shown, but nothing saved
- No progression tracking
- No avatar
- Useful for testing puzzles or playing for fun

### Account Creation Flow

1. User clicks "Create Family Account"
2. Enter email, password, display name
3. Email verification (optional for V1)
4. Add first child (name, PIN)
5. Done - can add more children later

### Progress Transfer (Guest → Account)

When a guest creates an account:

1. Prompt: "Transfer your progress to your new account?"
2. If yes: client uploads local progress to server via API
3. If no: start fresh
4. Clear local guest data after transfer

### Session Management

- Sessions expire after 30 days of inactivity
- "Remember me" keeps session alive
- Parent can log out all devices from dashboard
- Child sessions tied to parent session

---

## 2. Coin Economy (V3)

**Note:** Database schema and code architecture built in V1, but coin UI and shop not exposed to users until V3.

### Earning Coins

| Action | Coins | Notes |
|--------|-------|-------|
| Correct answer | +10 | During gameplay |
| Mistake | -30 | During gameplay |
| Complete puzzle | - | No bonus, just answer coins |

### Constraints

- **Minimum 0 coins per puzzle** (can't go negative in a single game)
- Existing coin balance is never reduced by gameplay
- Total balance can never go below 0
- Coins persist across sessions
- Coins shared across all modules

### Coin Display (V3)

**Standard Mode:**
- Coin counter in header shows clamped running total for current puzzle
- +10 floats UP in green when correct
- -30 floats DOWN in red when wrong (animation shows even when counter is at 0)
- Counter never displays negative; stops at 0

**Hidden Mode:**
- No coin animations during gameplay
- Coin counter stays static (shows balance from before puzzle started)
- All coin results revealed on summary screen at end

### Coin Storage

- **Stored value** in `users.coins` column for fast reads
- **Transaction history** in `coin_transactions` table for audit trail
- Reconciliation on each sync to ensure consistency

### Coin Service API

```typescript
interface CoinService {
  // Get current balance
  getBalance(): number;
  
  // Add coins (can be negative for penalties)
  // Returns actual amount added (respects per-puzzle minimum of 0)
  addCoins(amount: number): number;
  
  // Get clamped running total for current puzzle
  getPuzzleTotal(): number;
  
  // Reset puzzle total (called when starting new puzzle)
  resetPuzzleTotal(): void;
  
  // Spend coins (for purchases)
  // Returns true if successful, false if insufficient
  spend(amount: number): boolean;
  
  // Get transaction history (for parent dashboard)
  getHistory(limit?: number): Transaction[];
}

interface Transaction {
  id: string;
  amount: number;
  type: 'earned' | 'spent' | 'penalty';
  source: string;      // Module ID or 'shop'
  timestamp: Date;
  puzzleId?: string;   // If from gameplay
  itemId?: string;     // If from shop
}
```

### Economy Balancing (V3)

Initial pricing guidelines (to be tuned):

| Item Type | Price Range |
|-----------|-------------|
| Basic colour | 50-100 coins |
| Accessory | 100-200 coins |
| Special item | 200-500 coins |
| Rare item | 500-1000 coins |

A child who plays well earns roughly:
- 10-step puzzle, no mistakes: 100 coins
- 10-step puzzle, 2 mistakes: 40 coins
- 10-step puzzle, 4 mistakes: 0 coins (minimum)

So a basic item requires 1-2 perfect games.

---

## 3. Avatar System (V3)

**Note:** Database schema built in V1, but avatar UI and shop not exposed to users until V3.

### Concept

Each child has an alien avatar they can customise. The alien is built from modular parts that can be purchased with coins.

### Alien Anatomy

```
        ┌─────────┐
        │  HEAD   │ ◄── Includes eyes, antenna, etc.
        └────┬────┘
             │
        ┌────┴────┐
        │  BODY   │ ◄── Main torso shape
        └────┬────┘
           ┌─┴─┐
          ┌┴┐ ┌┴┐
          │L│ │R│ ◄── Arms (can be different)
          └─┘ └─┘
           ┌─┴─┐
          ┌┴┐ ┌┴┐
          │L│ │R│ ◄── Legs (can be different)
          └─┘ └─┘
```

### Customisation Slots

| Slot | Options | Notes |
|------|---------|-------|
| Skin colour | Multiple colours | Base appearance |
| Head shape | Multiple shapes | Basic head form |
| Eyes | Multiple styles | Expression |
| Antenna | Multiple styles + none | Optional |
| Body | Multiple shapes | Torso |
| Arms | Multiple styles | L/R can differ |
| Legs | Multiple styles | L/R can differ |
| Accessory | Hats, glasses, etc. | Optional extras |

### Default Avatar

New users start with:
- Basic green skin
- Round head
- Simple eyes
- No antenna
- Basic body
- Simple arms and legs
- No accessories

Everything else must be purchased.

### Avatar Data Structure

```typescript
interface AvatarConfig {
  skinColor: string;        // Hex colour or preset ID
  head: string;             // Item ID
  eyes: string;             // Item ID
  antenna: string | null;   // Item ID or null
  body: string;             // Item ID
  leftArm: string;          // Item ID
  rightArm: string;         // Item ID
  leftLeg: string;          // Item ID
  rightLeg: string;         // Item ID
  accessories: string[];    // Array of item IDs
}

interface AvatarItem {
  id: string;
  slot: 'head' | 'eyes' | 'antenna' | 'body' | 'arm' | 'leg' | 'accessory';
  name: string;
  price: number;
  rarity: 'common' | 'uncommon' | 'rare' | 'legendary';
  preview: string;          // Image path
  isDefault: boolean;       // True for starter items
}
```

### Avatar Service API

```typescript
interface AvatarService {
  // Get current avatar config
  getConfig(): AvatarConfig;
  
  // Update avatar (equip items)
  updateConfig(config: Partial<AvatarConfig>): void;
  
  // Get all items (owned and unowned)
  getAllItems(): AvatarItem[];
  
  // Get owned items
  getOwnedItems(): AvatarItem[];
  
  // Purchase item (uses CoinService internally)
  purchaseItem(itemId: string): PurchaseResult;
  
  // Check if item is owned
  isOwned(itemId: string): boolean;
}

interface PurchaseResult {
  success: boolean;
  error?: 'insufficient_coins' | 'already_owned' | 'item_not_found';
  newBalance?: number;
}
```

### Shop Interface (V3)

The shop displays items by category:
- Tabs for each slot type
- Grid of items with previews
- Price shown on each
- "Owned" badge on purchased items
- Tap item to preview on avatar
- "Buy" button (disabled if insufficient coins)
- Coin balance always visible

---

## 4. Parent Dashboard

### Purpose

Allow parents to monitor children's progress and usage without being intrusive.

### Dashboard Sections

#### 4.1 Family Overview

- List of all children in family
- Quick stats per child:
  - Total coins (V3)
  - Total stars earned (V2)
  - Last played
  - Time played this week

#### 4.2 Child Detail View

When parent selects a child:

**Summary Stats**
- Total coins (all time) — V3
- Total stars (all modules combined) — V2
- Favourite module (most played)
- Current streak (consecutive days)

**Per-Module Progress**
- Circuit Challenge:
  - Levels completed: 15/30 (V2)
  - Stars earned: 38/90 (V2)
  - Quick Play games: 47
  - Total correct answers: 523
  - Total mistakes: 87
  - Accuracy: 86%

**Activity History**
- List of recent sessions
- Date, module, duration, coins earned (V3)

#### 4.3 Settings

- Add/remove children (soft delete)
- Change child PINs
- Reset child progress (with confirmation)
- Add second parent
- Export data
- Delete family account

### Parent Dashboard API

```typescript
interface ParentDashboard {
  // Get family overview
  getFamily(): Family;
  
  // Get detailed stats for one child
  getChildStats(childId: string): ChildStats;
  
  // Get activity history
  getActivityHistory(childId: string, limit?: number): Activity[];
  
  // Management
  addChild(name: string, pin: string): Child;
  removeChild(childId: string): void;  // Soft delete
  updateChildPin(childId: string, newPin: string): void;
  resetChildProgress(childId: string, moduleId?: string): void;
}

interface ChildStats {
  totalCoins: number;
  totalStars: number;
  totalPlayTime: number;      // Minutes
  playTimeThisWeek: number;   // Minutes
  lastPlayed: Date | null;
  currentStreak: number;      // Days
  modules: {
    [moduleId: string]: ModuleStats;
  };
}

interface ModuleStats {
  levelsCompleted: number;
  totalLevels: number;
  starsEarned: number;
  totalStars: number;
  gamesPlayed: number;
  correctAnswers: number;
  mistakes: number;
  accuracy: number;           // Percentage
}

interface Activity {
  id: string;
  timestamp: Date;
  moduleId: string;
  moduleName: string;
  duration: number;           // Minutes
  coinsEarned: number;
  starsEarned: number;
}
```

---

## 5. Session Tracking

### Session Definition

A **play session** tracks continuous play within a module.

**Session starts:** When entering a module
**Session ends:** When any of these occur:
- User returns to hub
- User switches to another module
- 5 minutes of inactivity

### Session Data

Each session records:
- `moduleId`: Which module was played
- `session_started_at`: When session began
- `session_ended_at`: When session ended
- `duration_seconds`: Total play time
- `games_played`: Number of puzzles attempted
- `correct_answers`: Total correct answers
- `mistakes`: Total mistakes
- `coins_earned`: Net coins this session (V3)
- `stars_earned`: Stars earned this session (V2)

### Usage

- Displayed in parent dashboard activity history
- Used to calculate "time played this week"
- Used to calculate play streaks

---

## 6. Data Persistence

### Local Storage (IndexedDB)

Used for:
- Guest mode (all data)
- Offline cache (logged-in users)
- Pending sync queue

Structure:
```
maxs-puzzles-db/
├── user/           # Current user profile
├── coins/          # Coin balance and transactions (V3)
├── avatar/         # Avatar config and owned items (V3)
├── progress/       # Per-module progress
│   ├── circuit-challenge/
│   └── [other modules]/
└── sync-queue/     # Pending server updates
```

### Server Storage (Supabase)

See Document 09: Database Schema for full specification.

### Sync Strategy

1. **Write locally first** - All changes save to IndexedDB immediately
2. **Queue for sync** - Add to sync queue with timestamp
3. **Sync when online** - Process queue in order
4. **Handle conflicts** - Merge with best outcome for player
5. **Retry on failure** - Exponential backoff

### Merge Rules (Best Outcome for Player)

| Data | Merge Rule |
|------|------------|
| Coins balance | Take higher value |
| Level stars | Take higher value |
| Level best time | Take lower value (faster is better) |
| Level completed | `true` wins over `false` |
| Level first_completed_at | Take earliest timestamp |
| Level attempts | Take higher value |
| Quick play games played | Take higher value |
| Quick play total correct | Take higher value |
| Quick play total mistakes | Take higher value |
| Quick play best streak | Take higher value |
| Avatar config | Last-write-wins (timestamp) |
| Avatar purchases | Union of both sets |
| Settings | Last-write-wins (timestamp) |

---

## 7. Settings

### Per-User Settings

| Setting | Options | Default |
|---------|---------|---------|
| Sound effects | On/Off | On |
| Music | On/Off | On |
| Animations | Full/Reduced | Full |

### Parent-Only Settings (V2)

| Setting | Options | Default |
|---------|---------|---------|
| Daily time limit | Off/15/30/60 min | Off |
| Require parent PIN to exit | On/Off | Off |

**Note:** Daily time limits are deferred to V2. The settings will be stored but not enforced in V1.

### Settings Storage

Settings stored per-user in their profile, synced with server.

---

*End of Document 3*
