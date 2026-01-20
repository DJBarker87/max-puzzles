import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService

    var body: some View {
        Group {
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
