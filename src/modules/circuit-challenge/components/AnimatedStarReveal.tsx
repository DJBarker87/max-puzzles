import { useState, useEffect } from 'react'

interface AnimatedStarRevealProps {
  starsEarned: number
  totalStars?: number
  starSize?: 'sm' | 'md' | 'lg'
  delay?: number
}

/**
 * Animated star reveal that shows stars popping in one-by-one with bounce effect
 */
export default function AnimatedStarReveal({
  starsEarned,
  totalStars = 3,
  starSize = 'md',
  delay = 300,
}: AnimatedStarRevealProps) {
  const [revealedStars, setRevealedStars] = useState<boolean[]>([])
  const [animatingStars, setAnimatingStars] = useState<boolean[]>([])

  // Size configurations
  const sizeConfig = {
    sm: { fontSize: 'text-xl', gap: 'gap-1', sparkleSize: 2 },
    md: { fontSize: 'text-4xl', gap: 'gap-2', sparkleSize: 4 },
    lg: { fontSize: 'text-5xl', gap: 'gap-3', sparkleSize: 6 },
  }

  const config = sizeConfig[starSize]

  useEffect(() => {
    // Initialize arrays
    const initialRevealed = Array(totalStars).fill(false)
    const initialAnimating = Array(totalStars).fill(false)

    // Show empty stars immediately
    for (let i = starsEarned; i < totalStars; i++) {
      initialRevealed[i] = true
    }

    setRevealedStars(initialRevealed)
    setAnimatingStars(initialAnimating)

    // Animate each earned star with staggered delay
    for (let i = 0; i < starsEarned; i++) {
      const starDelay = delay + i * 400

      setTimeout(() => {
        // Start animation
        setAnimatingStars((prev) => {
          const next = [...prev]
          next[i] = true
          return next
        })

        // Reveal the star
        setRevealedStars((prev) => {
          const next = [...prev]
          next[i] = true
          return next
        })

        // End animation after bounce
        setTimeout(() => {
          setAnimatingStars((prev) => {
            const next = [...prev]
            next[i] = false
            return next
          })
        }, 500)
      }, starDelay)
    }
  }, [starsEarned, totalStars, delay])

  return (
    <div className={`flex justify-center ${config.gap}`}>
      {Array.from({ length: totalStars }).map((_, index) => {
        const isEarned = index < starsEarned
        const isRevealed = revealedStars[index]
        const isAnimating = animatingStars[index]

        return (
          <div key={index} className="relative">
            {/* Sparkle burst effect */}
            {isEarned && isAnimating && (
              <div className="absolute inset-0 flex items-center justify-center">
                {[...Array(8)].map((_, sparkleIndex) => {
                  const angle = (sparkleIndex / 8) * Math.PI * 2
                  const distance = 24
                  const x = Math.cos(angle) * distance
                  const y = Math.sin(angle) * distance

                  return (
                    <div
                      key={sparkleIndex}
                      className="absolute w-1 h-1 bg-yellow-300 rounded-full animate-ping"
                      style={{
                        transform: `translate(${x}px, ${y}px)`,
                        animationDuration: '0.5s',
                      }}
                    />
                  )
                })}
              </div>
            )}

            {/* Glow effect */}
            {isEarned && isRevealed && (
              <div
                className={`absolute inset-0 flex items-center justify-center ${config.fontSize}`}
                style={{
                  filter: 'blur(8px)',
                  opacity: 0.5,
                }}
              >
                <span className="text-yellow-400">⭐</span>
              </div>
            )}

            {/* The star */}
            <span
              className={`
                ${config.fontSize}
                inline-block
                transition-all duration-300
                ${isEarned && isRevealed ? 'opacity-100' : isEarned ? 'opacity-0' : 'opacity-30'}
                ${isAnimating ? 'scale-125' : 'scale-100'}
                ${isAnimating ? 'animate-bounce' : ''}
              `}
              style={{
                animationDuration: isAnimating ? '0.5s' : undefined,
                animationIterationCount: isAnimating ? '1' : undefined,
              }}
            >
              ⭐
            </span>
          </div>
        )
      })}
    </div>
  )
}
