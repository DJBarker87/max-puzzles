# Max's Puzzles iOS App - Build Guide (CLAUDE.md)

**Version:** 1.0
**Last Updated:** January 2025
**Purpose:** Guide for Claude Code to build the native iOS version of Max's Puzzles

---

## Project Overview

Max's Puzzles iOS is a native SwiftUI port of the web app. It's a fun, educational maths puzzle platform for children aged 5-11, starting with Max (age 6). Uses a **hub-and-spoke architecture** where a central hub provides shared services and independent puzzle modules plug into it.

**First module:** Circuit Challenge - a path-finding puzzle using arithmetic.

**Web app reference:** The React web app in `/src` is the reference implementation. Match its behavior exactly.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI (iOS 16+) |
| State | @Observable / ObservableObject |
| Local Storage | CoreData + UserDefaults |
| Secure Storage | Keychain (via KeychainAccess) |
| Backend | Supabase Swift SDK |
| Crash Reporting | Firebase Crashlytics |
| Architecture | MVVM |
| Testing | XCTest + Swift Testing |

---

## Reference Documentation

| Folder | Contents |
|--------|----------|
| `build-phases/` | Phase-by-phase build guides (PHASE_01 through PHASE_08) |
| `IOS_APP_PLANNING.md` | Full planning document with design decisions |
| `WEB_FILE_REFERENCE.md` | Map of web app files to reference |
| `/src` (parent) | Web app source code - the reference implementation |

**Build order:** Follow the phase documents sequentially. Each phase has detailed subphases with prompts.

---

## Project Structure

```
MaxPuzzles/
├── App/
│   ├── MaxPuzzlesApp.swift          # App entry point
│   ├── ContentView.swift            # Root navigation
│   └── AppState.swift               # Global app state
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
│   │   ├── CoinService.swift        # V3 stub
│   │   ├── StorageService.swift
│   │   ├── SyncService.swift
│   │   └── SoundService.swift       # V1 stub (silent)
│   │
│   └── Utilities/
│       ├── Theme.swift              # Colors, fonts
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
│   │
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── FamilyViewModel.swift
│   │   └── DashboardViewModel.swift
│   │
│   └── Components/
│       ├── StarryBackground.swift
│       ├── HeaderView.swift
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
│       │   └── DifficultyViewModel.swift
│       │
│       ├── Engine/
│       │   ├── PuzzleGenerator.swift
│       │   ├── PathFinder.swift
│       │   ├── ExpressionGenerator.swift
│       │   ├── ConnectorAssigner.swift
│       │   ├── CellAssigner.swift
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
│   │   └── Animations/
│   │
│   └── Types/
│       ├── ModuleProtocol.swift
│       ├── Coordinate.swift
│       └── GameState.swift
│
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
│
└── Tests/
    ├── EngineTests/
    ├── ViewModelTests/
    └── IntegrationTests/
```

---

## Build Phases

| Phase | Focus | Key Files |
|-------|-------|-----------|
| 1 | Foundation | Theme, buttons, cards, navigation shell |
| 2 | Puzzle Engine | Generator, pathfinder, expressions, validator |
| 3 | Grid Rendering | HexCell, Connector, PuzzleGrid with animations |
| 4 | Game Logic | GameViewModel, screens, state machine |
| 5 | Hub Screens | Splash, MainHub, Settings, menus |
| 6 | Authentication | Supabase, login, family select, PIN |
| 7 | Parent Features | Dashboard, child stats, activity history |
| 8 | Print & Polish | PDF generation, accessibility, testing |

**Read each `build-phases/PHASE_XX_*.md` file for detailed implementation prompts.**

---

## Critical Color Values

### Hub Colors

| Element | Hex | SwiftUI |
|---------|-----|---------|
| Background dark | #0f0f23 | `Color(hex: "0f0f23")` |
| Background mid | #1a1a3e | `Color(hex: "1a1a3e")` |
| Accent primary | #22c55e | `Color(hex: "22c55e")` |
| Accent secondary | #e94560 | `Color(hex: "e94560")` |
| Accent tertiary | #fbbf24 | `Color(hex: "fbbf24")` |
| Text primary | #ffffff | `.white` |
| Text secondary | #a1a1aa | `Color(hex: "a1a1aa")` |

### Cell State Colors

| State | Top Gradient | Border |
|-------|--------------|--------|
| Normal | #3a3a4a → #252530 | #4a4a5a |
| Start | #15803d → #0d5025 | #00ff88 |
| Finish | #ca8a04 → #854d0e | #ffcc00 |
| Current | #0d9488 → #086560 | #00ffcc |
| Visited | #1a5c38 → #103822 | #00ff88 |

### Connector Colors

| State | Color |
|-------|-------|
| Default | #3d3428 |
| Active/Glow | #00ff88 |
| Main line | #00dd77 |
| Energy slow | #88ffcc |
| Energy fast | #ffffff |
| Core | #aaffcc |

---

## Critical Design Decisions

| # | Decision | Implementation |
|---|----------|----------------|
| 1 | Always dark theme | `.preferredColorScheme(.dark)` |
| 2 | Timer start | First tap on ANY adjacent cell |
| 3 | Hidden Mode | No lives, no animations during, reveal at end |
| 4 | Grid model | Rectangular logic, hex visuals (8 neighbours) |
| 5 | View Solution | Instant full path reveal (all at once) |
| 6 | Generation failure | Retry 20 times, then error |
| 7 | PDF generation | 2 puzzles per A4, pure B&W |
| 8 | Auth model | Supabase for parents, PIN for children |
| 9 | Parent demo | Can play Quick Play, nothing saved |
| 10 | Session end | Module exit / hub return / 5 min inactivity |

---

## Hex Cell 3D Layers

Bottom to top (scale offsets for cell size):

1. **Shadow** - Black 50% opacity, offset (4, 14), blur 4
2. **Edge** - Dark gradient, offset (0, 12)
3. **Base** - Mid gradient, offset (0, 6)
4. **Top face** - State gradient, offset (0, 0)
5. **Inner shadow** - Black 30% stroke, blur 1
6. **Rim highlight** - State border color, 1.5px stroke

```swift
// Proportional offsets
var shadowOffset: CGFloat { cellSize * 0.1 }   // ~14px at 140
var edgeOffset: CGFloat { cellSize * 0.086 }   // ~12px
var baseOffset: CGFloat { cellSize * 0.043 }   // ~6px
```

---

## Electric Flow Animation

Traversed connectors have 5 layers:

```swift
// Layer 1: Glow (18px, blur 8)
.stroke(Color(hex: "00ff88").opacity(0.6), lineWidth: 18)
.blur(radius: 8)

// Layer 2: Main line (10px)
.stroke(Color(hex: "00dd77"), lineWidth: 10)

// Layer 3: Energy slow (6px, dash [6,30], 1.2s)
.stroke(style: StrokeStyle(lineWidth: 6, dash: [6, 30], dashPhase: flowPhase2))

// Layer 4: Energy fast (4px, dash [4,20], 0.8s)
.stroke(style: StrokeStyle(lineWidth: 4, dash: [4, 20], dashPhase: flowPhase1))

// Layer 5: Core (3px)
.stroke(Color(hex: "aaffcc"), lineWidth: 3)
```

Animation: `dashPhase` animates from 0 to -36 in linear loop.

---

## Cell Sizing by Device

| Device | Cell Width | Font Size |
|--------|------------|-----------|
| iPhone | 60-70px | 14px |
| iPad mini | 90-100px | 18px |
| iPad | 100-120px | 20px |
| iPad Pro 12.9" | 120-140px | 24px |

Use `@Environment(\.horizontalSizeClass)` to detect iPad.

---

## Layout Modes

### Portrait (iPhone/iPad)
Vertical stack: header → grid → action buttons

### Landscape (iPhone, height ≤ 500)
Three-panel horizontal:
- Left: Back + action buttons (vertical)
- Center: Grid (maximized)
- Right: Lives, timer, coins (vertical)

### iPad Landscape
Floating panels with maximized grid center.

```swift
var isMobileLandscape: Bool {
    verticalSizeClass == .compact && UIScreen.main.bounds.height <= 500
}
```

---

## Difficulty Presets

| Level | Ops | Add/Sub | Mult/Div | Grid | Answers |
|-------|-----|---------|----------|------|---------|
| 1 | + | 10 | - | 3×4 | 5-15 |
| 2 | + | 15 | - | 3×5 | 5-20 |
| 3 | +− | 15 | - | 4×4 | 5-20 |
| 4 | +− | 20 | - | 4×5 | 5-25 |
| 5 | +−× | 20 | 5 | 4×5 | 5-30 |
| 6 | +−× | 25 | 6 | 4×5 | 5-35 |
| 7 | +−× | 30 | 8 | 5×5 | 5-40 |
| 8 | +−×÷ | 30 | 10 | 5×5 | 5-45 |
| 9 | +−×÷ | 40 | 12 | 5×6 | 5-50 |
| 10 | +−×÷ | 50 | 14 | 5×6 | 5-100 |

---

## Game States

```swift
enum GameStatus {
    case setup           // Configuring difficulty
    case ready           // Puzzle shown, waiting for first move
    case playing         // Timer running
    case won             // Reached FINISH
    case lost            // Out of lives (standard mode)
    case revealing       // Hidden mode - showing results
    case showingSolution // View Solution active
}
```

---

## Haptic Feedback

| Action | Haptic |
|--------|--------|
| Cell tap | `.impact(.light)` |
| Correct answer | `.notificationOccurred(.success)` |
| Wrong answer | `.notificationOccurred(.error)` |
| Game win | Triple success |
| Game over | `.impact(.heavy)` |

---

## Key SwiftUI Patterns

### Color Extension
```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
```

### Hexagon Shape
```swift
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let points = [
            CGPoint(x: w * 0.5, y: 0),
            CGPoint(x: w, y: h * 0.25),
            CGPoint(x: w, y: h * 0.75),
            CGPoint(x: w * 0.5, y: h),
            CGPoint(x: 0, y: h * 0.75),
            CGPoint(x: 0, y: h * 0.25),
        ]
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}
```

---

## Testing Requirements

### Unit Tests (Priority)
1. Puzzle generation - all 10 levels
2. Path validation
3. Expression evaluation
4. Connector uniqueness

### Property Tests
- Generate 1000+ puzzles per level
- All must pass validation
- Generation < 200ms

### Integration Tests
- Complete Quick Play flow
- Guest → account transfer
- Offline → online sync

---

## V1 Scope

**Included:**
- Quick Play with all difficulties
- Hidden Mode toggle
- 5 lives system
- Reset + New Puzzle buttons
- Print current puzzle
- Puzzle Maker (batch PDF)
- Guest mode
- Family accounts (Supabase)
- Parent dashboard
- Parent demo mode
- Mac Catalyst support

**Stubbed (V3):**
- Coin service (returns 0)
- Avatar service (placeholder)
- Sound service (silent)

**Deferred (V2):**
- Progression levels
- Star ratings
- Tutorial hints
- Daily time limits

---

## Dependencies (SPM)

```swift
// Package.swift or Xcode SPM
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.0"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
]
```

Only use Firebase Crashlytics - no analytics.

---

## Error Messages

| Error | User Message |
|-------|--------------|
| Puzzle generation | "Oops! Couldn't create a puzzle. Let's try again!" |
| Network offline | "You're offline. Progress is saved and will sync later." |
| Auth failed | "Couldn't sign in. Please check your details." |
| Wrong PIN | "That's not the right PIN. Try again!" |
| Print failed | "Couldn't print. Make sure a printer is connected." |

Use friendly, non-technical language for children.

---

## App Store Requirements

- **Category:** Education (Kids)
- **Age Rating:** 4+
- **Privacy:** COPPA compliant, minimal data
- **Screenshots:** iPhone 6.7", iPhone 6.1", iPad Pro 12.9"

---

## Quick Reference Commands

```bash
# Open Xcode project
open MaxPuzzles.xcodeproj

# Run tests
xcodebuild test -scheme MaxPuzzles -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for device
xcodebuild -scheme MaxPuzzles -destination 'generic/platform=iOS'
```

---

## Success Criteria

1. Max can play Quick Play at any difficulty
2. Puzzles generate correctly every time
3. All animations match web app exactly
4. Print produces classroom-quality PDF (2 per A4, B&W)
5. Parent dashboard shows accurate stats
6. Offline play works seamlessly
7. App runs smoothly at 60fps
8. Passes App Store review

---

## Questions During Build

Check documents in order:
1. This CLAUDE.md
2. `IOS_APP_PLANNING.md`
3. Relevant `build-phases/PHASE_XX_*.md`
4. Web app source in `/src`
5. Ask the user

**When in doubt: fun first, match web exactly.**

---

*End of iOS CLAUDE.md*
