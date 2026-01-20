import SwiftUI

// MARK: - Level Select View

/// Shows 5 large hexagon levels arranged horizontally with connectors
/// Current level has green glow pulse animation
struct LevelSelectView: View {
    let chapter: Int
    let alien: ChapterAlien
    @ObservedObject var progress: StoryProgress
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLevel: Int?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                StarryBackground(useHubImage: true)

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
                    progress: progress
                )
            }
        }
    }

    // MARK: - Chapter Header

    private var chapterHeader: some View {
        HStack(spacing: 16) {
            Image(alien.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(alien.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text(alien.words.joined(separator: " • "))
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.accentPrimary.opacity(0.8))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Horizontal Level Path

    private func horizontalLevelPath(geometry: GeometryProxy) -> some View {
        let availableWidth = geometry.size.width - 48 // padding
        let hexSize = min((availableWidth - 4 * 20) / 5, 100) // 5 hexagons with connectors

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
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
                                width: 30
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
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
}

// MARK: - Large Hex Tile

struct LargeHexTile: View {
    let level: Int
    let chapter: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    let isCurrent: Bool
    let stars: Int
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

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Hexagon tile
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

                    // Main hexagon
                    HexagonShape()
                        .fill(hexagonGradient)
                        .frame(width: hexSize, height: hexSize)
                        .overlay(
                            HexagonShape()
                                .stroke(borderColor, lineWidth: shouldPulse ? 3 : 2)
                        )
                        .shadow(
                            color: shouldPulse ? AppTheme.connectorGlow.opacity(0.5) : .clear,
                            radius: 10
                        )

                    // Level number or lock
                    if isUnlocked {
                        VStack(spacing: 4) {
                            Text("\(level)")
                                .font(.system(size: hexSize * 0.4, weight: .bold))
                                .foregroundColor(.white)

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

                // Stars display
                if isCompleted {
                    LevelStarDisplay(stars: stars, size: .medium)
                } else if isUnlocked {
                    LevelStarDisplay(stars: 0, size: .medium)
                } else {
                    Text("Need ⭐⭐")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.6))
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

struct HorizontalLevelConnector: View {
    let isActive: Bool
    let isPulsing: Bool
    let width: CGFloat

    @State private var flowPhase: CGFloat = 0

    var body: some View {
        ZStack {
            // Base connector line
            Rectangle()
                .fill(isActive ? AppTheme.connectorActive : AppTheme.connectorDefault)
                .frame(width: width, height: 6)

            // Pulsing energy effect
            if isPulsing {
                // Glow
                Rectangle()
                    .fill(AppTheme.connectorGlow.opacity(0.5))
                    .frame(width: width, height: 12)
                    .blur(radius: 4)

                // Energy dots flowing right
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width, height: 4)
                    .mask(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .white, location: 0.3),
                                        .init(color: .white, location: 0.7),
                                        .init(color: .clear, location: 1)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: flowPhase * (width + 20) - (width / 2 + 10))
                    )
            }
        }
        .frame(width: width, height: 20)
        .onAppear {
            if isPulsing {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    flowPhase = 1
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
    @ObservedObject var progress: StoryProgress
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

                // Alien image
                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                // Speech bubble with intro message
                SpeechBubble {
                    Text(introMessage)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.backgroundDark)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)

                // Level info
                Text("Level \(chapter)-\(levelLetter)")
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
        // Use the alien's unique intro messages
        alien.randomIntroMessage
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

// MARK: - Preview

#Preview("Level Select") {
    NavigationStack {
        LevelSelectView(
            chapter: 1,
            alien: ChapterAlien.all[0],
            progress: StoryProgress()
        )
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
            isHiddenMode: false,
            hexSize: 90,
            onTap: {}
        )
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
            isHiddenMode: false,
            hexSize: 90,
            onTap: {}
        )
    }
}
