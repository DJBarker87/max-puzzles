# Max's Puzzles - Complete Specification Package

**Version:** 1.2  
**Last Updated:** January 2025  
**Author:** Dom Barker

---

## Overview

This package contains the complete specification for Max's Puzzles, a fun educational maths puzzle platform for children.

---

## Document Index

| Document | Description |
|----------|-------------|
| **01_PROJECT_OVERVIEW.md** | Vision, principles, release versions, success criteria |
| **02_PLATFORM_ARCHITECTURE.md** | Hub-and-spoke architecture, module interface, data flow |
| **03_SHARED_SYSTEMS.md** | Accounts, coins (V3), avatars (V3), parent dashboard |
| **04_HUB_UI_UX.md** | Hub screens, navigation, design system |
| **05_CIRCUIT_CHALLENGE_GAME_DESIGN.md** | Gameplay, modes, scoring, win/lose states |
| **06_CIRCUIT_CHALLENGE_ALGORITHM.md** | Puzzle generation algorithm |
| **07_CIRCUIT_CHALLENGE_DIFFICULTY.md** | Difficulty levers, presets, 30-level progression |
| **08_CIRCUIT_CHALLENGE_UI_UX.md** | Game UI, grid rendering, animations |
| **09_DATABASE_SCHEMA.md** | Supabase tables, relationships, RLS |
| **10_API_SPECIFICATION.md** | REST endpoints, sync strategy |
| **circuit-challenge-print-template.html** | Print template (2 puzzles per A4, B&W) |
| **circuit-challenge-visual-v5.html** | Interactive visual prototype |

---

## Version History

### v1.2 (January 2025)
- Clarified Hidden Mode: no coin animations during play, all revealed at end
- Clarified coin display: clamped running total shown in real-time (stops at 0)
- Defined timer start: first tap on any adjacent cell
- Defined session boundaries: module entry → hub return / switch / 5 min inactivity
- Changed PDF generation: client-side HTML/CSS (not LaTeX), 2 puzzles per A4
- Added parent demo mode: can play Quick Play, nothing tracked
- Clarified Level 4-B: standard unlock rules apply (just a design note)
- Confirmed avatar system is V3 only
- Sound effects: V1 stretch goal
- Keyboard navigation: deferred to V2
- Daily time limits: deferred to V2
- Generation failure: retry 20 times, then error (user adjusts manually)
- Sync: first_completed_at uses earliest timestamp
- Sync: attempts uses higher wins (accept minor inaccuracy)

### v1.1 (January 2025)
- Resolved all specification inconsistencies
- Added Database Schema document
- Added API Specification document
- Standardised level naming to `X-A, X-B, X-C` format
- Clarified Hidden Mode has no lives
- Specified two separate buttons (Reset + New Puzzle)
- Defined sync merge rules (best outcome for player)

### v1.0 (January 2025)
- Initial specification

---

## Key Design Decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | Level naming format | `1-A, 1-B, 1-C` |
| 2 | Hidden Mode introduction | Level 7 (mid-game) |
| 3 | Hidden Mode coins | No animations during play; reveal at end |
| 4 | View Solution UI | Instant full path reveal |
| 5 | Timer start trigger | First tap on any adjacent cell |
| 6 | Coin display | Clamped running total (stops at 0, -30 animation still shows) |
| 7 | Coin loss rules | Per-puzzle minimum 0 (can't lose savings) |
| 8 | Hidden Mode lives | No lives — always reach FINISH |
| 9 | Tutorial hints (Level 1-A) | Highlight valid moves |
| 10 | Grid model | Rectangular with hex visuals (8 neighbours) |
| 11 | Reset button | Two buttons: Reset (same) + New Puzzle |
| 12 | Generation failure | Retry 20 times, then show error |
| 13 | PDF generation | Client-side HTML/CSS, 2 per A4, B&W |
| 14 | Authentication | Supabase Auth for parents, PIN sub-session for children |
| 15 | Parent plays | Demo mode (Quick Play only, nothing saved) |
| 16 | Progress storage | Hybrid (normalized levels + JSONB stats) |
| 17 | Sync: first_completed_at | Earliest timestamp wins |
| 18 | Sync: attempts | Higher wins |
| 19 | Sync strategy | Merge with best outcome for player |
| 20 | Session boundaries | Module entry → hub/switch/5 min inactivity |
| 21 | Avatar system | V3 only |
| 22 | Sound effects | V1 stretch goal |
| 23 | Keyboard controls | Deferred to V2 |
| 24 | Daily time limits | Deferred to V2 |

---

## Version Scope Summary

### V1: Core Game
- Quick Play mode with all difficulty settings
- Hidden Mode toggle
- 5 lives system (standard mode)
- Print puzzles (2 per A4, client-side)
- Puzzle Maker (batch print up to 10)
- Guest mode + Family accounts
- Parent dashboard (play stats, no coins/stars display)
- Parent demo mode
- Sound service (stretch goal)

### V2: Progression
- 30 progression levels
- Star ratings (1/2/3)
- Level unlocking
- Tutorial hints
- Keyboard navigation
- Daily time limits

### V3: Rewards
- Coin economy (UI exposed)
- Avatar system + Shop
- Coins in parent dashboard

---

## Tech Stack

- **Frontend:** React (web), Swift/SwiftUI (iOS, later)
- **Backend:** Supabase (Auth, Database, Storage)
- **PDF Generation:** Client-side HTML/CSS → print

---

*Ready to build!*
