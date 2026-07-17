import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService

    var body: some View {
        ZStack {
            // Solid background that renders immediately - prevents black screen on first layout
            AppTheme.backgroundDark
                .ignoresSafeArea()

            #if DEBUG
            if let dotPreviewIndex {
                DotToDotSinglePreview(index: dotPreviewIndex)
            } else if let dotReviewPage {
                DotToDotReviewSheet(page: dotReviewPage)
            } else if let appStoreScreen {
                AppStoreScreenshotScene(screen: appStoreScreen)
            } else if appState.isLoading {
                SplashView()
            } else if appState.needsFirstRun {
                FirstRunView()
            } else if appState.needsProfileSelection {
                PlayerProfileSelectionView()
            } else {
                MainHubView()
            }
            #else
            if appState.isLoading {
                SplashView()
            } else if appState.needsFirstRun {
                FirstRunView()
            } else if appState.needsProfileSelection {
                PlayerProfileSelectionView()
            } else {
                MainHubView()
            }
            #endif
        }
    }

    #if DEBUG
    private var appStoreScreen: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-app-store-screen"),
              arguments.indices.contains(flagIndex + 1) else { return nil }
        return arguments[flagIndex + 1]
    }

    private var dotReviewPage: Int? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-dot-review-page"),
              arguments.indices.contains(flagIndex + 1),
              let page = Int(arguments[flagIndex + 1]) else { return nil }
        return min(max(page, 0), 9)
    }

    private var dotPreviewIndex: Int? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-dot-preview-index"),
              arguments.indices.contains(flagIndex + 1),
              let index = Int(arguments[flagIndex + 1]) else { return nil }
        return min(max(index, 0), DotPuzzleCatalog.downloadedReferencePuzzles.count - 1)
    }
    #endif
}

struct PlayerProfileSelectionView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var profileStore = CometLearningStore.shared

    @State private var showsAddProfile = false

    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 190), spacing: AppSpacing.lg)
    ]

    var body: some View {
        ZStack {
            AppTheme.backgroundDark.ignoresSafeArea()
            SplashBackground(overlayOpacity: 0.58)

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    VStack(spacing: AppSpacing.sm) {
                        Text("Who’s playing?")
                            .font(AppTypography.displayMedium)
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Choose a profile so every child keeps their own progress.")
                            .font(AppTypography.bodyLarge)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 520)
                    }

                    LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
                        ForEach(profileStore.profiles) { profile in
                            profileButton(profile)
                        }

                        addProfileButton
                    }
                    .frame(maxWidth: 720)

                    Label(
                        "When iCloud is available, a compact progress summary can sync privately.",
                        systemImage: "icloud.fill"
                    )
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xxl)
                .padding(.bottom, AppSpacing.xxl)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("player-profile-selection")
        }
        .sheet(isPresented: $showsAddProfile) {
            AddPlayerProfileView { name, hand in
                profileStore.addProfile(name: name, writingHand: hand)
                appState.selectProfile(profileStore.activeProfileID)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func profileButton(_ profile: CometChildProfile) -> some View {
        Button {
            FeedbackManager.shared.haptic(.buttonRelease)
            appState.selectProfile(profile.id)
        } label: {
            VStack(spacing: AppSpacing.md) {
                PlayerProfileAvatar(profile: profile, size: 96)

                VStack(spacing: AppSpacing.xs) {
                    Text(profile.name)
                        .font(AppTypography.buttonLarge)
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(profile.id == profileStore.activeProfileID ? "Last played" : "Tap to play")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.backgroundMid.opacity(0.90))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        profile.id == profileStore.activeProfileID
                            ? AppTheme.accentPrimary
                            : Color.white.opacity(0.16),
                        lineWidth: profile.id == profileStore.activeProfileID ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(profile.name) profile")
        .accessibilityHint("Selects \(profile.name) and opens the main menu")
        .accessibilityIdentifier("player-profile-\(profile.id.uuidString)")
    }

    private var addProfileButton: some View {
        Button {
            showsAddProfile = true
        } label: {
            VStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(AppTheme.backgroundMid)
                        .frame(width: 96, height: 96)
                    Circle()
                        .stroke(
                            AppTheme.cometCyan.opacity(0.75),
                            style: StrokeStyle(lineWidth: 2, dash: [7, 6])
                        )
                        .frame(width: 96, height: 96)
                    Image(systemName: "plus")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(AppTheme.cometCyan)
                }
                .accessibilityHidden(true)

                VStack(spacing: AppSpacing.xs) {
                    Text("Add a child")
                        .font(AppTypography.buttonLarge)
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Create another profile")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.backgroundDark.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppTheme.cometCyan.opacity(0.34), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("add-player-profile")
    }
}

struct PlayerProfileAvatar: View {
    let profile: CometChildProfile
    var size: CGFloat = 44

    private let colors = [
        AppTheme.accentPrimary,
        AppTheme.cometCyan,
        AppTheme.cometPurple,
        AppTheme.accentTertiary,
        AppTheme.accentSecondary
    ]

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(initial)
                .font(.system(size: size * 0.42, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.backgroundDark)
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.48), lineWidth: max(1, size * 0.025))
        )
        .accessibilityHidden(true)
    }

    private var initial: String {
        profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            .first
            .map { String($0).uppercased() }
            ?? "★"
    }

    private var accentColor: Color {
        let value = profile.id.uuidString.unicodeScalars.reduce(0) {
            $0 + Int($1.value)
        }
        return colors[value % colors.count]
    }
}

private struct AddPlayerProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profileStore = CometLearningStore.shared

    let onAdd: (String, WritingHand) -> Void

    @State private var name = ""
    @State private var writingHand: WritingHand = .right
    @FocusState private var nameFocused: Bool

    private var cleanedName: String {
        String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
    }

    private var duplicateName: Bool {
        profileStore.profiles.contains {
            $0.name.compare(
                cleanedName,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) == .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Child’s name")
                                .font(AppTypography.buttonLarge)
                                .foregroundColor(AppTheme.textPrimary)

                            TextField("Name", text: $name)
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .font(AppTypography.bodyLarge)
                                .foregroundColor(AppTheme.textPrimary)
                                .tint(AppTheme.cometCyan)
                                .padding(.horizontal, AppSpacing.md)
                                .frame(minHeight: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppTheme.backgroundMid)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            duplicateName
                                                ? AppTheme.error
                                                : AppTheme.cometCyan.opacity(0.42),
                                            lineWidth: 1
                                        )
                                )
                                .focused($nameFocused)

                            if duplicateName {
                                Text("That name already has a profile.")
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppTheme.error)
                            } else {
                                Text("Use a name each child can recognise.")
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Writing hand")
                                .font(AppTypography.buttonLarge)
                                .foregroundColor(AppTheme.textPrimary)

                            Text("Comet Writer uses this to keep controls clear of their hand.")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppTheme.textSecondary)

                            Picker("Writing hand", selection: $writingHand) {
                                ForEach(WritingHand.allCases) { hand in
                                    Text(hand.title).tag(hand)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Button {
                            onAdd(cleanedName, writingHand)
                        } label: {
                            Label("Add profile", systemImage: "person.badge.plus")
                                .font(AppTypography.buttonLarge)
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppTheme.accentPrimary)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(cleanedName.isEmpty || duplicateName)
                        .opacity(cleanedName.isEmpty || duplicateName ? 0.45 : 1)
                    }
                    .frame(maxWidth: 520)
                    .padding(AppSpacing.lg)
                }
            }
            .navigationTitle("Add a child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.cometCyan)
                }
            }
            .onAppear { nameFocused = true }
        }
        .preferredColorScheme(.dark)
    }
}

#if DEBUG
/// Deterministic navigation for pixel-perfect App Store captures. It exposes only real screens
/// and compiles out of the Release configuration.
private struct AppStoreScreenshotScene: View {
    let screen: String

    var body: some View {
        switch screen {
        case "hub":
            MainHubView()
        case "circuit":
            ModuleMenuView()
        case "writer-menu":
            CometWriterMenuView()
        case "quick-practice":
            NavigationStack { CometQuickPracticeView() }
        case "guided-c":
            NavigationStack {
                CometWriterGameView(startingGlyph: LetterLibrary.glyph(for: "c")!)
            }
        case "capital-a":
            NavigationStack {
                CometWriterGameView(startingGlyph: LetterLibrary.glyph(for: "A")!)
            }
        case "word-mission":
            NavigationStack {
                AdvancedWritingGameView(
                    mission: .wordWriting,
                    words: ["cat", "moon", "star"],
                    sessionLength: 3
                )
            }
        case "flight-school":
            NavigationStack { CometFlightSchoolView() }
        case "constellation":
            NavigationStack { CometConstellationView() }
        case "dot-menu":
            DotToDotMenuView()
        case "dot-game-tap":
            if let puzzle = DotPuzzleCatalog.puzzles(in: .numberExplorer).first {
                DotToDotPlayView(
                    puzzle: puzzle,
                    interactionMode: .tap,
                    initialProgress: 8
                )
            }
        case "dot-game-trace":
            if let puzzle = DotPuzzleCatalog.puzzles(in: .numberExplorer).first {
                DotToDotPlayView(
                    puzzle: puzzle,
                    interactionMode: .trace,
                    initialProgress: 8
                )
            }
        case "dot-paint":
            if let puzzle = DotPuzzleCatalog.all.first {
                DotToDotPlayView(
                    puzzle: puzzle,
                    interactionMode: .tap,
                    initialProgress: puzzle.points.count,
                    showsCompletionInitially: true
                )
            }
        default:
            MainHubView()
        }
    }
}
#endif

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(MusicService.shared)
}
