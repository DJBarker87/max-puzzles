import type { PrintablePuzzle, PrintConfig } from '../types/print'

interface PuzzlePreviewProps {
  puzzle: PrintablePuzzle
  config: PrintConfig
  showSolution?: boolean
}

/**
 * Renders a preview of a single printable puzzle.
 * Used in the Puzzle Maker screen.
 */
export default function PuzzlePreview({
  puzzle,
  config,
  showSolution = false,
}: PuzzlePreviewProps) {
  const { gridRows, gridCols, cells, connectors, targetSum } = puzzle

  // Calculate dimensions
  const cellSize = 40 // px for preview
  const gridWidth = gridCols * cellSize
  const gridHeight = gridRows * cellSize
  const padding = 30

  const svgWidth = gridWidth + padding * 2
  const svgHeight = gridHeight + padding * 2

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
        {/* Connectors */}
        {connectors.map((connector, i) => {
          const x1 = padding + connector.fromCol * cellSize + cellSize / 2
          const y1 = padding + connector.fromRow * cellSize + cellSize / 2
          const x2 = padding + connector.toCol * cellSize + cellSize / 2
          const y2 = padding + connector.toRow * cellSize + cellSize / 2

          const edgeKey = `${connector.fromRow},${connector.fromCol}-${connector.toRow},${connector.toCol}`
          const isInSolution = showSolution && solutionEdges.has(edgeKey)

          // Calculate midpoint for value label
          const midX = (x1 + x2) / 2
          const midY = (y1 + y2) / 2

          return (
            <g key={`connector-${i}`}>
              <line
                x1={x1}
                y1={y1}
                x2={x2}
                y2={y2}
                stroke={isInSolution ? '#000' : '#ccc'}
                strokeWidth={isInSolution ? 3 : 1.5}
                strokeLinecap="round"
              />
              {/* Connector value */}
              <rect
                x={midX - 10}
                y={midY - 7}
                width={20}
                height={14}
                fill="white"
              />
              <text
                x={midX}
                y={midY}
                textAnchor="middle"
                dominantBaseline="central"
                fontSize={10}
                fill="#666"
              >
                {connector.value}
              </text>
            </g>
          )
        })}

        {/* Cells */}
        {cells.map((cell) => {
          const cx = padding + cell.col * cellSize + cellSize / 2
          const cy = padding + cell.row * cellSize + cellSize / 2
          const radius = cellSize * 0.35

          const isInSolution = showSolution && solutionSet.has(cell.index)

          // Determine fill color
          let fill = 'white'
          if (cell.isStart || cell.isEnd) {
            fill = '#e5e5e5'
          } else if (isInSolution) {
            fill = '#f0f0f0'
          }

          return (
            <g key={`cell-${cell.index}`}>
              {/* Cell circle */}
              <circle
                cx={cx}
                cy={cy}
                r={radius}
                fill={fill}
                stroke="#000"
                strokeWidth={cell.isStart || cell.isEnd ? 2 : 1.5}
              />

              {/* Cell expression */}
              <text
                x={cx}
                y={cy}
                textAnchor="middle"
                dominantBaseline="central"
                fontSize={11}
                fontWeight="bold"
                fill="#000"
              >
                {cell.expression}
              </text>

              {/* Start/End labels */}
              {cell.isStart && (
                <text
                  x={cx}
                  y={cy - radius - 8}
                  textAnchor="middle"
                  fontSize={8}
                  fill="#666"
                >
                  START
                </text>
              )}
              {cell.isEnd && (
                <text
                  x={cx}
                  y={cy + radius + 10}
                  textAnchor="middle"
                  fontSize={8}
                  fill="#666"
                >
                  END
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
