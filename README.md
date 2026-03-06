# Max's Puzzles

A fun, educational maths puzzle platform for children aged 5-11. Built as a gift for Max (age 6), this project features a **hub-and-spoke architecture** where a central hub provides shared services and independent puzzle modules plug into it. The first module is **Circuit Challenge** - a path-finding puzzle that reinforces mental arithmetic through engaging gameplay.

Available as a **responsive web app** (React + TypeScript) and a **native iOS app** (SwiftUI).

---

## Circuit Challenge

Players navigate from START to FINISH on a hexagonal grid by solving arithmetic problems. Each cell shows a calculation, and the answer tells you which connector to follow to the next cell.

**How it works:**
1. A cell shows a calculation like `5 + 8`
2. Solve it mentally (answer: 13)
3. Find the connector labelled `13` leading to an adjacent cell
4. Tap that cell to move forward
5. Reach FINISH to win

### Game Modes

| Mode | Description |
|------|-------------|
| **Quick Play** | Generate puzzles on-demand at any of 10 difficulty levels or with custom settings |
| **Story Mode** | 10 chapters with unique alien characters, 7 levels each, progressive difficulty |
| **Puzzle Maker** | Batch-generate up to 10 puzzles for printing (2 per A4, pure B&W) |
| **Hidden Mode** | No feedback during play - mistakes are only revealed at the end |

### Difficulty Levels

| Level | Name | Operations | Grid | Target Age |
|-------|------|------------|------|------------|
| 1 | Tiny Tot | + | 3x4 | 4-5 |
| 2 | Beginner | + | 4x4 | 5-6 |
| 3 | Easy | + - | 4x5 | 5-7 |
| 4 | Getting There | + - | 4x5 | 6-7 |
| 5 | Times Tables | + - x | 4x5 | 6-8 |
| 6 | Confident | + - x | 5x5 | 7-8 |
| 7 | Adventurous | + - x | 5x6 | 7-9 |
| 8 | Division Intro | + - x / | 5x6 | 8-9 |
| 9 | Challenge | + - x / | 6x7 | 8-10 |
| 10 | Expert | + - x / | 6x8 | 9-11 |

Custom difficulty allows full control over operations, number ranges, grid size, and Hidden Mode.

---

## Story Mode

10 chapters, each guided by a unique alien character with its own personality and colour theme:

| Chapter | Alien | Theme |
|---------|-------|-------|
| 1 | Bob | Green |
| 2 | Blink | Blue |
| 3 | Drift | Purple |
| 4 | Fuzz | Orange |
| 5 | Prism | Pink |
| 6 | Nova | Yellow |
| 7 | Clicker | Red |
| 8 | Bolt | Teal |
| 9 | Sage | Silver |
| 10 | Bibomic | Gold |

Each chapter has 7 levels with increasing difficulty. Aliens appear in level intros, win celebrations, and loss encouragement screens with personalised messages using the player's name.

**Star ratings:** 1 star for completion, 2 stars for no mistakes, 3 stars for speed + accuracy. Two stars unlock the next level.

---

## Features

### Gameplay
- 3D "poker chip" hexagonal cells with layered SVG rendering
- Electric flow animations on traversed connectors (5-layer glow effect)
- 5 lives system in standard mode with heart pulse animations
- Timer starts on first move
- View Solution reveals the full path after game over
- Reset puzzle or generate a new one at any time
- Confetti celebration on wins

### Parent Features
- Family accounts with Supabase authentication
- Child PIN login (4-digit)
- Parent dashboard with play statistics per child
- Activity history and progress tracking
- Parent demo mode (play without saving data)

### Print & Classroom
- Print any puzzle directly from the game
- Puzzle Maker generates batches of up to 10 puzzles
- 2 puzzles per A4 page, pure black & white
- Includes optional answer pages
- Client-side generation (no server needed)

### Technical
- Offline-first with IndexedDB persistence
- PWA support with auto-update
- Responsive design (mobile, tablet, desktop)
- Optimised mobile landscape layout
- Background music and sound effects with toggle
- Haptic feedback on iOS

---

## Tech Stack

### Web App

| Layer | Technology |
|-------|------------|
| Frontend | React 18, TypeScript |
| Styling | Tailwind CSS |
| State | React Context + useReducer, IndexedDB |
| Backend | Supabase (Auth, PostgreSQL) |
| Build | Vite |
| Testing | Vitest + React Testing Library |
| PWA | vite-plugin-pwa |

### iOS App

| Layer | Technology |
|-------|------------|
| UI | SwiftUI (iOS 16+) |
| Architecture | MVVM + Reducer pattern |
| Audio | AVFoundation, AVAudioEngine |
| Haptics | CoreHaptics, UIKit feedback generators |
| Print | UIGraphicsPDFRenderer |
| State | Combine, ObservableObject |

---

## Project Structure

```
max-puzzles/
├── src/                          # Web app source
│   ├── app/                      # Shell, routing, providers
│   ├── hub/                      # Hub screens (splash, login, dashboard)
│   ├── modules/circuit-challenge/ # Puzzle module
│   │   ├── engine/               # Generation algorithm
│   │   ├── components/           # HexCell, Connector, Grid
│   │   ├── screens/              # Game, Summary, Story Mode
│   │   ├── hooks/                # Game state management
│   │   └── services/             # PDF/print generation
│   ├── shared/                   # Auth, storage, sync services
│   ├── ui/                       # Design system components
│   └── styles/                   # Theme and animations
│
├── ios-app/                      # Native iOS app
│   └── MaxPuzzles/
│       ├── App/                  # Entry point, routing
│       ├── Core/                 # Models, services, theme
│       ├── Hub/                  # Hub views
│       ├── Modules/CircuitChallenge/
│       │   ├── Engine/           # Puzzle generation (Swift)
│       │   ├── Views/            # Game screens
│       │   ├── Components/       # Grid, cells, connectors
│       │   └── ViewModels/       # Game state
│       ├── Shared/               # Reusable UI components
│       └── Resources/            # Assets, sounds, fonts
│
├── specs/                        # Design specifications
├── docs/                         # Phase-by-phase build guides
├── supabase/                     # Database migrations
└── tests/                        # Web app tests
```

---

## Puzzle Generation Algorithm

The engine uses a **"connectors first"** approach to guarantee valid, solvable puzzles:

1. **Path generation** - Create a solution path from START (0,0) to FINISH (rows-1, cols-1)
2. **Diagonal assignment** - Set diagonal directions for each 2x2 cell group
3. **Connector graph** - Build all horizontal, vertical, and diagonal connectors
4. **Value assignment** - Assign unique connector values per cell
5. **Cell answers** - Set each cell's answer to match its exit connector
6. **Expression generation** - Create arithmetic expressions for each answer with configurable operation weights
7. **Validation** - Verify path validity, connector uniqueness, expression correctness, and solution path integrity

Puzzles retry up to 30 times on generation failure. Target performance is under 200ms per puzzle.

---

## Getting Started

### Web App

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test

# Build for production
npm run build
```

### iOS App

Open `ios-app/MaxPuzzles.xcodeproj` in Xcode 15+ and build for iOS 16+.

### Environment Variables

The web app uses Supabase for authentication and data sync. Create a `.env` file:

```
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_anon_key
```

Guest mode works entirely offline without Supabase configuration.

---

## Design

The app uses a dark space theme with vibrant accent colours:

- **Background:** Deep space blue (#0f0f23)
- **Success/Active:** Cosmic green (#22c55e)
- **Secondary:** Nebula pink (#e94560)
- **Coins/Gold:** Star gold (#fbbf24)
- **Connectors:** Electric green (#00ff88) with animated glow

Hexagonal cells are rendered as 3D poker chips with 6 SVG layers (shadow, edge, base, top face, inner shadow, rim highlight). Traversed connectors animate with a multi-layer electric flow effect.

---

## Architecture

The hub-and-spoke design means adding a new puzzle module requires:

1. Implement the `PuzzleModule` interface
2. Register the module with the hub
3. Add routes

The hub handles authentication, navigation, coin economy (V3), and parent features. Each module owns its own gameplay, difficulty system, and progression.

---

## Specifications

Detailed design documents are in the `/specs` directory:

| Document | Contents |
|----------|----------|
| 01 - Project Overview | Vision, scope, version plan |
| 02 - Platform Architecture | Hub/spoke design, module interface |
| 03 - Shared Systems | Accounts, coins, avatars, parent dashboard |
| 04 - Hub UI/UX | Hub screen specifications |
| 05 - Circuit Challenge Game Design | Core gameplay, modes, objectives |
| 06 - Circuit Challenge Algorithm | Puzzle generation algorithm details |
| 07 - Circuit Challenge Difficulty | 10 preset levels + progression levels |
| 08 - Circuit Challenge UI/UX | Grid rendering, animations, print output |
| 09 - Database Schema | Supabase schema with RLS policies |
| 10 - API Specification | Backend endpoint definitions |

Interactive prototypes can be opened in a browser:
- `specs/circuit-challenge-visual-v5.html` - Visual gameplay prototype
- `specs/circuit-challenge-print-template.html` - Print layout reference

---

## License

This is a personal project built as a gift. Not intended for commercial use.
