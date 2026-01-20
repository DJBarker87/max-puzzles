import Foundation

// MARK: - Game Status

/// Game status representing the current state of gameplay
enum GameStatus: Equatable {
    case setup      // Choosing difficulty
    case ready      // Puzzle generated, waiting for first move
    case playing    // Timer running, game in progress
    case won        // Reached FINISH
    case lost       // Out of lives (standard mode only)
    case revealing  // Hidden mode: showing results
}

// MARK: - Game Move Result

/// Result of a single move during gameplay
struct GameMoveResult: Identifiable {
    let id = UUID()
    /// Whether the move followed the solution path
    let correct: Bool
    /// Starting cell coordinate
    let fromCell: Coordinate
    /// Target cell coordinate
    let toCell: Coordinate
    /// Value on the connector taken
    let connectorValue: Int
    /// The answer value of the cell we moved from
    let cellAnswer: Int
}

// MARK: - Coin Animation

/// Coin animation for visual feedback
struct CoinAnimation: Identifiable {
    let id = UUID()
    /// Amount of coins (+10 or -30)
    let value: Int
    /// Type of change
    let type: CoinChangeType
    /// Timestamp when animation started
    let timestamp: Date

    enum CoinChangeType {
        case earn
        case penalty
    }
}

// MARK: - Hidden Mode Results

/// Hidden mode results tracking
struct HiddenModeResults {
    /// All moves made
    var moves: [GameMoveResult] = []
    /// Number of correct moves
    var correctCount: Int = 0
    /// Number of incorrect moves
    var mistakeCount: Int = 0
}

// MARK: - Game State

/// Complete game state
struct GameState {
    // Core state
    var status: GameStatus = .setup
    var puzzle: Puzzle? = nil
    var difficulty: DifficultySettings

    // Position tracking
    var currentPosition: Coordinate = Coordinate(row: 0, col: 0)
    var visitedCells: [Coordinate] = []
    var traversedConnectors: [TraversedConnector] = []
    var moveHistory: [GameMoveResult] = []

    // Wrong moves (for visual feedback)
    var wrongMoves: [Coordinate] = []
    var wrongConnectors: [TraversedConnector] = []

    // Lives (standard mode)
    var lives: Int = 5
    var maxLives: Int = 5

    // Timer
    var startTime: Date? = nil
    var elapsedMs: Int = 0
    var isTimerRunning: Bool = false

    // Coins (for this puzzle)
    var puzzleCoins: Int = 0
    var coinAnimations: [CoinAnimation] = []

    // Mode flags
    var isHiddenMode: Bool

    // Hidden mode tracking
    var hiddenModeResults: HiddenModeResults? = nil

    // For solution reveal
    var showingSolution: Bool = false

    // Error state
    var error: String? = nil

    init(difficulty: DifficultySettings) {
        self.difficulty = difficulty
        self.isHiddenMode = difficulty.hiddenMode
        if isHiddenMode {
            self.hiddenModeResults = HiddenModeResults()
        }
    }
}

// MARK: - Game State Extensions

extension GameState {
    /// Whether the player can make moves
    var canMove: Bool {
        status == .ready || status == .playing
    }

    /// Whether the game has ended
    var isGameOver: Bool {
        status == .won || status == .lost
    }

    /// Time threshold for coins based on difficulty (in milliseconds)
    var timeThresholdMs: Int? {
        guard let puzzle = puzzle else { return nil }
        return puzzle.solution.steps * difficulty.secondsPerStep * 1000
    }

    /// Elapsed time formatted as M:SS
    var formattedTime: String {
        let totalSeconds = elapsedMs / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
