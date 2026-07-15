import SwiftUI

/// Main hub screen showing puzzle modules
struct MainHubView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService
    @StateObject private var router = AppRouter()

    @State private var showCircuitChallenge = false
    @State private var showCometWriter = false

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
                        // Portrait: vertical layout
                        VStack(spacing: AppSpacing.xl) {
                            headerView
                            Spacer()
                            moduleSelectionView(isLandscape: false)
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
            Text("Maxi's Mighty Mindgames")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            IconButton("gear") {
                router.navigate(to: .settings)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Module Selection

    private func moduleSelectionView(isLandscape: Bool) -> some View {
        VStack(spacing: isLandscape ? AppSpacing.md : AppSpacing.lg) {
            Text("Choose a Puzzle")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textSecondary)

            HStack(alignment: .top, spacing: isLandscape ? AppSpacing.lg : AppSpacing.md) {
                ModuleCardView(
                    title: "Circuit Challenge",
                    description: "Build paths and practise arithmetic",
                    iconName: "bolt.fill",
                    imageName: "circuit_challenge_icon",
                    isLocked: false
                ) {
                    showCircuitChallenge = true
                }

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
            .accessibilityElement(children: .contain)
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
