import { useState, useEffect, useCallback } from 'react'
import Modal from '@/ui/Modal'

export interface PinEntryModalProps {
  /** Whether the modal is open */
  isOpen: boolean
  /** Callback when modal should close */
  onClose: () => void
  /** Child's display name */
  childName: string
  /** Callback when PIN is submitted */
  onSubmit: (pin: string) => void
  /** Error message to display */
  error?: string | null
  /** Child's avatar emoji (optional) */
  avatarEmoji?: string
}

/**
 * PIN entry modal for child authentication
 * Features a number pad and auto-submit on 4 digits
 */
export default function PinEntryModal({
  isOpen,
  onClose,
  childName,
  onSubmit,
  error,
  avatarEmoji = '👽',
}: PinEntryModalProps) {
  const [pin, setPin] = useState('')
  const [isShaking, setIsShaking] = useState(false)

  // Reset PIN when modal opens/closes
  useEffect(() => {
    if (isOpen) {
      setPin('')
    }
  }, [isOpen])

  // Handle error with shake animation
  useEffect(() => {
    if (error) {
      setIsShaking(true)
      setPin('')
      const timer = setTimeout(() => setIsShaking(false), 300)
      return () => clearTimeout(timer)
    }
  }, [error])

  const handleKeyPress = useCallback((key: number | string | null) => {
    if (key === null) return

    if (key === 'back') {
      setPin(prev => prev.slice(0, -1))
      return
    }

    if (pin.length >= 4) return

    const newPin = pin + key.toString()
    setPin(newPin)

    // Auto-submit on 4 digits
    if (newPin.length === 4) {
      onSubmit(newPin)
    }
  }, [pin, onSubmit])

  // Keyboard support
  useEffect(() => {
    if (!isOpen) return

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key >= '0' && e.key <= '9') {
        handleKeyPress(parseInt(e.key, 10))
      } else if (e.key === 'Backspace') {
        handleKeyPress('back')
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [isOpen, handleKeyPress])

  // Number pad buttons
  const numberPad = [1, 2, 3, 4, 5, 6, 7, 8, 9, null, 0, 'back'] as const

  return (
    <Modal isOpen={isOpen} onClose={onClose} size="sm" showCloseButton={false}>
      <div className="text-center">
        {/* Child avatar/name */}
        <div className="text-5xl mb-2">{avatarEmoji}</div>
        <h2 className="text-xl font-bold mb-6">{childName}</h2>

        {/* PIN dots display */}
        <div
          className={`flex justify-center gap-3 mb-6 ${isShaking ? 'animate-shake' : ''}`}
        >
          {[0, 1, 2, 3].map(i => (
            <div
              key={i}
              className={`
                w-4 h-4 rounded-full border-2
                ${i < pin.length
                  ? 'bg-accent-primary border-accent-primary'
                  : 'border-white/30'}
                transition-all duration-150
              `}
            />
          ))}
        </div>

        {/* Error message */}
        {error && (
          <p className="text-error text-sm mb-4">{error}</p>
        )}

        {/* Hint text */}
        {!error && (
          <p className="text-text-secondary text-sm mb-4">
            Enter your 4-digit PIN
          </p>
        )}

        {/* Number pad */}
        <div className="grid grid-cols-3 gap-3 max-w-[240px] mx-auto">
          {numberPad.map((num, i) => (
            <button
              key={i}
              type="button"
              onClick={() => handleKeyPress(num)}
              disabled={num === null}
              className={`
                h-14 rounded-xl font-bold text-xl
                ${num === null
                  ? 'invisible'
                  : num === 'back'
                    ? 'bg-background-dark text-text-secondary hover:bg-background-light hover:text-text-primary'
                    : 'bg-background-dark hover:bg-background-light active:scale-95'}
                transition-all duration-150
                focus:outline-none focus-visible:ring-2 focus-visible:ring-accent-primary
              `}
            >
              {num === 'back' ? '←' : num}
            </button>
          ))}
        </div>

        {/* Cancel button */}
        <button
          type="button"
          onClick={onClose}
          className="mt-6 text-text-secondary underline hover:text-text-primary transition-colors"
        >
          Cancel
        </button>
      </div>
    </Modal>
  )
}
