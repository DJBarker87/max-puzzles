import SwiftUI

/// A curriculum-aligned starter pool for England Year 1.
///
/// The National Curriculum makes phoneme-based words, common exception words and the
/// days of the week statutory teaching requirements. The individual pattern words below
/// are representative examples from English Appendix 1 rather than a statutory word list.
/// Sources:
/// - https://www.gov.uk/government/publications/national-curriculum-in-england-english-programmes-of-study
/// - https://assets.publishing.service.gov.uk/media/5a7ccc06ed915d63cc65ce61/English_Appendix_1_-_Spelling.pdf
enum StarSpellerWordLibrary {
    static let englandYearOneDays = [
        "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
    ]

    static let englandYearOneCommonExceptionWords = [
        "the", "a", "do", "to", "today", "of", "said", "says", "are", "were", "was",
        "is", "his", "has", "I", "you", "your", "they", "be", "he", "me", "she", "we",
        "no", "go", "so", "by", "my", "here", "there", "where", "love", "come", "some",
        "one", "once", "ask", "friend", "school", "put", "push", "pull", "full", "house",
        "our"
    ]

    static let englandYearOnePatternWords = [
        "off", "well", "miss", "buzz", "back", "bank", "think", "pocket", "rabbit",
        "catch", "fetch", "have", "give", "cats", "dogs", "catches", "hunting", "hunted",
        "hunter", "quicker", "quickest", "rain", "coin", "play", "toy", "home", "five",
        "blue", "night", "food", "book", "boat", "out", "now", "snow", "chief", "short",
        "fair", "year", "happy", "funny", "phonics", "which", "kit", "unhappy", "football",
        "bedroom", "farmyard"
    ]

    static let englandYearOne = englandYearOneDays
        + englandYearOneCommonExceptionWords
        + englandYearOnePatternWords

    static func displayForm(for word: String) -> String {
        let normalized = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isDay = englandYearOneDays.contains { $0.lowercased() == normalized }
        return isDay ? word.uppercased() : word
    }
}

enum StarSpellerHintKeyboard {
    static let alphabet = Array("abcdefghijklmnopqrstuvwxyz").map(String.init)

    static func visibleLetters(for word: String, typedCharacterCount: Int) -> Set<String> {
        let normalizedWord = word
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard typedCharacterCount >= 0,
              typedCharacterCount < normalizedWord.count else { return [] }

        let targetIndex = normalizedWord.index(
            normalizedWord.startIndex,
            offsetBy: typedCharacterCount
        )
        let correctLetter = String(normalizedWord[targetIndex])
        guard let correctAlphabetIndex = alphabet.firstIndex(of: correctLetter) else { return [] }

        var choices: Set<String> = [correctLetter]
        var offset = 5 + (typedCharacterCount * 7) % alphabet.count
        while choices.count < 3 {
            choices.insert(alphabet[(correctAlphabetIndex + offset) % alphabet.count])
            offset += 7
        }
        return choices
    }
}

enum StarSpellerScoring {
    static let pointsPerWord = 100
    static let pointsPerHint = 10
    static let minimumPointsPerWord = 40

    static func points(forHintUses hintUses: Int) -> Int {
        max(
            minimumPointsPerWord,
            pointsPerWord - max(0, hintUses) * pointsPerHint
        )
    }
}

struct StarSpellerMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var musicService: MusicService
    @ObservedObject private var storage = StorageService.shared
    @ObservedObject private var wordStore = CometLearningStore.shared

    @State private var destination: Destination?
    @State private var sessionWords: [String] = []

    private enum Destination: Hashable {
        case game
        case words
    }

    private var practiceWords: [String] {
        let customWords = wordStore.activeCustomWords.map(\.text)
        let selectedWords = customWords.isEmpty
            ? StarSpellerWordLibrary.englandYearOne
            : customWords

        return selectedWords
            .filter { word in
                !word.isEmpty && word.allSatisfy {
                    LetterLibrary.glyph(for: String($0)) != nil
                }
            }
    }

    private var canStart: Bool {
        !practiceWords.isEmpty && storage.isVoiceEnabled
    }

    private var isUsingStarterList: Bool {
        wordStore.activeCustomWords.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()
                StarryBackground(starCount: 32, animateStars: true)

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        header
                        hero
                        howToPlay
                        launchCard
                    }
                    .frame(maxWidth: 860)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xxl)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(
                isPresented: Binding(
                    get: { destination != nil },
                    set: { if !$0 { destination = nil } }
                )
            ) {
                if let destination {
                    switch destination {
                    case .game:
                        StarSpellerGameView(words: sessionWords)
                    case .words:
                        CometCustomWordsView()
                    }
                }
            }
        }
        .onAppear {
            if !musicService.isPlaying {
                musicService.play(track: .hub)
            }
        }
        .accessibilityIdentifier("star-speller-menu")
    }

    private var header: some View {
        HStack(spacing: AppSpacing.md) {
            PremiumIconButton(
                icon: "xmark",
                action: { dismiss() },
                size: 48,
                accessibilityLabelText: "Close Star Speller"
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Star Speller")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Listen, spell, then write")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)

            Label("\(practiceWords.count)", systemImage: "textformat.abc")
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.cometCyan)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Capsule().fill(AppTheme.backgroundMid.opacity(0.90)))
                .accessibilityLabel("\(practiceWords.count) spelling words ready")
        }
        .padding(.top, AppSpacing.md)
    }

    private var hero: some View {
        HStack(spacing: AppSpacing.lg) {
            Image("star_speller_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: AppTheme.cometCyan.opacity(0.35), radius: 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Hear it. Type it. Write it.")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Every correct keyboard spelling launches the same handwriting tool used by Comet Writer.")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.backgroundMid.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.cometPurple.opacity(0.50), lineWidth: 1)
        )
    }

    private var howToPlay: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("How to play")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 180), spacing: AppSpacing.md)],
                spacing: AppSpacing.md
            ) {
                instructionCard(
                    number: "1",
                    icon: "speaker.wave.2.fill",
                    title: "Listen",
                    detail: "Hear the word as often as you need."
                )
                instructionCard(
                    number: "2",
                    icon: "keyboard.fill",
                    title: "Spell",
                    detail: "Type the word using the keyboard."
                )
                instructionCard(
                    number: "3",
                    icon: "pencil.tip",
                    title: "Handwrite",
                    detail: "Form every letter in Comet Writer."
                )
            }
        }
    }

    private func instructionCard(
        number: String,
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppTheme.cometCyan)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(AppTheme.cometPaperTop))

                Text(number)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.backgroundDark)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(AppTheme.cometGold))
                    .offset(x: 3, y: -3)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.textPrimary)
                Text(detail)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.backgroundMid.opacity(0.82))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number), \(title). \(detail)")
    }

    private var launchCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isUsingStarterList ? "England Year 1 starter list" : "Custom spelling list")
                        .font(AppTypography.titleSmall)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(
                        isUsingStarterList
                            ? "100 curriculum-aligned starter words are ready. A mission uses up to 10 words."
                            : "Using the words saved for \(wordStore.activeProfile.name). A mission uses up to 10 words."
                    )
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            if practiceWords.isEmpty {
                Label(
                    "These words cannot be used with the handwriting tool. Ask a grown-up to review the custom list.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppTheme.cometGold)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                wordPreview
            }

            if !storage.isVoiceEnabled {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Label("Spoken instructions are off", systemImage: "speaker.slash.fill")
                        .font(AppTypography.buttonLarge)
                        .foregroundColor(AppTheme.cometGold)
                    Text("Star Speller needs voice prompts so the word stays hidden.")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                    Button("Turn on spoken instructions") {
                        storage.setVoiceEnabled(true)
                        FeedbackManager.shared.haptic(.success)
                    }
                    .font(AppTypography.buttonMedium)
                    .foregroundColor(AppTheme.cometCyan)
                    .frame(minHeight: 44)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.cometGold.opacity(0.10))
                )
            }

            HStack(spacing: AppSpacing.md) {
                Button {
                    destination = .words
                } label: {
                    Label(
                        isUsingStarterList ? "Use my own words" : "Manage words",
                        systemImage: "doc.badge.plus"
                    )
                    .font(AppTypography.buttonMedium)
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.cometPaperTop)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.cometCyan.opacity(0.42), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("star-speller-manage-words")

                Button {
                    startGame()
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(AppTypography.buttonLarge)
                        .foregroundColor(AppTheme.backgroundDark)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppTheme.accentPrimary)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canStart)
                .opacity(canStart ? 1 : 0.42)
                .accessibilityHint(
                    canStart
                        ? "Starts a spelling mission"
                        : "Turn on spoken instructions first"
                )
                .accessibilityIdentifier("star-speller-start")
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.backgroundMid.opacity(0.90))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.accentPrimary.opacity(0.38), lineWidth: 1)
        )
    }

    private var wordPreview: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(isUsingStarterList ? "Includes every day of the week" : "Your words")
                .font(AppTypography.caption)
                .foregroundColor(AppTheme.textSecondary)
                .textCase(.uppercase)

            FlexibleWordChips(words: Array(practiceWords.prefix(8)))

            if practiceWords.count > 8 {
                Text("+\(practiceWords.count - 8) more")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.cometCyan)
            }
        }
    }

    private func startGame() {
        guard canStart else { return }
        sessionWords = Array(practiceWords.shuffled().prefix(10))
        FeedbackManager.shared.haptic(.buttonRelease)
        destination = .game
    }
}

private struct FlexibleWordChips: View {
    let words: [String]

    private let columns = [
        GridItem(.adaptive(minimum: 88), spacing: AppSpacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(words, id: \.self) { word in
                Text(StarSpellerWordLibrary.displayForm(for: word))
                    .font(AppTypography.buttonSmall)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(Capsule().fill(AppTheme.cometPaperTop))
            }
        }
    }
}

private enum StarSpellerStage: Equatable {
    case typing
    case readyToWrite
    case sessionComplete
}

struct StarSpellerGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var musicService: MusicService
    @ObservedObject private var wordStore = CometLearningStore.shared

    let words: [String]

    @State private var currentIndex = 0
    @State private var typedWord = ""
    @State private var stage: StarSpellerStage = .typing
    @State private var feedbackMessage = "Listen carefully, then type the word."
    @State private var showsCorrection = false
    @State private var showsHandwriting = false
    @State private var handwritingCompleted = false
    @State private var hasAppeared = false
    @State private var incorrectWordIndices = Set<Int>()
    @State private var hintLetters: Set<String> = []
    @State private var currentWordHintUses = 0
    @State private var score = 0
    @State private var launchTask: Task<Void, Never>?
    @State private var promptTask: Task<Void, Never>?
    @State private var focusTask: Task<Void, Never>?
    @State private var requiredAudioToken: UUID?
    @FocusState private var spellingFieldFocused: Bool

    private let speech = LetterSpeechService.shared
    private let customAudio = CustomPromptAudioService.shared

    private var currentWord: String {
        guard words.indices.contains(currentIndex) else { return "" }
        return words[currentIndex]
    }

    private var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentIndex) / Double(words.count)
    }

    private var displayedCurrentWord: String {
        StarSpellerWordLibrary.displayForm(for: currentWord)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()
                StarryBackground(starCount: 28, animateStars: !reduceMotion)

                if words.isEmpty {
                    missingWordsView
                } else if stage == .sessionComplete {
                    sessionCompleteView
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            gameHeader

                            if geometry.size.width > geometry.size.height {
                                HStack(alignment: .top, spacing: AppSpacing.lg) {
                                    listenCard
                                    spellingCard
                                }
                            } else {
                                VStack(spacing: AppSpacing.lg) {
                                    listenCard
                                    spellingCard
                                }
                            }
                        }
                        .frame(maxWidth: 900)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xxl)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .scrollIndicators(.hidden)
                }

                if stage == .sessionComplete && !reduceMotion {
                    ConfettiView(intensity: .normal)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showsHandwriting) {
            AdvancedWritingGameView(
                mission: .wordWriting,
                words: [displayedCurrentWord],
                sessionLength: 1,
                allowsShortWords: true,
                completionButtonTitle: currentIndex + 1 >= words.count
                    ? "Finish spelling mission"
                    : "Next spelling word",
                onSessionComplete: {
                    handwritingCompleted = true
                }
            )
        }
        .onAppear {
            if requiredAudioToken == nil {
                requiredAudioToken = musicService.beginRequiredAudioSession()
            }
            guard !hasAppeared else { return }
            hasAppeared = true
            speakCurrentWord(after: 0.35)
            focusSpellingField(after: 0.55)
        }
        .onDisappear {
            launchTask?.cancel()
            promptTask?.cancel()
            focusTask?.cancel()
            guard !showsHandwriting else { return }
            speech.stop()
            customAudio.stopPlayback()
            if let requiredAudioToken {
                musicService.endRequiredAudioSession(requiredAudioToken)
                self.requiredAudioToken = nil
            }
        }
        .onChange(of: showsHandwriting) { isPresented in
            guard !isPresented, handwritingCompleted else { return }
            advanceAfterHandwriting()
        }
        .onChange(of: typedWord) { newValue in
            let limited = String(newValue.prefix(CometLearningStore.maximumCustomWordLength))
            if limited != newValue {
                typedWord = limited
            }
            if showsCorrection {
                showsCorrection = false
                feedbackMessage = "Make your changes, then check the word again."
            }
        }
        .accessibilityIdentifier("star-speller-game")
    }

    private var gameHeader: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                PremiumIconButton(
                    icon: "chevron.left",
                    action: { dismiss() },
                    size: 48,
                    accessibilityLabelText: "Back to Star Speller"
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Star Speller")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Word \(currentIndex + 1) of \(words.count)")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.cometCyan)
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Label("\(score)", systemImage: "star.fill")
                        .foregroundColor(AppTheme.cometGold)
                    Text("\(currentWord.count) letters")
                        .foregroundColor(AppTheme.cometCyan)
                }
                .font(AppTypography.buttonSmall)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Capsule().fill(AppTheme.backgroundMid.opacity(0.92)))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Score \(score), \(currentWord.count) letters")
            }

            ProgressView(value: progress)
                .tint(AppTheme.accentPrimary)
                .accessibilityLabel("Spelling mission progress")
                .accessibilityValue("\(currentIndex) of \(words.count) words complete")
        }
        .padding(.top, AppSpacing.md)
    }

    private var listenCard: some View {
        VStack(spacing: AppSpacing.md) {
            VStack(spacing: 4) {
                Text("Listen carefully")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text("The word stays hidden until you spell it.")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                speakCurrentWord()
                FeedbackManager.shared.haptic(.light)
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.cometPurple.opacity(0.22))
                        .frame(width: 116, height: 116)
                    Circle()
                        .stroke(AppTheme.cometCyan.opacity(0.60), lineWidth: 2)
                        .frame(width: 98, height: 98)
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(AppTheme.cometCyan)
                }
            }
            .buttonStyle(.plain)
            .frame(minWidth: 116, minHeight: 116)
            .accessibilityLabel("Hear the spelling word again")
            .accessibilityHint("Plays the hidden word")
            .accessibilityIdentifier("star-speller-hear-word")

            HStack(spacing: 7) {
                ForEach(0..<currentWord.count, id: \.self) { _ in
                    Capsule()
                        .fill(AppTheme.cometCyan.opacity(0.72))
                        .frame(width: 24, height: 4)
                }
            }
            .accessibilityHidden(true)

            Text("\(currentWord.count) letter\(currentWord.count == 1 ? "" : "s")")
                .font(AppTypography.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, minHeight: 300)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.backgroundMid.opacity(0.90))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.cometPurple.opacity(0.48), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var spellingCard: some View {
        VStack(spacing: AppSpacing.md) {
            if stage == .readyToWrite {
                readyToWriteContent
            } else {
                typingContent
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, minHeight: 300)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.backgroundMid.opacity(0.90))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    stage == .readyToWrite
                        ? AppTheme.accentPrimary.opacity(0.66)
                        : AppTheme.cometCyan.opacity(0.38),
                    lineWidth: 1
                )
        )
    }

    private var typingContent: some View {
        VStack(spacing: AppSpacing.md) {
            VStack(spacing: 4) {
                Text("Type the word")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Use the keyboard, then check your spelling.")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            TextField("Type here", text: $typedWord)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.alphabet)
                .submitLabel(.done)
                .onSubmit(checkSpelling)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
                .frame(maxWidth: 460, minHeight: 66)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.cometPaperTop)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            showsCorrection
                                ? AppTheme.cometGold
                                : spellingFieldFocused
                                    ? AppTheme.cometCyan
                                    : Color.white.opacity(0.18),
                            lineWidth: spellingFieldFocused || showsCorrection ? 2 : 1
                        )
                )
                .focused($spellingFieldFocused)
                .allowsHitTesting(!isHintActive)
                .accessibilityLabel("Spell the spoken word")
                .accessibilityHint("Enter up to ten letters")
                .accessibilityIdentifier("star-speller-word-input")

            Button {
                toggleHint()
            } label: {
                Label(
                    isHintActive ? "Show full keyboard" : "Hint: 3 keys (-10)",
                    systemImage: isHintActive ? "keyboard" : "lightbulb.fill"
                )
                .font(AppTypography.buttonSmall)
                .foregroundColor(isHintActive ? AppTheme.cometCyan : AppTheme.cometGold)
                .frame(maxWidth: 460, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.backgroundDark.opacity(0.72))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            (isHintActive ? AppTheme.cometCyan : AppTheme.cometGold)
                                .opacity(0.46),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(!isHintActive && !canUseHint)
            .opacity(!isHintActive && !canUseHint ? 0.42 : 1)
            .accessibilityHint(
                isHintActive
                    ? "Returns to the full keyboard without refunding the hint"
                    : "Shows only three choices for the next letter and costs ten points"
            )
            .accessibilityIdentifier("star-speller-hint")

            if isHintActive {
                hintKeyboard
            }

            Label(
                feedbackMessage,
                systemImage: showsCorrection
                    ? "arrow.uturn.backward.circle.fill"
                    : "sparkles"
            )
            .font(AppTypography.bodySmall)
            .foregroundColor(showsCorrection ? AppTheme.cometGold : AppTheme.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("star-speller-feedback")

            Button {
                checkSpelling()
            } label: {
                Label("Check word", systemImage: "checkmark.circle.fill")
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.backgroundDark)
                    .frame(maxWidth: 460, minHeight: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.accentPrimary)
                    )
            }
            .buttonStyle(.plain)
            .disabled(typedWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(typedWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.42 : 1)
            .accessibilityIdentifier("star-speller-check-word")
        }
    }

    private var readyToWriteContent: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 58, weight: .bold))
                .foregroundColor(AppTheme.accentPrimary)
                .accessibilityHidden(true)

            VStack(spacing: 5) {
                Text("Great spelling!")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Text(displayedCurrentWord)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.cometCyan)
                Text("Now handwrite the whole word in Comet Writer.")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                openHandwriting()
            } label: {
                Label("Handwrite \(displayedCurrentWord)", systemImage: "pencil.tip")
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.backgroundDark)
                    .frame(maxWidth: 460, minHeight: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.cometCyan)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the Comet Writer handwriting surface")
            .accessibilityIdentifier("star-speller-open-handwriting")
        }
        .accessibilityElement(children: .contain)
    }

    private var sessionCompleteView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer(minLength: AppSpacing.xl)

            Image(systemName: "star.circle.fill")
                .font(.system(size: 76, weight: .bold))
                .foregroundColor(AppTheme.cometGold)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.sm) {
                Text("Spelling mission complete!")
                    .font(AppTypography.displayMedium)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("You spelled and handwrote every word.")
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: AppSpacing.md) {
                summaryStat(
                    value: "\(words.count)",
                    label: words.count == 1 ? "Word" : "Words",
                    icon: "textformat.abc"
                )
                summaryStat(
                    value: "\(firstTryCount)",
                    label: "First try",
                    icon: "sparkles"
                )
                summaryStat(
                    value: "\(score)",
                    label: "Score",
                    icon: "star.fill"
                )
            }
            .frame(maxWidth: 460)

            VStack(spacing: 10) {
                PrimaryButton("Play this list again", icon: "arrow.clockwise", size: .large) {
                    resetSession()
                }

                Button("Back to Star Speller") {
                    dismiss()
                }
                .font(AppTypography.buttonMedium)
                .foregroundColor(AppTheme.cometCyan)
                .frame(minHeight: 44)
            }
            .frame(maxWidth: 460)

            Spacer(minLength: AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.lg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("star-speller-session-complete")
    }

    private func summaryStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(AppTheme.cometCyan)
            Text(value)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            Text(label)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 118)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.backgroundMid.opacity(0.92))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var missingWordsView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 50, weight: .semibold))
                .foregroundColor(AppTheme.cometGold)
                .accessibilityHidden(true)
            Text("No spelling words found")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppTheme.textPrimary)
            Text("Go back and ask a grown-up to add or import a word list.")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Back to Star Speller") { dismiss() }
                .font(AppTypography.buttonLarge)
                .foregroundColor(AppTheme.cometCyan)
                .frame(minHeight: 44)
        }
        .padding(AppSpacing.lg)
    }

    private var firstTryCount: Int {
        max(0, words.count - incorrectWordIndices.count)
    }

    private var isHintActive: Bool {
        !hintLetters.isEmpty
    }

    private var typedCharacterCount: Int {
        typedWord
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .count
    }

    private var canUseHint: Bool {
        stage == .typing && typedCharacterCount < currentWord.count
    }

    private var hintKeyboard: some View {
        let columns = Array(
            repeating: GridItem(.flexible(minimum: 44), spacing: 6),
            count: 6
        )

        return VStack(spacing: 8) {
            Text("Choose the next letter")
                .font(AppTypography.caption)
                .foregroundColor(AppTheme.textSecondary)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(StarSpellerHintKeyboard.alphabet, id: \.self) { letter in
                    let isVisible = hintLetters.contains(letter)

                    Button {
                        chooseHintLetter(letter)
                    } label: {
                        Text(isVisible ? letter.uppercased() : " ")
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                            .foregroundColor(AppTheme.backgroundDark)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(
                                        isVisible
                                            ? AppTheme.cometCyan
                                            : AppTheme.backgroundDark.opacity(0.48)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .stroke(
                                        isVisible
                                            ? AppTheme.cometCyan
                                            : Color.white.opacity(0.08),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isVisible)
                    .accessibilityHidden(!isVisible)
                    .accessibilityLabel("Letter \(letter.uppercased())")
                }
            }
        }
        .frame(maxWidth: 460)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("star-speller-hint-keyboard")
    }

    private func toggleHint() {
        if isHintActive {
            hintLetters = []
            feedbackMessage = "Keep spelling with the full keyboard."
            focusSpellingField(after: 0.15)
            return
        }

        let choices = StarSpellerHintKeyboard.visibleLetters(
            for: currentWord,
            typedCharacterCount: typedCharacterCount
        )
        guard choices.count == 3 else { return }

        spellingFieldFocused = false
        hintLetters = choices
        currentWordHintUses += 1
        feedbackMessage = "Three keys are lit. Choose the next letter."
        FeedbackManager.shared.haptic(.light)
    }

    private func chooseHintLetter(_ letter: String) {
        guard hintLetters.contains(letter) else { return }
        typedWord.append(letter)
        hintLetters = []
        feedbackMessage = "Good choice. Keep spelling the word."
        FeedbackManager.shared.haptic(.light)
        focusSpellingField(after: 0.15)
    }

    private func checkSpelling() {
        guard stage == .typing else { return }
        let answer = CometLearningStore.normalizedCustomWord(typedWord)
        let expectedAnswer = CometLearningStore.normalizedCustomWord(currentWord)
        guard !answer.isEmpty else { return }

        if answer == expectedAnswer {
            spellingFieldFocused = false
            showsCorrection = false
            hintLetters = []
            score += StarSpellerScoring.points(forHintUses: currentWordHintUses)
            stage = .readyToWrite
            feedbackMessage = "Correct. Now handwrite the word."
            SoundEffectsService.shared.play(.correctMove)
            FeedbackManager.shared.haptic(.success)

            launchTask?.cancel()
            launchTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: reduceMotion ? 250_000_000 : 700_000_000)
                guard !Task.isCancelled, stage == .readyToWrite else { return }
                openHandwriting()
            }
        } else {
            incorrectWordIndices.insert(currentIndex)
            hintLetters = []
            showsCorrection = true
            feedbackMessage = "Almost! Listen again, check each letter, and try once more."
            SoundEffectsService.shared.play(.wrongMove)
            FeedbackManager.shared.haptic(.error)
            speakCurrentWord(after: 0.25)
            focusSpellingField(after: 0.35)
        }
    }

    private func speakCurrentWord(after delay: TimeInterval = 0) {
        guard !currentWord.isEmpty else { return }
        promptTask?.cancel()

        let action = {
            speech.stop()
            customAudio.stopPlayback()
            if let filename = wordStore.recordingFilename(forWord: currentWord) {
                customAudio.play(filename: filename)
            } else {
                speech.speak("Listen carefully. Spell the word. \(currentWord).")
            }
        }

        if delay <= 0 {
            action()
        } else {
            promptTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled, stage == .typing else { return }
                action()
            }
        }
    }

    private func focusSpellingField(after delay: TimeInterval) {
        focusTask?.cancel()
        focusTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled, stage == .typing else { return }
            spellingFieldFocused = true
        }
    }

    private func openHandwriting() {
        launchTask?.cancel()
        promptTask?.cancel()
        focusTask?.cancel()
        speech.stop()
        customAudio.stopPlayback()
        showsHandwriting = true
    }

    private func advanceAfterHandwriting() {
        handwritingCompleted = false
        typedWord = ""
        showsCorrection = false
        hintLetters = []
        currentWordHintUses = 0

        if currentIndex + 1 >= words.count {
            stage = .sessionComplete
            feedbackMessage = "Mission complete."
            SoundEffectsService.shared.play(.levelComplete)
            FeedbackManager.shared.haptic(.success)
            return
        }

        currentIndex += 1
        stage = .typing
        feedbackMessage = "Listen carefully, then type the word."
        speakCurrentWord(after: 0.45)
        focusSpellingField(after: 0.65)
    }

    private func resetSession() {
        launchTask?.cancel()
        promptTask?.cancel()
        focusTask?.cancel()
        currentIndex = 0
        typedWord = ""
        stage = .typing
        feedbackMessage = "Listen carefully, then type the word."
        showsCorrection = false
        handwritingCompleted = false
        incorrectWordIndices = []
        hintLetters = []
        currentWordHintUses = 0
        score = 0
        speakCurrentWord(after: 0.35)
        focusSpellingField(after: 0.55)
    }
}

#Preview("Star Speller Menu") {
    StarSpellerMenuView()
        .environmentObject(MusicService.shared)
}
