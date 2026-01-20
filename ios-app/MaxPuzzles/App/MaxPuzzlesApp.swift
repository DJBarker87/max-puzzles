import SwiftUI

@main
struct MaxPuzzlesApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            appState.resumeSession()
        case .inactive:
            appState.pauseSession()
        case .background:
            appState.saveState()
        @unknown default:
            break
        }
    }
}
