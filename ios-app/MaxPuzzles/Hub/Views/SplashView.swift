import SwiftUI

/// Splash screen shown during app launch
struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8

    var body: some View {
        ZStack {
            AppTheme.splashBackground
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                // App icon placeholder
                ZStack {
                    // Hex shape placeholder
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 120))
                        .foregroundColor(AppTheme.accentPrimary.opacity(0.3))

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.connectorGlow)
                }
                .scaleEffect(scale)

                Text("Max's Puzzles")
                    .font(AppTypography.titleLarge)
                    .foregroundColor(AppTheme.textPrimary)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
                scale = 1
            }

            // Simulate loading, then transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    appState.isLoading = false
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AppState())
}
