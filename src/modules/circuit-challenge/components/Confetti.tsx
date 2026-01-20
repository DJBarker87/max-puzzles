import { useEffect, useState, useMemo } from 'react'

interface ConfettiParticle {
  id: number
  x: number
  color: string
  size: number
  shape: 'rectangle' | 'circle' | 'triangle'
  delay: number
  duration: number
  drift: number
  rotation: number
}

const COLORS = [
  '#22c55e', // Green
  '#fbbf24', // Gold
  '#e94560', // Pink
  '#3b82f6', // Blue
  '#a855f7', // Purple
  '#f97316', // Orange
]

const SHAPES: ConfettiParticle['shape'][] = ['rectangle', 'circle', 'triangle']

/**
 * Confetti celebration animation
 * Particles fall from the top with rotation and drift
 */
export function Confetti({ particleCount = 80 }: { particleCount?: number }) {
  const [isVisible, setIsVisible] = useState(true)

  const particles = useMemo<ConfettiParticle[]>(() => {
    return Array.from({ length: particleCount }, (_, i) => ({
      id: i,
      x: Math.random() * 100, // percentage
      color: COLORS[Math.floor(Math.random() * COLORS.length)],
      size: 8 + Math.random() * 8,
      shape: SHAPES[Math.floor(Math.random() * SHAPES.length)],
      delay: Math.random() * 0.5,
      duration: 2 + Math.random() * 1.5,
      drift: (Math.random() - 0.5) * 100,
      rotation: Math.random() * 720,
    }))
  }, [particleCount])

  useEffect(() => {
    // Hide after animation completes
    const timer = setTimeout(() => {
      setIsVisible(false)
    }, 4000)
    return () => clearTimeout(timer)
  }, [])

  if (!isVisible) return null

  return (
    <div className="fixed inset-0 pointer-events-none z-50 overflow-hidden">
      {particles.map((particle) => (
        <ConfettiPiece key={particle.id} particle={particle} />
      ))}
    </div>
  )
}

function ConfettiPiece({ particle }: { particle: ConfettiParticle }) {
  return (
    <div
      className="absolute animate-confetti-fall"
      style={{
        left: `${particle.x}%`,
        top: -20,
        animationDelay: `${particle.delay}s`,
        animationDuration: `${particle.duration}s`,
        '--confetti-drift': `${particle.drift}px`,
        '--confetti-rotation': `${particle.rotation}deg`,
      } as React.CSSProperties}
    >
      {particle.shape === 'rectangle' && (
        <div
          className="animate-confetti-spin"
          style={{
            width: particle.size,
            height: particle.size * 0.6,
            backgroundColor: particle.color,
            animationDelay: `${particle.delay}s`,
          }}
        />
      )}
      {particle.shape === 'circle' && (
        <div
          className="rounded-full animate-confetti-spin"
          style={{
            width: particle.size * 0.8,
            height: particle.size * 0.8,
            backgroundColor: particle.color,
            animationDelay: `${particle.delay}s`,
          }}
        />
      )}
      {particle.shape === 'triangle' && (
        <div
          className="animate-confetti-spin"
          style={{
            width: 0,
            height: 0,
            borderLeft: `${particle.size / 2}px solid transparent`,
            borderRight: `${particle.size / 2}px solid transparent`,
            borderBottom: `${particle.size}px solid ${particle.color}`,
            animationDelay: `${particle.delay}s`,
          }}
        />
      )}
    </div>
  )
}
