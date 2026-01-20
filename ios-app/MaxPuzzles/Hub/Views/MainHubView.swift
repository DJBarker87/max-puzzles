import SwiftUI

/// Main hub screen showing puzzle modules
struct MainHubView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService
    @StateObject private var router = AppRouter()

    @State private var showCircuitChallenge = false

    private var storage: StorageService { StorageService.shared }

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                // Fallback background color
                Color(hex: "0f0f23").ignoresSafeArea()

                StarryBackground(useHubImage: true)

                VStack(spacing: AppSpacing.xl) {
                    // Header
                    headerView

                    Spacer()

                    // Module cards
                    moduleSelectionView

                    Spacer()
                }
                .padding(.top, AppSpacing.lg)
            }
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
            .fullScreenCover(isPresented: $showCircuitChallenge) {
                ModuleMenuView()
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
            Text("Max's Puzzles")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            // Coins (V3 stub - shows guest total or 0)
            CoinDisplay(storage.totalCoinsEarned, size: .medium)

            IconButton("gear") {
                router.navigate(to: .settings)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Module Selection

    private var moduleSelectionView: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("Choose a Puzzle")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textSecondary)

            ModuleCardView(
                title: "Circuit Challenge",
                description: "Path-finding puzzle with arithmetic",
                iconName: "bolt.fill",
                imageName: "circuit_challenge_icon",
                isLocked: false
            ) {
                showCircuitChallenge = true
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 32)
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
        case .login:
            LoginPlaceholderView()
        default:
            PlaceholderView(title: "Coming Soon")
        }
    }
}

// MARK: - Placeholder Views

/// Generic placeholder for unimplemented screens
struct PlaceholderView: View {
    let title: String
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            StarryBackground(useHubImage: true)

            VStack(spacing: AppSpacing.lg) {
                Text(title)
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                SecondaryButton("Back", icon: "arrow.left") {
                    router.pop()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

/// Login screen placeholder (Phase 6)
struct LoginPlaceholderView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            StarryBackground(useHubImage: true)

            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 64))
                    .foregroundColor(AppTheme.accentPrimary)

                Text("Login / Sign Up")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Account creation coming in a future update!")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                SecondaryButton("Back", icon: "arrow.left") {
                    router.pop()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    MainHubView()
        .environmentObject(AppState())
        .environmentObject(MusicService.shared)
}
