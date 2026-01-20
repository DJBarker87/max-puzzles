import { useEffect, useState } from 'react'

type AnimationStyle = 'float' | 'bounce' | 'breathe' | 'wiggle'

interface AnimatedAlienProps {
  src: string
  alt: string
  className?: string
  style?: AnimationStyle
  intensity?: number
}

/**
 * Animated alien image with idle animation effects
 */
export default function AnimatedAlien({
  src,
  alt,
  className = '',
  style = 'float',
  intensity = 1,
}: AnimatedAlienProps) {
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    // Start animations after mount
    setMounted(true)
  }, [])

  // Get animation class based on style
  const getAnimationClass = () => {
    if (!mounted) return ''

    switch (style) {
      case 'float':
        return 'animate-alien-float'
      case 'bounce':
        return 'animate-alien-bounce'
      case 'breathe':
        return 'animate-alien-breathe'
      case 'wiggle':
        return 'animate-alien-wiggle'
      default:
        return 'animate-alien-float'
    }
  }

  // Intensity affects animation scale via CSS custom property
  const animationStyle = {
    '--animation-intensity': intensity,
  } as React.CSSProperties

  return (
    <img
      src={src}
      alt={alt}
      className={`${className} ${getAnimationClass()}`}
      style={animationStyle}
    />
  )
}
