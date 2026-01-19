# Max's Puzzles - iOS App Planning Document

**Version:** 1.0
**Last Updated:** January 2025
**Purpose:** Comprehensive planning guide for building the native iOS version of Max's Puzzles

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Tech Stack Decisions](#tech-stack-decisions)
3. [Architecture Overview](#architecture-overview)
4. [Feature Parity Requirements](#feature-parity-requirements)
5. [Shared Logic & Code Reuse](#shared-logic--code-reuse)
6. [iOS-Specific Considerations](#ios-specific-considerations)
7. [Implementation Phases](#implementation-phases)
8. [Data & Storage](#data--storage)
9. [API Integration](#api-integration)
10. [Testing Strategy](#testing-strategy)
11. [App Store Requirements](#app-store-requirements)

---

## Project Overview

### What is Max's Puzzles?

A fun, educational maths puzzle platform for children aged 5-11, starting with Max (age 6). The platform uses a **hub-and-spoke architecture** where a central hub provides shared services (auth, coins, avatars) and independent puzzle modules plug into it.

### First Module: Circuit Challenge

A path-finding puzzle using arithmetic where players navigate from START to FINISH by solving calculations. Each cell contains an expression; the answer determines which connector to follow.

### Why Native iOS?

| Reason | Benefit |
|--------|---------|
| Performance | Smoother animations, especially for electric flow effects |
| Touch experience | Native gesture handling, haptic feedback |
| Offline support | Better CoreData/UserDefaults integration |
| App Store presence | Discoverability, trusted platform |
| Platform features | Widget support, Shortcuts integration (future) |

### Web App Status

The React web app serves as the primary reference implementation. The iOS app should achieve feature parity with V1 web functionality.

---

## Tech Stack Decisions

### Recommended Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **UI Framework** | SwiftUI | Modern, declarative, excellent animations |
| **State Management** | Swift Observation framework / @Observable | Native, performant |
| **Local Storage** | CoreData + UserDefaults | Offline-first, syncs well |
| **Backend** | Supabase Swift SDK | Same backend as web |
| **Networking** | Swift Concurrency (async/await) | Modern, clean error handling |
| **Testing** | XCTest + Swift Testing | Native, comprehensive |
| **Architecture** | MVVM | Clean separation, testable |

### Minimum iOS Version

**iOS 16.0+** recommended for:
- Modern SwiftUI features
- Charts framework
- Variable blur/materials
- Navigation improvements

Consider **iOS 17.0+** if acceptable:
- @Observable macro (simpler state)
- Improved animations
- Better SwiftUI performance

### Dependencies

| Package | Purpose | Source |
|---------|---------|--------|
| supabase-swift | Backend integration | SPM |
| KeychainAccess | Secure credential storage | SPM |

Keep dependencies minimal - prefer native APIs.

---

## Architecture Overview

### Hub-and-Spoke (Same as Web)

```
┌─────────────────────────────────────────────┐
│              MAX'S PUZZLES iOS              │
│                  (Hub)                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────────┐ │
│  │  Coins  │  │  Avatar │  │   Family    │ │
│  │ Service │  │ Service │  │  Accounts   │ │
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

### Project Structure

```
MaxPuzzles/
├── App/
│   ├── MaxPuzzlesApp.swift
│   ├── ContentView.swift
│   └── AppState.swift
│
├── Core/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Family.swift
│   │   ├── GameSession.swift
│   │   └── DifficultySettings.swift
│   │
│   ├── Services/
│   │   ├── AuthService.swift
│   │   ├── CoinService.swift          # V3 stub
│   │   ├── StorageService.swift
│   │   ├── SyncService.swift
│   │   └── SoundService.swift
│   │
│   └── Utilities/
│       ├── Theme.swift
│       └── Extensions/
│
├── Hub/
│   ├── Views/
│   │   ├── SplashView.swift
│   │   ├── LoginView.swift
│   │   ├── FamilySelectView.swift
│   │   ├── PINEntryView.swift
│   │   ├── MainHubView.swift
│   │   ├── SettingsView.swift
│   │   └── ParentDashboard/
│   │       ├── ParentDashboardView.swift
│   │       ├── ChildDetailView.swift
│   │       └── ActivityHistoryView.swift
│   │
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── FamilyViewModel.swift
│   │   └── DashboardViewModel.swift
│   │
│   └── Components/
│       ├── AvatarView.swift            # V3
│       ├── CoinDisplay.swift
│       └── ModuleCard.swift
│
├── Modules/
│   └── CircuitChallenge/
│       ├── Views/
│       │   ├── ModuleMenuView.swift
│       │   ├── QuickPlaySetupView.swift
│       │   ├── GameView.swift
│       │   ├── SummaryView.swift
│       │   └── PuzzleMakerView.swift
│       │
│       ├── ViewModels/
│       │   ├── GameViewModel.swift
│       │   ├── PuzzleViewModel.swift
│       │   └── DifficultyViewModel.swift
│       │
│       ├── Engine/
│       │   ├── PuzzleGenerator.swift
│       │   ├── PathFinder.swift
│       │   ├── ExpressionGenerator.swift
│       │   ├── PuzzleValidator.swift
│       │   └── DifficultyPresets.swift
│       │
│       ├── Components/
│       │   ├── PuzzleGridView.swift
│       │   ├── HexCellView.swift
│       │   ├── ConnectorView.swift
│       │   ├── LivesDisplay.swift
│       │   ├── TimerDisplay.swift
│       │   └── ActionButtons.swift
│       │
│       └── Print/
│           ├── PrintTemplateView.swift
│           └── PDFGenerator.swift
│
├── Shared/
│   ├── UI/
│   │   ├── PrimaryButton.swift
│   │   ├── SecondaryButton.swift
│   │   ├── CardView.swift
│   │   ├── ToggleStyle.swift
│   │   └── Animations/
│   │       ├── ConfettiView.swift
│   │       ├── CoinFloatView.swift
│   │       └── ShakeEffect.swift
│   │
│   └── Types/
│       ├── ModuleProtocol.swift
│       ├── Coordinate.swift
│       └── GameState.swift
│
├── Resources/
│   ├── Assets.xcassets
│   ├── Sounds/
│   └── Localizable.strings
│
└── Tests/
    ├── EngineTests/
    ├── ViewModelTests/
    └── IntegrationTests/
```

---

## Feature Parity Requirements

### V1 Must-Have Features

| Feature | Web | iOS | Notes |
|---------|-----|-----|-------|
| Quick Play mode | ✓ | Required | All difficulty settings |
| 10 preset difficulty levels | ✓ | Required | Plus custom |
| Hidden Mode toggle | ✓ | Required | No lives, reveal at end |
| 5 lives system | ✓ | Required | Standard mode only |
| Reset + New Puzzle buttons | ✓ | Required | Same puzzle / fresh |
| Print current puzzle | ✓ | Required | Use iOS print APIs |
| Puzzle Maker (batch) | ✓ | Required | Generate PDF |
| Guest mode | ✓ | Required | Local storage only |
| Family accounts | ✓ | Required | Supabase Auth |
| Parent dashboard | ✓ | Required | Play stats |
| Parent demo mode | ✓ | Required | Nothing tracked |
| Responsive layout | ✓ | Required | Portrait + landscape |
| Timer starts on first move | ✓ | Required | Any adjacent tap |

### V2 Features (Deferred)

- 30 progression levels
- Star ratings
- Level unlocking
- Tutorial hints
- Daily time limits

### V3 Features (Deferred)

- Coin economy UI
- Avatar system
- Shop

**Note:** Build V3 architecture now (stubs), expose later.

---

## Shared Logic & Code Reuse

### Portable from Web (Rewrite in Swift)

These algorithms/logic can be directly ported:

#### 1. Puzzle Generation Engine

```swift
// Core algorithm identical to TypeScript version
struct PuzzleGenerator {
    func generate(settings: DifficultySettings) throws -> Puzzle
}

struct PathFinder {
    func generatePath(
        rows: Int, cols: Int,
        minLength: Int, maxLength: Int
    ) throws -> (path: [Coordinate], diagonalCommitments: [DiagonalKey: Direction])
}

struct ExpressionGenerator {
    func generate(target: Int, difficulty: DifficultySettings) -> String
}
```

#### 2. Difficulty Presets

10 preset levels with identical parameters:

| Level | Operations | Add/Sub Range | Mult/Div Range | Grid | Answer Range |
|-------|------------|---------------|----------------|------|--------------|
| 1 | + only | 10 | - | 3×4 | 5-15 |
| 2 | + only | 15 | - | 3×5 | 5-20 |
| 3 | +, − | 15 | - | 4×4 | 5-20 |
| 4 | +, − | 20 | - | 4×5 | 5-25 |
| 5 | +, −, × | 20 | 5 | 4×5 | 5-30 |
| 6 | +, −, × | 25 | 6 | 4×5 | 5-35 |
| 7 | +, −, × | 30 | 8 | 5×5 | 5-40 |
| 8 | +, −, ×, ÷ | 30 | 10 | 5×5 | 5-45 |
| 9 | +, −, ×, ÷ | 40 | 12 | 5×6 | 5-50 |
| 10 | +, −, ×, ÷ | 50 | 14 | 5×6 | 5-100 |

#### 3. Validation Logic

```swift
struct PuzzleValidator {
    func validate(_ puzzle: Puzzle) -> [ValidationError]

    // Checks:
    // 1. Valid path from START to FINISH
    // 2. All connector values unique per cell
    // 3. Exactly one matching connector per cell
    // 4. All expressions evaluate correctly
    // 5. Solution path is arithmetically valid
}
```

#### 4. Merge Rules (Sync)

Same conflict resolution:

| Data | Rule |
|------|------|
| coins | Higher wins |
| stars | Higher wins |
| best_time_ms | Lower wins |
| completed | True wins |
| first_completed_at | Earliest wins |
| attempts | Higher wins |

### Platform-Specific (Must Rebuild)

| Component | Web | iOS |
|-----------|-----|-----|
| UI Components | React/Tailwind | SwiftUI |
| Animations | CSS/SVG | SwiftUI animations |
| Storage | IndexedDB | CoreData/UserDefaults |
| Print | Browser print | UIGraphicsPDFRenderer |
| Navigation | React Router | NavigationStack |
| Haptics | N/A | UIImpactFeedbackGenerator |

---

## iOS-Specific Considerations

### 1. Haptic Feedback

Add haptics for immersive experience:

| Action | Haptic |
|--------|--------|
| Cell tap | Light impact |
| Correct answer | Success notification |
| Wrong answer | Error notification |
| Game over | Heavy impact |
| Win | Triple success |

```swift
class HapticsService {
    func correctAnswer() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func wrongAnswer() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
```

### 2. Device Orientation

Support both orientations with optimized layouts (matching recent web updates):

**Portrait/Desktop:**
- Vertical stack: header → grid → action buttons
- Best for smaller grids

**Mobile Landscape (height <= 500px):**
- Horizontal three-panel layout:
  - **Left panel:** Back button + action buttons (vertical stack)
  - **Center:** Puzzle grid (maximized)
  - **Right panel:** Lives, timer, coins (vertical stack)
- Grid takes maximum available space
- UI elements moved to sides for maximum play area

```swift
struct GameView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var isMobileLandscape: Bool {
        isLandscape && UIScreen.main.bounds.height <= 500
    }

    var body: some View {
        if isMobileLandscape {
            HStack {
                // Left panel: back + action buttons
                VStack { ... }
                // Center: puzzle grid (maximized)
                PuzzleGridView(...)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Right panel: lives, timer, coins
                VStack { ... }
            }
        } else {
            // Portrait layout (vertical stack)
            VStack { ... }
        }
    }
}
```

### 3. Safe Areas & Notch

- Respect safe area insets
- Don't place critical UI near notch/Dynamic Island
- Game grid should be centered with proper margins

### 4. Accessibility

| Feature | Implementation |
|---------|----------------|
| VoiceOver | Semantic labels on all cells |
| Dynamic Type | Scale text appropriately |
| Reduce Motion | Disable animations when enabled |
| Increase Contrast | Alternative color scheme |

```swift
struct HexCellView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Disable pulse animation if reduce motion is on
}
```

### 5. Print/Share

Use native iOS print and share:

```swift
// Print current puzzle
func printPuzzle(_ puzzle: Puzzle) {
    let printInfo = UIPrintInfo.printInfo()
    printInfo.outputType = .general

    let renderer = UIGraphicsPDFRenderer(...)
    // Render puzzle to PDF

    let printController = UIPrintInteractionController.shared
    printController.printInfo = printInfo
    printController.printingItem = pdfData
    printController.present(animated: true)
}
```

### 6. App Lifecycle

Handle app states properly:

```swift
@main
struct MaxPuzzlesApp: App {
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // Resume timer if in game
            case .inactive:
                // Pause timer
            case .background:
                // Save game state, end session after 5 min
            }
        }
    }
}
```

---

## Implementation Phases

### Phase 1: Foundation (Core Setup)

**Goals:**
- Project setup with proper architecture
- Theme and design system
- Basic navigation structure

**Tasks:**
1. Create Xcode project with SwiftUI
2. Set up folder structure
3. Implement Theme.swift with color palette
4. Create reusable UI components (buttons, cards)
5. Set up navigation shell

**Color Palette:**
```swift
extension Color {
    // Hub colors
    static let backgroundDark = Color(hex: "0f0f23")
    static let backgroundMid = Color(hex: "1a1a3e")
    static let accentPrimary = Color(hex: "22c55e")
    static let accentSecondary = Color(hex: "e94560")
    static let accentTertiary = Color(hex: "fbbf24")

    // Circuit Challenge colors
    static let gridBackground = Color(hex: "0a0a12")
    static let connectorDefault = Color(hex: "3d3428")
    static let connectorActive = Color(hex: "00dd77")
    static let connectorGlow = Color(hex: "00ff88")
    static let heartsActive = Color(hex: "ff3366")
}
```

---

### Phase 2: Puzzle Engine

**Goals:**
- Port puzzle generation algorithm
- Full test coverage

**Tasks:**
1. Implement Coordinate, Cell, Connector models
2. Port PathFinder algorithm
3. Port ExpressionGenerator
4. Implement PuzzleGenerator orchestration
5. Port PuzzleValidator
6. Create DifficultyPresets
7. Write comprehensive unit tests
8. Property-based testing (generate 1000+ puzzles)

**Critical Files:**
- `Engine/PuzzleGenerator.swift`
- `Engine/PathFinder.swift`
- `Engine/ExpressionGenerator.swift`
- `Engine/DifficultyPresets.swift`
- `Engine/PuzzleValidator.swift`

**Test Requirements:**
- All generated puzzles must pass validation
- Generation time < 200ms
- Test all 10 difficulty levels

---

### Phase 3: Grid Rendering

**Goals:**
- Beautiful hex grid with 3D effect
- Connector rendering with animations

**Tasks:**
1. Create HexCellView with 3D poker chip effect
2. Implement cell states (normal, start, finish, current, visited)
3. Create ConnectorView with number badges
4. Build PuzzleGridView composition
5. Implement pulse animations for visited cells
6. Create electric flow animation for traversed connectors

**Hex Cell Layers (Bottom to Top):**
1. Shadow (offset 4, 14)
2. Edge (offset 0, 12)
3. Base (offset 0, 6)
4. Top face (offset 0, 0)
5. Inner shadow
6. Rim highlight

**Cell Text Visibility (Recent Web Update):**
- Add black shadow text layer behind white text for contrast
- All cell text renders as bright white (#ffffff)
- Current cell (and START at game start) pulses with electric surge glow effect
- Use `.shadow(color: .black, radius: 2, x: 1, y: 1)` for text contrast

```swift
struct CellTextView: View {
    let expression: String
    let isCurrent: Bool

    var body: some View {
        ZStack {
            // Shadow layer for contrast
            Text(expression)
                .foregroundColor(.black)
                .offset(x: 1, y: 1)

            // Main white text
            Text(expression)
                .foregroundColor(.white)
        }
        .font(.system(size: 14, weight: .bold))
        .modifier(isCurrent ? ElectricPulseModifier() : nil)
    }
}
```

**Electric Flow Animation:**
```swift
struct ElectricFlowView: View {
    @State private var flowOffset: CGFloat = 0

    var body: some View {
        Path { ... }
            .stroke(style: StrokeStyle(
                lineWidth: 4,
                dash: [4, 20],
                dashPhase: flowOffset
            ))
            .foregroundColor(.white)
            .onAppear {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    flowOffset = -36
                }
            }
    }
}
```

---

### Phase 4: Game Logic & Screens

**Goals:**
- Complete gameplay flow
- All game screens

**Tasks:**
1. Implement GameViewModel with state machine
2. Create QuickPlaySetupView (difficulty selector)
3. Build GameView with lives, timer, coins display
4. Implement touch handling for cell selection
5. Add correct/wrong move feedback
6. Create SummaryView for game end
7. Implement Hidden Mode variant
8. Add Reset and New Puzzle functionality
9. Integrate haptic feedback

**Game States:**
```swift
enum GameState {
    case setup
    case ready           // Puzzle shown, waiting for first move
    case playing         // Timer running
    case won
    case lost           // Standard mode only
    case revealing      // Hidden mode - showing results
}
```

---

### Phase 5: Hub Screens

**Goals:**
- All non-game screens
- Guest mode working

**Tasks:**
1. Create SplashView with animation
2. Build LoginView with guest/login/signup options
3. Implement MainHubView
4. Create SettingsView
5. Implement local storage (UserDefaults/CoreData)
6. Guest mode fully working

---

### Phase 6: Authentication

**Goals:**
- Full family account system
- Supabase integration

**Tasks:**
1. Set up Supabase Swift SDK
2. Implement AuthService
3. Create parent signup/login flows
4. Build FamilySelectView
5. Implement PINEntryView for children
6. Handle session management
7. Implement progress transfer (guest → account)

---

### Phase 7: Parent Features

**Goals:**
- Complete parent dashboard
- Activity tracking

**Tasks:**
1. Build ParentDashboardView
2. Create ChildDetailView with stats
3. Implement ActivityHistoryView
4. Add child management (add/remove/update PIN)
5. Implement parent demo mode
6. Session tracking and logging

---

### Phase 8: Print & Polish

**Goals:**
- Print functionality
- Final polish

**Tasks:**
1. Implement PDF generation for puzzles
2. Create print preview
3. Build PuzzleMakerView for batch generation
4. Add sound effects (optional)
5. Performance optimization
6. Accessibility audit
7. Final UI polish

---

## Data & Storage

### Local Storage Strategy

| Data Type | Storage | Notes |
|-----------|---------|-------|
| User session | Keychain | Secure token storage |
| User preferences | UserDefaults | Simple key-value |
| Guest progress | CoreData | Full offline support |
| Cached data | CoreData | Sync with server |
| Pending sync queue | CoreData | Offline changes |

### CoreData Models

```swift
// Simplified - expand as needed
@Model
class LocalUser {
    var id: UUID
    var displayName: String
    var role: String  // "parent" or "child"
    var coins: Int
    var isGuest: Bool
}

@Model
class LocalProgress {
    var userId: UUID
    var moduleId: String
    var quickPlayStats: Data  // JSON encoded
    var lastUpdated: Date
}

@Model
class PendingSync {
    var id: UUID
    var type: String
    var payload: Data
    var createdAt: Date
}
```

### Offline-First Flow

```
1. User makes change (e.g., completes puzzle)
   └─► Save to CoreData immediately
   └─► Add to sync queue

2. When online
   └─► Process sync queue
   └─► Apply merge rules for conflicts
   └─► Update local with server response
```

---

## API Integration

### Supabase Swift SDK

```swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
    supabaseKey: "YOUR_SUPABASE_ANON_KEY"
)
```

### Required Endpoints

Same as web app:

| Endpoint | Purpose |
|----------|---------|
| `POST /auth/child-login` | Verify child PIN |
| `POST /auth/transfer-guest` | Migrate guest data |
| `POST /family/children` | Add child |
| `PATCH /family/children/:id` | Update child |
| `POST /progress/:mod/levels/:id` | Record completion |
| `POST /activity/session` | Log session |
| `POST /sync` | Bulk sync |
| `GET /parent/children` | Family overview |
| `GET /parent/children/:id/stats` | Child stats |

### Direct Supabase Access (RLS)

Tables with direct access:
- `avatar_items` (read all)
- `avatar_configs` (read/write own)
- `progression_levels` (read own + children)
- `module_progress` (read/write own)
- `user_settings` (read/write own)

---

## Testing Strategy

### Unit Tests

**Priority 1: Engine**
- Path generation
- Expression generation
- Connector value assignment
- Puzzle validation

**Priority 2: ViewModels**
- Game state transitions
- Score calculation
- Timer logic

### Integration Tests

- Complete Quick Play flow
- Guest → account transfer
- Sync conflict resolution

### UI Tests

- Critical user journeys
- Accessibility compliance

### Performance Tests

- Puzzle generation < 200ms
- Grid rendering at 60fps
- Memory usage monitoring

---

## App Store Requirements

### Metadata

- **App Name:** Max's Puzzles
- **Category:** Education (Kids)
- **Age Rating:** 4+ (no objectionable content)
- **Privacy:** Minimal data collection, COPPA compliant

### Screenshots Needed

- iPhone 6.7" (Pro Max)
- iPhone 6.1" (Pro)
- iPad Pro 12.9"

### Privacy Policy

Required for:
- Family account data
- Child profiles
- Analytics (if any)

### COPPA Compliance

- Parental consent for accounts
- No behavioral advertising
- No social features for children
- Clear privacy disclosures

---

## Recent Web Changes to Mirror

These features were recently added/fixed in the web app and should be implemented in iOS:

### 1. Mobile Landscape Layout

The web app now has an optimized layout for mobile devices in landscape orientation:

- **Hook:** `useOrientation.ts` detects `isMobileLandscape` (landscape AND height <= 500px)
- **Layout:** Horizontal three-panel layout with grid maximized in center
- **iOS:** Use `verticalSizeClass == .compact` and screen height check

### 2. Cell Text Visibility Fix

Improved text readability on hex cells:

- Black shadow text layer behind white text for contrast
- All cell text renders as bright white (#ffffff)
- Current cell pulses with electric surge glow effect
- START cell also pulses at game start

### 3. View Solution Fix

The View Solution button now works correctly:

- When player loses (runs out of lives), they can tap "View Solution"
- Solution path connectors highlight with the active/traversed animation
- All cells on solution path show as visited (green, pulsing)
- Entire path reveals at once (instant, not animated step-by-step)

**Implementation in iOS:**

```swift
struct PuzzleGridView: View {
    let puzzle: Puzzle
    let gameState: GameState
    let showSolution: Bool

    private func isConnectorOnSolutionPath(connector: Connector) -> Bool {
        guard showSolution else { return false }

        let path = puzzle.solution.path
        for i in 0..<(path.count - 1) {
            let current = path[i]
            let next = path[i + 1]
            if connector.connects(current, next) {
                return true
            }
        }
        return false
    }

    // Use isConnectorOnSolutionPath to highlight connectors
    // when View Solution is active
}
```

---

## Critical Design Decisions (Reference)

Maintain consistency with web app:

| # | Decision | Implementation |
|---|----------|----------------|
| 1 | Level naming | `"1-A"`, `"1-B"`, `"1-C"` format |
| 2 | Timer start | First tap on ANY adjacent cell |
| 3 | Coin display (V3) | Clamped running total, stops at 0 |
| 4 | Per-puzzle minimum | 0 coins (can't lose existing) |
| 5 | Hidden Mode | No lives, no animations during play |
| 6 | Grid model | Rectangular logic, hex visuals (8 neighbours) |
| 7 | View Solution | Instant full path reveal |
| 8 | Generation failure | Retry 20 times, then error |
| 9 | PDF generation | 2 puzzles per A4, pure B&W |
| 10 | Auth model | Supabase for parents, PIN for children |
| 11 | Parent demo | Can play Quick Play, nothing saved |
| 12 | Session boundaries | Module entry → hub return / 5 min inactivity |

---

## Success Criteria

The iOS app is successful when:

1. Max can play Quick Play at any difficulty
2. Puzzles generate correctly every time
3. Print output matches web quality
4. Parent dashboard shows accurate stats
5. Offline play works seamlessly
6. Sync works reliably when online
7. App passes App Store review
8. Performance is smooth (60fps)

---

## Next Steps

1. **Review this document** - Confirm scope and approach
2. **Set up Xcode project** - Begin Phase 1
3. **Port puzzle engine** - Core algorithm first
4. **Build iteratively** - One phase at a time
5. **Test continuously** - Especially the engine

---

*End of iOS App Planning Document*
