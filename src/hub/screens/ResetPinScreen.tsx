import { useState, FormEvent } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import Button from '@/ui/Button'
import Card from '@/ui/Card'
import Header from '../components/Header'
import { setChildPin } from '@/shared/services/auth'

/**
 * Reset PIN Screen - Reset a child's login PIN
 */
export default function ResetPinScreen() {
  const { childId } = useParams<{ childId: string }>()
  const navigate = useNavigate()
  const { children } = useAuth()

  // Find the child
  const child = children.find((c) => c.id === childId)

  // Form state
  const [newPin, setNewPin] = useState('')
  const [confirmPin, setConfirmPin] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [isSuccess, setIsSuccess] = useState(false)

  // Validation
  const isPinValid = /^\d{4}$/.test(newPin)
  const doPinsMatch = newPin === confirmPin
  const weakPins = ['0000', '1111', '1234', '4321', '0123', '9999']
  const isWeakPin = weakPins.includes(newPin)

  // Handle PIN input
  const handlePinChange = (value: string, setter: (v: string) => void) => {
    const digitsOnly = value.replace(/\D/g, '').slice(0, 4)
    setter(digitsOnly)
    setError(null)
  }

  // Handle submit
  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)

    if (!isPinValid) {
      setError('PIN must be exactly 4 digits')
      return
    }

    if (!doPinsMatch) {
      setError('PINs do not match')
      return
    }

    if (isWeakPin) {
      setError('Please choose a stronger PIN')
      return
    }

    if (!childId) {
      setError('Child not found')
      return
    }

    setIsLoading(true)

    try {
      const success = await setChildPin(childId, newPin)

      if (success) {
        setIsSuccess(true)
        setTimeout(() => {
          navigate(`/parent/child/${childId}`)
        }, 2000)
      } else {
        setError('Failed to reset PIN. Please try again.')
      }
    } catch (err) {
      console.error('Error resetting PIN:', err)
      setError('An error occurred. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  // Child not found
  if (!child) {
    return (
      <div className="min-h-screen flex flex-col bg-background-dark">
        <Header title="Reset PIN" showBack />
        <main className="flex-1 flex items-center justify-center">
          <p className="text-text-secondary">Child not found</p>
        </main>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Reset PIN" showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-md mx-auto">
          <Card className="p-6">
            {/* Success State */}
            {isSuccess ? (
              <div className="text-center py-8">
                <div className="text-6xl mb-4">🔐</div>
                <h2 className="text-xl font-bold text-accent-primary mb-2">PIN Updated!</h2>
                <p className="text-text-secondary">{child.displayName}'s new PIN is ready to use.</p>
              </div>
            ) : (
              <form onSubmit={handleSubmit}>
                {/* Header */}
                <div className="text-center mb-6">
                  <div className="text-5xl mb-2">🔑</div>
                  <h2 className="text-xl font-bold">Reset PIN</h2>
                  <p className="text-sm text-text-secondary mt-1">
                    Create a new 4-digit PIN for {child.displayName}
                  </p>
                </div>

                {/* New PIN */}
                <div className="mb-4">
                  <label className="block text-sm font-medium mb-2">New PIN</label>
                  <input
                    type="password"
                    inputMode="numeric"
                    pattern="\d{4}"
                    maxLength={4}
                    value={newPin}
                    onChange={(e) => handlePinChange(e.target.value, setNewPin)}
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

                {/* Confirm PIN */}
                <div className="mb-4">
                  <label className="block text-sm font-medium mb-2">Confirm New PIN</label>
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

                {/* PIN Feedback */}
                {newPin.length === 4 && (
                  <div className="text-center mb-4">
                    {isWeakPin ? (
                      <span className="text-yellow-400 text-sm">⚠️ This PIN is too easy to guess</span>
                    ) : doPinsMatch ? (
                      <span className="text-accent-primary text-sm">✓ PINs match</span>
                    ) : confirmPin.length === 4 ? (
                      <span className="text-error text-sm">✗ PINs don't match</span>
                    ) : null}
                  </div>
                )}

                {/* Error */}
                {error && <p className="text-error text-sm text-center mb-4">{error}</p>}

                {/* Info */}
                <p className="text-xs text-text-secondary text-center mb-6">
                  Make sure to tell {child.displayName} their new PIN so they can log in.
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
                    Reset PIN
                  </Button>

                  <Button
                    type="button"
                    variant="ghost"
                    fullWidth
                    onClick={() => navigate(-1)}
                    disabled={isLoading}
                  >
                    Cancel
                  </Button>
                </div>
              </form>
            )}
          </Card>
        </div>
      </main>
    </div>
  )
}
