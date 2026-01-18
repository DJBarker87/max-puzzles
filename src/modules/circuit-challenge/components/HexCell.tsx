import type { CellState } from '../types'

interface HexCellProps {
  cx: number
  cy: number
  size?: number
  state: CellState
  expression: string
  label?: string
  onClick?: () => void
  disabled?: boolean
  showAnswer?: boolean
  answer?: number
}

/**
 * Generate a flat-top hexagon path
 */
function getHexagonPath(cx: number, cy: number, radius: number): string {
  const points: [number, number][] = []
  for (let i = 0; i < 6; i++) {
    const angle = (Math.PI / 3) * i - Math.PI / 6
    const x = cx + radius * Math.cos(angle)
    const y = cy + radius * Math.sin(angle)
    points.push([x, y])
  }
  return `M ${points.map(p => p.join(',')).join(' L ')} Z`
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
 * 3D hexagonal cell with poker chip effect
 */
export default function HexCell({
  cx,
  cy,
  size = 40,
  state,
  expression,
  label,
  onClick,
  disabled = false,
}: HexCellProps) {
  const gradients = getGradients(state)
  const shadowPath = getHexagonPath(cx + 4, cy + 14, size)
  const edgePath = getHexagonPath(cx, cy + 12, size)
  const basePath = getHexagonPath(cx, cy + 6, size)
  const topPath = getHexagonPath(cx, cy, size)
  const innerPath = getHexagonPath(cx, cy, size * 0.85)

  const isClickable = onClick && !disabled
  const animationClass = state === 'current' ? 'cell-current' : state === 'visited' ? 'cell-visited' : ''

  // Get text color based on state
  const getTextColor = () => {
    if (state === 'finish') return '#ffdd44'
    if (label === 'START') return '#00ff88'
    if (label === 'FINISH') return '#ffcc00'
    if (state === 'visited') return 'rgba(255,255,255,0.7)'
    return '#ffffff'
  }

  // Adjust font size for long expressions
  const fontSize = expression.length > 7 ? 13 : expression.length > 5 ? 15 : 17

  return (
    <g
      className={`hex-cell ${animationClass} ${isClickable ? 'cursor-pointer' : ''}`}
      onClick={isClickable ? onClick : undefined}
      role={isClickable ? 'button' : undefined}
      tabIndex={isClickable ? 0 : undefined}
      aria-label={label || expression}
      style={{
        cursor: isClickable ? 'pointer' : 'default',
        opacity: disabled && !isClickable ? 0.5 : 1,
      }}
    >
      {/* Layer 1: Shadow */}
      <path d={shadowPath} fill="rgba(0,0,0,0.6)" />

      {/* Layer 2: Edge */}
      <path d={edgePath} fill="url(#cc-cellEdgeGradient)" />

      {/* Layer 3: Base */}
      <path d={basePath} fill={gradients.base} />

      {/* Layer 4: Top face */}
      <path
        d={topPath}
        fill={gradients.top}
        stroke={gradients.stroke}
        strokeWidth={gradients.strokeWidth}
      />

      {/* Layer 5: Inner shadow */}
      <path d={innerPath} fill="url(#cc-cellInnerShadow)" />

      {/* Layer 6: Rim highlight */}
      <path
        d={topPath}
        fill="none"
        stroke="rgba(255,255,255,0.2)"
        strokeWidth={1.5}
      />

      {/* Label (START/FINISH) */}
      {label && (
        <text
          x={cx}
          y={cy - 10}
          textAnchor="middle"
          fontSize={11}
          fontWeight={700}
          letterSpacing={2}
          fill={label === 'START' ? '#00ff88' : '#ffcc00'}
          style={{ fontFamily: 'system-ui, sans-serif' }}
        >
          {label}
        </text>
      )}

      {/* Expression or answer */}
      <text
        x={cx}
        y={label ? cy + 8 : cy + 5}
        textAnchor="middle"
        dominantBaseline="middle"
        fontSize={fontSize}
        fontWeight={700}
        fill={getTextColor()}
        style={{ fontFamily: 'system-ui, sans-serif' }}
      >
        {expression}
      </text>
    </g>
  )
}
