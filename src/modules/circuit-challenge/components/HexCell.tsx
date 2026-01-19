import type { CellState } from '../types'
import './animations.css'

interface HexCellProps {
  cx: number
  cy: number
  size?: number
  state: CellState
  expression: string
  onClick?: () => void
  disabled?: boolean
  showAnswer?: boolean
  answer?: number
}

/**
 * Generate a pointy-top hexagon points string (matching spec)
 * Spec uses: "0,-42 36,-21 36,21 0,42 -36,21 -36,-21" for radius 42
 */
function getHexagonPoints(cx: number, cy: number, radius: number): string {
  // Pointy-top hexagon: vertices at top and bottom
  // Width factor is sqrt(3)/2 ≈ 0.866
  const w = radius * Math.sqrt(3) / 2  // half-width
  const h = radius / 2                  // quarter-height

  const points = [
    [cx, cy - radius],           // top
    [cx + w, cy - h],            // top-right
    [cx + w, cy + h],            // bottom-right
    [cx, cy + radius],           // bottom
    [cx - w, cy + h],            // bottom-left
    [cx - w, cy - h],            // top-left
  ]

  return points.map(p => p.join(',')).join(' ')
}

/**
 * Get gradient IDs based on cell state
 */
function getGradients(state: CellState) {
  const gradientMap: Record<CellState, { top: string; base: string; stroke: string; strokeWidth: number }> = {
    normal: {
      top: 'url(#cc-cellTopGradient)',
      base: 'url(#cc-cellBaseGradient)',
      stroke: '#4a4a5a',
      strokeWidth: 2,
    },
    start: {
      top: 'url(#cc-startGradient)',
      base: 'url(#cc-startBaseGradient)',
      stroke: '#00ff88',
      strokeWidth: 2,
    },
    finish: {
      top: 'url(#cc-finishGradient)',
      base: 'url(#cc-finishBaseGradient)',
      stroke: '#ffcc00',
      strokeWidth: 2,
    },
    current: {
      top: 'url(#cc-currentGradient)',
      base: 'url(#cc-currentBaseGradient)',
      stroke: '#00ffcc',
      strokeWidth: 3,
    },
    visited: {
      top: 'url(#cc-visitedGradient)',
      base: 'url(#cc-visitedBaseGradient)',
      stroke: '#00ff88',
      strokeWidth: 2,
    },
    wrong: {
      top: 'url(#cc-wrongGradient)',
      base: 'url(#cc-wrongBaseGradient)',
      stroke: '#dc2626',
      strokeWidth: 2,
    },
  }
  return gradientMap[state]
}

/**
 * 3D hexagonal cell with poker chip effect (matching spec exactly)
 */
export default function HexCell({
  cx,
  cy,
  size = 42,
  state,
  expression,
  onClick,
  disabled = false,
}: HexCellProps) {
  const gradients = getGradients(state)

  // Poker chip layers with offsets matching spec
  const shadowPoints = getHexagonPoints(cx + 4, cy + 14, size)
  const edgePoints = getHexagonPoints(cx, cy + 12, size)
  const basePoints = getHexagonPoints(cx, cy + 6, size)
  const topPoints = getHexagonPoints(cx, cy, size)
  const innerPoints = getHexagonPoints(cx, cy, size * 0.9)

  const isClickable = onClick && !disabled
  const isPulsing = state === 'current' || state === 'start'

  // Get font size - smaller for FINISH text
  const getFontSize = () => {
    if (state === 'finish') return 13
    if (expression.length > 7) return 13
    if (expression.length > 5) return 15
    return 17
  }

  return (
    <g
      className={`hex-cell ${isClickable ? 'cursor-pointer' : ''} ${isPulsing ? 'cell-current' : ''}`}
      onClick={isClickable ? onClick : undefined}
      role={isClickable ? 'button' : undefined}
      tabIndex={isClickable ? 0 : undefined}
      aria-label={expression}
      style={{
        cursor: isClickable ? 'pointer' : 'default',
      }}
    >
      {/* Layer 1: Shadow */}
      <polygon points={shadowPoints} fill="rgba(0,0,0,0.6)" />

      {/* Layer 2: Edge */}
      <polygon points={edgePoints} fill="url(#cc-cellEdgeGradient)" />

      {/* Layer 3: Base */}
      <polygon points={basePoints} fill={gradients.base} />

      {/* Layer 4: Top face */}
      <polygon
        points={topPoints}
        fill={gradients.top}
        stroke={gradients.stroke}
        strokeWidth={gradients.strokeWidth}
      />

      {/* Pulsing glow for current/start cell */}
      {isPulsing && (
        <polygon
          points={topPoints}
          fill="none"
          stroke="#00ffc8"
          strokeWidth={4}
        >
          <animate
            attributeName="stroke-opacity"
            values="0.3;1;0.3"
            dur="1s"
            repeatCount="indefinite"
          />
          <animate
            attributeName="stroke-width"
            values="2;6;2"
            dur="1s"
            repeatCount="indefinite"
          />
        </polygon>
      )}

      {/* Layer 5: Inner shadow */}
      <polygon points={innerPoints} fill="url(#cc-cellInnerShadow)" />

      {/* Layer 6: Rim highlight */}
      <polygon
        points={topPoints}
        fill="none"
        stroke="rgba(255,255,255,0.2)"
        strokeWidth={1.5}
      />

      {/* Expression text */}
      <text
        x={cx}
        y={cy + 2}
        textAnchor="middle"
        dominantBaseline="middle"
        fontSize={getFontSize()}
        fontWeight="900"
        fill={state === 'finish' ? '#ffdd44' : '#ffffff'}
      >
        {expression}
      </text>
    </g>
  )
}
