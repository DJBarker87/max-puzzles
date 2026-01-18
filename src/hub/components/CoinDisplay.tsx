export interface CoinDisplayProps {
  /** Coin amount to display */
  amount: number
  /** Size variant */
  size?: 'sm' | 'md' | 'lg'
  /** Additional CSS classes */
  className?: string
}

const sizes = {
  sm: { icon: 16, text: 'text-sm', padding: 'px-2.5 py-1' },
  md: { icon: 20, text: 'text-base', padding: 'px-3 py-1.5' },
  lg: { icon: 24, text: 'text-lg', padding: 'px-4 py-2' },
}

/**
 * Coin display component for showing user's coin balance
 * Used in the hub header and other places
 */
export default function CoinDisplay({
  amount,
  size = 'md',
  className = '',
}: CoinDisplayProps) {
  const sizeConfig = sizes[size]

  return (
    <div
      className={`
        inline-flex items-center gap-1.5
        bg-gradient-to-br from-[#2a2518] to-[#1a1810]
        ${sizeConfig.padding}
        rounded-full
        border border-accent-tertiary/30
        ${className}
      `}
    >
      <span style={{ fontSize: sizeConfig.icon }}>🪙</span>
      <span
        className={`
          font-bold text-accent-tertiary tabular-nums
          ${sizeConfig.text}
        `}
      >
        {amount.toLocaleString()}
      </span>
    </div>
  )
}
