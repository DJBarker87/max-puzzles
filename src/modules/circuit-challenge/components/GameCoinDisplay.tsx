import './animations.css'

interface GameCoinDisplayProps {
  amount: number
  showChange?: { value: number; type: 'earn' | 'penalty' }
  size?: 'sm' | 'md' | 'lg'
  className?: string
}

const sizes = {
  sm: { icon: 18, text: 'text-base', padding: 'px-3 py-1.5' },
  md: { icon: 22, text: 'text-xl', padding: 'px-5 py-2.5' },
  lg: { icon: 28, text: 'text-2xl', padding: 'px-6 py-3' },
}

/**
 * Coin display with floating change animation for game header
 */
export default function GameCoinDisplay({
  amount,
  showChange,
  size = 'md',
  className = '',
}: GameCoinDisplayProps) {
  const config = sizes[size]

  return (
    <div
      className={`
        relative inline-flex items-center gap-2
        bg-gradient-to-br from-[#2a2518] to-[#1a1810]
        ${config.padding}
        rounded-full
        border border-accent-tertiary/30
        shadow-lg
        ${className}
      `}
    >
      <span
        style={{ fontSize: config.icon }}
        className="drop-shadow-[0_0_6px_rgba(251,191,36,0.5)]"
      >
        🪙
      </span>

      <span
        className={`
          font-bold text-accent-tertiary
          ${config.text}
          tabular-nums
        `}
      >
        {amount.toLocaleString()}
      </span>

      {showChange && (
        <span
          className={`
            absolute -top-2 left-1/2 -translate-x-1/2
            font-bold text-lg
            ${showChange.type === 'earn' ? 'text-accent-primary animate-float-up' : 'text-error animate-float-down'}
            pointer-events-none
          `}
        >
          {showChange.type === 'earn' ? '+' : ''}
          {showChange.value}
        </span>
      )}
    </div>
  )
}
