import { forwardRef, InputHTMLAttributes } from 'react'

export interface SliderProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type' | 'onChange'> {
  /** Minimum value */
  min: number
  /** Maximum value */
  max: number
  /** Current value */
  value: number
  /** Callback when value changes */
  onChange: (value: number) => void
  /** Label text */
  label?: string
  /** Show current value */
  showValue?: boolean
  /** Step increment */
  step?: number
}

/**
 * Slider input component with large touch target
 */
const Slider = forwardRef<HTMLInputElement, SliderProps>(
  (
    {
      min,
      max,
      value,
      onChange,
      label,
      showValue = true,
      step = 1,
      disabled,
      className = '',
      id,
      ...props
    },
    ref
  ) => {
    const sliderId = id || `slider-${Math.random().toString(36).slice(2, 9)}`

    // Calculate fill percentage
    const fillPercent = ((value - min) / (max - min)) * 100

    return (
      <div className={`space-y-2 ${className}`}>
        {/* Label and value */}
        {(label || showValue) && (
          <div className="flex items-center justify-between">
            {label && (
              <label
                htmlFor={sliderId}
                className={`
                  font-display font-medium text-text-primary
                  ${disabled ? 'opacity-50' : ''}
                `}
              >
                {label}
              </label>
            )}
            {showValue && (
              <span
                className={`
                  font-display font-bold text-accent-primary
                  ${disabled ? 'opacity-50' : ''}
                `}
              >
                {value}
              </span>
            )}
          </div>
        )}

        {/* Slider track container */}
        <div className="relative h-8 flex items-center">
          {/* Background track */}
          <div
            className={`
              absolute inset-x-0
              h-3
              bg-background-light
              rounded-full
              ${disabled ? 'opacity-50' : ''}
            `}
          />

          {/* Filled track */}
          <div
            className={`
              absolute left-0
              h-3
              bg-accent-primary
              rounded-full
              transition-all duration-75
              ${disabled ? 'opacity-50' : ''}
            `}
            style={{ width: `${fillPercent}%` }}
          />

          {/* Input (invisible but handles interaction) */}
          <input
            ref={ref}
            type="range"
            id={sliderId}
            min={min}
            max={max}
            value={value}
            step={step}
            disabled={disabled}
            onChange={(e) => onChange(Number(e.target.value))}
            className={`
              absolute inset-0
              w-full h-full
              appearance-none
              bg-transparent
              cursor-pointer
              disabled:cursor-not-allowed

              [&::-webkit-slider-thumb]:appearance-none
              [&::-webkit-slider-thumb]:w-6
              [&::-webkit-slider-thumb]:h-6
              [&::-webkit-slider-thumb]:bg-white
              [&::-webkit-slider-thumb]:rounded-full
              [&::-webkit-slider-thumb]:shadow-lg
              [&::-webkit-slider-thumb]:shadow-black/30
              [&::-webkit-slider-thumb]:border-2
              [&::-webkit-slider-thumb]:border-accent-primary
              [&::-webkit-slider-thumb]:transition-transform
              [&::-webkit-slider-thumb]:duration-150
              [&::-webkit-slider-thumb]:hover:scale-110
              [&::-webkit-slider-thumb]:active:scale-95

              [&::-moz-range-thumb]:w-6
              [&::-moz-range-thumb]:h-6
              [&::-moz-range-thumb]:bg-white
              [&::-moz-range-thumb]:rounded-full
              [&::-moz-range-thumb]:shadow-lg
              [&::-moz-range-thumb]:border-2
              [&::-moz-range-thumb]:border-accent-primary
              [&::-moz-range-thumb]:transition-transform
              [&::-moz-range-thumb]:duration-150
              [&::-moz-range-thumb]:hover:scale-110
              [&::-moz-range-thumb]:active:scale-95

              focus:outline-none
              focus-visible:[&::-webkit-slider-thumb]:ring-2
              focus-visible:[&::-webkit-slider-thumb]:ring-accent-primary
              focus-visible:[&::-webkit-slider-thumb]:ring-offset-2
              focus-visible:[&::-webkit-slider-thumb]:ring-offset-background-dark
            `}
            {...props}
          />
        </div>
      </div>
    )
  }
)

Slider.displayName = 'Slider'

export default Slider
