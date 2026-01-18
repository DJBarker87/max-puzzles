# Max's Puzzles - Project Overview & Vision

**Version:** 1.2  
**Last Updated:** January 2025  
**Author:** Dom Barker

---

## Vision

A fun, educational maths puzzle platform for children, starting with Max (age 6). The platform hosts multiple puzzle modules that share a common reward system, allowing new puzzle types to be added over time as Max discovers games he enjoys.

---

## Core Principles

1. **Fun first** - Engaging gameplay that children want to return to
2. **Educational** - Reinforces mental arithmetic through play
3. **Quality over speed** - Professional-standard output, even if it takes longer
4. **Expandable** - Architecture supports adding new puzzle modules easily
5. **Offline-capable** - Core gameplay works without internet
6. **No monetisation** - A gift for Max, not a commercial product

---

## Target Audience

**Primary:** Max (age 6) and children aged 5-11

**Secondary:** Parents who want to track progress; teachers who might use printed puzzles

---

## Platforms

| Platform | Priority | Notes |
|----------|----------|-------|
| Web (responsive) | Primary | Works on desktop and mobile browsers |
| iOS (native) | Secondary | Native Swift/SwiftUI app, later phase |
| Android | Not planned | Web app serves Android users if needed |

---

## Platform Architecture

Max's Puzzles is a **hub-and-spoke platform**:

**The Hub (shared across all modules):**
- User accounts (guest mode, family accounts)
- Coin economy (earned across all modules, spent in one place) — V3
- Alien avatar customisation and shop — V3
- Parent dashboard
- Main menu and module selection

**Puzzle Modules (independent, pluggable):**
- Each module has its own gameplay, progression, and difficulty system
- Modules contribute coins to the shared pool
- Modules track their own stars/completion separately
- First module: **Circuit Challenge**

```
┌─────────────────────────────────────────────┐
│                 MAX'S PUZZLES               │
│                    (Hub)                    │
│  ┌─────────┐  ┌─────────┐  ┌─────────────┐ │
│  │  Coins  │  │  Alien  │  │   Family    │ │
│  │ Economy │  │  Avatar │  │  Accounts   │ │
│  │  (V3)   │  │  (V3)   │  │             │ │
│  └─────────┘  └─────────┘  └─────────────┘ │
└──────────────────┬──────────────────────────┘
                   │
       ┌───────────┼───────────┐
       │           │           │
       ▼           ▼           ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│ Circuit  │ │  Future  │ │  Future  │
│Challenge │ │  Module  │ │  Module  │
└──────────┘ └──────────┘ └──────────┘
```

---

## Release Versions

All versions are built with the full architecture in mind. Later features are designed upfront but implemented incrementally.

### Version 1: Core Game

- Quick Play mode (generate puzzles at any difficulty)
- Full difficulty system (all operations, number ranges, grid sizes)
- Hidden Mode toggle
- 5 lives system (standard mode only)
- Two action buttons: Reset (same puzzle) and New Puzzle
- Print current puzzle (client-side HTML/CSS to PDF)
- Puzzle Maker (batch print up to 10 puzzles, 2 per A4 page)
- Guest mode (local storage)
- Family accounts (email signup, parent + child profiles)
- Parent dashboard (view children's play history)
- Parent demo mode (can play Quick Play, nothing tracked)
- Responsive web (desktop + mobile, touch/click only)
- Timer starts on first move (any adjacent cell tap)
- Sound effects (stretch goal: build service, add sounds if time permits)

### Version 2: Progression

- 30 progression levels (10 levels × 3 sublevels: A, B, C)
- Star ratings (1/2/3 based on mistakes and time)
- Level unlocking (2 stars required)
- Hidden Mode built into specific levels (Level 7 onwards)
- Tutorial hints on Level 1-A (highlight valid moves)
- Keyboard navigation for desktop
- Daily time limits (parent setting)

### Version 3: Rewards

- Coin economy exposed to users (+10 correct, -30 mistake, minimum 0 per puzzle)
- Alien avatar system
- Shop (buy body parts with coins)
- Coins tracked in parent dashboard

**Critical design note:** Even in V1, the database schema and code architecture must accommodate coins, stars, avatars, and progression — they're just not exposed to the user yet.

---

## Game Modes (per module)

Each puzzle module supports:

| Mode | Description |
|------|-------------|
| **Quick Play** | Generate puzzles on-demand, player chooses difficulty, infinite play |
| **Progression** | Curated levels with increasing difficulty, star ratings, unlock gates (V2) |
| **Puzzle Maker** | Generate batches of puzzles for printing (up to 10), choose difficulty |

---

## Reward System

### Coins (V3)

- Earned: +10 per correct answer
- Lost: -30 per mistake
- **Minimum 0 coins per puzzle** (can't lose existing savings)
- UI shows clamped running total in real-time (counter stops at 0, but -30 animation still shows)
- In Hidden Mode: no coin animations during play; all revealed at end
- Spent: Avatar customisation in the shop
- Shared across all puzzle modules

### Stars (per module, V2)

- 1 star: Completed (with mistakes)
- 2 stars: No mistakes
- 3 stars: No mistakes + under time threshold
- 2 stars required to unlock next level
- Tracked separately per module

---

## First Module: Circuit Challenge

A path-finding puzzle where players navigate from START to FINISH by solving arithmetic problems. Each cell contains a calculation; the answer determines which connector to follow.

**Key features:**
- Hexagonal grid with connectors (visually hex, logically rectangular)
- Operations: +, −, ×, ÷ (scaled by difficulty)
- Hidden Mode option (mistakes revealed at end, no lives, no coin animations during play)
- 30 progression levels (10 levels × 3 sublevels) — V2
- Client-side printable puzzles (2 per A4 page, pure black & white)

---

## Success Criteria

The app is successful if:

1. Max actively wants to play it
2. Max's maths fluency improves
3. The architecture easily supports adding a second puzzle module
4. Print output is good enough for classroom use

---

## What This Is Not

- Not a commercial product
- Not competing with NumBots (inspiration, not competitor)
- Not multiplayer
- Not requiring constant internet

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Level naming format | `1-A, 1-B, 1-C` | Clear, parseable, consistent |
| Timer trigger | On first tap of any adjacent cell | Fair for children who need time to study puzzle |
| Coin loss | Per-puzzle minimum 0, clamped in real-time | Less punishing for young children |
| Hidden Mode lives | None (always finish) | Tests understanding, not survival |
| Hidden Mode coins | No animations during play, reveal at end | Don't reveal mistakes mid-game |
| Grid model | Rectangular with hex visuals | Simpler algorithm, 8 neighbours |
| View Solution | Instant full path reveal | Simple, allows study at own pace |
| Reset vs New | Two separate buttons | Allows both retry and fresh start |
| PDF generation | Client-side HTML/CSS print | Works on web and iOS without server |
| Parent plays | Demo mode (Quick Play only, nothing saved) | Testing without affecting profiles |
| Avatar system | V3 only | Focus on core gameplay first |
| Sound effects | V1 stretch goal | Build service, add if time permits |
| Keyboard nav | V2 | Touch/click only for V1 |
| Daily time limits | V2 | Focus on core game first |
| Generation failure | Retry 20 times, then error | User adjusts settings manually |
| Sync: first_completed_at | Earliest timestamp wins | True "first" completion |
| Sync: attempts | Higher wins | Accept minor inaccuracy in rare edge case |
| Session boundaries | Module entry → hub return / switch / 5 min inactivity | Meaningful play session tracking |

---

*End of Document 1*
