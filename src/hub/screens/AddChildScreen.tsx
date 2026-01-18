import { useState, FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import Button from '@/ui/Button'
import Card from '@/ui/Card'
import Header from '../components/Header'

// Avatar options for selection (V1 simple version)
const AVATAR_OPTIONS = ['👽', '🤖', '🦊', '🐱', '🐶', '🦁', '🐼', '🐸']

/**
 * Add child screen - Two-step flow: Name/Avatar then PIN
 */
export default function AddChildScreen() {
  const navigate = useNavigate()
  const { addChild, children } = useAuth()

  // Form state
  const [displayName, setDisplayName] = useState('')
  const [selectedAvatar, setSelectedAvatar] = useState(AVATAR_OPTIONS[0])
  const [pin, setPin] = useState('')
  const [confirmPin, setConfirmPin] = useState('')

  // UI state
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [step, setStep] = useState<'name' | 'pin'>('name')

  // Validation
  const isNameValid = displayName.trim().length >= 1 && displayName.trim().length <= 20
  const isPinValid = /^\d{4}$/.test(pin)
  const doPinsMatch = pin === confirmPin

  // Check for duplicate names
  const isDuplicateName = children.some(
    (c) => c.displayName.toLowerCase() === displayName.trim().toLowerCase()
  )

  // Weak PINs to reject
  const weakPins = ['0000', '1111', '1234', '4321', '0123', '9999']
  const isWeakPin = weakPins.includes(pin)

  // Handle name submission
  const handleNameSubmit = (e: FormEvent) => {
    e.preventDefault()
    setError(null)

    if (!displayName.trim()) {
      setError('Please enter a name')
      return
    }

    if (displayName.trim().length > 20) {
      setError('Name must be 20 characters or less')
      return
    }

    if (isDuplicateName) {
      setError('A child with this name already exists')
      return
    }

    // Move to PIN step
    setStep('pin')
  }

  // Handle final submission
  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)

    // Validate PIN
    if (pin.length !== 4) {
      setError('PIN must be exactly 4 digits')
      return
    }

    if (!/^\d{4}$/.test(pin)) {
      setError('PIN must contain only numbers')
      return
    }

    if (pin !== confirmPin) {
      setError('PINs do not match')
      return
    }

    if (isWeakPin) {
      setError('Please choose a stronger PIN')
      return
    }

    setIsLoading(true)

    try {
      const newChild = await addChild(displayName.trim(), pin)

      if (newChild) {
        // Success - navigate to dashboard
        navigate('/parent/dashboard', {
          state: { message: `${displayName} has been added!` },
        })
      } else {
        setError('Failed to add child. Please try again.')
      }
    } catch (err) {
      console.error('Error adding child:', err)
      setError('An error occurred. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  // Handle PIN input (digits only)
  const handlePinChange = (value: string, setter: (v: string) => void) => {
    const digitsOnly = value.replace(/\D/g, '').slice(0, 4)
    setter(digitsOnly)
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Add Child" showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-md mx-auto">
          {/* Progress Indicator */}
          <div className="flex items-center justify-center gap-2 mb-8">
            <div
              className={`w-3 h-3 rounded-full ${step === 'name' ? 'bg-accent-primary' : 'bg-accent-primary'}`}
            />
            <div className="w-8 h-0.5 bg-white/20" />
            <div
              className={`w-3 h-3 rounded-full ${step === 'pin' ? 'bg-accent-primary' : 'bg-white/20'}`}
            />
          </div>

          {/* Step 1: Name & Avatar */}
          {step === 'name' && (
            <Card className="p-6">
              <form onSubmit={handleNameSubmit}>
                {/* Avatar Selection */}
                <div className="text-center mb-6">
                  <div className="text-7xl mb-4">{selectedAvatar}</div>
                  <p className="text-sm text-text-secondary mb-3">Choose an avatar</p>
                  <div className="flex flex-wrap justify-center gap-2">
                    {AVATAR_OPTIONS.map((avatar) => (
                      <button
                        key={avatar}
                        type="button"
                        onClick={() => setSelectedAvatar(avatar)}
                        className={`
                          text-3xl p-2 rounded-lg transition-all
                          ${
                            selectedAvatar === avatar
                              ? 'bg-accent-primary/20 ring-2 ring-accent-primary'
                              : 'bg-background-dark hover:bg-background-light'
                          }
                        `}
                      >
                        {avatar}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Name Input */}
                <div className="mb-6">
                  <label className="block text-sm font-medium mb-2">What's their name?</label>
                  <input
                    type="text"
                    value={displayName}
                    onChange={(e) => setDisplayName(e.target.value)}
                    placeholder="e.g. Max"
                    maxLength={20}
                    autoFocus
                    className={`
                      w-full px-4 py-3 rounded-lg text-lg
                      bg-background-dark border-2
                      ${error ? 'border-error' : 'border-white/20 focus:border-accent-primary'}
                      outline-none transition-colors
                    `}
                  />
                  <div className="flex justify-between mt-1">
                    <span className="text-xs text-text-secondary">
                      {error || "This is how they'll appear in the app"}
                    </span>
                    <span className="text-xs text-text-secondary">{displayName.length}/20</span>
                  </div>
                </div>

                {/* Continue Button */}
                <Button type="submit" variant="primary" fullWidth disabled={!isNameValid || isDuplicateName}>
                  Continue
                </Button>
              </form>
            </Card>
          )}

          {/* Step 2: PIN Setup */}
          {step === 'pin' && (
            <Card className="p-6">
              <form onSubmit={handleSubmit}>
                {/* Header */}
                <div className="text-center mb-6">
                  <div className="text-5xl mb-2">{selectedAvatar}</div>
                  <h2 className="text-xl font-bold">{displayName}</h2>
                  <p className="text-sm text-text-secondary mt-1">
                    Create a 4-digit PIN for {displayName}
                  </p>
                </div>

                {/* PIN Input */}
                <div className="mb-4">
                  <label className="block text-sm font-medium mb-2">4-Digit PIN</label>
                  <input
                    type="password"
                    inputMode="numeric"
                    pattern="\d{4}"
                    maxLength={4}
                    value={pin}
                    onChange={(e) => handlePinChange(e.target.value, setPin)}
                    placeholder="••••"
                    autoFocus
                    className={`
                      w-full px-4 py-4 rounded-lg text-center text-3xl tracking-[0.5em]
                      bg-background-dark border-2
                      ${error && !isPinValid ? 'border-error' : 'border-white/20 focus:border-accent-primary'}
                      outline-none transition-colors font-mono
                    `}
                  />
                </div>

                {/* Confirm PIN Input */}
                <div className="mb-6">
                  <label className="block text-sm font-medium mb-2">Confirm PIN</label>
                  <input
                    type="password"
                    inputMode="numeric"
                    pattern="\d{4}"
                    maxLength={4}
                    value={confirmPin}
                    onChange={(e) => handlePinChange(e.target.value, setConfirmPin)}
                    placeholder="••••"
                    className={`
                      w-full px-4 py-4 rounded-lg text-center text-3xl tracking-[0.5em]
                      bg-background-dark border-2
                      ${error && !doPinsMatch ? 'border-error' : 'border-white/20 focus:border-accent-primary'}
                      outline-none transition-colors font-mono
                    `}
                  />
                </div>

                {/* PIN Strength Indicator */}
                {pin.length === 4 && (
                  <div className="mb-4 text-center">
                    {isWeakPin ? (
                      <span className="text-yellow-400 text-sm">⚠️ This PIN is too easy to guess</span>
                    ) : (
                      <span className="text-accent-primary text-sm">✓ Good PIN</span>
                    )}
                  </div>
                )}

                {/* Error Message */}
                {error && <p className="text-error text-sm text-center mb-4">{error}</p>}

                {/* Info Text */}
                <p className="text-xs text-text-secondary text-center mb-6">
                  {displayName} will use this PIN to log in and play. You can reset it anytime from
                  the parent dashboard.
                </p>

                {/* Buttons */}
                <div className="space-y-3">
                  <Button
                    type="submit"
                    variant="primary"
                    fullWidth
                    loading={isLoading}
                    disabled={!isPinValid || !doPinsMatch || isWeakPin || isLoading}
                  >
                    Add {displayName}
                  </Button>

                  <Button
                    type="button"
                    variant="ghost"
                    fullWidth
                    onClick={() => {
                      setStep('name')
                      setPin('')
                      setConfirmPin('')
                      setError(null)
                    }}
                    disabled={isLoading}
                  >
                    ← Back
                  </Button>
                </div>
              </form>
            </Card>
          )}

          {/* Child Limit Warning */}
          {children.length >= 4 && (
            <p className="text-center text-text-secondary text-sm mt-4">
              You can add up to 5 children per family.
            </p>
          )}
        </div>
      </main>
    </div>
  )
}
