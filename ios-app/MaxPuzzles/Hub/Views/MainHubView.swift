import SwiftUI

/// Main hub screen showing puzzle modules
struct MainHubView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService
    @StateObject private var router = AppRouter()
    @ObservedObject private var profileStore = CometLearningStore.shared

    @State private var showCircuitChallenge = false
    @State private var showCometWriter = false
    @State private var showDotToDot = false
    @State private var showStarSpeller = false
    var body: some View {
        NavigationStack(path: $router.path) {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height

                ZStack {
                    // Solid fallback background
                    AppTheme.backgroundDark
                        .ignoresSafeArea()

                    SplashBackground()

                    if isLandscape {
                        // Landscape: horizontal layout
                        HStack(spacing: AppSpacing.xl) {
                            // Header on left
                            VStack {
                                Text("Maxi's Mighty Mindgames")
                                    .font(AppTypography.titleMedium)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.75)

                                profileButton(showsName: true)

                                Spacer()

                                IconButton("gear") {
                                    router.navigate(to: .settings)
                                }
                            }
                            .frame(width: 140)
                            .padding(.vertical, AppSpacing.lg)

                            // Module cards centered
                            moduleSelectionView(isLandscape: true)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    } else {
                        // Portrait: every game stays visible. A two-by-two grid is easier for a
                        // pre-reader to recognise than an unlabeled page-control carousel.
                        ScrollView {
                            VStack(spacing: AppSpacing.lg) {
                                headerView
                                moduleSelectionView(isLandscape: false)
                                    .padding(.horizontal, AppSpacing.md)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, AppSpacing.md)
                            .padding(.bottom, AppSpacing.xl)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
            .fullScreenCover(isPresented: $showCircuitChallenge) {
                ModuleMenuView()
                    .environmentObject(appState)
                    .environmentObject(musicService)
            }
            .fullScreenCover(isPresented: $showCometWriter) {
                CometWriterMenuView()
                    .environmentObject(appState)
                    .environmentObject(musicService)
            }
            .fullScreenCover(isPresented: $showDotToDot) {
                DotToDotMenuView()
                    .environmentObject(appState)
                    .environmentObject(musicService)
            }
            .fullScreenCover(isPresented: $showStarSpeller) {
                StarSpellerMenuView()
                    .environmentObject(appState)
                    .environmentObject(musicService)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .environmentObject(router)
        .onAppear {
            // Start hub music when returning to menu
            if !musicService.isPlaying {
                musicService.play(track: .hub)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Maxi's Mighty Mindgames")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Playing as \(profileStore.activeProfile.name)")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            profileButton(showsName: false)

            IconButton("gear") {
                router.navigate(to: .settings)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func profileButton(showsName: Bool) -> some View {
        Button {
            appState.requestProfileSelection()
        } label: {
            if showsName {
                VStack(spacing: AppSpacing.xs) {
                    PlayerProfileAvatar(profile: profileStore.activeProfile, size: 52)
                    Text(profileStore.activeProfile.name)
                        .font(AppTypography.buttonSmall)
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 76)
            } else {
                PlayerProfileAvatar(profile: profileStore.activeProfile, size: 44)
                    .frame(width: 48, height: 48)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Switch player")
        .accessibilityValue("Current player \(profileStore.activeProfile.name)")
        .accessibilityHint("Opens the profile picker")
        .accessibilityIdentifier("switch-player")
    }

    // MARK: - Module Selection

    private func moduleSelectionView(isLandscape: Bool) -> some View {
        VStack(spacing: isLandscape ? AppSpacing.md : AppSpacing.lg) {
            Text("Choose a Puzzle")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textSecondary)

            if isLandscape {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    circuitCard
                    dotToDotCard
                    starSpellerCard
                    cometWriterCard
                }
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: AppSpacing.md),
                        GridItem(.flexible(), spacing: AppSpacing.md)
                    ],
                    spacing: AppSpacing.md
                ) {
                    circuitCard
                    dotToDotCard
                    starSpellerCard
                    cometWriterCard
                }
            }
        }
        .padding(.vertical, isLandscape ? AppSpacing.md : AppSpacing.xl)
        .padding(.horizontal, isLandscape ? AppSpacing.lg : AppSpacing.md)
        .frame(maxWidth: 720)
        .background(
            ZStack {
                // Outer glow
                RoundedRectangle(cornerRadius: 32)
                    .fill(AppTheme.accentPrimary.opacity(0.08))
                    .blur(radius: 20)

                // Main backdrop
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.backgroundMid.opacity(0.7),
                                AppTheme.backgroundDark.opacity(0.85)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Inner border glow
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.accentPrimary.opacity(0.4),
                                AppTheme.accentPrimary.opacity(0.1),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: AppTheme.accentPrimary.opacity(0.15), radius: 30, y: 10)
    }

    private var circuitCard: some View {
        ModuleCardView(
            title: "Circuit Challenge",
            description: "Build paths and practise arithmetic",
            iconName: "bolt.fill",
            imageName: "circuit_challenge_icon",
            isLocked: false
        ) {
            showCircuitChallenge = true
        }
    }

    private var cometWriterCard: some View {
        ModuleCardView(
            title: "Comet Writer",
            description: "Write letters and numbers",
            iconName: "pencil",
            imageName: "comet_writer_icon",
            iconGlowColor: AppTheme.cometCyan,
            isLocked: false
        ) {
            showCometWriter = true
        }
    }

    private var dotToDotCard: some View {
        ModuleCardView(
            title: "Dot-to-Dot Discovery",
            description: "Recognise numbers, then colour 84 real pictures",
            iconName: "point.3.connected.trianglepath.dotted",
            imageName: "dot_to_dot_icon",
            iconGlowColor: Color(hex: "5eead4"),
            isLocked: false
        ) {
            showDotToDot = true
        }
    }

    private var starSpellerCard: some View {
        ModuleCardView(
            title: "Star Speller",
            description: "Listen, type, then handwrite each word",
            iconName: "character.book.closed.fill",
            imageName: "star_speller_icon",
            iconGlowColor: AppTheme.cometPurple,
            isLocked: false
        ) {
            showStarSpeller = true
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .settings:
            SettingsView()
        default:
            // All routes should be handled - redirect to settings as fallback
            SettingsView()
        }
    }
}

#Preview {
    MainHubView()
        .environmentObject(AppState())
        .environmentObject(MusicService.shared)
}
