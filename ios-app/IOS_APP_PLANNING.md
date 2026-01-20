# Max's Puzzles - iOS App Planning Document

**Version:** 1.1
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
7. [iPad Optimization](#ipad-optimization)
8. [Implementation Phases](#implementation-phases)
9. [Data & Storage](#data--storage)
10. [API Integration](#api-integration)
11. [Testing Strategy](#testing-strategy)
12. [App Store Requirements](#app-store-requirements)
13. [Recent Web Changes to Mirror](#recent-web-changes-to-mirror)
14. [Onboarding & First Run](#onboarding--first-run)
15. [App Appearance](#app-appearance)
16. [Parental Controls](#parental-controls)
17. [Push Notifications](#push-notifications)
18. [Crash Reporting & Analytics](#crash-reporting--analytics)
19. [Build & Distribution](#build--distribution)
20. [Mac Catalyst Support](#mac-catalyst-support)
21. [Sound Effects](#sound-effects)
22. [App Icon & Launch Screen](#app-icon--launch-screen)
23. [Error Handling](#error-handling)
24. [Module Registration Protocol](#module-registration-protocol)
25. [Critical Design Decisions](#critical-design-decisions-reference)
26. [Success Criteria](#success-criteria)

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

## iPad Optimization

iPad deserves a **first-class experience**, not just a scaled-up iPhone app. The larger screen enables enhanced layouts, bigger touch targets, and richer visual effects.

### iPad Device Targets

| Device | Screen Size | Resolution | Notes |
|--------|-------------|------------|-------|
| iPad mini | 8.3" | 2266×1488 | Smallest iPad, still larger than iPhone |
| iPad | 10.9" | 2360×1640 | Standard iPad |
| iPad Air | 10.9" | 2360×1640 | Same as standard |
| iPad Pro 11" | 11" | 2388×1668 | ProMotion 120Hz |
| iPad Pro 12.9" | 12.9" | 2732×2048 | Largest, ProMotion 120Hz |

### Detection Strategy

```swift
struct DeviceInfo {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    static var isLargeIPad: Bool {
        isIPad && min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) >= 1024
    }
}

// In SwiftUI views
struct GameView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    var isIPadLandscape: Bool {
        isIPad && UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }
}
```

---

### iPad Game Screen Layout

#### Portrait Mode (iPad)

Two-column layout with sidebar:

```
┌─────────────────────────────────────────────────────────┐
│  ←  Circuit Challenge                        🪙 1,234   │
├───────────────────┬─────────────────────────────────────┤
│                   │                                     │
│   Quick Play      │                                     │
│                   │         ┌─────────────────┐         │
│   ───────────     │         │                 │         │
│                   │         │                 │         │
│   Difficulty:     │         │   PUZZLE GRID   │         │
│   Level 5         │         │                 │         │
│                   │         │   (LARGER)      │         │
│   ───────────     │         │                 │         │
│                   │         │                 │         │
│   ♥ ♥ ♥ ♥ ♥      │         └─────────────────┘         │
│   Lives           │                                     │
│                   │                                     │
│   ⏱ 0:45         │    [🔄 Reset]  [✨ New Puzzle]      │
│   Timer           │    [⚙️ Difficulty]  [🖨️ Print]     │
│                   │                                     │
└───────────────────┴─────────────────────────────────────┘
```

#### Landscape Mode (iPad)

Maximized grid with floating panels:

```
┌─────────────────────────────────────────────────────────────────────┐
│  ←  Circuit Challenge                                    🪙 1,234   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────┐                                         ┌─────────┐   │
│  │ Level 5 │      ┌───────────────────────────┐      │ ♥♥♥♥♥   │   │
│  │         │      │                           │      │         │   │
│  │ Hidden  │      │                           │      │ ⏱ 0:45  │   │
│  │ Mode: ○ │      │      PUZZLE GRID          │      │         │   │
│  │         │      │                           │      │ 🪙 +80   │   │
│  │─────────│      │      (MAXIMIZED)          │      │         │   │
│  │ [Reset] │      │                           │      │─────────│   │
│  │ [New]   │      │                           │      │ Stats   │   │
│  │ [Print] │      └───────────────────────────┘      │ 47 games│   │
│  └─────────┘                                         └─────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

### iPad Cell Sizing

Larger cells for iPad's bigger screen:

| Device | Cell Width | Cell Height | Touch Target | Text Size |
|--------|------------|-------------|--------------|-----------|
| iPhone | 60-70px | 52-60px | 70px | 14px |
| iPad mini | 90-100px | 78-86px | 100px | 18px |
| iPad | 100-120px | 86-103px | 120px | 20px |
| iPad Pro 12.9" | 120-140px | 103-120px | 140px | 24px |

```swift
struct HexCellView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var cellSize: CGFloat {
        switch horizontalSizeClass {
        case .regular:
            return DeviceInfo.isLargeIPad ? 130 : 110
        default:
            return 65
        }
    }

    var fontSize: CGFloat {
        switch horizontalSizeClass {
        case .regular:
            return DeviceInfo.isLargeIPad ? 24 : 20
        default:
            return 14
        }
    }
}
```

---

### Visual Style Consistency (CRITICAL)

**All visual styles must match the web app exactly.** The visual design was carefully crafted - do not deviate.

#### Hex Cell 3D "Poker Chip" Effect

Exact layer structure (scales proportionally on iPad):

```swift
struct HexCellView: View {
    let state: CellState
    let expression: String

    // EXACT offsets from web (scale for iPad)
    var shadowOffset: CGFloat { cellSize * 0.1 }  // ~14px at 140px cell
    var edgeOffset: CGFloat { cellSize * 0.086 }  // ~12px
    var baseOffset: CGFloat { cellSize * 0.043 }  // ~6px

    var body: some View {
        ZStack {
            // Layer 1: Shadow
            HexagonShape()
                .fill(Color.black.opacity(0.5))
                .offset(x: 4, y: shadowOffset)
                .blur(radius: 4)

            // Layer 2: Edge (3D depth)
            HexagonShape()
                .fill(edgeGradient)
                .offset(y: edgeOffset)

            // Layer 3: Base
            HexagonShape()
                .fill(baseGradient)
                .offset(y: baseOffset)

            // Layer 4: Top face
            HexagonShape()
                .fill(topGradient)

            // Layer 5: Inner shadow (on top face)
            HexagonShape()
                .stroke(Color.black.opacity(0.3), lineWidth: 2)
                .blur(radius: 1)

            // Layer 6: Rim highlight
            HexagonShape()
                .stroke(rimColor, lineWidth: 1.5)

            // Expression text with shadow
            CellTextView(expression: expression, state: state)
        }
        .frame(width: cellSize, height: cellSize * 0.866)
    }
}
```

#### Cell State Colors (EXACT from web)

```swift
extension Color {
    // Normal cell
    static let cellNormalTop1 = Color(hex: "3a3a4a")
    static let cellNormalTop2 = Color(hex: "252530")
    static let cellNormalEdge1 = Color(hex: "1a1a25")
    static let cellNormalEdge2 = Color(hex: "0f0f15")
    static let cellNormalBorder = Color(hex: "4a4a5a")

    // Start cell
    static let cellStartTop1 = Color(hex: "15803d")
    static let cellStartTop2 = Color(hex: "0d5025")
    static let cellStartBorder = Color(hex: "00ff88")

    // Finish cell
    static let cellFinishTop1 = Color(hex: "ca8a04")
    static let cellFinishTop2 = Color(hex: "854d0e")
    static let cellFinishBorder = Color(hex: "ffcc00")
    static let cellFinishText = Color(hex: "ffdd44")

    // Current cell
    static let cellCurrentTop1 = Color(hex: "0d9488")
    static let cellCurrentTop2 = Color(hex: "086560")
    static let cellCurrentBorder = Color(hex: "00ffcc")

    // Visited cell
    static let cellVisitedTop1 = Color(hex: "1a5c38")
    static let cellVisitedTop2 = Color(hex: "103822")
    static let cellVisitedBorder = Color(hex: "00ff88")

    // Wrong (reveal)
    static let cellWrongTop = Color(hex: "ef4444")
    static let cellWrongBorder = Color(hex: "dc2626")
}
```

#### Connector Styles (EXACT from web)

```swift
// Default connector
static let connectorDefault = Color(hex: "3d3428")

// Active/traversed connector - multi-layer electric effect
struct TraversedConnectorView: View {
    @State private var flowPhase1: CGFloat = 0
    @State private var flowPhase2: CGFloat = 0
    @State private var glowIntensity: CGFloat = 0.6

    var body: some View {
        ZStack {
            // Layer 1: Glow (18px, blurred)
            connectorPath
                .stroke(Color(hex: "00ff88").opacity(glowIntensity), lineWidth: 18)
                .blur(radius: 8)

            // Layer 2: Main line (10px)
            connectorPath
                .stroke(Color(hex: "00dd77"), lineWidth: 10)

            // Layer 3: Energy particles 2 (6px, slower)
            connectorPath
                .stroke(
                    Color(hex: "88ffcc"),
                    style: StrokeStyle(lineWidth: 6, dash: [6, 30], dashPhase: flowPhase2)
                )

            // Layer 4: Energy particles 1 (4px, faster)
            connectorPath
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 4, dash: [4, 20], dashPhase: flowPhase1)
                )

            // Layer 5: Bright core (3px)
            connectorPath
                .stroke(Color(hex: "aaffcc"), lineWidth: 3)

            // Number badge
            ConnectorBadge(value: value)
        }
        .onAppear {
            // Energy flow animation (0.8s fast, 1.2s slow)
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                flowPhase1 = -36
            }
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                flowPhase2 = -36
            }
            // Glow pulse (1.5s)
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowIntensity = 0.9
            }
        }
    }
}
```

#### Connector Badge (Number Display)

```swift
struct ConnectorBadge: View {
    let value: Int

    var body: some View {
        Text("\(value)")
            .font(.system(size: badgeFontSize, weight: .bold))
            .foregroundColor(Color(hex: "ff9f43"))  // Orange text
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "15151f"))  // Dark background
            )
    }

    var badgeFontSize: CGFloat {
        DeviceInfo.isIPad ? 18 : 14
    }
}
```

#### Cell Pulse Animations

```swift
// Current cell pulse (1.5s cycle)
struct CurrentCellPulse: ViewModifier {
    @State private var glowAmount: CGFloat = 0.3

    func body(content: Content) -> some View {
        content
            .shadow(color: Color(hex: "00ffcc").opacity(glowAmount), radius: 12)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowAmount = 0.7
                }
            }
    }
}

// Visited cell pulse (2s cycle)
struct VisitedCellPulse: ViewModifier {
    @State private var glowAmount: CGFloat = 0.3

    func body(content: Content) -> some View {
        content
            .shadow(color: Color(hex: "00ff88").opacity(glowAmount), radius: 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowAmount = 0.6
                }
            }
    }
}
```

#### Hearts Pulse Animation

```swift
// Active hearts pulse (1.2s heartbeat)
struct HeartPulse: ViewModifier {
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    scale = 1.15
                }
            }
    }
}

struct LivesDisplay: View {
    let lives: Int
    let maxLives: Int = 5

    var body: some View {
        HStack(spacing: DeviceInfo.isIPad ? 12 : 8) {
            ForEach(0..<maxLives, id: \.self) { index in
                Image(systemName: "heart.fill")
                    .foregroundColor(index < lives ? Color(hex: "ff3366") : Color(hex: "2a2a3a"))
                    .font(.system(size: DeviceInfo.isIPad ? 28 : 20))
                    .modifier(index < lives ? HeartPulse() : nil)
            }
        }
    }
}
```

#### Starry Background

```swift
struct StarryBackground: View {
    let starCount = 80

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(hex: "0a0a12"),
                    Color(hex: "12121f"),
                    Color(hex: "0d0d18")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Stars
            ForEach(0..<starCount, id: \.self) { i in
                StarView(seed: i)
            }

            // Ambient green glow (3% opacity)
            Color(hex: "00ff88").opacity(0.03)
        }
    }
}

struct StarView: View {
    let seed: Int
    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
            .position(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
            )
            .opacity(opacity)
            .onAppear {
                // Twinkle animation (3-5s cycle, staggered)
                withAnimation(
                    .easeInOut(duration: Double.random(in: 3...5))
                    .repeatForever(autoreverses: true)
                    .delay(Double(seed) * 0.05)
                ) {
                    opacity = 0.8
                }
            }
    }
}
```

---

### iPad Multitasking Support

#### Split View & Slide Over

The app should work properly in all multitasking modes:

```swift
struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        // Adapt layout based on available width
        // Split View gives .compact horizontalSizeClass
        if horizontalSizeClass == .compact {
            // Use iPhone-style layout
            CompactGameView()
        } else {
            // Use iPad-optimized layout
            RegularGameView()
        }
    }
}
```

**Requirements:**
- Support all Split View sizes (1/3, 1/2, 2/3)
- Support Slide Over (compact width overlay)
- Grid scales appropriately
- No content gets cut off

#### Stage Manager (iPadOS 16+)

- Support resizable windows
- Minimum window size: 320×480
- Adapt grid and UI to window size

---

### iPad Pointer/Trackpad Support

iPad supports mouse and trackpad - add hover effects:

```swift
struct HexCellView: View {
    @State private var isHovered = false

    var body: some View {
        cellContent
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(
                color: isHovered ? Color(hex: "00ffcc").opacity(0.5) : .clear,
                radius: 8
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

struct PrimaryButton: View {
    @State private var isHovered = false

    var body: some View {
        button
            .brightness(isHovered ? 0.1 : 0)
            .onHover { isHovered = $0 }
    }
}
```

---

### iPad Keyboard Support

Add keyboard shortcuts for parents and power users:

```swift
struct GameView: View {
    var body: some View {
        gameContent
            .keyboardShortcut("r", modifiers: .command)  // Reset
            .keyboardShortcut("n", modifiers: .command)  // New Puzzle
            .keyboardShortcut("p", modifiers: .command)  // Print
    }
}

// Arrow key navigation for cells
struct PuzzleGridView: View {
    @FocusState private var focusedCell: Coordinate?

    var body: some View {
        gridContent
            .focusable()
            .onKeyPress(.leftArrow) { moveFocus(.left); return .handled }
            .onKeyPress(.rightArrow) { moveFocus(.right); return .handled }
            .onKeyPress(.upArrow) { moveFocus(.up); return .handled }
            .onKeyPress(.downArrow) { moveFocus(.down); return .handled }
            .onKeyPress(.return) { selectFocusedCell(); return .handled }
            .onKeyPress(.space) { selectFocusedCell(); return .handled }
    }
}
```

**Keyboard Shortcuts:**
| Shortcut | Action |
|----------|--------|
| ⌘R | Reset puzzle |
| ⌘N | New puzzle |
| ⌘P | Print |
| Arrow keys | Navigate cells |
| Return/Space | Select cell |
| Escape | Back/Cancel |

---

### iPad Parent Dashboard

Enhanced layout using iPad's space:

```
┌─────────────────────────────────────────────────────────────────────┐
│  ←  Parent Dashboard                                                │
├───────────────────────────────────────────────────────────────────  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Your Family                                                 │   │
│  │                                                              │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐│   │
│  │  │  👽 Max │  │ 👽 Lily │  │ 👽 Tom  │  │  + Add Child    ││   │
│  │  │ 🪙 1,234│  │ 🪙 567  │  │ 🪙 890  │  │                 ││   │
│  │  │ ⭐ 38   │  │ ⭐ 12   │  │ ⭐ 25   │  │                 ││   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────────────┘│   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌────────────────────────────┐  ┌────────────────────────────┐    │
│  │  Max's Progress            │  │  This Week's Activity      │    │
│  │                            │  │                            │    │
│  │  Circuit Challenge         │  │  ┌────────────────────┐   │    │
│  │  ████████████░░░░ 15/30    │  │  │   [Activity Chart] │   │    │
│  │                            │  │  │                    │   │    │
│  │  Quick Play: 47 games      │  │  │   Mon Tue Wed ...  │   │    │
│  │  Accuracy: 87%             │  │  └────────────────────┘   │    │
│  │  Best streak: 12           │  │                            │    │
│  │                            │  │  Total: 2h 15m             │    │
│  └────────────────────────────┘  └────────────────────────────┘    │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Recent Sessions                                              │  │
│  │  Today 4:30pm │ Circuit Challenge │ 15 min │ +80 coins       │  │
│  │  Yesterday    │ Circuit Challenge │ 22 min │ +120 coins      │  │
│  │  2 days ago   │ Circuit Challenge │ 18 min │ +60 coins       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

Use Swift Charts for activity visualization:

```swift
import Charts

struct ActivityChart: View {
    let weeklyData: [DayActivity]

    var body: some View {
        Chart(weeklyData) { day in
            BarMark(
                x: .value("Day", day.name),
                y: .value("Minutes", day.minutes)
            )
            .foregroundStyle(Color.accentPrimary)
        }
        .chartYAxisLabel("Minutes")
        .frame(height: 200)
    }
}
```

---

### iPad-Specific Testing Checklist

- [ ] All layouts work in portrait AND landscape
- [ ] Split View 1/3, 1/2, 2/3 all work
- [ ] Slide Over works correctly
- [ ] Stage Manager resizing works
- [ ] Pointer hover effects work
- [ ] Keyboard shortcuts work
- [ ] External keyboard navigation works
- [ ] Cell sizes scale correctly per device
- [ ] Animations match web exactly
- [ ] All colors match web exactly
- [ ] Electric flow effect matches web
- [ ] Starry background matches web
- [ ] Text is readable at all sizes
- [ ] Touch targets are large enough

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

## Onboarding & First Run

### Approach: Skip to Play

Minimal onboarding - get Max playing immediately:

```
App Launch
    └─► Splash Screen (1-2 seconds)
        └─► Main Hub (Guest Mode)
            └─► Tap Circuit Challenge
                └─► Quick Play Setup
                    └─► Playing!
```

**No intro tutorial in V1.** Tutorial hints are deferred to V2 with progression levels.

### First Launch Behavior

1. Show splash screen with app logo
2. Auto-create anonymous guest session (stored in UserDefaults)
3. Navigate directly to Main Hub
4. Guest can play immediately - prompt to create account later

### Account Prompts

Show gentle account creation prompts at natural moments:
- After completing 5 puzzles (non-blocking toast)
- When accessing Parent Dashboard (required)
- In Settings screen (optional)

Never interrupt gameplay with account prompts.

---

## App Appearance

### Always Dark Theme

The cosmic dark theme is core to the visual identity. **Do not** create a light mode variant.

```swift
// In App setup
.preferredColorScheme(.dark)
```

This ensures:
- Consistent experience matching web app
- Better visibility of glow effects and animations
- Reduced battery usage on OLED devices

### Status Bar

Use light content (white text) status bar:

```swift
.statusBarStyle(.lightContent)
```

---

## Parental Controls

### iOS Screen Time

The app works normally with iOS Screen Time - parents can limit usage through system settings.

### Built-in Time Limits (V2)

V2 will add app-specific daily time limits controlled via Parent Dashboard:
- Per-child configurable limits
- Visual countdown warning at 5 minutes remaining
- Graceful session end (finish current puzzle, then lock)
- Override with parent PIN

**V1:** No in-app time limits. Defer to iOS Screen Time.

---

## Push Notifications

### V1: No Notifications

Push notifications are **not included** in V1:
- Keeps app simple
- Avoids COPPA notification consent complexity
- Reduces server infrastructure needs

### Future Consideration (V2+)

If added later, parent-only notifications:
- Weekly progress summaries
- Achievement milestones
- Never notifications directly to children

---

## Crash Reporting & Analytics

### Firebase Crashlytics Only

```swift
// Dependencies (SPM)
// firebase-ios-sdk - Crashlytics module only
```

**Included:**
- Crash reports with stack traces
- Non-fatal error logging
- Basic device info (iOS version, device model)

**Excluded:**
- No usage analytics
- No event tracking
- No user behavior data

This respects privacy while enabling bug fixes.

### Privacy Considerations

- Crashlytics is COPPA-compliant
- No personally identifiable information collected
- Declare in App Store privacy nutrition labels

---

## Build & Distribution

### V1: Manual Builds

For V1, build and distribute manually:

1. **Development:** Write code in Claude Code / VS Code
2. **Build:** Open `.xcodeproj` in Xcode on Mac
3. **Test:** Run on Simulator and physical devices
4. **Archive:** Product → Archive in Xcode
5. **Upload:** Distribute to App Store Connect
6. **TestFlight:** Internal testing before release

### TestFlight Beta Testing

Before App Store release:
1. Upload build to App Store Connect
2. Add internal testers (yourself, family)
3. Test on multiple devices (iPhone, iPad)
4. Fix any issues
5. Submit for review

### Future: Xcode Cloud

Consider adding Xcode Cloud if release frequency increases:
- Automatic builds on push
- TestFlight distribution
- 25 free compute hours/month

---

## Mac Catalyst Support

### Enable Catalyst

The iPad app runs on Mac via Catalyst with minimal effort:

```
Xcode → Target → General → Deployment Info
☑️ Mac (Designed for iPad)
```

### Mac-Specific Considerations

| Feature | Behavior |
|---------|----------|
| Window resizing | Supported (iPad multitasking already handles this) |
| Menu bar | Auto-generated from keyboard shortcuts |
| Touch Bar | Not needed |
| Hover effects | Already implemented for iPad trackpad |
| Keyboard shortcuts | Already implemented for iPad keyboard |

### Print on Mac

`UIPrintInteractionController` works on Mac Catalyst - print functionality carries over automatically.

---

## Sound Effects

### V1: Architecture Only

Sound service architecture is built but **no audio files** in V1:

```swift
protocol SoundService {
    func play(_ sound: SoundEffect)
    var isMuted: Bool { get set }
}

enum SoundEffect {
    case correctTap
    case wrongTap
    case gameWin
    case gameLose
    case buttonTap
}

// V1 Implementation
class SilentSoundService: SoundService {
    func play(_ sound: SoundEffect) { /* no-op */ }
    var isMuted: Bool = true
}
```

### Future Sound Design (V2+)

When sounds are added:

| Sound | Trigger | Duration |
|-------|---------|----------|
| `correct.wav` | Correct cell tap | ~200ms |
| `wrong.wav` | Wrong cell tap | ~300ms |
| `win.wav` | Puzzle completed | ~1s |
| `lose.wav` | Out of lives | ~800ms |
| `tap.wav` | Button tap | ~100ms |

Use `.caf` format for best iOS performance.

---

## App Icon & Launch Screen

### App Icon: Hex Cell with Circuit

Design concept:
- Glowing green hexagon (#00ff88)
- Electric circuit lines flowing through
- Dark cosmic background (#0a0a12)
- Subtle glow effect around edges

```
┌─────────────────┐
│    ╱──────╲     │
│   ╱   ⚡    ╲    │
│  │  ══╪══   │   │
│   ╲   ⚡    ╱    │
│    ╲──────╱     │
└─────────────────┘
```

**Required sizes:**
- 1024×1024 (App Store)
- 180×180 (@3x iPhone)
- 167×167 (@2x iPad Pro)
- 152×152 (@2x iPad)
- 120×120 (@2x iPhone, @3x iPhone)
- Plus all smaller sizes

### Launch Screen

Simple launch screen matching app theme:

```swift
// LaunchScreen.storyboard or SwiftUI
ZStack {
    // Cosmic gradient background
    LinearGradient(
        colors: [Color(hex: "0a0a12"), Color(hex: "0f0f23")],
        startPoint: .top,
        endPoint: .bottom
    )

    // App icon (centered, ~200pt)
    Image("AppIconLarge")
        .resizable()
        .frame(width: 200, height: 200)
}
```

No loading text or progress indicators - keep it clean.

---

## Error Handling

### User-Facing Error Messages

| Error Type | Message | Action |
|------------|---------|--------|
| Puzzle generation failed | "Oops! Couldn't create a puzzle. Let's try again!" | Auto-retry or tap to retry |
| Network offline (sync) | "You're offline. Your progress is saved and will sync later." | Dismiss (non-blocking) |
| Network offline (login) | "Can't connect right now. Try again when you're online." | Retry button |
| Auth failed | "Couldn't sign in. Please check your details and try again." | Stay on login screen |
| PIN incorrect | "That's not the right PIN. Try again!" | Clear PIN, stay on screen |
| Print failed | "Couldn't print. Make sure a printer is connected." | Dismiss |

### Error Presentation

```swift
enum AppError: LocalizedError {
    case puzzleGenerationFailed
    case networkOffline
    case authenticationFailed
    case incorrectPIN
    case printFailed

    var errorDescription: String? {
        switch self {
        case .puzzleGenerationFailed:
            return "Oops! Couldn't create a puzzle. Let's try again!"
        // ... etc
        }
    }
}
```

Use friendly, non-technical language appropriate for children and parents.

### Retry Strategy

- Puzzle generation: Auto-retry up to 20 times (per web app spec)
- Network requests: Retry up to 3 times with exponential backoff
- Show error only after all retries exhausted

---

## Module Registration Protocol

### Module Interface

Future puzzle modules register with the hub:

```swift
protocol PuzzleModule {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var iconName: String { get }

    func createMenuView() -> AnyView
    func createGameView(config: GameConfig) -> AnyView
    func getProgressSummary(userId: UUID) -> ModuleProgress
}

struct ModuleRegistry {
    static var modules: [PuzzleModule] = [
        CircuitChallengeModule()
    ]

    static func register(_ module: PuzzleModule) {
        modules.append(module)
    }
}
```

### Hub Services

Modules receive hub services for shared functionality:

```swift
struct HubServices {
    let auth: AuthService
    let coins: CoinService      // V3 stub
    let storage: StorageService
    let sound: SoundService
}

// Module initialization
class CircuitChallengeModule: PuzzleModule {
    private var hubServices: HubServices?

    func initialize(with services: HubServices) {
        self.hubServices = services
    }
}
```

This mirrors the web app's hub-and-spoke architecture.

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
