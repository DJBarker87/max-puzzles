import SwiftUI

struct CometWriterMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject private var storage = StorageService.shared
    @ObservedObject private var learningStore = CometLearningStore.shared
    @AppStorage("maxpuzzles.cometWriter.cometPoints") private var cometPoints = 0

    @State private var destination: Destination?
    @State private var showsRecallPicker = false
    @State private var selectedRecallLetters = LetterRecallCatalog.allLetters
    @State private var showsMorePractice = false
    @State private var selectedPracticeCategory: PracticeCategory?
    @State private var selectedFamily: LetterFamily?

    private enum Destination: Hashable {
        case lesson(LetterGlyph)
        case advanced(AdvancedWritingMission, recallLetters: [String])
        case quickPractice
        case dailyMission
        case flightSchool
        case paperTransfer
        case constellation
        case customWords
        case missionControl
    }

    private enum PracticeCategory: String, CaseIterable, Identifiable {
        case daily
        case lettersAndNumbers
        case soundAndWords
        case pencilControl

        var id: String { rawValue }

        var title: String {
            switch self {
            case .daily: return "Today’s Mission"
            case .lettersAndNumbers: return "Letters & Numbers"
            case .soundAndWords: return "Sounds & Words"
            case .pencilControl: return "Pencil Control"
            }
        }

        var detail: String {
            switch self {
            case .daily: return "A short, balanced practice journey"
            case .lettersAndNumbers: return "Choose one movement family"
            case .soundAndWords: return "Recall letters and build words"
            case .pencilControl: return "Lines, paper practice and progress"
            }
        }

        var icon: String {
            switch self {
            case .daily: return "flag.checkered"
            case .lettersAndNumbers: return "textformat.abc"
            case .soundAndWords: return "ear.and.waveform"
            case .pencilControl: return "pencil.line"
            }
        }

        var color: Color {
            switch self {
            case .daily: return AppTheme.cometGold
            case .lettersAndNumbers: return AppTheme.cometCyan
            case .soundAndWords: return AppTheme.cometPurple
            case .pencilControl: return AppTheme.accentPrimary
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()
                SplashBackground(overlayOpacity: 0.48)

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        header
                        stylusNote
                        missionHero
                        morePracticeDisclosure
                        grownUpTools
                    }
                    .frame(maxWidth: 920)
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
                    case let .lesson(glyph):
                        CometWriterGameView(startingGlyph: glyph)
                    case let .advanced(mission, recallLetters):
                        AdvancedWritingGameView(
                            mission: mission,
                            recallCharacters: recallLetters,
                            words: learningStore.availableWords,
                            sessionLength: mission == .wordWriting || mission == .alienMail ? 3 : 5
                        )
                    case .quickPractice:
                        CometQuickPracticeView()
                    case .dailyMission:
                        CometDailyMissionView()
                    case .flightSchool:
                        CometFlightSchoolView()
                    case .paperTransfer:
                        CometPaperTransferView()
                    case .constellation:
                        CometConstellationView()
                    case .customWords:
                        CometCustomWordsView()
                    case .missionControl:
                        CometMissionControlView()
                    }
                }
            }
        }
        .sheet(isPresented: $showsRecallPicker) {
            LetterRecallPickerView(
                selectedLetters: $selectedRecallLetters,
                onStart: { recallLetters in
                    destination = .advanced(.letterRecall, recallLetters: recallLetters)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        // Keep the largest accessibility setting readable without allowing text to squeeze every
        // launch control off a compact iPhone screen. AX1 remains substantially enlarged.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .background {
            Color.clear
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Comet Writer menu")
                .accessibilityIdentifier("comet-writer-menu")
        }
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        closeButton
                        headerTitle
                        Spacer(minLength: 0)
                    }

                    progressBadge
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack(spacing: AppSpacing.md) {
                    closeButton
                    headerTitle
                    Spacer(minLength: 0)
                    progressBadge
                }
            }
        }
        .padding(.top, AppSpacing.md)
    }

    private var closeButton: some View {
        PremiumIconButton(
            icon: "xmark",
            action: { dismiss() },
            size: 48,
            accessibilityLabelText: "Close Comet Writer"
        )
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Comet Writer")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Learn how every letter and number moves")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var progressBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundColor(AppTheme.cometGold)
            Text("\(practisedCount)/\(LetterLibrary.all.count)")
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.textPrimary)
                .monospacedDigit()
                .lineLimit(1)

            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 1, height: 20)

            Image(systemName: "sparkles")
                .foregroundColor(AppTheme.cometGold)
            Text("\(displayedPoints)")
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.cometGold)
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(Capsule().fill(AppTheme.backgroundMid.opacity(0.86)))
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(practisedCount) of \(LetterLibrary.all.count) symbols practised, \(displayedPoints) Comet Points")
        .accessibilityIdentifier("comet-writer-progress")
    }

    private var stylusNote: some View {
        Label {
            Text("Write with your finger, or use a stylus if you have one.")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "pencil.tip.crop.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(AppTheme.cometCyan)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.md)
        .frame(minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.cometPurple.opacity(0.16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppTheme.cometCyan.opacity(0.38), lineWidth: 1)
        )
        .accessibilityIdentifier("comet-writer-stylus-note")
    }

    private var missionHero: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.md) {
                        novaImage(size: 64)
                        missionTitle
                    }
                    missionDescription
                    missionActions
                }
            } else {
                HStack(spacing: AppSpacing.md) {
                    novaImage(size: 92)

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        missionTitle
                        missionDescription
                        missionActions
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.backgroundMid.opacity(0.86))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.cometCyan.opacity(0.34), lineWidth: 1)
        )
    }

    private func novaImage(size: CGFloat) -> some View {
        Image("alien_nova")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var missionTitle: some View {
        Text(practisedCount == 0 ? "Ready for launch?" : "Continue your mission")
            .font(AppTypography.titleSmall)
            .foregroundColor(AppTheme.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var missionDescription: some View {
        Text("Trace each symbol three ways: follow the glow, connect the stars, then fly solo.")
            .font(AppTypography.bodySmall)
            .foregroundColor(AppTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var missionActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.sm) {
                continueButton
                choosePracticeButton
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                continueButton
                choosePracticeButton
            }
        }
    }

    private var continueButton: some View {
        PrimaryButton(
            practisedCount == 0 ? "Start with c" : "Continue",
            icon: "paperplane.fill",
            size: .medium
        ) {
            destination = .lesson(continueGlyph)
        }
        .accessibilityIdentifier("comet-writer-continue")
    }

    private var choosePracticeButton: some View {
        SecondaryButton("Choose practice", icon: "hand.tap.fill") {
            destination = .quickPractice
        }
        .accessibilityIdentifier("comet-writer-quick-practice")
    }

    private var morePracticeDisclosure: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Button {
                if reduceMotion {
                    showsMorePractice.toggle()
                } else {
                    withAnimation(.easeInOut(duration: 0.20)) {
                        showsMorePractice.toggle()
                    }
                }
                if !showsMorePractice {
                    selectedPracticeCategory = nil
                    selectedFamily = nil
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundColor(AppTheme.cometPurple)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(AppTheme.cometPurple.opacity(0.18)))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("More Practice")
                            .font(AppTypography.titleSmall)
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Sounds, words, pencil control and every letter family")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                    Image(systemName: showsMorePractice ? "chevron.up" : "chevron.down")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.cometCyan)
                        .accessibilityHidden(true)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.backgroundMid.opacity(0.88))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.cometPurple.opacity(0.34), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More Practice")
            .accessibilityValue(showsMorePractice ? "Expanded" : "Collapsed")
            .accessibilityHint(showsMorePractice ? "Hides additional practice" : "Shows additional practice")
            .accessibilityIdentifier("comet-writer-more-practice")

            if showsMorePractice {
                if let selectedPracticeCategory {
                    practiceCategoryHeader(selectedPracticeCategory)
                    practiceContent(for: selectedPracticeCategory)
                } else {
                    practiceCategoryGrid
                }
            }
        }
    }

    private var practiceCategoryGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 250), spacing: AppSpacing.md)],
            spacing: AppSpacing.md
        ) {
            ForEach(PracticeCategory.allCases) { category in
                Button {
                    selectPracticeCategory(category)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: category.icon)
                            .font(.system(size: 23, weight: .bold))
                            .foregroundColor(category.color)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(category.color.opacity(0.16)))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.title)
                                .font(AppTypography.buttonLarge)
                                .foregroundColor(AppTheme.textPrimary)
                            Text(category.detail)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 20).fill(AppTheme.backgroundMid.opacity(0.88)))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(category.color.opacity(0.28), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(category.title), \(category.detail)")
                .accessibilityHint("Shows only this practice category")
                .accessibilityIdentifier("comet-writer-category-\(category.rawValue)")
            }
        }
    }

    private func practiceCategoryHeader(_ category: PracticeCategory) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                if category == .lettersAndNumbers, selectedFamily != nil {
                    selectedFamily = nil
                } else {
                    selectedPracticeCategory = nil
                    selectedFamily = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.cometCyan)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppTheme.backgroundMid.opacity(0.92)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(selectedFamily == nil ? "Back to practice categories" : "Back to letter families")

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedFamily?.title ?? category.title)
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(selectedFamily?.formationHint ?? category.detail)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .accessibilityIdentifier("comet-writer-category-header")
    }

    @ViewBuilder
    private func practiceContent(for category: PracticeCategory) -> some View {
        switch category {
        case .daily:
            featureCard(
                title: "Today’s Comet Mission",
                detail: "A balanced warm-up, formation, sound, word and paper journey.",
                icon: "flag.checkered",
                color: AppTheme.cometGold,
                destination: .dailyMission,
                identifier: "comet-writer-daily-mission"
            )
        case .lettersAndNumbers:
            familyGrid
        case .soundAndWords:
            advancedMissions
        case .pencilControl:
            moreWaysToLearn
        }
    }

    private func selectPracticeCategory(_ category: PracticeCategory) {
        if reduceMotion {
            selectedPracticeCategory = category
        } else {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedPracticeCategory = category
            }
        }
        selectedFamily = nil
        FeedbackManager.shared.haptic(.light)
        SoundEffectsService.shared.play(.cardTap)
    }

    private var advancedMissions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Ready for a challenge?")
                        .font(AppTypography.titleSmall)
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Remember letters and build real words with only a start star.")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
                Label("More points", systemImage: "sparkles")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.cometGold)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 260), spacing: AppSpacing.md)],
                spacing: AppSpacing.md
            ) {
                advancedMissionCard(
                    mission: .letterRecall,
                    title: "Letter Recall",
                    detail: "See it or hear it, then write it from memory.",
                    icon: "ear.and.waveform",
                    reward: "Up to 10 per letter"
                )
                advancedMissionCard(
                    mission: .wordWriting,
                    title: "Word Mission",
                    detail: "Write a whole common word on one writing line.",
                    icon: "textformat.abc",
                    reward: "+25 bonus"
                )
                advancedMissionCard(
                    mission: .phonics,
                    title: "Letter Name Mission",
                    detail: "Hear a letter name, remember it, then write it.",
                    icon: "waveform.and.mic",
                    reward: "5 adaptive letters"
                )
                advancedMissionCard(
                    mission: .alienMail,
                    title: "Alien Mail",
                    detail: "Write complete words to send messages to Nova.",
                    icon: "paperplane.fill",
                    reward: "+25 per message"
                )
            }
        }
    }

    private func advancedMissionCard(
        mission: AdvancedWritingMission,
        title: String,
        detail: String,
        icon: String,
        reward: String
    ) -> some View {
        Button {
            if mission == .letterRecall {
                showsRecallPicker = true
            } else {
                destination = .advanced(
                    mission,
                    recallLetters: mission == .phonics ? LetterRecallCatalog.teachingOrder : []
                )
            }
            FeedbackManager.shared.haptic(.medium)
            SoundEffectsService.shared.play(.cardTap)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.cometCyan)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(AppTheme.cometPurple.opacity(0.24)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.buttonLarge)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(detail)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(reward)
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.cometGold)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.backgroundMid.opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.cometPurple.opacity(0.34), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(
            mission == .letterRecall
                ? "comet-writer-letter-recall"
                : mission == .wordWriting
                    ? "comet-writer-word-writing"
                    : "comet-writer-\(mission.rawValue)"
        )
        .accessibilityLabel("\(title), \(detail), reward \(reward) Comet Points")
    }

    private var familyGrid: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if let selectedFamily {
                familyCard(selectedFamily)
            } else {
                Text("Choose one movement family")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 250), spacing: AppSpacing.md)],
                    spacing: AppSpacing.md
                ) {
                    ForEach(LetterFamily.allCases) { family in
                        familySelectionCard(family)
                    }
                }
            }
        }
    }

    private func familySelectionCard(_ family: LetterFamily) -> some View {
        let glyphs = LetterLibrary.glyphs(in: family)
        let completed = glyphs.filter { mastery(for: $0.character) != .new }.count

        return Button {
            if reduceMotion {
                selectedFamily = family
            } else {
                withAnimation(.easeInOut(duration: 0.18)) {
                    selectedFamily = family
                }
            }
            FeedbackManager.shared.haptic(.light)
            SoundEffectsService.shared.play(.cardTap)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: family.symbol)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(AppTheme.cometCyan)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(AppTheme.cometPurple.opacity(0.22)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(family.title)
                        .font(AppTypography.buttonLarge)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(family.formationHint)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
                Text("\(completed)/\(glyphs.count)")
                    .font(AppTypography.buttonSmall)
                    .foregroundColor(completed == glyphs.count ? AppTheme.accentPrimary : AppTheme.cometGold)
                    .monospacedDigit()
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(AppTheme.backgroundMid.opacity(0.84)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(family.title), \(completed) of \(glyphs.count) symbols complete")
        .accessibilityHint("Shows this movement family")
        .accessibilityIdentifier("comet-writer-family-\(family.rawValue)")
    }

    private var moreWaysToLearn: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("More ways to learn")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 240), spacing: AppSpacing.md)],
                spacing: AppSpacing.md
            ) {
                featureCard(
                    title: "Flight School",
                    detail: "Build pencil control with lines, slants, curves and loops.",
                    icon: "paperplane.fill",
                    color: AppTheme.cometPurple,
                    destination: .flightSchool,
                    identifier: "comet-writer-flight-school"
                )
                featureCard(
                    title: "My Constellation",
                    detail: "See secure formations light up and choose what to revisit.",
                    icon: "sparkles",
                    color: AppTheme.cometGold,
                    destination: .constellation,
                    identifier: "comet-writer-constellation"
                )
                featureCard(
                    title: "Paper Mission",
                    detail: "Move from the screen to real pencil-and-paper writing.",
                    icon: "doc.text.fill",
                    color: AppTheme.accentPrimary,
                    destination: .paperTransfer,
                    identifier: "comet-writer-paper-transfer"
                )
            }
        }
    }

    private var grownUpTools: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Divider()
                .overlay(Color.white.opacity(0.18))

            VStack(alignment: .leading, spacing: 3) {
                Label("For grown-ups", systemImage: "lock.fill")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.cometGold)
                Text("Protected by a grown-up check. Compact progress may sync privately with Apple iCloud; detailed attempts and recordings stay local.")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 280), spacing: AppSpacing.md)],
                spacing: AppSpacing.md
            ) {
                featureCard(
                    title: "My Words",
                    detail: "Add names and classroom words, with an optional local voice prompt.",
                    icon: "text.badge.plus",
                    color: AppTheme.cometCyan,
                    destination: .customWords,
                    identifier: "comet-writer-my-words"
                )
                featureCard(
                    title: "Mission Control",
                    detail: "Profiles, mastery, correction insights, trace replay and PDF reports.",
                    icon: "chart.bar.xaxis",
                    color: AppTheme.cometGold,
                    destination: .missionControl,
                    identifier: "comet-writer-mission-control"
                )
            }
        }
    }

    private func featureCard(
        title: String,
        detail: String,
        icon: String,
        color: Color,
        destination nextDestination: Destination,
        identifier: String
    ) -> some View {
        Button {
            destination = nextDestination
            FeedbackManager.shared.haptic(.medium)
            SoundEffectsService.shared.play(.cardTap)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(color.opacity(0.14)))
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
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20).fill(AppTheme.backgroundMid.opacity(0.88)))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel("\(title), \(detail)")
    }

    private func familyCard(_ family: LetterFamily) -> some View {
        let glyphs = LetterLibrary.glyphs(in: family)
        let completed = glyphs.filter { mastery(for: $0.character) != .new }.count

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.cometPurple.opacity(0.24))
                        .frame(width: 48, height: 48)
                    Image(systemName: family.symbol)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(AppTheme.cometCyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(family.title)
                        .font(AppTypography.buttonLarge)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(family.formationHint)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Text("\(completed)/\(glyphs.count)")
                    .font(AppTypography.buttonSmall)
                    .foregroundColor(completed == glyphs.count ? AppTheme.accentPrimary : AppTheme.cometGold)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 42), spacing: 7)], spacing: 7) {
                ForEach(glyphs) { glyph in
                    let bestScore = bestScore(for: glyph.character)
                    let isPractised = mastery(for: glyph.character) != .new
                    Button {
                        destination = .lesson(glyph)
                        FeedbackManager.shared.haptic(.light)
                        SoundEffectsService.shared.play(.cardTap)
                    } label: {
                        VStack(spacing: 0) {
                            Text(glyph.character)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                            if let bestScore {
                                Text("\(bestScore)")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                            }
                        }
                        .foregroundColor(
                            isPractised
                                ? AppTheme.backgroundDark
                                : AppTheme.textPrimary
                        )
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(
                                    isPractised
                                        ? AppTheme.accentPrimary
                                        : AppTheme.cometPaperTop
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("comet-writer-practice-\(glyph.character)")
                    .accessibilityLabel(
                        bestScore.map { "Practice \(glyph.formationName), best score \($0) out of 100" }
                            ?? "Practice \(glyph.formationName), not completed"
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.backgroundMid.opacity(0.84))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(family.title), \(completed) of \(glyphs.count) symbols complete")
    }

    private var continueGlyph: LetterGlyph {
        if let last = learningStore.recentAttempts(limit: 1).first?.character,
           let glyph = LetterLibrary.glyph(for: last),
           mastery(for: last) != .mastered {
            return glyph
        }

        return LetterLibrary.practiceOrder
            .first { mastery(for: $0) == .new }
            .flatMap { LetterLibrary.glyph(for: $0) }
            ?? LetterLibrary.glyph(for: "c")!
    }

    private var practisedCount: Int {
        LetterLibrary.all.filter { mastery(for: $0.character) != .new }.count
    }

    private var displayedPoints: Int {
        learningStore.profiles.count == 1 ? cometPoints : learningStore.activePoints
    }

    private func mastery(for character: String) -> CometMasteryLevel {
        let learned = learningStore.mastery(for: character)
        if learned == .new,
           learningStore.profiles.count == 1,
           storage.cometWriterCompletedLetters.contains(character) {
            return .practising
        }
        return learned
    }

    private func bestScore(for character: String) -> Int? {
        learningStore.bestScore(for: character)
            ?? (learningStore.profiles.count == 1 ? storage.bestCometWriterScore(for: character) : nil)
    }
}

private struct LetterRecallPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedLetters: Set<String>
    let onStart: ([String]) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 44), spacing: AppSpacing.sm),
        count: 6
    )

    private var allSelected: Bool {
        selectedLetters == LetterRecallCatalog.allLetters
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundDark.ignoresSafeArea()
            StarryBackground(starCount: 22, animateStars: false)

            VStack(spacing: AppSpacing.lg) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        selectionSummary
                        letterGrid

                        if selectedLetters.isEmpty {
                            Label("Choose at least one letter.", systemImage: "arrow.up.circle.fill")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppTheme.cometGold)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .accessibilityIdentifier("comet-writer-recall-empty")
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
                .scrollIndicators(.hidden)

                PrimaryButton("Start Recall", icon: "paperplane.fill", size: .large) {
                    let orderedLetters = LetterRecallCatalog.orderedSelection(selectedLetters)
                    guard !orderedLetters.isEmpty else { return }
                    SoundEffectsService.shared.play(.buttonTap)
                    onStart(orderedLetters)
                    dismiss()
                }
                .disabled(selectedLetters.isEmpty)
                .opacity(selectedLetters.isEmpty ? 0.45 : 1)
                .accessibilityIdentifier("comet-writer-start-recall")
                .accessibilityHint(
                    selectedLetters.isEmpty
                        ? "Choose at least one letter first"
                        : "Starts Letter Recall with the selected letters"
                )
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
            }
        }
        .background {
            Color.clear
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Choose recall letters")
                .accessibilityIdentifier("comet-writer-recall-picker")
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.md) {
            PremiumIconButton(
                icon: "xmark",
                action: { dismiss() },
                size: 48,
                accessibilityLabelText: "Close letter picker"
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Choose recall letters")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Text("All letters are selected to start.")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.md)
    }

    private var selectionSummary: some View {
        HStack(spacing: AppSpacing.sm) {
            Text("\(selectedLetters.count) of \(LetterRecallCatalog.alphabet.count) selected")
                .font(AppTypography.buttonMedium)
                .foregroundColor(AppTheme.textPrimary)
                .accessibilityIdentifier("comet-writer-recall-selection-count")

            Spacer(minLength: 0)

            Button(allSelected ? "Clear all" : "Select all") {
                selectedLetters = allSelected ? [] : LetterRecallCatalog.allLetters
                FeedbackManager.shared.haptic(.light)
            }
            .font(AppTypography.buttonSmall)
            .foregroundColor(AppTheme.cometCyan)
            .frame(minHeight: 44)
            .padding(.horizontal, 12)
            .background(Capsule().fill(AppTheme.cometPaperTop))
            .buttonStyle(.plain)
            .accessibilityIdentifier("comet-writer-recall-toggle-all")
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.backgroundMid.opacity(0.90))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppTheme.cometPurple.opacity(0.34), lineWidth: 1)
        )
    }

    private var letterGrid: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ForEach(LetterRecallCatalog.alphabet, id: \.self) { letter in
                letterButton(letter)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func letterButton(_ letter: String) -> some View {
        let isSelected = selectedLetters.contains(letter)

        return Button {
            if isSelected {
                selectedLetters.remove(letter)
            } else {
                selectedLetters.insert(letter)
            }
            FeedbackManager.shared.haptic(.light)
        } label: {
            Text(letter)
                                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundColor(isSelected ? AppTheme.backgroundDark : AppTheme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? AppTheme.cometCyan : AppTheme.cometPaperTop)
                )
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.backgroundDark)
                            .padding(4)
                            .accessibilityHidden(true)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recall-letter-\(letter)")
        .accessibilityLabel("Letter \(letter)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    CometWriterMenuView()
}
