import SwiftUI

/// Main hub screen showing puzzle modules
struct MainHubView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                StarryBackground()

                VStack(spacing: AppSpacing.xl) {
                    // Header
                    headerView

                    Spacer()

                    // Module cards
                    moduleSelectionView

                    Spacer()

                    // Guest mode indicator
                    if appState.isGuest {
                        guestModeIndicator
                    }
                }
                .padding(.top, AppSpacing.lg)
            }
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
        }
        .environmentObject(router)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Max's Puzzles")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            // Coins (V3 stub - shows 0)
            CoinDisplay(0, size: .medium)

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
                isLocked: false
            ) {
                router.navigate(to: .circuitChallengeMenu)
            }
        }
    }

    // MARK: - Guest Mode Indicator

    private var guestModeIndicator: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "person.fill.questionmark")
            Text("Playing as Guest")
            Text("•")
            Button("Create Account") {
                router.navigate(to: .login)
            }
            .foregroundColor(AppTheme.accentPrimary)
        }
        .font(AppTypography.bodySmall)
        .foregroundColor(AppTheme.textSecondary)
        .padding(.bottom, AppSpacing.lg)
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .settings:
            SettingsPlaceholderView()
        case .login:
            LoginPlaceholderView()
        case .circuitChallengeMenu:
            CircuitChallengeMenuPlaceholderView()
        case .circuitChallengeSetup:
            QuickPlaySetupPlaceholderView()
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
            StarryBackground()

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

/// Settings screen placeholder
struct SettingsPlaceholderView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            StarryBackground()

            VStack(spacing: AppSpacing.lg) {
                Text("Settings")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Coming in Phase 5")
                    .foregroundColor(AppTheme.textSecondary)

                SecondaryButton("Back", icon: "arrow.left") {
                    router.pop()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

/// Login screen placeholder
struct LoginPlaceholderView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            StarryBackground()

            VStack(spacing: AppSpacing.lg) {
                Text("Login / Sign Up")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Coming in Phase 6")
                    .foregroundColor(AppTheme.textSecondary)

                SecondaryButton("Back", icon: "arrow.left") {
                    router.pop()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

/// Circuit Challenge menu placeholder
struct CircuitChallengeMenuPlaceholderView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            StarryBackground()

            VStack(spacing: AppSpacing.lg) {
                Text("Circuit Challenge")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                PrimaryButton("Quick Play", icon: "play.fill") {
                    router.navigate(to: .circuitChallengeSetup)
                }

                SecondaryButton("Back to Hub", icon: "arrow.left") {
                    router.pop()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

/// Quick Play setup placeholder
struct QuickPlaySetupPlaceholderView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            StarryBackground()

            VStack(spacing: AppSpacing.lg) {
                Text("Quick Play Setup")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Difficulty selection coming in Phase 4")
                    .foregroundColor(AppTheme.textSecondary)

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
}
