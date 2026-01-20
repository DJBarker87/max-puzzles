# Max's Puzzles - Build Guide (CLAUDE.md)

**Version:** 1.0  
**Last Updated:** January 2025  
**Purpose:** Guide for Claude Code to build Max's Puzzles from the specification package

---

## Project Overview

Max's Puzzles is a fun, educational maths puzzle platform for children aged 5-11, starting with Max (age 6). It uses a **hub-and-spoke architecture** where a central hub provides shared services (auth, coins, avatars) and independent puzzle modules plug into it.

**First module:** Circuit Challenge - a path-finding puzzle using arithmetic.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | React 18+ with TypeScript |
| Styling | Tailwind CSS |
| State | React Context + hooks (simple state), IndexedDB (persistence) |
| Backend | Supabase (Auth, PostgreSQL, Storage) |
| Build | Vite |
| Testing | Vitest + React Testing Library |
| PDF/Print | Client-side HTML/CSS → browser print |

---

## Reference Documentation

| Folder | Contents |
|--------|----------|
| `/docs` | Phase-by-phase build guides (PHASE_01 through PHASE_10) |
| `/specs` | Original design specifications and visual prototypes |

**Key reference files:**
- `/specs/circuit-challenge-visual-v5.html` - Interactive visual prototype (open in browser for CSS/SVG reference)
- `/specs/circuit-challenge-print-template.html` - Print layout reference
- `/specs/06_CIRCUIT_CHALLENGE_ALGORITHM.md` - Puzzle generation algorithm details
- `/specs/08_CIRCUIT_CHALLENGE_UI_UX.md` - UI specifications and colour values

When implementing, check the relevant `/docs/PHASE_XX` file for step-by-step instructions, and reference `/specs` for design details and edge cases.

---

## Project Structure

```
max-puzzles/
├── src/
│   ├── app/                    # App shell, routing, providers
│   │   ├── App.tsx
│   │   ├── routes.tsx
│   │   └── providers/
│   │       ├── AuthProvider.tsx
│   │       ├── CoinProvider.tsx      # V3 - stub for now
│   │       ├── SoundProvider.tsx     # V1 stretch goal
│   │       └── StorageProvider.tsx
│   │
│   ├── hub/                    # Hub screens and components
│   │   ├── screens/
│   │   │   ├── SplashScreen.tsx
│   │   │   ├── LoginScreen.tsx
│   │   │   ├── FamilySelectScreen.tsx
│   │   │   ├── PinEntryScreen.tsx
│   │   │   ├── MainHubScreen.tsx
│   │   │   ├── ModuleSelectScreen.tsx
│   │   │   ├── ShopScreen.tsx        # V3
│   │   │   ├── SettingsScreen.tsx
│   │   │   └── ParentDashboard/
│   │   │       ├── index.tsx
│   │   │       ├── ChildDetailView.tsx
│   │   │       └── ActivityHistory.tsx
│   │   └── components/
│   │       ├── Avatar.tsx            # V3 - placeholder for now
│   │       ├── CoinDisplay.tsx
│   │       ├── Header.tsx
│   │       └── ModuleCard.tsx
│   │
│   ├── modules/                # Puzzle modules (hub-and-spoke)
│   │   └── circuit-challenge/
│   │       ├── index.ts              # Module registration
│   │       ├── types.ts              # Module-specific types
│   │       ├── screens/
│   │       │   ├── ModuleMenu.tsx
│   │       │   ├── QuickPlaySetup.tsx
│   │       │   ├── GameScreen.tsx
│   │       │   ├── SummaryScreen.tsx
│   │       │   ├── ProgressionSelect.tsx   # V2
│   │       │   └── PuzzleMaker.tsx
│   │       ├── components/
│   │       │   ├── PuzzleGrid.tsx
│   │       │   ├── HexCell.tsx
│   │       │   ├── Connector.tsx
│   │       │   ├── LivesDisplay.tsx
│   │       │   ├── TimerDisplay.tsx
│   │       │   └── ActionButtons.tsx
│   │       ├── engine/
│   │       │   ├── generator.ts          # Puzzle generation algorithm
│   │       │   ├── pathfinder.ts         # Solution path generation
│   │       │   ├── expressions.ts        # Arithmetic expression generation
│   │       │   ├── validator.ts          # Puzzle validation
│   │       │   └── difficulty.ts         # Difficulty presets & settings
│   │       ├── hooks/
│   │       │   ├── useGame.ts            # Game state management
│   │       │   ├── usePuzzle.ts          # Puzzle generation hook
│   │       │   └── useProgress.ts        # Progress tracking
│   │       └── print/
│   │           ├── PrintTemplate.tsx
│   │           └── generatePrintPuzzles.ts
│   │
│   ├── shared/                 # Shared utilities
│   │   ├── services/
│   │   │   ├── auth.ts
│   │   │   ├── coins.ts              # V3 - stub returning 0 for now
│   │   │   ├── storage.ts            # IndexedDB + Supabase sync
│   │   │   ├── sound.ts              # V1 stretch goal
│   │   │   └── sync.ts               # Offline sync logic
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   ├── useCoins.ts           # V3
│   │   │   ├── useStorage.ts
│   │   │   └── useOffline.ts
│   │   ├── types/
│   │   │   ├── auth.ts
│   │   │   ├── module.ts             # PuzzleModule interface
│   │   │   ├── coins.ts              # V3
│   │   │   └── avatar.ts             # V3
│   │   └── utils/
│   │       ├── formatters.ts
│   │       └── validators.ts
│   │
│   ├── ui/                     # Design system components
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Input.tsx
│   │   ├── Modal.tsx
│   │   ├── Toggle.tsx
│   │   ├── Slider.tsx
│   │   └── animations/
│   │       ├── Confetti.tsx
│   │       ├── CoinFloat.tsx
│   │       └── ScreenShake.tsx
│   │
│   └── styles/
│       ├── globals.css
│       └── theme.ts            # Colour palette, typography
│
├── public/
│   ├── icons/
│   └── sounds/                 # V1 stretch goal
│
├── supabase/
│   ├── migrations/
│   │   └── 001_initial_schema.sql
│   └── seed.sql                # Avatar items, test data
│
├── tests/
│   ├── engine/                 # Puzzle generation tests
│   ├── integration/            # User flow tests
│   └── utils/                  # Utility tests
│
├── docs/                       # Specification documents
│   ├── 01_PROJECT_OVERVIEW.md
│   ├── ... (all spec docs)
│   └── circuit-challenge-visual-v5.html
│
├── CLAUDE.md                   # This file
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.js
└── README.md
```

---

## Version Scope

### V1: Core Game (CURRENT BUILD)

**Must have:**
- [ ] Quick Play mode with all difficulty settings
- [ ] Full difficulty system (10 preset levels + custom)
- [ ] Hidden Mode toggle
- [ ] 5 lives system (standard mode only)
- [ ] Two action buttons: Reset + New Puzzle
- [ ] Print current puzzle (client-side HTML/CSS)
- [ ] Puzzle Maker (batch print up to 10, 2 per A4)
- [ ] Guest mode (IndexedDB only)
- [ ] Family accounts (Supabase Auth)
- [ ] Parent dashboard (play stats visible)
- [ ] Parent demo mode
- [ ] Responsive web (mobile + desktop)
- [ ] Timer starts on first move

**Stretch goal:**
- [ ] Sound effects service

**Deferred to V2:**
- 30 progression levels
- Star ratings
- Level unlocking
- Tutorial hints (Level 1-A)
- Keyboard navigation
- Daily time limits

**Deferred to V3:**
- Coin economy (UI exposed)
- Avatar system + shop
- Coins in parent dashboard

---

## Critical Design Decisions

Reference these when implementing:

| # | Decision | Implementation |
|---|----------|----------------|
| 1 | Level naming | `"1-A"`, `"1-B"`, `"1-C"` format |
| 2 | Timer start | First tap on ANY adjacent cell (correct or wrong) |
| 3 | Coin display | Clamped running total, stops at 0, -30 animation still shows |
| 4 | Per-puzzle minimum | 0 coins (can't lose existing savings from single puzzle) |
| 5 | Hidden Mode | No lives, no coin animations during play, all revealed at end |
| 6 | Grid model | Rectangular logic with hexagonal visuals (8 neighbours) |
| 7 | View Solution | Instant full path reveal (all at once) |
| 8 | Generation failure | Retry 20 times, then show error to user |
| 9 | PDF generation | Client-side HTML/CSS → browser print, 2 per A4 |
| 10 | Auth model | Supabase Auth for parents, PIN sub-session for children |
| 11 | Parent demo | Can play Quick Play, nothing tracked/saved |
| 12 | Session boundaries | Module entry → hub return / switch / 5 min inactivity |

---

## Circuit Challenge - Puzzle Generation Algorithm

### Overview

The algorithm uses a **"connectors first"** approach:

1. Generate solution path from START (0,0) to FINISH (rows-1, cols-1)
2. Set diagonal directions for each 2×2 cell group
3. Build connector graph (horizontal, vertical, diagonal)
4. Assign unique connector values per cell
5. Set cell answers to match their exit connectors
6. Generate arithmetic expressions for each answer
7. Validate the complete puzzle

### Key Files

- `generator.ts` - Main orchestration
- `pathfinder.ts` - Solution path generation with diagonal commitment tracking
- `expressions.ts` - Arithmetic expression generation with operation weights
- `difficulty.ts` - 10 preset levels + custom settings schema

### Validation Requirements

Every generated puzzle must pass:
1. Valid path from START to FINISH
2. All connector values unique per cell
3. Exactly one matching connector per cell (except FINISH)
4. All expressions evaluate correctly
5. Solution path is arithmetically valid

---

## Grid & Cell Rendering

### Hexagon Construction

Cells are **3D "poker chip" style** hexagons rendered in SVG:

```
Layers (bottom to top):
1. Shadow (translate 4, 14)
2. Edge (translate 0, 12) 
3. Base (translate 0, 6)
4. Top face (translate 0, 0)
5. Inner shadow
6. Rim highlight
```

Total depth: ~12px visible edge

### Cell States

| State | Gradient | Border | Effect |
|-------|----------|--------|--------|
| Normal | #3a3a4a → #252530 | #4a4a5a | None |
| Start | #15803d → #0d5025 | #00ff88 | Subtle glow |
| Finish | #ca8a04 → #854d0e | #ffcc00 | Subtle glow |
| Current | #0d9488 → #086560 | #00ffcc | Pulsing (1.5s) |
| Visited | #1a5c38 → #103822 | #00ff88 | Pulsing (2s) |

### Connector Animation (Traversed)

Multi-layer electric flow effect:
1. Glow layer (18px, #00ff88, 50% opacity, blur)
2. Main line (10px, #00dd77)
3. Energy 2 (6px, #88ffcc, dash 6 30, 1.2s flow)
4. Energy 1 (4px, #ffffff, dash 4 20, 0.8s flow)
5. Core (3px, #aaffcc)

---

## Colour Palette

### Hub (from 04_HUB_UI_UX.md)

| Element | Hex |
|---------|-----|
| Background dark | #0f0f23 |
| Background mid | #1a1a3e |
| Accent primary (success) | #22c55e |
| Accent secondary | #e94560 |
| Accent tertiary (coins) | #fbbf24 |
| Text primary | #ffffff |
| Text secondary | #a1a1aa |
| Error | #ef4444 |

### Circuit Challenge additions

| Element | Hex |
|---------|-----|
| Grid background | #0a0a12 → #0d0d18 |
| Connector default | #3d3428 |
| Connector active | #00dd77 |
| Connector glow | #00ff88 |
| Hearts active | #ff3366 |
| Hearts inactive | #2a2a3a |

---

## Database Schema Summary

### Core Tables

```sql
-- families: family units
-- users: parents + children (role, coins, pin_hash)
-- avatar_items: reference data (V3)
-- avatar_configs: user avatar state (V3)
-- avatar_purchases: owned items (V3)
-- coin_transactions: audit trail (V3)
-- progression_levels: level completion data
-- module_progress: JSONB for quick play stats
-- activity_log: session tracking
-- user_settings: preferences
```

### Key RLS Rules

- Users read their own data
- Parents read their children's data
- Children cannot access other children

### Sync Merge Rules

| Data | Rule |
|------|------|
| coins | Higher wins |
| stars | Higher wins |
| best_time_ms | Lower wins (faster) |
| completed | True wins |
| first_completed_at | Earliest wins |
| attempts | Higher wins |
| avatar_config | Last-write-wins |
| purchases | Union |

---

## Module Interface

Every puzzle module implements:

```typescript
interface PuzzleModule {
  id: string;                    // "circuit-challenge"
  name: string;                  // "Circuit Challenge"
  description: string;
  icon: string;
  
  init(hub: HubServices): void;
  destroy(): void;
  renderMenu(): Component;
  renderGame(config: GameConfig): Component;
  getProgressSummary(userId: string): ModuleProgress;
}

interface HubServices {
  auth: AuthService;
  coins: CoinService;      // V3 stub
  storage: StorageService;
  avatar: AvatarService;   // V3 stub
  sound: SoundService;     // V1 stretch
}
```

---

## Testing Strategy

### Unit Tests (Vitest)

Priority order:
1. Puzzle generation algorithm
2. Expression generation
3. Path validation
4. Difficulty settings

### Integration Tests

1. Complete game flow (Quick Play)
2. Guest → account transfer
3. Parent dashboard data display

### Property-Based Tests

Generate 1000+ random puzzles per difficulty level and verify:
- All pass validation
- Generation time < 200ms
- Solution paths are unique

---

## Build Order

### Phase 1: Foundation
1. Project setup (Vite + React + TS + Tailwind)
2. Design system components (Button, Card, Modal, etc.)
3. Theme and colour palette
4. Basic routing structure

### Phase 2: Hub Shell
1. Splash screen
2. Guest mode with IndexedDB
3. Main hub screen (no coins/avatar yet)
4. Settings screen

### Phase 3: Circuit Challenge Engine
1. Difficulty settings schema
2. Path generation algorithm
3. Connector value assignment
4. Expression generation
5. Puzzle validation
6. Unit tests for engine

### Phase 4: Circuit Challenge UI
1. Hexagon cell component
2. Connector component with animation
3. Puzzle grid composition
4. Game screen with lives/timer
5. Summary screen
6. Quick Play setup screen

### Phase 5: Game Features
1. Standard mode gameplay
2. Hidden mode gameplay
3. Reset / New Puzzle buttons
4. View Solution after game over
5. Print current puzzle

### Phase 6: Authentication
1. Supabase project setup
2. Database migrations
3. Parent signup/login
4. Child PIN authentication
5. Family management

### Phase 7: Parent Features
1. Family select screen
2. Parent dashboard
3. Child detail view
4. Activity history
5. Parent demo mode

### Phase 8: Puzzle Maker & Polish
1. Puzzle Maker batch generation
2. Print template (2 per A4)
3. Responsive testing
4. Performance optimization

### Phase 9: Stretch Goals (if time)
1. Sound effects service
2. Sound assets

---

## API Reference

### Custom Endpoints (from 10_API_SPECIFICATION.md)

```
POST /api/v1/auth/child-login      # Verify PIN
POST /api/v1/auth/transfer-guest   # Migrate guest data
POST /api/v1/family/children       # Add child
PATCH /api/v1/family/children/:id  # Update child
DELETE /api/v1/family/children/:id # Soft delete
POST /api/v1/coins/earn            # Record coins (V3)
POST /api/v1/avatar/purchase/:id   # Buy item (V3)
POST /api/v1/progress/:mod/levels/:id # Record completion
POST /api/v1/activity/session      # Log session
POST /api/v1/sync                  # Bulk sync
GET /api/v1/parent/children        # Family overview
GET /api/v1/parent/children/:id/stats
GET /api/v1/parent/children/:id/activity
```

### Supabase Direct

Tables with direct RLS access:
- avatar_items (read all)
- avatar_configs (read/write own)
- progression_levels (read own + children)
- module_progress (read/write own)
- user_settings (read/write own)

---

## Reference Files

Visual prototypes for implementation reference:
- `docs/circuit-challenge-visual-v5.html` - Interactive visual prototype
- `docs/circuit-challenge-print-template.html` - Print template

---

## Known Constraints

1. **No LaTeX** - Print uses HTML/CSS only
2. **No monetisation** - This is a gift for Max
3. **Offline-first** - Core gameplay must work without internet
4. **V3 stubs required** - Coin/avatar architecture must be built in V1 even though UI is hidden
5. **Mobile-first** - Design for touch, enhance for desktop

---

## Success Criteria

The build is successful when:
1. Max can play Quick Play at any difficulty
2. Puzzles generate correctly every time
3. Print output is classroom-quality (2 per A4, pure B&W)
4. Parent can view child's play history
5. App works offline (guest mode)
6. Adding a second module requires only registering it

---

## Questions to Resolve During Build

If you encounter ambiguity, check documents in this order:
1. This CLAUDE.md
2. 01_PROJECT_OVERVIEW.md (key decisions table)
3. Specific domain doc (05-08 for Circuit Challenge)
4. Ask the user

When in doubt: **fun first, quality over speed**.

---

## Recent Changes (January 2025)

### Mobile Landscape Layout

Added optimized layout for mobile devices in landscape orientation:

**New files:**
- `src/shared/hooks/useOrientation.ts` - Hook to detect device orientation
  - `isLandscape`: true when width > height
  - `isMobileLandscape`: true when landscape AND height <= 500px
  - `isPortrait`: true when in portrait mode

**Layout changes (GameScreen.tsx):**
- Portrait/Desktop: Vertical stack (header → grid → action buttons)
- Mobile Landscape: Horizontal layout
  - Left panel: Back button + action buttons (vertical, centered)
  - Center: Puzzle grid (maximized, flex-1)
  - Right panel: Lives, timer, coins (vertical stack)

**Component updates:**
- `ActionButtons.tsx` - Added `vertical` prop for stacked layout, `onContinue`/`showContinue` for View Solution flow
- `LivesDisplay.tsx` - Added `vertical` prop for stacked hearts

**Tailwind config:**
- Added `landscape-mobile` variant: `@media (orientation: landscape) and (max-height: 500px)`

### Cell Text Visibility

Improved text readability on hex cells:
- All cell text renders as bright white (#ffffff) with fontWeight="900"
- FINISH cell text renders as gold (#ffdd44)
- Inline style override ensures fill color is applied

### Current Cell Electric Pulse Animation

Current and START cells now pulse with connector-matching energy flow effect:

**Animation layers (HexCell.tsx) - uses SVG `<path>` for proper dash animation:**
1. Glow layer - #00ff88, 18px stroke, 50% opacity with blur filter
2. Main line - #00dd77, 10px solid stroke
3. Energy flow slow - #88ffcc, 6px dashed (6 30), 1.2s animation
4. Energy flow fast - #ffffff, 4px dashed (4 20), 0.8s animation
5. Bright core - #aaffcc, 3px solid stroke

**Key implementation details:**
- Uses `getHexagonPath()` to generate SVG path (not polygon) for proper stroke-dashoffset animation
- `strokeLinecap="round"` and `strokeLinejoin="round"` for smooth flowing dots
- Matches Connector component style exactly

**CSS classes used (animations.css):**
- `.cell-current` - Drop shadow pulse effect on the cell group
- `.connector-glow` - Opacity pulse (0.5 → 0.8)
- `.energy-flow-slow` - Dash offset animation at 1.2s
- `.energy-flow-fast` - Dash offset animation at 0.8s

**Trigger condition:**
```typescript
const isPulsing = state === 'current' || state === 'start'
```

### View Solution Feature

Complete View Solution implementation:

**PuzzleGrid.tsx:**
- `showSolution` prop controls solution path visibility
- `isConnectorOnSolutionPath()` helper identifies solution connectors
- Solution path connectors highlight when View Solution is activated
- Traversal direction correctly follows solution path order

**GameScreen.tsx:**
- Auto-navigation to summary prevented while `state.showingSolution` is true
- User stays on game screen to view the solution path
- Continue button appears to proceed to summary when ready

**ActionButtons.tsx:**
- Added `onContinue` and `showContinue` props
- Continue button (➡️) shown when viewing solution
- Allows user to proceed to summary after viewing solution

### Animation System (animations.css)

Complete animation definitions:

| Animation | Duration | Effect |
|-----------|----------|--------|
| `electricFlow` | 0.8s / 1.2s | Stroke dash offset for energy flow |
| `connectorPulse` | 1.5s | Opacity pulse 0.5 → 0.8 |
| `cellPulse` | 1s | Drop shadow intensity surge |
| `strokePulse` | 1s | Stroke width/opacity pulse |
| `visitedPulse` | 2s | Subtle glow on visited cells |
| `heartPulse` | 1.2s | Scale pulse for hearts |
| `heartBreak` | 0.5s | Break animation when life lost |
| `floatUp/Down` | 0.8s | Coin floating animation |
| `screenShake` | 0.3s | Wrong answer feedback |
| `twinkle` | 4s (var) | Background star effect |

### SVG Filter Definitions (GridDefs.tsx)

Required filters for effects:
- `cc-connectorGlowFilter` - Gaussian blur for glow effects
- `cc-cellShadowFilter` - Drop shadow for 3D cell effect

### Story Mode with Chapter Aliens

Added complete Story Mode with 10 unique chapter aliens and level progression:

**Chapter Aliens (`src/shared/types/chapterAlien.ts`, `ios-app/.../ChapterAlien.swift`):**

| Chapter | Alien Name | Color Theme |
|---------|------------|-------------|
| 1 | Zix | Green |
| 2 | Blurp | Blue |
| 3 | Quasar | Purple |
| 4 | Nimbus | Cyan |
| 5 | Flare | Orange |
| 6 | Echo | Pink |
| 7 | Cosmo | Indigo |
| 8 | Nova | Red |
| 9 | Stellar | Gold |
| 10 | Nebula | Rainbow |

**Story Mode Screens:**
- `ChapterSelect` - 3D carousel chapter selection
- `LevelSelect` - Horizontal level hexagon layout
- `StoryGameScreen` - Level intro + game wrapper

**Story Difficulty (`storyDifficulty.ts`, `StoryDifficulty.swift`):**
- Maps chapter/level to difficulty settings
- 5 levels per chapter (A-E)
- Progressive difficulty within chapters

### 3D Carousel Chapter Selection

Chapter select uses a 3D sphere-like carousel with swipe gestures:

**Web (ChapterSelect.tsx):**
```tsx
const angle = offset * 35  // degrees of rotation per card
const scale = Math.max(0.6, 1 - absOffset * 0.15)
style={{ transform: `translateX(${xOffset}px) scale(${scale}) rotateY(${angle}deg)` }}
```

**iOS (ChapterSelectView.swift):**
```swift
.rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
```

**Features:**
- Large cards (~70% viewport width, 60% height)
- Swipe left/right with spring animations
- Cards scale down and rotate away from center
- Touch anywhere to dismiss to level select

### Horizontal Level Selection with Glow Effects

Level selection displays hexagons horizontally with animated connectors:

**Current Level Detection:**
```typescript
// First unlocked but not completed level
const isCurrentLevel = (level: number): boolean => {
  if (!isLevelUnlocked(level)) return false
  if (isLevelCompleted(chapter, level, progress)) return false
  // Check all previous levels completed
  return allPreviousCompleted
}
```

**Glow Animation (current/completed levels):**
- Green pulsing glow (#00ff88)
- Animated dashed stroke connectors
- CSS animations: `dash`, `flowRight`, `flowDown`

### Level Intro Overlay

Before each story level, an overlay shows the chapter alien with a speech bubble:

**Web (StoryGameScreen.tsx):**
- Alien image with speech bubble
- Random intro messages: "Let's solve Level X-Y!"
- Auto-dismisses after 2.5s or tap to start
- `skipIntro` state preserves when returning from summary

**iOS (LevelSelectView.swift - StoryGameScreenView):**
- Same overlay pattern in SwiftUI
- Uses `@State var showIntro` with animation

### Alien Appearances on Win/Lose Screens

Story mode shows the chapter alien on summary screens:

**Character Reveal Animation:**
- Shows before main results
- Alien image with speech bubble
- Random win messages: "Amazing work! You did it!"
- Random lose messages: "Don't give up! Try again!"
- Auto-dismisses after 2 seconds or tap

**Result Cards:**
- Win: Shows alien image instead of 🎉 emoji
- Lose: Shows alien image instead of 💔 emoji
- Hidden mode: Shows alien at top of results

**Speech Bubble Messages:**
```typescript
const winMessages = [
  "Amazing work! You did it!",
  "Fantastic! You're a star!",
  "Woohoo! Great job!",
  "You're incredible!",
  "That was awesome!",
]

const loseMessages = [
  "Don't give up! Try again!",
  "You've got this! One more try!",
  "Almost there! Keep going!",
  "You're doing great! Try again!",
  "Practice makes perfect!",
]
```

### Music Toggle Button

Added music control to menu and game screens:

**Web (MusicToggleButton.tsx):**
```tsx
export function MusicToggleButton({ size = 'md' }) {
  const { isMuted, toggleMute } = useSound()
  return <button onClick={toggleMute}>{isMuted ? '🔇' : '🎵'}</button>
}
```

**iOS (MusicToggleButton.swift):**
```swift
struct MusicToggleButton: View {
  @ObservedObject private var storage = StorageService.shared
  @EnvironmentObject var musicService: MusicService
  // Shows music.note or speaker.slash.fill
}
```

**Placement:**
- ModuleMenu: Top-right corner
- GameScreen: In header (portrait) or left panel (landscape)

### Music Service (iOS)

Complete music service for background audio:

**MusicService.swift:**
```swift
enum MusicTrack: String {
  case hub = "hub_music"
  case game = "game_music"
  case victory = "victory_music"
  case lose = "lose_music"
}

class MusicService: ObservableObject {
  func play(track: MusicTrack, loop: Bool = true)
  func stop()
  func fadeOut(duration: TimeInterval)
}
```

**Audio Files (ios-app/MaxPuzzles/Resources/Sounds/):**
- `hub_music.m4a` - Main menu background
- `game_music.m4a` - Gameplay loop
- `victory_music.m4a` - Win celebration
- `lose_music.wav` - Game over sting

### Story Mode Routes

**Web routes (routes.tsx):**
```tsx
/play/circuit-challenge/story           → ChapterSelect
/play/circuit-challenge/story/:chapterId → LevelSelect
/play/circuit-challenge/story/:chapterId/:levelId → StoryGameScreen
```

**iOS navigation (AppRouter.swift):**
- Uses NavigationStack with destination routing
- Story data flows through GameScreenView props

### Supporting Models and Services

**iOS New Files:**
- `StorageService.swift` - UserDefaults persistence
- `MusicService.swift` - Background audio playback
- `FeedbackManager.swift` - Haptic/shake feedback
- `GameViewModel.swift` - Game state management
- `GameState.swift` / `GameAction.swift` - State types
- `SummaryData.swift` - Summary screen data model
- `OrientationManager.swift` - Device orientation
- `AnimatedCharacter.swift` - Character animations
- `ConfettiView.swift` - Win celebration effects
- `Print/` - PDF generation for Puzzle Maker

---

*End of CLAUDE.md*
