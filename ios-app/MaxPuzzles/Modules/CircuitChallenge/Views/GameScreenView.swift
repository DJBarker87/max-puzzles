import SwiftUI

// MARK: - GameScreenView

/// Main game screen for Circuit Challenge
/// Brings together the puzzle grid, status displays, and action buttons
struct GameScreenView: View {
    @StateObject private var viewModel: GameViewModel
    private var feedback: FeedbackManager { FeedbackManager.shared }
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var showExitConfirm = false
    @State private var navigateToSummary = false
    @State private var summaryData: SummaryData?
    @State private var coinsPersisted = false

    private let difficulty: DifficultySettings

    // Story mode optional parameters
    private let storyAlien: ChapterAlien?
    private let storyChapter: Int?
    private let storyLevel: Int?

    init(
        difficulty: DifficultySettings,
        storyAlien: ChapterAlien? = nil,
        storyChapter: Int? = nil,
        storyLevel: Int? = nil
    ) {
        self.difficulty = difficulty
        self.storyAlien = storyAlien
        self.storyChapter = storyChapter
        self.storyLevel = storyLevel
        _viewModel = StateObject(wrappedValue: GameViewModel(difficulty: difficulty))
    }

    /// Check if in compact vertical (landscape on iPhone)
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    /// Title for the header - shows alien name for story mode
    private var storyModeTitle: String {
        if let alien = storyAlien, let level = storyLevel {
            return "\(alien.name) \(level)"
        } else if viewModel.state.isHiddenMode {
            return "Hidden Mode"
        } else {
            return "Quick Play"
        }
    }

    var body: some View {
        ZStack {
            StarryBackground()

            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }

            // Game Over Overlay (brief flash before navigation)
            if viewModel.state.isGameOver && !viewModel.state.showingSolution && !navigateToSummary {
                gameOverOverlay
            }

            // Exit Confirmation
            if showExitConfirm {
                exitConfirmationOverlay
            }
        }
        .shake(isShaking: feedback.isShaking)
        .navigationBarHidden(true)
        .landscapeOnly()
        .onAppear {
            if viewModel.state.puzzle == nil && viewModel.state.status == .setup {
                viewModel.generateNewPuzzle()
            }
            // Start game music
            musicService.play(track: .game)
        }
        .onDisappear {
            // Stop game music when leaving
            musicService.stop()
        }
        .onChange(of: viewModel.state.moveHistory.count) { newCount in
            // Watch for wrong moves and trigger shake
            if let lastMove = viewModel.state.moveHistory.last,
               !lastMove.correct && !viewModel.state.isHiddenMode {
                feedback.triggerShake()
            }
        }
        .onChange(of: viewModel.state.status) { newStatus in
            handleStatusChange(to: newStatus)
        }
        .fullScreenCover(isPresented: $navigateToSummary) {
            if let data = summaryData {
                SummaryScreenView(
                    data: data,
                    onPlayAgain: {
                        navigateToSummary = false
                        handleNewPuzzle()
                    },
                    onChangeDifficulty: {
                        navigateToSummary = false
                        dismiss()
                    },
                    onSeeSolution: data.won ? nil : {
                        navigateToSummary = false
                        viewModel.showSolution()
                    },
                    onExit: {
                        navigateToSummary = false
                        // Small delay to let fullScreenCover dismiss before navigation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
                    }
                )
                .environmentObject(appState)
                .environmentObject(musicService)
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // Header
            GameHeaderView(
                title: storyModeTitle,
                lives: viewModel.state.lives,
                maxLives: viewModel.state.maxLives,
                elapsedMs: viewModel.state.elapsedMs,
                isTimerRunning: viewModel.state.isTimerRunning,
                coins: viewModel.state.puzzleCoins,
                coinChange: latestCoinAnimation,
                isHiddenMode: viewModel.state.isHiddenMode,
                onBackClick: { showExitConfirm = true }
            )

            // Puzzle Grid
            gridContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Action Buttons
            actionButtonsSection
        }
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            // Left Panel: Back + Actions (minimal width)
            VStack(spacing: 8) {
                Button(action: { showExitConfirm = true }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.backgroundMid)
                        .cornerRadius(8)
                }

                MusicToggleButton(size: .small)

                Spacer()

                ActionButtons(
                    onReset: { viewModel.resetPuzzle() },
                    onNewPuzzle: handleNewPuzzle,
                    onViewSolution: viewModel.state.status == .lost ? { viewModel.showSolution() } : nil,
                    onContinue: viewModel.state.showingSolution ? handleContinueToSummary : nil,
                    showViewSolution: viewModel.state.status == .lost && !viewModel.state.showingSolution,
                    showContinue: viewModel.state.showingSolution,
                    vertical: true,
                    compact: true
                )

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(width: 60)
            .background(AppTheme.backgroundDark.opacity(0.95))

            // Center: Grid (maximize space)
            gridContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Right Panel: Status (minimal width)
            VStack(spacing: 12) {
                Spacer()

                if !viewModel.state.isHiddenMode {
                    LivesDisplay(
                        lives: viewModel.state.lives,
                        maxLives: viewModel.state.maxLives,
                        vertical: true,
                        compact: true
                    )
                }

                TimerDisplayCompact(elapsedMs: viewModel.state.elapsedMs, vertical: true)

                if !viewModel.state.isHiddenMode {
                    GameCoinDisplay(
                        amount: viewModel.state.puzzleCoins,
                        showChange: latestCoinAnimation,
                        size: .small
                    )
                }

                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(width: 80)
            .background(AppTheme.backgroundDark.opacity(0.95))
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            ActionButtons(
                onReset: { viewModel.resetPuzzle() },
                onNewPuzzle: handleNewPuzzle,
                onViewSolution: viewModel.state.status == .lost ? { viewModel.showSolution() } : nil,
                onContinue: viewModel.state.showingSolution ? handleContinueToSummary : nil,
                showViewSolution: viewModel.state.status == .lost && !viewModel.state.showingSolution,
                showContinue: viewModel.state.showingSolution
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(AppTheme.backgroundDark.opacity(0.9))
    }

    // MARK: - Grid Content

    @ViewBuilder
    private var gridContent: some View {
        if let puzzle = viewModel.state.puzzle {
            PuzzleGridView(
                puzzle: puzzle,
                currentPosition: viewModel.state.currentPosition,
                visitedCells: viewModel.state.visitedCells,
                traversedConnectors: viewModel.state.traversedConnectors,
                wrongMoves: viewModel.state.wrongMoves,
                wrongConnectors: viewModel.state.wrongConnectors,
                showSolution: viewModel.state.showingSolution,
                disabled: !viewModel.state.canMove,
                onCellTap: viewModel.state.canMove ? { coord in
                    viewModel.makeMove(to: coord)
                } : nil
            )
        } else if let error = viewModel.state.error {
            errorContent(error)
        } else {
            loadingContent
        }
    }

    private func errorContent(_ error: String) -> some View {
        VStack(spacing: 16) {
            Text("⚠️")
                .font(.system(size: 48))
            Text(error)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.error)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Try Again") {
                handleNewPuzzle()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppTheme.accentPrimary)
            .cornerRadius(10)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.accentPrimary)
            Text("Generating puzzle...")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    // MARK: - Overlays

    private var gameOverOverlay: some View {
        Color.black.opacity(0.5)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: viewModel.state.status == .won ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(viewModel.state.status == .won ? AppTheme.accentPrimary : AppTheme.accentSecondary)
                    Text(viewModel.state.status == .won ? "Puzzle Complete!" : "Out of Lives")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
    }

    private var exitConfirmationOverlay: some View {
        Color.black.opacity(0.6)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 24) {
                    Text("Exit Puzzle?")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text("Your progress on this puzzle will be lost.")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Button("Continue Playing") {
                            showExitConfirm = false
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(AppTheme.backgroundDark)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )

                        Button("Exit") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(AppTheme.accentSecondary)
                        .cornerRadius(10)
                    }
                }
                .padding(32)
                .background(AppTheme.backgroundMid)
                .cornerRadius(20)
                .padding(24)
            }
    }

    // MARK: - Helpers

    private var latestCoinAnimation: CoinAnimation? {
        viewModel.state.coinAnimations.first
    }

    private func handleNewPuzzle() {
        coinsPersisted = false // Reset for new puzzle
        viewModel.requestNewPuzzle()
        viewModel.generateNewPuzzle()
        // Restart game music (may have been changed to victory/lose music)
        musicService.play(track: .game)
    }

    private func handleContinueToSummary() {
        createSummaryData()
        navigateToSummary = true
    }

    private func handleStatusChange(to newStatus: GameStatus) {
        // Navigate to summary when game ends (but not if viewing solution)
        if (newStatus == .won || newStatus == .lost) && !viewModel.state.showingSolution {
            // Play victory sound on win
            if newStatus == .won {
                musicService.play(track: .victory, loop: false)
            }

            // Small delay to show final state
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                createSummaryData()
                navigateToSummary = true
            }
        }

        // Handle hidden mode revealing
        if newStatus == .revealing && viewModel.state.isHiddenMode {
            viewModel.revealHiddenResults()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                createSummaryData()
                navigateToSummary = true
            }
        }
    }

    private func createSummaryData() {
        // Persist coins and record completion (only once per puzzle)
        if !coinsPersisted {
            if viewModel.state.puzzleCoins > 0 {
                appState.updateGuestCoins(viewModel.state.puzzleCoins)
            }
            appState.recordPuzzleCompleted()

            // Record story mode progress
            if let chapter = storyChapter, let level = storyLevel {
                let won = viewModel.state.status == .won
                let livesLost = viewModel.state.moveHistory.filter { !$0.correct }.count
                let timeSeconds = Double(viewModel.state.elapsedMs) / 1000.0
                let tileCount = viewModel.state.moveHistory.filter { $0.correct }.count

                appState.storyProgress.recordAttempt(
                    chapter: chapter,
                    level: level,
                    won: won,
                    livesLost: livesLost,
                    timeSeconds: timeSeconds,
                    tileCount: tileCount
                )
            }

            coinsPersisted = true
        }

        summaryData = SummaryData(
            won: viewModel.state.status == .won,
            isHiddenMode: viewModel.state.isHiddenMode,
            elapsedMs: viewModel.state.elapsedMs,
            puzzleCoins: viewModel.state.puzzleCoins,
            moveHistory: viewModel.state.moveHistory,
            hiddenModeResults: viewModel.state.hiddenModeResults,
            puzzle: viewModel.state.puzzle,
            difficulty: viewModel.state.difficulty,
            storyAlien: storyAlien,
            storyChapter: storyChapter,
            storyLevel: storyLevel
        )
    }
}

// MARK: - Preview

#Preview("Game Screen") {
    GameScreenView(difficulty: DifficultyPresets.byLevel(5))
}
