import SwiftUI

// MARK: - SummaryScreenView

/// End-of-game summary screen showing results and actions
struct SummaryScreenView: View {
    let data: SummaryData

    @Environment(\.dismiss) private var dismiss

    /// Callback when user wants to play again / retry
    var onPlayAgain: (() -> Void)?

    /// Callback when user wants to go to next level (story mode wins only)
    var onNextLevel: (() -> Void)?

    /// Callback when user wants to change difficulty
    var onChangeDifficulty: (() -> Void)?

    /// Callback when user wants to see solution (only for lost games)
    var onSeeSolution: (() -> Void)?

    /// Callback when user wants to exit (story mode needs this to exit to level select)
    var onExit: (() -> Void)?

    // Music service
    @EnvironmentObject var musicService: MusicService

    // State for character reveal phase
    @State private var showingCharacter = true
    @State private var characterScale: CGFloat = 0.3
    @State private var characterOpacity: Double = 0
    @State private var resultsOpacity: Double = 0

    // State for chapter complete celebration (Level 5 wins)
    @State private var showingChapterComplete = false
    @State private var nextAlienScale: CGFloat = 0.1
    @State private var nextAlienOpacity: Double = 0
    @State private var nextAlienRotation: Double = -180
    @State private var chapterCompleteTextOpacity: Double = 0
    @State private var unlockGlowOpacity: Double = 0

    /// Check if this is a chapter completion (Level 7 win in story mode)
    private var isChapterComplete: Bool {
        data.isStoryMode && data.won && data.storyLevel == 7
    }

    /// Get the next chapter's alien (for unlock celebration)
    private var nextChapterAlien: ChapterAlien? {
        guard let currentChapter = data.storyChapter, currentChapter < 10 else { return nil }
        return ChapterAlien.forChapter(currentChapter + 1)
    }

    var body: some View {
        ZStack {
            StarryBackground()

            if showingChapterComplete {
                // Special chapter complete celebration with next alien reveal
                chapterCompleteCelebration
            } else if data.isHiddenMode && data.hiddenModeResults != nil && !isChapterComplete {
                // Hidden mode goes straight to results (unless chapter complete)
                hiddenModeContent
            } else if showingCharacter {
                // Full screen character reveal
                characterRevealView
            } else {
                // Results screen - use GeometryReader to fit content on screen
                GeometryReader { geometry in
                    let isExtraCompact = geometry.size.height < 580
                    let spacerMin: CGFloat = isExtraCompact ? 8 : 20

                    VStack(spacing: 0) {
                        Spacer(minLength: spacerMin)

                        if data.won {
                            winContent(screenHeight: geometry.size.height)
                        } else {
                            loseContent(screenHeight: geometry.size.height)
                        }

                        Spacer(minLength: spacerMin)
                    }
                }
                .opacity(resultsOpacity)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Chapter complete celebration for Level 5 wins
            if isChapterComplete {
                showingCharacter = false
                showingChapterComplete = true
                startChapterCompleteCelebration()
            } else if data.isHiddenMode {
                // Skip character reveal for hidden mode (non-chapter complete)
                // Play win or lose music
                if data.won {
                    musicService.play(track: .victory, loop: false)
                } else {
                    musicService.play(track: .lose, loop: false)
                }
                showingCharacter = false
                resultsOpacity = 1
            } else {
                // Regular mode with character reveal
                // Play win or lose music
                if data.won {
                    musicService.play(track: .victory, loop: false)
                } else {
                    musicService.play(track: .lose, loop: false)
                }
                startCharacterReveal()
            }
        }
    }

    // MARK: - Chapter Complete Celebration

    private var chapterCompleteCelebration: some View {
        GeometryReader { geometry in
            let alienSize = min(geometry.size.width, geometry.size.height) * 0.5

            ZStack {
                // Lots of confetti!
                ConfettiView()

                // Radial glow behind next alien
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.accentPrimary.opacity(0.6),
                                AppTheme.accentPrimary.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: alienSize * 0.8
                        )
                    )
                    .frame(width: alienSize * 1.6, height: alienSize * 1.6)
                    .opacity(unlockGlowOpacity)
                    .blur(radius: 20)

                VStack(spacing: 24) {
                    // "Chapter Complete!" text
                    VStack(spacing: 8) {
                        Text("Chapter Complete!")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: AppTheme.accentPrimary.opacity(0.8), radius: 10)

                        if let chapter = data.storyChapter {
                            Text("You finished Chapter \(chapter)!")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .opacity(chapterCompleteTextOpacity)

                    // Current alien celebrating (small)
                    if let alien = data.storyAlien {
                        Image(alien.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: alienSize * 0.5, height: alienSize * 0.5)
                            .alienIdleAnimation(style: .bounce, intensity: 1.2)
                            .opacity(characterOpacity)
                    }

                    // Next alien reveal (big, dramatic entrance)
                    if let nextAlien = nextChapterAlien {
                        VStack(spacing: 12) {
                            Text("New Friend Unlocked!")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.accentTertiary)
                                .opacity(nextAlienOpacity)

                            Image(nextAlien.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: alienSize, height: alienSize)
                                .scaleEffect(nextAlienScale)
                                .rotationEffect(.degrees(nextAlienRotation))
                                .opacity(nextAlienOpacity)
                                .shadow(color: AppTheme.accentPrimary.opacity(0.5), radius: 20)

                            Text("Meet \(nextAlien.name)!")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .opacity(nextAlienOpacity)

                            // Show the alien's fun words
                            HStack(spacing: 8) {
                                ForEach(nextAlien.words, id: \.self) { word in
                                    Text(word)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.accentPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.backgroundMid)
                                        .cornerRadius(12)
                                }
                            }
                            .opacity(nextAlienOpacity)
                        }
                    } else if data.storyChapter == 10 {
                        // Final chapter complete - special message
                        VStack(spacing: 12) {
                            Text("🏆")
                                .font(.system(size: 80))
                                .opacity(nextAlienOpacity)

                            Text("You completed ALL chapters!")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.accentTertiary)
                                .opacity(nextAlienOpacity)

                            Text("You're a Puzzle Master!")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .opacity(nextAlienOpacity)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onTapGesture {
            transitionFromChapterComplete()
        }
    }

    private func startChapterCompleteCelebration() {
        // Play victory music
        musicService.play(track: .victory, loop: false)

        // Haptic celebration
        FeedbackManager.shared.haptic(.success)

        // Phase 1: Show "Chapter Complete!" text (0s)
        withAnimation(.easeOut(duration: 0.5)) {
            chapterCompleteTextOpacity = 1.0
        }

        // Phase 2: Show current alien (0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                characterOpacity = 1.0
            }
        }

        // Phase 3: Glow starts (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.8)) {
                unlockGlowOpacity = 1.0
            }
        }

        // Phase 4: Next alien spins in dramatically (1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            FeedbackManager.shared.haptic(.medium)

            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                nextAlienScale = 1.0
                nextAlienRotation = 0
                nextAlienOpacity = 1.0
            }
        }

        // Phase 5: Another haptic when alien lands (1.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            FeedbackManager.shared.haptic(.success)
        }

        // Auto-transition to results after celebration (4.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            if showingChapterComplete {
                transitionFromChapterComplete()
            }
        }
    }

    private func transitionFromChapterComplete() {
        // Fade out celebration, then show results
        withAnimation(.easeOut(duration: 0.4)) {
            chapterCompleteTextOpacity = 0
            characterOpacity = 0
            nextAlienOpacity = 0
            unlockGlowOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showingChapterComplete = false
            withAnimation(.easeIn(duration: 0.3)) {
                resultsOpacity = 1
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

                        // Speech bubble with message (pointing up to alien)
                        SpeechBubble(pointsUp: true) {
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

    // Get the player name for personalization
    private var playerName: String {
        StorageService.shared.playerName
    }

    // Alien win messages - use alien-specific messages when in story mode
    private var alienWinMessage: String {
        // Use alien-specific win messages for story mode with personalization
        if let alien = data.storyAlien {
            return alien.personalizedWinMessage(playerName: playerName)
        }
        // Fallback for quick play
        let baseMessages = [
            "Amazing work! You did it!",
            "Fantastic! You're a star!",
            "Woohoo! Great job!",
            "You're incredible!",
            "That was awesome!"
        ]
        let baseMessage = baseMessages.randomElement() ?? "Great job!"
        if playerName.isEmpty {
            return baseMessage
        }
        return "\(baseMessage) Way to go, \(playerName)!"
    }

    // Alien lose/encourage messages
    private var alienLoseMessage: String {
        let baseMessages = [
            "Don't give up! Try again!",
            "You've got this! One more try!",
            "Almost there! Keep going!",
            "You're doing great! Try again!",
            "Practice makes perfect!"
        ]
        let baseMessage = baseMessages.randomElement() ?? "Try again!"
        if playerName.isEmpty {
            return baseMessage
        }
        // Add personalized encouragement
        let personalizedPrefixes = [
            "\(playerName), ",
            "Come on \(playerName)! ",
            "Hey \(playerName)! "
        ]
        let prefix = personalizedPrefixes.randomElement() ?? ""
        return prefix + baseMessage
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

                actionButtons()

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Win Content

    private func winContent(screenHeight: CGFloat) -> some View {
        // Three tiers: extra compact (<580), compact (<700), normal
        let isExtraCompact = screenHeight < 580
        let isCompact = screenHeight < 700

        let characterSize: CGFloat = isExtraCompact ? 50 : (isCompact ? 70 : 100)
        let titleSize: CGFloat = isExtraCompact ? 20 : (isCompact ? 24 : 32)
        let spacing: CGFloat = isExtraCompact ? 6 : (isCompact ? 12 : 24)
        let padding: CGFloat = isExtraCompact ? 12 : (isCompact ? 16 : 28)
        let statFontSize: CGFloat = isExtraCompact ? 13 : (isCompact ? 15 : 18)
        let statSpacing: CGFloat = isExtraCompact ? 2 : (isCompact ? 6 : 10)

        return VStack(spacing: spacing) {
            // Small character at top of results with subtle animation
            if let alien = data.storyAlien {
                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: characterSize, height: characterSize)
                    .alienIdleAnimation(style: .breathe, intensity: 0.8)
            } else {
                AnimatedCharacter.boxer(size: characterSize)
            }

            // Results Card
            VStack(spacing: isExtraCompact ? 6 : (isCompact ? 10 : 20)) {
                Text("Puzzle Complete!")
                    .font(.system(size: titleSize, weight: .bold))
                    .foregroundColor(.white)

                // Animated stars reveal - smaller on extra compact
                if isExtraCompact {
                    AnimatedStarReveal.summary(starsEarned: data.starsEarned, delay: 0.3, starSize: 28)
                } else {
                    AnimatedStarReveal.summary(starsEarned: data.starsEarned, delay: 0.3)
                }

                // Stats in a more compact horizontal layout for extra small screens
                if isExtraCompact {
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text(data.formattedTime)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Time")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 11))
                        }
                        VStack(spacing: 2) {
                            Text("+\(data.puzzleCoins)")
                                .foregroundColor(AppTheme.accentTertiary)
                                .fontWeight(.bold)
                            Text("Coins")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 11))
                        }
                        VStack(spacing: 2) {
                            Text("\(data.mistakes)")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Mistakes")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 11))
                        }
                    }
                    .font(.system(size: statFontSize))
                } else {
                    VStack(spacing: statSpacing) {
                        HStack {
                            Text("Time:")
                                .foregroundColor(AppTheme.textSecondary)
                            Text(data.formattedTime)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .font(.system(size: statFontSize))

                        HStack {
                            Text("Coins:")
                                .foregroundColor(AppTheme.textSecondary)
                            Text("+\(data.puzzleCoins)")
                                .foregroundColor(AppTheme.accentTertiary)
                                .fontWeight(.bold)
                        }
                        .font(.system(size: statFontSize))

                        HStack {
                            Text("Mistakes:")
                                .foregroundColor(AppTheme.textSecondary)
                            Text("\(data.mistakes)")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .font(.system(size: statFontSize))
                    }
                }
            }
            .padding(padding)
            .background(AppTheme.backgroundMid.opacity(0.9))
            .cornerRadius(isExtraCompact ? 12 : 20)
            .padding(.horizontal)

            actionButtons(compact: isCompact, extraCompact: isExtraCompact)
        }
    }

    // MARK: - Lose Content

    private func loseContent(screenHeight: CGFloat) -> some View {
        // Three tiers: extra compact (<580), compact (<700), normal
        let isExtraCompact = screenHeight < 580
        let isCompact = screenHeight < 700

        let characterSize: CGFloat = isExtraCompact ? 50 : (isCompact ? 70 : 100)
        let titleSize: CGFloat = isExtraCompact ? 18 : (isCompact ? 22 : 28)
        let spacing: CGFloat = isExtraCompact ? 6 : (isCompact ? 12 : 24)
        let padding: CGFloat = isExtraCompact ? 12 : (isCompact ? 16 : 28)

        return VStack(spacing: spacing) {
            // Small character at top of results with subtle animation
            if let alien = data.storyAlien {
                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: characterSize, height: characterSize)
                    .alienIdleAnimation(style: .breathe, intensity: 0.8)
            } else {
                AnimatedCharacter.spaceOctopus(size: characterSize)
            }

            // Results Card
            VStack(spacing: isExtraCompact ? 6 : (isCompact ? 10 : 20)) {
                Text("Out of Lives")
                    .font(.system(size: titleSize, weight: .bold))
                    .foregroundColor(.white)

                Text("You made \(data.correctMoves) correct moves before running out of lives.")
                    .font(.system(size: isExtraCompact ? 12 : (isCompact ? 13 : 15)))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                HStack {
                    Text("Coins:")
                        .foregroundColor(AppTheme.textSecondary)
                    Text("+\(data.puzzleCoins)")
                        .foregroundColor(AppTheme.accentTertiary)
                        .fontWeight(.bold)
                }
                .font(.system(size: isExtraCompact ? 14 : (isCompact ? 16 : 20)))
            }
            .padding(padding)
            .background(AppTheme.backgroundMid.opacity(0.9))
            .cornerRadius(isExtraCompact ? 12 : 20)
            .padding(.horizontal)

            loseActionButtons(compact: isCompact, extraCompact: isExtraCompact)
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(compact: Bool = false, extraCompact: Bool = false) -> some View {
        let buttonPadding: CGFloat = extraCompact ? 8 : (compact ? 12 : 16)
        let fontSize: CGFloat = extraCompact ? 14 : (compact ? 15 : 17)
        let spacing: CGFloat = extraCompact ? 4 : (compact ? 8 : 12)
        let cornerRadius: CGFloat = extraCompact ? 8 : 12

        return VStack(spacing: spacing) {
            if data.isStoryMode && data.won {
                // Story mode WIN: Show both Retry and Next Level
                // On extra compact screens, show them in a horizontal row
                if extraCompact {
                    HStack(spacing: 8) {
                        // Next Level is primary (green)
                        Button(action: {
                            onNextLevel?()
                        }) {
                            Text("Next Level")
                                .font(.system(size: fontSize, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, buttonPadding)
                                .background(AppTheme.accentPrimary)
                                .cornerRadius(cornerRadius)
                        }

                        // Retry (secondary style)
                        Button(action: {
                            onPlayAgain?()
                        }) {
                            Text("Retry")
                                .font(.system(size: fontSize, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, buttonPadding)
                                .background(AppTheme.backgroundDark)
                                .cornerRadius(cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: cornerRadius)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                } else {
                    // Next Level is primary (green)
                    Button(action: {
                        onNextLevel?()
                    }) {
                        Text("Next Level")
                            .font(.system(size: fontSize, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, buttonPadding)
                            .background(AppTheme.accentPrimary)
                            .cornerRadius(cornerRadius)
                    }

                    // Retry to try for more stars (secondary style)
                    Button(action: {
                        onPlayAgain?()
                    }) {
                        Text("Retry")
                            .font(.system(size: fontSize, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, buttonPadding)
                            .background(AppTheme.backgroundDark)
                            .cornerRadius(cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            } else if data.isStoryMode && !data.won {
                // Story mode LOSS: Only show Retry button (no Next Level)
                Button(action: {
                    onPlayAgain?()
                }) {
                    Text("Try Again")
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, buttonPadding)
                        .background(AppTheme.accentPrimary)
                        .cornerRadius(cornerRadius)
                }
            } else {
                // Quick Play: Play Again button
                Button(action: {
                    onPlayAgain?()
                }) {
                    Text("Play Again")
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, buttonPadding)
                        .background(AppTheme.accentPrimary)
                        .cornerRadius(cornerRadius)
                }

                // Change Difficulty
                Button(action: {
                    onChangeDifficulty?()
                }) {
                    Text("Change Difficulty")
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, buttonPadding)
                        .background(AppTheme.backgroundDark)
                        .cornerRadius(cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }

            // Exit
            Button(action: handleExit) {
                Text("Exit")
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, extraCompact ? 6 : (compact ? 10 : 16))
            }
        }
        .padding(.horizontal)
    }

    private func handleExit() {
        if let onExit = onExit {
            onExit()
        } else {
            dismiss()
        }
    }

    private func loseActionButtons(compact: Bool = false, extraCompact: Bool = false) -> some View {
        let buttonPadding: CGFloat = extraCompact ? 8 : (compact ? 12 : 16)
        let fontSize: CGFloat = extraCompact ? 14 : (compact ? 15 : 17)
        let spacing: CGFloat = extraCompact ? 4 : (compact ? 8 : 12)
        let cornerRadius: CGFloat = extraCompact ? 8 : 12

        return VStack(spacing: spacing) {
            // On extra compact, show Try Again and See Solution in a row
            if extraCompact {
                HStack(spacing: 8) {
                    // Try Again
                    Button(action: {
                        onPlayAgain?()
                    }) {
                        Text("Try Again")
                            .font(.system(size: fontSize, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, buttonPadding)
                            .background(AppTheme.accentPrimary)
                            .cornerRadius(cornerRadius)
                    }

                    // See Solution
                    if let seeSolution = onSeeSolution {
                        Button(action: seeSolution) {
                            Text("Solution")
                                .font(.system(size: fontSize, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, buttonPadding)
                                .background(AppTheme.accentSecondary)
                                .cornerRadius(cornerRadius)
                        }
                    }
                }
            } else {
                // Try Again
                Button(action: {
                    onPlayAgain?()
                }) {
                    Text("Try Again")
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, buttonPadding)
                        .background(AppTheme.accentPrimary)
                        .cornerRadius(cornerRadius)
                }

                // See Solution
                if let seeSolution = onSeeSolution {
                    Button(action: seeSolution) {
                        Text("See Solution")
                            .font(.system(size: fontSize, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, buttonPadding)
                            .background(AppTheme.accentSecondary)
                            .cornerRadius(cornerRadius)
                    }
                }
            }

            // Exit
            Button(action: handleExit) {
                Text("Exit")
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, extraCompact ? 6 : (compact ? 10 : 16))
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
