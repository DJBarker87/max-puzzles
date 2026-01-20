import SwiftUI

// MARK: - ModuleMenuView

/// Entry screen for Circuit Challenge module
/// Shows Quick Play option and future progression levels (V2)
struct ModuleMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject var musicService: MusicService

    @State private var showQuickPlay = false
    @State private var showStoryMode = false
    @State private var showPuzzleMaker = false
    @State private var selectedDifficulty: DifficultySettings?

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Colorful splash background
                Image("splash_background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // Dark overlay for readability
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                if isLandscape {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
            .navigationTitle("Circuit Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    MusicToggleButton(size: .small, showBackground: false)
                }
            }
            .navigationDestination(isPresented: $showQuickPlay) {
                QuickPlaySetupView { difficulty in
                    selectedDifficulty = difficulty
                }
            }
            .navigationDestination(isPresented: $showStoryMode) {
                ChapterSelectView()
            }
            .navigationDestination(isPresented: $showPuzzleMaker) {
                PuzzleMakerView()
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedDifficulty != nil },
                set: { if !$0 { selectedDifficulty = nil } }
            )) {
                if let difficulty = selectedDifficulty {
                    GameScreenView(difficulty: difficulty)
                }
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                moduleHeader
                VStack(spacing: 16) {
                    quickPlayCard
                    progressionCard
                    puzzleMakerCard
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        HStack(spacing: 32) {
            // Left: Compact header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accentPrimary.opacity(0.3), AppTheme.accentPrimary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)

                    Image("circuit_challenge_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                }

                Text("Circuit Challenge")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: AppTheme.connectorGlow.opacity(0.8), radius: 6)

                Text("Find the path by solving arithmetic!")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 180)

            // Right: Menu cards in scroll view
            ScrollView {
                VStack(spacing: 12) {
                    quickPlayCard
                    progressionCard
                    puzzleMakerCard
                }
                .padding(.vertical, 16)
            }
            .frame(maxWidth: 400)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Module Header

    private var moduleHeader: some View {
        VStack(spacing: 12) {
            // Electric hexagon icon
            Image("circuit_challenge_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: AppTheme.connectorGlow.opacity(0.5), radius: 15)

            Text("Circuit Challenge")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: AppTheme.connectorGlow.opacity(0.8), radius: 8)
                .shadow(color: AppTheme.accentPrimary.opacity(0.5), radius: 4)

            Text("Find the path from START to FINISH by solving arithmetic problems!")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Quick Play Card

    private var quickPlayCard: some View {
        Button(action: { showQuickPlay = true }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.accentPrimary.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accentPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Play")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Play at any difficulty level")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(16)
            .background(AppTheme.backgroundMid.opacity(0.8))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.accentPrimary.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Story Mode Card

    private var progressionCard: some View {
        Button(action: { showStoryMode = true }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.accentSecondary.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accentSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Story Mode")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Help the aliens solve puzzles!")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(16)
            .background(AppTheme.backgroundMid.opacity(0.8))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.accentSecondary.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Puzzle Maker Card

    private var puzzleMakerCard: some View {
        Button(action: { showPuzzleMaker = true }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.accentTertiary.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "printer.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accentTertiary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Puzzle Maker")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Print puzzles for offline play")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(16)
            .background(AppTheme.backgroundMid.opacity(0.8))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.accentTertiary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - DifficultySettings Identifiable

extension DifficultySettings: Identifiable {
    public var id: Int { hashValue }
}

// MARK: - Preview

#Preview("Module Menu") {
    ModuleMenuView()
}
