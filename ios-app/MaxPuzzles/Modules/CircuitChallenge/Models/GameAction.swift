import Foundation

// MARK: - GameAction

/// All possible actions that can modify game state
/// Used by the GameViewModel reducer pattern
enum GameAction {
    // MARK: - Configuration

    /// Set difficulty settings for puzzle generation
    case setDifficulty(DifficultySettings)

    // MARK: - Puzzle Lifecycle

    /// Request puzzle generation to begin
    case generatePuzzle

    /// Puzzle was successfully generated
    case puzzleGenerated(Puzzle)

    /// Puzzle generation failed with error message
    case puzzleGenerationFailed(String)

    // MARK: - Gameplay

    /// Player attempts to move to a coordinate
    case makeMove(Coordinate)

    /// Start the game timer (first move)
    case startTimer

    /// Timer tick with elapsed milliseconds
    case tickTimer(Int)

    // MARK: - Reset/New

    /// Reset to the start of the same puzzle
    case resetPuzzle

    /// Request a completely new puzzle
    case newPuzzle

    // MARK: - Solution Viewing

    /// Show the solution path after game over
    case showSolution

    /// Hide the solution path
    case hideSolution

    // MARK: - Hidden Mode

    /// Reveal hidden mode results when reaching FINISH
    case revealHiddenResults

    // MARK: - Animations

    /// Clear a coin animation after it completes
    case clearCoinAnimation(UUID)

    /// Clear wrong move visual feedback
    case clearWrongMove
}
