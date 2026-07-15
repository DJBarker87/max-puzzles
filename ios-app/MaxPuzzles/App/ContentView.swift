import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService

    var body: some View {
        ZStack {
            // Solid background that renders immediately - prevents black screen on first layout
            AppTheme.backgroundDark
                .ignoresSafeArea()

            #if DEBUG
            if let appStoreScreen {
                AppStoreScreenshotScene(screen: appStoreScreen)
            } else if appState.isLoading {
                SplashView()
            } else if appState.needsFirstRun {
                FirstRunView()
            } else {
                MainHubView()
            }
            #else
            if appState.isLoading {
                SplashView()
            } else if appState.needsFirstRun {
                FirstRunView()
            } else {
                MainHubView()
            }
            #endif
        }
    }

    #if DEBUG
    private var appStoreScreen: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-app-store-screen"),
              arguments.indices.contains(flagIndex + 1) else { return nil }
        return arguments[flagIndex + 1]
    }
    #endif
}

#if DEBUG
/// Deterministic navigation for pixel-perfect App Store captures. It exposes only real screens
/// and compiles out of the Release configuration.
private struct AppStoreScreenshotScene: View {
    let screen: String

    var body: some View {
        switch screen {
        case "hub":
            MainHubView()
        case "circuit":
            ModuleMenuView()
        case "writer-menu":
            CometWriterMenuView()
        case "quick-practice":
            NavigationStack { CometQuickPracticeView() }
        case "guided-c":
            NavigationStack {
                CometWriterGameView(startingGlyph: LetterLibrary.glyph(for: "c")!)
            }
        case "capital-a":
            NavigationStack {
                CometWriterGameView(startingGlyph: LetterLibrary.glyph(for: "A")!)
            }
        case "word-mission":
            NavigationStack {
                AdvancedWritingGameView(
                    mission: .wordWriting,
                    words: ["cat", "moon", "star"],
                    sessionLength: 3
                )
            }
        case "flight-school":
            NavigationStack { CometFlightSchoolView() }
        case "constellation":
            NavigationStack { CometConstellationView() }
        default:
            MainHubView()
        }
    }
}
#endif

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(MusicService.shared)
}
