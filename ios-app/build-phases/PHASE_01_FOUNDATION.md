# Phase 1: Foundation

**Goal:** Set up the Xcode project with proper architecture, design system, and navigation shell.

**Prerequisites:** None - this is the starting phase.

**Estimated Subphases:** 5

---

## Subphase 1.1: Project Setup

### Objective
Create a new Xcode project with SwiftUI, configure for iOS 16+, iPad, and Mac Catalyst support.

### Technical Prompt for Claude Code

```
Create a new iOS app project called "MaxPuzzles" with the following specifications:

PROJECT CONFIGURATION:
- Bundle ID: com.maxpuzzles.app
- Deployment target: iOS 16.0
- Interface: SwiftUI
- Language: Swift
- Include tests: Yes (Unit and UI tests)
- Enable Mac Catalyst: Yes (Designed for iPad)

FOLDER STRUCTURE:
Create this exact folder structure under MaxPuzzles/:

MaxPuzzles/
├── App/
│   ├── MaxPuzzlesApp.swift
│   ├── ContentView.swift
│   └── AppState.swift
├── Core/
│   ├── Models/
│   ├── Services/
│   └── Utilities/
├── Hub/
│   ├── Views/
│   ├── ViewModels/
│   └── Components/
├── Modules/
│   └── CircuitChallenge/
│       ├── Views/
│       ├── ViewModels/
│       ├── Engine/
│       ├── Components/
│       └── Print/
├── Shared/
│   ├── UI/
│   └── Types/
├── Resources/
│   ├── Assets.xcassets
│   └── Sounds/
└── Tests/
    ├── EngineTests/
    ├── ViewModelTests/
    └── IntegrationTests/

APP ENTRY POINT (MaxPuzzlesApp.swift):
```swift
import SwiftUI

@main
struct MaxPuzzlesApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            appState.resumeSession()
        case .inactive:
            appState.pauseSession()
        case .background:
            appState.saveState()
        @unknown default:
            break
        }
    }
}
```

APP STATE (AppState.swift):
```swift
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var isLoading = true
    @Published var currentUser: User?
    @Published var isGuest = true

    func resumeSession() {
        // Resume timer if in game
    }

    func pauseSession() {
        // Pause timer
    }

    func saveState() {
        // Save game state for background
    }
}
```

CONTENT VIEW (ContentView.swift):
```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                SplashView()
            } else {
                MainHubView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
```

INFO.PLIST SETTINGS:
- UILaunchScreen: Use SwiftUI launch screen
- UISupportedInterfaceOrientations: All orientations
- UIRequiresFullScreen: NO (for iPad multitasking)

Verify the project:
1. Builds without errors
2. Runs on iOS Simulator
3. Shows dark background
4. Mac Catalyst target appears in scheme selector
```

### Acceptance Criteria
- [ ] Project builds without errors
- [ ] Folder structure matches specification
- [ ] App launches on iOS Simulator
- [ ] Dark mode is enforced
- [ ] Mac Catalyst is enabled

---

## Subphase 1.2: Theme & Color System

### Objective
Create the complete color palette and theme system matching the web app exactly.

### Technical Prompt for Claude Code

```
Create the theme system for MaxPuzzles iOS app. All colors must match the web app exactly.

FILE: Core/Utilities/Theme.swift

```swift
import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Theme
struct AppTheme {
    // MARK: Hub Colors
    static let backgroundDark = Color(hex: "0f0f23")
    static let backgroundMid = Color(hex: "1a1a3e")
    static let accentPrimary = Color(hex: "22c55e")      // Success green
    static let accentSecondary = Color(hex: "e94560")    // Accent pink/red
    static let accentTertiary = Color(hex: "fbbf24")     // Coins gold
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "a1a1aa")
    static let error = Color(hex: "ef4444")

    // MARK: Circuit Challenge Grid
    static let gridBackgroundTop = Color(hex: "0a0a12")
    static let gridBackgroundBottom = Color(hex: "0d0d18")
    static let connectorDefault = Color(hex: "3d3428")
    static let connectorActive = Color(hex: "00dd77")
    static let connectorGlow = Color(hex: "00ff88")
    static let heartsActive = Color(hex: "ff3366")
    static let heartsInactive = Color(hex: "2a2a3a")

    // MARK: Cell States - Normal
    static let cellNormalTop1 = Color(hex: "3a3a4a")
    static let cellNormalTop2 = Color(hex: "252530")
    static let cellNormalEdge1 = Color(hex: "1a1a25")
    static let cellNormalEdge2 = Color(hex: "0f0f15")
    static let cellNormalBorder = Color(hex: "4a4a5a")

    // MARK: Cell States - Start
    static let cellStartTop1 = Color(hex: "15803d")
    static let cellStartTop2 = Color(hex: "0d5025")
    static let cellStartBorder = Color(hex: "00ff88")

    // MARK: Cell States - Finish
    static let cellFinishTop1 = Color(hex: "ca8a04")
    static let cellFinishTop2 = Color(hex: "854d0e")
    static let cellFinishBorder = Color(hex: "ffcc00")
    static let cellFinishText = Color(hex: "ffdd44")

    // MARK: Cell States - Current
    static let cellCurrentTop1 = Color(hex: "0d9488")
    static let cellCurrentTop2 = Color(hex: "086560")
    static let cellCurrentBorder = Color(hex: "00ffcc")

    // MARK: Cell States - Visited
    static let cellVisitedTop1 = Color(hex: "1a5c38")
    static let cellVisitedTop2 = Color(hex: "103822")
    static let cellVisitedBorder = Color(hex: "00ff88")

    // MARK: Cell States - Wrong
    static let cellWrongTop = Color(hex: "ef4444")
    static let cellWrongBorder = Color(hex: "dc2626")

    // MARK: Connector Badge
    static let connectorBadgeBackground = Color(hex: "15151f")
    static let connectorBadgeText = Color(hex: "ff9f43")

    // MARK: Gradients
    static var gridBackground: LinearGradient {
        LinearGradient(
            colors: [gridBackgroundTop, Color(hex: "12121f"), gridBackgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var splashBackground: LinearGradient {
        LinearGradient(
            colors: [backgroundDark, backgroundMid],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Typography
struct AppTypography {
    static let titleLarge = Font.system(size: 32, weight: .bold)
    static let titleMedium = Font.system(size: 24, weight: .bold)
    static let titleSmall = Font.system(size: 20, weight: .semibold)
    static let bodyLarge = Font.system(size: 18, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .regular)
    static let bodySmall = Font.system(size: 14, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let cellExpression = Font.system(size: 14, weight: .bold)
    static let connectorBadge = Font.system(size: 14, weight: .bold)
}

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Animation Durations
struct AppAnimation {
    static let fast: Double = 0.15
    static let normal: Double = 0.3
    static let slow: Double = 0.5
    static let energyFlowFast: Double = 0.8
    static let energyFlowSlow: Double = 1.2
    static let cellPulse: Double = 1.5
    static let visitedPulse: Double = 2.0
    static let heartPulse: Double = 1.2
}
```

Create a preview file to verify colors:

FILE: Core/Utilities/ThemePreview.swift

```swift
import SwiftUI

struct ThemePreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hub Colors
                colorSection("Hub Colors", colors: [
                    ("backgroundDark", AppTheme.backgroundDark),
                    ("backgroundMid", AppTheme.backgroundMid),
                    ("accentPrimary", AppTheme.accentPrimary),
                    ("accentSecondary", AppTheme.accentSecondary),
                    ("accentTertiary", AppTheme.accentTertiary),
                ])

                // Cell States
                colorSection("Cell States", colors: [
                    ("Normal", AppTheme.cellNormalTop1),
                    ("Start", AppTheme.cellStartTop1),
                    ("Finish", AppTheme.cellFinishTop1),
                    ("Current", AppTheme.cellCurrentTop1),
                    ("Visited", AppTheme.cellVisitedTop1),
                    ("Wrong", AppTheme.cellWrongTop),
                ])

                // Connectors
                colorSection("Connectors", colors: [
                    ("Default", AppTheme.connectorDefault),
                    ("Active", AppTheme.connectorActive),
                    ("Glow", AppTheme.connectorGlow),
                ])
            }
            .padding()
        }
        .background(AppTheme.backgroundDark)
    }

    func colorSection(_ title: String, colors: [(String, Color)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)

            ForEach(colors, id: \.0) { name, color in
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: 40, height: 40)
                    Text(name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
}

#Preview {
    ThemePreview()
}
```

Verify in Xcode preview that all colors render correctly.
```

### Acceptance Criteria
- [ ] All color hex values match web app exactly
- [ ] Theme preview shows all colors correctly
- [ ] Gradients render properly
- [ ] Typography scales defined

---

## Subphase 1.3: UI Components - Buttons

### Objective
Create reusable button components matching the web app design system.

### Technical Prompt for Claude Code

```
Create the button components for MaxPuzzles. Match the web app styling exactly.

FILE: Shared/UI/PrimaryButton.swift

```swift
import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool

    @State private var isHovered = false
    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .frame(minWidth: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.accentPrimary,
                                AppTheme.accentPrimary.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.accentPrimary.opacity(0.5), lineWidth: 1)
            )
            .shadow(
                color: AppTheme.accentPrimary.opacity(isHovered ? 0.4 : 0.2),
                radius: isHovered ? 12 : 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: AppAnimation.fast)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton("Play Now", icon: "play.fill") { }
        PrimaryButton("Loading...", isLoading: true) { }
        PrimaryButton("Disabled", isDisabled: true) { }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
```

FILE: Shared/UI/SecondaryButton.swift

```swift
import SwiftUI

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isDisabled: Bool

    @State private var isHovered = false
    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }

                Text(title)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)
            }
            .foregroundColor(AppTheme.textPrimary)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .frame(minWidth: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.backgroundMid)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .brightness(isHovered ? 0.1 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: AppAnimation.fast)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        SecondaryButton("Settings", icon: "gear") { }
        SecondaryButton("Cancel") { }
        SecondaryButton("Disabled", isDisabled: true) { }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
```

FILE: Shared/UI/IconButton.swift

```swift
import SwiftUI

struct IconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    init(
        _ icon: String,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(AppTheme.backgroundMid)
                )
                .overlay(
                    Circle()
                        .stroke(AppTheme.textSecondary.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.9 : (isHovered ? 1.05 : 1.0))
                .shadow(
                    color: isHovered ? AppTheme.accentPrimary.opacity(0.3) : .clear,
                    radius: 8
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    HStack(spacing: 20) {
        IconButton("arrow.left") { }
        IconButton("gear") { }
        IconButton("arrow.clockwise") { }
        IconButton("printer") { }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
```

Ensure all buttons:
1. Have hover effects (for iPad trackpad/Mac)
2. Have press effects
3. Support disabled state
4. Match the dark cosmic theme
```

### Acceptance Criteria
- [ ] PrimaryButton renders with green gradient
- [ ] SecondaryButton renders with outline style
- [ ] IconButton renders as circular button
- [ ] Hover effects work on iPad/Mac
- [ ] Press animations work

---

## Subphase 1.4: UI Components - Cards & Layout

### Objective
Create card components and layout helpers.

### Technical Prompt for Claude Code

```
Create card and layout components for MaxPuzzles.

FILE: Shared/UI/CardView.swift

```swift
import SwiftUI

struct CardView<Content: View>: View {
    let content: Content
    let padding: CGFloat

    init(
        padding: CGFloat = AppSpacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.backgroundMid)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    CardView {
        VStack(alignment: .leading, spacing: 8) {
            Text("Circuit Challenge")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)
            Text("Path-finding puzzle with arithmetic")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
```

FILE: Shared/UI/ModuleCardView.swift

```swift
import SwiftUI

struct ModuleCardView: View {
    let title: String
    let description: String
    let iconName: String
    let isLocked: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: {
            if !isLocked { action() }
        }) {
            VStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.accentPrimary.opacity(0.3),
                                    AppTheme.accentPrimary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: iconName)
                        .font(.system(size: 36))
                        .foregroundColor(AppTheme.accentPrimary)
                }

                // Title
                Text(title)
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)

                // Description
                Text(description)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Lock indicator or play button
                if isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                        Text("Coming Soon")
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                } else {
                    Text("Play")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentPrimary)
                }
            }
            .padding(AppSpacing.lg)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.backgroundMid)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isHovered && !isLocked ? AppTheme.accentPrimary.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: isHovered && !isLocked ? 2 : 1
                    )
            )
            .shadow(
                color: isHovered && !isLocked ? AppTheme.accentPrimary.opacity(0.2) : .black.opacity(0.2),
                radius: isHovered ? 15 : 10
            )
            .scaleEffect(isHovered && !isLocked ? 1.02 : 1.0)
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: AppAnimation.fast), value: isHovered)
    }
}

#Preview {
    HStack(spacing: 20) {
        ModuleCardView(
            title: "Circuit Challenge",
            description: "Path-finding puzzle with arithmetic",
            iconName: "bolt.fill",
            isLocked: false
        ) { }

        ModuleCardView(
            title: "Number Maze",
            description: "Coming in V2",
            iconName: "square.grid.3x3",
            isLocked: true
        ) { }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
```

FILE: Shared/UI/StarryBackground.swift

```swift
import SwiftUI

struct StarryBackground: View {
    let starCount: Int

    init(starCount: Int = 80) {
        self.starCount = starCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                AppTheme.gridBackground

                // Stars
                ForEach(0..<starCount, id: \.self) { index in
                    StarView(
                        seed: index,
                        bounds: geometry.size
                    )
                }

                // Ambient green glow
                AppTheme.connectorGlow.opacity(0.03)
            }
        }
        .ignoresSafeArea()
    }
}

struct StarView: View {
    let seed: Int
    let bounds: CGSize

    @State private var opacity: Double = 0.3

    private var position: CGPoint {
        // Use seed for deterministic random position
        let x = CGFloat((seed * 7919) % 1000) / 1000.0 * bounds.width
        let y = CGFloat((seed * 6271) % 1000) / 1000.0 * bounds.height
        return CGPoint(x: x, y: y)
    }

    private var size: CGFloat {
        CGFloat((seed * 3571) % 3 + 1)
    }

    private var animationDuration: Double {
        Double((seed * 2311) % 20 + 30) / 10.0  // 3-5 seconds
    }

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .position(position)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
                    .delay(Double(seed % 50) * 0.1)
                ) {
                    opacity = 0.8
                }
            }
    }
}

#Preview {
    StarryBackground()
}
```

FILE: Shared/UI/CoinDisplay.swift

```swift
import SwiftUI

struct CoinDisplay: View {
    let amount: Int
    let showPlus: Bool
    let size: CoinDisplaySize

    enum CoinDisplaySize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            case .large: return 28
            }
        }

        var font: Font {
            switch self {
            case .small: return AppTypography.bodySmall
            case .medium: return AppTypography.bodyMedium
            case .large: return AppTypography.titleSmall
            }
        }
    }

    init(_ amount: Int, showPlus: Bool = false, size: CoinDisplaySize = .medium) {
        self.amount = amount
        self.showPlus = showPlus
        self.size = size
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: size.iconSize))
                .foregroundColor(AppTheme.accentTertiary)

            Text(showPlus && amount > 0 ? "+\(amount)" : "\(amount)")
                .font(size.font)
                .fontWeight(.bold)
                .foregroundColor(showPlus && amount > 0 ? AppTheme.accentPrimary : AppTheme.textPrimary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CoinDisplay(1234, size: .small)
        CoinDisplay(1234, size: .medium)
        CoinDisplay(1234, size: .large)
        CoinDisplay(80, showPlus: true, size: .medium)
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
```
```

### Acceptance Criteria
- [ ] CardView renders with proper styling
- [ ] ModuleCardView has hover effects
- [ ] StarryBackground animates correctly
- [ ] CoinDisplay shows coin icon and amount

---

## Subphase 1.5: Navigation Shell

### Objective
Create the basic navigation structure with placeholder views.

### Technical Prompt for Claude Code

```
Create the navigation shell for MaxPuzzles with placeholder screens.

FILE: App/Navigation/AppRouter.swift

```swift
import SwiftUI

enum AppRoute: Hashable {
    case splash
    case hub
    case login
    case familySelect
    case pinEntry(childId: UUID)
    case settings
    case parentDashboard

    // Circuit Challenge routes
    case circuitChallengeMenu
    case circuitChallengeSetup
    case circuitChallengeGame(difficulty: Int, isCustom: Bool)
    case circuitChallengeSummary
    case circuitChallengePuzzleMaker
}

@MainActor
class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func replace(with route: AppRoute) {
        path = NavigationPath()
        path.append(route)
    }
}
```

FILE: Hub/Views/SplashView.swift

```swift
import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8

    var body: some View {
        ZStack {
            AppTheme.splashBackground
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                // App icon placeholder
                ZStack {
                    // Hex shape placeholder
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 120))
                        .foregroundColor(AppTheme.accentPrimary.opacity(0.3))

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.connectorGlow)
                }
                .scaleEffect(scale)

                Text("Max's Puzzles")
                    .font(AppTypography.titleLarge)
                    .foregroundColor(AppTheme.textPrimary)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
                scale = 1
            }

            // Simulate loading, then transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    appState.isLoading = false
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AppState())
}
```

FILE: Hub/Views/MainHubView.swift

```swift
import SwiftUI

struct MainHubView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                StarryBackground()

                VStack(spacing: AppSpacing.xl) {
                    // Header
                    HStack {
                        Text("Max's Puzzles")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        // Coins (V3 stub - shows 0)
                        CoinDisplay(0, size: .medium)

                        IconButton("gear") {
                            router.navigate(to: .settings)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer()

                    // Module cards
                    VStack(spacing: AppSpacing.lg) {
                        Text("Choose a Puzzle")
                            .font(AppTypography.titleSmall)
                            .foregroundColor(AppTheme.textSecondary)

                        ModuleCardView(
                            title: "Circuit Challenge",
                            description: "Path-finding puzzle with arithmetic",
                            iconName: "bolt.fill",
                            isLocked: false
                        ) {
                            router.navigate(to: .circuitChallengeMenu)
                        }
                    }

                    Spacer()

                    // Guest mode indicator
                    if appState.isGuest {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "person.fill.questionmark")
                            Text("Playing as Guest")
                            Text("•")
                            Button("Create Account") {
                                router.navigate(to: .login)
                            }
                            .foregroundColor(AppTheme.accentPrimary)
                        }
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.bottom, AppSpacing.lg)
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
        }
        .environmentObject(router)
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .settings:
            SettingsPlaceholderView()
        case .login:
            LoginPlaceholderView()
        case .circuitChallengeMenu:
            CircuitChallengeMenuPlaceholderView()
        case .circuitChallengeSetup:
            QuickPlaySetupPlaceholderView()
        default:
            PlaceholderView(title: "Coming Soon")
        }
    }
}

// MARK: - Placeholder Views

struct PlaceholderView: View {
    let title: String
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            StarryBackground()

            VStack(spacing: AppSpacing.lg) {
                Text(title)
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                SecondaryButton("Back", icon: "arrow.left") {
                    router.pop()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct SettingsPlaceholderView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            StarryBackground()

            VStack(spacing: AppSpacing.lg) {
                Text("Settings")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Coming in Phase 5")
                    .foregroundColor(AppTheme.textSecondary)

                SecondaryButton("Back", icon: "arrow.left") {
                    router.pop()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct LoginPlaceholderView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            StarryBackground()

            VStack(spacing: AppSpacing.lg) {
                Text("Login / Sign Up")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Coming in Phase 6")
                    .foregroundColor(AppTheme.textSecondary)

                SecondaryButton("Back", icon: "arrow.left") {
                    router.pop()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct CircuitChallengeMenuPlaceholderView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            StarryBackground()

            VStack(spacing: AppSpacing.lg) {
                Text("Circuit Challenge")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                PrimaryButton("Quick Play", icon: "play.fill") {
                    router.navigate(to: .circuitChallengeSetup)
                }

                SecondaryButton("Back to Hub", icon: "arrow.left") {
                    router.pop()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct QuickPlaySetupPlaceholderView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            StarryBackground()

            VStack(spacing: AppSpacing.lg) {
                Text("Quick Play Setup")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Difficulty selection coming in Phase 4")
                    .foregroundColor(AppTheme.textSecondary)

                SecondaryButton("Back", icon: "arrow.left") {
                    router.pop()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    MainHubView()
        .environmentObject(AppState())
}
```

Update ContentView.swift to use the navigation:

FILE: App/ContentView.swift (update)

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                SplashView()
            } else {
                MainHubView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
```

Test the navigation:
1. App launches to splash
2. Splash animates and transitions to hub
3. Can navigate to Circuit Challenge menu
4. Can navigate to Quick Play setup
5. Back buttons work correctly
6. Settings placeholder accessible
```

### Acceptance Criteria
- [ ] Splash screen shows and animates
- [ ] Transition to main hub works
- [ ] Navigation to module menu works
- [ ] Back navigation works
- [ ] All placeholders render correctly
- [ ] Starry background visible throughout

---

## Phase 1 Completion Checklist

- [ ] Project compiles without errors
- [ ] All folders created per structure
- [ ] Theme colors match web app exactly
- [ ] All button components working
- [ ] Card components rendering
- [ ] Starry background animating
- [ ] Navigation flow working
- [ ] Splash → Hub transition working
- [ ] Guest mode indicator showing
- [ ] Mac Catalyst build works

---

## Files Created in Phase 1

```
MaxPuzzles/
├── App/
│   ├── MaxPuzzlesApp.swift
│   ├── ContentView.swift
│   ├── AppState.swift
│   └── Navigation/
│       └── AppRouter.swift
├── Core/
│   └── Utilities/
│       ├── Theme.swift
│       └── ThemePreview.swift
├── Hub/
│   └── Views/
│       ├── SplashView.swift
│       └── MainHubView.swift
├── Shared/
│   └── UI/
│       ├── PrimaryButton.swift
│       ├── SecondaryButton.swift
│       ├── IconButton.swift
│       ├── CardView.swift
│       ├── ModuleCardView.swift
│       ├── StarryBackground.swift
│       └── CoinDisplay.swift
└── Resources/
    └── Assets.xcassets
```

---

*End of Phase 1*
