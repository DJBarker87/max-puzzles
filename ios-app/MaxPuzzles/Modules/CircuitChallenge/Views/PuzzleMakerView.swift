import SwiftUI

// MARK: - PuzzleMakerView

/// Puzzle Maker screen for generating printable worksheets
struct PuzzleMakerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @StateObject private var viewModel = PuzzleMakerViewModel()

    @State private var showShareSheet = false
    @State private var pdfData: Data?

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        ZStack {
            StarryBackground()

            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .navigationTitle("Puzzle Maker")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [data])
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 20) {
                introCard
                difficultyCard
                customSettingsCard
                puzzleCountCard

                generateButton

                if !viewModel.puzzles.isEmpty {
                    previewCard
                    exportButtons
                }

                if let error = viewModel.errorMessage {
                    errorCard(error)
                }
            }
            .padding()
        }
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column: Settings
            ScrollView {
                VStack(spacing: 12) {
                    compactDifficultyCard
                    compactCustomToggle
                    if viewModel.isCustomMode {
                        compactCustomSettingsCard
                    }
                    compactPuzzleCountCard
                }
                .padding(.vertical, 12)
            }
            .frame(maxWidth: 300)

            // Right column: Actions & Preview
            VStack(spacing: 12) {
                generateButton

                if !viewModel.puzzles.isEmpty {
                    compactPreviewCard
                    exportButtons
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Intro Card

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create Printable Puzzles")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text("Generate Circuit Challenge puzzles to print. Each A4 page contains 2 puzzles.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Difficulty Card

    private var difficultyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Difficulty")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Menu {
                ForEach(0..<10, id: \.self) { index in
                    Button(action: { viewModel.selectPreset(index) }) {
                        let preset = DifficultyPresets.byLevel(index + 1)
                        Text("Level \(index + 1): \(preset.name)")
                    }
                }
            } label: {
                HStack {
                    Text("Level \(viewModel.selectedPreset + 1): \(viewModel.currentPreset.name)")
                        .foregroundColor(viewModel.isCustomMode ? AppTheme.textSecondary : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(viewModel.isCustomMode ? AppTheme.textSecondary : .white)
                }
                .padding()
                .background(AppTheme.backgroundDark)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(viewModel.isCustomMode)

            Text(viewModel.presetDescription)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding()
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Custom Settings Card

    private var customSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Custom Settings", isOn: Binding(
                get: { viewModel.isCustomMode },
                set: { _ in viewModel.toggleCustomMode() }
            ))
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))

            if viewModel.isCustomMode {
                VStack(spacing: 20) {
                    // Operations
                    operationsSection

                    // Add/Sub Range
                    VStack(alignment: .leading, spacing: 8) {
                        Text("+/− Number Range: \(Int(viewModel.addSubRange))")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        Slider(value: $viewModel.addSubRange, in: 5...100, step: 5)
                            .tint(AppTheme.accentPrimary)
                            .onChange(of: viewModel.addSubRange) { _ in viewModel.clearPuzzles() }
                    }

                    // Mult/Div Range (if enabled)
                    if viewModel.multiplicationEnabled || viewModel.divisionEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("×/÷ Number Range: \(Int(viewModel.multDivRange))")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            Slider(value: $viewModel.multDivRange, in: 2...12, step: 1)
                                .tint(AppTheme.accentPrimary)
                                .onChange(of: viewModel.multDivRange) { _ in viewModel.clearPuzzles() }
                        }
                    }

                    // Grid Size
                    gridSizeSection

                    // Custom description
                    Text(viewModel.customDescription)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding()
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Operations Section

    private var operationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Operations")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                ForEach(["+", "−", "×", "÷"], id: \.self) { op in
                    operationToggle(op, isOn: viewModel.isOperationEnabled(op))
                }
            }

            if !viewModel.hasValidOperations {
                Text("At least one operation must be enabled")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.error)
            }
        }
    }

    private func operationToggle(_ symbol: String, isOn: Bool) -> some View {
        Button(action: { viewModel.toggleOperation(symbol) }) {
            Text(symbol)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 48, height: 48)
                .background(isOn ? AppTheme.accentPrimary : AppTheme.backgroundDark)
                .foregroundColor(.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOn ? AppTheme.accentPrimary : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - Grid Size Section

    private var gridSizeSection: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Rows")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    ForEach([3, 4, 5, 6], id: \.self) { n in
                        gridSizeButton(n, selected: viewModel.gridRows == n) {
                            viewModel.setGridRows(n)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Columns")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    ForEach([4, 5, 6, 7, 8], id: \.self) { n in
                        gridSizeButton(n, selected: viewModel.gridCols == n) {
                            viewModel.setGridCols(n)
                        }
                    }
                }
            }
        }
    }

    private func gridSizeButton(_ value: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(value)")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 36, height: 36)
                .background(selected ? AppTheme.accentPrimary : AppTheme.backgroundDark)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    // MARK: - Puzzle Count Card

    private var puzzleCountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Puzzle Count")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("Number of Puzzles: \(viewModel.config.puzzleCount)")
                    .font(.system(size: 14))
                    .foregroundColor(.white)

                Slider(
                    value: Binding(
                        get: { Double(viewModel.config.puzzleCount) },
                        set: { viewModel.setPuzzleCount(Int($0)) }
                    ),
                    in: 2...50,
                    step: 2
                )
                .tint(AppTheme.accentPrimary)

                HStack {
                    Text("2")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("50")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Toggle("Include answer key pages", isOn: Binding(
                get: { viewModel.config.showAnswers },
                set: { viewModel.setShowAnswers($0) }
            ))
            .font(.system(size: 14))
            .foregroundColor(.white)
            .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))
        }
        .padding()
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: { viewModel.generatePuzzles() }) {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(viewModel.isGenerating
                     ? "Generating Puzzles..."
                     : "Generate \(viewModel.config.puzzleCount) Puzzles")
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.hasValidOperations && !viewModel.isGenerating
                    ? AppTheme.accentPrimary
                    : Color.gray.opacity(0.5)
            )
            .cornerRadius(12)
        }
        .disabled(!viewModel.hasValidOperations || viewModel.isGenerating)
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Preview")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(viewModel.puzzles.count) puzzles • \(viewModel.totalPages) pages")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }

            // Navigator
            HStack {
                Button(action: { viewModel.previousPuzzle() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(viewModel.previewIndex > 0 ? .white : AppTheme.textSecondary)
                }
                .disabled(viewModel.previewIndex == 0)

                Spacer()

                Text("Puzzle \(viewModel.previewIndex + 1) of \(viewModel.puzzles.count)")
                    .font(.system(size: 14))
                    .foregroundColor(.white)

                Spacer()

                Button(action: { viewModel.nextPuzzle() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(viewModel.previewIndex < viewModel.puzzles.count - 1 ? .white : AppTheme.textSecondary)
                }
                .disabled(viewModel.previewIndex >= viewModel.puzzles.count - 1)
            }
            .padding(.vertical, 8)

            // Preview content
            if viewModel.previewIndex < viewModel.puzzles.count {
                PuzzlePreviewView(puzzle: viewModel.puzzles[viewModel.previewIndex])
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Export Buttons

    private var exportButtons: some View {
        VStack(spacing: 12) {
            Button(action: exportPDF) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share / Print PDF")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.accentPrimary)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Compact Cards (Landscape)

    private var compactDifficultyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Difficulty")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Menu {
                ForEach(0..<10, id: \.self) { index in
                    Button(action: { viewModel.selectPreset(index) }) {
                        let preset = DifficultyPresets.byLevel(index + 1)
                        Text("Level \(index + 1): \(preset.name)")
                    }
                }
            } label: {
                HStack {
                    Text("Level \(viewModel.selectedPreset + 1)")
                        .foregroundColor(viewModel.isCustomMode ? AppTheme.textSecondary : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(viewModel.isCustomMode ? AppTheme.textSecondary : .white)
                }
                .padding(10)
                .background(AppTheme.backgroundDark)
                .cornerRadius(8)
            }
            .disabled(viewModel.isCustomMode)

            Text(viewModel.currentPreset.name)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(12)
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(10)
    }

    private var compactCustomToggle: some View {
        HStack {
            Text("Custom Settings")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: Binding(
                get: { viewModel.isCustomMode },
                set: { _ in viewModel.toggleCustomMode() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))
            .labelsHidden()
        }
        .padding(12)
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(10)
    }

    private var compactCustomSettingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Operations row
            VStack(alignment: .leading, spacing: 4) {
                Text("Operations")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    ForEach(["+", "−", "×", "÷"], id: \.self) { op in
                        compactOpToggle(op, isOn: viewModel.isOperationEnabled(op))
                    }
                }
            }

            // Number range
            VStack(alignment: .leading, spacing: 2) {
                Text("+/− Range: \(Int(viewModel.addSubRange))")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                Slider(value: $viewModel.addSubRange, in: 5...100, step: 5)
                    .tint(AppTheme.accentPrimary)
            }

            // Grid size
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rows")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    HStack(spacing: 3) {
                        ForEach([3, 4, 5, 6], id: \.self) { n in
                            compactSizeButton(n, selected: viewModel.gridRows == n) {
                                viewModel.setGridRows(n)
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cols")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    HStack(spacing: 3) {
                        ForEach([4, 5, 6, 7], id: \.self) { n in
                            compactSizeButton(n, selected: viewModel.gridCols == n) {
                                viewModel.setGridCols(n)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(10)
    }

    private func compactOpToggle(_ symbol: String, isOn: Bool) -> some View {
        Button(action: { viewModel.toggleOperation(symbol) }) {
            Text(symbol)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 36, height: 36)
                .background(isOn ? AppTheme.accentPrimary : AppTheme.backgroundDark)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    private func compactSizeButton(_ value: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(value)")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 28, height: 28)
                .background(selected ? AppTheme.accentPrimary : AppTheme.backgroundDark)
                .foregroundColor(.white)
                .cornerRadius(6)
        }
    }

    private var compactPuzzleCountCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Puzzles: \(viewModel.config.puzzleCount)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Slider(
                value: Binding(
                    get: { Double(viewModel.config.puzzleCount) },
                    set: { viewModel.setPuzzleCount(Int($0)) }
                ),
                in: 2...50,
                step: 2
            )
            .tint(AppTheme.accentPrimary)

            Toggle("Answer key", isOn: Binding(
                get: { viewModel.config.showAnswers },
                set: { viewModel.setShowAnswers($0) }
            ))
            .font(.system(size: 12))
            .foregroundColor(.white)
            .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))
        }
        .padding(12)
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(10)
    }

    private var compactPreviewCard: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { viewModel.previousPuzzle() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(viewModel.previewIndex > 0 ? .white : AppTheme.textSecondary)
                }
                .disabled(viewModel.previewIndex == 0)

                Spacer()

                Text("\(viewModel.previewIndex + 1)/\(viewModel.puzzles.count)")
                    .font(.system(size: 12))
                    .foregroundColor(.white)

                Spacer()

                Button(action: { viewModel.nextPuzzle() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(viewModel.previewIndex < viewModel.puzzles.count - 1 ? .white : AppTheme.textSecondary)
                }
                .disabled(viewModel.previewIndex >= viewModel.puzzles.count - 1)
            }

            if viewModel.previewIndex < viewModel.puzzles.count {
                PuzzlePreviewView(puzzle: viewModel.puzzles[viewModel.previewIndex])
                    .frame(height: 120)
                    .background(Color.white)
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(10)
    }

    // MARK: - Error Card

    private func errorCard(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppTheme.error)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.error)
        }
        .padding()
        .background(AppTheme.error.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func exportPDF() {
        guard let data = viewModel.generatePDF() else { return }
        pdfData = data
        showShareSheet = true
    }
}

// MARK: - Puzzle Preview View

struct PuzzlePreviewView: View {
    let puzzle: PrintablePuzzle

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                drawPuzzle(context: context, size: size)
            }
        }
    }

    private func drawPuzzle(context: GraphicsContext, size: CGSize) {
        let gridRows = puzzle.gridRows
        let gridCols = puzzle.gridCols

        // Calculate cell size based on available space
        let spacingX: CGFloat = 45
        let spacingY: CGFloat = 40
        let cellWidth: CGFloat = 22
        let cellHeight: CGFloat = 26

        let naturalWidth = CGFloat(gridCols - 1) * spacingX + cellWidth + 20
        let naturalHeight = CGFloat(gridRows - 1) * spacingY + cellHeight + 20
        let scaleX = size.width / naturalWidth
        let scaleY = size.height / naturalHeight
        let scale = min(scaleX, scaleY) * 0.85

        let scaledWidth = naturalWidth * scale
        let scaledHeight = naturalHeight * scale
        let offsetX = (size.width - scaledWidth) / 2 + 10 * scale
        let offsetY = (size.height - scaledHeight) / 2 + 10 * scale

        func getCellCenter(row: Int, col: Int) -> CGPoint {
            CGPoint(
                x: offsetX + CGFloat(col) * spacingX * scale,
                y: offsetY + CGFloat(row) * spacingY * scale
            )
        }

        // Draw connectors
        for connector in puzzle.connectors {
            let from = getCellCenter(row: connector.fromRow, col: connector.fromCol)
            let to = getCellCenter(row: connector.toRow, col: connector.toCol)
            let mid = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)

            // Draw line
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            context.stroke(path, with: .color(.black), lineWidth: 1 * scale)

            // Draw badge
            let badgeWidth: CGFloat = 14 * scale
            let badgeHeight: CGFloat = 10 * scale
            let badgeRect = CGRect(
                x: mid.x - badgeWidth / 2,
                y: mid.y - badgeHeight / 2,
                width: badgeWidth,
                height: badgeHeight
            )
            context.fill(RoundedRectangle(cornerRadius: 2 * scale).path(in: badgeRect), with: .color(.white))
            context.stroke(RoundedRectangle(cornerRadius: 2 * scale).path(in: badgeRect), with: .color(.black), lineWidth: 0.5 * scale)

            // Draw value text
            let text = Text("\(connector.value)")
                .font(.system(size: 6 * scale, weight: .bold))
                .foregroundColor(.black)
            context.draw(text, at: mid)
        }

        // Draw cells
        for cell in puzzle.cells {
            let center = getCellCenter(row: cell.row, col: cell.col)
            let w = cellWidth * scale
            let h = cellHeight * scale

            // Create hexagon path
            var path = Path()
            let points: [CGPoint] = [
                CGPoint(x: center.x, y: center.y - h / 2),
                CGPoint(x: center.x + w / 2, y: center.y - h / 4),
                CGPoint(x: center.x + w / 2, y: center.y + h / 4),
                CGPoint(x: center.x, y: center.y + h / 2),
                CGPoint(x: center.x - w / 2, y: center.y + h / 4),
                CGPoint(x: center.x - w / 2, y: center.y - h / 4)
            ]
            path.addLines(points)
            path.closeSubpath()

            context.fill(path, with: .color(.white))
            context.stroke(path, with: .color(.black), lineWidth: (cell.isStart || cell.isEnd) ? 1.5 * scale : 1 * scale)

            // Draw text
            let displayText = cell.isEnd ? "FIN" : (cell.isStart ? "START" : cell.expression)
            let text = Text(displayText)
                .font(.system(size: cell.isStart ? 5 * scale : 7 * scale, weight: .bold))
                .foregroundColor(.black)
            context.draw(text, at: center)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Puzzle Maker") {
    NavigationStack {
        PuzzleMakerView()
    }
}
