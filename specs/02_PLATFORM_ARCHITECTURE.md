# Max's Puzzles - Platform Architecture

**Version:** 1.2  
**Last Updated:** January 2025  
**Author:** Dom Barker

---

## Overview

Max's Puzzles uses a hub-and-spoke architecture designed for extensibility. The platform consists of a central hub providing shared services, with independent puzzle modules that plug into it.

This document defines the boundaries between hub and modules, the interfaces they share, and how new modules can be added.

---

## Architecture Principles

1. **Modules are independent** - Each puzzle module can be developed, tested, and deployed separately
2. **Shared services live in the hub** - Authentication, coins, avatars, and persistence are centralised
3. **Modules own their gameplay** - Game logic, difficulty, and UI are entirely within the module
4. **Communication via interfaces** - Modules interact with the hub through defined APIs, not direct coupling
5. **Offline-first** - Game logic runs client-side; server is only for persistence and sync

---

## System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                        HUB UI                             │  │
│  │  • Main menu           • Avatar display (V3)              │  │
│  │  • Module selector     • Shop interface (V3)              │  │
│  │  • Parent dashboard    • Settings                         │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│              ┌───────────────┼───────────────┐                  │
│              │               │               │                  │
│              ▼               ▼               ▼                  │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐       │
│  │    Circuit    │  │    Future     │  │    Future     │       │
│  │   Challenge   │  │    Module     │  │    Module     │       │
│  │    Module     │  │               │  │               │       │
│  └───────────────┘  └───────────────┘  └───────────────┘       │
├─────────────────────────────────────────────────────────────────┤
│                       SHARED SERVICES                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │    Auth     │  │   Coins &   │  │   Avatar    │             │
│  │   Service   │  │   Economy   │  │   Service   │             │
│  │             │  │    (V3)     │  │    (V3)     │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Storage   │  │    Sync     │  │   Sound     │             │
│  │   Service   │  │   Service   │  │   Service   │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
├─────────────────────────────────────────────────────────────────┤
│                       SERVER LAYER                              │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                      Supabase                               ││
│  │  • Authentication    • Database    • Realtime (future)     ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## Hub Responsibilities

The hub provides these services to all modules:

### 1. Authentication Service

- Guest mode (local storage, no account)
- Family account creation (email/password via Supabase Auth)
- Login/logout
- Session management
- Child authentication (PIN as sub-session of parent)
- Progress transfer (guest → account, client-side migration)
- Parent demo mode (can play Quick Play, nothing tracked)

### 2. User Profile Service

- Current user info (name, isParent, familyId)
- Coin balance (read/update) — V3
- Avatar configuration — V3

### 3. Avatar Service (V3)

- Current avatar state
- Available items (unlocked/locked)
- Purchase item (deduct coins, unlock item)
- Equip/unequip items

### 4. Storage Service

- Save module progress
- Load module progress
- Local caching for offline support
- Sync with server when online
- Merge strategy: best outcome for player

### 5. Parent Dashboard

- List children in family
- View child's progress per module
- View play history (session-based tracking)

### 6. Sound Service (V1 Stretch Goal)

- Play sound effects (correct, wrong, complete, etc.)
- Sound on/off toggle
- Respects user settings

---

## Module Interface

Every puzzle module must implement this interface to integrate with the hub:

```typescript
interface PuzzleModule {
  // Metadata
  id: string;                    // Unique identifier, e.g., "circuit-challenge"
  name: string;                  // Display name, e.g., "Circuit Challenge"
  description: string;           // Short description for module selector
  icon: string;                  // Icon path or component
  
  // Lifecycle
  init(hub: HubServices): void;  // Called when module loads
  destroy(): void;               // Called when module unloads
  
  // Entry points
  renderMenu(): Component;       // Module's own menu (Quick Play, Progression, etc.)
  renderGame(config: GameConfig): Component;  // Active gameplay
  
  // Progress (for parent dashboard)
  getProgressSummary(userId: string): ModuleProgress;
}

interface HubServices {
  auth: AuthService;
  coins: CoinService;      // V3 - stubbed in V1/V2
  storage: StorageService;
  avatar: AvatarService;   // V3 - stubbed in V1/V2
  sound: SoundService;     // V1 stretch goal
}

interface ModuleProgress {
  totalLevels: number;
  completedLevels: number;
  totalStars: number;
  earnedStars: number;
  lastPlayed: Date | null;
}
```

---

## Module Registration

Modules are registered with the hub at startup:

```typescript
// In app initialization
import { CircuitChallengeModule } from './modules/circuit-challenge';
import { FutureModule } from './modules/future-module';

hub.registerModule(CircuitChallengeModule);
hub.registerModule(FutureModule);  // When ready
```

The hub maintains a registry of available modules and renders the module selector accordingly.

---

## Coin Flow (V3)

Coins flow from modules to the hub:

```
┌─────────────────┐         ┌─────────────────┐
│     Module      │         │       Hub       │
│                 │         │                 │
│  Player gets    │         │                 │
│  answer correct ├────────►│  addCoins(10)   │
│                 │         │                 │
│  Player makes   │         │                 │
│  mistake        ├────────►│  addCoins(-30)  │
│                 │         │  (min 0/puzzle) │
│                 │         │                 │
└─────────────────┘         └─────────────────┘
```

Modules never store coins - they call the hub's coin service.

**Important:** Each puzzle tracks a running total (clamped to minimum 0). The UI shows the clamped value in real-time, so the counter never goes negative. The -30 animation still displays to show that mistakes have consequences, but the counter stops at 0.

**Hidden Mode exception:** In Hidden Mode, no coin animations are shown during play. All coin results are revealed at the end.

---

## Progress Storage

Each module has its own progress namespace:

```typescript
// Module saves progress
hub.storage.save('circuit-challenge', {
  quickPlay: {
    gamesPlayed: 47,
    bestStreak: 12
  },
  progression: {
    levels: {
      '1-A': { stars: 3, bestTime: 45, completed: true },
      '1-B': { stars: 2, bestTime: 78, completed: true },
      '1-C': { stars: 0, bestTime: null, completed: false }
    }
  }
});

// Module loads progress
const progress = await hub.storage.load('circuit-challenge');
```

The storage service handles:
- Local caching (IndexedDB)
- Server sync (Supabase)
- Conflict resolution (merge with best outcome for player)
- Offline queuing

---

## Session Tracking

A **play session** is tracked for the parent dashboard:

**Session boundaries:**
- Starts: When entering a module
- Ends: When returning to hub, switching modules, OR after 5 minutes of inactivity

**Session data recorded:**
- Module ID
- Start/end timestamps
- Duration
- Games played
- Correct answers / mistakes
- Coins earned (V3)
- Stars earned (V2)

---

## Data Flow: Complete Session Example

```
1. User opens app
   └─► Hub loads from local storage (instant)
   └─► Hub syncs with server in background
   
2. User selects Circuit Challenge
   └─► Hub calls module.init(hubServices)
   └─► Hub starts session tracking
   └─► Module loads its progress via hub.storage.load()
   └─► Module renders its menu
   
3. User plays Quick Play
   └─► Module generates puzzle (client-side)
   └─► Module handles all gameplay
   └─► On correct answer: module calls hub.coins.add(10) [V3]
   └─► On mistake: module calls hub.coins.add(-30) [V3]
   
4. User completes puzzle
   └─► Module calculates final coins for this puzzle (min 0) [V3]
   └─► Module saves progress via hub.storage.save()
   └─► Hub queues sync to server
   
5. User returns to hub
   └─► Hub ends session (or after 5 min inactivity)
   └─► Module calls destroy()
   └─► Hub logs session to activity_log
   └─► Hub displays updated coin balance [V3]
   
6. User goes to shop [V3]
   └─► Hub displays avatar and items
   └─► User purchases item
   └─► Hub deducts coins, unlocks item
   └─► Hub saves to local storage + syncs
```

---

## Adding a New Module

To add a new puzzle module:

1. **Create module folder**
   ```
   /modules/new-puzzle/
     index.ts          # Module entry point
     components/       # UI components
     logic/           # Game engine
     types.ts         # Module-specific types
   ```

2. **Implement the interface**
   ```typescript
   export const NewPuzzleModule: PuzzleModule = {
     id: 'new-puzzle',
     name: 'New Puzzle',
     description: 'A new type of puzzle',
     icon: '/icons/new-puzzle.svg',
     
     init(hub) { /* ... */ },
     destroy() { /* ... */ },
     renderMenu() { /* ... */ },
     renderGame(config) { /* ... */ },
     getProgressSummary(userId) { /* ... */ }
   };
   ```

3. **Register with hub**
   ```typescript
   hub.registerModule(NewPuzzleModule);
   ```

4. **Add database migration** (if needed for progress schema)

That's it. The hub handles everything else.

---

## Offline Behaviour

### What works offline:
- Gameplay (all game logic is client-side)
- Local progress saving
- Avatar display (cached) — V3
- Module switching

### What requires online:
- Account creation
- Login (initial)
- Sync to server
- Shop purchases (needs coin balance verification) — V3

### Sync strategy:
- Save locally immediately
- Queue server sync
- Sync when online
- Merge conflicts using best outcome for player (see Document 10 for details)

---

## Future Considerations

### Multiplayer (not planned, but possible)
- Would require realtime sync (Supabase Realtime)
- Modules could expose a `multiplayerConfig` if supported
- Hub would manage matchmaking

### Module marketplace (not planned)
- Could allow third-party modules
- Would need sandboxing and review process
- Current architecture supports it

### Cross-device play
- Already supported via family accounts
- Progress syncs automatically
- Could add "continue on this device" notification

---

*End of Document 2*
