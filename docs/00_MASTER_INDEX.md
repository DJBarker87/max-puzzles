# Max's Puzzles - Master Build Index

**Complete build documentation for Max's Puzzles educational game platform.**

---

## Quick Reference

| Item | Value |
|------|-------|
| **Total Phases** | 13 documents |
| **Total Subphases** | ~95 |
| **Estimated Build Time** | 40-60 hours with Claude Code |
| **Target Platform** | Web (PWA), iOS-ready |
| **Tech Stack** | React 18, TypeScript, Vite, Tailwind, Supabase |

---

## Document Inventory

### Phase Documents

| File | Phase | Subphases | Description |
|------|-------|-----------|-------------|
| `PHASE_01_PROJECT_FOUNDATION.md` | 1 | 1.1-1.6 | Project setup, design system, folder structure |
| `PHASE_02_PUZZLE_ENGINE.md` | 2 | 2.1-2.8 | Connectors First algorithm, difficulty configs |
| `PHASE_03_UI_COMPONENTS.md` | 3 | 3.1-3.10 | HexCell, HexGrid, Connectors, animations |
| `PHASE_04_GAME_LOGIC_SCREENS.md` | 4 | 4.1-4.10 | useGame hook, GameScreen, results |
| `PHASE_05_HUB_SCREENS_NAVIGATION.md` | 5 | 5.1-5.10 | Splash, Login, Family, Hub screens |
| `PHASE_06_AUTH_STORAGE.md` | 6 | 6.1-6.10 | Supabase, IndexedDB, sync service |
| `PHASE_07_1_PARENT_DASHBOARD_OVERVIEW.md` | 7.1 | 7.1-7.4 | Dashboard types, service, overview |
| `PHASE_07_2_CHILD_DETAIL_CHARTS.md` | 7.2 | 7.5-7.7 | Child stats, charts, activity history |
| `PHASE_07_3_CHILD_MANAGEMENT_SETTINGS.md` | 7.3 | 7.8-7.10 | Add/Edit child, Reset PIN, Settings |
| `PHASE_08_PRINT_PUZZLE_MAKER.md` | 8 | 8.1-8.8 | SVG renderer, PDF export, Puzzle Maker |
| `PHASE_09_POLISH_PWA_DEPLOYMENT.md` | 9 | 9.1-9.10 | PWA, performance, Vercel deployment |
| `PHASE_10_1_TESTING_SETUP_CORE.md` | 10.1 | 10.1-10.3 | Vitest setup, engine tests, hook tests |
| `PHASE_10_2_TESTING_UI_INTEGRATION.md` | 10.2 | 10.4-10.8 | UI tests, integration, accessibility |

---

## Build Order

Execute phases in this order. Each phase depends on previous phases.

```
Phase 1: Project Foundation
    ↓
Phase 2: Puzzle Engine
    ↓
Phase 3: UI Components
    ↓
Phase 4: Game Logic & Screens
    ↓
Phase 5: Hub Screens & Navigation
    ↓
Phase 6: Authentication & Storage
    ↓
Phase 7.1 → 7.2 → 7.3: Parent Dashboard
    ↓
Phase 8: Print & Puzzle Maker
    ↓
Phase 9: Polish, PWA & Deployment
    ↓
Phase 10.1 → 10.2: Testing Suite
```

---

## Dependencies by Phase

### Phase 1: Project Foundation
```bash
# Core
npm create vite@latest max-puzzles -- --template react-ts
npm install react-router-dom

# Styling
npm install -D tailwindcss postcss autoprefixer
npm install clsx tailwind-merge

# Icons (optional)
npm install lucide-react
```

### Phase 2: Puzzle Engine
```
No additional dependencies
(Pure TypeScript algorithms)
```

### Phase 3: UI Components
```
No additional dependencies
(Uses Tailwind from Phase 1)
```

### Phase 4: Game Logic & Screens
```
No additional dependencies
```

### Phase 5: Hub Screens & Navigation
```
No additional dependencies
```

### Phase 6: Authentication & Storage
```bash
npm install @supabase/supabase-js
npm install idb
```

### Phase 7: Parent Dashboard
```
No additional dependencies
```

### Phase 8: Print & Puzzle Maker
```bash
npm install jspdf svg2pdf.js
```

### Phase 9: PWA & Deployment
```bash
npm install -D vite-plugin-pwa
```

### Phase 10: Testing
```bash
npm install -D vitest @vitest/coverage-v8 @vitest/ui
npm install -D @testing-library/react @testing-library/jest-dom @testing-library/user-event
npm install -D jsdom msw @faker-js/faker
npm install -D vitest-axe
```

### All Dependencies (package.json)
```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "@supabase/supabase-js": "^2.38.0",
    "idb": "^7.1.1",
    "jspdf": "^2.5.1",
    "svg2pdf.js": "^2.2.3",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0",
    "lucide-react": "^0.294.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.2.0",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31",
    "tailwindcss": "^3.3.5",
    "typescript": "^5.2.2",
    "vite": "^5.0.0",
    "vite-plugin-pwa": "^0.17.0",
    "vitest": "^1.0.0",
    "@vitest/coverage-v8": "^1.0.0",
    "@vitest/ui": "^1.0.0",
    "@testing-library/react": "^14.1.0",
    "@testing-library/jest-dom": "^6.1.0",
    "@testing-library/user-event": "^14.5.0",
    "jsdom": "^23.0.0",
    "msw": "^2.0.0",
    "@faker-js/faker": "^8.3.0",
    "vitest-axe": "^0.1.0"
  }
}
```

---

## Final Project Structure

```
max-puzzles/
├── public/
│   ├── icons/                    # PWA icons (72-512px)
│   ├── apple-touch-icon.png
│   ├── favicon.ico
│   └── robots.txt
│
├── src/
│   ├── app/
│   │   ├── providers/
│   │   │   ├── AuthProvider.tsx
│   │   │   ├── SoundProvider.tsx
│   │   │   └── StorageProvider.tsx
│   │   ├── routes.tsx
│   │   └── App.tsx
│   │
│   ├── hub/
│   │   ├── components/
│   │   │   ├── Header.tsx
│   │   │   ├── CoinDisplay.tsx
│   │   │   ├── PinEntryModal.tsx
│   │   │   ├── ChildSummaryCard.tsx
│   │   │   └── ActivityChart.tsx
│   │   ├── screens/
│   │   │   ├── SplashScreen.tsx
│   │   │   ├── LoginScreen.tsx
│   │   │   ├── FamilySelectScreen.tsx
│   │   │   ├── MainHubScreen.tsx
│   │   │   ├── ModuleSelectScreen.tsx
│   │   │   ├── SettingsScreen.tsx
│   │   │   ├── ParentDashboard.tsx
│   │   │   ├── ChildDetailScreen.tsx
│   │   │   ├── ActivityHistoryScreen.tsx
│   │   │   ├── AddChildScreen.tsx
│   │   │   ├── EditChildScreen.tsx
│   │   │   ├── ResetPinScreen.tsx
│   │   │   └── ParentSettingsScreen.tsx
│   │   └── types/
│   │       └── dashboard.ts
│   │
│   ├── modules/
│   │   └── circuit-challenge/
│   │       ├── components/
│   │       │   ├── HexCell.tsx
│   │       │   ├── HexGrid.tsx
│   │       │   ├── Connector.tsx
│   │       │   ├── GameHeader.tsx
│   │       │   ├── GameControls.tsx
│   │       │   ├── ResultsOverlay.tsx
│   │       │   └── PuzzlePreview.tsx
│   │       ├── engine/
│   │       │   ├── puzzleGenerator.ts
│   │       │   ├── pathValidation.ts
│   │       │   ├── difficultyConfig.ts
│   │       │   └── coinCalculator.ts
│   │       ├── hooks/
│   │       │   ├── useGame.ts
│   │       │   └── useGameTimer.ts
│   │       ├── screens/
│   │       │   ├── GameScreen.tsx
│   │       │   └── PuzzleMakerScreen.tsx
│   │       ├── services/
│   │       │   ├── printGenerator.ts
│   │       │   ├── svgRenderer.ts
│   │       │   └── pdfGenerator.ts
│   │       └── types/
│   │           ├── game.ts
│   │           └── print.ts
│   │
│   ├── shared/
│   │   ├── components/
│   │   │   ├── PWAUpdatePrompt.tsx
│   │   │   ├── OfflineBanner.tsx
│   │   │   ├── InstallPrompt.tsx
│   │   │   ├── LoadingScreen.tsx
│   │   │   ├── ErrorBoundary.tsx
│   │   │   └── GameErrorBoundary.tsx
│   │   ├── hooks/
│   │   │   ├── useOnlineStatus.ts
│   │   │   └── usePerformance.ts
│   │   ├── services/
│   │   │   ├── supabase.ts
│   │   │   ├── storage.ts
│   │   │   ├── auth.ts
│   │   │   ├── dashboard.ts
│   │   │   ├── sync.ts
│   │   │   └── analytics.ts
│   │   ├── utils/
│   │   │   ├── cn.ts
│   │   │   └── formatters.ts
│   │   └── config/
│   │       └── env.ts
│   │
│   ├── ui/
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Modal.tsx
│   │   ├── Input.tsx
│   │   ├── Toggle.tsx
│   │   └── index.ts
│   │
│   ├── test/
│   │   ├── setup.ts
│   │   ├── utils.tsx
│   │   ├── factories.ts
│   │   ├── a11y.ts
│   │   ├── mocks/
│   │   │   ├── server.ts
│   │   │   └── handlers.ts
│   │   ├── integration/
│   │   │   ├── gameplay.test.tsx
│   │   │   ├── authentication.test.tsx
│   │   │   └── parentDashboard.test.tsx
│   │   └── accessibility/
│   │       ├── screens.test.tsx
│   │       ├── components.test.tsx
│   │       └── keyboard.test.tsx
│   │
│   ├── main.tsx
│   └── vite-env.d.ts
│
├── supabase/
│   └── migrations/
│       └── 001_initial_schema.sql
│
├── .env.example
├── .env.development
├── .env.production
├── .gitignore
├── index.html
├── package.json
├── postcss.config.js
├── tailwind.config.js
├── tsconfig.json
├── vite.config.ts
├── vitest.config.ts
├── vercel.json
├── README.md
├── CHANGELOG.md
├── DEPLOYMENT.md
└── TESTING.md
```

---

## Database Schema (Supabase)

```sql
-- Users table (parents and children)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('parent', 'child')),
  display_name TEXT NOT NULL,
  pin_hash TEXT,
  coins INTEGER DEFAULT 0,
  family_id UUID REFERENCES families(id),
  parent_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Families table
CREATE TABLE families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Module progress
CREATE TABLE module_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  module_id TEXT NOT NULL,
  current_level INTEGER DEFAULT 0,
  highest_level INTEGER DEFAULT 0,
  total_stars INTEGER DEFAULT 0,
  progress_data JSONB DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, module_id)
);

-- Activity log
CREATE TABLE activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  module_id TEXT NOT NULL,
  session_start TIMESTAMPTZ NOT NULL,
  session_end TIMESTAMPTZ,
  games_played INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  mistakes INTEGER DEFAULT 0,
  coins_earned INTEGER DEFAULT 0,
  difficulty_played INTEGER[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Design Tokens

### Colors
```css
--background-dark: #0a0a1a
--background-mid: #12122a
--background-light: #1a1a3a
--text-primary: #ffffff
--text-secondary: #a0a0c0
--accent-primary: #00ff88 (green)
--accent-secondary: #ff6b6b (coral)
--accent-tertiary: #ffd93d (gold/coins)
--error: #ff4444
--success: #00ff88
```

### Typography
```css
--font-display: 'Nunito', system-ui, sans-serif
--font-body: 'Inter', system-ui, sans-serif
--font-mono: 'JetBrains Mono', monospace
```

### Spacing Scale
```
4px, 8px, 12px, 16px, 24px, 32px, 48px, 64px
```

### Border Radius
```
sm: 4px, md: 8px, lg: 12px, xl: 16px, full: 9999px
```

---

## Key Algorithms

### Connectors First Puzzle Generation
1. Create empty grid
2. Generate random path from start to end
3. Calculate target sum from path
4. Fill remaining cells with valid values
5. Validate puzzle is solvable

### Coin Calculation
```typescript
baseCoins = 10 + (difficulty * 5)
timeBonus = max(0, (60 - seconds) * 0.5)
accuracyMultiplier = mistakes === 0 ? 1.5 : 1.0
total = floor(baseCoins * accuracyMultiplier + timeBonus)
```

---

## Scripts Reference

```bash
# Development
npm run dev           # Start dev server
npm run build         # Production build
npm run preview       # Preview production build

# Testing
npm test              # Run tests in watch mode
npm run test:run      # Run tests once
npm run test:coverage # Run with coverage
npm run test:ui       # Open Vitest UI

# Code Quality
npm run lint          # ESLint
npm run type-check    # TypeScript check

# Deployment
vercel                # Deploy preview
vercel --prod         # Deploy production
```

---

## Environment Variables

```bash
# Required
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key

# Optional
VITE_ANALYTICS_ENABLED=false
VITE_APP_VERSION=1.0.0

# Feature Flags (V2+)
VITE_FEATURE_PROGRESSION_MODE=false
VITE_FEATURE_SHOP=false
VITE_FEATURE_AVATARS=false
```

---

## Version Roadmap

### V1 (This Build)
- ✅ Circuit Challenge game
- ✅ 10 difficulty levels
- ✅ Guest mode
- ✅ Family accounts
- ✅ Parent dashboard
- ✅ Printable worksheets
- ✅ PWA support

### V2 (Future)
- Progression mode (level unlocking)
- More puzzle modules
- Achievement system
- Custom avatars
- Sound effects
- Haptic feedback

### V3 (Future)
- Coin shop
- Multiplayer challenges
- Teacher accounts
- Class management
- Analytics dashboard

---

## Support Files Included

| File | Purpose |
|------|---------|
| `README.md` | Project overview |
| `CHANGELOG.md` | Version history |
| `DEPLOYMENT.md` | Deployment guide |
| `TESTING.md` | Testing guide |
| `vercel.json` | Vercel config |
| `.env.example` | Environment template |

---

## How to Use These Documents

### With Claude Code:

1. **Start a new Claude Code session**
2. **Upload the relevant phase document**
3. **Copy-paste each subphase prompt**
4. **Review and iterate on output**
5. **Move to next subphase**

### Tips:
- Complete phases in order
- Test each phase before moving on
- Keep the Master Index open for reference
- Use the project structure as your guide

---

## Checklist

### Setup
- [ ] Clone/create repository
- [ ] Install Phase 1 dependencies
- [ ] Configure Tailwind
- [ ] Set up folder structure

### Core Build
- [ ] Phase 1: Project Foundation
- [ ] Phase 2: Puzzle Engine
- [ ] Phase 3: UI Components
- [ ] Phase 4: Game Logic
- [ ] Phase 5: Hub Screens
- [ ] Phase 6: Auth & Storage

### Features
- [ ] Phase 7.1-7.3: Parent Dashboard
- [ ] Phase 8: Print & Puzzle Maker

### Polish
- [ ] Phase 9: PWA & Deployment
- [ ] Phase 10.1-10.2: Testing

### Launch
- [ ] Configure Supabase production
- [ ] Set environment variables
- [ ] Deploy to Vercel
- [ ] Test PWA installation
- [ ] Monitor for errors

---

*Last updated: January 2025*
*Total documentation: ~95 subphases across 13 phase documents*
