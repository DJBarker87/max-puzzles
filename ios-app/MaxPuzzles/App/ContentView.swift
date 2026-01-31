import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService

    var body: some View {
        ZStack {
            // Solid background that renders immediately - prevents black screen on first layout
            AppTheme.backgroundDark
                .ignoresSafeArea()

            if appState.isLoading {
                SplashView()
            } else if appState.needsFirstRun {
                FirstRunView()
            } else {
                MainHubView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(MusicService.shared)
}
