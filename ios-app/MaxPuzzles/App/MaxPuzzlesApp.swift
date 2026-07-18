import SwiftUI
import UIKit

@main
struct MaxPuzzlesApp: App {
    // Use AppDelegate for orientation control
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState: AppState
    @StateObject private var playTimer: ParentPlayTimer
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
            ParentPlayTimer.shared.resetAll()
        }
        if launchArguments.contains("-ui-testing-skip-onboarding") {
            StorageService.shared.setPlayerName("Test Player")
            StorageService.shared.completeFirstRun()
            if launchArguments.contains("-ui-testing-reset") {
                CometLearningStore.shared.renameActiveProfile("Test Player")
            }
        }
        if launchArguments.contains("-ui-testing-disable-voice") {
            StorageService.shared.setVoiceEnabled(false)
        }
        if launchArguments.contains("-ui-testing-expired-play-timer") {
            ParentPlayTimer.shared.setPasscodeForUITesting("2468")
            ParentPlayTimer.shared.expireForUITesting()
        }
        #endif

        _playTimer = StateObject(wrappedValue: ParentPlayTimer.shared)
        _appState = StateObject(wrappedValue: AppState())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(MusicService.shared)
                .environmentObject(playTimer)
                .preferredColorScheme(.dark)
                .onAppear {
                    playTimer.setMonitoringActive(true)
                    handlePlayTimerLockChange(playTimer.isLocked)
                }
                .onChange(of: playTimer.isLocked) { isLocked in
                    handlePlayTimerLockChange(isLocked)
                }
                .task {
                    // These services are not needed to draw or use the first frame.
                    await Task.yield()
                    playTimer.loadPasscodeAvailabilityAfterLaunch()
                    CometLearningStore.shared.preloadDetailedHistoriesAfterLaunch()
                    guard !isRunningUITests else { return }
                    do {
                        try await Task.sleep(nanoseconds: 150_000_000)
                    } catch {
                        return
                    }
                    guard !Task.isCancelled, scenePhase == .active else { return }
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
            playTimer.loadPasscodeAvailabilityAfterLaunch()
            playTimer.setMonitoringActive(true)
            musicService.setSceneActive(true)
            if playTimer.isLocked {
                handlePlayTimerLockChange(true)
            } else {
                appState.resumeSession()
                musicService.resume()
            }
            if !isRunningUITests {
                ICloudProgressSyncService.shared.refresh()
            }
        case .inactive:
            // App is about to go to background or user switched apps
            playTimer.setMonitoringActive(false)
            appState.pauseSession()
            musicService.setSceneActive(false)
        case .background:
            // App is in background - save state and pause music
            playTimer.setMonitoringActive(false)
            appState.saveState()
            musicService.setSceneActive(false)
            musicService.pause()
            LetterSpeechService.shared.stop(preservingPreparedAudio: false)
            NumeralSpeechService.shared.stop()
            PhonemeAudioService.shared.stop(preservingPreparedAudio: false)
            CustomPromptAudioService.shared.stopPlayback(preservingPreparedAudio: false)
            SoundEffectsService.shared.suspend()
            persistLearningHistoriesInBackground()
            if !isRunningUITests {
                ICloudProgressSyncService.shared.flush()
            }
        @unknown default:
            break
        }
    }

    private func handlePlayTimerLockChange(_ isLocked: Bool) {
        ParentPlayTimerOverlayCoordinator.shared.update(isLocked: isLocked)

        if isLocked {
            appState.pauseSession()
            musicService.pause()
            LetterSpeechService.shared.stop(preservingPreparedAudio: false)
            NumeralSpeechService.shared.stop()
            PhonemeAudioService.shared.stop(preservingPreparedAudio: false)
            CustomPromptAudioService.shared.stopPlayback(preservingPreparedAudio: false)
            SoundEffectsService.shared.suspend()
        } else if scenePhase == .active {
            appState.resumeSession()
            musicService.resume()
        }
    }

    private func persistLearningHistoriesInBackground() {
        var backgroundTask = UIBackgroundTaskIdentifier.invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask(
            withName: "Finish learning history"
        ) {
            guard backgroundTask != .invalid else { return }
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }

        Task { @MainActor in
            await CometLearningStore.shared.waitForPendingAttemptPersistence()
            guard backgroundTask != .invalid else { return }
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
