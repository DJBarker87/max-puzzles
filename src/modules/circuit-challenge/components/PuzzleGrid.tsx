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
  cellSize?: number
  className?: string
}

/**
 * Complete puzzle grid with cells and connectors
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
  cellSize = 45,
  className = '',
}: PuzzleGridProps) {
  const hexWidth = cellSize * 2
  const hexHeight = cellSize * Math.sqrt(3)
  const horizontalSpacing = hexWidth * 0.75
  const verticalSpacing = hexHeight

  const rows = puzzle.grid.length
  const cols = puzzle.grid[0]?.length ?? 0

  const gridWidth = (cols - 1) * horizontalSpacing + hexWidth + 40
  const gridHeight = (rows - 1) * verticalSpacing + hexHeight + 40

  const getCellCenter = (row: number, col: number) => ({
    x: 20 + col * horizontalSpacing + cellSize,
    y: 20 + row * verticalSpacing + cellSize,
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

            return (
              <HexCell
                key={`cell-${rowIndex}-${colIndex}`}
                cx={center.x}
                cy={center.y}
                size={cellSize}
                state={state}
                expression={cell.expression}
                label={cell.isStart ? 'START' : cell.isFinish ? 'FINISH' : undefined}
                onClick={clickable && onCellClick ? () => onCellClick({ row: rowIndex, col: colIndex }) : undefined}
                disabled={!clickable}
                answer={cell.answer ?? undefined}
              />
            )
          })
        )}
      </g>
    </svg>
  )
}
