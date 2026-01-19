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
7. [iPad Optimization](#ipad-optimization)
8. [Implementation Phases](#implementation-phases)
9. [Data & Storage](#data--storage)
10. [API Integration](#api-integration)
11. [Testing Strategy](#testing-strategy)
12. [App Store Requirements](#app-store-requirements)

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
// CSS: connectorPulse opacity 0.5 → 0.8 over 1.5s
struct TraversedConnectorView: View {
    @State private var flowPhase1: CGFloat = 0
    @State private var flowPhase2: CGFloat = 0
    @State private var glowIntensity: CGFloat = 0.5  // Start at 0.5 (CSS min)

    var body: some View {
        ZStack {
            // Layer 1: Glow (18px, blurred) - pulses 0.5 → 0.8 opacity
            connectorPath
                .stroke(Color(hex: "00ff88").opacity(glowIntensity), lineWidth: 18)
                .blur(radius: 8)

            // Layer 2: Main line (10px)
            connectorPath
                .stroke(Color(hex: "00dd77"), lineWidth: 10)

            // Layer 3: Energy particles 2 (6px, slower, 1.2s)
            connectorPath
                .stroke(
                    Color(hex: "88ffcc"),
                    style: StrokeStyle(lineWidth: 6, dash: [6, 30], dashPhase: flowPhase2)
                )

            // Layer 4: Energy particles 1 (4px, faster, 0.8s)
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
            // Energy flow animation - dashOffset 0 → -36
            // Fast particles (0.8s linear infinite)
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                flowPhase1 = -36
            }
            // Slow particles (1.2s linear infinite)
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                flowPhase2 = -36
            }
            // Glow pulse (1.5s ease-in-out infinite) - opacity 0.5 → 0.8
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
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

#### Cell Pulse Animations (EXACT from animations.css)

The current/start cell has **TWO** simultaneous animations:
1. **cellPulse**: Multi-layer drop-shadow glow (1s cycle)
2. **strokePulse**: Overlay stroke width 2px → 6px (1s cycle)

```swift
// Current/Start cell - DUAL animation effect (1s cycle each)
// Color: #00ffc8 (cyan-green)

struct CurrentCellPulse: ViewModifier {
    @State private var phase: CGFloat = 0  // 0 = min, 1 = max

    func body(content: Content) -> some View {
        content
            // Multi-layer drop shadow (matches CSS filter exactly)
            // Min: drop-shadow(0 0 8px rgba(0,255,200,0.4)) drop-shadow(0 0 15px rgba(0,255,200,0.2))
            // Max: drop-shadow(0 0 20px rgba(0,255,200,1)) drop-shadow(0 0 40px rgba(0,255,200,0.8)) drop-shadow(0 0 60px rgba(0,255,200,0.4))
            .shadow(
                color: Color(hex: "00ffc8").opacity(phase == 0 ? 0.4 : 1.0),
                radius: phase == 0 ? 8 : 20
            )
            .shadow(
                color: Color(hex: "00ffc8").opacity(phase == 0 ? 0.2 : 0.8),
                radius: phase == 0 ? 15 : 40
            )
            .shadow(
                color: Color(hex: "00ffc8").opacity(phase == 0 ? 0 : 0.4),
                radius: phase == 0 ? 0 : 60
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    phase = 1
                }
            }
    }
}

// Stroke pulse overlay for current/start cell (runs simultaneously with above)
struct CurrentCellStrokePulse: ViewModifier {
    @State private var strokeWidth: CGFloat = 2
    @State private var strokeOpacity: CGFloat = 0.3

    func body(content: Content) -> some View {
        content
            .overlay(
                HexagonShape()
                    .stroke(Color(hex: "00ffc8").opacity(strokeOpacity), lineWidth: strokeWidth)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    strokeWidth = 6
                    strokeOpacity = 1.0
                }
            }
    }
}

// Visited cell pulse (2s cycle) - matches visitedPulse keyframes
// Color: #00ff88 (green)
struct VisitedCellPulse: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            // Min: drop-shadow(0 0 8px rgba(0,255,136,0.3))
            // Max: drop-shadow(0 0 20px rgba(0,255,136,0.6))
            .shadow(
                color: Color(hex: "00ff88").opacity(phase == 0 ? 0.3 : 0.6),
                radius: phase == 0 ? 8 : 20
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    phase = 1
                }
            }
    }
}
```

**Animation Timing Summary (from animations.css):**
| Animation | Duration | Easing |
|-----------|----------|--------|
| cellPulse (current/start glow) | 1.0s | ease-in-out |
| strokePulse (current/start stroke) | 1.0s | ease-in-out |
| visitedPulse | 2.0s | ease-in-out |
| heartPulse | 1.2s | ease-in-out |
| electricFlow (fast) | 0.8s | linear |
| electricFlow (slow) | 1.2s | linear |
| connectorPulse | 1.5s | ease-in-out |
| twinkle (stars) | 3-5s (random) | ease-in-out |

#### Hearts Pulse & Break Animations

```swift
// Active hearts pulse (1.2s heartbeat) - scale 1 → 1.15
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

// Heart break animation (0.5s) - plays when losing a life
struct HeartBreak: ViewModifier {
    @State private var phase: Int = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scaleForPhase)
            .rotationEffect(.degrees(rotationForPhase))
            .opacity(opacityForPhase)
            .onAppear {
                // Sequence: scale up, shrink + rotate, fade, restore
                withAnimation(.easeOut(duration: 0.5)) {
                    phase = 4
                }
            }
    }

    var scaleForPhase: CGFloat {
        switch phase {
        case 0: return 1.0
        case 1: return 1.3
        case 2: return 0.8
        case 3: return 0.5
        default: return 1.0
        }
    }

    var rotationForPhase: Double {
        switch phase {
        case 2: return 10
        case 3: return -10
        default: return 0
        }
    }

    var opacityForPhase: Double {
        phase == 3 ? 0.5 : 1.0
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

#### Screen Shake Animation (Wrong Answer)

```swift
// Screen shake for wrong answer (0.3s, 5 oscillations)
struct ScreenShake: ViewModifier {
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
    }

    func shake() {
        // Oscillate: 0 → -5 → 5 → -5 → 5 → -5 → 5 → -5 → 5 → 0
        withAnimation(.easeOut(duration: 0.3)) {
            // Use keyframe animation in iOS 17+
            // Or approximate with spring animation
        }
    }
}

// iOS 17+ version with keyframes
struct ScreenShakeKeyframes: ViewModifier {
    var trigger: Bool

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { view, value in
                view.offset(x: value)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(0, duration: 0.03)
                    LinearKeyframe(-5, duration: 0.03)
                    LinearKeyframe(5, duration: 0.03)
                    LinearKeyframe(-5, duration: 0.03)
                    LinearKeyframe(5, duration: 0.03)
                    LinearKeyframe(-5, duration: 0.03)
                    LinearKeyframe(5, duration: 0.03)
                    LinearKeyframe(-5, duration: 0.03)
                    LinearKeyframe(5, duration: 0.03)
                    LinearKeyframe(0, duration: 0.03)
                }
            }
    }
}
```

#### Coin Float Animations

```swift
// Coin earned - float up and fade (0.8s)
struct CoinFloatUp: ViewModifier {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    offset = -30
                    opacity = 0
                }
            }
    }
}

// Coin lost - float down and fade (0.8s)
struct CoinFloatDown: ViewModifier {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    offset = 20
                    opacity = 0
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

### 3. View Solution Feature (Complete Implementation)

The View Solution feature allows players to see the correct path after losing.

**User Flow:**
1. Player runs out of lives (5 mistakes in standard mode)
2. Summary screen shows "Out of Lives" with "See Solution" button
3. Tapping "See Solution" returns to game screen with `showSolution: true`
4. Entire solution path displays with electric flow animation
5. Game is in view-only mode (no interaction)

**Summary Screen (SummaryView.swift):**

```swift
// Game Over screen - show "See Solution" button
struct GameOverView: View {
    let puzzle: Puzzle
    let difficulty: DifficultySettings
    let correctMoves: Int
    let coins: Int

    @EnvironmentObject var router: Router

    var body: some View {
        VStack(spacing: 24) {
            Text("💔").font(.system(size: 60))
            Text("Out of Lives")
                .font(.title.bold())

            Text("You made \(correctMoves) correct moves before running out of lives.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Coins: +\(coins)")
                .font(.title2)

            VStack(spacing: 12) {
                Button("Try Again") {
                    router.navigate(to: .game(difficulty: difficulty))
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("See Solution") {
                    router.navigate(to: .game(
                        difficulty: difficulty,
                        showSolution: true,
                        puzzle: puzzle  // Pass same puzzle to show solution
                    ))
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("Exit") {
                    router.navigate(to: .moduleMenu)
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
    }
}
```

**PuzzleGrid Implementation:**

```swift
struct PuzzleGridView: View {
    let puzzle: Puzzle
    let currentPosition: Coordinate
    let visitedCells: [Coordinate]
    let traversedConnectors: [(Coordinate, Coordinate)]
    let showSolution: Bool  // When true, show entire solution path
    let onCellTap: ((Coordinate) -> Void)?

    // Check if connector is on the solution path
    private func isConnectorOnSolutionPath(cellA: Coordinate, cellB: Coordinate) -> Bool {
        let path = puzzle.solution.path
        for i in 0..<(path.count - 1) {
            let from = path[i]
            let to = path[i + 1]
            // Check both directions (connectors are bidirectional)
            if (from == cellA && to == cellB) || (from == cellB && to == cellA) {
                return true
            }
        }
        return false
    }

    // Connector is "traversed" if player walked it OR if showing solution
    private func isConnectorTraversed(cellA: Coordinate, cellB: Coordinate) -> Bool {
        // If showing solution, highlight all solution path connectors
        if showSolution && isConnectorOnSolutionPath(cellA: cellA, cellB: cellB) {
            return true
        }
        // Otherwise check if player actually traversed it
        return traversedConnectors.contains { tc in
            (tc.0 == cellA && tc.1 == cellB) || (tc.0 == cellB && tc.1 == cellA)
        }
    }

    // Get traversal direction for animation flow
    private func getTraversalDirection(cellA: Coordinate, cellB: Coordinate) -> (from: Coordinate, to: Coordinate)? {
        // Check player's actual traversal first
        if let match = traversedConnectors.first(where: { tc in
            (tc.0 == cellA && tc.1 == cellB) || (tc.0 == cellB && tc.1 == cellA)
        }) {
            return (from: match.0, to: match.1)
        }

        // If showing solution, get direction from solution path
        if showSolution {
            let path = puzzle.solution.path
            for i in 0..<(path.count - 1) {
                let from = path[i]
                let to = path[i + 1]
                if (from == cellA && to == cellB) || (from == cellB && to == cellA) {
                    return (from: from, to: to)
                }
            }
        }
        return nil
    }

    var body: some View {
        // When showSolution is true:
        // - All solution path connectors render with electric flow animation
        // - All cells on solution path show as "visited" state (green, pulsing)
        // - onCellTap is disabled (view-only mode)
        // - Grid displays instantly (no step-by-step animation)

        Canvas { context, size in
            // Render connectors
            for connector in puzzle.connectors {
                let isTraversed = isConnectorTraversed(
                    cellA: connector.cellA,
                    cellB: connector.cellB
                )
                // If traversed, use electric flow animation
                // Otherwise use default brown connector
            }

            // Render cells
            for (row, cells) in puzzle.grid.enumerated() {
                for (col, cell) in cells.enumerated() {
                    let coord = Coordinate(row: row, col: col)
                    let state = getCellState(coord)
                    // Render hex cell with appropriate state
                }
            }
        }
    }

    private func getCellState(_ coord: Coordinate) -> CellState {
        // When showing solution, mark all path cells as visited
        if showSolution && puzzle.solution.path.contains(coord) {
            if coord == Coordinate(row: 0, col: 0) { return .visited }  // START
            if coord == puzzle.finishCoord { return .finish }
            return .visited
        }
        // Normal state logic...
    }
}
```

**Key Points:**
- Pass the SAME puzzle to the game view when showing solution (don't generate new)
- All solution path connectors display electric flow animation simultaneously
- All cells on path show as visited (green with 2s pulse)
- Disable all touch interaction when `showSolution: true`
- User can only go back or try again from the solution view

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
