import SwiftUI

/// Splash screen shown during app launch
/// Initializes guest session and performs startup animations
struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8
    @State private var boltGlow: Double = 0.5
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        ZStack {
            // Hub background image
            StarryBackground(useHubImage: true)

            VStack(spacing: AppSpacing.lg) {
                // App icon with animated glow
                ZStack {
                    // Glow backdrop
                    Circle()
                        .fill(AppTheme.connectorGlow.opacity(boltGlow * 0.2))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)

                    // Hex shape
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 120))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    AppTheme.accentPrimary.opacity(0.4),
                                    AppTheme.accentPrimary.opacity(0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Electric bolt icon
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.connectorGlow)
                        .shadow(color: AppTheme.connectorGlow.opacity(boltGlow), radius: 12)
                }
                .scaleEffect(scale)

                // Title
                Text("Max's Puzzles")
                    .font(AppTypography.titleLarge)
                    .foregroundColor(AppTheme.textPrimary)

                // Subtitle
                Text("Fun maths puzzles for kids")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppTheme.textSecondary)
                    .opacity(subtitleOpacity)
            }
            .opacity(opacity)
        }
        .onAppear {
            startAnimations()
            initializeApp()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Fade in and scale up
        withAnimation(.easeOut(duration: 0.6)) {
            opacity = 1
            scale = 1
        }

        // Subtitle fade in (delayed)
        withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
            subtitleOpacity = 1
        }

        // Pulsing glow effect on bolt
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            boltGlow = 1.0
        }
    }

    // MARK: - Initialization

    private func initializeApp() {
        // Ensure guest session exists on first launch
        let storage = StorageService.shared
        _ = storage.ensureGuestSession()

        // Transition to hub after splash duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.3)) {
                appState.completeLoading()
            }
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AppState())
}
