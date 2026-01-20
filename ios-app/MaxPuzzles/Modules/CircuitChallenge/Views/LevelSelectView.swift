import SwiftUI

// MARK: - Level Select View

/// Shows 5 large hexagon levels arranged horizontally with connectors
/// Current level has green glow pulse animation
struct LevelSelectView: View {
    let chapter: Int
    let alien: ChapterAlien
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var progress: StoryProgress { appState.storyProgress }

    @State private var selectedLevel: Int?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Colorful splash background
                Image("splash_background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // Dark overlay for readability
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Chapter header with alien
                    chapterHeader

                    Spacer()

                    // Horizontal hexagon level path
                    horizontalLevelPath(geometry: geometry)

                    Spacer()

                    // Chapter stats
                    chapterStats
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Chapter \(chapter)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
        .portraitOnPhone()
        .navigationDestination(isPresented: Binding(
            get: { selectedLevel != nil },
            set: { if !$0 { selectedLevel = nil } }
        )) {
            if let level = selectedLevel {
                StoryGameScreenView(
                    chapter: chapter,
                    level: level,
                    alien: alien
                )
            }
        }
    }

    // MARK: - Chapter Header (Top Trumps Style Card)

    private var chapterHeader: some View {
        AlienTopTrumpsCard(alien: alien, chapter: chapter)
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }

    // MARK: - Horizontal Level Path

    private func horizontalLevelPath(geometry: GeometryProxy) -> some View {
        // Calculate sizes to fill the screen width
        let horizontalPadding: CGFloat = 16
        let availableWidth = geometry.size.width - (horizontalPadding * 2)

        // 5 hexagons + 4 connectors
        // connectorWidth = hexSize * 0.25 (proportional)
        // 5 * hexSize + 4 * (hexSize * 0.25) = availableWidth
        // 5 * hexSize + hexSize = availableWidth
        // 6 * hexSize = availableWidth
        let hexSize = availableWidth / 6
        let connectorWidth = hexSize * 0.25

        return HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { level in
                HStack(spacing: 0) {
                    // Hexagon level tile
                    LargeHexTile(
                        level: level,
                        chapter: chapter,
                        isUnlocked: isLevelUnlocked(level),
                        isCompleted: isLevelCompleted(level),
                        isCurrent: isCurrentLevel(level),
                        stars: starsForLevel(level),
                        bestTime: bestTimeForLevel(level),
                        isHiddenMode: isHiddenMode(level: level),
                        hexSize: hexSize,
                        onTap: {
                            if isLevelUnlocked(level) {
                                selectedLevel = level
                            }
                        }
                    )

                    // Connector to next (except for level 5)
                    if level < 5 {
                        HorizontalLevelConnector(
                            isActive: isLevelUnlocked(level + 1),
                            isPulsing: isLevelCompleted(level),
                            width: connectorWidth
                        )
                    }
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 20)
    }

    // MARK: - Chapter Stats

    private var chapterStats: some View {
        let totalStars = progress.starsInChapter(chapter)
        let completedLevels = (1...5).filter { isLevelCompleted($0) }.count

        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(AppTheme.accentTertiary)
                Text("\(totalStars) / 15")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
            }

            Text("\(completedLevels) of 5 levels completed")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    // MARK: - Helpers

    private func isLevelUnlocked(_ level: Int) -> Bool {
        if level == 1 {
            return progress.isChapterUnlocked(chapter)
        }
        let previousStars = progress.starsForLevel(chapter: chapter, level: level - 1)
        return previousStars >= 2
    }

    private func isLevelCompleted(_ level: Int) -> Bool {
        progress.isLevelCompleted(chapter: chapter, level: level)
    }

    private func isCurrentLevel(_ level: Int) -> Bool {
        // Current level is the first unlocked but not completed level
        if !isLevelUnlocked(level) { return false }
        if isLevelCompleted(level) { return false }

        // Check if all previous levels are completed
        for prevLevel in 1..<level {
            if !isLevelCompleted(prevLevel) {
                return false
            }
        }
        return true
    }

    private func starsForLevel(_ level: Int) -> Int {
        progress.starsForLevel(chapter: chapter, level: level)
    }

    private func isHiddenMode(level: Int) -> Bool {
        level == 5 || chapter == 10
    }

    private func bestTimeForLevel(_ level: Int) -> Double? {
        progress.bestTimeForLevel(chapter: chapter, level: level)
    }
}

// MARK: - Large Hex Tile

struct LargeHexTile: View {
    let level: Int
    let chapter: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    let isCurrent: Bool
    let stars: Int
    let bestTime: Double?
    let isHiddenMode: Bool
    let hexSize: CGFloat
    let onTap: () -> Void

    @State private var flowPhase: CGFloat = 0
    @State private var glowPhase: CGFloat = 0

    private var levelLetter: String {
        ["A", "B", "C", "D", "E"][level - 1]
    }

    // Show glow animation for current level OR completed level
    private var shouldPulse: Bool {
        isCurrent || isCompleted
    }

    /// Format seconds into MM:SS display
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // 3D layer offsets (proportional to hex size like game cells)
    private var shadowOffset: CGFloat { hexSize * 0.12 }
    private var edgeOffset: CGFloat { hexSize * 0.1 }
    private var baseOffset: CGFloat { hexSize * 0.05 }

    private var edgeGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "1a1a25"), Color(hex: "0f0f15")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var baseGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "2a2a3a"), Color(hex: "1a1a25")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // 3D Hexagon tile (poker chip style)
                ZStack {
                    // Pulsing glow for current/completed levels
                    if shouldPulse {
                        // Outer glow
                        HexagonShape()
                            .fill(AppTheme.connectorGlow.opacity(0.4))
                            .frame(width: hexSize + 30, height: hexSize + 30)
                            .blur(radius: 15)
                            .opacity(0.5 + glowPhase * 0.5)

                        // Inner glow
                        HexagonShape()
                            .fill(AppTheme.connectorGlow.opacity(0.3))
                            .frame(width: hexSize + 15, height: hexSize + 15)
                            .blur(radius: 8)

                        // Energy border animation
                        HexagonShape()
                            .stroke(
                                AppTheme.connectorGlow,
                                style: StrokeStyle(lineWidth: 4, dash: [8, 12], dashPhase: flowPhase * 40)
                            )
                            .frame(width: hexSize + 10, height: hexSize + 10)

                        // Second energy layer (faster)
                        HexagonShape()
                            .stroke(
                                Color.white.opacity(0.8),
                                style: StrokeStyle(lineWidth: 2, dash: [4, 16], dashPhase: flowPhase * 60)
                            )
                            .frame(width: hexSize + 10, height: hexSize + 10)
                    }

                    // Layer 1: Shadow
                    HexagonShape()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: hexSize, height: hexSize)
                        .offset(x: 3, y: shadowOffset)

                    // Layer 2: Edge (3D depth)
                    HexagonShape()
                        .fill(edgeGradient)
                        .frame(width: hexSize, height: hexSize)
                        .offset(y: edgeOffset)

                    // Layer 3: Base
                    HexagonShape()
                        .fill(baseGradient)
                        .frame(width: hexSize, height: hexSize)
                        .offset(y: baseOffset)

                    // Layer 4: Top face
                    HexagonShape()
                        .fill(hexagonGradient)
                        .frame(width: hexSize, height: hexSize)
                        .overlay(
                            HexagonShape()
                                .stroke(borderColor, lineWidth: shouldPulse ? 3 : 2)
                        )

                    // Layer 5: Inner shadow (radial gradient)
                    HexagonShape()
                        .fill(
                            RadialGradient(
                                colors: [.clear, .clear, Color.black.opacity(0.25)],
                                center: .center,
                                startRadius: 0,
                                endRadius: hexSize * 0.4
                            )
                        )
                        .frame(width: hexSize * 0.9, height: hexSize * 0.9)

                    // Layer 6: Rim highlight
                    HexagonShape()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        .frame(width: hexSize, height: hexSize)

                    // Level number or lock
                    if isUnlocked {
                        VStack(spacing: 4) {
                            Text("\(level)")
                                .font(.system(size: hexSize * 0.4, weight: .black))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)

                            if isHiddenMode {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: hexSize * 0.15))
                                    .foregroundColor(AppTheme.accentSecondary)
                            }
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: hexSize * 0.3))
                            .foregroundColor(.gray)
                    }
                }

                // Stars and best time display
                VStack(spacing: 2) {
                    if isCompleted {
                        LevelStarDisplay(stars: stars, size: .medium)
                        if let time = bestTime {
                            Text(formatTime(time))
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    } else if isUnlocked {
                        LevelStarDisplay(stars: 0, size: .medium)
                    } else {
                        Text("2 stars needed")
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
        .onAppear {
            if shouldPulse {
                // Flow animation for dashed border
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    flowPhase = 1
                }
                // Glow pulse animation
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPhase = 1
                }
            }
        }
    }

    private var hexagonGradient: some ShapeStyle {
        if isCompleted {
            return LinearGradient(
                colors: [AppTheme.accentPrimary, AppTheme.accentPrimary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isCurrent {
            return LinearGradient(
                colors: [Color(hex: "0d9488"), Color(hex: "086560")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isUnlocked {
            return LinearGradient(
                colors: [AppTheme.backgroundMid, AppTheme.backgroundDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var borderColor: Color {
        if isCompleted || isCurrent {
            return AppTheme.connectorGlow
        } else if isUnlocked {
            return AppTheme.accentPrimary.opacity(0.5)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Horizontal Level Connector

/// Game-style electric connector between level hexagons
struct HorizontalLevelConnector: View {
    let isActive: Bool
    let isPulsing: Bool
    let width: CGFloat

    @State private var flowPhase1: CGFloat = 0
    @State private var flowPhase2: CGFloat = 0
    @State private var glowOpacity: CGFloat = 0.5

    // Connector height (thicker for level select)
    private let connectorHeight: CGFloat = 10

    var body: some View {
        ZStack {
            if isPulsing {
                // Layer 1: Glow (blur effect)
                RoundedRectangle(cornerRadius: connectorHeight / 2)
                    .fill(AppTheme.connectorGlow.opacity(glowOpacity))
                    .frame(width: width, height: connectorHeight + 10)
                    .blur(radius: 6)

                // Layer 2: Main line
                RoundedRectangle(cornerRadius: connectorHeight / 2)
                    .fill(Color(hex: "00dd77"))
                    .frame(width: width, height: connectorHeight)

                // Layer 3: Energy flow slow (dash effect)
                RoundedRectangle(cornerRadius: connectorHeight / 2)
                    .fill(Color(hex: "88ffcc"))
                    .frame(width: width, height: connectorHeight - 2)
                    .mask(
                        HStack(spacing: 0) {
                            ForEach(0..<20, id: \.self) { i in
                                let offset = CGFloat(i) * 12 - flowPhase2 * 40
                                Circle()
                                    .frame(width: 6, height: 6)
                                    .offset(x: offset)
                            }
                        }
                        .frame(width: width)
                    )

                // Layer 4: Energy flow fast
                RoundedRectangle(cornerRadius: connectorHeight / 2)
                    .fill(Color.white)
                    .frame(width: width, height: connectorHeight - 4)
                    .mask(
                        HStack(spacing: 0) {
                            ForEach(0..<30, id: \.self) { i in
                                let offset = CGFloat(i) * 8 - flowPhase1 * 50
                                Circle()
                                    .frame(width: 4, height: 4)
                                    .offset(x: offset)
                            }
                        }
                        .frame(width: width)
                    )

                // Layer 5: Bright core
                RoundedRectangle(cornerRadius: connectorHeight / 2)
                    .fill(Color(hex: "aaffcc"))
                    .frame(width: width, height: 3)
            } else if isActive {
                // Active but not pulsing - just green
                RoundedRectangle(cornerRadius: connectorHeight / 2)
                    .fill(AppTheme.connectorActive)
                    .frame(width: width, height: connectorHeight)
            } else {
                // Inactive connector
                RoundedRectangle(cornerRadius: connectorHeight / 2)
                    .fill(AppTheme.connectorDefault)
                    .frame(width: width, height: connectorHeight - 2)
            }
        }
        .frame(width: width, height: 24)
        .onAppear {
            if isPulsing {
                // Energy flow animations
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    flowPhase1 = 1
                }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    flowPhase2 = 1
                }
                // Glow pulse
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.8
                }
            }
        }
    }
}

// MARK: - Story Game Screen View

struct StoryGameScreenView: View {
    let chapter: Int
    let level: Int
    let alien: ChapterAlien
    @Environment(\.dismiss) private var dismiss

    @State private var showIntro = true
    @State private var introScale: CGFloat = 0.5
    @State private var introOpacity: Double = 0

    var body: some View {
        ZStack {
            // Game screen underneath
            let storyLevel = StoryLevel(chapter: chapter, level: level)
            let difficulty = StoryDifficulty.settings(for: storyLevel)

            GameScreenView(
                difficulty: difficulty,
                storyAlien: alien,
                storyChapter: chapter,
                storyLevel: level
            )

            // Level intro overlay
            if showIntro {
                levelIntroOverlay
                    .scaleEffect(introScale)
                    .opacity(introOpacity)
                    .onTapGesture {
                        dismissIntro()
                    }
            }
        }
        .onAppear {
            // Animate intro in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                introScale = 1.0
                introOpacity = 1.0
            }

            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if showIntro {
                    dismissIntro()
                }
            }
        }
    }

    private var levelIntroOverlay: some View {
        ZStack {
            // Dark backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Alien image with bounce animation
                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .alienIdleAnimation(style: .bounce, intensity: 1.0)

                // Speech bubble with intro message (pointing up to alien)
                SpeechBubble(pointsUp: true) {
                    Text(introMessage)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.backgroundDark)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)

                // Level info - use alien name + level number
                Text("\(alien.name) \(level)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                // Tap to continue hint
                Text("Tap to start")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.bottom, 40)
            }
        }
    }

    private var levelLetter: String {
        ["A", "B", "C", "D", "E"][level - 1]
    }

    private var introMessage: String {
        // Use the alien's unique intro messages with personalization
        let playerName = StorageService.shared.playerName
        return alien.personalizedIntroMessage(playerName: playerName)
    }

    private func dismissIntro() {
        withAnimation(.easeOut(duration: 0.3)) {
            introOpacity = 0
            introScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showIntro = false
        }
    }
}

// MARK: - Level Star Display

private struct LevelStarDisplay: View {
    let stars: Int
    let size: LevelStarSize

    enum LevelStarSize {
        case small, medium, large

        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 24
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            ForEach(1...3, id: \.self) { index in
                Image(systemName: index <= stars ? "star.fill" : "star")
                    .font(.system(size: size.fontSize))
                    .foregroundColor(index <= stars ? AppTheme.accentTertiary : Color.gray.opacity(0.4))
            }
        }
    }
}

// MARK: - Alien Top Trumps Card

/// Boxing/Top Trumps style character card for the chapter alien
struct AlienTopTrumpsCard: View {
    let alien: ChapterAlien
    let chapter: Int

    @State private var glowPhase: CGFloat = 0.5

    // Chapter color themes
    private var accentColor: Color {
        switch chapter {
        case 1: return Color(hex: "4ade80")   // Bob - Green
        case 2: return Color(hex: "60a5fa")   // Blink - Blue
        case 3: return Color(hex: "c084fc")   // Drift - Purple
        case 4: return Color(hex: "fb923c")   // Fuzz - Orange
        case 5: return Color(hex: "f472b6")   // Prism - Pink
        case 6: return Color(hex: "fbbf24")   // Nova - Yellow/Gold
        case 7: return Color(hex: "f87171")   // Clicker - Red
        case 8: return Color(hex: "2dd4bf")   // Bolt - Teal
        case 9: return Color(hex: "94a3b8")   // Sage - Silver
        case 10: return Color(hex: "fcd34d")  // Bibomic - Gold
        default: return AppTheme.accentPrimary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left: Large alien image with glow
            ZStack {
                // Glow backdrop
                Circle()
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)
                    .opacity(glowPhase)

                // Alien image
                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .alienIdleAnimation(style: .bounce, intensity: 0.8)
            }

            // Right: Name and traits
            VStack(alignment: .leading, spacing: 6) {
                // Chapter badge
                Text("CHAPTER \(chapter)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.2))
                    .cornerRadius(4)

                // Alien name
                Text(alien.name.uppercased())
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: accentColor.opacity(0.8), radius: 8)
                    .shadow(color: accentColor.opacity(0.5), radius: 4)

                // Trait pills
                HStack(spacing: 6) {
                    ForEach(alien.words, id: \.self) { word in
                        Text(word)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.25))
                            .cornerRadius(8)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.backgroundMid.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(0.5), lineWidth: 2)
                )
        )
        .shadow(color: accentColor.opacity(0.3), radius: 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPhase = 0.8
            }
        }
    }
}

// MARK: - Preview

#Preview("Level Select") {
    NavigationStack {
        LevelSelectView(
            chapter: 1,
            alien: ChapterAlien.all[0]
        )
        .environmentObject(AppState())
    }
}

#Preview("Large Hex Tile - Current") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        LargeHexTile(
            level: 2,
            chapter: 1,
            isUnlocked: true,
            isCompleted: false,
            isCurrent: true,
            stars: 0,
            bestTime: nil,
            isHiddenMode: false,
            hexSize: 90,
            onTap: {}
        )
    }
}

#Preview("Alien Card - Bob") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        AlienTopTrumpsCard(alien: ChapterAlien.all[0], chapter: 1)
            .padding()
    }
}

#Preview("Alien Card - Bibomic") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        AlienTopTrumpsCard(alien: ChapterAlien.all[9], chapter: 10)
            .padding()
    }
}

#Preview("Large Hex Tile - Completed") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        LargeHexTile(
            level: 1,
            chapter: 1,
            isUnlocked: true,
            isCompleted: true,
            isCurrent: false,
            stars: 3,
            bestTime: 45.0,
            isHiddenMode: false,
            hexSize: 90,
            onTap: {}
        )
    }
}
