# Phase 8: Print & Polish

**Objective:** Implement puzzle printing functionality, app polish, accessibility, and final optimizations.

**Dependencies:** All previous phases

---

## Subphase 8.1: Print Template

**Goal:** Create a print-ready view for puzzles that can be exported to PDF.

### Prompt for Claude Code:

```
Create the PrintTemplateView for Circuit Challenge iOS app.

Create file: CircuitChallenge/Views/Print/PrintTemplateView.swift

This view renders a puzzle in a print-friendly format (black and white, no animations):

```swift
import SwiftUI

struct PrintTemplateView: View {
    let puzzle: Puzzle
    let showSolution: Bool
    let puzzleNumber: Int

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Circuit Challenge")
                    .font(.system(size: 14, weight: .bold))

                Spacer()

                Text("Puzzle #\(puzzleNumber)")
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Grid
            PrintPuzzleGridView(puzzle: puzzle, showSolution: showSolution)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()

            // Footer with difficulty info
            HStack {
                Text("Difficulty: Level \(puzzle.difficulty)")
                    .font(.system(size: 10))

                Spacer()

                Text("Max's Puzzles")
                    .font(.system(size: 10))
            }
            .foregroundColor(.gray)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color.white)
    }
}

/// Print-friendly puzzle grid (black and white)
struct PrintPuzzleGridView: View {
    let puzzle: Puzzle
    let showSolution: Bool

    var body: some View {
        GeometryReader { geometry in
            let cellSize = calculateCellSize(
                availableWidth: geometry.size.width,
                availableHeight: geometry.size.height,
                cols: puzzle.grid[0].count,
                rows: puzzle.grid.count
            )

            ZStack {
                // Connectors (draw first, behind cells)
                ForEach(puzzle.connectors, id: \.id) { connector in
                    PrintConnectorView(
                        connector: connector,
                        cellSize: cellSize,
                        isOnPath: showSolution && isConnectorOnPath(connector)
                    )
                }

                // Cells
                ForEach(0..<puzzle.grid.count, id: \.self) { row in
                    ForEach(0..<puzzle.grid[row].count, id: \.self) { col in
                        let cell = puzzle.grid[row][col]
                        PrintCellView(
                            cell: cell,
                            isOnPath: showSolution && isCellOnPath(row: row, col: col)
                        )
                        .frame(width: cellSize, height: cellSize)
                        .position(
                            x: CGFloat(col) * cellSize * 0.85 + cellSize / 2,
                            y: CGFloat(row) * cellSize * 0.8 + cellSize / 2
                        )
                    }
                }
            }
        }
    }

    private func calculateCellSize(
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        cols: Int,
        rows: Int
    ) -> CGFloat {
        let horizontalSize = availableWidth / (CGFloat(cols) * 0.85 + 0.15)
        let verticalSize = availableHeight / (CGFloat(rows) * 0.8 + 0.2)
        return min(horizontalSize, verticalSize, 80) // Cap at 80pt
    }

    private func isConnectorOnPath(_ connector: Connector) -> Bool {
        let path = puzzle.solution.path
        for i in 0..<path.count - 1 {
            let a = path[i]
            let b = path[i + 1]
            if (connector.cellA == a && connector.cellB == b) ||
               (connector.cellA == b && connector.cellB == a) {
                return true
            }
        }
        return false
    }

    private func isCellOnPath(row: Int, col: Int) -> Bool {
        puzzle.solution.path.contains { $0.row == row && $0.col == col }
    }
}

/// Print-friendly cell (hexagon outline)
struct PrintCellView: View {
    let cell: Cell
    let isOnPath: Bool

    var body: some View {
        ZStack {
            // Hexagon outline
            HexagonShape()
                .stroke(Color.black, lineWidth: isOnPath ? 3 : 1)
                .fill(isOnPath ? Color.gray.opacity(0.2) : Color.white)

            // Cell content
            VStack(spacing: 2) {
                if cell.isStart {
                    Text("START")
                        .font(.system(size: 8, weight: .bold))
                } else if cell.isFinish {
                    Text("FINISH")
                        .font(.system(size: 8, weight: .bold))
                } else {
                    Text(cell.expression)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundColor(.black)
        }
    }
}

/// Print-friendly connector
struct PrintConnectorView: View {
    let connector: Connector
    let cellSize: CGFloat
    let isOnPath: Bool

    var body: some View {
        // Calculate positions
        let startPos = cellPosition(connector.cellA)
        let endPos = cellPosition(connector.cellB)

        ZStack {
            // Line
            Path { path in
                path.move(to: startPos)
                path.addLine(to: endPos)
            }
            .stroke(Color.black, lineWidth: isOnPath ? 3 : 1)

            // Value label
            let midPoint = CGPoint(
                x: (startPos.x + endPos.x) / 2,
                y: (startPos.y + endPos.y) / 2
            )

            Text("\(connector.value)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.black)
                .padding(4)
                .background(Color.white)
                .clipShape(Circle())
                .position(midPoint)
        }
    }

    private func cellPosition(_ coord: Coordinate) -> CGPoint {
        CGPoint(
            x: CGFloat(coord.col) * cellSize * 0.85 + cellSize / 2,
            y: CGFloat(coord.row) * cellSize * 0.8 + cellSize / 2
        )
    }
}

#Preview {
    PrintTemplateView(
        puzzle: Puzzle.preview,
        showSolution: false,
        puzzleNumber: 1
    )
    .frame(width: 400, height: 500)
}
```
```

---

## Subphase 8.2: PDF Generation Service

**Goal:** Create a service to generate PDFs from puzzles.

### Prompt for Claude Code:

```
Create the PDFGenerationService for Circuit Challenge iOS app.

Create file: CircuitChallenge/Services/PDFGenerationService.swift

```swift
import SwiftUI
import PDFKit

/// Service for generating PDF documents from puzzles
class PDFGenerationService {
    static let shared = PDFGenerationService()

    private init() {}

    /// A4 page dimensions in points (72 points per inch)
    private let pageWidth: CGFloat = 595.28  // 210mm
    private let pageHeight: CGFloat = 841.89 // 297mm

    /// Generate PDF with puzzles (2 per page)
    func generatePDF(
        puzzles: [Puzzle],
        showSolutions: Bool = false
    ) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )

        let data = pdfRenderer.pdfData { context in
            // Process puzzles in pairs (2 per page)
            for pageIndex in stride(from: 0, to: puzzles.count, by: 2) {
                context.beginPage()

                // Top puzzle
                let topPuzzle = puzzles[pageIndex]
                renderPuzzle(
                    context: context.cgContext,
                    puzzle: topPuzzle,
                    showSolution: showSolutions,
                    puzzleNumber: pageIndex + 1,
                    rect: CGRect(x: 20, y: 20, width: pageWidth - 40, height: (pageHeight - 60) / 2)
                )

                // Bottom puzzle (if exists)
                if pageIndex + 1 < puzzles.count {
                    let bottomPuzzle = puzzles[pageIndex + 1]
                    renderPuzzle(
                        context: context.cgContext,
                        puzzle: bottomPuzzle,
                        showSolution: showSolutions,
                        puzzleNumber: pageIndex + 2,
                        rect: CGRect(x: 20, y: (pageHeight / 2) + 10, width: pageWidth - 40, height: (pageHeight - 60) / 2)
                    )
                }
            }
        }

        return data
    }

    /// Generate PDF for a single puzzle (full page)
    func generateSinglePuzzlePDF(
        puzzle: Puzzle,
        showSolution: Bool = false
    ) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )

        let data = pdfRenderer.pdfData { context in
            context.beginPage()

            renderPuzzle(
                context: context.cgContext,
                puzzle: puzzle,
                showSolution: showSolution,
                puzzleNumber: 1,
                rect: CGRect(x: 40, y: 40, width: pageWidth - 80, height: pageHeight - 80)
            )
        }

        return data
    }

    /// Render a single puzzle to the given context
    private func renderPuzzle(
        context: CGContext,
        puzzle: Puzzle,
        showSolution: Bool,
        puzzleNumber: Int,
        rect: CGRect
    ) {
        // Create SwiftUI view
        let view = PrintTemplateView(
            puzzle: puzzle,
            showSolution: showSolution,
            puzzleNumber: puzzleNumber
        )
        .frame(width: rect.width, height: rect.height)

        // Render to image
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // Higher quality

        guard let image = renderer.cgImage else { return }

        // Draw to PDF context
        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.minY + rect.height)
        context.scaleBy(x: 1, y: -1) // Flip coordinate system
        context.draw(image, in: CGRect(origin: .zero, size: rect.size))
        context.restoreGState()
    }

    /// Share/print the generated PDF
    func sharePDF(data: Data, from viewController: UIViewController) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("puzzles.pdf")

        do {
            try data.write(to: tempURL)

            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )

            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(
                    x: viewController.view.bounds.midX,
                    y: viewController.view.bounds.midY,
                    width: 0, height: 0
                )
            }

            viewController.present(activityVC, animated: true)
        } catch {
            print("Error sharing PDF: \(error)")
        }
    }
}
```
```

---

## Subphase 8.3: Print Current Puzzle

**Goal:** Add ability to print the current puzzle from the game screen.

### Prompt for Claude Code:

```
Update the GameScreenView to support printing the current puzzle.

Add print functionality to CircuitChallenge/Views/GameScreenView.swift:

```swift
// Add to GameScreenView

@State private var showingPrintSheet = false

// In the handlePrint function:
private func handlePrint() {
    guard let puzzle = viewModel.state.puzzle else { return }

    let pdfService = PDFGenerationService.shared

    if let pdfData = pdfService.generateSinglePuzzlePDF(
        puzzle: puzzle,
        showSolution: viewModel.state.showingSolution
    ) {
        // Get the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            pdfService.sharePDF(data: pdfData, from: rootVC)
        }
    }
}
```

Also create a helper extension for accessing the root view controller:

Create file: Shared/Extensions/UIApplication+Extensions.swift

```swift
import UIKit

extension UIApplication {
    /// Get the key window's root view controller
    var rootViewController: UIViewController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}
```
```

---

## Subphase 8.4: Puzzle Maker Implementation

**Goal:** Complete the Puzzle Maker screen with batch PDF generation.

### Prompt for Claude Code:

```
Complete the PuzzleMakerView with full puzzle generation and PDF export.

Update CircuitChallenge/Views/PuzzleMakerView.swift:

```swift
import SwiftUI

struct PuzzleMakerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDifficulty: Int = 4
    @State private var puzzleCount: Int = 4
    @State private var includeSolutions: Bool = true
    @State private var isGenerating = false
    @State private var error: String?
    @State private var generatedPuzzles: [Puzzle] = []

    private let pdfService = PDFGenerationService.shared

    var body: some View {
        ZStack {
            StarryBackgroundView()

            VStack(spacing: 0) {
                HubHeader(title: "Puzzle Maker", showBack: true)

                ScrollView {
                    VStack(spacing: 24) {
                        // Info card
                        infoCard

                        // Difficulty selector
                        difficultyCard

                        // Puzzle count selector
                        countCard

                        // Options
                        optionsCard

                        // Generate button
                        generateButton

                        // Preview (if puzzles generated)
                        if !generatedPuzzles.isEmpty {
                            previewCard
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Cards

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🖨️")
                    .font(.title)
                Text("Print puzzles for classroom use!")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Text("Generate up to 10 puzzles at once. Each A4 page fits 2 puzzles. Solutions can be included on separate pages.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private var difficultyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty")
                .font(.headline)
                .foregroundColor(.white)

            Menu {
                ForEach(0..<10, id: \.self) { index in
                    Button("Level \(index + 1): \(DifficultyPresets.presets[index].name)") {
                        selectedDifficulty = index
                    }
                }
            } label: {
                HStack {
                    Text("Level \(selectedDifficulty + 1): \(DifficultyPresets.presets[selectedDifficulty].name)")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.backgroundDark)
                .cornerRadius(8)
            }

            Text(getDifficultyDescription())
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private var countCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Number of Puzzles")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 8) {
                ForEach([2, 4, 6, 8, 10], id: \.self) { count in
                    Button(action: { puzzleCount = count }) {
                        Text("\(count)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 44)
                            .background(
                                puzzleCount == count
                                    ? Color.accentPrimary
                                    : Color.backgroundDark
                            )
                            .cornerRadius(8)
                    }
                }
            }

            Text("= \(puzzleCount / 2) page\(puzzleCount > 2 ? "s" : "") of puzzles\(includeSolutions ? " + \(puzzleCount / 2) page\(puzzleCount > 2 ? "s" : "") of solutions" : "")")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)
                .foregroundColor(.white)

            Toggle("Include solution pages", isOn: $includeSolutions)
                .toggleStyle(SwitchToggleStyle(tint: .accentPrimary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private var generateButton: some View {
        Button(action: generateAndShare) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                    Text("Generating...")
                } else {
                    Image(systemName: "printer")
                    Text("Generate & Print")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isGenerating ? Color.gray : Color.accentPrimary)
            .cornerRadius(12)
        }
        .disabled(isGenerating)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(.white)

            Text("\(generatedPuzzles.count) puzzles ready")
                .foregroundColor(.textSecondary)

            Button(action: sharePDF) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share PDF")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentSecondary)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func generateAndShare() {
        isGenerating = true
        error = nil
        generatedPuzzles = []

        Task {
            // Generate puzzles
            var puzzles: [Puzzle] = []
            let settings = DifficultyPresets.presets[selectedDifficulty]

            for _ in 0..<puzzleCount {
                let result = PuzzleGenerator.generatePuzzle(settings: settings)
                switch result {
                case .success(let puzzle):
                    puzzles.append(puzzle)
                case .failure(let err):
                    await MainActor.run {
                        error = err.localizedDescription
                        isGenerating = false
                    }
                    return
                }
            }

            await MainActor.run {
                generatedPuzzles = puzzles
                isGenerating = false
                sharePDF()
            }
        }
    }

    private func sharePDF() {
        guard !generatedPuzzles.isEmpty else { return }

        // Generate puzzle pages
        guard var pdfData = pdfService.generatePDF(
            puzzles: generatedPuzzles,
            showSolutions: false
        ) else {
            error = "Failed to generate PDF"
            return
        }

        // Add solution pages if requested
        if includeSolutions {
            if let solutionData = pdfService.generatePDF(
                puzzles: generatedPuzzles,
                showSolutions: true
            ) {
                // Merge PDFs
                if let merged = mergePDFs([pdfData, solutionData]) {
                    pdfData = merged
                }
            }
        }

        // Share
        if let rootVC = UIApplication.shared.rootViewController {
            pdfService.sharePDF(data: pdfData, from: rootVC)
        }
    }

    private func mergePDFs(_ pdfs: [Data]) -> Data? {
        let document = PDFDocument()

        for pdfData in pdfs {
            guard let pdf = PDFDocument(data: pdfData) else { continue }
            for i in 0..<pdf.pageCount {
                if let page = pdf.page(at: i) {
                    document.insert(page, at: document.pageCount)
                }
            }
        }

        return document.dataRepresentation()
    }

    private func getDifficultyDescription() -> String {
        let settings = DifficultyPresets.presets[selectedDifficulty]
        var ops: [String] = []
        if settings.additionEnabled { ops.append("+") }
        if settings.subtractionEnabled { ops.append("−") }
        if settings.multiplicationEnabled { ops.append("×") }
        if settings.divisionEnabled { ops.append("÷") }
        return "\(ops.joined(separator: " ")) | Numbers up to \(settings.addSubRange) | \(settings.gridRows)×\(settings.gridCols) grid"
    }
}

import PDFKit
```
```

---

## Subphase 8.5: Accessibility

**Goal:** Add accessibility labels and VoiceOver support.

### Prompt for Claude Code:

```
Add accessibility support throughout the app.

Create file: Shared/Extensions/Accessibility+Extensions.swift

```swift
import SwiftUI

// MARK: - Accessibility Labels

extension View {
    /// Add accessibility for a puzzle cell
    func puzzleCellAccessibility(
        cell: Cell,
        isCurrentPosition: Bool,
        isVisited: Bool
    ) -> some View {
        self
            .accessibilityLabel(cellAccessibilityLabel(
                cell: cell,
                isCurrentPosition: isCurrentPosition,
                isVisited: isVisited
            ))
            .accessibilityHint(isCurrentPosition ? "Current position" : "Tap to move here")
            .accessibilityAddTraits(isCurrentPosition ? .isSelected : [])
    }

    /// Add accessibility for a connector
    func connectorAccessibility(connector: Connector, isTraversed: Bool) -> some View {
        self
            .accessibilityLabel("Path with value \(connector.value)")
            .accessibilityHint(isTraversed ? "Already traveled" : "Available path")
    }
}

private func cellAccessibilityLabel(
    cell: Cell,
    isCurrentPosition: Bool,
    isVisited: Bool
) -> String {
    var label = ""

    if cell.isStart {
        label = "Start cell"
    } else if cell.isFinish {
        label = "Finish cell"
    } else {
        label = "Cell with expression \(cell.expression)"
        if let answer = cell.answer {
            label += ", answer is \(answer)"
        }
    }

    if isCurrentPosition {
        label += ", current position"
    } else if isVisited {
        label += ", already visited"
    }

    return label
}

// MARK: - Dynamic Type Support

extension Font {
    /// Scaled font that respects dynamic type
    static func scaledBody() -> Font {
        .body.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    static func scaledHeadline() -> Font {
        .headline.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    static func scaledTitle() -> Font {
        .title.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

// MARK: - Reduce Motion Support

extension View {
    /// Apply animation only if reduce motion is not enabled
    @ViewBuilder
    func animationIfAllowed<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self
        } else {
            self.animation(animation, value: value)
        }
    }
}
```

Update HexCellView to include accessibility:

```swift
// In HexCellView.swift, add to the main view:
.puzzleCellAccessibility(
    cell: cell,
    isCurrentPosition: state == .current,
    isVisited: state == .visited
)
```

Update buttons and interactive elements throughout the app with:
- `accessibilityLabel()` for all buttons
- `accessibilityHint()` for non-obvious actions
- `accessibilityValue()` for stateful elements (toggles, sliders)
```

---

## Subphase 8.6: Error Handling & Loading States

**Goal:** Implement consistent error handling and loading states.

### Prompt for Claude Code:

```
Create consistent error handling and loading state components.

Create file: Shared/Views/Components/StateViews.swift

```swift
import SwiftUI

/// Loading state view
struct LoadingView: View {
    var message: String = "Loading..."
    var icon: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            if let icon = icon {
                Text(icon)
                    .font(.system(size: 48))
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.accentPrimary)
            }

            Text(message)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Error state view
struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Text("⚠️")
                .font(.system(size: 48))

            Text("Something went wrong")
                .font(.headline)
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            if let retry = retryAction {
                Button("Try Again", action: retry)
                    .buttonStyle(.borderedProminent)
                    .tint(.accentSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Empty state view
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 64))

            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.accentPrimary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Async content view wrapper
struct AsyncContentView<Content: View, T>: View {
    @Binding var state: AsyncState<T>
    @ViewBuilder let content: (T) -> Content
    var loadingMessage: String = "Loading..."
    var retryAction: (() -> Void)? = nil

    enum AsyncState<T> {
        case idle
        case loading
        case loaded(T)
        case error(String)
    }

    var body: some View {
        switch state {
        case .idle:
            Color.clear

        case .loading:
            LoadingView(message: loadingMessage)

        case .loaded(let data):
            content(data)

        case .error(let message):
            ErrorView(message: message, retryAction: retryAction)
        }
    }
}

#Preview("Loading") {
    LoadingView(message: "Generating puzzle...")
        .background(Color.backgroundDark)
}

#Preview("Error") {
    ErrorView(message: "Network connection failed", retryAction: {})
        .background(Color.backgroundDark)
}

#Preview("Empty") {
    EmptyStateView(
        icon: "📋",
        title: "No Activity",
        message: "Play some puzzles to see your history here!",
        actionTitle: "Play Now",
        action: {}
    )
    .background(Color.backgroundDark)
}
```
```

---

## Subphase 8.7: Performance Optimizations

**Goal:** Optimize app performance for smooth gameplay.

### Prompt for Claude Code:

```
Add performance optimizations to the Circuit Challenge app.

Create file: Shared/Utils/PerformanceUtils.swift

```swift
import SwiftUI

// MARK: - Lazy View Loading

/// Wrapper for lazy loading expensive views
struct LazyView<Content: View>: View {
    let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

// MARK: - Debouncing

/// Debounce rapid function calls
class Debouncer {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let delay: TimeInterval

    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    func call(_ action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}

// MARK: - Memoization

/// Cache expensive computations
class MemoizationCache<Key: Hashable, Value> {
    private var cache: [Key: Value] = [:]
    private let queue = DispatchQueue(label: "memoization.queue")

    func get(_ key: Key, compute: () -> Value) -> Value {
        queue.sync {
            if let cached = cache[key] {
                return cached
            }
            let value = compute()
            cache[key] = value
            return value
        }
    }

    func clear() {
        queue.sync {
            cache.removeAll()
        }
    }
}

// MARK: - Grid Rendering Optimization

extension PuzzleGridView {
    /// Memoized cell positions
    static let positionCache = MemoizationCache<String, CGPoint>()

    static func cachedCellPosition(row: Int, col: Int, cellSize: CGFloat) -> CGPoint {
        let key = "\(row)-\(col)-\(cellSize)"
        return positionCache.get(key) {
            let horizontalSpacing = cellSize * 0.85
            let verticalSpacing = cellSize * 0.8
            return CGPoint(
                x: CGFloat(col) * horizontalSpacing + cellSize / 2,
                y: CGFloat(row) * verticalSpacing + cellSize / 2
            )
        }
    }
}

// MARK: - Animation Throttling

/// Throttle animations when device is low on resources
class AnimationThrottler {
    static let shared = AnimationThrottler()

    private var lastAnimationTime: Date = .distantPast
    private let minimumInterval: TimeInterval = 0.016 // ~60fps

    func shouldAnimate() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastAnimationTime) >= minimumInterval else {
            return false
        }
        lastAnimationTime = now
        return true
    }
}
```

Add to HexCellView and ConnectorView to skip animations when unnecessary:

```swift
// In animation code:
if AnimationThrottler.shared.shouldAnimate() {
    withAnimation { ... }
}
```
```

---

## Subphase 8.8: App Configuration

**Goal:** Set up app icons, launch screen, and Info.plist.

### Prompt for Claude Code:

```
Configure the app for release.

1. App Icons - Create an AppIcon asset catalog with the hex cell circuit design:
   - 1024x1024 App Store icon
   - 180x180, 120x120, 87x87, etc. for device icons

2. Launch Screen - Create LaunchScreen.storyboard:
   - Dark background (#0f0f23)
   - Centered alien emoji (👽)
   - "Max's Puzzles" text below

3. Info.plist additions:

```xml
<key>CFBundleDisplayName</key>
<string>Max's Puzzles</string>

<key>CFBundleName</key>
<string>MaxPuzzles</string>

<key>LSRequiresIPhoneOS</key>
<true/>

<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>

<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>

<key>UIRequiresFullScreen</key>
<false/>

<key>UIStatusBarStyle</key>
<string>UIStatusBarStyleLightContent</string>

<key>UIBackgroundModes</key>
<array/>

<!-- Privacy descriptions -->
<key>NSCameraUsageDescription</key>
<string>Not used</string>

<!-- Supabase config (replace with your values) -->
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
```

4. Build Settings:
   - Set minimum iOS version to 16.0
   - Enable Mac Catalyst
   - Set bundle identifier
   - Configure signing team
```

---

## Subphase 8.9: Testing Checklist

**Goal:** Create a comprehensive testing checklist for QA.

### Prompt for Claude Code:

```
Create a testing checklist document.

Create file: ios-app/TESTING_CHECKLIST.md

```markdown
# Max's Puzzles iOS - Testing Checklist

## 1. Puzzle Generation
- [ ] Puzzles generate within 200ms
- [ ] All difficulty levels generate valid puzzles
- [ ] Solution path is always valid (START to FINISH)
- [ ] No duplicate connector values per cell
- [ ] All expressions evaluate correctly
- [ ] Division expressions produce whole numbers

## 2. Gameplay - Standard Mode
- [ ] Timer starts on first move
- [ ] Correct moves advance position
- [ ] Correct moves earn +10 coins
- [ ] Wrong moves lose 1 life
- [ ] Wrong moves cost -30 coins (min 0)
- [ ] Screen shakes on wrong move
- [ ] Game ends at FINISH (win)
- [ ] Game ends at 0 lives (lose)
- [ ] Connectors animate when traversed

## 3. Gameplay - Hidden Mode
- [ ] No lives displayed
- [ ] No feedback on moves
- [ ] Always reach FINISH
- [ ] Results revealed at end
- [ ] Coins calculated correctly

## 4. View Solution
- [ ] Shows complete path
- [ ] Available after losing
- [ ] Continue button to summary

## 5. Quick Play Setup
- [ ] All 10 difficulty presets work
- [ ] Custom settings apply correctly
- [ ] Operations toggle works
- [ ] Range sliders work
- [ ] Grid size selection works
- [ ] Hidden mode toggle works

## 6. Printing
- [ ] Single puzzle prints correctly
- [ ] Puzzle Maker generates batch
- [ ] 2 puzzles per A4 page
- [ ] Solutions on separate pages
- [ ] Black and white output
- [ ] Share sheet appears

## 7. Authentication
- [ ] Guest mode works offline
- [ ] Signup creates account
- [ ] Login works
- [ ] Family loads children
- [ ] PIN entry works
- [ ] Demo mode works
- [ ] Logout works

## 8. Parent Dashboard
- [ ] Shows all children
- [ ] Weekly stats displayed
- [ ] Child detail loads
- [ ] Activity history loads
- [ ] Edit name works
- [ ] Reset PIN works
- [ ] Remove child works

## 9. UI/UX
- [ ] Portrait layout correct
- [ ] Landscape layout correct
- [ ] iPad layout correct
- [ ] Mac Catalyst works
- [ ] Dark mode only
- [ ] Animations smooth
- [ ] No layout overflow

## 10. Accessibility
- [ ] VoiceOver labels present
- [ ] Dynamic type works
- [ ] Reduce motion respected
- [ ] Color contrast sufficient

## 11. Performance
- [ ] 60fps during gameplay
- [ ] No memory leaks
- [ ] Responsive touch input
- [ ] Fast screen transitions

## 12. Edge Cases
- [ ] Network offline handling
- [ ] App backgrounding
- [ ] App termination
- [ ] Low memory warning
- [ ] Interruptions (calls, etc.)
```
```

---

## Phase 8 Summary

After completing Phase 8, you will have:

1. **Print Template** - Print-ready puzzle view (B&W)
2. **PDF Generation** - Export puzzles to PDF
3. **Print Current Puzzle** - Share/print from game
4. **Puzzle Maker** - Batch generation and export
5. **Accessibility** - VoiceOver and dynamic type
6. **State Views** - Consistent loading/error states
7. **Performance Utils** - Optimization helpers
8. **App Configuration** - Icons, launch screen, Info.plist
9. **Testing Checklist** - QA verification guide

---

## Complete Build Order Summary

| Phase | Name | Key Deliverables |
|-------|------|------------------|
| 1 | Foundation | Project setup, theme, UI components, navigation |
| 2 | Puzzle Engine | Types, pathfinder, connectors, expressions, validation |
| 3 | Grid Rendering | HexCell, Connector, PuzzleGrid, Lives/Timer |
| 4 | Game Logic | GameState, GameViewModel, screens |
| 5 | Hub Screens | Splash, Hub, Modules, Settings |
| 6 | Authentication | Auth types, Supabase, login, family, PIN |
| 7 | Parent Features | Dashboard, child stats, activity history |
| 8 | Print & Polish | PDF export, accessibility, optimization |

**Total estimated files:** ~50-60 Swift files

**Ready for App Store submission after completing all phases!**
