import SwiftUI
import UIKit

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

    static let starterPhonicsWords = [
        "off", "well", "miss", "buzz", "back", "bank", "think", "pocket", "rabbit",
        "catch", "fetch", "have", "give", "cats", "dogs", "catches", "hunting", "hunted",
        "hunter", "quicker", "quickest", "kit", "happy", "funny"
    ]

    static let soundPatternWords = englandYearOnePatternWords.filter {
        !starterPhonicsWords.contains($0)
    }

    /// Every built-in word has an authored sentence. Besides making the prompt more meaningful,
    /// this distinguishes sound-alike words such as there/their, no/know and night/knight.
    static let contextSentences: [String: String] = [
        "monday": "We go back to school on Monday.",
        "tuesday": "Swimming club is on Tuesday.",
        "wednesday": "We visit the library on Wednesday.",
        "thursday": "Our class plants seeds on Thursday.",
        "friday": "Friday is the last school day of the week.",
        "saturday": "We play in the park on Saturday.",
        "sunday": "Our family has lunch together on Sunday.",
        "the": "The moon is bright tonight.",
        "a": "I saw a red kite.",
        "do": "Please do your best.",
        "to": "We went to the park.",
        "today": "We will paint today.",
        "of": "I ate a slice of cake.",
        "said": "Mum said it was time to go.",
        "says": "The sign says stop.",
        "are": "We are ready to begin.",
        "were": "They were in the garden.",
        "was": "The puppy was asleep.",
        "is": "The cat is under the chair.",
        "his": "That blue hat is his.",
        "has": "She has a new book.",
        "i": "I can hop on one foot.",
        "you": "You can choose the game.",
        "your": "Please bring your coat.",
        "they": "They are building a den.",
        "be": "Be kind to your friend.",
        "he": "He can kick the ball.",
        "me": "Please read the story to me.",
        "she": "She drew a rocket.",
        "we": "We are going home.",
        "no": "No, thank you, I am full.",
        "go": "It is time to go outside.",
        "so": "The box was so heavy.",
        "by": "Sit by the window.",
        "my": "This is my pencil.",
        "here": "Put your school bag here.",
        "there": "The red ball is over there.",
        "where": "Where is my other shoe?",
        "love": "I love reading with Dad.",
        "come": "Please come and sit down.",
        "some": "Would you like some grapes?",
        "one": "I have one green apple.",
        "once": "We read that story once before.",
        "ask": "Please ask before you borrow it.",
        "friend": "My friend helped me today.",
        "school": "We walk to school together.",
        "put": "Put the cup on the table.",
        "push": "Push the door to open it.",
        "pull": "Pull the drawer towards you.",
        "full": "The basket is full of toys.",
        "house": "Our house has a red door.",
        "our": "Our class has a small garden.",
        "off": "Turn the bedroom light off.",
        "well": "You read that sentence well.",
        "miss": "I miss my friend when she is away.",
        "buzz": "Bees buzz around the flowers.",
        "back": "Please put the book back.",
        "bank": "The ducks stood on the river bank.",
        "think": "Stop and think before you answer.",
        "pocket": "The coin is in my pocket.",
        "rabbit": "A rabbit hopped across the grass.",
        "catch": "Can you catch the red ball?",
        "fetch": "The dog will fetch the stick.",
        "have": "I have a yellow pencil.",
        "give": "Please give the note to Mum.",
        "cats": "The cats are sleeping together.",
        "dogs": "The dogs ran around the field.",
        "catches": "She catches the beanbag safely.",
        "hunting": "The owl is hunting for food.",
        "hunted": "The cat hunted for its toy.",
        "hunter": "The hunter followed the animal tracks.",
        "quicker": "A bicycle is quicker than walking.",
        "quickest": "Sam found the quickest way home.",
        "rain": "The rain tapped on the window.",
        "coin": "I found a shiny coin.",
        "play": "We play football after school.",
        "toy": "The toy train is on the floor.",
        "home": "We went home before tea.",
        "five": "There are five frogs in the pond.",
        "blue": "The clear sky is blue.",
        "night": "The stars shine at night.",
        "food": "The rabbit needs fresh food.",
        "book": "Choose a book from the shelf.",
        "boat": "The little boat sailed across the lake.",
        "out": "We went out into the sunshine.",
        "now": "Please put your pencil down now.",
        "snow": "The snow covered the playground.",
        "chief": "The fire chief checked the engine.",
        "short": "The blue ribbon is short.",
        "fair": "The fair has rides and games.",
        "year": "My birthday comes once each year.",
        "happy": "The puppy looked happy.",
        "funny": "The clown wore a funny hat.",
        "phonics": "We practise phonics at school.",
        "which": "Which book would you like?",
        "kit": "My football kit is in the bag.",
        "unhappy": "The wet cat looked unhappy.",
        "football": "We kicked the football into the goal.",
        "bedroom": "My bedroom has a cosy lamp.",
        "farmyard": "The hens wandered around the farmyard."
    ]

    static func displayForm(for word: String) -> String {
        let normalized = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // Weekdays are proper nouns. Keep their conventional English capitalisation even when
        // the stored/imported spelling was lowercased for case-insensitive answer checking.
        return englandYearOneDays.first { $0.lowercased() == normalized } ?? word
    }

    static func contextSentence(for word: String) -> String? {
        contextSentences[CometLearningStore.normalizedCustomWord(word)]
    }

    static func spokenPrompt(
        for word: String,
        contextSentence customContext: String? = nil
    ) -> String {
        if let context = customContext ?? Self.contextSentence(for: word) {
            return "Spell the word \(word). \(context)"
        }
        return "Spell the word \(word)."
    }
}

enum StarSpellerPracticeGroup: String, CaseIterable, Identifiable {
    case starterPhonics
    case soundPatterns
    case trickyWords
    case daysOfWeek
    case mixed
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .starterPhonics: return "Starter sounds"
        case .soundPatterns: return "Sound patterns"
        case .trickyWords: return "Tricky words"
        case .daysOfWeek: return "Days of the week"
        case .mixed: return "Mixed challenge"
        case .custom: return "My words"
        }
    }

    var difficulty: String {
        switch self {
        case .starterPhonics: return "Phonics · Start here"
        case .soundPatterns: return "Phonics · Growing"
        case .trickyWords: return "Exception words · Challenge"
        case .daysOfWeek: return "Calendar words · Challenge"
        case .mixed: return "All Year 1 · Adaptive"
        case .custom: return "Grown-up list · Adaptive"
        }
    }

    var icon: String {
        switch self {
        case .starterPhonics: return "mouth.fill"
        case .soundPatterns: return "waveform"
        case .trickyWords: return "brain.head.profile"
        case .daysOfWeek: return "calendar"
        case .mixed: return "shuffle"
        case .custom: return "person.text.rectangle"
        }
    }

    func words(customWords: [String]) -> [String] {
        switch self {
        case .starterPhonics: return StarSpellerWordLibrary.starterPhonicsWords
        case .soundPatterns: return StarSpellerWordLibrary.soundPatternWords
        case .trickyWords: return StarSpellerWordLibrary.englandYearOneCommonExceptionWords
        case .daysOfWeek: return StarSpellerWordLibrary.englandYearOneDays
        case .mixed: return StarSpellerWordLibrary.englandYearOne
        case .custom: return customWords
        }
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
    static let maximumHintUses = pointsPerWord / pointsPerHint

    static func points(forHintUses hintUses: Int) -> Int {
        max(
            0,
            pointsPerWord - max(0, hintUses) * pointsPerHint
        )
    }

    static func canUseAnotherHint(after hintUses: Int) -> Bool {
        hintUses < maximumHintUses
    }
}

enum StarSpellerAccessibilityPolicy {
    static func shouldUseAppPromptAudio(isVoiceOverRunning: Bool) -> Bool {
        !isVoiceOverRunning
    }

    static func shouldAutomaticallyFocusInput(isVoiceOverRunning: Bool) -> Bool {
        !isVoiceOverRunning
    }
}

enum StarSpellerPromptAudioState: Equatable {
    case ready
    case failed

    static func afterPlaybackAttempt(succeeded: Bool) -> Self {
        succeeded ? .ready : .failed
    }
}

enum StarSpellerPromptAudioPlayback {
    /// A saved family recording is preferred, but it must never become a dead end. Files can be
    /// removed by an interrupted restore or become unreadable; in that case the built-in voice
    /// immediately supplies the same hidden-word prompt.
    static func play(
        customRecordingFilename: String?,
        customPlayback: (String) -> Bool,
        voicePlayback: () -> Bool
    ) -> Bool {
        if let customRecordingFilename,
           customPlayback(customRecordingFilename) {
            return true
        }
        return voicePlayback()
    }
}

struct StarSpellerMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var musicService: MusicService
    @ObservedObject private var storage = StorageService.shared
    @ObservedObject private var wordStore = CometLearningStore.shared

    @State private var destination: Destination?
    @State private var sessionWords: [String] = []
    @State private var sessionStartIndex = 0
    @State private var sessionStartingScore = 0
    @State private var sessionStartsReadyToWrite = false
    @State private var selectedGroup: StarSpellerPracticeGroup
    @State private var sessionLength = 5
    @State private var showsReplaceSessionConfirmation = false
    @State private var showsHowToPlay = true

    init() {
        _selectedGroup = State(
            initialValue: CometLearningStore.shared.activeCustomWords.isEmpty
                ? .starterPhonics
                : .custom
        )
    }

    private enum Destination: Hashable {
        case game
        case words
        case progress
    }

    private var practiceWords: [String] {
        let customWords = wordStore.activeCustomWords.map(\.text)
        let selectedWords = selectedGroup.words(customWords: customWords)

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

    private var availableGroups: [StarSpellerPracticeGroup] {
        StarSpellerPracticeGroup.allCases.filter {
            $0 != .custom || !wordStore.activeCustomWords.isEmpty
        }
    }

    private var tutorialDefaultsKey: String {
        "maxpuzzles.starSpeller.hasStarted.\(wordStore.activeProfileID.uuidString)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()
                StarryBackground(starCount: 32, animateStars: !reduceMotion)

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        header
                        if let resumeSession = wordStore.activeSpellingSession {
                            resumeCard(resumeSession)
                        }
                        launchCard
                        hero
                        howToPlayDisclosure
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
                        StarSpellerGameView(
                            words: sessionWords,
                            startingIndex: sessionStartIndex,
                            startingScore: sessionStartingScore,
                            startsReadyToWrite: sessionStartsReadyToWrite
                        )
                    case .words:
                        CometCustomWordsView()
                    case .progress:
                        CometMissionControlView()
                    }
                }
            }
        }
        .onAppear {
            if !musicService.isPlaying {
                musicService.play(track: .hub)
            }
            showsHowToPlay = !UserDefaults.standard.bool(forKey: tutorialDefaultsKey)
        }
        .onChange(of: wordStore.activeCustomWords.isEmpty) { customWordsAreEmpty in
            if customWordsAreEmpty && selectedGroup == .custom {
                selectedGroup = .starterPhonics
            }
        }
        .alert("Start a new spelling mission?", isPresented: $showsReplaceSessionConfirmation) {
            Button("Keep current mission", role: .cancel) {}
            Button("Start new mission", role: .destructive) {
                startGame()
            }
        } message: {
            Text("The saved place in the unfinished mission will be replaced.")
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

                Text("Every correct keyboard spelling unlocks the same handwriting tool used by Comet Writer.")
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

    private var howToPlayDisclosure: some View {
        VStack(alignment: .leading, spacing: showsHowToPlay ? AppSpacing.md : 0) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    showsHowToPlay.toggle()
                }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(AppTheme.cometCyan)
                    Text("How to play")
                        .font(AppTypography.titleSmall)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer(minLength: 0)
                    Image(systemName: showsHowToPlay ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(minHeight: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(showsHowToPlay ? "Expanded" : "Collapsed")
            .accessibilityHint(showsHowToPlay ? "Hides the three instructions" : "Shows the three instructions")
            .accessibilityIdentifier("star-speller-how-to-toggle")

            if showsHowToPlay {
                howToPlay
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.backgroundMid.opacity(0.82))
        )
        .accessibilityElement(children: .contain)
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
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose today’s practice")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Start with a phonics level or let adaptive practice revisit words that needed help.")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !storage.isVoiceEnabled {
                voiceRequirementCard
            }

            launchActions

            Text("Change practice")
                .font(AppTypography.buttonMedium)
                .foregroundColor(AppTheme.textPrimary)

            groupPicker
            sessionLengthPicker

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

            Button {
                destination = .progress
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(AppTheme.cometGold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Grown-up spelling summary")
                            .font(AppTypography.buttonMedium)
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Attempts, errors, hints and word mastery for \(wordStore.activeProfile.name)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "lock.fill")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.backgroundDark.opacity(0.62))
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("star-speller-grown-up-summary")
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

    private var voiceRequirementCard: some View {
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
            .accessibilityIdentifier("star-speller-enable-voice")
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cometGold.opacity(0.10))
        )
    }

    private var launchActions: some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                destination = .words
            } label: {
                Label("Manage words", systemImage: "doc.badge.plus")
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
                requestStartGame()
            } label: {
                Label("Start \(sessionLength) words", systemImage: "play.fill")
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

    private var wordPreview: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("\(selectedGroup.title) · \(practiceWords.count) words")
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

    private var groupPicker: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 190), spacing: AppSpacing.sm)],
            spacing: AppSpacing.sm
        ) {
            ForEach(availableGroups) { group in
                let isSelected = selectedGroup == group
                Button {
                    selectedGroup = group
                    FeedbackManager.shared.haptic(.light)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: group.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isSelected ? AppTheme.backgroundDark : AppTheme.cometCyan)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.title)
                                .font(AppTypography.buttonSmall)
                                .foregroundColor(isSelected ? AppTheme.backgroundDark : AppTheme.textPrimary)
                            Text(group.difficulty)
                                .font(AppTypography.caption)
                                .foregroundColor(
                                    isSelected
                                        ? AppTheme.backgroundDark.opacity(0.78)
                                        : AppTheme.textSecondary
                                )
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.backgroundDark)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isSelected ? AppTheme.cometCyan : AppTheme.cometPaperTop)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(group.title), \(group.difficulty)")
                .accessibilityValue(isSelected ? "Selected" : "Not selected")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("star-speller-group-\(group.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var sessionLengthPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Mission length")
                .font(AppTypography.buttonMedium)
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: AppSpacing.sm) {
                ForEach([3, 5, 10], id: \.self) { length in
                    let isSelected = sessionLength == length
                    Button {
                        sessionLength = length
                        FeedbackManager.shared.haptic(.light)
                    } label: {
                        Text("\(length) words")
                            .font(AppTypography.buttonSmall)
                            .foregroundColor(isSelected ? AppTheme.backgroundDark : AppTheme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? AppTheme.accentPrimary : AppTheme.cometPaperTop)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .accessibilityIdentifier("star-speller-length-\(length)")
                }
            }
        }
    }

    private func resumeCard(_ session: StarSpellerSessionSnapshot) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.cometGold)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Mission saved")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Resume word \(session.currentIndex + 1) of \(session.words.count).")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)

            Button(storage.isVoiceEnabled ? "Resume" : "Turn on voice") {
                if storage.isVoiceEnabled {
                    resumeGame(session)
                } else {
                    storage.setVoiceEnabled(true)
                    FeedbackManager.shared.haptic(.success)
                }
            }
            .font(AppTypography.buttonMedium)
            .foregroundColor(AppTheme.backgroundDark)
            .padding(.horizontal, AppSpacing.md)
            .frame(minHeight: 48)
            .background(Capsule().fill(AppTheme.cometGold))
            .buttonStyle(.plain)
            .accessibilityHint(
                storage.isVoiceEnabled
                    ? "Continues the saved spelling mission"
                    : "Enables the hidden-word voice prompt; activate Resume afterwards"
            )
            .accessibilityIdentifier("star-speller-resume")
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cometGold.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.cometGold.opacity(0.42), lineWidth: 1)
        )
    }

    private func requestStartGame() {
        guard canStart else { return }
        if wordStore.activeSpellingSession != nil {
            showsReplaceSessionConfirmation = true
        } else {
            startGame()
        }
    }

    private func startGame() {
        guard canStart else { return }
        sessionWords = wordStore.adaptiveSpellingWords(
            from: practiceWords,
            count: sessionLength
        )
        sessionStartIndex = 0
        sessionStartingScore = 0
        sessionStartsReadyToWrite = false
        wordStore.clearActiveSpellingSession()
        wordStore.saveSpellingSession(words: sessionWords, currentIndex: 0)
        UserDefaults.standard.set(true, forKey: tutorialDefaultsKey)
        showsHowToPlay = false
        FeedbackManager.shared.haptic(.buttonRelease)
        destination = .game
    }

    private func resumeGame(_ session: StarSpellerSessionSnapshot) {
        guard storage.isVoiceEnabled else { return }
        sessionWords = session.words
        sessionStartIndex = session.currentIndex
        sessionStartingScore = session.score ?? 0
        sessionStartsReadyToWrite = session.currentWordIsReadyToWrite ?? false
        UserDefaults.standard.set(true, forKey: tutorialDefaultsKey)
        showsHowToPlay = false
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
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @EnvironmentObject private var musicService: MusicService
    @ObservedObject private var wordStore = CometLearningStore.shared

    let words: [String]

    @State private var currentIndex: Int
    @State private var typedWord = ""
    @State private var stage: StarSpellerStage
    @State private var feedbackMessage: String
    @State private var showsCorrection = false
    @State private var showsHandwriting = false
    @State private var handwritingCompleted = false
    @State private var hasAppeared = false
    @State private var incorrectWordIndices = Set<Int>()
    @State private var hintLetters: Set<String> = []
    @State private var currentWordHintUses = 0
    @State private var currentWordCheckAttempts = 0
    @State private var currentWordErrorCount = 0
    @State private var didRecordCurrentWord: Bool
    @State private var score: Int
    @State private var showsExitConfirmation = false
    @State private var isVoiceOverAlternativeActive = false
    @State private var promptAudioState: StarSpellerPromptAudioState = .ready
    @State private var promptTask: Task<Void, Never>?
    @State private var focusTask: Task<Void, Never>?
    @State private var requiredAudioToken: UUID?
    @FocusState private var spellingFieldFocused: Bool
    @AccessibilityFocusState private var handwritingActionFocused: Bool
    @AccessibilityFocusState private var voiceOverAlternativeDoneFocused: Bool

    private let speech = LetterSpeechService.shared
    private let customAudio = CustomPromptAudioService.shared

    init(
        words: [String],
        startingIndex: Int = 0,
        startingScore: Int = 0,
        startsReadyToWrite: Bool = false
    ) {
        self.words = words
        let safeIndex = words.isEmpty ? 0 : min(max(0, startingIndex), words.count - 1)
        _currentIndex = State(initialValue: safeIndex)
        _score = State(initialValue: max(0, startingScore))
        _stage = State(initialValue: startsReadyToWrite ? .readyToWrite : .typing)
        _feedbackMessage = State(
            initialValue: startsReadyToWrite
                ? "Correct. Handwrite the word when you are ready."
                : "Listen carefully, then type the word."
        )
        _didRecordCurrentWord = State(initialValue: startsReadyToWrite)
    }

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

    private var isVoiceOverRunning: Bool {
        voiceOverEnabled || UIAccessibility.isVoiceOverRunning
    }

    private var forcesPromptAudioFailureForUITesting: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-ui-testing-force-spelling-audio-failure")
        #else
        false
        #endif
    }

    private var usesSilentPromptAudioForUITesting: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-ui-testing-use-silent-spelling-audio")
        #else
        false
        #endif
    }

    private var accessibilitySpellingPrompt: String {
        StarSpellerWordLibrary.spokenPrompt(
            for: currentWord,
            contextSentence: wordStore.contextSentence(forWord: currentWord)
                ?? StarSpellerWordLibrary.contextSentence(for: currentWord)
        )
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
            wordStore.saveSpellingSession(
                words: words,
                currentIndex: currentIndex,
                score: score,
                currentWordIsReadyToWrite: stage == .readyToWrite
            )
            if stage == .readyToWrite {
                announceHandwritingStep()
            } else {
                speakCurrentWord(after: 0.35)
                focusSpellingField(after: 0.55)
            }
        }
        .onDisappear {
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
        .alert("Leave spelling mission?", isPresented: $showsExitConfirmation) {
            Button("Keep playing", role: .cancel) {}
            Button("Leave mission", role: .destructive) {
                recordAbandonedAttemptIfNeeded()
                wordStore.saveSpellingSession(
                    words: words,
                    currentIndex: currentIndex,
                    score: score,
                    currentWordIsReadyToWrite: stage == .readyToWrite
                )
                dismiss()
            }
        } message: {
            Text("Your place is saved, so you can continue this word when you return.")
        }
        .accessibilityIdentifier("star-speller-game")
    }

    private var gameHeader: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                PremiumIconButton(
                    icon: "chevron.left",
                    action: requestExit,
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
                speakCurrentWord(announceForVoiceOver: true)
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
            .accessibilityLabel(
                isVoiceOverRunning
                    ? accessibilitySpellingPrompt
                    : "Hear the spelling word again"
            )
            .accessibilityHint(
                isVoiceOverRunning
                    ? "Double-tap to hear this prompt again"
                    : "Plays the hidden word"
            )
            .accessibilityIdentifier("star-speller-hear-word")

            if promptAudioState == .failed {
                VStack(spacing: AppSpacing.sm) {
                    Label(
                        "The word could not play. Check the sound, then try again.",
                        systemImage: "speaker.slash.fill"
                    )
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.cometGold)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("star-speller-audio-error")

                    Button {
                        speakCurrentWord(announceForVoiceOver: true)
                        FeedbackManager.shared.haptic(.light)
                    } label: {
                        Label("Try voice prompt again", systemImage: "arrow.clockwise")
                            .font(AppTypography.buttonMedium)
                            .foregroundColor(AppTheme.backgroundDark)
                            .padding(.horizontal, AppSpacing.md)
                            .frame(minHeight: 48)
                            .background(Capsule().fill(AppTheme.cometGold))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Retries the hidden spelling word")
                    .accessibilityIdentifier("star-speller-audio-retry")
                }
                .accessibilityElement(children: .contain)
            }

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
                .font(.system(.title2, design: .rounded, weight: .heavy))
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
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
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
            .accessibilityFocused($handwritingActionFocused)

            if voiceOverEnabled {
                if isVoiceOverAlternativeActive {
                    VStack(spacing: AppSpacing.sm) {
                        Text("Spell each letter aloud, then mark this step complete.")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            completeVoiceOverAlternative()
                        } label: {
                            Label("Done spelling aloud", systemImage: "checkmark.circle.fill")
                                .font(AppTypography.buttonLarge)
                                .foregroundColor(AppTheme.backgroundDark)
                                .frame(maxWidth: 460, minHeight: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppTheme.accentPrimary)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Completes the accessible alternative to drawing")
                        .accessibilityIdentifier("star-speller-voiceover-done")
                        .accessibilityFocused($voiceOverAlternativeDoneFocused)
                    }
                } else {
                    Button {
                        activateVoiceOverAlternative()
                    } label: {
                        Label("Spell aloud instead", systemImage: "waveform.and.mic")
                            .font(AppTypography.buttonMedium)
                            .foregroundColor(AppTheme.cometCyan)
                            .frame(maxWidth: 460, minHeight: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.cometPaperTop)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Provides a VoiceOver alternative to handwriting")
                    .accessibilityIdentifier("star-speller-voiceover-alternative")
                }
            }
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
                Text("You completed every spelling and writing step.")
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
                .font(.system(.title2, design: .rounded, weight: .heavy))
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
        stage == .typing
            && typedCharacterCount < currentWord.count
            && StarSpellerScoring.canUseAnotherHint(after: currentWordHintUses)
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
                            .font(.system(.title3, design: .rounded, weight: .heavy))
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
        currentWordCheckAttempts += 1

        if answer == expectedAnswer {
            spellingFieldFocused = false
            showsCorrection = false
            hintLetters = []
            let wordPoints = StarSpellerScoring.points(forHintUses: currentWordHintUses)
            score += wordPoints
            stage = .readyToWrite
            feedbackMessage = "Correct. Now handwrite the word."
            wordStore.recordSpellingAttempt(
                word: currentWord,
                checkAttempts: currentWordCheckAttempts,
                errorCount: currentWordErrorCount,
                hintUses: currentWordHintUses,
                wasSuccessful: true,
                pointsEarned: wordPoints
            )
            didRecordCurrentWord = true
            wordStore.saveSpellingSession(
                words: words,
                currentIndex: currentIndex,
                score: score,
                currentWordIsReadyToWrite: true
            )
            SoundEffectsService.shared.play(.correctMove)
            FeedbackManager.shared.haptic(.success)
            announceHandwritingStep()
        } else {
            currentWordErrorCount += 1
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

    private func speakCurrentWord(
        after delay: TimeInterval = 0,
        announceForVoiceOver: Bool = false
    ) {
        guard !currentWord.isEmpty else { return }
        promptTask?.cancel()

        guard StarSpellerAccessibilityPolicy.shouldUseAppPromptAudio(
            isVoiceOverRunning: isVoiceOverRunning
        ) else {
            speech.stop()
            customAudio.stopPlayback()
            if announceForVoiceOver {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: accessibilitySpellingPrompt
                )
            }
            return
        }

        let action = {
            speech.stop()
            customAudio.stopPlayback()
            let succeeded: Bool
            if forcesPromptAudioFailureForUITesting {
                succeeded = false
            } else if usesSilentPromptAudioForUITesting {
                // UI automation validates the hidden-word interaction without depending on the
                // simulator speech daemon, which can stall or terminate a test runner. Unit and
                // device tests still exercise the real audio-session result path.
                succeeded = true
            } else {
                succeeded = StarSpellerPromptAudioPlayback.play(
                    customRecordingFilename: wordStore.recordingFilename(forWord: currentWord),
                    customPlayback: { filename in
                        customAudio.play(filename: filename)
                    },
                    voicePlayback: {
                        speech.speakSpellingPrompt(
                            for: currentWord,
                            contextSentence: wordStore.contextSentence(forWord: currentWord)
                        )
                    }
                )
            }
            promptAudioState = .afterPlaybackAttempt(succeeded: succeeded)
            if !succeeded {
                feedbackMessage = "The word could not play. Use Try voice prompt again."
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "The spelling word could not play. Try the voice prompt again."
                )
            }
        }

        if delay <= 0 {
            action()
        } else {
            promptTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled,
                      stage == .typing,
                      StarSpellerAccessibilityPolicy.shouldUseAppPromptAudio(
                        isVoiceOverRunning: isVoiceOverRunning
                      ) else { return }
                action()
            }
        }
    }

    private func focusSpellingField(after delay: TimeInterval) {
        focusTask?.cancel()
        guard StarSpellerAccessibilityPolicy.shouldAutomaticallyFocusInput(
            isVoiceOverRunning: isVoiceOverRunning
        ) else {
            spellingFieldFocused = false
            return
        }
        focusTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled,
                  stage == .typing,
                  StarSpellerAccessibilityPolicy.shouldAutomaticallyFocusInput(
                    isVoiceOverRunning: isVoiceOverRunning
                  ) else { return }
            spellingFieldFocused = true
        }
    }

    private func openHandwriting() {
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
        currentWordCheckAttempts = 0
        currentWordErrorCount = 0
        didRecordCurrentWord = false
        isVoiceOverAlternativeActive = false

        if currentIndex + 1 >= words.count {
            stage = .sessionComplete
            feedbackMessage = "Mission complete."
            wordStore.clearActiveSpellingSession()
            SoundEffectsService.shared.play(.levelComplete)
            FeedbackManager.shared.haptic(.success)
            UIAccessibility.post(
                notification: .announcement,
                argument: "Spelling mission complete."
            )
            return
        }

        currentIndex += 1
        stage = .typing
        feedbackMessage = "Listen carefully, then type the word."
        wordStore.saveSpellingSession(
            words: words,
            currentIndex: currentIndex,
            score: score,
            currentWordIsReadyToWrite: false
        )
        speakCurrentWord(after: 0.45)
        focusSpellingField(after: 0.65)
    }

    private func resetSession() {
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
        currentWordCheckAttempts = 0
        currentWordErrorCount = 0
        didRecordCurrentWord = false
        isVoiceOverAlternativeActive = false
        score = 0
        wordStore.saveSpellingSession(
            words: words,
            currentIndex: 0,
            score: 0,
            currentWordIsReadyToWrite: false
        )
        speakCurrentWord(after: 0.35)
        focusSpellingField(after: 0.55)
    }

    private func requestExit() {
        guard stage != .sessionComplete, !words.isEmpty else {
            dismiss()
            return
        }
        spellingFieldFocused = false
        showsExitConfirmation = true
    }

    private func recordAbandonedAttemptIfNeeded() {
        guard !didRecordCurrentWord,
              currentWordCheckAttempts > 0 || currentWordHintUses > 0 else { return }
        wordStore.recordSpellingAttempt(
            word: currentWord,
            checkAttempts: max(1, currentWordCheckAttempts),
            errorCount: currentWordErrorCount,
            hintUses: currentWordHintUses,
            wasSuccessful: false,
            pointsEarned: 0
        )
        didRecordCurrentWord = true
    }

    private func announceHandwritingStep() {
        let message = "Correct. \(displayedCurrentWord). Choose Handwrite to continue."
        UIAccessibility.post(notification: .announcement, argument: message)
        Task { @MainActor in
            await Task.yield()
            handwritingActionFocused = true
        }
    }

    private func activateVoiceOverAlternative() {
        isVoiceOverAlternativeActive = true
        let letters = CometLearningStore.normalizedCustomWord(currentWord)
            .map { String($0).uppercased() }
            .joined(separator: ", ")
        UIAccessibility.post(
            notification: .announcement,
            argument: "Spell \(displayedCurrentWord) aloud, letter by letter: \(letters)."
        )
        Task { @MainActor in
            await Task.yield()
            voiceOverAlternativeDoneFocused = true
        }
    }

    private func completeVoiceOverAlternative() {
        handwritingCompleted = true
        advanceAfterHandwriting()
    }
}

#Preview("Star Speller Menu") {
    StarSpellerMenuView()
        .environmentObject(MusicService.shared)
}
