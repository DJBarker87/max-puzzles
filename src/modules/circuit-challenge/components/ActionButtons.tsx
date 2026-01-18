import { Button } from '@/ui'

interface ActionButtonsProps {
  onReset: () => void
  onNewPuzzle: () => void
  onChangeDifficulty: () => void
  onPrint: () => void
  onViewSolution?: () => void
  disabled?: boolean
  showViewSolution?: boolean
  className?: string
}

/**
 * Action buttons bar for gameplay controls
 */
export default function ActionButtons({
  onReset,
  onNewPuzzle,
  onChangeDifficulty,
  onPrint,
  onViewSolution,
  disabled = false,
  showViewSolution = false,
  className = '',
}: ActionButtonsProps) {
  const buttons = [
    { id: 'reset', icon: '🔄', label: 'Reset', onClick: onReset },
    { id: 'new', icon: '✨', label: 'New Puzzle', onClick: onNewPuzzle },
    { id: 'difficulty', icon: '⚙️', label: 'Difficulty', onClick: onChangeDifficulty },
    { id: 'print', icon: '🖨️', label: 'Print', onClick: onPrint },
  ]

  if (showViewSolution && onViewSolution) {
    buttons.push({ id: 'solution', icon: '👁️', label: 'Solution', onClick: onViewSolution })
  }

  return (
    <div
      className={`
        flex items-center justify-center gap-2 md:gap-4
        px-4 py-3
        bg-background-dark/80 backdrop-blur-sm
        border-t border-white/10
        ${className}
      `}
    >
      {buttons.map(btn => (
        <Button
          key={btn.id}
          variant="ghost"
          size="sm"
          onClick={btn.onClick}
          disabled={disabled}
          className="flex items-center gap-2 px-3 py-2 md:px-4"
          aria-label={btn.label}
        >
          <span className="text-lg">{btn.icon}</span>
          <span className="hidden md:inline text-sm">{btn.label}</span>
        </Button>
      ))}
    </div>
  )
}
