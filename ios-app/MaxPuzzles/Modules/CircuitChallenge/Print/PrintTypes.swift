import Foundation

// MARK: - Print Configuration

/// Configuration for print output
struct PrintConfig {
    // Page layout
    var pageSize: PageSize = .a4
    var orientation: PageOrientation = .portrait
    var puzzlesPerPage: Int = 2

    // Puzzle settings
    var difficulty: Int = 3 // 0-9 index
    var showAnswers: Bool = false
    var showDifficulty: Bool = true
    var showPuzzleNumber: Bool = true

    // Styling
    var cellSize: CGFloat = 12 // mm
    var lineWidth: CGFloat = 0.5 // mm
    var fontSize: CGFloat = 10 // pt

    // Header/Footer
    var title: String = "Circuit Challenge"
    var subtitle: String = ""
    var showDate: Bool = true
    var showPageNumbers: Bool = true

    // Batch settings
    var puzzleCount: Int = 10
    var uniquePuzzles: Bool = true
}

// MARK: - Page Size

enum PageSize: String, CaseIterable {
    case a4 = "A4"
    case letter = "Letter"

    var width: CGFloat {
        switch self {
        case .a4: return 210
        case .letter: return 216
        }
    }

    var height: CGFloat {
        switch self {
        case .a4: return 297
        case .letter: return 279
        }
    }
}

// MARK: - Page Orientation

enum PageOrientation: String {
    case portrait
    case landscape
}

// MARK: - Page Layout

struct PageLayout {
    let width: CGFloat
    let height: CGFloat
    let marginTop: CGFloat
    let marginBottom: CGFloat
    let marginLeft: CGFloat
    let marginRight: CGFloat
    let contentWidth: CGFloat
    let contentHeight: CGFloat
    let puzzleAreaHeight: CGFloat
    let gapBetweenPuzzles: CGFloat

    static let a4Portrait = PageLayout(
        width: 210,
        height: 297,
        marginTop: 15,
        marginBottom: 15,
        marginLeft: 15,
        marginRight: 15,
        contentWidth: 180,
        contentHeight: 267,
        puzzleAreaHeight: 125,
        gapBetweenPuzzles: 10
    )

    static let letterPortrait = PageLayout(
        width: 216,
        height: 279,
        marginTop: 15,
        marginBottom: 15,
        marginLeft: 15,
        marginRight: 15,
        contentWidth: 186,
        contentHeight: 249,
        puzzleAreaHeight: 115,
        gapBetweenPuzzles: 10
    )

    static func forConfig(_ config: PrintConfig) -> PageLayout {
        switch config.pageSize {
        case .a4: return .a4Portrait
        case .letter: return .letterPortrait
        }
    }
}

// MARK: - Printable Puzzle

/// A puzzle prepared for printing
struct PrintablePuzzle: Identifiable {
    let id: String
    let puzzleNumber: Int
    let difficulty: Int
    let difficultyName: String

    // Grid data
    let gridRows: Int
    let gridCols: Int
    let cells: [PrintableCell]

    // Connectors between cells
    let connectors: [PrintableConnector]

    // Solution
    let targetSum: Int
    let solution: [Int] // Cell indices in solution path
}

// MARK: - Printable Cell

/// Cell data for print rendering
struct PrintableCell: Identifiable {
    var id: Int { index }
    let index: Int
    let row: Int
    let col: Int
    let expression: String
    let answer: Int?
    let isStart: Bool
    let isEnd: Bool
    var inSolution: Bool
}

// MARK: - Printable Connector

/// Connector data for print rendering
struct PrintableConnector: Identifiable {
    var id: String { "\(fromRow),\(fromCol)-\(toRow),\(toCol)" }
    let fromRow: Int
    let fromCol: Int
    let toRow: Int
    let toCol: Int
    let value: Int
    var inSolution: Bool
}

// MARK: - Default Config

extension PrintConfig {
    static let `default` = PrintConfig()
}

// MARK: - Difficulty Names

enum DifficultyNames {
    static let names: [Int: String] = [
        0: "Tiny Tot",
        1: "Beginner",
        2: "Easy",
        3: "Getting There",
        4: "Times Tables",
        5: "Confident",
        6: "Adventurous",
        7: "Division Intro",
        8: "Challenge",
        9: "Expert"
    ]

    static func name(for index: Int) -> String {
        names[index] ?? "Level \(index + 1)"
    }
}
