import SwiftUI
import UIKit

@main
struct MaxPuzzlesApp: App {
    // Use AppDelegate for orientation control
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState: AppState
    private var musicService: MusicService { MusicService.shared }
    @Environment(\.scenePhase) var scenePhase

    private var isRunningUITests: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("-ui-testing-") }
        #else
        false
        #endif
    }

    init() {
        #if DEBUG
        // Apply deterministic UI-test storage before any singleton service can cache old values.
        let launchArguments = ProcessInfo.processInfo.arguments
        if launchArguments.contains("-ui-testing-reset"),
           let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
            // The storage singleton may already exist during repeated UI-test launches.
            // Reset its in-memory published values as well as the persistent domain.
            StorageService.shared.clearAllData()
            CometLearningStore.shared.resetAfterDataClear()
        }
        if launchArguments.contains("-ui-testing-skip-onboarding") {
            StorageService.shared.setPlayerName("Test Player")
            StorageService.shared.completeFirstRun()
            if launchArguments.contains("-ui-testing-reset") {
                CometLearningStore.shared.renameActiveProfile("Test Player")
            }
        }
        #endif

        _appState = StateObject(wrappedValue: AppState())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(MusicService.shared)
                .preferredColorScheme(.dark)
                .task {
                    guard !isRunningUITests else { return }
                    ICloudProgressSyncService.shared.start()
                }
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App returned to foreground
            appState.resumeSession()
            musicService.setSceneActive(true)
            musicService.resume()
            if !isRunningUITests {
                ICloudProgressSyncService.shared.refresh()
            }
        case .inactive:
            // App is about to go to background or user switched apps
            appState.pauseSession()
            musicService.setSceneActive(false)
        case .background:
            // App is in background - save state and pause music
            appState.saveState()
            musicService.setSceneActive(false)
            musicService.pause()
            LetterSpeechService.shared.stop()
            NumeralSpeechService.shared.stop()
            CustomPromptAudioService.shared.stopPlayback()
            SoundEffectsService.shared.suspend()
            CometLearningStore.shared.flushPendingAttemptPersistence()
            if !isRunningUITests {
                ICloudProgressSyncService.shared.flush()
            }
        @unknown default:
            break
        }
    }
}
