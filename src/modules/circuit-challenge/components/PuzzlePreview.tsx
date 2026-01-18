import type { PrintablePuzzle, PrintConfig } from '../types/print'

interface PuzzlePreviewProps {
  puzzle: PrintablePuzzle
  config: PrintConfig
  showSolution?: boolean
}

// Hexagon path (pointy-top, centered at origin)
const HEX_PATH = 'M 0,-20 L 17,-10 L 17,10 L 0,20 L -17,10 L -17,-10 Z'

// Cell spacing for preview
const CELL_SPACING_X = 70
const CELL_SPACING_Y = 60

/**
 * Renders a preview of a single printable puzzle.
 * Uses hexagon cells matching the print template.
 */
export default function PuzzlePreview({
  puzzle,
  config,
  showSolution = false,
}: PuzzlePreviewProps) {
  const { gridRows, gridCols, cells, connectors, targetSum } = puzzle

  // Calculate dimensions
  const firstCellX = 35
  const firstCellY = 35
  const svgWidth = firstCellX + (gridCols - 1) * CELL_SPACING_X + 35
  const svgHeight = firstCellY + (gridRows - 1) * CELL_SPACING_Y + 35

  // Create solution set for highlighting
  const solutionSet = new Set(puzzle.solution)
  const solutionEdges = new Set<string>()
  for (let i = 0; i < puzzle.solution.length - 1; i++) {
    const fromIdx = puzzle.solution[i]
    const toIdx = puzzle.solution[i + 1]
    const fromRow = Math.floor(fromIdx / gridCols)
    const fromCol = fromIdx % gridCols
    const toRow = Math.floor(toIdx / gridCols)
    const toCol = toIdx % gridCols
    solutionEdges.add(`${fromRow},${fromCol}-${toRow},${toCol}`)
    solutionEdges.add(`${toRow},${toCol}-${fromRow},${fromCol}`)
  }

  // Helper to get cell center
  const getCellCenter = (row: number, col: number) => ({
    x: firstCellX + col * CELL_SPACING_X,
    y: firstCellY + row * CELL_SPACING_Y,
  })

  return (
    <div className="flex flex-col items-center">
      {/* Header */}
      <div className="flex justify-between w-full mb-2 px-2">
        <div className="text-sm text-gray-600">
          {config.showPuzzleNumber && `Puzzle ${puzzle.puzzleNumber}`}
          {config.showDifficulty && (
            <span className="ml-2 text-gray-400">({puzzle.difficultyName})</span>
          )}
        </div>
        <div className="text-lg font-bold text-gray-800">Target: {targetSum}</div>
      </div>

      {/* Grid */}
      <svg
        width={svgWidth}
        height={svgHeight}
        viewBox={`0 0 ${svgWidth} ${svgHeight}`}
        className="border border-gray-200 rounded bg-white"
      >
        <defs>
          <path id="hex-preview" d={HEX_PATH} />
        </defs>

        {/* Connectors */}
        {connectors.map((connector, i) => {
          const from = getCellCenter(connector.fromRow, connector.fromCol)
          const to = getCellCenter(connector.toRow, connector.toCol)

          const edgeKey = `${connector.fromRow},${connector.fromCol}-${connector.toRow},${connector.toCol}`
          const isInSolution = showSolution && solutionEdges.has(edgeKey)

          // Shorten lines to not overlap with hexagons
          const dx = to.x - from.x
          const dy = to.y - from.y
          const len = Math.sqrt(dx * dx + dy * dy)
          const shortenBy = 17 // Hexagon radius
          const ratio = shortenBy / len

          const x1 = from.x + dx * ratio
          const y1 = from.y + dy * ratio
          const x2 = to.x - dx * ratio
          const y2 = to.y - dy * ratio

          // Calculate midpoint for value badge
          const midX = (from.x + to.x) / 2
          const midY = (from.y + to.y) / 2

          return (
            <g key={`connector-${i}`}>
              <line
                x1={x1}
                y1={y1}
                x2={x2}
                y2={y2}
                stroke={isInSolution ? '#000' : '#888'}
                strokeWidth={isInSolution ? 2.5 : 1.5}
                strokeLinecap="round"
              />
              {/* Connector value badge */}
              <rect
                x={midX - 10}
                y={midY - 7}
                width={20}
                height={14}
                rx={2}
                fill="white"
                stroke="#000"
                strokeWidth={0.75}
              />
              <text
                x={midX}
                y={midY}
                textAnchor="middle"
                dominantBaseline="central"
                fontSize={9}
                fontWeight="bold"
                fill="#000"
              >
                {connector.value}
              </text>
            </g>
          )
        })}

        {/* Cells */}
        {cells.map((cell) => {
          const center = getCellCenter(cell.row, cell.col)
          const isInSolution = showSolution && solutionSet.has(cell.index)

          // Determine fill color
          let fill = 'white'
          if (isInSolution) {
            fill = '#e8e8e8'
          }

          return (
            <g key={`cell-${cell.index}`} transform={`translate(${center.x}, ${center.y})`}>
              {/* Hexagon */}
              <use
                href="#hex-preview"
                fill={fill}
                stroke="#000"
                strokeWidth={cell.isStart || cell.isEnd ? 2 : 1.5}
              />

              {/* START label above cell */}
              {cell.isStart && (
                <text
                  x={0}
                  y={-9}
                  textAnchor="middle"
                  dominantBaseline="hanging"
                  fontSize={7}
                  fontWeight="bold"
                  fill="#000"
                >
                  START
                </text>
              )}

              {/* Cell content */}
              {cell.isEnd ? (
                <text
                  x={0}
                  y={2}
                  textAnchor="middle"
                  dominantBaseline="middle"
                  fontSize={9}
                  fontWeight="600"
                  fill="#000"
                >
                  FINISH
                </text>
              ) : (
                <text
                  x={0}
                  y={cell.isStart ? 3 : 2}
                  textAnchor="middle"
                  dominantBaseline="middle"
                  fontSize={9}
                  fontWeight="600"
                  fill="#000"
                >
                  {cell.expression}
                </text>
              )}
            </g>
          )
        })}
      </svg>

      {/* Solution indicator */}
      {showSolution && (
        <div className="mt-2 text-sm text-green-600 font-medium">
          Solution shown
        </div>
      )}
    </div>
  )
}
