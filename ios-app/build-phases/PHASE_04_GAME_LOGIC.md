# Phase 4: Game Logic

**Objective:** Implement the complete game state management, move validation, timer system, coin tracking, and gameplay flow for Circuit Challenge.

**Dependencies:** Phase 2 (Puzzle Engine), Phase 3 (Grid Rendering)

---

## Subphase 4.1: Game State Types

**Goal:** Define all types for game state management including status, moves, coins, and hidden mode tracking.

### Prompt for Claude Code:

```
Create the game state types for Circuit Challenge iOS app in the CircuitChallenge module.

Create file: CircuitChallenge/Models/GameState.swift

Define the following types that mirror the web app's gameState.ts:

1. GameStatus enum:
```swift
/// Game status representing the current state of gameplay
enum GameStatus: Equatable {
    case setup      // Choosing difficulty
    case ready      // Puzzle generated, waiting for first move
    case playing    // Timer running, game in progress
    case won        // Reached FINISH
    case lost       // Out of lives (standard mode only)
    case revealing  // Hidden mode: showing results
}
```

2. GameMoveResult struct:
```swift
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
```

3. CoinAnimation struct:
```swift
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
```

4. HiddenModeResults struct:
```swift
/// Hidden mode results tracking
struct HiddenModeResults {
    /// All moves made
    var moves: [GameMoveResult] = []
    /// Number of correct moves
    var correctCount: Int = 0
    /// Number of incorrect moves
    var mistakeCount: Int = 0
}
```

5. TraversedConnector struct (for tracking path taken):
```swift
/// Represents a connector that has been traversed
struct TraversedConnector: Equatable {
    let cellA: Coordinate
    let cellB: Coordinate
}
```

6. Main GameState struct:
```swift
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
```

Include computed properties:
```swift
extension GameState {
    /// Whether the player can make moves
    var canMove: Bool {
        status == .ready || status == .playing
    }

    /// Whether the game has ended
    var isGameOver: Bool {
        status == .won || status == .lost
    }

    /// Time threshold for coins based on difficulty
    var timeThresholdMs: Int? {
        guard let puzzle = puzzle else { return nil }
        return puzzle.solution.steps * difficulty.secondsPerStep * 1000
    }
}
```

Unit tests:
- Test GameState initialization with different difficulties
- Test computed properties return correct values
- Test isHiddenMode sets up hiddenModeResults
```

---

## Subphase 4.2: Move Validation Utilities

**Goal:** Implement utility functions for checking adjacency, finding connectors, and validating moves.

### Prompt for Claude Code:

```
Create move validation utilities for the Circuit Challenge game in iOS.

Create file: CircuitChallenge/Engine/MoveValidator.swift

Implement the following functions that match the web app's gameReducer.ts:

1. Adjacency check (cells can move in 8 directions):
```swift
/// Check if two cells are adjacent (including diagonals)
/// Adjacent means at most 1 step in each direction, but not same cell
func isAdjacent(from: Coordinate, to: Coordinate) -> Bool {
    let rowDiff = abs(from.row - to.row)
    let colDiff = abs(from.col - to.col)
    return rowDiff <= 1 && colDiff <= 1 && (rowDiff > 0 || colDiff > 0)
}
```

2. Find connector between two cells:
```swift
/// Find the connector between two cells
func getConnectorBetweenCells(
    from: Coordinate,
    to: Coordinate,
    connectors: [Connector]
) -> Connector? {
    return connectors.first { c in
        (c.cellA == from && c.cellB == to) ||
        (c.cellB == from && c.cellA == to)
    }
}
```

3. Check move correctness:
```swift
/// Result of checking a move
struct MoveCheckResult {
    let correct: Bool
    let connector: Connector?
}

/// Check if a move is correct (follows the solution path)
/// A move is correct if the connector's value equals the fromCell's answer
func checkMoveCorrectness(
    fromCell: Cell,
    toCell: Coordinate,
    connectors: [Connector]
) -> MoveCheckResult {
    guard let connector = getConnectorBetweenCells(
        from: Coordinate(row: fromCell.row, col: fromCell.col),
        to: toCell,
        connectors: connectors
    ) else {
        return MoveCheckResult(correct: false, connector: nil)
    }

    // A move is correct if the connector's value equals the fromCell's answer
    // The fromCell's answer tells us which connector to take
    let correct = fromCell.answer == connector.value

    return MoveCheckResult(correct: correct, connector: connector)
}
```

4. Check if cell was already visited:
```swift
/// Check if a coordinate is in the visited cells list
func isAlreadyVisited(_ coord: Coordinate, in visitedCells: [Coordinate]) -> Bool {
    return visitedCells.contains { $0.row == coord.row && $0.col == coord.col }
}
```

5. Check if cell is the FINISH cell:
```swift
/// Check if a coordinate is the FINISH cell
func isFinishCell(_ coord: Coordinate, in puzzle: Puzzle) -> Bool {
    return coord.row == puzzle.grid.count - 1 &&
           coord.col == puzzle.grid[0].count - 1
}
```

Unit tests:
- Test isAdjacent with all 8 directions (horizontal, vertical, diagonal)
- Test isAdjacent returns false for same cell
- Test isAdjacent returns false for non-adjacent cells
- Test getConnectorBetweenCells finds connector in either direction
- Test getConnectorBetweenCells returns nil when no connector exists
- Test checkMoveCorrectness with matching answer (correct)
- Test checkMoveCorrectness with non-matching answer (incorrect)
- Test isAlreadyVisited with visited and unvisited cells
- Test isFinishCell at correct position
```

---

## Subphase 4.3: Game Actions Enum

**Goal:** Define all possible game actions as an enum for state management.

### Prompt for Claude Code:

```
Create the GameAction enum for Circuit Challenge iOS app.

Create file: CircuitChallenge/Models/GameAction.swift

Define all game actions matching the web app's reducer:

```swift
/// All possible actions that can modify game state
enum GameAction {
    // Configuration
    case setDifficulty(DifficultySettings)

    // Puzzle lifecycle
    case generatePuzzle
    case puzzleGenerated(Puzzle)
    case puzzleGenerationFailed(String)

    // Gameplay
    case makeMove(Coordinate)
    case startTimer
    case tickTimer(Int)  // elapsed milliseconds

    // Reset/New
    case resetPuzzle
    case newPuzzle

    // Solution viewing
    case showSolution
    case hideSolution

    // Hidden mode
    case revealHiddenResults

    // Animation cleanup
    case clearCoinAnimation(UUID)
}
```

This enum will be used by the GameViewModel to process state changes.
The view model will implement a reduce function that takes the current state and an action, returning a new state.
```

---

## Subphase 4.4: Game ViewModel

**Goal:** Implement the main game state manager as a SwiftUI ObservableObject.

### Prompt for Claude Code:

```
Create the main GameViewModel for Circuit Challenge iOS app.

Create file: CircuitChallenge/ViewModels/GameViewModel.swift

Implement an ObservableObject that manages game state:

```swift
import SwiftUI
import Combine

/// Main view model for Circuit Challenge gameplay
@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var state: GameState

    // MARK: - Private
    private var timerCancellable: AnyCancellable?
    private var coinAnimationTimers: [UUID: AnyCancellable] = [:]

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

        // Run puzzle generation
        let result = PuzzleGenerator.generatePuzzle(settings: state.difficulty)

        switch result {
        case .success(let puzzle):
            dispatch(.puzzleGenerated(puzzle))
        case .failure(let error):
            dispatch(.puzzleGenerationFailed(error.localizedDescription))
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
        timerCancellable = Timer.publish(every: 0.016, on: .main, in: .common)
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

                // Schedule animation cleanup
                scheduleCoinAnimationCleanup(id: coinAnim.id)

                if newLives <= 0 {
                    newState.status = .lost
                    stopTimer()
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
}
```

Unit tests:
- Test initialization with different difficulties
- Test generateNewPuzzle creates valid puzzle
- Test makeMove with correct move updates position and coins
- Test makeMove with wrong move decrements lives
- Test makeMove to FINISH triggers won status
- Test makeMove when out of lives triggers lost status
- Test resetPuzzle resets all state except puzzle
- Test timer starts on first move
- Test hidden mode tracks results without affecting lives
- Test revealHiddenResults calculates coins correctly
```

---

## Subphase 4.5: Feedback Manager

**Goal:** Implement visual feedback for wrong moves (screen shake) and sound placeholders.

### Prompt for Claude Code:

```
Create the FeedbackManager for Circuit Challenge iOS app.

Create file: CircuitChallenge/Services/FeedbackManager.swift

Implement feedback for wrong moves:

```swift
import SwiftUI
import Combine

/// Manages visual and audio feedback for game events
@MainActor
class FeedbackManager: ObservableObject {
    // MARK: - Published State
    @Published private(set) var isShaking: Bool = false

    // MARK: - Private
    private var shakeTimer: AnyCancellable?

    // MARK: - Screen Shake

    /// Trigger screen shake animation for wrong moves
    func triggerShake() {
        isShaking = true

        // Auto-reset after 300ms (matches web app)
        shakeTimer?.cancel()
        shakeTimer = Timer.publish(every: 0.3, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.isShaking = false
            }
    }

    /// View modifier offset for shake animation
    var shakeOffset: CGFloat {
        isShaking ? 8 : 0
    }

    // MARK: - Sound Effects (V1 Stretch Goal - Placeholder)

    /// Play correct move sound
    func playCorrect() {
        // TODO: Implement in V1 stretch goal
    }

    /// Play wrong move sound
    func playWrong() {
        // TODO: Implement in V1 stretch goal
    }

    /// Play win sound
    func playWin() {
        // TODO: Implement in V1 stretch goal
    }

    /// Play lose sound
    func playLose() {
        // TODO: Implement in V1 stretch goal
    }
}

// MARK: - Shake Effect Modifier

/// View modifier that applies shake effect
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

extension View {
    /// Apply shake animation
    func shake(isShaking: Bool) -> some View {
        self.modifier(ShakeEffect(animatableData: isShaking ? 1 : 0))
            .animation(.linear(duration: 0.3), value: isShaking)
    }
}
```

Unit tests:
- Test triggerShake sets isShaking to true
- Test isShaking resets to false after 300ms
- Test shakeOffset returns correct value based on state
```

---

## Subphase 4.6: Quick Play Setup Screen

**Goal:** Implement the difficulty selection screen for Quick Play mode.

### Prompt for Claude Code:

```
Create the QuickPlaySetupView for Circuit Challenge iOS app.

Create file: CircuitChallenge/Views/QuickPlaySetupView.swift

Implement the difficulty selection screen matching the web app:

```swift
import SwiftUI

struct QuickPlaySetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPreset: Int = 4 // Default to Level 5
    @State private var isCustomMode: Bool = false
    @State private var hiddenMode: Bool = false

    // Custom settings
    @State private var additionEnabled: Bool = true
    @State private var subtractionEnabled: Bool = true
    @State private var multiplicationEnabled: Bool = false
    @State private var divisionEnabled: Bool = false
    @State private var addSubRange: Int = 20
    @State private var multDivRange: Int = 5
    @State private var gridRows: Int = 4
    @State private var gridCols: Int = 5

    /// Callback when starting the game
    var onStart: (DifficultySettings) -> Void

    private var currentPreset: DifficultySettings {
        DifficultyPresets.presets[selectedPreset]
    }

    private var hasValidOperations: Bool {
        if isCustomMode {
            return additionEnabled || subtractionEnabled ||
                   multiplicationEnabled || divisionEnabled
        }
        return true
    }

    private var finalDifficulty: DifficultySettings {
        if isCustomMode {
            var settings = DifficultySettings.createCustom(
                additionEnabled: additionEnabled,
                subtractionEnabled: subtractionEnabled,
                multiplicationEnabled: multiplicationEnabled,
                divisionEnabled: divisionEnabled,
                addSubRange: addSubRange,
                multDivRange: multDivRange,
                gridRows: gridRows,
                gridCols: gridCols
            )
            settings.hiddenMode = hiddenMode
            return settings
        } else {
            var preset = currentPreset
            preset.hiddenMode = hiddenMode
            return preset
        }
    }

    var body: some View {
        ZStack {
            // Background
            StarryBackgroundView()

            ScrollView {
                VStack(spacing: 24) {
                    // Difficulty Selection Card
                    difficultySelectionCard

                    // Custom Settings Card
                    customSettingsCard

                    // Hidden Mode Card
                    hiddenModeCard

                    // Start Button
                    Button(action: { onStart(finalDifficulty) }) {
                        Text("Start Puzzle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                hasValidOperations
                                    ? Color.accentPrimary
                                    : Color.gray.opacity(0.5)
                            )
                            .cornerRadius(12)
                    }
                    .disabled(!hasValidOperations)
                }
                .padding()
            }
        }
        .navigationTitle("Quick Play")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Subviews

    private var difficultySelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Difficulty")
                .font(.headline)

            // Difficulty Picker
            Menu {
                ForEach(0..<DifficultyPresets.presets.count, id: \.self) { index in
                    Button(action: { selectedPreset = index }) {
                        Text("Level \(index + 1): \(DifficultyPresets.presets[index].name)")
                    }
                }
            } label: {
                HStack {
                    Text("Level \(selectedPreset + 1): \(currentPreset.name)")
                        .foregroundColor(isCustomMode ? .gray : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(isCustomMode ? .gray : .white)
                }
                .padding()
                .background(Color.backgroundDark)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(isCustomMode)

            // Description
            Text(getPresetDescription(currentPreset))
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private var customSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Customise Settings", isOn: $isCustomMode)
                .toggleStyle(SwitchToggleStyle(tint: .accentPrimary))

            if isCustomMode {
                VStack(spacing: 20) {
                    // Operations
                    operationsSection

                    // Add/Sub Range
                    VStack(alignment: .leading, spacing: 8) {
                        Text("+/− Number Range: \(addSubRange)")
                            .font(.subheadline)
                        Slider(value: Binding(
                            get: { Double(addSubRange) },
                            set: { addSubRange = Int($0) }
                        ), in: 5...100, step: 5)
                        .accentColor(.accentPrimary)
                    }

                    // Mult/Div Range (if enabled)
                    if multiplicationEnabled || divisionEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("×/÷ Number Range: \(multDivRange)")
                                .font(.subheadline)
                            Slider(value: Binding(
                                get: { Double(multDivRange) },
                                set: { multDivRange = Int($0) }
                            ), in: 2...12, step: 1)
                            .accentColor(.accentPrimary)
                        }
                    }

                    // Grid Size
                    gridSizeSection
                }
            }
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private var operationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Operations")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 16) {
                operationToggle("+", isOn: $additionEnabled)
                operationToggle("−", isOn: $subtractionEnabled)
                operationToggle("×", isOn: $multiplicationEnabled)
                operationToggle("÷", isOn: $divisionEnabled)
            }

            if !hasValidOperations {
                Text("At least one operation must be enabled")
                    .font(.caption)
                    .foregroundColor(.error)
            }
        }
    }

    private func operationToggle(_ symbol: String, isOn: Binding<Bool>) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            Text(symbol)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(isOn.wrappedValue ? Color.accentPrimary : Color.backgroundDark)
                .foregroundColor(.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var gridSizeSection: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Rows")
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    ForEach([3, 4, 5, 6, 7, 8], id: \.self) { n in
                        gridSizeButton(n, selected: gridRows == n) {
                            gridRows = n
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Columns")
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    ForEach([4, 5, 6, 7, 8], id: \.self) { n in
                        gridSizeButton(n, selected: gridCols == n) {
                            gridCols = n
                        }
                    }
                }
            }
        }
    }

    private func gridSizeButton(_ value: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(value)")
                .font(.subheadline)
                .frame(width: 32, height: 32)
                .background(selected ? Color.accentPrimary : Color.backgroundDark)
                .foregroundColor(.white)
                .cornerRadius(6)
        }
    }

    private var hiddenModeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Hidden Mode", isOn: $hiddenMode)
                .toggleStyle(SwitchToggleStyle(tint: .accentPrimary))

            Text("Mistakes aren't revealed until the end. No lives - always reach FINISH.")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func getPresetDescription(_ preset: DifficultySettings) -> String {
        var ops: [String] = []
        if preset.additionEnabled { ops.append("addition") }
        if preset.subtractionEnabled { ops.append("subtraction") }
        if preset.multiplicationEnabled { ops.append("multiplication") }
        if preset.divisionEnabled { ops.append("division") }

        let opsStr: String
        if ops.count == 1 {
            opsStr = ops[0]
        } else {
            opsStr = ops.dropLast().joined(separator: ", ") + " & " + (ops.last ?? "")
        }

        return "\(opsStr.capitalized), numbers up to \(preset.addSubRange), \(preset.gridRows)×\(preset.gridCols) grid"
    }
}
```

Preview:
```swift
#Preview {
    NavigationStack {
        QuickPlaySetupView { settings in
            print("Starting with: \(settings)")
        }
    }
}
```
```

---

## Subphase 4.7: Game Screen

**Goal:** Implement the main game screen that brings together the grid, status displays, and action buttons.

### Prompt for Claude Code:

```
Create the GameScreenView for Circuit Challenge iOS app.

Create file: CircuitChallenge/Views/GameScreenView.swift

Implement the main game screen matching the web app's GameScreen.tsx:

```swift
import SwiftUI

struct GameScreenView: View {
    @StateObject private var viewModel: GameViewModel
    @StateObject private var feedback = FeedbackManager()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showExitConfirm = false
    @State private var navigateToSummary = false
    @State private var summaryData: SummaryData?

    init(difficulty: DifficultySettings) {
        _viewModel = StateObject(wrappedValue: GameViewModel(difficulty: difficulty))
    }

    /// Check if in mobile landscape mode
    private var isMobileLandscape: Bool {
        // In a real app, use GeometryReader to detect orientation
        // For now, use horizontal size class as approximation
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            StarryBackgroundView()

            if isMobileLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }

            // Game Over Overlay
            if viewModel.state.isGameOver && !viewModel.state.showingSolution {
                gameOverOverlay
            }

            // Exit Confirmation
            if showExitConfirm {
                exitConfirmationOverlay
            }
        }
        .shake(isShaking: feedback.isShaking)
        .navigationBarHidden(true)
        .onAppear {
            if viewModel.state.puzzle == nil && viewModel.state.status == .setup {
                viewModel.generateNewPuzzle()
            }
        }
        .onChange(of: viewModel.state.moveHistory) { oldValue, newValue in
            // Watch for wrong moves and trigger shake
            if let lastMove = newValue.last,
               !lastMove.correct && !viewModel.state.isHiddenMode {
                feedback.triggerShake()
            }
        }
        .onChange(of: viewModel.state.status) { oldStatus, newStatus in
            handleStatusChange(from: oldStatus, to: newStatus)
        }
        .navigationDestination(isPresented: $navigateToSummary) {
            if let data = summaryData {
                SummaryScreenView(data: data, difficulty: viewModel.state.difficulty)
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // Header
            GameHeaderView(
                title: viewModel.state.isHiddenMode ? "Hidden Mode" : "Quick Play",
                lives: viewModel.state.lives,
                maxLives: viewModel.state.maxLives,
                elapsedMs: viewModel.state.elapsedMs,
                isTimerRunning: viewModel.state.isTimerRunning,
                timeThresholdMs: viewModel.state.isHiddenMode ? nil : viewModel.state.timeThresholdMs,
                coins: viewModel.state.puzzleCoins,
                coinChange: latestCoinAnimation,
                isHiddenMode: viewModel.state.isHiddenMode,
                onBackClick: { showExitConfirm = true }
            )

            // Puzzle Grid
            gridContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Action Buttons
            ActionButtonsView(
                onReset: { viewModel.resetPuzzle() },
                onNewPuzzle: handleNewPuzzle,
                onChangeDifficulty: { dismiss() },
                onPrint: handlePrint,
                onViewSolution: viewModel.state.status == .lost ? { viewModel.showSolution() } : nil,
                showViewSolution: viewModel.state.status == .lost && !viewModel.state.showingSolution,
                onContinue: handleContinueToSummary,
                showContinue: viewModel.state.showingSolution,
                disabled: viewModel.state.puzzle == nil
            )
        }
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            // Left Panel: Back + Actions
            VStack(spacing: 12) {
                Button(action: { showExitConfirm = true }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.backgroundDark.opacity(0.8))
                        .cornerRadius(8)
                }

                ActionButtonsView(
                    onReset: { viewModel.resetPuzzle() },
                    onNewPuzzle: handleNewPuzzle,
                    onChangeDifficulty: { dismiss() },
                    onPrint: handlePrint,
                    onViewSolution: viewModel.state.status == .lost ? { viewModel.showSolution() } : nil,
                    showViewSolution: viewModel.state.status == .lost && !viewModel.state.showingSolution,
                    onContinue: handleContinueToSummary,
                    showContinue: viewModel.state.showingSolution,
                    disabled: viewModel.state.puzzle == nil,
                    vertical: true
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color.backgroundDark.opacity(0.8))

            // Center: Grid
            gridContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Right Panel: Status
            VStack(spacing: 12) {
                if !viewModel.state.isHiddenMode {
                    LivesDisplayView(
                        lives: viewModel.state.lives,
                        maxLives: viewModel.state.maxLives,
                        vertical: true
                    )
                }

                TimerDisplayView(
                    elapsedMs: viewModel.state.elapsedMs,
                    thresholdMs: viewModel.state.isHiddenMode ? nil : viewModel.state.timeThresholdMs,
                    isRunning: viewModel.state.isTimerRunning
                )

                GameCoinDisplayView(
                    amount: viewModel.state.puzzleCoins,
                    showChange: viewModel.state.isHiddenMode ? nil : latestCoinAnimation
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color.backgroundDark.opacity(0.8))
        }
    }

    // MARK: - Grid Content

    @ViewBuilder
    private var gridContent: some View {
        if let puzzle = viewModel.state.puzzle {
            PuzzleGridView(
                puzzle: puzzle,
                currentPosition: viewModel.state.currentPosition,
                visitedCells: viewModel.state.visitedCells,
                traversedConnectors: viewModel.state.traversedConnectors,
                showSolution: viewModel.state.showingSolution,
                onCellTap: viewModel.state.canMove ? { coord in
                    viewModel.makeMove(to: coord)
                } : nil
            )
            .padding()
        } else if let error = viewModel.state.error {
            errorContent(error)
        } else {
            loadingContent
        }
    }

    private func errorContent(_ error: String) -> some View {
        VStack(spacing: 16) {
            Text("⚠️")
                .font(.system(size: 48))
            Text(error)
                .foregroundColor(.error)
            Button("Try Again") {
                handleNewPuzzle()
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentPrimary)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentPrimary)
            Text("Generating puzzle...")
                .foregroundColor(.textSecondary)
        }
    }

    // MARK: - Overlays

    private var gameOverOverlay: some View {
        Color.black.opacity(0.5)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    Text(viewModel.state.status == .won ? "🎉" : "💔")
                        .font(.system(size: 64))
                    Text(viewModel.state.status == .won ? "Puzzle Complete!" : "Out of Lives")
                        .font(.title.bold())
                }
            }
    }

    private var exitConfirmationOverlay: some View {
        Color.black.opacity(0.5)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 24) {
                    Text("Exit Puzzle?")
                        .font(.title2.bold())

                    Text("Your progress on this puzzle will be lost.")
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Button("Continue Playing") {
                            showExitConfirm = false
                        }
                        .buttonStyle(.bordered)

                        Button("Exit") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentSecondary)
                    }
                }
                .padding(32)
                .background(Color.backgroundMid)
                .cornerRadius(16)
                .padding(32)
            }
    }

    // MARK: - Helpers

    private var latestCoinAnimation: CoinAnimation? {
        viewModel.state.coinAnimations.first
    }

    private func handleNewPuzzle() {
        viewModel.requestNewPuzzle()
        viewModel.generateNewPuzzle()
    }

    private func handlePrint() {
        // TODO: Implement print functionality in Phase 8
    }

    private func handleContinueToSummary() {
        createSummaryData()
        navigateToSummary = true
    }

    private func handleStatusChange(from oldStatus: GameStatus, to newStatus: GameStatus) {
        // Navigate to summary when game ends (but not if viewing solution)
        if (newStatus == .won || newStatus == .lost) && !viewModel.state.showingSolution {
            // Small delay to show final state
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                createSummaryData()
                navigateToSummary = true
            }
        }

        // Handle hidden mode revealing
        if newStatus == .revealing && viewModel.state.isHiddenMode {
            createSummaryData()
            navigateToSummary = true
        }
    }

    private func createSummaryData() {
        summaryData = SummaryData(
            won: viewModel.state.status == .won,
            isHiddenMode: viewModel.state.isHiddenMode,
            elapsedMs: viewModel.state.elapsedMs,
            puzzleCoins: viewModel.state.puzzleCoins,
            moveHistory: viewModel.state.moveHistory,
            hiddenModeResults: viewModel.state.hiddenModeResults,
            puzzle: viewModel.state.puzzle
        )
    }
}
```

Unit tests:
- Test portrait layout renders correctly
- Test landscape layout renders correctly
- Test game over overlay appears when status is won/lost
- Test exit confirmation shows/hides correctly
- Test navigation to summary works
```

---

## Subphase 4.8: Summary Screen

**Goal:** Implement the end-of-game summary screen showing results.

### Prompt for Claude Code:

```
Create the SummaryScreenView for Circuit Challenge iOS app.

Create file: CircuitChallenge/Views/SummaryScreenView.swift

First, create the SummaryData model:

```swift
// In CircuitChallenge/Models/SummaryData.swift

/// Data passed to the summary screen
struct SummaryData {
    let won: Bool
    let isHiddenMode: Bool
    let elapsedMs: Int
    let puzzleCoins: Int
    let moveHistory: [GameMoveResult]
    let hiddenModeResults: HiddenModeResults?
    let puzzle: Puzzle?

    // Computed stats
    var totalMoves: Int { moveHistory.count }
    var correctMoves: Int { moveHistory.filter { $0.correct }.count }
    var mistakes: Int { totalMoves - correctMoves }
    var accuracy: Int {
        totalMoves > 0 ? Int(round(Double(correctMoves) / Double(totalMoves) * 100)) : 0
    }
}
```

Then create the summary screen:

```swift
import SwiftUI

struct SummaryScreenView: View {
    let data: SummaryData
    let difficulty: DifficultySettings

    @Environment(\.dismiss) private var dismiss

    /// Format milliseconds to MM:SS
    private func formatTime(_ ms: Int) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            StarryBackgroundView()

            ScrollView {
                if data.isHiddenMode && data.hiddenModeResults != nil {
                    hiddenModeContent
                } else if data.won {
                    winContent
                } else {
                    loseContent
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Hidden Mode Results

    private var hiddenModeContent: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            VStack(spacing: 16) {
                Text("Puzzle Complete!")
                    .font(.title.bold())

                Text("Results:")
                    .font(.headline)

                if let results = data.hiddenModeResults {
                    VStack(spacing: 12) {
                        resultRow(
                            icon: "✓",
                            iconColor: .accentPrimary,
                            label: "Correct:",
                            value: "\(results.correctCount)"
                        )
                        resultRow(
                            icon: "✗",
                            iconColor: .error,
                            label: "Mistakes:",
                            value: "\(results.mistakeCount)"
                        )
                        resultRow(
                            icon: nil,
                            iconColor: .white,
                            label: "Accuracy:",
                            value: "\(data.accuracy)%"
                        )
                        resultRow(
                            icon: nil,
                            iconColor: .white,
                            label: "Time:",
                            value: formatTime(data.elapsedMs)
                        )
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical, 8)

                    VStack(spacing: 4) {
                        HStack {
                            Text("Coins:")
                            Text("+\(data.puzzleCoins)")
                                .foregroundColor(.accentTertiary)
                                .fontWeight(.bold)
                        }
                        .font(.title3)

                        Text("(\(results.correctCount * 10) earned − \(results.mistakeCount * 30) penalty)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(24)
            .background(Color.backgroundMid.opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal)

            actionButtons

            Spacer(minLength: 40)
        }
    }

    // MARK: - Win Content

    private var winContent: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 64))

                Text("Puzzle Complete!")
                    .font(.largeTitle.bold())

                // Stars (V2 placeholder)
                Text("⭐ ⭐ ⭐")
                    .font(.system(size: 40))

                VStack(spacing: 8) {
                    Text("Time: **\(formatTime(data.elapsedMs))**")
                    HStack {
                        Text("Coins:")
                        Text("+\(data.puzzleCoins)")
                            .foregroundColor(.accentTertiary)
                            .fontWeight(.bold)
                    }
                    Text("Mistakes: **\(data.mistakes)**")
                }
                .font(.title3)
            }
            .padding(24)
            .background(Color.backgroundMid.opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal)

            actionButtons

            Spacer(minLength: 40)
        }
    }

    // MARK: - Lose Content

    private var loseContent: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            VStack(spacing: 16) {
                Text("💔")
                    .font(.system(size: 64))

                Text("Out of Lives")
                    .font(.title.bold())

                Text("You made \(data.correctMoves) correct moves before running out of lives.")
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)

                HStack {
                    Text("Coins:")
                    Text("+\(data.puzzleCoins)")
                        .foregroundColor(.accentTertiary)
                        .fontWeight(.bold)
                }
                .font(.title3)
            }
            .padding(24)
            .background(Color.backgroundMid.opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal)

            loseActionButtons

            Spacer(minLength: 40)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: GameScreenView(difficulty: difficulty)) {
                Text("Play Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentPrimary)
                    .cornerRadius(12)
            }

            Button("Change Difficulty") {
                // Pop back to setup
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.backgroundDark)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

            Button("Exit") {
                // Pop to module menu
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .padding(.horizontal)
    }

    private var loseActionButtons: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: GameScreenView(difficulty: difficulty)) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentPrimary)
                    .cornerRadius(12)
            }

            // See Solution button
            Button("See Solution") {
                // TODO: Navigate back to game with showSolution=true
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentSecondary)
            .cornerRadius(12)

            Button("Exit") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func resultRow(icon: String?, iconColor: Color, label: String, value: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                if let icon = icon {
                    Text(icon)
                        .foregroundColor(iconColor)
                }
                Text(label)
            }
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .font(.title2)
        }
        .padding(.horizontal)
    }
}

#Preview("Win") {
    NavigationStack {
        SummaryScreenView(
            data: SummaryData(
                won: true,
                isHiddenMode: false,
                elapsedMs: 45000,
                puzzleCoins: 80,
                moveHistory: [],
                hiddenModeResults: nil,
                puzzle: nil
            ),
            difficulty: DifficultyPresets.presets[4]
        )
    }
}

#Preview("Hidden Mode") {
    NavigationStack {
        SummaryScreenView(
            data: SummaryData(
                won: true,
                isHiddenMode: true,
                elapsedMs: 60000,
                puzzleCoins: 40,
                moveHistory: [],
                hiddenModeResults: HiddenModeResults(
                    moves: [],
                    correctCount: 7,
                    mistakeCount: 2
                ),
                puzzle: nil
            ),
            difficulty: DifficultyPresets.presets[4]
        )
    }
}

#Preview("Lost") {
    NavigationStack {
        SummaryScreenView(
            data: SummaryData(
                won: false,
                isHiddenMode: false,
                elapsedMs: 30000,
                puzzleCoins: 20,
                moveHistory: [],
                hiddenModeResults: nil,
                puzzle: nil
            ),
            difficulty: DifficultyPresets.presets[4]
        )
    }
}
```

Unit tests:
- Test hidden mode results display correctly
- Test win screen shows celebration
- Test lose screen shows correct message
- Test time formatting works correctly
- Test accuracy calculation is correct
```

---

## Subphase 4.9: Game Header View

**Goal:** Implement the header component showing lives, timer, and coins.

### Prompt for Claude Code:

```
Create the GameHeaderView for Circuit Challenge iOS app.

Create file: CircuitChallenge/Views/Components/GameHeaderView.swift

```swift
import SwiftUI

struct GameHeaderView: View {
    let title: String
    let lives: Int
    let maxLives: Int
    let elapsedMs: Int
    let isTimerRunning: Bool
    let timeThresholdMs: Int?
    let coins: Int
    let coinChange: CoinAnimation?
    let isHiddenMode: Bool
    let onBackClick: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Back button
            Button(action: onBackClick) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.backgroundDark.opacity(0.8))
                    .cornerRadius(12)
            }

            // Title
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Status displays
            HStack(spacing: 12) {
                // Lives (hidden in hidden mode)
                if !isHiddenMode {
                    LivesDisplayView(lives: lives, maxLives: maxLives)
                }

                // Timer
                TimerDisplayView(
                    elapsedMs: elapsedMs,
                    thresholdMs: isHiddenMode ? nil : timeThresholdMs,
                    isRunning: isTimerRunning
                )

                // Coins
                GameCoinDisplayView(
                    amount: coins,
                    showChange: isHiddenMode ? nil : coinChange
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.backgroundDark.opacity(0.9))
    }
}

#Preview {
    VStack {
        GameHeaderView(
            title: "Quick Play",
            lives: 3,
            maxLives: 5,
            elapsedMs: 45000,
            isTimerRunning: true,
            timeThresholdMs: 60000,
            coins: 50,
            coinChange: nil,
            isHiddenMode: false,
            onBackClick: {}
        )

        GameHeaderView(
            title: "Hidden Mode",
            lives: 5,
            maxLives: 5,
            elapsedMs: 30000,
            isTimerRunning: true,
            timeThresholdMs: nil,
            coins: 0,
            coinChange: nil,
            isHiddenMode: true,
            onBackClick: {}
        )
    }
    .background(Color.backgroundDark)
}
```
```

---

## Subphase 4.10: Coin Display with Animation

**Goal:** Implement the coin display with floating +/- animations.

### Prompt for Claude Code:

```
Create the GameCoinDisplayView for Circuit Challenge iOS app.

Create file: CircuitChallenge/Views/Components/GameCoinDisplayView.swift

```swift
import SwiftUI

struct GameCoinDisplayView: View {
    let amount: Int
    let showChange: CoinAnimation?
    var size: DisplaySize = .regular

    enum DisplaySize {
        case small, regular

        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .regular: return .subheadline
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .regular: return 20
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Main display
            HStack(spacing: 4) {
                // Coin icon
                Circle()
                    .fill(Color.accentTertiary)
                    .frame(width: size.iconSize, height: size.iconSize)
                    .overlay {
                        Text("$")
                            .font(.system(size: size.iconSize * 0.6, weight: .bold))
                            .foregroundColor(.black)
                    }

                Text("\(amount)")
                    .font(size.fontSize.monospacedDigit().bold())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.backgroundDark.opacity(0.8))
            .cornerRadius(20)

            // Floating animation
            if let change = showChange {
                CoinChangeAnimation(change: change, size: size)
                    .offset(y: -30)
            }
        }
    }
}

struct CoinChangeAnimation: View {
    let change: CoinAnimation
    let size: GameCoinDisplayView.DisplaySize

    @State private var opacity: Double = 1
    @State private var offset: CGFloat = 0

    private var isEarn: Bool {
        change.type == .earn
    }

    var body: some View {
        Text(isEarn ? "+\(change.value)" : "\(change.value)")
            .font(size.fontSize.bold())
            .foregroundColor(isEarn ? .accentPrimary : .error)
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    opacity = 0
                    offset = isEarn ? -20 : 20
                }
            }
    }
}

#Preview {
    VStack(spacing: 32) {
        GameCoinDisplayView(amount: 50, showChange: nil)

        GameCoinDisplayView(
            amount: 60,
            showChange: CoinAnimation(value: 10, type: .earn, timestamp: Date())
        )

        GameCoinDisplayView(
            amount: 20,
            showChange: CoinAnimation(value: -30, type: .penalty, timestamp: Date())
        )

        GameCoinDisplayView(amount: 30, showChange: nil, size: .small)
    }
    .padding()
    .background(Color.backgroundDark)
}
```
```

---

## Phase 4 Summary

After completing Phase 4, you will have:

1. **Game State Types** - Complete type definitions for game state management
2. **Move Validation** - Utilities for checking valid moves
3. **Game Actions** - Enum of all possible state changes
4. **Game ViewModel** - Main state manager with reducer pattern
5. **Feedback Manager** - Screen shake and sound placeholders
6. **Quick Play Setup** - Difficulty selection screen
7. **Game Screen** - Main gameplay screen with grid integration
8. **Summary Screen** - End-of-game results display
9. **Game Header** - Status bar with lives/timer/coins
10. **Coin Display** - Animated coin counter

**Next Phase:** Phase 5 will implement the hub screens (splash, module menu, settings).
