import SwiftUI
import UIKit

// MARK: - PuzzleGridView

/// Complete puzzle grid with cells and connectors
/// Matches web app layout exactly: 150px horizontal spacing, 140px vertical spacing
struct PuzzleGridView: View {
    let puzzle: Puzzle
    let currentPosition: Coordinate
    let visitedCells: [Coordinate]
    let traversedConnectors: [TraversedConnector]
    let wrongMoves: [Coordinate]
    let wrongConnectors: [TraversedConnector]
    let showSolution: Bool
    let disabled: Bool
    let onCellTap: ((Coordinate) -> Void)?

    @State private var currentGeometry: HexagonGeometry = .standard

    init(
        puzzle: Puzzle,
        currentPosition: Coordinate,
        visitedCells: [Coordinate] = [],
        traversedConnectors: [TraversedConnector] = [],
        wrongMoves: [Coordinate] = [],
        wrongConnectors: [TraversedConnector] = [],
        showSolution: Bool = false,
        disabled: Bool = false,
        onCellTap: ((Coordinate) -> Void)? = nil
    ) {
        self.puzzle = puzzle
        self.currentPosition = currentPosition
        self.visitedCells = visitedCells
        self.traversedConnectors = traversedConnectors
        self.wrongMoves = wrongMoves
        self.wrongConnectors = wrongConnectors
        self.showSolution = showSolution
        self.disabled = disabled
        self.onCellTap = onCellTap
    }

    var body: some View {
        GeometryReader { geo in
            let scaledGeometry = HexagonGeometry.scaled(
                for: geo.size,
                rows: puzzle.rows,
                cols: puzzle.cols
            )

            ZStack(alignment: .topLeading) {
                // START label
                startLabel(geometry: scaledGeometry)

                // Connectors layer (behind cells)
                connectorsLayer(geometry: scaledGeometry)

                // Cells layer (on top)
                cellsLayer(geometry: scaledGeometry)
            }
            .frame(
                width: scaledGeometry.gridWidth(cols: puzzle.cols),
                height: scaledGeometry.gridHeight(rows: puzzle.rows)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                currentGeometry = scaledGeometry
            }
            .onChange(of: geo.size) { newSize in
                currentGeometry = HexagonGeometry.scaled(
                    for: newSize,
                    rows: puzzle.rows,
                    cols: puzzle.cols
                )
            }
        }
    }

    // MARK: - START Label

    private func startLabel(geometry: HexagonGeometry) -> some View {
        let startCenter = geometry.cellCenter(row: 0, col: 0)
        // Scale font size with geometry (about 25% of cell radius)
        let fontSize = max(geometry.cellRadius * 0.25, 10)

        return Text("START")
            .font(.system(size: fontSize, weight: .bold))
            .tracking(2)
            .foregroundColor(Color(hex: "00ff88"))
            .shadow(color: Color(hex: "00ff88").opacity(0.6), radius: 6)
            .position(x: startCenter.x, y: geometry.padding - geometry.cellRadius - 5)
    }

    // MARK: - Connectors Layer

    /// On iPhone with 6 rows, put vertical connector badges at bottom to avoid overlap
    private var shouldUseBottomBadges: Bool {
        let isIPhone = UIDevice.current.userInterfaceIdiom == .phone
        return isIPhone && puzzle.rows >= 6
    }

    /// On iPhone with 4 rows (story mode), use compact glow to avoid blocking answers
    private var shouldUseCompactGlow: Bool {
        let isIPhone = UIDevice.current.userInterfaceIdiom == .phone
        return isIPhone && puzzle.rows <= 4
    }

    private func connectorsLayer(geometry: HexagonGeometry) -> some View {
        ForEach(Array(puzzle.connectors.enumerated()), id: \.offset) { index, connector in
            let isTraversed = isConnectorTraversed(connector.cellA, connector.cellB)
            let traversalDir = isTraversed ? getTraversalDirection(connector.cellA, connector.cellB) : nil

            let fromCoord = traversalDir?.from ?? connector.cellA
            let toCoord = traversalDir?.to ?? connector.cellB

            let startPoint = geometry.cellCenter(row: fromCoord.row, col: fromCoord.col)
            let endPoint = geometry.cellCenter(row: toCoord.row, col: toCoord.col)

            ConnectorView(
                startPoint: startPoint,
                endPoint: endPoint,
                value: connector.value,
                isTraversed: isTraversed,
                isWrong: isConnectorWrong(connector.cellA, connector.cellB),
                animationDelay: Double(index * 50),
                cellRadius: geometry.cellRadius,
                verticalBadgeAtBottom: shouldUseBottomBadges
            )
        }
    }

    // MARK: - Cells Layer

    private func cellsLayer(geometry: HexagonGeometry) -> some View {
        ForEach(0..<puzzle.rows, id: \.self) { row in
            ForEach(0..<puzzle.cols, id: \.self) { col in
                let cell = puzzle.grid[row][col]
                let center = geometry.cellCenter(row: row, col: col)
                let state = getCellState(row: row, col: col)
                let clickable = isCellClickable(row: row, col: col)
                let displayExpression = cell.isFinish ? "FINISH" : cell.expression

                HexCellView(
                    state: state,
                    expression: displayExpression,
                    size: geometry.cellRadius,
                    isClickable: clickable,
                    compactGlow: shouldUseCompactGlow,
                    onTap: clickable ? { onCellTap?(Coordinate(row: row, col: col)) } : nil
                )
                .position(center)
            }
        }
    }

    // MARK: - State Helpers

    private func getCellState(row: Int, col: Int) -> CellState {
        let coord = Coordinate(row: row, col: col)
        let isStart = row == 0 && col == 0
        let isFinish = row == puzzle.rows - 1 && col == puzzle.cols - 1
        let isCurrent = currentPosition == coord
        let isVisited = visitedCells.contains(coord)
        let isWrong = wrongMoves.contains(coord)

        if isWrong { return .wrong }
        if isCurrent { return .current }
        if isStart && isVisited { return .visited }
        if isStart { return .start }
        if isFinish { return .finish }
        if isVisited { return .visited }
        return .normal
    }

    private func isCellClickable(row: Int, col: Int) -> Bool {
        guard !disabled, onCellTap != nil else { return false }
        let rowDiff = abs(row - currentPosition.row)
        let colDiff = abs(col - currentPosition.col)
        return rowDiff <= 1 && colDiff <= 1 && !(rowDiff == 0 && colDiff == 0)
    }

    // MARK: - Connector Helpers

    private func isConnectorTraversed(_ cellA: Coordinate, _ cellB: Coordinate) -> Bool {
        // If showing solution, highlight all solution path connectors
        if showSolution && isConnectorOnSolutionPath(cellA, cellB) {
            return true
        }

        return traversedConnectors.contains { tc in
            (tc.cellA == cellA && tc.cellB == cellB) ||
            (tc.cellA == cellB && tc.cellB == cellA)
        }
    }

    private func isConnectorOnSolutionPath(_ cellA: Coordinate, _ cellB: Coordinate) -> Bool {
        let path = puzzle.solution.path
        for i in 0..<(path.count - 1) {
            let from = path[i]
            let to = path[i + 1]
            if (from == cellA && to == cellB) || (from == cellB && to == cellA) {
                return true
            }
        }
        return false
    }

    private func getTraversalDirection(_ cellA: Coordinate, _ cellB: Coordinate) -> (from: Coordinate, to: Coordinate)? {
        // Check traversed connectors first
        if let match = traversedConnectors.first(where: { tc in
            (tc.cellA == cellA && tc.cellB == cellB) ||
            (tc.cellA == cellB && tc.cellB == cellA)
        }) {
            return (from: match.cellA, to: match.cellB)
        }

        // If showing solution, get direction from solution path
        if showSolution {
            let path = puzzle.solution.path
            for i in 0..<(path.count - 1) {
                let from = path[i]
                let to = path[i + 1]
                if (from == cellA && to == cellB) || (from == cellB && to == cellA) {
                    return (from: from, to: to)
                }
            }
        }

        return nil
    }

    private func isConnectorWrong(_ cellA: Coordinate, _ cellB: Coordinate) -> Bool {
        wrongConnectors.contains { wc in
            (wc.cellA == cellA && wc.cellB == cellB) ||
            (wc.cellA == cellB && wc.cellB == cellA)
        }
    }
}

// MARK: - Preview Helper

/// Creates a mock puzzle for preview purposes
private func createMockPuzzle() -> Puzzle {
    // Create a simple 3x4 puzzle for preview
    var cells: [[Cell]] = []
    for row in 0..<3 {
        var rowCells: [Cell] = []
        for col in 0..<4 {
            let isStart = row == 0 && col == 0
            let isFinish = row == 2 && col == 3
            let expression = isStart ? "5 + 3" : (isFinish ? "" : "\(row * 4 + col + 5) + \(col + 1)")
            let answer = isFinish ? nil : (row * 4 + col + 5 + col + 1)

            rowCells.append(Cell(
                row: row,
                col: col,
                expression: expression,
                answer: answer,
                isStart: isStart,
                isFinish: isFinish
            ))
        }
        cells.append(rowCells)
    }

    // Create mock connectors
    var connectors: [Connector] = []

    // Horizontal connectors
    for row in 0..<3 {
        for col in 0..<3 {
            connectors.append(Connector(
                type: .horizontal,
                cellA: Coordinate(row: row, col: col),
                cellB: Coordinate(row: row, col: col + 1),
                value: row * 3 + col + 8
            ))
        }
    }

    // Vertical connectors
    for row in 0..<2 {
        for col in 0..<4 {
            connectors.append(Connector(
                type: .vertical,
                cellA: Coordinate(row: row, col: col),
                cellB: Coordinate(row: row + 1, col: col),
                value: row * 4 + col + 15
            ))
        }
    }

    return Puzzle(
        id: "preview",
        difficulty: 1,
        grid: cells,
        connectors: connectors,
        solution: Solution(path: [
            Coordinate(row: 0, col: 0),
            Coordinate(row: 0, col: 1),
            Coordinate(row: 1, col: 1),
            Coordinate(row: 2, col: 2),
            Coordinate(row: 2, col: 3)
        ])
    )
}

// MARK: - Preview

#Preview("Puzzle Grid") {
    let mockPuzzle = createMockPuzzle()

    ZStack {
        LinearGradient(
            colors: [Color(hex: "0a0a12"), Color(hex: "0d0d18")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        PuzzleGridView(
            puzzle: mockPuzzle,
            currentPosition: Coordinate(row: 0, col: 0),
            visitedCells: [],
            traversedConnectors: [],
            showSolution: false,
            disabled: false
        ) { coord in
            print("Tapped cell: \(coord.row), \(coord.col)")
        }
    }
}

#Preview("Puzzle Grid - Mid Game") {
    let mockPuzzle = createMockPuzzle()

    ZStack {
        LinearGradient(
            colors: [Color(hex: "0a0a12"), Color(hex: "0d0d18")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        PuzzleGridView(
            puzzle: mockPuzzle,
            currentPosition: Coordinate(row: 1, col: 1),
            visitedCells: [Coordinate(row: 0, col: 0), Coordinate(row: 0, col: 1)],
            traversedConnectors: [
                TraversedConnector(cellA: Coordinate(row: 0, col: 0), cellB: Coordinate(row: 0, col: 1)),
                TraversedConnector(cellA: Coordinate(row: 0, col: 1), cellB: Coordinate(row: 1, col: 1))
            ],
            showSolution: false,
            disabled: false
        ) { coord in
            print("Tapped cell: \(coord.row), \(coord.col)")
        }
    }
}

#Preview("Puzzle Grid - Show Solution") {
    let mockPuzzle = createMockPuzzle()

    ZStack {
        LinearGradient(
            colors: [Color(hex: "0a0a12"), Color(hex: "0d0d18")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        PuzzleGridView(
            puzzle: mockPuzzle,
            currentPosition: Coordinate(row: 0, col: 0),
            visitedCells: [],
            traversedConnectors: [],
            showSolution: true,
            disabled: true
        )
    }
}
