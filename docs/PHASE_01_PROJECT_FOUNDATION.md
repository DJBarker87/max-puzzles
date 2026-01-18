# Phase 1: Project Foundation

**Goal:** Set up the project scaffolding with Vite, React, TypeScript, Tailwind, and establish the folder structure and design system.

---

## Subphase 1.1: Project Initialization

### Prompt for Claude Code:

```
Create a new Vite project for Max's Puzzles with the following specifications:

1. Initialize with: npm create vite@latest max-puzzles -- --template react-ts

2. Install core dependencies:
   - tailwindcss, postcss, autoprefixer
   - @supabase/supabase-js (for later)
   - idb (IndexedDB wrapper)
   - uuid
   - react-router-dom

3. Install dev dependencies:
   - vitest, @testing-library/react, @testing-library/jest-dom
   - @types/uuid

4. Initialize Tailwind CSS with: npx tailwindcss init -p

5. Update package.json scripts to include:
   - "test": "vitest"
   - "test:ui": "vitest --ui"

After setup, verify the dev server runs with npm run dev.
```

---

## Subphase 1.2: Tailwind Theme Configuration

### Prompt for Claude Code:

```
Configure Tailwind CSS for Max's Puzzles with the custom theme.

Update tailwind.config.js with:

1. Content paths: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"]

2. Extended theme colors:
   - background: { dark: '#0f0f23', mid: '#1a1a3e', light: '#252550' }
   - accent: { 
       primary: '#22c55e',      // Cosmic green (success)
       secondary: '#e94560',    // Nebula pink (buttons)
       tertiary: '#fbbf24'      // Star gold (coins)
     }
   - circuit: {
       cell: { normal: '#3a3a4a', edge: '#1a1a25' },
       start: '#15803d',
       finish: '#ca8a04', 
       current: '#0d9488',
       visited: '#1a5c38',
       connector: { default: '#3d3428', active: '#00dd77', glow: '#00ff88' }
     }
   - text: { primary: '#ffffff', secondary: '#a1a1aa' }
   - error: '#ef4444'
   - hearts: { active: '#ff3366', inactive: '#2a2a3a' }

3. Extended fontFamily:
   - display: ['Nunito', 'Quicksand', 'sans-serif']
   - body: ['Inter', 'system-ui', 'sans-serif']

4. Update src/index.css with:
   - Tailwind directives (@tailwind base, components, utilities)
   - Import Google Fonts: Nunito (400,600,700,800) and Inter (400,500,600,700)
   - Base styles for body: bg-background-dark, text-text-primary, font-body
   - CSS custom properties for the color values (for use in SVG gradients)

5. Add custom animation keyframes in tailwind config:
   - pulse-glow: opacity/scale pulsing for cells
   - electric-flow: dash offset animation for connectors
   - twinkle: star twinkling effect
   - heart-pulse: beating heart animation
```

---

## Subphase 1.3: Folder Structure Setup

### Prompt for Claude Code:

```
Create the complete folder structure for Max's Puzzles following the hub-and-spoke architecture.

Create these directories and placeholder index.ts files:

src/
├── app/
│   ├── App.tsx                    # Main app component with router
│   ├── routes.tsx                 # Route definitions
│   └── providers/
│       ├── index.ts               # Re-export all providers
│       ├── AuthProvider.tsx       # Stub: { user: null, isGuest: true }
│       ├── StorageProvider.tsx    # IndexedDB provider
│       └── SoundProvider.tsx      # Stub: { playSound: () => {} }
│
├── hub/
│   ├── screens/
│   │   ├── index.ts
│   │   ├── SplashScreen.tsx       # Placeholder
│   │   ├── LoginScreen.tsx        # Placeholder
│   │   ├── MainHubScreen.tsx      # Placeholder
│   │   └── SettingsScreen.tsx     # Placeholder
│   └── components/
│       ├── index.ts
│       ├── Header.tsx             # Placeholder
│       └── CoinDisplay.tsx        # Placeholder
│
├── modules/
│   └── circuit-challenge/
│       ├── index.ts               # Module registration
│       ├── types.ts               # Module-specific types
│       ├── screens/
│       │   ├── index.ts
│       │   ├── ModuleMenu.tsx     # Placeholder
│       │   ├── QuickPlaySetup.tsx # Placeholder
│       │   ├── GameScreen.tsx     # Placeholder
│       │   └── SummaryScreen.tsx  # Placeholder
│       ├── components/
│       │   └── index.ts
│       ├── engine/
│       │   ├── index.ts
│       │   ├── types.ts           # Engine types
│       │   ├── generator.ts       # Placeholder
│       │   ├── difficulty.ts      # Placeholder
│       │   └── expressions.ts     # Placeholder
│       ├── hooks/
│       │   └── index.ts
│       └── print/
│           └── index.ts
│
├── shared/
│   ├── services/
│   │   ├── index.ts
│   │   ├── storage.ts             # IndexedDB service
│   │   └── sound.ts               # Sound service stub
│   ├── hooks/
│   │   ├── index.ts
│   │   └── useStorage.ts
│   ├── types/
│   │   ├── index.ts
│   │   ├── auth.ts
│   │   └── module.ts              # PuzzleModule interface
│   └── utils/
│       ├── index.ts
│       └── formatters.ts
│
├── ui/
│   ├── index.ts                   # Re-export all UI components
│   ├── Button.tsx
│   ├── Card.tsx
│   ├── Modal.tsx
│   ├── Toggle.tsx
│   ├── Slider.tsx
│   └── animations/
│       └── index.ts
│
└── styles/
    ├── globals.css                # Already created
    └── theme.ts                   # Theme constants export

Each placeholder file should have a minimal implementation:
- Components: export a div with the component name
- Types files: export empty interfaces with TODO comments
- Index files: re-export from the directory

Also create a src/vite-env.d.ts if not present.
```

---

## Subphase 1.4: Core Type Definitions

### Prompt for Claude Code:

```
Create the core TypeScript type definitions for Max's Puzzles.

1. src/shared/types/auth.ts:
   - User interface: { id, familyId?, email?, displayName, role: 'parent' | 'child', coins, isActive }
   - Family interface: { id, name, createdAt }
   - AuthState interface: { user: User | null, isGuest: boolean, isLoading: boolean }
   - ChildSession interface: { childId, displayName, familyId }

2. src/shared/types/module.ts:
   - PuzzleModule interface:
     {
       id: string;
       name: string;
       description: string;
       icon: string;
       init(hub: HubServices): void;
       destroy(): void;
       renderMenu(): React.ComponentType;
       renderGame(config: GameConfig): React.ComponentType;
       getProgressSummary(userId: string): ModuleProgress;
     }
   - HubServices interface: { auth, coins, storage, avatar, sound }
   - ModuleProgress interface: { totalLevels, completedLevels, totalStars, earnedStars, lastPlayed }
   - GameConfig interface: { difficulty, mode: 'quickplay' | 'progression', levelId? }

3. src/modules/circuit-challenge/types.ts:
   - Coordinate: { row: number, col: number }
   - Cell: { row, col, expression, answer: number | null, isStart, isFinish }
   - DiagonalDirection: 'DR' | 'DL'
   - Diagonal: { direction: DiagonalDirection, value: number }
   - ConnectorType: 'horizontal' | 'vertical' | 'diagonal'
   - Connector: { type, cellA: Coordinate, cellB: Coordinate, value: number, direction?: DiagonalDirection }
   - CellState: 'normal' | 'start' | 'finish' | 'current' | 'visited' | 'wrong'
   - GameMode: 'standard' | 'hidden'
   - Puzzle: { id, difficulty, grid: Cell[][], connectors: Connector[], solution: { path: Coordinate[], steps: number } }

4. src/modules/circuit-challenge/engine/types.ts:
   - DifficultySettings interface:
     {
       name: string;
       additionEnabled: boolean;
       subtractionEnabled: boolean;
       multiplicationEnabled: boolean;
       divisionEnabled: boolean;
       addSubRange: number;
       multDivRange: number;
       connectorMin: number;
       connectorMax: number;
       gridRows: number;
       gridCols: number;
       minPathLength: number;
       maxPathLength: number;
       weights: { addition, subtraction, multiplication, division: number };
       hiddenMode: boolean;
       secondsPerStep: number;
     }
   - GenerationResult: { success: true, puzzle: Puzzle } | { success: false, error: string }
   - Operation: '+' | '−' | '×' | '÷'

Ensure all types are properly exported and have JSDoc comments explaining their purpose.
```

---

## Subphase 1.5: Design System Components

### Prompt for Claude Code:

```
Create the core UI design system components for Max's Puzzles. These should be child-friendly with large touch targets and playful styling.

1. src/ui/Button.tsx:
   - Props: variant ('primary' | 'secondary' | 'ghost'), size ('sm' | 'md' | 'lg'), disabled, loading, fullWidth, children, onClick
   - Primary: bg-accent-primary with hover glow effect
   - Secondary: bg-accent-secondary (nebula pink)
   - Ghost: transparent with border
   - Minimum touch target: 44px height
   - Scale-down animation on press (0.95)
   - Loading state shows spinner
   - Rounded-xl corners, font-display font-bold

2. src/ui/Card.tsx:
   - Props: variant ('default' | 'elevated' | 'interactive'), padding ('sm' | 'md' | 'lg'), children, onClick, className
   - Default: bg-background-mid with subtle border
   - Elevated: adds shadow and slight transform
   - Interactive: hover lift effect, cursor-pointer
   - Rounded-2xl corners

3. src/ui/Modal.tsx:
   - Props: isOpen, onClose, title, children, size ('sm' | 'md' | 'lg')
   - Backdrop with blur effect and click-to-close
   - Centered card with slide-up animation
   - Close button (X) in top-right
   - Title with font-display
   - Proper focus trap and escape key handling

4. src/ui/Toggle.tsx:
   - Props: checked, onChange, label, disabled
   - Large toggle switch (child-friendly)
   - Green when on, grey when off
   - Smooth sliding animation
   - Label to the left of toggle

5. src/ui/Slider.tsx:
   - Props: min, max, value, onChange, label, showValue, step
   - Large thumb (24px) for easy touch
   - Track shows filled portion in accent-primary
   - Optional value display
   - Label above slider

6. src/ui/index.ts:
   - Re-export all components

Style notes:
- Use Tailwind classes exclusively
- All interactive elements need focus-visible states
- Include transition-all for smooth interactions
- Use the theme colors from tailwind config
```

---

## Subphase 1.6: App Shell & Basic Routing

### Prompt for Claude Code:

```
Set up the main App shell with routing and providers for Max's Puzzles.

1. src/app/providers/AuthProvider.tsx:
   - Create AuthContext with: user, isGuest, isLoading, login, logout, setGuestMode
   - Initial state: { user: null, isGuest: true, isLoading: false }
   - Stub implementations for login/logout (just console.log for now)
   - Export useAuth hook

2. src/app/providers/StorageProvider.tsx:
   - Create StorageContext
   - Placeholder that will connect to IndexedDB service
   - Methods: save, load, clear (all return Promises)
   - Export useStorageContext hook

3. src/app/providers/SoundProvider.tsx:
   - Create SoundContext with: playSound, isMuted, toggleMute
   - Stub implementation (playSound just logs)
   - Export useSound hook

4. src/app/providers/index.ts:
   - Create AppProviders component that wraps children with all providers in correct order
   - Export individual providers and hooks

5. src/app/routes.tsx:
   - Define routes using react-router-dom:
     - "/" -> SplashScreen
     - "/hub" -> MainHubScreen
     - "/login" -> LoginScreen
     - "/settings" -> SettingsScreen
     - "/play/circuit-challenge" -> ModuleMenu
     - "/play/circuit-challenge/quick" -> QuickPlaySetup
     - "/play/circuit-challenge/game" -> GameScreen
   - Export router configuration

6. src/app/App.tsx:
   - Import and use RouterProvider with the routes
   - Wrap everything in AppProviders
   - Add a simple error boundary

7. src/main.tsx:
   - Update to render App component
   - Ensure StrictMode is enabled

8. Update index.html:
   - Title: "Max's Puzzles"
   - Add meta description
   - Add theme-color meta tag (#0f0f23)
   - Add favicon placeholder comment

Test that the app runs and navigating to different routes shows the placeholder components.
```

---

## Phase 1 Completion Checklist

After completing all subphases, verify:

- [ ] `npm run dev` starts without errors
- [ ] All routes are accessible and show placeholder content
- [ ] Tailwind classes apply correctly (test a bg-accent-primary somewhere)
- [ ] TypeScript compiles without errors
- [ ] Folder structure matches the specification
- [ ] All design system components render correctly

---

## Files Created in This Phase

```
max-puzzles/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tailwind.config.js
├── postcss.config.js
├── index.html
├── src/
│   ├── main.tsx
│   ├── index.css
│   ├── vite-env.d.ts
│   ├── app/
│   │   ├── App.tsx
│   │   ├── routes.tsx
│   │   └── providers/
│   │       ├── index.ts
│   │       ├── AuthProvider.tsx
│   │       ├── StorageProvider.tsx
│   │       └── SoundProvider.tsx
│   ├── hub/
│   │   ├── screens/ (placeholders)
│   │   └── components/ (placeholders)
│   ├── modules/
│   │   └── circuit-challenge/
│   │       ├── index.ts
│   │       ├── types.ts
│   │       ├── screens/ (placeholders)
│   │       ├── components/
│   │       ├── engine/
│   │       │   ├── index.ts
│   │       │   └── types.ts
│   │       ├── hooks/
│   │       └── print/
│   ├── shared/
│   │   ├── services/
│   │   ├── hooks/
│   │   ├── types/
│   │   │   ├── auth.ts
│   │   │   └── module.ts
│   │   └── utils/
│   ├── ui/
│   │   ├── index.ts
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Modal.tsx
│   │   ├── Toggle.tsx
│   │   └── Slider.tsx
│   └── styles/
│       └── theme.ts
```

---

*End of Phase 1*
