import SwiftUI

/// Main hub screen showing puzzle modules
struct MainHubView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var router = AppRouter()
    @ObservedObject private var profileStore = CometLearningStore.shared

    @State private var showCircuitChallenge = false
    @State private var showCometWriter = false
    @State private var showDotToDot = false
    @State private var showStarSpeller = false
    @State private var selectedModulePage = 0

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
                            moduleSelectionView(
                                isLandscape: true,
                                usePortraitGrid: false
                            )
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    } else {
                        // Portrait: vertical layout
                        VStack(spacing: AppSpacing.xl) {
                            headerView
                            Spacer()
                            moduleSelectionView(
                                isLandscape: false,
                                usePortraitGrid: geometry.size.width >= 700
                            )
                                .padding(.horizontal, AppSpacing.md)
                            Spacer()
                        }
                        .padding(.top, AppSpacing.lg)
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

    private func moduleSelectionView(
        isLandscape: Bool,
        usePortraitGrid: Bool
    ) -> some View {
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
            } else if usePortraitGrid {
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
            } else {
                VStack(spacing: AppSpacing.sm) {
                    TabView(selection: $selectedModulePage) {
                        circuitCard
                            .frame(width: 235)
                            .tag(0)
                        dotToDotCard
                            .frame(width: 235)
                            .tag(1)
                        starSpellerCard
                            .frame(width: 235)
                            .tag(2)
                        cometWriterCard
                            .frame(width: 235)
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 370)
                    .accessibilityLabel("Puzzle games")
                    .accessibilityValue("Page \(selectedModulePage + 1) of 4")
                    .accessibilityIdentifier("puzzle-game-carousel")

                    HStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { page in
                            Button {
                                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                                    selectedModulePage = page
                                }
                            } label: {
                                Circle()
                                    .fill(
                                        page == selectedModulePage
                                            ? AppTheme.cometCyan
                                            : AppTheme.textSecondary.opacity(0.55)
                                    )
                                    .frame(width: 10, height: 10)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(modulePageName(page))
                            .accessibilityValue(page == selectedModulePage ? "Selected" : "")
                        }
                    }
                    .accessibilityElement(children: .contain)
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
            description: "Recognise numerals, then colour 84 real pictures",
            iconName: "point.3.connected.trianglepath.dotted",
            imageName: "dot_to_dot_icon",
            iconGlowColor: Color(hex: "5eead4"),
            isLocked: false
        ) {
            showDotToDot = true
        }
    }

    private func modulePageName(_ page: Int) -> String {
        switch page {
        case 0: return "Show Circuit Challenge"
        case 1: return "Show Dot-to-Dot Discovery"
        case 2: return "Show Star Speller"
        default: return "Show Comet Writer"
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
