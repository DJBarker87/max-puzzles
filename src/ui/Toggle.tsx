import { forwardRef, InputHTMLAttributes } from 'react'

export interface ToggleProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type' | 'onChange'> {
  /** Whether the toggle is checked */
  checked: boolean
  /** Callback when toggle state changes */
  onChange: (checked: boolean) => void
  /** Label text */
  label?: string
}

/**
 * Toggle switch component (child-friendly, large touch target)
 */
const Toggle = forwardRef<HTMLInputElement, ToggleProps>(
  ({ checked, onChange, label, disabled, className = '', id, ...props }, ref) => {
    const toggleId = id || `toggle-${Math.random().toString(36).slice(2, 9)}`

    return (
      <div className={`flex items-center gap-3 ${className}`}>
        {label && (
          <label
            htmlFor={toggleId}
            className={`
              font-display font-medium text-text-primary
              ${disabled ? 'opacity-50' : 'cursor-pointer'}
            `}
          >
            {label}
          </label>
        )}

        <button
          type="button"
          role="switch"
          aria-checked={checked}
          disabled={disabled}
          onClick={() => !disabled && onChange(!checked)}
          className={`
            relative
            w-14 h-8
            rounded-full
            transition-colors duration-200
            focus:outline-none focus-visible:ring-2 focus-visible:ring-accent-primary focus-visible:ring-offset-2 focus-visible:ring-offset-background-dark
            ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
            ${checked ? 'bg-accent-primary' : 'bg-background-light'}
          `}
        >
          {/* Hidden input for form compatibility */}
          <input
            ref={ref}
            type="checkbox"
            id={toggleId}
            checked={checked}
            onChange={(e) => onChange(e.target.checked)}
            disabled={disabled}
            className="sr-only"
            {...props}
          />

          {/* Toggle thumb */}
          <span
            className={`
              absolute top-1 left-1
              w-6 h-6
              bg-white
              rounded-full
              shadow-md
              transition-transform duration-200
              ${checked ? 'translate-x-6' : 'translate-x-0'}
            `}
          />
        </button>
      </div>
    )
  }
)

Toggle.displayName = 'Toggle'

export default Toggle
