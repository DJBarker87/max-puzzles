# Web File Reference for iOS Development

**Purpose:** Quick reference mapping iOS components to their web counterparts for implementation reference.

---

## Puzzle Engine (Port Directly)

| iOS File | Web Reference |
|----------|---------------|
| `Engine/PuzzleGenerator.swift` | `src/modules/circuit-challenge/engine/generator.ts` |
| `Engine/PathFinder.swift` | `src/modules/circuit-challenge/engine/pathfinder.ts` |
| `Engine/ExpressionGenerator.swift` | `src/modules/circuit-challenge/engine/expressions.ts` |
| `Engine/PuzzleValidator.swift` | `src/modules/circuit-challenge/engine/validator.ts` |
| `Engine/DifficultyPresets.swift` | `src/modules/circuit-challenge/engine/difficulty.ts` |

---

## UI Components

| iOS Component | Web Reference |
|---------------|---------------|
| `HexCellView.swift` | `src/modules/circuit-challenge/components/HexCell.tsx` |
| `ConnectorView.swift` | `src/modules/circuit-challenge/components/Connector.tsx` |
| `PuzzleGridView.swift` | `src/modules/circuit-challenge/components/PuzzleGrid.tsx` |
| `LivesDisplay.swift` | `src/modules/circuit-challenge/components/LivesDisplay.tsx` |
| `TimerDisplay.swift` | `src/modules/circuit-challenge/components/TimerDisplay.tsx` |
| `ActionButtons.swift` | `src/modules/circuit-challenge/components/ActionButtons.tsx` |

---

## Screens

| iOS View | Web Reference |
|----------|---------------|
| `GameView.swift` | `src/modules/circuit-challenge/screens/GameScreen.tsx` |
| `QuickPlaySetupView.swift` | `src/modules/circuit-challenge/screens/QuickPlaySetup.tsx` |
| `SummaryView.swift` | `src/modules/circuit-challenge/screens/SummaryScreen.tsx` |
| `ModuleMenuView.swift` | `src/modules/circuit-challenge/screens/ModuleMenu.tsx` |
| `PuzzleMakerView.swift` | `src/modules/circuit-challenge/screens/PuzzleMaker.tsx` |
| `MainHubView.swift` | `src/hub/screens/MainHubScreen.tsx` |
| `LoginView.swift` | `src/hub/screens/LoginScreen.tsx` |
| `FamilySelectView.swift` | `src/hub/screens/FamilySelectScreen.tsx` |
| `PINEntryView.swift` | `src/hub/screens/PinEntryScreen.tsx` |
| `SettingsView.swift` | `src/hub/screens/SettingsScreen.tsx` |
| `ParentDashboardView.swift` | `src/hub/screens/ParentDashboard/index.tsx` |

---

## Game Logic

| iOS File | Web Reference |
|----------|---------------|
| `GameViewModel.swift` | `src/modules/circuit-challenge/hooks/useGame.ts` |
| `PuzzleViewModel.swift` | `src/modules/circuit-challenge/hooks/usePuzzle.ts` |

---

## Services

| iOS Service | Web Reference |
|-------------|---------------|
| `AuthService.swift` | `src/shared/services/auth.ts` |
| `StorageService.swift` | `src/shared/services/storage.ts` |
| `SyncService.swift` | `src/shared/services/sync.ts` |
| `SoundService.swift` | `src/shared/services/sound.ts` |
| `CoinService.swift` | `src/shared/services/coins.ts` |

---

## Shared Utilities

| iOS File | Web Reference |
|----------|---------------|
| `Theme.swift` | `src/styles/theme.ts` |
| Orientation detection | `src/shared/hooks/useOrientation.ts` |

---

## Print Templates

| iOS File | Web Reference |
|----------|---------------|
| `PDFGenerator.swift` | `src/modules/circuit-challenge/print/generatePrintPuzzles.ts` |
| `PrintTemplateView.swift` | `src/modules/circuit-challenge/print/PrintTemplate.tsx` |

---

## Visual Prototypes (HTML Reference)

Open these in a browser to see exact styling:

- **Game Visual:** `specs/circuit-challenge-visual-v5.html`
- **Print Layout:** `specs/circuit-challenge-print-template.html`

---

## Key Specification Documents

| Topic | Document |
|-------|----------|
| Overall architecture | `specs/02_PLATFORM_ARCHITECTURE.md` |
| Shared systems | `specs/03_SHARED_SYSTEMS.md` |
| Hub UI/UX | `specs/04_HUB_UI_UX.md` |
| Game design | `specs/05_CIRCUIT_CHALLENGE_GAME_DESIGN.md` |
| Algorithm details | `specs/06_CIRCUIT_CHALLENGE_ALGORITHM.md` |
| Difficulty system | `specs/07_CIRCUIT_CHALLENGE_DIFFICULTY.md` |
| Game UI/UX | `specs/08_CIRCUIT_CHALLENGE_UI_UX.md` |
| Database schema | `specs/09_DATABASE_SCHEMA.md` |
| API spec | `specs/10_API_SPECIFICATION.md` |

---

## Recent Changes Log

Check `CLAUDE.md` "Recent Changes" section for latest updates to mirror.

Current changes (January 2025):
- Mobile landscape layout
- Cell text visibility improvements
- View Solution fix

---

*Use this as a quick lookup when implementing iOS features.*
