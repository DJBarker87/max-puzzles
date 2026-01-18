import { useMemo } from 'react'
import './animations.css'

interface Star {
  id: number
  x: number
  y: number
  size: number
  twinkleDuration: number
  twinkleDelay: number
}

interface StarryBackgroundProps {
  starCount?: number
  className?: string
}

/**
 * Generate random stars for the background
 */
function generateStars(count: number = 80): Star[] {
  return Array.from({ length: count }, (_, i) => ({
    id: i,
    x: Math.random() * 100,
    y: Math.random() * 100,
    size: Math.random() < 0.6 ? 1 : Math.random() < 0.9 ? 2 : 3,
    twinkleDuration: 3 + Math.random() * 2, // 3-5 seconds
    twinkleDelay: Math.random() * 5, // 0-5 seconds
  }))
}

/**
 * Starry background for game screens
 */
export default function StarryBackground({
  starCount = 80,
  className = '',
}: StarryBackgroundProps) {
  const stars = useMemo(() => generateStars(starCount), [starCount])

  return (
    <div
      className={`fixed inset-0 overflow-hidden pointer-events-none z-0 ${className}`}
    >
      {/* Gradient background */}
      <div className="absolute inset-0 bg-gradient-to-br from-[#0a0a12] via-[#12121f] to-[#0d0d18]" />

      {/* Ambient glow */}
      <div
        className="absolute inset-0"
        style={{
          background:
            'radial-gradient(circle at 50% 50%, rgba(0,255,128,0.03) 0%, transparent 50%)',
        }}
      />

      {/* Stars */}
      {stars.map((star) => (
        <div
          key={star.id}
          className="absolute rounded-full bg-white animate-twinkle"
          style={
            {
              left: `${star.x}%`,
              top: `${star.y}%`,
              width: star.size,
              height: star.size,
              '--twinkle-duration': `${star.twinkleDuration}s`,
              animationDelay: `${star.twinkleDelay}s`,
            } as React.CSSProperties
          }
        />
      ))}
    </div>
  )
}
