import { useEffect, useRef, useState } from 'react'
import './animations.css'

interface LivesDisplayProps {
  lives: number
  maxLives?: number
  size?: 'sm' | 'md' | 'lg'
  vertical?: boolean
  className?: string
}

const sizes = {
  sm: { heart: 20, gap: 4 },
  md: { heart: 28, gap: 8 },
  lg: { heart: 36, gap: 10 },
}

interface HeartProps {
  active: boolean
  breaking?: boolean
  size: number
}

function Heart({ active, breaking, size }: HeartProps) {
  return (
    <svg
      viewBox="0 0 24 24"
      width={size}
      height={size}
      className={`
        transition-all duration-300
        ${active ? 'text-hearts-active' : 'text-hearts-inactive'}
        ${active && !breaking ? 'animate-heart-pulse' : ''}
        ${breaking ? 'animate-heart-break' : ''}
      `}
      style={{
        filter: active ? 'drop-shadow(0 0 8px rgba(255,51,102,0.6))' : 'none',
      }}
      fill="currentColor"
    >
      <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
    </svg>
  )
}

/**
 * Lives display with heart icons and break animation
 */
export default function LivesDisplay({
  lives,
  maxLives = 5,
  size = 'md',
  vertical = false,
  className = '',
}: LivesDisplayProps) {
  const prevLivesRef = useRef(lives)
  const [breakingIndex, setBreakingIndex] = useState<number | null>(null)

  useEffect(() => {
    if (lives < prevLivesRef.current) {
      // A life was lost
      setBreakingIndex(lives)
      const timer = setTimeout(() => setBreakingIndex(null), 500)
      return () => clearTimeout(timer)
    }
    prevLivesRef.current = lives
  }, [lives])

  const config = sizes[size]

  return (
    <div
      className={`flex items-center ${vertical ? 'flex-col' : ''} ${className}`}
      style={{ gap: config.gap }}
      role="status"
      aria-label={`${lives} of ${maxLives} lives remaining`}
    >
      {Array.from({ length: maxLives }, (_, i) => (
        <Heart
          key={i}
          active={i < lives}
          breaking={i === breakingIndex}
          size={config.heart}
        />
      ))}
    </div>
  )
}
