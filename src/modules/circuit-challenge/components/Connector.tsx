import type { ConnectorType } from '../types'
import './animations.css'

interface ConnectorProps {
  cellA: { x: number; y: number }
  cellB: { x: number; y: number }
  value: number
  type: ConnectorType
  isTraversed: boolean
  isWrong?: boolean
  animationDelay?: number
}

/**
 * Connector line between two cells with electric flow animation
 */
export default function Connector({
  cellA,
  cellB,
  value,
  isTraversed,
  isWrong = false,
  animationDelay = 0,
}: ConnectorProps) {
  // Calculate direction and shorten endpoints
  const dx = cellB.x - cellA.x
  const dy = cellB.y - cellA.y
  const length = Math.sqrt(dx * dx + dy * dy)
  const shortenBy = 25

  const ux = dx / length
  const uy = dy / length

  const x1 = cellA.x + ux * shortenBy
  const y1 = cellA.y + uy * shortenBy
  const x2 = cellB.x - ux * shortenBy
  const y2 = cellB.y - uy * shortenBy

  // Midpoint for value badge
  const midX = (x1 + x2) / 2
  const midY = (y1 + y2) / 2

  if (isWrong) {
    return (
      <g className="connector wrong">
        <line
          x1={x1} y1={y1} x2={x2} y2={y2}
          stroke="#ef4444"
          strokeWidth={8}
          strokeLinecap="round"
        />
        <rect
          x={midX - 16} y={midY - 14}
          width={32} height={28}
          rx={6}
          fill="#7f1d1d"
          stroke="#ef4444"
          strokeWidth={2}
        />
        <text
          x={midX} y={midY}
          textAnchor="middle"
          dominantBaseline="middle"
          fill="#ef4444"
          fontSize={14}
          fontWeight={800}
          style={{ fontFamily: 'system-ui, sans-serif' }}
        >
          {value}
        </text>
      </g>
    )
  }

  if (isTraversed) {
    return (
      <g className="connector traversed">
        {/* Layer 1: Glow */}
        <line
          x1={x1} y1={y1} x2={x2} y2={y2}
          stroke="#00ff88"
          strokeWidth={18}
          strokeLinecap="round"
          opacity={0.5}
          filter="url(#cc-connectorGlowFilter)"
          className="connector-glow"
        />

        {/* Layer 2: Main line */}
        <line
          x1={x1} y1={y1} x2={x2} y2={y2}
          stroke="#00dd77"
          strokeWidth={10}
          strokeLinecap="round"
        />

        {/* Layer 3: Energy flow slow */}
        <line
          x1={x1} y1={y1} x2={x2} y2={y2}
          stroke="#88ffcc"
          strokeWidth={6}
          strokeLinecap="round"
          strokeDasharray="6 30"
          className="energy-flow-slow"
          style={{ animationDelay: `${animationDelay}ms` }}
        />

        {/* Layer 4: Energy flow fast */}
        <line
          x1={x1} y1={y1} x2={x2} y2={y2}
          stroke="#ffffff"
          strokeWidth={4}
          strokeLinecap="round"
          strokeDasharray="4 20"
          className="energy-flow-fast"
          style={{ animationDelay: `${animationDelay + 200}ms` }}
        />

        {/* Layer 5: Bright core */}
        <line
          x1={x1} y1={y1} x2={x2} y2={y2}
          stroke="#aaffcc"
          strokeWidth={3}
          strokeLinecap="round"
        />

        {/* Value badge */}
        <rect
          x={midX - 16} y={midY - 14}
          width={32} height={28}
          rx={6}
          fill="#0a3020"
          stroke="#00ff88"
          strokeWidth={2}
        />
        <text
          x={midX} y={midY}
          textAnchor="middle"
          dominantBaseline="middle"
          fill="#00ff88"
          fontSize={14}
          fontWeight={800}
          style={{ fontFamily: 'system-ui, sans-serif' }}
        >
          {value}
        </text>
      </g>
    )
  }

  // Default inactive connector
  return (
    <g className="connector">
      <line
        x1={x1} y1={y1} x2={x2} y2={y2}
        stroke="#3d3428"
        strokeWidth={8}
        strokeLinecap="round"
      />
      <rect
        x={midX - 16} y={midY - 14}
        width={32} height={28}
        rx={6}
        fill="#15151f"
        stroke="#2a2a3a"
        strokeWidth={2}
      />
      <text
        x={midX} y={midY}
        textAnchor="middle"
        dominantBaseline="middle"
        fill="#ff9f43"
        fontSize={14}
        fontWeight={800}
        style={{ fontFamily: 'system-ui, sans-serif' }}
      >
        {value}
      </text>
    </g>
  )
}
