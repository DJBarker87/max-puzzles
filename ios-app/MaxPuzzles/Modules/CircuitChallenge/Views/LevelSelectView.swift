import SwiftUI
import UIKit

// MARK: - Level Select View

/// Shows 7 levels arranged in a hexagonal pattern:
/// - Levels 1-6 form the outer hexagon vertices (clockwise from top)
/// - Level 7 is the enlarged center with the chapter alien (Hidden Mode)
struct LevelSelectView: View {
    let chapter: Int
    let alien: ChapterAlien
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var progress: StoryProgress { appState.storyProgress }

    @State private var selectedLevel: Int?
    @State private var showCenterUnlockAnimation: Bool = false
    @State private var centerUnlocked: Bool = false
    @State private var previousLevel6Completed: Bool = false
    @State private var showFullScreenGlow: Bool = false
    @State private var glowIntensity: CGFloat = 0  // 0 to 1, controls glow opacity
    @State private var isExtendingConnectors: Bool = false
    @State private var extensionProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                SplashBackground()

                if isLandscape {
                    landscapeLayout(geometry: geometry)
                } else {
                    portraitLayout(geometry: geometry)
                }

                // Full-screen green glow during unlock animation - radiates from center
                if showFullScreenGlow {
                    RadialGradient(
                        colors: [
                            Color(hex: "00ff88").opacity(0.9 * glowIntensity),
                            Color(hex: "00ff88").opacity(0.6 * glowIntensity),
                            Color(hex: "00ff88").opacity(0.2 * glowIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(geometry.size.width, geometry.size.height) * 0.8
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .blur(radius: 30)
                }
            }
        }
        .onAppear {
            OrientationManager.shared.unlockAll()
            checkCenterUnlockAnimation()
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
        .navigationDestination(isPresented: Binding(
            get: { selectedLevel != nil },
            set: { if !$0 { selectedLevel = nil } }
        )) {
            if let level = selectedLevel {
                StoryGameScreenView(
                    chapter: chapter,
                    level: level,
                    alien: alien,
                    onExitToChapterSelect: {
                        // Dismiss LevelSelectView to go back to chapter select
                        dismiss()
                    }
                )
            }
        }
    }

    // MARK: - Center Unlock Animation Check

    private func checkCenterUnlockAnimation() {
        let level6NowCompleted = progress.isLevelCompleted(chapter: chapter, level: 6)
        centerUnlocked = level6NowCompleted

        // Only animate if level 6 just became completed (wasn't completed before)
        if level6NowCompleted && !previousLevel6Completed {
            // Phase 1: Start extension animation (lines grow from outer toward center)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isExtendingConnectors = true
                extensionProgress = 0
                showCenterUnlockAnimation = true

                // Animate extension over 1.2 seconds
                withAnimation(.easeInOut(duration: 1.2)) {
                    extensionProgress = 1.0
                }
            }

            // Phase 2: Huge green glow when energy reaches center (after extension completes)
            // Crescendo: build up intensity over 1s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showFullScreenGlow = true
                glowIntensity = 0
                withAnimation(.easeIn(duration: 1.0)) {
                    glowIntensity = 1.0  // Crescendo to full intensity
                }
            }

            // Phase 3: Hold at peak briefly, then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.8)) {
                    glowIntensity = 0  // Fade out
                }
            }

            // Phase 3b: Hide glow view after fade completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
                showFullScreenGlow = false
                // End extending state, start normal pulsing
                isExtendingConnectors = false
            }

            // Phase 4: End initial unlock animation flag
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                showCenterUnlockAnimation = false
            }
        }
        previousLevel6Completed = level6NowCompleted
    }

    // MARK: - Portrait Layout

    private func portraitLayout(geometry: GeometryProxy) -> some View {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        let availableHeight = screenHeight - 160 // Room for header and stats
        let hexRadius = min((screenWidth - 80) / 2.2, availableHeight / 2.5)
        let outerHexSize = hexRadius * 0.45
        let centerHexSize = outerHexSize * 1.4

        return VStack(spacing: 8) {
            // Header
            portraitHeader

            Spacer()

            // Hexagonal level layout
            ZStack {
                // Edge connectors between outer levels (1-2, 2-3, 3-4, 4-5, 5-6, 6-1)
                edgeConnectors(radius: hexRadius, hexSize: outerHexSize)

                // Radial connectors from outer to center (only shown after level 6 completed)
                if centerUnlocked {
                    radialConnectors(radius: hexRadius, hexSize: outerHexSize, centerSize: centerHexSize)
                }

                // Outer level hexagons (1-6)
                ForEach(1...6, id: \.self) { level in
                    let position = outerHexPosition(index: level - 1, radius: hexRadius)
                    LargeHexTile(
                        level: level,
                        chapter: chapter,
                        isUnlocked: isLevelUnlocked(level),
                        isCompleted: isLevelCompleted(level),
                        isCurrent: isCurrentLevel(level),
                        stars: starsForLevel(level),
                        bestTime: bestTimeForLevel(level),
                        isHiddenMode: false,
                        hexSize: outerHexSize,
                        onTap: {
                            if isLevelUnlocked(level) {
                                selectedLevel = level
                            }
                        }
                    )
                    .offset(x: position.x, y: position.y)
                }

                // Center level 7 (alien)
                CenterAlienHexTile(
                    alien: alien,
                    level: 7,
                    chapter: chapter,
                    isUnlocked: isLevelUnlocked(7),
                    isCompleted: isLevelCompleted(7),
                    isCurrent: isCurrentLevel(7),
                    stars: starsForLevel(7),
                    bestTime: bestTimeForLevel(7),
                    hexSize: centerHexSize,
                    showUnlockAnimation: showCenterUnlockAnimation,
                    onTap: {
                        if isLevelUnlocked(7) {
                            selectedLevel = 7
                        }
                    }
                )
            }
            .frame(width: hexRadius * 2.2, height: hexRadius * 2.2)

            Spacer()

            // Stats
            Text("\((1...7).filter { isLevelCompleted($0) }.count) of 7 levels completed")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        let screenHeight = geometry.size.height
        let screenWidth = geometry.size.width
        let availableHeight = screenHeight - 40
        // Increased hexRadius for bigger hexagons in landscape
        let hexRadius = min((availableHeight * 0.85) / 2.0, (screenWidth - 160) / 2.8)
        let outerHexSize = hexRadius * 0.5  // Increased from 0.4 for easier tapping
        let centerHexSize = outerHexSize * 1.4
        let alienSize = min(screenHeight * 0.2, 70)

        return HStack(spacing: 16) {
            // Left side: alien and stats
            VStack(spacing: 8) {
                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: alienSize)

                Text(alien.name)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.accentTertiary)
                    Text("\(progress.starsInChapter(chapter))/21")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 90)
            .padding(.leading, 16)

            // Center: Hexagonal layout
            ZStack {
                edgeConnectors(radius: hexRadius, hexSize: outerHexSize)

                if centerUnlocked {
                    radialConnectors(radius: hexRadius, hexSize: outerHexSize, centerSize: centerHexSize)
                }

                ForEach(1...6, id: \.self) { level in
                    let position = outerHexPosition(index: level - 1, radius: hexRadius)
                    LargeHexTile(
                        level: level,
                        chapter: chapter,
                        isUnlocked: isLevelUnlocked(level),
                        isCompleted: isLevelCompleted(level),
                        isCurrent: isCurrentLevel(level),
                        stars: starsForLevel(level),
                        bestTime: bestTimeForLevel(level),
                        isHiddenMode: false,
                        hexSize: outerHexSize,
                        onTap: {
                            if isLevelUnlocked(level) {
                                selectedLevel = level
                            }
                        }
                    )
                    .offset(x: position.x, y: position.y)
                }

                CenterAlienHexTile(
                    alien: alien,
                    level: 7,
                    chapter: chapter,
                    isUnlocked: isLevelUnlocked(7),
                    isCompleted: isLevelCompleted(7),
                    isCurrent: isCurrentLevel(7),
                    stars: starsForLevel(7),
                    bestTime: bestTimeForLevel(7),
                    hexSize: centerHexSize,
                    showUnlockAnimation: showCenterUnlockAnimation,
                    onTap: {
                        if isLevelUnlocked(7) {
                            selectedLevel = 7
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity)

            Spacer()
                .frame(width: 16)
        }
    }

    // MARK: - Portrait Header

    private var portraitHeader: some View {
        HStack(spacing: 12) {
            Image(alien.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text("Chapter \(chapter)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                Text(alien.name)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.accentTertiary)
                Text("\(progress.starsInChapter(chapter))/21")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Edge Connectors

    private func edgeConnectors(radius: CGFloat, hexSize: CGFloat) -> some View {
        // Connectors between adjacent outer levels
        // Order: 1→2, 2→3, 3→4, 4→5, 5→6, 6→1
        let connections: [(from: Int, to: Int)] = [
            (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)
        ]

        return ZStack {
            ForEach(connections, id: \.from) { connection in
                let fromPos = outerHexPosition(index: connection.from - 1, radius: radius)
                let toPos = outerHexPosition(index: connection.to - 1, radius: radius)
                let toLevel = connection.to == 1 ? 7 : connection.to // 6→1 connector unlocks with level 7

                EdgeLevelConnector(
                    from: fromPos,
                    to: toPos,
                    hexSize: hexSize,
                    isActive: isLevelUnlocked(toLevel),
                    isPulsing: isLevelCompleted(connection.from) && (connection.to != 1 || isLevelCompleted(6))
                )
            }
        }
    }

    // MARK: - Radial Connectors

    private func radialConnectors(radius: CGFloat, hexSize: CGFloat, centerSize: CGFloat) -> some View {
        ZStack {
            ForEach(1...6, id: \.self) { level in
                let outerPos = outerHexPosition(index: level - 1, radius: radius)

                RadialLevelConnector(
                    from: outerPos,
                    hexSize: hexSize,
                    centerSize: centerSize,
                    isPulsing: centerUnlocked && !isExtendingConnectors,  // Pulse after extension complete
                    isActive: centerUnlocked,
                    isExtending: isExtendingConnectors,
                    extensionProgress: extensionProgress
                )
            }
        }
    }

    // MARK: - Geometry Helpers

    /// Calculate outer hex position (0=top, clockwise)
    private func outerHexPosition(index: Int, radius: CGFloat) -> CGPoint {
        let angleDegrees = 270.0 + Double(index) * 60.0  // Start from top (270°)
        let angleRadians = angleDegrees * .pi / 180.0
        return CGPoint(
            x: CGFloat(cos(angleRadians)) * radius,
            y: CGFloat(sin(angleRadians)) * radius
        )
    }

    // MARK: - Level State Helpers

    private func isLevelUnlocked(_ level: Int) -> Bool {
        if level == 1 {
            return progress.isChapterUnlocked(chapter)
        }
        // Level 7 requires level 6 completed
        if level == 7 {
            return progress.isLevelCompleted(chapter: chapter, level: 6)
        }
        // Levels 2-6 require 2+ stars on previous level
        return progress.starsForLevel(chapter: chapter, level: level - 1) >= 2
    }

    private func isLevelCompleted(_ level: Int) -> Bool {
        progress.isLevelCompleted(chapter: chapter, level: level)
    }

    private func isCurrentLevel(_ level: Int) -> Bool {
        if !isLevelUnlocked(level) { return false }
        if isLevelCompleted(level) { return false }

        // For levels 1-6, check all previous are completed
        if level <= 6 {
            for prevLevel in 1..<level {
                if !isLevelCompleted(prevLevel) {
                    return false
                }
            }
        } else {
            // Level 7 is current if levels 1-6 are completed
            for prevLevel in 1...6 {
                if !isLevelCompleted(prevLevel) {
                    return false
                }
            }
        }
        return true
    }

    private func starsForLevel(_ level: Int) -> Int {
        progress.starsForLevel(chapter: chapter, level: level)
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

    @State private var flowPhase1: CGFloat = 0
    @State private var flowPhase2: CGFloat = 0
    @State private var glowOpacity: CGFloat = 0.5
    @State private var shadowGlow: CGFloat = 0.4  // For pulsing shadow effect

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

    // Scale factor for energy border line widths on iPad
    private var borderScale: CGFloat {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 1.5 : 1.0
        #else
        return 1.5
        #endif
    }

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
            VStack(spacing: 6) {
                // 3D Hexagon tile (poker chip style)
                ZStack {
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

                    // Electric glow effect for current/completed levels
                    if shouldPulse {
                        HexagonShape()
                            .stroke(Color(hex: "00ff88").opacity(glowOpacity), lineWidth: 18 * borderScale)
                            .blur(radius: 6)
                            .frame(width: hexSize, height: hexSize)

                        HexagonShape()
                            .stroke(Color(hex: "00dd77"), lineWidth: 10 * borderScale)
                            .frame(width: hexSize, height: hexSize)

                        HexagonShape()
                            .stroke(
                                Color(hex: "88ffcc"),
                                style: StrokeStyle(
                                    lineWidth: 6 * borderScale,
                                    lineCap: .round,
                                    lineJoin: .round,
                                    dash: [6, 30],
                                    dashPhase: flowPhase2
                                )
                            )
                            .frame(width: hexSize, height: hexSize)

                        HexagonShape()
                            .stroke(
                                Color.white,
                                style: StrokeStyle(
                                    lineWidth: 4 * borderScale,
                                    lineCap: .round,
                                    lineJoin: .round,
                                    dash: [4, 20],
                                    dashPhase: flowPhase1
                                )
                            )
                            .frame(width: hexSize, height: hexSize)

                        HexagonShape()
                            .stroke(Color(hex: "aaffcc"), lineWidth: 3 * borderScale)
                            .frame(width: hexSize, height: hexSize)
                    }

                    // Level number or lock
                    if isUnlocked {
                        VStack(spacing: 2) {
                            Text("\(level)")
                                .font(.system(size: hexSize * 0.35, weight: .black))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)

                            if isHiddenMode {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: hexSize * 0.12))
                                    .foregroundColor(AppTheme.accentSecondary)
                            }
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: hexSize * 0.25))
                            .foregroundColor(.gray)
                    }
                }

                // Stars display
                if isUnlocked {
                    LevelStarDisplay(stars: stars, size: .small)
                } else {
                    LevelStarDisplay(stars: 0, size: .small)
                        .opacity(0.3)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
        // Pulsing shadow glow like game cells
        .shadow(color: shouldPulse ? Color(hex: "00ffc8").opacity(shadowGlow) : .clear, radius: 15)
        .shadow(color: shouldPulse ? Color(hex: "00ffc8").opacity(shadowGlow * 0.5) : .clear, radius: 30)
        .onAppear {
            if shouldPulse {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    flowPhase1 = -36
                }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    flowPhase2 = -36
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.8
                }
                // Shadow glow pulse
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    shadowGlow = 1.0
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

// MARK: - Center Alien Hex Tile

struct CenterAlienHexTile: View {
    let alien: ChapterAlien
    let level: Int
    let chapter: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    let isCurrent: Bool
    let stars: Int
    let bestTime: Double?
    let hexSize: CGFloat
    let showUnlockAnimation: Bool
    let onTap: () -> Void

    @State private var flowPhase1: CGFloat = 0
    @State private var flowPhase2: CGFloat = 0
    @State private var glowOpacity: CGFloat = 0.5
    @State private var unlockGlow: CGFloat = 0
    @State private var shadowGlow: CGFloat = 0.4  // For pulsing shadow effect

    private var shouldPulse: Bool {
        isUnlocked  // Always pulse when center tile is unlocked
    }

    private var borderScale: CGFloat {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 1.5 : 1.0
        #else
        return 1.5
        #endif
    }

    private var shadowOffset: CGFloat { hexSize * 0.12 }
    private var edgeOffset: CGFloat { hexSize * 0.1 }
    private var baseOffset: CGFloat { hexSize * 0.05 }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    // Shadow
                    HexagonShape()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: hexSize, height: hexSize)
                        .offset(x: 4, y: shadowOffset)

                    // Edge
                    HexagonShape()
                        .fill(LinearGradient(
                            colors: [Color(hex: "1a1a25"), Color(hex: "0f0f15")],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: hexSize, height: hexSize)
                        .offset(y: edgeOffset)

                    // Base
                    HexagonShape()
                        .fill(LinearGradient(
                            colors: [Color(hex: "2a2a3a"), Color(hex: "1a1a25")],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: hexSize, height: hexSize)
                        .offset(y: baseOffset)

                    // Top face
                    HexagonShape()
                        .fill(hexagonGradient)
                        .frame(width: hexSize, height: hexSize)
                        .overlay(
                            HexagonShape()
                                .stroke(borderColor, lineWidth: shouldPulse ? 3 : 2)
                        )

                    // Inner shadow
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

                    // Rim highlight
                    HexagonShape()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        .frame(width: hexSize, height: hexSize)

                    // Electric glow for current/completed
                    if shouldPulse {
                        electricGlowLayers
                    }

                    // Unlock animation glow
                    if showUnlockAnimation {
                        HexagonShape()
                            .stroke(Color(hex: "00ff88").opacity(unlockGlow), lineWidth: 24 * borderScale)
                            .blur(radius: 12)
                            .frame(width: hexSize, height: hexSize)
                    }

                    // Content: Alien or lock
                    if isUnlocked {
                        VStack(spacing: 2) {
                            Image(alien.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: hexSize * 0.5, height: hexSize * 0.5)

                            // Hidden mode indicator
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: hexSize * 0.1))
                                .foregroundColor(AppTheme.accentSecondary)
                        }
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: hexSize * 0.2))
                                .foregroundColor(.gray)
                            Text("Complete 1-6")
                                .font(.system(size: hexSize * 0.08, weight: .medium))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
                }

                // Stars
                if isUnlocked {
                    LevelStarDisplay(stars: stars, size: .small)
                } else {
                    LevelStarDisplay(stars: 0, size: .small)
                        .opacity(0.3)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
        // Pulsing shadow glow like game cells
        .shadow(color: shouldPulse ? Color(hex: "00ffc8").opacity(shadowGlow) : .clear, radius: 15)
        .shadow(color: shouldPulse ? Color(hex: "00ffc8").opacity(shadowGlow * 0.5) : .clear, radius: 30)
        .onAppear {
            if shouldPulse {
                startPulseAnimations()
            }
        }
        .onChange(of: showUnlockAnimation) { newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    unlockGlow = 0.9
                }
            } else {
                unlockGlow = 0
            }
        }
    }

    private var electricGlowLayers: some View {
        Group {
            HexagonShape()
                .stroke(Color(hex: "00ff88").opacity(glowOpacity), lineWidth: 18 * borderScale)
                .blur(radius: 6)
                .frame(width: hexSize, height: hexSize)

            HexagonShape()
                .stroke(Color(hex: "00dd77"), lineWidth: 10 * borderScale)
                .frame(width: hexSize, height: hexSize)

            HexagonShape()
                .stroke(
                    Color(hex: "88ffcc"),
                    style: StrokeStyle(
                        lineWidth: 6 * borderScale,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: [6, 30],
                        dashPhase: flowPhase2
                    )
                )
                .frame(width: hexSize, height: hexSize)

            HexagonShape()
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: 4 * borderScale,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: [4, 20],
                        dashPhase: flowPhase1
                    )
                )
                .frame(width: hexSize, height: hexSize)

            HexagonShape()
                .stroke(Color(hex: "aaffcc"), lineWidth: 3 * borderScale)
                .frame(width: hexSize, height: hexSize)
        }
    }

    private func startPulseAnimations() {
        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            flowPhase1 = -36
        }
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            flowPhase2 = -36
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }
        // Shadow glow pulse
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            shadowGlow = 1.0
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

// MARK: - Edge Level Connector

struct EdgeLevelConnector: View {
    let from: CGPoint
    let to: CGPoint
    let hexSize: CGFloat
    let isActive: Bool
    let isPulsing: Bool

    @State private var flowPhase1: CGFloat = 0
    @State private var flowPhase2: CGFloat = 0
    @State private var glowOpacity: CGFloat = 0.5

    private var borderScale: CGFloat {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 1.5 : 1.0
        #else
        return 1.5
        #endif
    }

    // Shorten the connector to not overlap with hex tiles
    private var shortenedFrom: CGPoint {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = sqrt(dx * dx + dy * dy)
        let shortenBy = hexSize * 0.55
        let factor = shortenBy / length
        return CGPoint(x: from.x + dx * factor, y: from.y + dy * factor)
    }

    private var shortenedTo: CGPoint {
        let dx = from.x - to.x
        let dy = from.y - to.y
        let length = sqrt(dx * dx + dy * dy)
        let shortenBy = hexSize * 0.55
        let factor = shortenBy / length
        return CGPoint(x: to.x + dx * factor, y: to.y + dy * factor)
    }

    var body: some View {
        ZStack {
            if isPulsing {
                // Glow
                LevelConnectorLine(from: shortenedFrom, to: shortenedTo)
                    .stroke(Color(hex: "00ff88").opacity(glowOpacity), style: StrokeStyle(lineWidth: 18 * borderScale, lineCap: .round))
                    .blur(radius: 6)

                // Main line
                LevelConnectorLine(from: shortenedFrom, to: shortenedTo)
                    .stroke(Color(hex: "00dd77"), style: StrokeStyle(lineWidth: 10 * borderScale, lineCap: .round))

                // Energy slow
                LevelConnectorLine(from: shortenedFrom, to: shortenedTo)
                    .stroke(
                        Color(hex: "88ffcc"),
                        style: StrokeStyle(lineWidth: 6 * borderScale, lineCap: .round, dash: [6, 30], dashPhase: flowPhase2)
                    )

                // Energy fast
                LevelConnectorLine(from: shortenedFrom, to: shortenedTo)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 4 * borderScale, lineCap: .round, dash: [4, 20], dashPhase: flowPhase1)
                    )

                // Core
                LevelConnectorLine(from: shortenedFrom, to: shortenedTo)
                    .stroke(Color(hex: "aaffcc"), style: StrokeStyle(lineWidth: 3 * borderScale, lineCap: .round))
            } else if isActive {
                LevelConnectorLine(from: shortenedFrom, to: shortenedTo)
                    .stroke(AppTheme.connectorActive, style: StrokeStyle(lineWidth: 8, lineCap: .round))
            } else {
                LevelConnectorLine(from: shortenedFrom, to: shortenedTo)
                    .stroke(AppTheme.connectorDefault, style: StrokeStyle(lineWidth: 8, lineCap: .round))
            }
        }
        .onAppear {
            if isPulsing {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    flowPhase1 = -36
                }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    flowPhase2 = -36
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.8
                }
            }
        }
    }
}

// MARK: - Radial Level Connector

struct RadialLevelConnector: View {
    let from: CGPoint  // Outer hex position
    let hexSize: CGFloat
    let centerSize: CGFloat
    let isPulsing: Bool
    let isActive: Bool
    let isExtending: Bool  // True during the initial extension animation
    let extensionProgress: CGFloat  // 0 = at outer, 1 = reached center

    @State private var flowPhase1: CGFloat = 0
    @State private var flowPhase2: CGFloat = 0
    @State private var glowOpacity: CGFloat = 0.5

    private var borderScale: CGFloat {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 1.5 : 1.0
        #else
        return 1.5
        #endif
    }

    // Shorten from outer toward center (start point)
    private var shortenedFrom: CGPoint {
        let length = sqrt(from.x * from.x + from.y * from.y)
        let shortenBy = hexSize * 0.55
        let factor = shortenBy / length
        return CGPoint(x: from.x - from.x * factor, y: from.y - from.y * factor)
    }

    // Shorten from center toward outer (end point when fully extended)
    private var shortenedTo: CGPoint {
        let length = sqrt(from.x * from.x + from.y * from.y)
        let shortenBy = centerSize * 0.55
        let factor = shortenBy / length
        return CGPoint(x: from.x * factor, y: from.y * factor)
    }

    // Current end point based on extension progress
    private var currentTo: CGPoint {
        // Interpolate between shortenedFrom and shortenedTo based on progress
        let startX = shortenedFrom.x
        let startY = shortenedFrom.y
        let endX = shortenedTo.x
        let endY = shortenedTo.y
        return CGPoint(
            x: startX + (endX - startX) * extensionProgress,
            y: startY + (endY - startY) * extensionProgress
        )
    }

    var body: some View {
        ZStack {
            if isExtending || isPulsing {
                let toPoint = isExtending ? currentTo : shortenedTo

                // Glow
                LevelConnectorLine(from: shortenedFrom, to: toPoint)
                    .stroke(Color(hex: "00ff88").opacity(glowOpacity), style: StrokeStyle(lineWidth: 18 * borderScale, lineCap: .round))
                    .blur(radius: 6)

                // Main line
                LevelConnectorLine(from: shortenedFrom, to: toPoint)
                    .stroke(Color(hex: "00dd77"), style: StrokeStyle(lineWidth: 10 * borderScale, lineCap: .round))

                // Energy slow - INWARD flow (positive dashPhase)
                LevelConnectorLine(from: shortenedFrom, to: toPoint)
                    .stroke(
                        Color(hex: "88ffcc"),
                        style: StrokeStyle(lineWidth: 6 * borderScale, lineCap: .round, dash: [6, 30], dashPhase: flowPhase2)
                    )

                // Energy fast - INWARD flow (positive dashPhase)
                LevelConnectorLine(from: shortenedFrom, to: toPoint)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 4 * borderScale, lineCap: .round, dash: [4, 20], dashPhase: flowPhase1)
                    )

                // Core
                LevelConnectorLine(from: shortenedFrom, to: toPoint)
                    .stroke(Color(hex: "aaffcc"), style: StrokeStyle(lineWidth: 3 * borderScale, lineCap: .round))
            } else if isActive {
                // Static green glow after animation
                LevelConnectorLine(from: shortenedFrom, to: shortenedTo)
                    .stroke(Color(hex: "00ff88").opacity(0.5), style: StrokeStyle(lineWidth: 14 * borderScale, lineCap: .round))
                    .blur(radius: 4)

                LevelConnectorLine(from: shortenedFrom, to: shortenedTo)
                    .stroke(Color(hex: "00dd77"), style: StrokeStyle(lineWidth: 8 * borderScale, lineCap: .round))
            }
        }
        .onAppear {
            if isPulsing {
                // INWARD flow: positive dashPhase
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    flowPhase1 = 36  // Positive = inward
                }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    flowPhase2 = 36  // Positive = inward
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.8
                }
            }
        }
    }
}

// MARK: - Level Connector Line Shape

/// A line shape for level select connectors that takes relative positions from center
private struct LevelConnectorLine: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let centerY = rect.midY
        path.move(to: CGPoint(x: centerX + from.x, y: centerY + from.y))
        path.addLine(to: CGPoint(x: centerX + to.x, y: centerY + to.y))
        return path
    }
}

// MARK: - Level Star Display

private struct LevelStarDisplay: View {
    let stars: Int
    let size: StarSize

    enum StarSize {
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

// MARK: - Story Game Screen View

struct StoryGameScreenView: View {
    let chapter: Int
    let level: Int
    let alien: ChapterAlien
    let onExitToChapterSelect: (() -> Void)?
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
                storyLevel: level,
                onExitToChapterSelect: {
                    // First dismiss this view, then call parent's callback
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onExitToChapterSelect?()
                    }
                }
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
            // Fully opaque backdrop with starry background (hides grid sizing behind it)
            StarryBackground()

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

    private var introMessage: String {
        let playerName = StorageService.shared.playerName
        // Level 7 is hidden mode - show special explanation
        if level == 7 {
            return alien.hiddenModeIntro(playerName: playerName)
        }
        // Use the alien's unique intro messages with personalization
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
        HStack(spacing: 10) {
            // Left: Alien image with glow
            ZStack {
                // Glow backdrop
                Circle()
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .blur(radius: 12)
                    .opacity(glowPhase)

                // Alien image
                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .alienIdleAnimation(style: .bounce, intensity: 0.8)
            }
            .frame(width: 80, height: 80)

            // Right: Name and traits
            VStack(alignment: .leading, spacing: 4) {
                // Chapter badge
                Text("CHAPTER \(chapter)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.2))
                    .cornerRadius(4)

                // Alien name
                Text(alien.name.uppercased())
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: accentColor.opacity(0.8), radius: 6)
                    .shadow(color: accentColor.opacity(0.5), radius: 3)

                // Trait pills - wrap if needed
                HStack(spacing: 4) {
                    ForEach(alien.words, id: \.self) { word in
                        Text(word)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.25))
                            .cornerRadius(6)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
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

#Preview("Center Alien Hex") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        CenterAlienHexTile(
            alien: ChapterAlien.all[0],
            level: 7,
            chapter: 1,
            isUnlocked: true,
            isCompleted: false,
            isCurrent: true,
            stars: 0,
            bestTime: nil,
            hexSize: 120,
            showUnlockAnimation: false,
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
