import { useState, FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import Button from '@/ui/Button'
import Card from '@/ui/Card'
import Input from '@/ui/Input'
import Header from '../components/Header'

/**
 * Add child screen - allows parents to add a new child account
 * Will be expanded in Phase 7 with full Supabase integration
 */
export default function AddChildScreen() {
  const navigate = useNavigate()

  const [displayName, setDisplayName] = useState('')
  const [pin, setPin] = useState('')
  const [confirmPin, setConfirmPin] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()

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

    setError(null)
    setIsLoading(true)

    try {
      // TODO: Implement actual child creation with Supabase
      console.log('Creating child:', displayName, 'with PIN')

      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 500))

      // Navigate back to family select
      navigate('/family-select')
    } catch {
      setError('Could not add child. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Add Child" showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-md mx-auto">
          <Card className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="text-center mb-4">
                <div className="text-5xl mb-2">👽</div>
                <p className="text-text-secondary text-sm">
                  Add a new player to your family
                </p>
              </div>

              <Input
                type="text"
                label="Child's Name"
                value={displayName}
                onChange={e => setDisplayName(e.target.value)}
                required
                autoFocus
                placeholder="e.g., Max"
              />

              <Input
                type="password"
                label="4-Digit PIN"
                value={pin}
                onChange={e => setPin(e.target.value.replace(/\D/g, '').slice(0, 4))}
                required
                placeholder="e.g., 1234"
                maxLength={4}
                inputMode="numeric"
                pattern="\d{4}"
              />

              <Input
                type="password"
                label="Confirm PIN"
                value={confirmPin}
                onChange={e => setConfirmPin(e.target.value.replace(/\D/g, '').slice(0, 4))}
                required
                placeholder="Re-enter PIN"
                maxLength={4}
                inputMode="numeric"
                pattern="\d{4}"
              />

              <p className="text-text-secondary text-xs">
                The PIN lets your child log in without a password.
                Make sure it's something they can remember!
              </p>

              {error && (
                <p className="text-error text-sm">{error}</p>
              )}

              <Button
                type="submit"
                variant="primary"
                fullWidth
                loading={isLoading}
              >
                Add Child
              </Button>
            </form>
          </Card>
        </div>
      </main>
    </div>
  )
}
