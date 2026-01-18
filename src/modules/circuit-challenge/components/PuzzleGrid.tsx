import type { Puzzle, Coordinate, CellState } from '../types'
import HexCell from './HexCell'
import Connector from './Connector'
import GridDefs from './GridDefs'

interface PuzzleGridProps {
  puzzle: Puzzle
  currentPosition: Coordinate
  visitedCells: Coordinate[]
  traversedConnectors: Array<{ cellA: Coordinate; cellB: Coordinate }>
  wrongMoves?: Coordinate[]
  wrongConnectors?: Array<{ cellA: Coordinate; cellB: Coordinate }>
  onCellClick?: (coord: Coordinate) => void
  disabled?: boolean
  showSolution?: boolean
  className?: string
}

/**
 * Complete puzzle grid with cells and connectors
 * Layout matches spec: rectangular grid with 150px horizontal, 140px vertical spacing
 */
export default function PuzzleGrid({
  puzzle,
  currentPosition,
  visitedCells,
  traversedConnectors,
  wrongMoves,
  wrongConnectors,
  onCellClick,
  disabled = false,
  className = '',
}: PuzzleGridProps) {
  // Fixed dimensions matching the spec exactly
  const cellSize = 42  // radius of hexagon
  const horizontalSpacing = 150  // matches spec: cells at 75, 225, 375, 525, 675
  const verticalSpacing = 140    // matches spec: cells at 75, 215, 355, 495

  const rows = puzzle.grid.length
  const cols = puzzle.grid[0]?.length ?? 0

  // Calculate grid dimensions with padding
  // First cell at (75, 75), so we need padding of 75 on left/top
  const padding = 75
  const gridWidth = padding + (cols - 1) * horizontalSpacing + padding + 30
  const gridHeight = padding + (rows - 1) * verticalSpacing + padding + 50

  // Cell centers matching spec positions
  const getCellCenter = (row: number, col: number) => ({
    x: padding + col * horizontalSpacing,
    y: padding + row * verticalSpacing,
  })

  const getCellState = (row: number, col: number): CellState => {
    const isStart = row === 0 && col === 0
    const isFinish = row === rows - 1 && col === cols - 1
    const isCurrent = currentPosition.row === row && currentPosition.col === col
    const isVisited = visitedCells.some(c => c.row === row && c.col === col)
    const isWrong = wrongMoves?.some(c => c.row === row && c.col === col)

    if (isWrong) return 'wrong'
    if (isCurrent) return 'current'
    if (isStart && isVisited) return 'visited'
    if (isStart) return 'start'
    if (isFinish) return 'finish'
    if (isVisited) return 'visited'
    return 'normal'
  }

  const isConnectorTraversed = (cellA: Coordinate, cellB: Coordinate): boolean => {
    return traversedConnectors.some(tc =>
      (tc.cellA.row === cellA.row && tc.cellA.col === cellA.col &&
       tc.cellB.row === cellB.row && tc.cellB.col === cellB.col) ||
      (tc.cellA.row === cellB.row && tc.cellA.col === cellB.col &&
       tc.cellB.row === cellA.row && tc.cellB.col === cellA.col)
    )
  }

  const isConnectorWrong = (cellA: Coordinate, cellB: Coordinate): boolean => {
    return wrongConnectors?.some(wc =>
      (wc.cellA.row === cellA.row && wc.cellA.col === cellA.col &&
       wc.cellB.row === cellB.row && wc.cellB.col === cellB.col) ||
      (wc.cellA.row === cellB.row && wc.cellA.col === cellB.col &&
       wc.cellB.row === cellA.row && wc.cellB.col === cellA.col)
    ) ?? false
  }

  const isCellClickable = (row: number, col: number): boolean => {
    if (disabled) return false
    const rowDiff = Math.abs(row - currentPosition.row)
    const colDiff = Math.abs(col - currentPosition.col)
    return rowDiff <= 1 && colDiff <= 1 && !(rowDiff === 0 && colDiff === 0)
  }

  // Get the start cell position for the label
  const startCenter = getCellCenter(0, 0)

  return (
    <svg
      viewBox={`0 0 ${gridWidth} ${gridHeight}`}
      className={`puzzle-grid ${className}`}
      style={{ maxWidth: '100%', height: 'auto' }}
    >
      <GridDefs />

      {/* Connectors layer (behind cells) */}
      <g className="connectors-layer">
        {puzzle.connectors.map((connector, index) => {
          const centerA = getCellCenter(connector.cellA.row, connector.cellA.col)
          const centerB = getCellCenter(connector.cellB.row, connector.cellB.col)

          return (
            <Connector
              key={`connector-${index}`}
              cellA={centerA}
              cellB={centerB}
              value={connector.value}
              type={connector.type}
              isTraversed={isConnectorTraversed(connector.cellA, connector.cellB)}
              isWrong={isConnectorWrong(connector.cellA, connector.cellB)}
              animationDelay={index * 50}
            />
          )
        })}
      </g>

      {/* Cells layer (on top) */}
      <g className="cells-layer">
        {puzzle.grid.map((row, rowIndex) =>
          row.map((cell, colIndex) => {
            const center = getCellCenter(rowIndex, colIndex)
            const state = getCellState(rowIndex, colIndex)
            const clickable = isCellClickable(rowIndex, colIndex)

            // For FINISH cell, show "FINISH" as the expression
            // For all other cells (including START), show the math expression
            const displayExpression = cell.isFinish ? 'FINISH' : cell.expression

            return (
              <HexCell
                key={`cell-${rowIndex}-${colIndex}`}
                cx={center.x}
                cy={center.y}
                size={cellSize}
                state={state}
                expression={displayExpression}
                onClick={clickable && onCellClick ? () => onCellClick({ row: rowIndex, col: colIndex }) : undefined}
                disabled={!clickable}
                answer={cell.answer ?? undefined}
              />
            )
          })
        )}
      </g>

      {/* START label above the grid (matching spec) */}
      <text
        className="start-label"
        x={startCenter.x}
        y={20}
        textAnchor="middle"
        fontSize={11}
        fontWeight={700}
        letterSpacing={2}
        fill="#00ff88"
        style={{
          fontFamily: "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif",
          filter: 'drop-shadow(0 0 6px rgba(0,255,136,0.6))'
        }}
      >
        START
      </text>
    </svg>
  )
}
