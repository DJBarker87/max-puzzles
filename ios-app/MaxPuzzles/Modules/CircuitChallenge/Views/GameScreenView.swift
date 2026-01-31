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

    // Current level state (can change for "Next Level" / "Next Chapter")
    @State private var currentChapter: Int?
    @State private var currentLevel: Int?
    @State private var currentAlien: ChapterAlien?

    // Level intro overlay (for "Next Level" transitions)
    @State private var showLevelIntro = false
    @State private var introScale: CGFloat = 0.5
    @State private var introOpacity: Double = 0

    private let initialDifficulty: DifficultySettings

    // Story mode optional parameters (initial values)
    private let initialAlien: ChapterAlien?
    private let initialChapter: Int?
    private let initialLevel: Int?

    // Callback when user exits after advancing to a new chapter (pop to chapter select)
    private let onExitToChapterSelect: (() -> Void)?

    /// Whether this is story mode
    private var isStoryMode: Bool {
        currentChapter != nil && currentLevel != nil
    }

    init(
        difficulty: DifficultySettings,
        storyAlien: ChapterAlien? = nil,
        storyChapter: Int? = nil,
        storyLevel: Int? = nil,
        onExitToChapterSelect: (() -> Void)? = nil
    ) {
        self.initialDifficulty = difficulty
        self.initialAlien = storyAlien
        self.initialChapter = storyChapter
        self.initialLevel = storyLevel
        self.onExitToChapterSelect = onExitToChapterSelect
        _viewModel = StateObject(wrappedValue: GameViewModel(difficulty: difficulty))
        _currentChapter = State(initialValue: storyChapter)
        _currentLevel = State(initialValue: storyLevel)
        _currentAlien = State(initialValue: storyAlien)
    }

    /// Get the current difficulty based on chapter/level
    private var currentDifficulty: DifficultySettings {
        if let chapter = currentChapter, let level = currentLevel {
            let storyLevel = StoryLevel(chapter: chapter, level: level)
            return StoryDifficulty.settings(for: storyLevel)
        }
        return initialDifficulty
    }

    /// Check if in compact vertical (landscape on iPhone)
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    /// Title for the header - shows alien name for story mode
    private var storyModeTitle: String {
        if let alien = currentAlien, let level = currentLevel {
            return "\(alien.name) \(level)"
        } else if viewModel.state.isHiddenMode {
            return "Hidden Mode"
        } else {
            return "Quick Play"
        }
    }

    /// Check if there's a next level available (including next chapter)
    private var hasNextLevel: Bool {
        guard let chapter = currentChapter, let level = currentLevel else { return false }
        // Has next level in same chapter (levels 1-6 can advance)
        if level < 7 { return true }
        // Level 7: check if there's a next chapter
        return chapter < 10
    }

    /// Check if advancing means going to next chapter
    private var isAdvancingToNextChapter: Bool {
        guard let level = currentLevel else { return false }
        return level == 7
    }

    /// Check if level 6 just completed - returns to level select for unlock animation
    private var shouldReturnToLevelSelect: Bool {
        guard let level = currentLevel else { return false }
        return level == 6
    }

    /// Check if we advanced to a different chapter than we started on
    private var hasChangedChapter: Bool {
        guard let initialChapter = initialChapter, let currentChapter = currentChapter else { return false }
        return currentChapter != initialChapter
    }

    var body: some View {
        ZStack {
            // Starry background for gameplay
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

            // Level intro overlay (for "Next Level" transitions in story mode)
            if showLevelIntro, let alien = currentAlien, let level = currentLevel {
                levelIntroOverlay(alien: alien, level: level)
                    .scaleEffect(introScale)
                    .opacity(introOpacity)
                    .onTapGesture {
                        dismissLevelIntro()
                    }
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
                        // Retry the same level
                        navigateToSummary = false
                        handleNewPuzzle()
                    },
                    onNextLevel: data.isStoryMode && data.won && hasNextLevel ? {
                        navigateToSummary = false

                        // Level 6 completion: Return to level select to see unlock animation
                        if shouldReturnToLevelSelect {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if hasChangedChapter, let chapter = currentChapter {
                                    // Set pending navigation so ChapterSelectView auto-navigates
                                    appState.pendingChapterNavigation = chapter
                                    onExitToChapterSelect?()
                                } else {
                                    dismiss()
                                }
                            }
                            return
                        }

                        // Advance to next level (or next chapter if on level 7)
                        if let chapter = currentChapter, let level = currentLevel {
                            coinsPersisted = false // Reset for new puzzle

                            let newChapter: Int
                            let newLevel: Int

                            if level == 7 && chapter < 10 {
                                // Advance to next chapter, level 1
                                newChapter = chapter + 1
                                newLevel = 1
                                // Update alien for new chapter
                                currentAlien = ChapterAlien.forChapter(newChapter)
                            } else {
                                // Advance to next level in same chapter
                                newChapter = chapter
                                newLevel = level + 1
                            }

                            currentChapter = newChapter
                            currentLevel = newLevel

                            // Compute new difficulty explicitly
                            let storyLevel = StoryLevel(chapter: newChapter, level: newLevel)
                            let newDifficulty = StoryDifficulty.settings(for: storyLevel)
                            viewModel.setDifficulty(newDifficulty)

                            // Show alien intro overlay with encouragement
                            showNextLevelIntro()

                            // Generate puzzle after brief delay (while intro shows)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.generateNewPuzzle()
                                // Restart game music
                                musicService.play(track: .game)
                            }
                        }
                    } : nil,
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
                            // If chapter changed, pop back to chapter select
                            if hasChangedChapter, let onExitToChapterSelect = onExitToChapterSelect {
                                onExitToChapterSelect()
                            } else {
                                dismiss()
                            }
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
                    onReset: isStoryMode ? nil : { viewModel.resetPuzzle() },
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
                onReset: isStoryMode ? nil : { viewModel.resetPuzzle() },
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
                .accessibilityHidden(true)
            Text(error)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.error)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .accessibilityLabel("Error: \(error)")
            Button("Try Again") {
                handleNewPuzzle()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppTheme.accentPrimary)
            .cornerRadius(10)
            .accessibilityLabel("Try Again")
            .accessibilityHint("Generates a new puzzle")
        }
        .accessibilityElement(children: .contain)
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

    private func levelIntroOverlay(alien: ChapterAlien, level: Int) -> some View {
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
                    Text(introMessage(for: alien))
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

    private func introMessage(for alien: ChapterAlien) -> String {
        let playerName = StorageService.shared.playerName
        return alien.personalizedIntroMessage(playerName: playerName)
    }

    private func showNextLevelIntro() {
        showLevelIntro = true
        introScale = 0.5
        introOpacity = 0

        // Animate intro in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            introScale = 1.0
            introOpacity = 1.0
        }

        // Auto-dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if showLevelIntro {
                dismissLevelIntro()
            }
        }
    }

    private func dismissLevelIntro() {
        withAnimation(.easeOut(duration: 0.3)) {
            introOpacity = 0
            introScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showLevelIntro = false
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
            // Small delay to show final state before navigating to summary
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
            if let chapter = currentChapter, let level = currentLevel {
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
            storyAlien: currentAlien,
            storyChapter: currentChapter,
            storyLevel: currentLevel
        )
    }
}

// MARK: - Preview

#Preview("Game Screen") {
    GameScreenView(difficulty: DifficultyPresets.byLevel(5))
}
