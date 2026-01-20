import SwiftUI

// MARK: - Level Select View

/// Shows 5 hexagon levels connected by pathways within a chapter
/// Levels unlock when 2+ stars achieved on previous level
struct LevelSelectView: View {
    let chapter: Int
    let alien: ChapterAlien
    @ObservedObject var progress: StoryProgress
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLevel: Int?

    var body: some View {
        ZStack {
            StarryBackground(useHubImage: true)

            ScrollView {
                VStack(spacing: 24) {
                    // Chapter header with alien
                    chapterHeader

                    // Hexagon level path
                    levelPath

                    // Chapter stats
                    chapterStats
                }
                .padding(.vertical, 20)
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
        .navigationDestination(item: $selectedLevel) { level in
            StoryGameScreenView(
                chapter: chapter,
                level: level,
                alien: alien,
                progress: progress
            )
        }
    }

    // MARK: - Chapter Header

    private var chapterHeader: some View {
        HStack(spacing: 16) {
            Image(alien.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 4) {
                Text(alien.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text(alien.words.joined(separator: " • "))
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.accentPrimary.opacity(0.8))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Level Path

    private var levelPath: some View {
        VStack(spacing: 0) {
            ForEach(1...5, id: \.self) { level in
                VStack(spacing: 0) {
                    // Connector to previous (except for level 1)
                    if level > 1 {
                        LevelConnector(
                            isActive: isLevelUnlocked(level),
                            isPulsing: isLevelCompleted(level - 1)
                        )
                    }

                    // Hexagon level tile
                    LevelHexTile(
                        level: level,
                        chapter: chapter,
                        isUnlocked: isLevelUnlocked(level),
                        isCompleted: isLevelCompleted(level),
                        stars: starsForLevel(level),
                        isHiddenMode: isHiddenMode(level: level),
                        onTap: {
                            if isLevelUnlocked(level) {
                                selectedLevel = level
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 24)
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
        .padding(.top, 16)
    }

    // MARK: - Helpers

    private func isLevelUnlocked(_ level: Int) -> Bool {
        // Level 1 always unlocked if chapter is unlocked
        if level == 1 {
            return progress.isChapterUnlocked(chapter)
        }
        // Level n+1 unlocks when 2+ stars on level n
        let previousStars = progress.starsForLevel(chapter: chapter, level: level - 1)
        return previousStars >= 2
    }

    private func isLevelCompleted(_ level: Int) -> Bool {
        progress.isLevelCompleted(chapter: chapter, level: level)
    }

    private func starsForLevel(_ level: Int) -> Int {
        progress.starsForLevel(chapter: chapter, level: level)
    }

    private func isHiddenMode(level: Int) -> Bool {
        level == 5 || chapter == 10
    }
}

// MARK: - Level Hex Tile

struct LevelHexTile: View {
    let level: Int
    let chapter: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    let stars: Int
    let isHiddenMode: Bool
    let onTap: () -> Void

    @State private var flowPhase: CGFloat = 0

    private var levelLetter: String {
        ["A", "B", "C", "D", "E"][level - 1]
    }

    private let hexSize: CGFloat = 80

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Hexagon tile
                ZStack {
                    // Pulsing glow for completed
                    if isCompleted {
                        HexagonShape()
                            .fill(AppTheme.connectorGlow.opacity(0.3))
                            .frame(width: hexSize + 20, height: hexSize + 20)
                            .blur(radius: 10)
                            .opacity(flowPhase > 0.5 ? 0.8 : 0.4)

                        // Energy border animation
                        HexagonShape()
                            .stroke(
                                AppTheme.connectorGlow,
                                style: StrokeStyle(lineWidth: 4, dash: [6, 10], dashPhase: flowPhase * 36)
                            )
                            .frame(width: hexSize + 8, height: hexSize + 8)
                    }

                    // Main hexagon
                    HexagonShape()
                        .fill(hexagonGradient)
                        .frame(width: hexSize, height: hexSize)
                        .overlay(
                            HexagonShape()
                                .stroke(borderColor, lineWidth: 2)
                        )

                    // Level number or lock
                    if isUnlocked {
                        VStack(spacing: 2) {
                            Text("\(level)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            if isHiddenMode {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.accentSecondary)
                            }
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }

                // Stars display
                if isCompleted {
                    StarDisplay(stars: stars, size: .small)
                } else if isUnlocked {
                    // Empty star placeholders
                    StarDisplay(stars: 0, size: .small)
                } else {
                    Text("Need ⭐⭐")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
        .onAppear {
            if isCompleted {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    flowPhase = 1
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
        if isCompleted {
            return AppTheme.connectorGlow
        } else if isUnlocked {
            return AppTheme.accentPrimary.opacity(0.5)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Level Connector

struct LevelConnector: View {
    let isActive: Bool
    let isPulsing: Bool

    @State private var flowPhase: CGFloat = 0

    var body: some View {
        ZStack {
            // Base connector line
            Rectangle()
                .fill(isActive ? AppTheme.connectorActive : AppTheme.connectorDefault)
                .frame(width: 6, height: 40)

            // Pulsing energy effect
            if isPulsing {
                // Glow
                Rectangle()
                    .fill(AppTheme.connectorGlow.opacity(0.5))
                    .frame(width: 12, height: 40)
                    .blur(radius: 4)

                // Energy dots
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4, height: 40)
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
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .offset(y: flowPhase * 60 - 30)
                    )
            }
        }
        .frame(height: 40)
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

    var body: some View {
        let storyLevel = StoryLevel(chapter: chapter, level: level)
        let difficulty = StoryDifficulty.settings(for: storyLevel)

        GameScreenView(difficulty: difficulty)
        // TODO: Integrate star reveal animation and progress recording
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

#Preview("Level Hex Tile - Completed") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        LevelHexTile(
            level: 1,
            chapter: 1,
            isUnlocked: true,
            isCompleted: true,
            stars: 3,
            isHiddenMode: false,
            onTap: {}
        )
    }
}

#Preview("Level Hex Tile - Unlocked") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        LevelHexTile(
            level: 2,
            chapter: 1,
            isUnlocked: true,
            isCompleted: false,
            stars: 0,
            isHiddenMode: false,
            onTap: {}
        )
    }
}

#Preview("Level Hex Tile - Locked") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        LevelHexTile(
            level: 3,
            chapter: 1,
            isUnlocked: false,
            isCompleted: false,
            stars: 0,
            isHiddenMode: false,
            onTap: {}
        )
    }
}
