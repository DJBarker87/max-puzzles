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
            if let dotPreviewIndex {
                DotToDotSinglePreview(index: dotPreviewIndex)
            } else if let dotReviewPage {
                DotToDotReviewSheet(page: dotReviewPage)
            } else if let appStoreScreen {
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

    private var dotReviewPage: Int? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-dot-review-page"),
              arguments.indices.contains(flagIndex + 1),
              let page = Int(arguments[flagIndex + 1]) else { return nil }
        return min(max(page, 0), 9)
    }

    private var dotPreviewIndex: Int? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-dot-preview-index"),
              arguments.indices.contains(flagIndex + 1),
              let index = Int(arguments[flagIndex + 1]) else { return nil }
        return min(max(index, 0), DotPuzzleCatalog.downloadedReferencePuzzles.count - 1)
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
        case "dot-menu":
            DotToDotMenuView()
        case "dot-game-tap":
            if let puzzle = DotPuzzleCatalog.puzzles(in: .numberExplorer).first {
                DotToDotPlayView(
                    puzzle: puzzle,
                    interactionMode: .tap,
                    initialProgress: 8
                )
            }
        case "dot-game-trace":
            if let puzzle = DotPuzzleCatalog.puzzles(in: .numberExplorer).first {
                DotToDotPlayView(
                    puzzle: puzzle,
                    interactionMode: .trace,
                    initialProgress: 8
                )
            }
        case "dot-paint":
            if let puzzle = DotPuzzleCatalog.all.first(where: { $0.id == "unicorn" }) {
                DotToDotPlayView(
                    puzzle: puzzle,
                    interactionMode: .tap,
                    initialProgress: puzzle.points.count,
                    showsCompletionInitially: true
                )
            }
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
