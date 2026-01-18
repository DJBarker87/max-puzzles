import { HTMLAttributes, forwardRef } from 'react'

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  /** Card style variant */
  variant?: 'default' | 'elevated' | 'interactive'
  /** Padding size */
  padding?: 'sm' | 'md' | 'lg' | 'none'
}

/**
 * Card component for content containers
 */
const Card = forwardRef<HTMLDivElement, CardProps>(
  (
    {
      variant = 'default',
      padding = 'md',
      className = '',
      children,
      onClick,
      ...props
    },
    ref
  ) => {
    const baseStyles = `
      rounded-2xl
      bg-background-mid
      border border-background-light/30
      transition-all duration-200
    `

    const variantStyles = {
      default: '',
      elevated: `
        shadow-lg shadow-black/20
        translate-y-0
      `,
      interactive: `
        cursor-pointer
        hover:translate-y-[-2px]
        hover:shadow-lg hover:shadow-black/30
        hover:border-accent-primary/30
        active:translate-y-0
        active:shadow-md
      `,
    }

    const paddingStyles = {
      none: '',
      sm: 'p-3',
      md: 'p-4',
      lg: 'p-6',
    }

    // If variant is interactive and onClick is provided, make it focusable
    const interactiveProps =
      variant === 'interactive' && onClick
        ? {
            role: 'button',
            tabIndex: 0,
            onKeyDown: (e: React.KeyboardEvent) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault()
                onClick(e as unknown as React.MouseEvent<HTMLDivElement>)
              }
            },
          }
        : {}

    return (
      <div
        ref={ref}
        className={`
          ${baseStyles}
          ${variantStyles[variant]}
          ${paddingStyles[padding]}
          ${variant === 'interactive' ? 'focus:outline-none focus-visible:ring-2 focus-visible:ring-accent-primary focus-visible:ring-offset-2 focus-visible:ring-offset-background-dark' : ''}
          ${className}
        `}
        onClick={onClick}
        {...interactiveProps}
        {...props}
      >
        {children}
      </div>
    )
  }
)

Card.displayName = 'Card'

export default Card
