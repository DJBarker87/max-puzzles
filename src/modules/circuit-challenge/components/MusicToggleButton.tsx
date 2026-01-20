import { useSound } from '@/app/providers/SoundProvider'

interface MusicToggleButtonProps {
  /** Size variant */
  size?: 'sm' | 'md' | 'lg'
  /** Additional CSS classes */
  className?: string
}

/**
 * Button that toggles background music on/off
 * Shows a double music note icon that changes appearance based on mute state
 */
export function MusicToggleButton({ size = 'md', className = '' }: MusicToggleButtonProps) {
  const { isMuted, toggleMute } = useSound()

  const sizeClasses = {
    sm: 'w-10 h-10',
    md: 'w-12 h-12',
    lg: 'w-14 h-14',
  }

  const iconSizeClasses = {
    sm: 'w-5 h-5',
    md: 'w-6 h-6',
    lg: 'w-7 h-7',
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
        border border-white/10
        transition-all
        hover:scale-105
        active:scale-95
        ${className}
      `}
      aria-label={isMuted ? 'Turn music on' : 'Turn music off'}
      title={isMuted ? 'Turn music on' : 'Turn music off'}
    >
      {isMuted ? (
        // Muted - music notes with slash
        <svg className={`${iconSizeClasses[size]} text-text-secondary`} fill="currentColor" viewBox="0 0 24 24">
          <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z" />
          <path d="M3.27 1L2 2.27l9 9V16c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4v-1.73l5.73 5.73L22 20.73 3.27 1z" opacity="0.3" />
          <line x1="4" y1="4" x2="20" y2="20" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        </svg>
      ) : (
        // Not muted - double music notes
        <svg className={`${iconSizeClasses[size]} text-accent-primary`} fill="currentColor" viewBox="0 0 24 24">
          <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z" />
          <circle cx="10" cy="17" r="3" />
          <circle cx="19" cy="14" r="2.5" opacity="0.7" />
          <path d="M19 4v7.5M19 4h-3v3" opacity="0.7" />
        </svg>
      )}
    </button>
  )
}
