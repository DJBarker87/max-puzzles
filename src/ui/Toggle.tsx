import { forwardRef, InputHTMLAttributes, useId } from 'react'

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
    const generatedId = useId()
    const toggleId = id || generatedId

    return (
      <label
        htmlFor={toggleId}
        className={`flex min-h-11 items-center gap-3 ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'} ${className}`}
      >
        {label && (
          <span className="font-display font-medium text-text-primary">
            {label}
          </span>
        )}

        <span
          className={`
            relative
            w-14 h-8
            rounded-full
            transition-colors duration-200 motion-reduce:transition-none
            has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-accent-primary has-[:focus-visible]:ring-offset-2 has-[:focus-visible]:ring-offset-background-dark
            ${checked ? 'bg-accent-primary' : 'bg-background-light'}
          `}
        >
          <input
            ref={ref}
            type="checkbox"
            role="switch"
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
              transition-transform duration-200 motion-reduce:transition-none
              ${checked ? 'translate-x-6' : 'translate-x-0'}
            `}
          />
        </span>
      </label>
    )
  }
)

Toggle.displayName = 'Toggle'

export default Toggle
