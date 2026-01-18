import { useState, useEffect, FormEvent } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import Button from '@/ui/Button'
import Card from '@/ui/Card'
import Header from '../components/Header'
import { supabase } from '@/shared/services/supabase'

/**
 * Edit Child Screen - Edit a child's display name
 */
export default function EditChildScreen() {
  const { childId } = useParams<{ childId: string }>()
  const navigate = useNavigate()
  const { children } = useAuth()

  // Find the child
  const child = children.find((c) => c.id === childId)

  // Form state
  const [displayName, setDisplayName] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [isSaved, setIsSaved] = useState(false)

  // Initialize form with current name
  useEffect(() => {
    if (child) {
      setDisplayName(child.displayName)
    }
  }, [child])

  // Validation
  const isValid = displayName.trim().length >= 1 && displayName.trim().length <= 20
  const hasChanged = child && displayName.trim() !== child.displayName

  // Check for duplicates (excluding current child)
  const isDuplicate = children.some(
    (c) => c.id !== childId && c.displayName.toLowerCase() === displayName.trim().toLowerCase()
  )

  // Handle save
  const handleSave = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)

    if (!displayName.trim()) {
      setError('Name cannot be empty')
      return
    }

    if (displayName.trim().length > 20) {
      setError('Name must be 20 characters or less')
      return
    }

    if (isDuplicate) {
      setError('Another child already has this name')
      return
    }

    if (!hasChanged) {
      navigate(-1)
      return
    }

    setIsLoading(true)

    try {
      if (!supabase || !childId) {
        throw new Error('Unable to save')
      }

      const { error: updateError } = await supabase
        .from('users')
        .update({ display_name: displayName.trim() })
        .eq('id', childId)

      if (updateError) {
        throw updateError
      }

      // Show success briefly then navigate
      setIsSaved(true)
      setTimeout(() => {
        navigate(`/parent/child/${childId}`)
      }, 1000)
    } catch (err) {
      console.error('Error updating child:', err)
      setError('Failed to save changes. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  // Child not found
  if (!child) {
    return (
      <div className="min-h-screen flex flex-col bg-background-dark">
        <Header title="Edit Profile" showBack />
        <main className="flex-1 flex items-center justify-center">
          <p className="text-text-secondary">Child not found</p>
        </main>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Edit Profile" showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-md mx-auto">
          <Card className="p-6">
            {/* Success State */}
            {isSaved ? (
              <div className="text-center py-8">
                <div className="text-5xl mb-4">✓</div>
                <h2 className="text-xl font-bold text-accent-primary">Saved!</h2>
              </div>
            ) : (
              <form onSubmit={handleSave}>
                {/* Avatar Display */}
                <div className="text-center mb-6">
                  <div className="text-6xl mb-2">👽</div>
                  <p className="text-sm text-text-secondary">Editing {child.displayName}'s profile</p>
                </div>

                {/* Name Input */}
                <div className="mb-6">
                  <label className="block text-sm font-medium mb-2">Display Name</label>
                  <input
                    type="text"
                    value={displayName}
                    onChange={(e) => setDisplayName(e.target.value)}
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
                    {error ? (
                      <span className="text-xs text-error">{error}</span>
                    ) : (
                      <span className="text-xs text-text-secondary">
                        {hasChanged ? 'Unsaved changes' : 'No changes'}
                      </span>
                    )}
                    <span className="text-xs text-text-secondary">{displayName.length}/20</span>
                  </div>
                </div>

                {/* Buttons */}
                <div className="space-y-3">
                  <Button
                    type="submit"
                    variant="primary"
                    fullWidth
                    loading={isLoading}
                    disabled={!isValid || isDuplicate || isLoading}
                  >
                    {hasChanged ? 'Save Changes' : 'No Changes'}
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
