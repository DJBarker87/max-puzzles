import { useEffect, useState, useRef, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import { SplashBackground } from '@/modules/circuit-challenge/components'

// Particle type for assembly animation
interface Particle {
  id: number
  startX: number
  startY: number
  color: string
  size: number
  delay: number
}

/**
 * Generate particles that will converge to center
 */
function generateParticles(count: number): Particle[] {
  const colors = ['#00ff88', '#22c55e', '#ffffff']
  return Array.from({ length: count }, (_, i) => {
    const angle = (i / count) * 2 * Math.PI
    const distance = Math.max(window.innerWidth, window.innerHeight) * 0.7
    return {
      id: i,
      startX: window.innerWidth / 2 + Math.cos(angle) * distance,
      startY: window.innerHeight / 2 + Math.sin(angle) * distance,
      color: colors[Math.floor(Math.random() * colors.length)],
      size: 3 + Math.random() * 5,
      delay: i * 0.01,
    }
  })
}

/**
 * Premium splash screen with particle assembly animation
 */
export default function SplashScreen() {
  const navigate = useNavigate()
  const { user, isGuest, isLoading } = useAuth()

  // Animation phases
  const [phase, setPhase] = useState<'initial' | 'assembling' | 'revealing' | 'complete'>('initial')
  const [particleProgress, setParticleProgress] = useState(0)
  const [ringScale, setRingScale] = useState(0.5)
  const [ringOpacity, setRingOpacity] = useState(0)
  const [titleOpacity, setTitleOpacity] = useState(0)
  const [subtitleOpacity, setSubtitleOpacity] = useState(0)
  const [minTimeElapsed, setMinTimeElapsed] = useState(false)

  // Generate particles once
  const particles = useMemo(() => generateParticles(40), [])
  const canvasRef = useRef<HTMLCanvasElement>(null)

  // Draw particles on canvas
  useEffect(() => {
    if (phase !== 'assembling' && phase !== 'revealing') return

    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    // Set canvas size
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight

    const centerX = canvas.width / 2
    const centerY = canvas.height / 2 - 40

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height)

    // Draw each particle
    particles.forEach((particle) => {
      const adjustedProgress = Math.max(0, Math.min(1, (particleProgress - particle.delay) / (1 - particle.delay)))
      // Ease out quart
      const eased = 1 - Math.pow(1 - adjustedProgress, 4)

      const currentX = particle.startX + (centerX - particle.startX) * eased
      const currentY = particle.startY + (centerY - particle.startY) * eased

      const opacity = Math.min(1, particleProgress * 2) * (1 - particleProgress * 0.3)
      const particleSize = particle.size * (1 - particleProgress * 0.5)

      // Draw glow
      ctx.beginPath()
      ctx.arc(currentX, currentY, particleSize, 0, Math.PI * 2)
      ctx.fillStyle = particle.color.replace(')', `, ${opacity * 0.5})`).replace('rgb', 'rgba').replace('#', '')
      // Convert hex to rgba
      const r = parseInt(particle.color.slice(1, 3), 16)
      const g = parseInt(particle.color.slice(3, 5), 16)
      const b = parseInt(particle.color.slice(5, 7), 16)
      ctx.fillStyle = `rgba(${r}, ${g}, ${b}, ${opacity * 0.5})`
      ctx.fill()

      // Draw core
      ctx.beginPath()
      ctx.arc(currentX, currentY, particleSize * 0.5, 0, Math.PI * 2)
      ctx.fillStyle = `rgba(${r}, ${g}, ${b}, ${opacity})`
      ctx.fill()
    })
  }, [phase, particleProgress, particles])

  // Start premium animation sequence
  useEffect(() => {
    // Phase 1: Particle assembly (0 - 0.5s)
    setPhase('assembling')

    // Animate particle progress
    const startTime = Date.now()
    const duration = 500
    const animateParticles = () => {
      const elapsed = Date.now() - startTime
      const progress = Math.min(1, elapsed / duration)
      // Ease out
      const eased = 1 - Math.pow(1 - progress, 2)
      setParticleProgress(eased)
      if (progress < 1) {
        requestAnimationFrame(animateParticles)
      }
    }
    animateParticles()

    // Phase 2: Energy ring expands (0.3s - 0.8s)
    const ringTimer = setTimeout(() => {
      setPhase('revealing')
      setRingScale(3)
      setRingOpacity(0.5)
      setTimeout(() => setRingOpacity(0), 400)
    }, 300)

    // Phase 4: Title appears (0.4s - 0.8s)
    const titleTimer = setTimeout(() => {
      setTitleOpacity(1)
    }, 400)

    // Phase 5: Subtitle appears (0.7s - 1.0s)
    const subtitleTimer = setTimeout(() => {
      setSubtitleOpacity(1)
      setPhase('complete')
    }, 700)

    // Minimum display time
    const minTimer = setTimeout(() => {
      setMinTimeElapsed(true)
    }, 2000)

    return () => {
      clearTimeout(ringTimer)
      clearTimeout(titleTimer)
      clearTimeout(subtitleTimer)
      clearTimeout(minTimer)
    }
  }, [])

  // Navigate when ready
  useEffect(() => {
    if (!minTimeElapsed || isLoading) return

    // Check if first run
    const hasCompletedFirstRun = localStorage.getItem('hasCompletedFirstRun') === 'true'

    if (!hasCompletedFirstRun) {
      navigate('/first-run', { replace: true })
    } else if (user && user.role === 'parent') {
      navigate('/family-select', { replace: true })
    } else if (isGuest) {
      navigate('/hub', { replace: true })
    } else {
      navigate('/hub', { replace: true })
    }
  }, [minTimeElapsed, isLoading, user, isGuest, navigate])

  return (
    <div className="min-h-screen flex flex-col items-center justify-center relative overflow-hidden">
      <SplashBackground overlayOpacity={0.3} />

      {/* Energy ring expanding */}
      <div
        className="absolute pointer-events-none transition-all duration-600 ease-out"
        style={{
          width: 200 * ringScale,
          height: 200 * ringScale,
          border: `3px solid rgba(0, 255, 136, ${ringOpacity})`,
          borderRadius: '50%',
          filter: 'blur(4px)',
          transform: 'translate(-50%, -50%)',
          left: '50%',
          top: 'calc(50% - 40px)',
        }}
      />

      {/* Particle assembly canvas */}
      {(phase === 'assembling' || phase === 'revealing') && (
        <canvas
          ref={canvasRef}
          className="absolute inset-0 pointer-events-none"
          style={{ filter: 'blur(2px)' }}
        />
      )}

      {/* Main content */}
      <div className="relative z-10 flex flex-col items-center text-center px-4">
        {/* Title */}
        <h1
          className="text-4xl md:text-5xl font-bold mb-2 transition-opacity duration-500"
          style={{
            opacity: titleOpacity,
            textShadow: '0 2px 4px rgba(0,0,0,0.8), 0 0 12px rgba(0,255,136,0.6)',
            fontFamily: 'system-ui, -apple-system, sans-serif',
          }}
        >
          <span className="text-white">Maxi's Mighty</span>
          <br />
          <span className="text-white">Mindgames</span>
        </h1>

        {/* Subtitle */}
        <p
          className="text-lg text-white/95 transition-opacity duration-400"
          style={{
            opacity: subtitleOpacity,
            textShadow: '0 1px 3px rgba(0,0,0,0.7)',
          }}
        >
          Brain Training for Kids
        </p>
      </div>

      {/* Loading indicator */}
      <div className="absolute bottom-16 flex gap-2">
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            className="w-3 h-3 rounded-full bg-accent-primary animate-pulse"
            style={{
              animationDelay: `${i * 0.2}s`,
              boxShadow: '0 0 8px rgba(0, 255, 136, 0.5)',
            }}
          />
        ))}
      </div>
    </div>
  )
}
