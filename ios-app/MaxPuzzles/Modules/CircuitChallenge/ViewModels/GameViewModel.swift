import SwiftUI
import Combine
import UIKit

// MARK: - GameViewModel

/// Main view model for Circuit Challenge gameplay
/// Manages game state using a reducer pattern
@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var state: GameState

    // MARK: - Private

    private var timerCancellable: AnyCancellable?
    private var coinAnimationTimers: [UUID: AnyCancellable] = [:]
    private var wrongMoveTimer: AnyCancellable?

    // MARK: - Initialization

    init(difficulty: DifficultySettings) {
        self.state = GameState(difficulty: difficulty)
    }

    // MARK: - Public Actions

    /// Set new difficulty settings
    func setDifficulty(_ difficulty: DifficultySettings) {
        dispatch(.setDifficulty(difficulty))
    }

    /// Generate a new puzzle
    func generateNewPuzzle() {
        dispatch(.generatePuzzle)

        // Apply device-specific grid caps (iPhone caps at 6×7, iPad uses full size)
        let cappedDifficulty = state.difficulty.cappedForDevice()

        // Run puzzle generation with capped settings
        let result = PuzzleGenerator.generatePuzzle(difficulty: cappedDifficulty)

        switch result {
        case .success(let puzzle):
            dispatch(.puzzleGenerated(puzzle))
        case .failure(let error):
            dispatch(.puzzleGenerationFailed(error))
        }
    }

    /// Attempt to make a move to the specified coordinate
    func makeMove(to coord: Coordinate) {
        // Start timer on first move if not already running
        if state.status == .ready {
            dispatch(.startTimer)
            startTimer()
        }

        dispatch(.makeMove(coord))
    }

    /// Reset to the start of the same puzzle
    func resetPuzzle() {
        stopTimer()
        dispatch(.resetPuzzle)
    }

    /// Request a new puzzle (clears current puzzle)
    func requestNewPuzzle() {
        stopTimer()
        dispatch(.newPuzzle)
    }

    /// Show the solution path
    func showSolution() {
        dispatch(.showSolution)
    }

    /// Hide the solution path
    func hideSolution() {
        dispatch(.hideSolution)
    }

    /// Reveal hidden mode results
    func revealHiddenResults() {
        dispatch(.revealHiddenResults)
    }

    // MARK: - Timer Management

    private func startTimer() {
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                      let startTime = self.state.startTime else { return }
                let elapsed = Int(Date().timeIntervalSince(startTime) * 1000)
                self.dispatch(.tickTimer(elapsed))
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - Reducer

    private func dispatch(_ action: GameAction) {
        state = reduce(state: state, action: action)

        // Handle side effects
        handleSideEffects(for: action)
    }

    private func reduce(state: GameState, action: GameAction) -> GameState {
        var newState = state

        switch action {
        case .setDifficulty(let difficulty):
            newState.difficulty = difficulty
            newState.isHiddenMode = difficulty.hiddenMode
            if difficulty.hiddenMode {
                newState.hiddenModeResults = HiddenModeResults()
            } else {
                newState.hiddenModeResults = nil
            }

        case .generatePuzzle:
            newState.status = .setup
            newState.error = nil

        case .puzzleGenerated(let puzzle):
            newState.status = .ready
            newState.puzzle = puzzle
            newState.currentPosition = Coordinate(row: 0, col: 0)
            newState.visitedCells = [Coordinate(row: 0, col: 0)] // START is initially visited
            newState.traversedConnectors = []
            newState.moveHistory = []
            newState.wrongMoves = []
            newState.wrongConnectors = []
            newState.lives = newState.maxLives
            newState.startTime = nil
            newState.elapsedMs = 0
            newState.isTimerRunning = false
            newState.puzzleCoins = 0
            newState.coinAnimations = []
            newState.hiddenModeResults = newState.isHiddenMode ? HiddenModeResults() : nil
            newState.showingSolution = false
            newState.error = nil

        case .puzzleGenerationFailed(let error):
            newState.status = .setup
            newState.error = error

        case .startTimer:
            guard !newState.isTimerRunning else { break }
            newState.status = .playing
            newState.startTime = Date()
            newState.isTimerRunning = true

        case .tickTimer(let elapsed):
            guard newState.isTimerRunning else { break }
            newState.elapsedMs = elapsed

        case .makeMove(let targetCoord):
            newState = processMakeMove(state: newState, targetCoord: targetCoord)

        case .resetPuzzle:
            guard newState.puzzle != nil else { break }
            newState.status = .ready
            newState.currentPosition = Coordinate(row: 0, col: 0)
            newState.visitedCells = [Coordinate(row: 0, col: 0)]
            newState.traversedConnectors = []
            newState.moveHistory = []
            newState.wrongMoves = []
            newState.wrongConnectors = []
            newState.lives = newState.maxLives
            newState.startTime = nil
            newState.elapsedMs = 0
            newState.isTimerRunning = false
            newState.puzzleCoins = 0
            newState.coinAnimations = []
            newState.hiddenModeResults = newState.isHiddenMode ? HiddenModeResults() : nil
            newState.showingSolution = false

        case .newPuzzle:
            newState.status = .setup
            newState.puzzle = nil
            newState.error = nil

        case .showSolution:
            newState.showingSolution = true

        case .hideSolution:
            newState.showingSolution = false

        case .revealHiddenResults:
            guard let results = newState.hiddenModeResults else { break }
            let earnedCoins = results.correctCount * 10
            let penaltyCoins = results.mistakeCount * 30
            let finalCoins = max(0, earnedCoins - penaltyCoins)
            newState.status = .won
            newState.puzzleCoins = finalCoins

        case .clearCoinAnimation(let id):
            newState.coinAnimations.removeAll { $0.id == id }

        case .clearWrongMove:
            newState.wrongMoves = []
            newState.wrongConnectors = []
        }

        return newState
    }

    /// Process a move action - separated for complexity
    private func processMakeMove(state: GameState, targetCoord: Coordinate) -> GameState {
        var newState = state

        guard let puzzle = state.puzzle,
              state.status != .won && state.status != .lost else {
            return state
        }

        let fromCell = puzzle.grid[state.currentPosition.row][state.currentPosition.col]

        // Check if target is adjacent
        guard isAdjacent(from: state.currentPosition, to: targetCoord) else {
            return state // Invalid move, ignore
        }

        // Check if already visited
        guard !isAlreadyVisited(targetCoord, in: state.visitedCells) else {
            return state // Can't revisit
        }

        // Check move correctness
        let result = checkMoveCorrectness(
            fromCell: fromCell,
            toCell: targetCoord,
            connectors: puzzle.connectors
        )

        guard let connector = result.connector else {
            return state // No connector exists
        }

        let moveResult = GameMoveResult(
            correct: result.correct,
            fromCell: state.currentPosition,
            toCell: targetCoord,
            connectorValue: connector.value,
            cellAnswer: fromCell.answer ?? 0
        )

        // Check if reached FINISH
        let isFinish = isFinishCell(targetCoord, in: puzzle)

        // Haptic feedback
        triggerHaptics(correct: result.correct)

        // Handle based on mode
        if state.isHiddenMode {
            // Hidden mode: always accept move, track results
            var hiddenResults = state.hiddenModeResults ?? HiddenModeResults()
            hiddenResults.moves.append(moveResult)
            hiddenResults.correctCount += result.correct ? 1 : 0
            hiddenResults.mistakeCount += result.correct ? 0 : 1

            newState.currentPosition = targetCoord
            newState.visitedCells.append(targetCoord)
            newState.traversedConnectors.append(
                TraversedConnector(cellA: state.currentPosition, cellB: targetCoord)
            )
            newState.moveHistory.append(moveResult)
            newState.hiddenModeResults = hiddenResults

            if isFinish {
                newState.status = .revealing
            }
        } else {
            // Standard mode
            if result.correct {
                // Correct move
                let newPuzzleCoins = state.puzzleCoins + 10
                let coinAnim = CoinAnimation(value: 10, type: .earn, timestamp: Date())

                newState.currentPosition = targetCoord
                newState.visitedCells.append(targetCoord)
                newState.traversedConnectors.append(
                    TraversedConnector(cellA: state.currentPosition, cellB: targetCoord)
                )
                newState.moveHistory.append(moveResult)
                newState.puzzleCoins = newPuzzleCoins
                newState.coinAnimations.append(coinAnim)

                // Schedule animation cleanup
                scheduleCoinAnimationCleanup(id: coinAnim.id)

                if isFinish {
                    newState.status = .won
                    stopTimer()
                    triggerWinHaptics()
                }
            } else {
                // Wrong move
                let newLives = state.lives - 1
                let newPuzzleCoins = max(0, state.puzzleCoins - 30) // Clamp to 0
                let coinAnim = CoinAnimation(value: -30, type: .penalty, timestamp: Date())

                newState.lives = newLives
                newState.moveHistory.append(moveResult)
                newState.puzzleCoins = newPuzzleCoins
                newState.coinAnimations.append(coinAnim)

                // Add wrong move visuals
                newState.wrongMoves.append(targetCoord)
                newState.wrongConnectors.append(
                    TraversedConnector(cellA: state.currentPosition, cellB: targetCoord)
                )

                // Schedule animation cleanup
                scheduleCoinAnimationCleanup(id: coinAnim.id)
                scheduleWrongMoveCleanup()

                if newLives <= 0 {
                    newState.status = .lost
                    stopTimer()
                    triggerLoseHaptics()
                }
            }
        }

        return newState
    }

    // MARK: - Side Effects

    private func handleSideEffects(for action: GameAction) {
        switch action {
        case .puzzleGenerated, .resetPuzzle:
            // Ensure timer is stopped
            stopTimer()

        case .makeMove:
            // Check if game ended
            if state.status == .won || state.status == .lost || state.status == .revealing {
                stopTimer()
            }

        default:
            break
        }
    }

    private func scheduleCoinAnimationCleanup(id: UUID) {
        coinAnimationTimers[id] = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.dispatch(.clearCoinAnimation(id))
                self?.coinAnimationTimers.removeValue(forKey: id)
            }
    }

    private func scheduleWrongMoveCleanup() {
        wrongMoveTimer?.cancel()
        wrongMoveTimer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.dispatch(.clearWrongMove)
            }
    }

    // MARK: - Haptics

    private func triggerHaptics(correct: Bool) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(correct ? .success : .error)
    }

    private func triggerWinHaptics() {
        let generator = UINotificationFeedbackGenerator()
        // Triple success for win
        generator.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.notificationOccurred(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            generator.notificationOccurred(.success)
        }
    }

    private func triggerLoseHaptics() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}
