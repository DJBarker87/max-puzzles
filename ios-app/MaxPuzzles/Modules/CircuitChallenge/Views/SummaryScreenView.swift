import SwiftUI

// MARK: - SummaryScreenView

/// End-of-game summary screen showing results and actions
struct SummaryScreenView: View {
    let data: SummaryData

    @Environment(\.dismiss) private var dismiss

    /// Callback when user wants to play again
    var onPlayAgain: (() -> Void)?

    /// Callback when user wants to change difficulty
    var onChangeDifficulty: (() -> Void)?

    /// Callback when user wants to see solution (only for lost games)
    var onSeeSolution: (() -> Void)?

    // Music service
    @EnvironmentObject var musicService: MusicService

    // State for character reveal phase
    @State private var showingCharacter = true
    @State private var characterScale: CGFloat = 0.3
    @State private var characterOpacity: Double = 0
    @State private var resultsOpacity: Double = 0

    var body: some View {
        ZStack {
            StarryBackground()

            if data.isHiddenMode && data.hiddenModeResults != nil {
                // Hidden mode goes straight to results (no character)
                hiddenModeContent
            } else if showingCharacter {
                // Full screen character reveal
                characterRevealView
            } else {
                // Results screen
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)

                        if data.won {
                            winContent
                        } else {
                            loseContent
                        }

                        Spacer(minLength: 40)
                    }
                }
                .opacity(resultsOpacity)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Play appropriate music
            if data.won {
                musicService.play(track: .victory, loop: false)
            } else {
                musicService.play(track: .lose, loop: false)
            }

            // Skip character reveal for hidden mode
            if data.isHiddenMode {
                showingCharacter = false
                resultsOpacity = 1
            } else {
                startCharacterReveal()
            }
        }
    }

    // MARK: - Character Reveal

    private var characterRevealView: some View {
        GeometryReader { geometry in
            let characterSize = min(geometry.size.width, geometry.size.height) * 0.7

            ZStack {
                // Confetti for wins
                if data.won {
                    ConfettiView()
                }

                VStack(spacing: 20) {
                    // Story mode: Show the chapter's alien with animation
                    if let alien = data.storyAlien {
                        Image(alien.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: characterSize, height: characterSize)
                            .alienIdleAnimation(style: data.won ? .bounce : .float, intensity: 1.0)

                        // Speech bubble with message
                        SpeechBubble {
                            Text(data.won ? alienWinMessage : alienLoseMessage)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppTheme.backgroundDark)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        // Quick Play: Show generic characters
                        if data.won {
                            AnimatedCharacter.boxer(size: characterSize)
                        } else {
                            AnimatedCharacter.spaceOctopus(size: characterSize)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .scaleEffect(characterScale)
        .opacity(characterOpacity)
        .onTapGesture {
            transitionToResults()
        }
    }

    // Alien win messages
    private var alienWinMessage: String {
        let messages = [
            "Amazing work! You did it!",
            "Fantastic! You're a star!",
            "Woohoo! Great job!",
            "You're incredible!",
            "That was awesome!"
        ]
        return messages.randomElement() ?? "Great job!"
    }

    // Alien lose/encourage messages
    private var alienLoseMessage: String {
        let messages = [
            "Don't give up! Try again!",
            "You've got this! One more try!",
            "Almost there! Keep going!",
            "You're doing great! Try again!",
            "Practice makes perfect!"
        ]
        return messages.randomElement() ?? "Try again!"
    }

    private func startCharacterReveal() {
        // Animate character in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            characterScale = 1.0
            characterOpacity = 1.0
        }

        // Auto-transition to results after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if showingCharacter {
                transitionToResults()
            }
        }
    }

    private func transitionToResults() {
        // Fade out character, then show results
        withAnimation(.easeOut(duration: 0.3)) {
            characterOpacity = 0
            characterScale = 1.2
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingCharacter = false
            withAnimation(.easeIn(duration: 0.3)) {
                resultsOpacity = 1
            }
        }
    }

    // MARK: - Hidden Mode Results

    private var hiddenModeContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                // Results Card
                VStack(spacing: 20) {
                    Text("Puzzle Complete!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Results")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)

                    if let results = data.hiddenModeResults {
                        VStack(spacing: 12) {
                            resultRow(
                                icon: "checkmark",
                                iconColor: AppTheme.accentPrimary,
                                label: "Correct:",
                                value: "\(results.correctCount)"
                            )
                            resultRow(
                                icon: "xmark",
                                iconColor: AppTheme.error,
                                label: "Mistakes:",
                                value: "\(results.mistakeCount)"
                            )
                            resultRow(
                                icon: nil,
                                iconColor: .white,
                                label: "Accuracy:",
                                value: "\(data.accuracy)%"
                            )
                            resultRow(
                                icon: nil,
                                iconColor: .white,
                                label: "Time:",
                                value: data.formattedTime
                            )
                        }
                        .padding(.vertical, 8)

                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.vertical, 8)

                        // Coins summary
                        VStack(spacing: 4) {
                            HStack {
                                Text("Coins:")
                                    .foregroundColor(.white)
                                Text("+\(data.puzzleCoins)")
                                    .foregroundColor(AppTheme.accentTertiary)
                                    .fontWeight(.bold)
                            }
                            .font(.system(size: 22))

                            Text("(\(results.correctCount * 10) earned - \(results.mistakeCount * 30) penalty)")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(28)
                .background(AppTheme.backgroundMid.opacity(0.9))
                .cornerRadius(20)
                .padding(.horizontal)

                actionButtons

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Win Content

    private var winContent: some View {
        VStack(spacing: 24) {
            // Small character at top of results with subtle animation
            if let alien = data.storyAlien {
                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .alienIdleAnimation(style: .breathe, intensity: 0.8)
            } else {
                AnimatedCharacter.boxer(size: 100)
            }

            // Results Card
            VStack(spacing: 20) {
                Text("Puzzle Complete!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                // Animated stars reveal
                AnimatedStarReveal.summary(starsEarned: data.starsEarned, delay: 0.3)
                    .padding(.vertical, 4)

                VStack(spacing: 10) {
                    HStack {
                        Text("Time:")
                            .foregroundColor(AppTheme.textSecondary)
                        Text(data.formattedTime)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .font(.system(size: 18))

                    HStack {
                        Text("Coins:")
                            .foregroundColor(AppTheme.textSecondary)
                        Text("+\(data.puzzleCoins)")
                            .foregroundColor(AppTheme.accentTertiary)
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 18))

                    HStack {
                        Text("Mistakes:")
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(data.mistakes)")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .font(.system(size: 18))
                }
            }
            .padding(28)
            .background(AppTheme.backgroundMid.opacity(0.9))
            .cornerRadius(20)
            .padding(.horizontal)

            actionButtons
        }
    }

    // MARK: - Lose Content

    private var loseContent: some View {
        VStack(spacing: 24) {
            // Small character at top of results with subtle animation
            if let alien = data.storyAlien {
                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .alienIdleAnimation(style: .breathe, intensity: 0.8)
            } else {
                AnimatedCharacter.spaceOctopus(size: 100)
            }

            // Results Card
            VStack(spacing: 20) {
                Text("Out of Lives")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("You made \(data.correctMoves) correct moves before running out of lives.")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                HStack {
                    Text("Coins:")
                        .foregroundColor(AppTheme.textSecondary)
                    Text("+\(data.puzzleCoins)")
                        .foregroundColor(AppTheme.accentTertiary)
                        .fontWeight(.bold)
                }
                .font(.system(size: 20))
            }
            .padding(28)
            .background(AppTheme.backgroundMid.opacity(0.9))
            .cornerRadius(20)
            .padding(.horizontal)

            loseActionButtons
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Play Again / Next Level
            Button(action: {
                onPlayAgain?()
            }) {
                Text(data.isStoryMode ? "Next Level" : "Play Again")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.accentPrimary)
                    .cornerRadius(12)
            }

            // Change Difficulty - only show for quick play
            if !data.isStoryMode {
                Button(action: {
                    onChangeDifficulty?()
                }) {
                    Text("Change Difficulty")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.backgroundDark)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }

            // Exit
            Button(action: {
                dismiss()
            }) {
                Text("Exit")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .padding(.horizontal)
    }

    private var loseActionButtons: some View {
        VStack(spacing: 12) {
            // Try Again
            Button(action: {
                onPlayAgain?()
            }) {
                Text("Try Again")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.accentPrimary)
                    .cornerRadius(12)
            }

            // See Solution
            if let seeSolution = onSeeSolution {
                Button(action: seeSolution) {
                    Text("See Solution")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accentSecondary)
                        .cornerRadius(12)
                }
            }

            // Exit
            Button(action: {
                dismiss()
            }) {
                Text("Exit")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func resultRow(icon: String?, iconColor: Color, label: String, value: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(label)
                    .foregroundColor(.white)
            }
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .font(.system(size: 22))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("Win") {
    SummaryScreenView(
        data: SummaryData(
            won: true,
            isHiddenMode: false,
            elapsedMs: 45000,
            puzzleCoins: 80,
            moveHistory: [],
            hiddenModeResults: nil,
            puzzle: nil,
            difficulty: DifficultyPresets.byLevel(5)
        )
    )
}

#Preview("Hidden Mode") {
    SummaryScreenView(
        data: SummaryData(
            won: true,
            isHiddenMode: true,
            elapsedMs: 60000,
            puzzleCoins: 40,
            moveHistory: [],
            hiddenModeResults: HiddenModeResults(
                moves: [],
                correctCount: 7,
                mistakeCount: 2
            ),
            puzzle: nil,
            difficulty: DifficultyPresets.byLevel(5)
        )
    )
}

#Preview("Lost") {
    SummaryScreenView(
        data: SummaryData(
            won: false,
            isHiddenMode: false,
            elapsedMs: 30000,
            puzzleCoins: 20,
            moveHistory: [],
            hiddenModeResults: nil,
            puzzle: nil,
            difficulty: DifficultyPresets.byLevel(5)
        )
    )
}
