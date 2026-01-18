import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth, type Child } from '@/app/providers/AuthProvider'
import Button from '@/ui/Button'
import Card from '@/ui/Card'
import PinEntryModal from '../components/PinEntryModal'

/**
 * Family member selection screen for logged-in families
 * Shows children cards and parent options
 */
export default function FamilySelectScreen() {
  const navigate = useNavigate()
  const { family, children, selectChild, enterDemoMode } = useAuth()

  const [selectedChild, setSelectedChild] = useState<Child | null>(null)
  const [showPinEntry, setShowPinEntry] = useState(false)
  const [pinError, setPinError] = useState<string | null>(null)

  const handleChildSelect = (child: Child) => {
    setSelectedChild(child)
    setPinError(null)
    setShowPinEntry(true)
  }

  const handlePinSubmit = async (pin: string) => {
    if (!selectedChild) return

    try {
      await selectChild(selectedChild.id, pin)
      navigate('/hub')
    } catch {
      setPinError('Wrong PIN. Try again!')
    }
  }

  const handleDemoMode = () => {
    enterDemoMode()
    navigate('/hub')
  }

  const handleClosePinEntry = () => {
    setShowPinEntry(false)
    setSelectedChild(null)
    setPinError(null)
  }

  return (
    <div className="min-h-screen flex flex-col p-4 bg-background-dark">
      {/* Header */}
      <header className="text-center py-8">
        <h1 className="text-2xl font-display font-bold mb-2">
          Who's Playing?
        </h1>
        <p className="text-text-secondary">
          {family?.name || 'Your Family'}
        </p>
      </header>

      {/* Children Grid */}
      <div className="flex-1 flex flex-wrap justify-center gap-4 py-4">
        {children.map(child => (
          <Card
            key={child.id}
            variant="interactive"
            className="w-32 h-40 flex flex-col items-center justify-center p-4 cursor-pointer"
            onClick={() => handleChildSelect(child)}
          >
            {/* Avatar */}
            <div className="text-5xl mb-2">
              {child.avatarEmoji || '👽'}
            </div>
            <p className="font-bold text-center truncate w-full">
              {child.displayName}
            </p>
          </Card>
        ))}

        {/* Add Child button (if less than max) */}
        {children.length < 5 && (
          <Card
            variant="interactive"
            className="w-32 h-40 flex flex-col items-center justify-center p-4 border-dashed border-2 border-background-light/50 cursor-pointer"
            onClick={() => navigate('/parent/add-child')}
          >
            <div className="text-4xl mb-2 text-text-secondary">+</div>
            <p className="text-text-secondary text-sm text-center">
              Add Child
            </p>
          </Card>
        )}
      </div>

      {/* Parent Options */}
      <div className="space-y-3 max-w-sm mx-auto w-full pb-8">
        <Button
          variant="secondary"
          fullWidth
          onClick={() => navigate('/parent/dashboard')}
        >
          Parent Dashboard
        </Button>

        <Button
          variant="ghost"
          fullWidth
          onClick={handleDemoMode}
        >
          Play as Parent (Demo)
        </Button>

        <Button
          variant="ghost"
          fullWidth
          onClick={() => navigate('/settings')}
        >
          Settings
        </Button>
      </div>

      {/* PIN Entry Modal */}
      <PinEntryModal
        isOpen={showPinEntry}
        onClose={handleClosePinEntry}
        childName={selectedChild?.displayName || ''}
        avatarEmoji={selectedChild?.avatarEmoji}
        onSubmit={handlePinSubmit}
        error={pinError}
      />
    </div>
  )
}
