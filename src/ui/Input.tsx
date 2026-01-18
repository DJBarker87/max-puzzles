import { forwardRef, InputHTMLAttributes } from 'react'

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  /** Label text */
  label?: string
  /** Error message */
  error?: string
  /** Helper text */
  helperText?: string
}

/**
 * Text input component
 */
const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, helperText, className = '', id, disabled, ...props }, ref) => {
    const inputId = id || `input-${Math.random().toString(36).slice(2, 9)}`

    return (
      <div className={`space-y-1.5 ${className}`}>
        {label && (
          <label
            htmlFor={inputId}
            className={`
              block font-display font-medium text-text-primary
              ${disabled ? 'opacity-50' : ''}
            `}
          >
            {label}
          </label>
        )}

        <input
          ref={ref}
          id={inputId}
          disabled={disabled}
          className={`
            w-full
            px-4 py-3
            bg-background-light
            border-2 rounded-xl
            font-body text-text-primary
            placeholder:text-text-secondary/50
            transition-colors duration-150
            focus:outline-none focus:ring-0
            disabled:opacity-50 disabled:cursor-not-allowed
            ${
              error
                ? 'border-error focus:border-error'
                : 'border-background-light focus:border-accent-primary'
            }
          `}
          {...props}
        />

        {(error || helperText) && (
          <p
            className={`
              text-sm font-body
              ${error ? 'text-error' : 'text-text-secondary'}
            `}
          >
            {error || helperText}
          </p>
        )}
      </div>
    )
  }
)

Input.displayName = 'Input'

export default Input
