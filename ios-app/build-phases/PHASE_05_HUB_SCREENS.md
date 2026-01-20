# Phase 5: Hub Screens

**Objective:** Implement the hub navigation screens including splash, main hub, module selection, settings, and the Circuit Challenge module menu.

**Dependencies:** Phase 1 (Foundation), Phase 3 (Grid Rendering for StarryBackground)

---

## Subphase 5.1: Starry Background

**Goal:** Create the animated starry background used throughout the app.

### Prompt for Claude Code:

```
Create the StarryBackgroundView for Max's Puzzles iOS app.

Create file: Shared/Views/StarryBackgroundView.swift

Implement a starry background with twinkling stars:

```swift
import SwiftUI

/// Individual star data
struct Star: Identifiable {
    let id: Int
    let x: CGFloat // Percentage 0-100
    let y: CGFloat // Percentage 0-100
    let size: CGFloat // 1, 2, or 3 points
    let twinkleDuration: Double // 3-5 seconds
    let twinkleDelay: Double // 0-5 seconds
}

/// Generate random stars
func generateStars(count: Int = 80) -> [Star] {
    (0..<count).map { i in
        let sizeRandom = Double.random(in: 0...1)
        let size: CGFloat = sizeRandom < 0.6 ? 1 : (sizeRandom < 0.9 ? 2 : 3)

        return Star(
            id: i,
            x: CGFloat.random(in: 0...100),
            y: CGFloat.random(in: 0...100),
            size: size,
            twinkleDuration: Double.random(in: 3...5),
            twinkleDelay: Double.random(in: 0...5)
        )
    }
}

/// Starry background for game screens
struct StarryBackgroundView: View {
    let starCount: Int

    @State private var stars: [Star] = []

    init(starCount: Int = 80) {
        self.starCount = starCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "0a0a12"),
                        Color(hex: "12121f"),
                        Color(hex: "0d0d18")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Ambient glow
                RadialGradient(
                    colors: [
                        Color(hex: "00ff80").opacity(0.03),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.5
                )

                // Stars
                ForEach(stars) { star in
                    TwinklingStar(star: star, containerSize: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            stars = generateStars(count: starCount)
        }
    }
}

/// Individual twinkling star
struct TwinklingStar: View {
    let star: Star
    let containerSize: CGSize

    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: star.size, height: star.size)
            .opacity(opacity)
            .position(
                x: containerSize.width * star.x / 100,
                y: containerSize.height * star.y / 100
            )
            .onAppear {
                // Start twinkling animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + star.twinkleDelay) {
                    withAnimation(
                        .easeInOut(duration: star.twinkleDuration)
                        .repeatForever(autoreverses: true)
                    ) {
                        opacity = 1.0
                    }
                }
            }
    }
}

#Preview {
    StarryBackgroundView()
}
```

The stars should:
- Be positioned randomly across the screen
- Vary in size (1, 2, or 3 points)
- Twinkle with varying durations and delays
- Sit behind all other content (z-index 0)
```

---

## Subphase 5.2: Splash Screen

**Goal:** Create the splash screen shown when the app launches.

### Prompt for Claude Code:

```
Create the SplashScreenView for Max's Puzzles iOS app.

Create file: Hub/Views/SplashScreenView.swift

Implement the splash screen matching the web app:

```swift
import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var minTimeElapsed = false
    @State private var navigateToNext = false

    // Loading dots animation
    @State private var dotOpacities: [Double] = [0.3, 0.3, 0.3]

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Alien mascot with bounce
                Text("👽")
                    .font(.system(size: 100))
                    .bounce()

                // Title
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Max's")
                            .foregroundColor(.accentPrimary)
                        Text("Puzzles")
                            .foregroundColor(.white)
                    }
                    .font(.system(size: 40, weight: .bold, design: .rounded))

                    Text("Fun maths adventures!")
                        .font(.title3)
                        .foregroundColor(.textSecondary)
                }

                // Loading dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.accentPrimary)
                            .frame(width: 12, height: 12)
                            .opacity(dotOpacities[index])
                    }
                }
                .padding(.top, 40)
            }
            .opacity(minTimeElapsed ? 0 : 1)
            .animation(.easeOut(duration: 0.3), value: minTimeElapsed)
        }
        .onAppear {
            startLoadingAnimation()
            startMinimumTimer()
        }
        .onChange(of: minTimeElapsed) { _, elapsed in
            if elapsed && !authManager.isLoading {
                navigateToNext = true
            }
        }
        .onChange(of: authManager.isLoading) { _, loading in
            if !loading && minTimeElapsed {
                navigateToNext = true
            }
        }
        .navigationDestination(isPresented: $navigateToNext) {
            determineDestination()
        }
    }

    private func startLoadingAnimation() {
        // Pulse the dots in sequence
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            if navigateToNext {
                timer.invalidate()
                return
            }

            withAnimation(.easeInOut(duration: 0.3)) {
                for i in 0..<3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                        dotOpacities[i] = dotOpacities[i] == 1.0 ? 0.3 : 1.0
                    }
                }
            }
        }
    }

    private func startMinimumTimer() {
        // Minimum 1.5 seconds display time for branding
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            minTimeElapsed = true
        }
    }

    @ViewBuilder
    private func determineDestination() -> some View {
        if let user = authManager.currentUser, user.role == .parent {
            FamilySelectView()
        } else if authManager.isGuest {
            LoginView()
        } else {
            MainHubView()
        }
    }
}

// MARK: - Bounce Animation Modifier

extension View {
    func bounce() -> some View {
        self.modifier(BounceModifier())
    }
}

struct BounceModifier: ViewModifier {
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = -10
                }
            }
    }
}

#Preview {
    NavigationStack {
        SplashScreenView()
            .environmentObject(AuthManager.preview)
    }
}
```

The splash should:
- Display for minimum 1.5 seconds
- Show alien mascot with subtle bounce animation
- Show loading dots with pulse animation
- Navigate based on auth state when ready
```

---

## Subphase 5.3: Main Hub Screen

**Goal:** Create the main hub - the central navigation point of the app.

### Prompt for Claude Code:

```
Create the MainHubView for Max's Puzzles iOS app.

Create file: Hub/Views/MainHubView.swift

Implement the main hub screen matching the web app:

```swift
import SwiftUI

struct MainHubView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showMenu = false

    private var displayName: String {
        authManager.currentUser?.displayName ?? "Guest"
    }

    private var coins: Int {
        authManager.currentUser?.coins ?? 0
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HubHeader(
                    showMenu: true,
                    showCoins: !authManager.isDemoMode,
                    coins: coins,
                    onMenuTap: { showMenu = true }
                )

                Spacer()

                // Avatar and greeting
                VStack(spacing: 16) {
                    // Avatar (tappable to shop)
                    NavigationLink(destination: ShopView()) {
                        Text("👽")
                            .font(.system(size: 80))
                    }
                    .disabled(authManager.isDemoMode)

                    // Greeting
                    Text("Hi, \(displayName)!")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    // Demo mode indicator
                    if authManager.isDemoMode {
                        Text("Demo Mode - Progress not saved")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                // Main action - PLAY button
                NavigationLink(destination: ModuleSelectView()) {
                    Text("PLAY")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(Color.accentPrimary)
                        .cornerRadius(30)
                        .shadow(color: Color.accentPrimary.opacity(0.4), radius: 10, y: 4)
                }
                .padding(.bottom, 24)

                // Secondary actions
                HStack(spacing: 16) {
                    if !authManager.isDemoMode {
                        NavigationLink(destination: ShopView()) {
                            SecondaryButton(title: "Shop")
                        }
                    }

                    NavigationLink(destination: SettingsView()) {
                        SecondaryButton(title: "Settings", variant: .ghost)
                    }
                }

                Spacer()

                // Guest prompt
                if authManager.isGuest {
                    guestPrompt
                }
            }

            // Side menu
            if showMenu {
                SideMenuView(isPresented: $showMenu)
            }
        }
        .navigationBarHidden(true)
    }

    private var guestPrompt: some View {
        VStack(spacing: 8) {
            Text("Playing as guest - progress saved locally")
                .font(.caption)
                .foregroundColor(.textSecondary)

            NavigationLink(destination: LoginView()) {
                Text("Create Account to Save Progress")
                    .font(.caption)
                    .foregroundColor(.accentPrimary)
            }
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.5))
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    var variant: Variant = .secondary

    enum Variant {
        case secondary, ghost
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                variant == .secondary
                    ? Color.accentSecondary
                    : Color.clear
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: variant == .ghost ? 1 : 0)
            )
    }
}

#Preview {
    NavigationStack {
        MainHubView()
            .environmentObject(AuthManager.preview)
    }
}
```
```

---

## Subphase 5.4: Hub Header Component

**Goal:** Create the reusable header component for hub screens.

### Prompt for Claude Code:

```
Create the HubHeader component for Max's Puzzles iOS app.

Create file: Hub/Views/Components/HubHeader.swift

```swift
import SwiftUI

struct HubHeader: View {
    var title: String? = nil
    var showBack: Bool = false
    var showMenu: Bool = false
    var showCoins: Bool = false
    var coins: Int = 0
    var onMenuTap: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            // Left section
            HStack(spacing: 12) {
                // Back button
                if showBack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.backgroundDark.opacity(0.8))
                            .cornerRadius(12)
                    }
                }

                // Menu button
                if showMenu {
                    Button(action: { onMenuTap?() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.backgroundDark.opacity(0.8))
                            .cornerRadius(12)
                    }
                }

                // Title or Logo
                if let title = title {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                } else {
                    // Logo
                    NavigationLink(destination: ModuleMenuView()) {
                        HStack(spacing: 8) {
                            Text("👽")
                                .font(.title)
                            Text("Max's Puzzles")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
            }

            Spacer()

            // Right section - Coins
            if showCoins {
                CoinDisplayView(amount: coins, size: .small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        HubHeader(showMenu: true, showCoins: true, coins: 150)
        HubHeader(title: "Settings", showBack: true)
        HubHeader(title: "Choose a Puzzle", showBack: true)
    }
    .background(Color.backgroundDark)
}
```
```

---

## Subphase 5.5: Side Menu

**Goal:** Create the slide-out side menu for navigation.

### Prompt for Claude Code:

```
Create the SideMenuView for Max's Puzzles iOS app.

Create file: Hub/Views/Components/SideMenuView.swift

```swift
import SwiftUI

struct SideMenuView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }

            // Drawer
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("Menu")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding()

                    // Menu items
                    VStack(spacing: 4) {
                        MenuLink(
                            destination: AnyView(ModuleSelectView()),
                            icon: "🎮",
                            label: "Play"
                        ) {
                            isPresented = false
                        }

                        MenuLink(
                            destination: AnyView(ShopView()),
                            icon: "🛒",
                            label: "Shop"
                        ) {
                            isPresented = false
                        }

                        MenuLink(
                            destination: AnyView(SettingsView()),
                            icon: "⚙️",
                            label: "Settings"
                        ) {
                            isPresented = false
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .frame(width: 256)
                .background(Color.backgroundMid)

                Spacer()
            }
            .transition(.move(edge: .leading))
        }
        .animation(.easeOut(duration: 0.2), value: isPresented)
    }
}

struct MenuLink<Destination: View>: View {
    let destination: Destination
    let icon: String
    let label: String
    let onTap: () -> Void

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.title2)
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .simultaneousGesture(TapGesture().onEnded {
            onTap()
        })
    }
}

#Preview {
    ZStack {
        Color.backgroundDark.ignoresSafeArea()
        SideMenuView(isPresented: .constant(true))
    }
}
```
```

---

## Subphase 5.6: Module Select Screen

**Goal:** Create the module selection screen showing available puzzle games.

### Prompt for Claude Code:

```
Create the ModuleSelectView for Max's Puzzles iOS app.

Create file: Hub/Views/ModuleSelectView.swift

```swift
import SwiftUI

struct Module: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let available: Bool
    var progress: ModuleProgress?

    struct ModuleProgress {
        let level: Int
        let stars: Int
    }
}

struct ModuleSelectView: View {
    @Environment(\.dismiss) private var dismiss

    private let modules: [Module] = [
        Module(
            id: "circuit-challenge",
            name: "Circuit Challenge",
            description: "Navigate the circuit by solving arithmetic!",
            icon: "⚡",
            available: true,
            progress: Module.ModuleProgress(level: 1, stars: 0)
        ),
        Module(
            id: "coming-soon-1",
            name: "Coming Soon",
            description: "More puzzles on the way!",
            icon: "🔒",
            available: false
        ),
        Module(
            id: "coming-soon-2",
            name: "Coming Soon",
            description: "Stay tuned for new challenges!",
            icon: "🔒",
            available: false
        )
    ]

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HubHeader(title: "Choose a Puzzle", showBack: true)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(modules) { module in
                            ModuleCard(module: module)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct ModuleCard: View {
    let module: Module

    var body: some View {
        Group {
            if module.available {
                NavigationLink(destination: ModuleMenuView()) {
                    cardContent
                }
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        HStack(spacing: 16) {
            // Icon
            Text(module.icon)
                .font(.system(size: 40))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(module.name)
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text(module.description)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                // Progress indicator
                if module.available, let progress = module.progress {
                    HStack(spacing: 8) {
                        // Stars
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { index in
                                Image(systemName: index < (progress.stars / 10) ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }

                        Text("Level \(progress.level)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 4)
                }
            }

            Spacer()

            // Arrow (if available)
            if module.available {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.backgroundMid.opacity(module.available ? 0.8 : 0.4))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .opacity(module.available ? 1 : 0.5)
    }
}

#Preview {
    NavigationStack {
        ModuleSelectView()
    }
}
```
```

---

## Subphase 5.7: Circuit Challenge Module Menu

**Goal:** Create the Circuit Challenge specific menu screen.

### Prompt for Claude Code:

```
Create the ModuleMenuView for Circuit Challenge in the iOS app.

Create file: CircuitChallenge/Views/ModuleMenuView.swift

```swift
import SwiftUI

struct ModuleMenuView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            StarryBackgroundView()

            VStack(spacing: 0) {
                // Header with menu button
                HubHeader(showMenu: true)

                // Title section
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("⚡")
                            .foregroundColor(.accentPrimary)
                        Text("Circuit Challenge")
                    }
                    .font(.title.bold())
                    .foregroundColor(.white)

                    Text("Navigate the circuit!")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom)

                Spacer()

                // Menu Options
                VStack(spacing: 16) {
                    // Quick Play
                    NavigationLink(destination: QuickPlaySetupView { settings in
                        // Navigate to game
                    }) {
                        ModuleMenuCard(
                            icon: "⚡",
                            title: "Quick Play",
                            subtitle: "Play at any difficulty"
                        )
                    }

                    // Progression (V2 - disabled)
                    ModuleMenuCard(
                        icon: "📈",
                        title: "Progression",
                        subtitle: "Coming in V2",
                        locked: true,
                        lockMessage: "30 levels to master"
                    )

                    // Puzzle Maker
                    NavigationLink(destination: PuzzleMakerView()) {
                        ModuleMenuCard(
                            icon: "🖨️",
                            title: "Puzzle Maker",
                            subtitle: "Print puzzles for class"
                        )
                    }
                }
                .padding()

                Spacer()

                // Stats summary
                Text("Games played: 0 | Best streak: 0")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding()
            }
        }
        .navigationBarHidden(true)
    }
}

struct ModuleMenuCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var locked: Bool = false
    var lockMessage: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                if locked, let message = lockMessage {
                    HStack(spacing: 4) {
                        Text("🔒")
                            .font(.caption)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.backgroundMid.opacity(locked ? 0.4 : 0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .opacity(locked ? 0.5 : 1)
    }
}

#Preview {
    NavigationStack {
        ModuleMenuView()
    }
}
```
```

---

## Subphase 5.8: Settings Screen

**Goal:** Create the settings screen for app preferences.

### Prompt for Claude Code:

```
Create the SettingsView for Max's Puzzles iOS app.

Create file: Hub/Views/SettingsView.swift

```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var soundEffects = true
    @State private var music = true
    @State private var animations: AnimationSetting = .full

    enum AnimationSetting: String, CaseIterable {
        case full = "Full"
        case reduced = "Reduced"
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HubHeader(title: "Settings", showBack: true)

                ScrollView {
                    VStack(spacing: 24) {
                        // Audio Settings
                        SettingsCard(title: "Audio") {
                            Toggle("Sound Effects", isOn: $soundEffects)
                                .toggleStyle(SwitchToggleStyle(tint: .accentPrimary))

                            Toggle("Music", isOn: $music)
                                .toggleStyle(SwitchToggleStyle(tint: .accentPrimary))
                        }

                        // Display Settings
                        SettingsCard(title: "Display") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Animations")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)

                                HStack(spacing: 8) {
                                    ForEach(AnimationSetting.allCases, id: \.self) { setting in
                                        Button(action: { animations = setting }) {
                                            Text(setting.rawValue)
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    animations == setting
                                                        ? Color.accentPrimary
                                                        : Color.backgroundDark
                                                )
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }

                        // Account Settings
                        SettingsCard(title: "Account") {
                            if authManager.isGuest {
                                guestAccountSection
                            } else {
                                loggedInAccountSection
                            }
                        }

                        // About Section
                        SettingsCard(title: "About") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Max's Puzzles v1.0.0")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                Text("Made with love for Max")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var guestAccountSection: some View {
        VStack(spacing: 12) {
            Text("Playing as guest. Create an account to save your progress!")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            NavigationLink(destination: LoginView()) {
                Text("Create Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentSecondary)
                    .cornerRadius(8)
            }
        }
    }

    private var loggedInAccountSection: some View {
        VStack(spacing: 12) {
            Text("Logged in as \(authManager.currentUser?.email ?? authManager.currentUser?.displayName ?? "User")")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            NavigationLink(destination: FamilySelectView()) {
                SettingsButton(title: "Switch User")
            }

            Button(action: {
                Task {
                    await authManager.logout()
                    dismiss()
                }
            }) {
                SettingsButton(title: "Log Out")
            }
        }
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }
}

struct SettingsButton: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.backgroundDark)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthManager.preview)
    }
}
```
```

---

## Subphase 5.9: Coin Display Component

**Goal:** Create the coin display component for headers and menus.

### Prompt for Claude Code:

```
Create the CoinDisplayView for Max's Puzzles iOS app.

Create file: Shared/Views/Components/CoinDisplayView.swift

```swift
import SwiftUI

struct CoinDisplayView: View {
    let amount: Int
    var size: DisplaySize = .regular

    enum DisplaySize {
        case small, regular

        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .regular: return .subheadline
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .regular: return 24
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 8
            case .regular: return 12
            }
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            // Coin icon
            Circle()
                .fill(Color.accentTertiary)
                .frame(width: size.iconSize, height: size.iconSize)
                .overlay {
                    Text("$")
                        .font(.system(size: size.iconSize * 0.6, weight: .bold))
                        .foregroundColor(.black)
                }

            // Amount
            Text("\(amount)")
                .font(size.fontSize.monospacedDigit().bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding * 0.75)
        .background(Color.backgroundDark.opacity(0.8))
        .cornerRadius(20)
    }
}

#Preview {
    VStack(spacing: 16) {
        CoinDisplayView(amount: 150, size: .regular)
        CoinDisplayView(amount: 50, size: .small)
        CoinDisplayView(amount: 1000)
    }
    .padding()
    .background(Color.backgroundMid)
}
```
```

---

## Subphase 5.10: Shop Screen (V3 Placeholder)

**Goal:** Create a placeholder shop screen for V3.

### Prompt for Claude Code:

```
Create a placeholder ShopView for Max's Puzzles iOS app.

Create file: Hub/Views/ShopView.swift

This is a V3 feature, so create a placeholder:

```swift
import SwiftUI

struct ShopView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HubHeader(title: "Shop", showBack: true)

                Spacer()

                VStack(spacing: 24) {
                    Text("🛒")
                        .font(.system(size: 80))

                    Text("Coming in V3!")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text("Customize your alien avatar with coins you earn from puzzles!")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        ShopView()
    }
}
```
```

---

## Subphase 5.11: Puzzle Maker Screen (Placeholder)

**Goal:** Create a placeholder for the Puzzle Maker screen.

### Prompt for Claude Code:

```
Create a placeholder PuzzleMakerView for Circuit Challenge iOS app.

Create file: CircuitChallenge/Views/PuzzleMakerView.swift

```swift
import SwiftUI

struct PuzzleMakerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDifficulty: Int = 4
    @State private var puzzleCount: Int = 4
    @State private var isGenerating = false

    var body: some View {
        ZStack {
            StarryBackgroundView()

            VStack(spacing: 0) {
                HubHeader(title: "Puzzle Maker", showBack: true)

                ScrollView {
                    VStack(spacing: 24) {
                        // Info card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("🖨️ Print puzzles for classroom use!")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Generate up to 10 puzzles at once. Each A4 page fits 2 puzzles.")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.backgroundMid.opacity(0.8))
                        .cornerRadius(12)

                        // Difficulty selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Difficulty")
                                .font(.headline)
                                .foregroundColor(.white)

                            Menu {
                                ForEach(0..<10, id: \.self) { index in
                                    Button("Level \(index + 1)") {
                                        selectedDifficulty = index
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Level \(selectedDifficulty + 1)")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color.backgroundDark)
                                .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.backgroundMid.opacity(0.8))
                        .cornerRadius(12)

                        // Puzzle count
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Number of Puzzles")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack(spacing: 8) {
                                ForEach([2, 4, 6, 8, 10], id: \.self) { count in
                                    Button(action: { puzzleCount = count }) {
                                        Text("\(count)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                puzzleCount == count
                                                    ? Color.accentPrimary
                                                    : Color.backgroundDark
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                            }

                            Text("= \(puzzleCount / 2) page\(puzzleCount > 2 ? "s" : "")")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.backgroundMid.opacity(0.8))
                        .cornerRadius(12)

                        // Generate button
                        Button(action: generatePuzzles) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Generate & Print")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentPrimary)
                            .cornerRadius(12)
                        }
                        .disabled(isGenerating)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func generatePuzzles() {
        isGenerating = true
        // TODO: Implement puzzle generation and printing in Phase 8
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isGenerating = false
        }
    }
}

#Preview {
    NavigationStack {
        PuzzleMakerView()
    }
}
```
```

---

## Phase 5 Summary

After completing Phase 5, you will have:

1. **Starry Background** - Animated twinkling stars background
2. **Splash Screen** - Initial loading screen with branding
3. **Main Hub Screen** - Central navigation point
4. **Hub Header** - Reusable header component
5. **Side Menu** - Slide-out navigation drawer
6. **Module Select** - Puzzle game selection
7. **Module Menu** - Circuit Challenge specific menu
8. **Settings Screen** - App preferences
9. **Coin Display** - Reusable coin counter
10. **Shop Screen** - V3 placeholder
11. **Puzzle Maker** - Print puzzles placeholder

**Next Phase:** Phase 6 will implement authentication (Supabase, login, family accounts).
