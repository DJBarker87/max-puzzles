import SwiftUI
import Combine

// MARK: - PuzzleMakerViewModel

/// View model for the Puzzle Maker screen
@MainActor
class PuzzleMakerViewModel: ObservableObject {

    // MARK: - Configuration State

    @Published var config = PrintConfig.default
    @Published var selectedPreset: Int = 3 // Default to Level 4
    @Published var isCustomMode: Bool = false

    // MARK: - Custom Settings

    @Published var additionEnabled: Bool = true
    @Published var subtractionEnabled: Bool = true
    @Published var multiplicationEnabled: Bool = false
    @Published var divisionEnabled: Bool = false
    @Published var addSubRange: Double = 20
    @Published var selectedTimesTables: Set<Int> = [2, 5, 10]
    @Published var gridRows: Int = 4
    @Published var gridCols: Int = 5

    // MARK: - Generation State

    @Published var puzzles: [PrintablePuzzle] = []
    @Published var isGenerating: Bool = false
    @Published var previewIndex: Int = 0
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    var currentPreset: DifficultySettings {
        DifficultyPresets.byLevel(selectedPreset + 1)
    }

    var hasValidOperations: Bool {
        if isCustomMode {
            let hasOperation = additionEnabled || subtractionEnabled ||
                multiplicationEnabled || divisionEnabled
            let tablesAreValid = !(multiplicationEnabled || divisionEnabled) ||
                !selectedTimesTables.isEmpty
            return hasOperation && tablesAreValid
        }
        return true
    }

    var finalDifficulty: DifficultySettings {
        if isCustomMode {
            return createCustomDifficulty()
        } else {
            return currentPreset
        }
    }

    var totalPages: Int {
        PrintRenderer.pageCount(
            puzzleCount: puzzles.count,
            puzzlesPerPage: config.puzzlesPerPage,
            includeAnswers: config.showAnswers
        )
    }

    var presetDescription: String {
        getPresetDescription(currentPreset)
    }

    var customDescription: String {
        getPresetDescription(finalDifficulty)
    }

    // MARK: - Actions

    func selectPreset(_ preset: Int) {
        selectedPreset = preset
        config.difficulty = preset
        clearPuzzles()
    }

    func toggleCustomMode() {
        isCustomMode.toggle()
        clearPuzzles()
    }

    func toggleOperation(_ op: String) {
        switch op {
        case "+": additionEnabled.toggle()
        case "−": subtractionEnabled.toggle()
        case "×": multiplicationEnabled.toggle()
        case "÷": divisionEnabled.toggle()
        default: break
        }
        clearPuzzles()
    }

    func isOperationEnabled(_ op: String) -> Bool {
        switch op {
        case "+": return additionEnabled
        case "−": return subtractionEnabled
        case "×": return multiplicationEnabled
        case "÷": return divisionEnabled
        default: return false
        }
    }

    func setTimesTables(_ tables: Set<Int>) {
        selectedTimesTables = Set(tables.filter { (1...12).contains($0) })
        clearPuzzles()
    }

    func setGridRows(_ rows: Int) {
        gridRows = rows
        clearPuzzles()
    }

    func setGridCols(_ cols: Int) {
        gridCols = cols
        clearPuzzles()
    }

    func setPuzzleCount(_ count: Int) {
        config.puzzleCount = count
        clearPuzzles()
    }

    func setShowAnswers(_ show: Bool) {
        config.showAnswers = show
    }

    func clearPuzzles() {
        puzzles = []
        previewIndex = 0
    }

    // MARK: - Generation

    func generatePuzzles() {
        guard hasValidOperations else { return }

        isGenerating = true
        errorMessage = nil

        // Run generation on background thread
        Task.detached { [self] in
            let difficulty = await self.finalDifficulty
            let puzzleConfig = await self.config

            let generatedPuzzles = PrintConverter.generatePrintablePuzzles(
                config: puzzleConfig,
                difficulty: difficulty
            )

            await MainActor.run {
                self.puzzles = generatedPuzzles
                self.previewIndex = 0
                self.isGenerating = false

                if generatedPuzzles.isEmpty {
                    self.errorMessage = "Failed to generate puzzles. Please try again."
                }
            }
        }
    }

    // MARK: - PDF Generation

    func generatePDF() -> Data? {
        guard !puzzles.isEmpty else { return nil }
        return PrintRenderer.generatePDF(puzzles: puzzles, config: config)
    }

    // MARK: - Navigation

    func previousPuzzle() {
        if previewIndex > 0 {
            previewIndex -= 1
        }
    }

    func nextPuzzle() {
        if previewIndex < puzzles.count - 1 {
            previewIndex += 1
        }
    }

    // MARK: - Private Helpers

    private func createCustomDifficulty() -> DifficultySettings {
        let rows = gridRows
        let cols = gridCols
        let usesTables = multiplicationEnabled || divisionEnabled
        let maximumTableProduct = (selectedTimesTables.max() ?? 1) * 12
        let hasAddSub = additionEnabled || subtractionEnabled

        return DifficultySettings(
            name: "Custom",
            additionEnabled: additionEnabled,
            subtractionEnabled: subtractionEnabled,
            multiplicationEnabled: multiplicationEnabled,
            divisionEnabled: divisionEnabled,
            addSubRange: Int(addSubRange),
            multDivRange: usesTables ? 12 : 0,
            selectedTimesTables: usesTables ? selectedTimesTables : nil,
            connectorMin: usesTables && !hasAddSub ? 1 : 5,
            connectorMax: max(Int(addSubRange), usesTables ? maximumTableProduct : Int(addSubRange)),
            gridRows: rows,
            gridCols: cols,
            minPathLength: DifficultyPresets.calculateMinPathLength(rows: rows, cols: cols),
            maxPathLength: DifficultyPresets.calculateMaxPathLength(rows: rows, cols: cols),
            weights: OperationWeights(
                addition: additionEnabled ? 30 : 0,
                subtraction: subtractionEnabled ? 30 : 0,
                multiplication: multiplicationEnabled ? 25 : 0,
                division: divisionEnabled ? 15 : 0
            ),
            hiddenMode: false,
            secondsPerStep: 7
        )
    }

    private func getPresetDescription(_ preset: DifficultySettings) -> String {
        var ops: [String] = []
        if preset.additionEnabled { ops.append("addition") }
        if preset.subtractionEnabled { ops.append("subtraction") }
        if preset.multiplicationEnabled { ops.append("multiplication") }
        if preset.divisionEnabled { ops.append("division") }

        let opsStr: String
        if ops.count == 1 {
            opsStr = ops[0]
        } else if ops.isEmpty {
            opsStr = "none"
        } else {
            opsStr = ops.dropLast().joined(separator: ", ") + " & " + (ops.last ?? "")
        }

        let tableDescription = preset.timesTables.isEmpty
            ? ""
            : ", tables \(preset.timesTables.sorted().map(String.init).joined(separator: ", "))"
        return "\(opsStr.capitalized), numbers up to \(preset.addSubRange)\(tableDescription), \(preset.gridRows)×\(preset.gridCols) grid"
    }
}
