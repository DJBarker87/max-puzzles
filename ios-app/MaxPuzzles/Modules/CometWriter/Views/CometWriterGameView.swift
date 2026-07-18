import SwiftUI

enum CometWriterLayoutPolicy {
    static func tracePrecedesSidebar(isWide: Bool, writingHand: WritingHand) -> Bool {
        isWide && writingHand == .left
    }
}

enum CometWriterAutomaticSpeechPolicy {
    nonisolated static let deferredRecordingFailureAnnouncement =
        "The recording could not play. Choose Hear to try again."

    nonisolated static func shouldSpeak(
        isVoiceOverRunning: Bool,
        isHearCue: Bool,
        isWordMission: Bool
    ) -> Bool {
        !isVoiceOverRunning && (isHearCue || isWordMission)
    }

    nonisolated static func shouldStartDeferredRecordingFallback(
        isVoiceOverRunning: Bool
    ) -> Bool {
        !isVoiceOverRunning
    }
}

enum CometWriterRecallCuePolicy {
    nonisolated static func startsWithHearCue(for mission: AdvancedWritingMission) -> Bool {
        mission == .phonics
    }
}

enum CometWriterFeedbackAccessibilityCopy {
    nonisolated static func label(
        visibleMessage: String,
        isLetterComplete: Bool
    ) -> String {
        isLetterComplete ? "Letter complete." : visibleMessage
    }
}

struct CometWriterRecallSpeechRecovery: Equatable {
    let shouldRevealCue: Bool
    let shouldShowRetry: Bool

    nonisolated static func afterPlaybackAttempt(started: Bool) -> Self {
        Self(shouldRevealCue: !started, shouldShowRetry: !started)
    }
}

enum CometWriterWordAccessibilityCopy {
    nonisolated static func spokenWordDescription(for word: String) -> String {
        let cleaned = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count > 1, cleaned == cleaned.uppercased() else {
            return cleaned
        }

        return cleaned.prefix(1).uppercased() + cleaned.dropFirst().lowercased()
    }

    nonisolated static func oneLetterSoundDescription(for word: String) -> String? {
        let cleaned = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = cleaned.lowercased()
        guard cleaned.count == 1,
              lowercased != "a",
              lowercased != "i",
              LetterSpeechService.phonemeIDs(forLetter: cleaned) != nil,
              let glyph = LetterLibrary.glyph(for: cleaned) else { return nil }
        let location = lowercased == "x" ? "at the end of" : "at the start of"
        return "the one-letter sound \(location) \(glyph.exampleWord)"
    }

    nonisolated static func targetDescription(for word: String) -> String {
        oneLetterSoundDescription(for: word)
            ?? spokenWordDescription(for: word)
    }

    nonisolated static func writingSurfaceDescription(for word: String) -> String {
        if let soundDescription = oneLetterSoundDescription(for: word) {
            return soundDescription
        }
        return "the word \(spokenWordDescription(for: word))"
    }

    nonisolated static func characterDescription(_ character: String, in word: String) -> String {
        oneLetterSoundDescription(for: word)
            ?? oneLetterSoundDescription(for: character)
            ?? character
    }

    nonisolated static func writingPromptLabel(
        for word: String,
        activeCharacter: String,
        activeIndex: Int,
        characterCount: Int
    ) -> String {
        let target = targetDescription(for: word)
        let position = "letter \(activeIndex + 1) of \(characterCount)"
        if oneLetterSoundDescription(for: word) != nil {
            return "Write \(target) on one writing surface, \(position)"
        }
        let activeDescription = characterDescription(activeCharacter, in: word)
        return "Write \(target) on one writing surface, \(position), \(activeDescription)"
    }

    nonisolated static func hearLabel(for word: String) -> String {
        if let soundDescription = oneLetterSoundDescription(for: word) {
            return "Hear \(soundDescription)"
        }
        return "Hear the word \(spokenWordDescription(for: word))"
    }
}

struct CometWriterGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @EnvironmentObject private var musicService: MusicService
    @StateObject private var viewModel: CometWriterViewModel
    @ObservedObject private var learningStore = CometLearningStore.shared
    @AppStorage("maxpuzzles.cometWriter.pencilOnly") private var pencilOnly = false
    @AppStorage("maxpuzzles.cometWriter.letterScale") private var letterScale = Double(LetterDisplayTransform.defaultScale)
    @AppStorage("maxpuzzles.cometWriter.showsWritingLines") private var showsWritingLines = true
    @AppStorage("maxpuzzles.cometWriter.cometPoints") private var cometPoints = 0
    @AppStorage("maxpuzzles.cometWriter.accuracyStreak") private var accuracyStreak = 0
    @AppStorage("maxpuzzles.cometWriter.bestAccuracyStreak") private var bestAccuracyStreak = 0
    @State private var showsWritingTools = false
    @State private var showsExitConfirmation = false
    @State private var latestReward: CometReward?
    @State private var requiredAudioToken: UUID?
    @State private var didSpeechFail = false

    private let speech = LetterSpeechService.shared

    private var isVoiceOverRunning: Bool {
        voiceOverEnabled || UIAccessibility.isVoiceOverRunning
    }

    init(startingGlyph: LetterGlyph) {
        _viewModel = StateObject(wrappedValue: CometWriterViewModel(glyph: startingGlyph))
    }

    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height

            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()
                // Precision play needs a completely stable visual reference frame.
                StarryBackground(starCount: 28, animateStars: false)

                if isWide {
                    HStack(spacing: AppSpacing.lg) {
                        if CometWriterLayoutPolicy.tracePrecedesSidebar(
                            isWide: isWide,
                            writingHand: learningStore.activeWritingHand
                        ) {
                            traceArea
                                .frame(maxHeight: geometry.size.height - AppSpacing.md * 2)
                            sidebar
                                .frame(width: min(300, geometry.size.width * 0.32))
                        } else {
                            sidebar
                                .frame(width: min(300, geometry.size.width * 0.32))
                            traceArea
                                .frame(maxHeight: geometry.size.height - AppSpacing.md * 2)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                } else {
                    VStack(spacing: 12) {
                        gameHeader
                        promptCard
                        traceArea
                        feedbackPill
                        actionRow
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
                }

                if viewModel.isRoundComplete {
                    completionOverlay
                }
            }
            // The precision surface must retain enough physical height for a child's hand.
            // Accessibility sizes remain enlarged, while the fixed game chrome stops growing
            // after AX1; all longer explanatory screens remain scrollable at the user's full size.
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showsWritingTools) {
            CometWriterToolsSheet(
                pencilOnly: $pencilOnly,
                letterScale: $letterScale,
                showsWritingLines: $showsWritingLines,
                writingHand: Binding(
                    get: { learningStore.activeWritingHand },
                    set: { learningStore.setWritingHand($0) }
                )
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if requiredAudioToken == nil {
                requiredAudioToken = musicService.beginRequiredAudioSession()
            }
            pencilOnly = TraceInputPolicy.resolvedPencilOnly(
                pencilOnly,
                supportsApplePencil: UIDevice.current.userInterfaceIdiom == .pad
            )
            StorageService.shared.setLastCometWriterLetter(viewModel.glyph.character)
            if StorageService.shared.isVoiceEnabled && !isVoiceOverRunning {
                speakCurrentGlyph()
            }
        }
        .onDisappear {
            viewModel.stopHint()
            speech.stop()
            if let requiredAudioToken {
                musicService.endRequiredAudioSession(requiredAudioToken)
                self.requiredAudioToken = nil
            }
        }
        .onReceive(speech.$playbackState) { state in
            switch state {
            case .idle:
                break
            case .playing:
                didSpeechFail = false
            case .failed:
                didSpeechFail = true
            }
        }
        .onChange(of: viewModel.isLetterComplete) { isComplete in
            guard isComplete else { return }
            StorageService.shared.markCometWriterLetterCompleted(viewModel.glyph.character)
            awardCompletedLetter()
        }
        .alert("Leave this writing session?", isPresented: $showsExitConfirmation) {
            Button("Keep practising", role: .cancel) {}
            Button("Leave session", role: .destructive) { dismiss() }
        } message: {
            Text("Completed attempts are saved, but the current unfinished letter will reset.")
        }
        // Keep the screen marker separate so it cannot overwrite identifiers on the direct-
        // interaction writing pad or the child-facing controls around it.
        .background {
            Color.clear
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Comet Writer game")
                .accessibilityIdentifier("comet-writer-game")
        }
    }

    private var gameHeader: some View {
        HStack(spacing: 12) {
            PremiumIconButton(
                icon: "chevron.left",
                action: requestExit,
                size: 48,
                accessibilityLabelText: "Back to letter missions"
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("Round \(viewModel.roundNumber) of 3")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                Text(viewModel.assistance.title)
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
            }

            Spacer()

            scoreBadge

            PremiumIconButton(
                icon: "speaker.wave.2.fill",
                action: speakCurrentGlyph,
                size: 48,
                iconColor: AppTheme.cometCyan,
                accessibilityLabelText: "Hear the letter instructions"
            )
        }
    }

    private var scoreBadge: some View {
        Label("\(displayedCometPoints)", systemImage: "sparkles")
            .font(AppTypography.buttonSmall)
            .foregroundColor(AppTheme.cometGold)
            .padding(.horizontal, 10)
            .frame(minHeight: 36)
            .background(Capsule().fill(AppTheme.cometPaperTop))
            .accessibilityLabel("\(displayedCometPoints) Comet Points")
    }

    private var promptCard: some View {
        HStack(spacing: AppSpacing.md) {
            Text(viewModel.glyph.character)
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundColor(AppTheme.cometCyan)
                .frame(width: 72)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.glyph.promptTitle)
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)

                Text(viewModel.glyph.formationCue)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.backgroundMid.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppTheme.cometPurple.opacity(0.38), lineWidth: 1)
        )
    }

    private var traceArea: some View {
        LetterTracePad(
            viewModel: viewModel,
            letterScale: CGFloat(letterScale),
            pencilOnly: pencilOnly,
            showsWritingLines: showsWritingLines
        )
            .frame(maxWidth: 660, maxHeight: .infinity)
            .aspectRatio(1.18, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var feedbackPill: some View {
        HStack(spacing: 8) {
            Image(systemName: feedbackIcon)
                .foregroundColor(feedbackColor)
            Text(currentFeedbackMessage)
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(Capsule().fill(AppTheme.backgroundMid.opacity(0.92)))
        .overlay(
            Capsule()
                .stroke(
                    feedbackColor.opacity(
                        didSpeechFail || viewModel.feedbackTone == .correction ? 0.72 : 0.18
                    ),
                    lineWidth: 1.5
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(currentFeedbackMessage)
    }

    private var currentFeedbackMessage: String {
        didSpeechFail
            ? "The voice could not play. Tap the speaker to try again."
            : viewModel.feedbackMessage
    }

    private var feedbackIcon: String {
        if didSpeechFail { return "speaker.slash.fill" }
        switch viewModel.feedbackTone {
        case .instruction: return "paperplane.fill"
        case .success: return "star.fill"
        case .correction: return "arrow.uturn.backward.circle.fill"
        }
    }

    private var feedbackColor: Color {
        if didSpeechFail { return AppTheme.cometGold }
        switch viewModel.feedbackTone {
        case .instruction: return AppTheme.cometCyan
        case .success: return AppTheme.accentPrimary
        case .correction: return AppTheme.cometGold
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            actionButton(title: "Restart", icon: "arrow.counterclockwise") {
                viewModel.retryCurrentStroke()
            }

            actionButton(title: "Show path", icon: "play.fill") {
                viewModel.showHint(animated: !reduceMotion)
                speech.speakPathPrompt(for: viewModel.glyph, animated: !reduceMotion)
            }
            .accessibilityIdentifier("comet-writer-show-path")
            .accessibilityValue(viewModel.isDemonstrating ? "Playing" : "Ready")
            .accessibilityHint("Shows the correct start point, stroke order, and direction")

            actionButton(title: "Tools", icon: "slider.horizontal.3") {
                viewModel.stopHint()
                viewModel.cancelActiveTrace()
                showsWritingTools = true
            }
            .accessibilityIdentifier("comet-writer-writing-tools")
            .accessibilityValue(
                UIDevice.current.userInterfaceIdiom == .pad
                    ? (pencilOnly ? "Apple Pencil only" : "Finger or Apple Pencil")
                    : "Finger drawing"
            )
            .accessibilityHint("Changes drawing input, writing lines, and letter size")
        }
    }

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.backgroundMid.opacity(0.92))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var sidebar: some View {
        VStack(spacing: 10) {
            compactHeader
            compactPrompt
            Label("Green star  →  follow the arrow  →  gold ring", systemImage: "sparkles")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.cometGold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.backgroundMid.opacity(0.84))
                )
            feedbackPill
            actionRow
            Spacer(minLength: 0)
        }
    }

    private var compactHeader: some View {
        HStack(spacing: 10) {
            PremiumIconButton(
                icon: "chevron.left",
                action: requestExit,
                size: 44,
                accessibilityLabelText: "Back to letter missions"
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Round \(viewModel.roundNumber) of 3")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                Text(viewModel.assistance.title)
                    .font(AppTypography.buttonMedium)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)

            scoreBadge

            PremiumIconButton(
                icon: "speaker.wave.2.fill",
                action: speakCurrentGlyph,
                size: 44,
                iconColor: AppTheme.cometCyan,
                accessibilityLabelText: "Hear the letter instructions"
            )
        }
    }

    private var compactPrompt: some View {
        HStack(spacing: 12) {
            Text(viewModel.glyph.character)
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundColor(AppTheme.cometCyan)
                .frame(width: 54)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.glyph.promptTitle)
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.textPrimary)
                Text(viewModel.assistance.instruction)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.backgroundMid.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cometPurple.opacity(0.38), lineWidth: 1)
        )
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()

            if viewModel.isLetterComplete && !reduceMotion {
                ConfettiView(intensity: .light)
                    .ignoresSafeArea()
            }

            VStack(spacing: AppSpacing.md) {
                if viewModel.isLetterComplete {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: index < viewModel.earnedStars ? "star.fill" : "star")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(AppTheme.cometGold)
                        }
                    }

                    Text(viewModel.glyph.isNumber ? "Number complete!" : "Letter complete!")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("You formed \(viewModel.glyph.formationName) from the right place and in the right direction.")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    if let latestReward {
                        rewardSummary(latestReward)
                    }

                    if let next = LetterLibrary.next(after: viewModel.glyph) {
                        PrimaryButton("Next: \(next.character)", icon: "arrow.right", size: .large) {
                            latestReward = nil
                            didSpeechFail = false
                            viewModel.load(next)
                            StorageService.shared.setLastCometWriterLetter(next.character)
                            if !isVoiceOverRunning {
                                speakCurrentGlyph()
                            }
                        }
                        .accessibilityIdentifier("comet-writer-next-letter")
                    } else {
                        PrimaryButton("Back to missions", icon: "checkmark", size: .large) {
                            dismiss()
                        }
                    }
                } else {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 58))
                        .foregroundColor(AppTheme.cometGold)

                    Text("Trail \(viewModel.roundNumber) complete")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(nextRoundCopy)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    PrimaryButton("Next round", icon: "arrow.right", size: .large) {
                        viewModel.advanceRound()
                    }
                    .accessibilityIdentifier("comet-writer-next-round")
                }
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(AppTheme.backgroundMid)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(AppTheme.cometCyan.opacity(0.5), lineWidth: 1)
            )
            .padding(AppSpacing.lg)
            .accessibilityElement(children: .contain)
        }
    }

    private var nextRoundCopy: String {
        let next = TraceAssistance(rawValue: viewModel.assistance.rawValue + 1)
        return next.map { "Next: \($0.title.lowercased())." } ?? "Wonderful writing."
    }

    private func speakCurrentGlyph() {
        didSpeechFail = false
        if !speech.speak(viewModel.glyph) {
            didSpeechFail = true
        }
    }

    private func awardCompletedLetter() {
        let metrics = viewModel.performanceMetrics
        let reward = CometRewardCalculator.reward(metrics: metrics)
        cometPoints += reward.points
        StorageService.shared.recordCometWriterScore(
            reward.score,
            for: viewModel.glyph.character
        )
        CometLearningStore.shared.recordAttempt(
            character: viewModel.glyph.character,
            mode: .guided,
            reward: reward,
            metrics: metrics,
            traces: viewModel.completedTraces
        )
        if reward.isPerfect {
            accuracyStreak += 1
            bestAccuracyStreak = max(bestAccuracyStreak, accuracyStreak)
        } else {
            accuracyStreak = 0
        }
        latestReward = reward
    }

    private func requestExit() {
        guard !viewModel.isLetterComplete else {
            dismiss()
            return
        }
        viewModel.cancelActiveTrace()
        showsExitConfirmation = true
    }

    private func rewardSummary(_ reward: CometReward) -> some View {
        VStack(spacing: 7) {
            HStack(spacing: 14) {
                VStack(spacing: 0) {
                    Text("\(reward.score)")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .foregroundColor(AppTheme.accentPrimary)
                    Text("out of 100")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(reward.encouragement)
                        .font(AppTypography.buttonLarge)
                        .foregroundColor(AppTheme.textPrimary)
                    Label("+\(reward.characterPoints) Comet Points", systemImage: "sparkles")
                        .font(AppTypography.buttonMedium)
                        .foregroundColor(AppTheme.cometGold)
                    Text("Formation score ÷ 10")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            if reward.isPerfect {
                Text("Perfect formation · \(displayedAccuracyStreak) streak")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.accentPrimary)
            }

            HStack(spacing: 10) {
                scorePart("Path", reward.breakdown.pathAccuracy, 40)
                scorePart("Moves", reward.breakdown.formation, 25)
                scorePart("Lines", reward.breakdown.linePlacement, 15)
                scorePart("Smooth", reward.breakdown.smoothness, 10)
                scorePart("Solo", reward.breakdown.independence, 10)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("comet-writer-letter-score")
        .accessibilityLabel("Formation score \(reward.score) out of 100, earned \(reward.characterPoints) Comet Points")
    }

    private func scorePart(_ title: String, _ score: Int, _ maximum: Int) -> some View {
        VStack(spacing: 1) {
            Text("\(score)/\(maximum)")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(AppTheme.cometCyan)
            Text(title)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var displayedCometPoints: Int {
        learningStore.profiles.count == 1 ? cometPoints : learningStore.activePoints
    }

    private var displayedAccuracyStreak: Int {
        learningStore.profiles.count == 1 ? accuracyStreak : learningStore.activePerfectStreak
    }
}

private enum RecallCueStyle: String, CaseIterable {
    case see = "See it"
    case hear = "Hear it"
}

struct AdvancedWritingGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @EnvironmentObject private var musicService: MusicService

    let mission: AdvancedWritingMission
    private let recallCharacters: [String]
    private let missionWords: [String]
    private let sessionTarget: Int
    private let completionButtonTitle: String?
    private let onSessionComplete: (() -> Void)?
    @StateObject private var viewModel: CometWriterViewModel
    @ObservedObject private var learningStore = CometLearningStore.shared

    @AppStorage("maxpuzzles.cometWriter.pencilOnly") private var pencilOnly = false
    @AppStorage("maxpuzzles.cometWriter.letterScale") private var letterScale = Double(LetterDisplayTransform.defaultScale)
    @AppStorage("maxpuzzles.cometWriter.showsWritingLines") private var showsWritingLines = true
    @AppStorage("maxpuzzles.cometWriter.cometPoints") private var cometPoints = 0
    @AppStorage("maxpuzzles.cometWriter.accuracyStreak") private var accuracyStreak = 0
    @AppStorage("maxpuzzles.cometWriter.bestAccuracyStreak") private var bestAccuracyStreak = 0

    @State private var cueStyle: RecallCueStyle = .see
    @State private var recallIndex = 0
    @State private var wordIndex = 0
    @State private var characterIndex = 0
    @State private var showsWritingTools = false
    @State private var latestReward: CometReward?
    @State private var wordAttempts: [WordLetterAttempt] = []
    @State private var autoAdvanceTask: Task<Void, Never>?
    @State private var sessionItemsCompleted = 0
    @State private var sessionRewards: [CometReward] = []
    @State private var isSessionComplete = false
    @State private var showsExitConfirmation = false
    @State private var requiredAudioToken: UUID?
    @State private var didSpeechFail = false

    private let speech = LetterSpeechService.shared
    init(
        mission: AdvancedWritingMission,
        recallCharacters: [String] = LetterRecallCatalog.teachingOrder,
        words: [String] = [],
        sessionLength: Int = 5,
        allowsShortWords: Bool = false,
        completionButtonTitle: String? = nil,
        onSessionComplete: (() -> Void)? = nil
    ) {
        self.mission = mission
        self.completionButtonTitle = completionButtonTitle
        self.onSessionComplete = onSessionComplete
        let resolvedSessionLength = min(max(sessionLength, 1), 8)
        sessionTarget = resolvedSessionLength
        let requestedRecallLetters = LetterRecallCatalog.orderedSelection(Set(recallCharacters))
        let resolvedRecallLetters = requestedRecallLetters.isEmpty
            ? LetterRecallCatalog.teachingOrder
            : requestedRecallLetters
        let adaptiveRecall = CometLearningStore.shared.recommendedCharacters(
            from: resolvedRecallLetters,
            count: min(resolvedSessionLength, resolvedRecallLetters.count)
        )
        let finalRecallCharacters = adaptiveRecall.isEmpty ? resolvedRecallLetters : adaptiveRecall
        self.recallCharacters = finalRecallCharacters

        let validWords = words
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.allSatisfy { LetterLibrary.glyph(for: String($0)) != nil } }
        let resolvedWords = validWords.isEmpty ? CometLearningStore.shared.availableWords : validWords
        // A whole-word mission must actually require several letters. Starting with "a" or "I"
        // turns the advanced exercise back into single-letter recall and creates a portrait-tall
        // writing pad instead of the intended one-screen horizontal word surface.
        let requiresWholeWord = mission == .wordWriting || mission == .alienMail
        let multiLetterWords = resolvedWords.filter { $0.count >= 3 }
        let fallbackMultiLetterWords = CometLearningStore.shared.availableWords.filter { $0.count >= 3 }
        let wordsForMission: [String]
        if requiresWholeWord && !allowsShortWords {
            wordsForMission = multiLetterWords.isEmpty ? fallbackMultiLetterWords : multiLetterWords
        } else {
            wordsForMission = resolvedWords
        }
        missionWords = Array(wordsForMission.prefix(max(1, min(resolvedSessionLength, wordsForMission.count))))

        let isRecall = mission == .letterRecall || mission == .phonics
        let firstCharacter = isRecall
            ? finalRecallCharacters[0]
            : String(missionWords[0].first!)
        _cueStyle = State(initialValue: mission == .phonics ? .hear : .see)
        _viewModel = StateObject(
            wrappedValue: CometWriterViewModel(
                glyph: LetterLibrary.glyph(for: firstCharacter)!,
                assistance: .flySolo
            )
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height

            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()
                StarryBackground(starCount: 28, animateStars: false)

                Group {
                    if isWide {
                        HStack(spacing: AppSpacing.lg) {
                            if learningStore.activeWritingHand == .left {
                                traceArea
                                    .frame(maxHeight: geometry.size.height - AppSpacing.md * 2)
                                challengeSidebar
                                    .frame(width: min(310, geometry.size.width * 0.34))
                            } else {
                                challengeSidebar
                                    .frame(width: min(310, geometry.size.width * 0.34))
                                traceArea
                                    .frame(maxHeight: geometry.size.height - AppSpacing.md * 2)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                    } else {
                        VStack(spacing: 10) {
                            challengeHeader
                            challengePrompt
                            traceArea
                            feedbackPill
                            actionRow
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.md)
                    }
                }
                .accessibilityHidden(isBlockingOverlayPresented)

                if isSessionComplete {
                    sessionSummaryOverlay
                } else if viewModel.isLetterComplete &&
                    (isRecallMission || isCurrentWordComplete) {
                    completionOverlay
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showsWritingTools) {
            CometWriterToolsSheet(
                pencilOnly: $pencilOnly,
                letterScale: $letterScale,
                showsWritingLines: $showsWritingLines,
                writingHand: Binding(
                    get: { learningStore.activeWritingHand },
                    set: { learningStore.setWritingHand($0) }
                )
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if requiredAudioToken == nil {
                requiredAudioToken = musicService.beginRequiredAudioSession()
            }
            if UIDevice.current.userInterfaceIdiom != .pad {
                pencilOnly = false
            }
            if shouldAutomaticallySpeakCurrentTarget {
                speakCurrentTarget()
            }
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
            viewModel.stopHint()
            speech.stop()
            CustomPromptAudioService.shared.stopPlayback()
            if let requiredAudioToken {
                musicService.endRequiredAudioSession(requiredAudioToken)
                self.requiredAudioToken = nil
            }
        }
        .onReceive(speech.$playbackState) { state in
            switch state {
            case .idle:
                break
            case .playing:
                didSpeechFail = false
            case .failed:
                didSpeechFail = true
                if isRecallMission {
                    // A hidden target with failed audio is impossible. Reveal the letter for both
                    // recall modes while leaving Hear available for an explicit retry.
                    cueStyle = .see
                }
            }
        }
        .onChange(of: viewModel.isLetterComplete) { complete in
            guard complete else { return }
            awardSuccess()
            if isWordMission && !isCurrentWordComplete {
                scheduleNextWordLetter()
            }
        }
        .alert("Leave this writing mission?", isPresented: $showsExitConfirmation) {
            Button("Keep practising", role: .cancel) {}
            Button("Leave mission", role: .destructive) { dismiss() }
        } message: {
            Text("Finished attempts are saved, but the current unfinished challenge will reset.")
        }
        // Keep the screen marker separate so it does not overwrite identifiers on the word pad
        // and its direct-interaction writing surface.
        .background {
            Color.clear
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(missionTitle) game"
                )
                .accessibilityIdentifier("comet-writer-advanced-game")
        }
    }

    private var challengeHeader: some View {
        HStack(spacing: 12) {
            PremiumIconButton(
                icon: "chevron.left",
                action: requestExit,
                size: 48,
                accessibilityLabelText: "Back to writing missions"
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(missionTitle)
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Mission \(min(sessionItemsCompleted + 1, sessionTarget)) of \(sessionTarget) · start star only")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.cometCyan)
            }

            Spacer(minLength: 0)
            scoreBadge
        }
    }

    private var scoreBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Label("\(displayedCometPoints)", systemImage: "sparkles")
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.cometGold)
            if displayedAccuracyStreak > 1 {
                Text("\(displayedAccuracyStreak) streak")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.accentPrimary)
            }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 44)
        .background(Capsule().fill(AppTheme.cometPaperTop))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayedCometPoints) Comet Points, \(displayedAccuracyStreak) first-try streak")
    }

    @ViewBuilder
    private var challengePrompt: some View {
        if isRecallMission {
            recallPrompt
        } else {
            wordPrompt
        }
    }

    private var recallPrompt: some View {
        HStack(spacing: 12) {
            Text(cueStyle == .see ? viewModel.glyph.character : "?")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundColor(cueStyle == .see ? AppTheme.cometCyan : AppTheme.cometPurple)
                .frame(width: 62)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text(cueStyle == .see ? "Write this letter" : "Listen, then write")
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Only the correct start star is shown.")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)

                if didSpeechFail {
                    Text(recallSpeechFailureMessage)
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.cometGold)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 8) {
                    if mission != .phonics {
                        cueButton(.see, icon: "eye.fill")
                    }
                    cueButton(.hear, icon: "speaker.wave.2.fill")
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 10)
        .challengeCardStyle()
        .accessibilityIdentifier("comet-writer-recall-prompt")
    }

    private func cueButton(_ style: RecallCueStyle, icon: String) -> some View {
        Button {
            cueStyle = style
            if style == .hear { speakCurrentTarget() }
        } label: {
            Label(style.rawValue, systemImage: icon)
                .font(AppTypography.caption)
                .foregroundColor(cueStyle == style ? AppTheme.backgroundDark : AppTheme.textPrimary)
                .padding(.horizontal, 10)
                .frame(minHeight: 36)
                .background(
                    Capsule().fill(cueStyle == style ? AppTheme.cometCyan : AppTheme.cometPaperTop)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(cueStyle == style ? .isSelected : [])
    }

    private var wordPrompt: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(mission == .alienMail ? "Write your message" : "Write the word")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 8) {
                    ForEach(Array(wordCharacters.enumerated()), id: \.offset) { index, character in
                        VStack(spacing: 2) {
                            Text(character)
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                                .foregroundColor(wordCharacterColor(at: index))
                                .frame(minWidth: 28)
                                .overlay(alignment: .bottom) {
                                    if index == characterIndex {
                                        Capsule()
                                            .fill(AppTheme.cometCyan)
                                            .frame(height: 3)
                                            .offset(y: 5)
                                    }
                                }

                            if wordAttempts.indices.contains(index) {
                                Text("\(wordAttempts[index].reward.score)")
                                    .font(.system(.caption2, design: .rounded, weight: .bold))
                                    .foregroundColor(AppTheme.accentPrimary)
                            }
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    CometWriterWordAccessibilityCopy.writingPromptLabel(
                        for: currentWord,
                        activeCharacter: viewModel.glyph.character,
                        activeIndex: characterIndex,
                        characterCount: wordCharacters.count
                    )
                )

                if didSpeechFail {
                    Text("The word could not play. Tap Hear to try again.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.cometGold)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            PremiumIconButton(
                icon: "speaker.wave.2.fill",
                action: { speakCurrentTarget() },
                size: 48,
                iconColor: AppTheme.cometCyan,
                accessibilityLabelText: CometWriterWordAccessibilityCopy.hearLabel(
                    for: currentWord
                )
            )
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
        .challengeCardStyle()
        .accessibilityIdentifier("comet-writer-word-prompt")
    }

    @ViewBuilder
    private var traceArea: some View {
        if isWordMission {
            WordMissionTracePad(
                viewModel: viewModel,
                characters: wordCharacters,
                activeIndex: characterIndex,
                completedAttempts: wordAttempts,
                letterScale: CGFloat(letterScale),
                pencilOnly: pencilOnly,
                showsWritingLines: showsWritingLines
            )
            .frame(maxWidth: 760, maxHeight: .infinity)
            .aspectRatio(
                WordMissionLayout.aspectRatio(characterCount: wordCharacters.count),
                contentMode: .fit
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            LetterTracePad(
                viewModel: viewModel,
                letterScale: CGFloat(letterScale),
                pencilOnly: pencilOnly,
                showsWritingLines: showsWritingLines
            )
            .frame(maxWidth: 660, maxHeight: .infinity)
            .aspectRatio(1.18, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var feedbackPill: some View {
        HStack(spacing: 8) {
            Image(systemName: feedbackIcon)
                .foregroundColor(feedbackColor)
            Text(viewModel.feedbackMessage)
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(Capsule().fill(AppTheme.backgroundMid.opacity(0.92)))
        .overlay(Capsule().stroke(feedbackColor.opacity(0.55), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            CometWriterFeedbackAccessibilityCopy.label(
                visibleMessage: viewModel.feedbackMessage,
                isLetterComplete: viewModel.isLetterComplete
            )
        )
    }

    private var feedbackIcon: String {
        switch viewModel.feedbackTone {
        case .instruction: return "paperplane.fill"
        case .success: return "star.fill"
        case .correction: return "arrow.uturn.backward.circle.fill"
        }
    }

    private var feedbackColor: Color {
        switch viewModel.feedbackTone {
        case .instruction: return AppTheme.cometCyan
        case .success: return AppTheme.accentPrimary
        case .correction: return AppTheme.cometGold
        }
    }

    private var actionRow: some View {
        VStack(spacing: 10) {
            if isWordMission {
                challengeAction(title: "Show Comet Example", icon: "play.fill") {
                    CustomPromptAudioService.shared.stopPlayback()
                    viewModel.showHint(animated: !reduceMotion)
                    speech.speakPathPrompt(for: viewModel.glyph, animated: !reduceMotion)
                }
                .accessibilityIdentifier("comet-writer-show-comet-example")
                .accessibilityValue(
                    viewModel.isDemonstrating
                        ? "Playing"
                        : viewModel.isHintVisible ? "Shown" : "Ready"
                )
                .accessibilityHint("Shows how the comet forms the highlighted letter")
            }

            HStack(spacing: 10) {
                challengeAction(title: "Restart", icon: "arrow.counterclockwise") {
                    viewModel.retryCurrentStroke()
                }
                challengeAction(title: "Hear", icon: "speaker.wave.2.fill") {
                    speakCurrentTarget()
                }
                challengeAction(title: "Tools", icon: "slider.horizontal.3") {
                    viewModel.stopHint()
                    viewModel.cancelActiveTrace()
                    showsWritingTools = true
                }
            }
        }
    }

    private func challengeAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.backgroundMid.opacity(0.92))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var challengeSidebar: some View {
        VStack(spacing: 10) {
            challengeHeader
            challengePrompt
            feedbackPill
            actionRow
            Spacer(minLength: 0)
        }
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            if !reduceMotion {
                ConfettiView(intensity: isCurrentWordComplete ? .normal : .light)
                    .ignoresSafeArea()
            }

            VStack(spacing: AppSpacing.md) {
                Image(systemName: isCurrentWordComplete ? "text.badge.checkmark" : "sparkles")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundColor(AppTheme.cometGold)

                Text(completionTitle)
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                    .accessibilityLabel(accessibleCompletionTitle)

                if let latestReward {
                    advancedRewardSummary(latestReward)
                }

                PrimaryButton(nextButtonTitle, icon: "arrow.right", size: .large) {
                    advanceChallenge()
                }
                .accessibilityIdentifier("comet-writer-advanced-next")
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: 420)
            .background(RoundedRectangle(cornerRadius: 28).fill(AppTheme.backgroundMid))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(AppTheme.cometCyan.opacity(0.5), lineWidth: 1)
            )
            .padding(AppSpacing.lg)
            .accessibilityElement(children: .contain)
        }
    }

    private var sessionSummaryOverlay: some View {
        ZStack {
            Color.black.opacity(0.68).ignoresSafeArea()
            if !reduceMotion {
                ConfettiView(intensity: .normal)
                    .ignoresSafeArea()
            }

            VStack(spacing: AppSpacing.md) {
                Image(systemName: mission == .alienMail ? "paperplane.circle.fill" : "sparkles.rectangle.stack.fill")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundColor(AppTheme.cometGold)

                Text("Mission complete!")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("\(sessionTarget) challenges finished")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: AppSpacing.lg) {
                    summaryStat(title: "Average", value: "\(sessionAverageScore)", icon: "gauge.with.dots.needle.67percent")
                    summaryStat(title: "Points", value: "+\(sessionPointTotal)", icon: "sparkles")
                    summaryStat(title: "Mastered", value: "\(sessionMasteryCount)", icon: "star.fill")
                }
                .padding(.vertical, AppSpacing.sm)

                PrimaryButton("Back to missions", icon: "checkmark", size: .large) {
                    dismiss()
                }

                Button("Practise another set") {
                    restartSession()
                }
                .font(AppTypography.buttonMedium)
                .foregroundColor(AppTheme.cometCyan)
                .frame(minHeight: 44)
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: 450)
            .background(RoundedRectangle(cornerRadius: 28).fill(AppTheme.backgroundMid))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(AppTheme.cometCyan.opacity(0.5), lineWidth: 1)
            )
            .padding(AppSpacing.lg)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("comet-writer-session-summary")
        }
    }

    private func summaryStat(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.cometGold)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundColor(AppTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var sessionAverageScore: Int {
        guard !sessionRewards.isEmpty else { return 0 }
        return sessionRewards.reduce(0) { $0 + $1.score } / sessionRewards.count
    }

    private var sessionPointTotal: Int {
        sessionRewards.reduce(0) { $0 + $1.points }
    }

    private var sessionMasteryCount: Int {
        let characters = Set(
            CometLearningStore.shared.recentAttempts(limit: sessionRewards.count + 8)
                .filter { $0.wasIndependent && $0.score >= 90 }
                .map(\.character)
        )
        return characters.count
    }

    private func restartSession() {
        isSessionComplete = false
        sessionItemsCompleted = 0
        sessionRewards = []
        recallIndex = 0
        wordIndex = 0
        characterIndex = 0
        wordAttempts = []
        latestReward = nil
        didSpeechFail = false
        resetCueStyleForCurrentMission()
        let firstCharacter = isRecallMission ? recallCharacters[0] : String(missionWords[0].first!)
        viewModel.load(LetterLibrary.glyph(for: firstCharacter)!, assistance: .flySolo)
        if shouldAutomaticallySpeakCurrentTarget {
            speakCurrentTarget()
        }
    }

    private func requestExit() {
        guard !isSessionComplete else {
            dismiss()
            return
        }
        autoAdvanceTask?.cancel()
        viewModel.cancelActiveTrace()
        showsExitConfirmation = true
    }

    private var currentWord: String {
        missionWords[wordIndex % missionWords.count]
    }

    private var wordCharacters: [String] {
        currentWord.map(String.init)
    }

    private var isCurrentWordComplete: Bool {
        isWordMission && characterIndex == wordCharacters.count - 1
    }

    private var completionTitle: String {
        if mission == .letterRecall { return "Letter remembered!" }
        if mission == .phonics { return "Letter remembered!" }
        if mission == .alienMail { return "Message ready!" }
        return "\(currentWord) complete!"
    }

    private var accessibleCompletionTitle: String {
        guard isWordMission else { return completionTitle }
        return "\(CometWriterWordAccessibilityCopy.targetDescription(for: currentWord)) complete!"
    }

    private var nextButtonTitle: String {
        if sessionItemsCompleted + 1 >= sessionTarget {
            return completionButtonTitle ?? "Finish mission"
        }
        return isRecallMission ? "Next letter" : "Next word"
    }

    private var isRecallMission: Bool {
        mission == .letterRecall || mission == .phonics
    }

    private var isBlockingOverlayPresented: Bool {
        isSessionComplete
            || (viewModel.isLetterComplete && (isRecallMission || isCurrentWordComplete))
    }

    private func resetCueStyleForCurrentMission() {
        cueStyle = CometWriterRecallCuePolicy.startsWithHearCue(for: mission) ? .hear : .see
    }

    private var isWordMission: Bool {
        mission == .wordWriting || mission == .alienMail
    }

    private var recallSpeechFailureMessage: String {
        mission == .phonics
            ? "The sound could not play, so the letter is shown. Tap Hear to try again."
            : "The voice could not play, so the letter is shown. Tap Hear to try again."
    }

    private var isVoiceOverRunning: Bool {
        voiceOverEnabled || UIAccessibility.isVoiceOverRunning
    }

    private var shouldAutomaticallySpeakCurrentTarget: Bool {
        CometWriterAutomaticSpeechPolicy.shouldSpeak(
            isVoiceOverRunning: isVoiceOverRunning,
            isHearCue: cueStyle == .hear,
            isWordMission: isWordMission
        )
    }

    private var missionTitle: String {
        switch mission {
        case .letterRecall: return "Letter Recall"
        case .wordWriting: return "Word Mission"
        case .phonics: return "Letter Sound Mission"
        case .alienMail: return "Alien Mail"
        }
    }

    private func wordCharacterColor(at index: Int) -> Color {
        if wordAttempts.indices.contains(index) { return AppTheme.accentPrimary }
        if index == characterIndex { return AppTheme.cometCyan }
        return AppTheme.textSecondary
    }

    private func speakCurrentTarget() {
        didSpeechFail = false
        speech.stop()
        CustomPromptAudioService.shared.stopPlayback()

        if isRecallMission {
            let started: Bool
            if mission == .phonics {
                cueStyle = .hear
                started = speech.speakLetterSoundPrompt(for: viewModel.glyph)
            } else {
                started = speech.speakRecallPrompt(for: viewModel.glyph)
            }
            let recovery = CometWriterRecallSpeechRecovery.afterPlaybackAttempt(
                started: started
            )
            didSpeechFail = recovery.shouldShowRetry
            if recovery.shouldRevealCue {
                cueStyle = .see
            }
        } else {
            let requestedWord = currentWord
            let requestedCharacterIndex = characterIndex
            let requestedGlyphCharacter = viewModel.glyph.character
            let prefix = mission == .alienMail ? "Send this word to Nova." : "Write the word."
            let contextSentence = learningStore.contextSentence(forWord: requestedWord)
            let requestedTargetIsCurrent = {
                isWordMission
                    && !isSessionComplete
                    && !viewModel.isLetterComplete
                    && currentWord == requestedWord
                    && characterIndex == requestedCharacterIndex
                    && viewModel.glyph.character == requestedGlyphCharacter
            }
            let speakBuiltInPrompt = {
                guard requestedTargetIsCurrent() else { return }
                if !speech.speakWordPrompt(
                    for: viewModel.glyph,
                    word: requestedWord,
                    introduction: prefix,
                    contextSentence: contextSentence
                ) {
                    didSpeechFail = true
                }
            }

            if characterIndex == 0,
               let filename = learningStore.recordingFilename(forWord: requestedWord) {
                Task { @MainActor in
                    let started = await CustomPromptAudioService.shared.playAsync(
                        filename: filename,
                        onCompletion: { outcome in
                            guard outcome == .failed else { return }
                            guard requestedTargetIsCurrent() else { return }
                            guard CometWriterAutomaticSpeechPolicy
                                .shouldStartDeferredRecordingFallback(
                                    isVoiceOverRunning: isVoiceOverRunning
                                ) else {
                                didSpeechFail = true
                                UIAccessibility.post(
                                    notification: .announcement,
                                    argument: CometWriterAutomaticSpeechPolicy
                                        .deferredRecordingFailureAnnouncement
                                )
                                return
                            }
                            speakBuiltInPrompt()
                        }
                    )
                    guard requestedTargetIsCurrent() else {
                        if started { CustomPromptAudioService.shared.stopPlayback() }
                        return
                    }
                    if !started { speakBuiltInPrompt() }
                }
                return
            }
            speakBuiltInPrompt()
        }
    }

    private func awardSuccess() {
        let metrics = viewModel.performanceMetrics
        let reward = CometRewardCalculator.reward(
            metrics: metrics,
            completedWord: isCurrentWordComplete
        )
        cometPoints += reward.points
        StorageService.shared.markCometWriterLetterCompleted(viewModel.glyph.character)
        StorageService.shared.recordCometWriterScore(
            reward.score,
            for: viewModel.glyph.character
        )
        CometLearningStore.shared.recordAttempt(
            character: viewModel.glyph.character,
            mode: {
                switch mission {
                case .letterRecall: return .recall
                case .wordWriting: return .word
                case .phonics: return .phonics
                case .alienMail: return .alienMail
                }
            }(),
            reward: reward,
            metrics: metrics,
            traces: viewModel.completedTraces
        )

        if isWordMission {
            let attempt = WordLetterAttempt(
                character: viewModel.glyph.character,
                traces: viewModel.completedTraces,
                reward: reward
            )
            if wordAttempts.indices.contains(characterIndex) {
                wordAttempts[characterIndex] = attempt
            } else {
                wordAttempts.append(attempt)
            }
        }
        sessionRewards.append(reward)

        if reward.isPerfect {
            accuracyStreak += 1
            bestAccuracyStreak = max(bestAccuracyStreak, accuracyStreak)
        } else {
            accuracyStreak = 0
        }
        latestReward = reward
    }

    private func advanceChallenge() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil

        let completedSessionItem = isRecallMission || isCurrentWordComplete
        if completedSessionItem {
            sessionItemsCompleted += 1
            if sessionItemsCompleted >= sessionTarget {
                latestReward = nil
                if let onSessionComplete {
                    onSessionComplete()
                    dismiss()
                    return
                }
                isSessionComplete = true
                return
            }
        }
        latestReward = nil
        didSpeechFail = false
        resetCueStyleForCurrentMission()

        if isRecallMission {
            recallIndex = (recallIndex + 1) % recallCharacters.count
            let next = LetterLibrary.glyph(for: recallCharacters[recallIndex])!
            viewModel.load(next, assistance: .flySolo)
        } else {
            if isCurrentWordComplete {
                wordIndex = (wordIndex + 1) % missionWords.count
                characterIndex = 0
                wordAttempts = []
            } else {
                characterIndex += 1
            }
            let next = LetterLibrary.glyph(for: wordCharacters[characterIndex])!
            viewModel.load(next, assistance: .flySolo)
        }

        if shouldAutomaticallySpeakCurrentTarget {
            speakCurrentTarget()
        }
    }

    private func scheduleNextWordLetter() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            advanceChallenge()
        }
    }

    @ViewBuilder
    private func advancedRewardSummary(_ reward: CometReward) -> some View {
        if isWordMission {
            VStack(spacing: 9) {
                HStack(spacing: 12) {
                    ForEach(Array(wordAttempts.enumerated()), id: \.offset) { _, attempt in
                        VStack(spacing: 1) {
                            Text(attempt.character)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("\(attempt.reward.score)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.accentPrimary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "\(CometWriterWordAccessibilityCopy.characterDescription(attempt.character, in: currentWord)), score \(attempt.reward.score)"
                        )
                    }
                }

                Text("Each letter scored out of 100")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 10) {
                    Label("+\(wordCharacterPoints) letters", systemImage: "character.cursor.ibeam")
                    Label("+\(reward.wordBonusPoints) word", systemImage: "text.badge.checkmark")
                }
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.cometCyan)

                Label("+\(wordMissionPoints) Comet Points", systemImage: "sparkles")
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.cometGold)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("comet-writer-word-score")
        } else {
            VStack(spacing: 5) {
                Text("\(reward.score) / 100")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundColor(AppTheme.accentPrimary)
                Text(reward.encouragement)
                    .font(AppTypography.buttonMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Label("+\(reward.characterPoints) Comet Points", systemImage: "sparkles")
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.cometGold)
                if reward.isPerfect {
                    Text("Perfect formation · \(displayedAccuracyStreak) streak")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.accentPrimary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("comet-writer-recall-score")
            .accessibilityLabel("Formation score \(reward.score) out of 100, earned \(reward.characterPoints) Comet Points")
        }
    }

    private var wordCharacterPoints: Int {
        wordAttempts.reduce(0) { $0 + $1.reward.characterPoints }
    }

    private var wordMissionPoints: Int {
        wordCharacterPoints + (latestReward?.wordBonusPoints ?? 0)
    }

    private var displayedCometPoints: Int {
        learningStore.profiles.count == 1 ? cometPoints : learningStore.activePoints
    }

    private var displayedAccuracyStreak: Int {
        learningStore.profiles.count == 1 ? accuracyStreak : learningStore.activePerfectStreak
    }
}

private extension View {
    func challengeCardStyle() -> some View {
        background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.backgroundMid.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppTheme.cometPurple.opacity(0.38), lineWidth: 1)
        )
    }
}

struct CometWriterToolsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var pencilOnly: Bool
    @Binding var letterScale: Double
    @Binding var showsWritingLines: Bool
    @Binding var writingHand: WritingHand

    private var sizePercentage: Int {
        Int((letterScale * 100).rounded())
    }

    private var supportsApplePencil: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        practiceControls
                        handControl
                        sizeControl
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .navigationTitle("Writing tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(AppTypography.buttonMedium)
                        .foregroundColor(AppTheme.cometCyan)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            pencilOnly = TraceInputPolicy.resolvedPencilOnly(
                pencilOnly,
                supportsApplePencil: supportsApplePencil
            )
        }
    }

    private var practiceControls: some View {
        VStack(spacing: 0) {
            if supportsApplePencil {
                pencilControl
                    .padding(AppSpacing.md)

                Divider()
                    .overlay(Color.white.opacity(0.12))
                    .padding(.leading, 62)
            }

            writingLinesControl
                .padding(AppSpacing.md)
        }
        .background(toolCardBackground)
    }

    private var pencilControl: some View {
        Toggle(isOn: $pencilOnly) {
            toolLabel(
                icon: "applepencil",
                title: "Apple Pencil only",
                detail: "Finger drawing is ignored while this is on."
            )
        }
        .tint(AppTheme.cometCyan)
        .frame(minHeight: 60)
        .accessibilityIdentifier("comet-writer-pencil-only")
        .accessibilityHint("Allows only Apple Pencil strokes on the writing pad")
    }

    private var writingLinesControl: some View {
        Toggle(isOn: $showsWritingLines) {
            toolLabel(
                icon: "textformat",
                title: "Writing lines",
                detail: "Shows handwriting guide lines behind the letter."
            )
        }
        .tint(AppTheme.cometCyan)
        .frame(minHeight: 60)
        .accessibilityIdentifier("comet-writer-writing-lines")
        .accessibilityHint("Shows or hides the handwriting guide lines")
    }

    private func toolLabel(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(AppTheme.cometCyan)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTypography.buttonMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Text(detail)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var sizeControl: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Letter size", systemImage: "textformat.size")
                    .font(AppTypography.buttonMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(sizePercentage)%")
                    .font(AppTypography.buttonSmall)
                    .foregroundColor(AppTheme.cometGold)
                    .monospacedDigit()
            }

            HStack(spacing: 12) {
                Image(systemName: "textformat.size.smaller")
                    .foregroundColor(AppTheme.textSecondary)
                    .accessibilityHidden(true)

                Slider(
                    value: $letterScale,
                    in: Double(LetterDisplayTransform.minimumScale)...Double(LetterDisplayTransform.maximumScale),
                    step: 0.05
                )
                .tint(AppTheme.cometCyan)
                .accessibilityLabel("Letter size")
                .accessibilityValue("\(sizePercentage) percent")
                .accessibilityIdentifier("comet-writer-letter-size")

                Image(systemName: "textformat.size.larger")
                    .foregroundColor(AppTheme.textPrimary)
                    .accessibilityHidden(true)
            }

            Button("Reset to 100%") {
                letterScale = Double(LetterDisplayTransform.defaultScale)
            }
            .font(AppTypography.buttonSmall)
            .foregroundColor(AppTheme.cometCyan)
            .frame(minHeight: 44)
            .accessibilityIdentifier("comet-writer-letter-size-reset")
        }
        .padding(AppSpacing.md)
        .background(toolCardBackground)
    }

    private var handControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolLabel(
                icon: "hand.raised.fill",
                title: "Writing hand",
                detail: "Moves side controls away from the hand and shows the matching paper position."
            )

            Picker("Writing hand", selection: $writingHand) {
                ForEach(WritingHand.allCases) { hand in
                    Text(hand.title).tag(hand)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("comet-writer-writing-hand")

            Label(
                writingHand == .left
                    ? "Tilt the top of the page slightly right and keep your wrist below the line."
                    : "Tilt the top of the page slightly left and keep your wrist below the line.",
                systemImage: "rectangle.portrait.rotate"
            )
            .font(.footnote)
            .foregroundColor(AppTheme.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(toolCardBackground)
    }

    private var toolCardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(AppTheme.backgroundMid.opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        CometWriterGameView(startingGlyph: LetterLibrary.glyph(for: "c")!)
    }
    .environmentObject(MusicService.shared)
}
