/**
 * Splash background with vibrant image and dark overlay
 * Used across splash screen, module menu, and setup screens
 */

interface SplashBackgroundProps {
  overlayOpacity?: number
  className?: string
}

export default function SplashBackground({
  overlayOpacity = 0.6,
  className = '',
}: SplashBackgroundProps) {
  return (
    <div className={`fixed inset-0 overflow-hidden ${className}`}>
      {/* Fallback gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-[#0a0a12] via-[#12121f] to-[#0d0d18]" />

      {/* Background image */}
      <img
        src="/splash_background.png"
        alt=""
        className="absolute inset-0 w-full h-full object-cover"
        style={{
          // Offset image slightly on mobile portrait to hide certain parts
          objectPosition: window.innerHeight > window.innerWidth ? '-80px center' : 'center',
        }}
      />

      {/* Dark overlay for text readability */}
      <div
        className="absolute inset-0"
        style={{ backgroundColor: `rgba(0, 0, 0, ${overlayOpacity})` }}
      />
    </div>
  )
}
