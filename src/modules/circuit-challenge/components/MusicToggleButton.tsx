import { useSound } from '@/app/providers/SoundProvider'

interface MusicToggleButtonProps {
  /** Size variant */
  size?: 'sm' | 'md' | 'lg'
  /** Additional CSS classes */
  className?: string
}

/**
 * Button that toggles background music on/off
 * Shows a musical note icon that changes appearance based on mute state
 */
export function MusicToggleButton({ size = 'md', className = '' }: MusicToggleButtonProps) {
  const { isMuted, toggleMute } = useSound()

  const sizeClasses = {
    sm: 'w-8 h-8 text-base',
    md: 'w-10 h-10 text-xl',
    lg: 'w-12 h-12 text-2xl',
  }

  return (
    <button
      onClick={toggleMute}
      className={`
        ${sizeClasses[size]}
        flex items-center justify-center
        rounded-full
        bg-background-mid/80
        hover:bg-background-mid
        transition-colors
        ${className}
      `}
      aria-label={isMuted ? 'Turn music on' : 'Turn music off'}
      title={isMuted ? 'Turn music on' : 'Turn music off'}
    >
      {isMuted ? (
        <span className="text-text-secondary">🔇</span>
      ) : (
        <span className="text-accent-primary">🎵</span>
      )}
    </button>
  )
}
