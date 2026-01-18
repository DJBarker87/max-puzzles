import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import Button from '@/ui/Button'
import Card from '@/ui/Card'
import Modal from '@/ui/Modal'
import Header from '../components/Header'

/**
 * Parent Settings Screen - Family management and account settings
 */
export default function ParentSettingsScreen() {
  const navigate = useNavigate()
  const { user, family, children, logout } = useAuth()

  // Modal states
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [showResetConfirm, setShowResetConfirm] = useState(false)
  const [deleteConfirmText, setDeleteConfirmText] = useState('')

  // Loading states
  const [isLoggingOut, setIsLoggingOut] = useState(false)

  // Handle logout
  const handleLogout = async () => {
    setIsLoggingOut(true)
    try {
      await logout()
      navigate('/login')
    } catch (err) {
      console.error('Logout error:', err)
    } finally {
      setIsLoggingOut(false)
      setShowLogoutConfirm(false)
    }
  }

  // Calculate family stats
  const totalCoins = children.reduce((sum, c) => sum + (c.coins || 0), 0)

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Family Settings" showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-md mx-auto space-y-6">
          {/* Account Info */}
          <Card className="p-4">
            <h2 className="text-lg font-bold mb-4 flex items-center gap-2">
              <span>👤</span> Account
            </h2>

            <div className="space-y-3">
              <InfoRow label="Email" value={user?.email || 'Not set'} />
              <InfoRow label="Family Name" value={family?.name || 'Your Family'} />
              <InfoRow label="Children" value={`${children.length} / 5`} />
              <InfoRow
                label="Total Family Coins"
                value={totalCoins.toLocaleString()}
                valueClass="text-accent-tertiary"
              />
            </div>
          </Card>

          {/* Family Management */}
          <Card className="p-4">
            <h2 className="text-lg font-bold mb-4 flex items-center gap-2">
              <span>👨‍👩‍👧‍👦</span> Family
            </h2>

            <div className="space-y-2">
              <Button
                variant="ghost"
                fullWidth
                onClick={() => navigate('/parent/dashboard')}
                className="justify-start"
              >
                <span className="mr-3">👶</span>
                Manage Children
              </Button>

              <Button
                variant="ghost"
                fullWidth
                onClick={() => navigate('/parent/add-child')}
                className="justify-start"
                disabled={children.length >= 5}
              >
                <span className="mr-3">➕</span>
                Add Child
                {children.length >= 5 && (
                  <span className="ml-auto text-xs text-text-secondary">(Limit reached)</span>
                )}
              </Button>

              <Button
                variant="ghost"
                fullWidth
                onClick={() => {
                  /* TODO: Implement family name edit */
                }}
                className="justify-start"
              >
                <span className="mr-3">✏️</span>
                Rename Family
              </Button>
            </div>
          </Card>

          {/* Data Management */}
          <Card className="p-4">
            <h2 className="text-lg font-bold mb-4 flex items-center gap-2">
              <span>💾</span> Data
            </h2>

            <div className="space-y-2">
              <Button
                variant="ghost"
                fullWidth
                onClick={() => {
                  /* TODO: Implement data export */
                }}
                className="justify-start"
              >
                <span className="mr-3">📤</span>
                Export Data
                <span className="ml-auto text-xs text-text-secondary">Coming soon</span>
              </Button>

              <Button
                variant="ghost"
                fullWidth
                onClick={() => setShowResetConfirm(true)}
                className="justify-start text-yellow-400 hover:bg-yellow-400/10"
              >
                <span className="mr-3">🔄</span>
                Reset All Progress
              </Button>
            </div>
          </Card>

          {/* Account Actions */}
          <Card className="p-4">
            <h2 className="text-lg font-bold mb-4 flex items-center gap-2">
              <span>🔐</span> Account Actions
            </h2>

            <div className="space-y-2">
              <Button
                variant="ghost"
                fullWidth
                onClick={() => {
                  /* TODO: Implement password change */
                }}
                className="justify-start"
              >
                <span className="mr-3">🔑</span>
                Change Password
              </Button>

              <Button
                variant="ghost"
                fullWidth
                onClick={() => setShowLogoutConfirm(true)}
                className="justify-start"
              >
                <span className="mr-3">🚪</span>
                Log Out
              </Button>
            </div>
          </Card>

          {/* Danger Zone */}
          <Card className="p-4 border-error/30">
            <h2 className="text-lg font-bold mb-4 flex items-center gap-2 text-error">
              <span>⚠️</span> Danger Zone
            </h2>

            <p className="text-sm text-text-secondary mb-4">
              These actions are permanent and cannot be undone.
            </p>

            <Button
              variant="ghost"
              fullWidth
              onClick={() => setShowDeleteConfirm(true)}
              className="justify-start text-error hover:bg-error/10"
            >
              <span className="mr-3">🗑️</span>
              Delete Family Account
            </Button>
          </Card>

          {/* App Info */}
          <div className="text-center text-sm text-text-secondary pt-4">
            <p>Max's Puzzles v1.0.0</p>
            <p className="mt-1">Made with ❤️ for Max</p>
          </div>
        </div>
      </main>

      {/* Logout Confirmation Modal */}
      <Modal isOpen={showLogoutConfirm} onClose={() => setShowLogoutConfirm(false)} title="Log Out?">
        <p className="text-text-secondary mb-6">
          Are you sure you want to log out? You'll need to sign in again to access your family's
          data.
        </p>
        <div className="flex gap-3">
          <Button
            variant="ghost"
            fullWidth
            onClick={() => setShowLogoutConfirm(false)}
            disabled={isLoggingOut}
          >
            Cancel
          </Button>
          <Button variant="secondary" fullWidth onClick={handleLogout} loading={isLoggingOut}>
            Log Out
          </Button>
        </div>
      </Modal>

      {/* Reset Progress Confirmation Modal */}
      <Modal
        isOpen={showResetConfirm}
        onClose={() => setShowResetConfirm(false)}
        title="Reset All Progress?"
      >
        <div className="text-center">
          <div className="text-5xl mb-4">⚠️</div>
          <p className="text-text-secondary mb-2">
            This will reset all progress for all children:
          </p>
          <ul className="text-sm text-text-secondary mb-4 space-y-1">
            <li>• All game statistics will be cleared</li>
            <li>• All earned coins will be removed</li>
            <li>• Progression levels will be reset</li>
          </ul>
          <p className="text-error text-sm font-medium mb-6">This action cannot be undone!</p>
        </div>
        <div className="flex gap-3">
          <Button variant="ghost" fullWidth onClick={() => setShowResetConfirm(false)}>
            Cancel
          </Button>
          <Button
            variant="secondary"
            fullWidth
            className="bg-yellow-600 hover:bg-yellow-500"
            onClick={() => {
              // TODO: Implement reset
              setShowResetConfirm(false)
            }}
          >
            Reset Everything
          </Button>
        </div>
      </Modal>

      {/* Delete Account Confirmation Modal */}
      <Modal
        isOpen={showDeleteConfirm}
        onClose={() => {
          setShowDeleteConfirm(false)
          setDeleteConfirmText('')
        }}
        title="Delete Family Account?"
      >
        <div className="text-center">
          <div className="text-5xl mb-4">🗑️</div>
          <p className="mb-4">
            This will <strong className="text-error">permanently delete</strong>:
          </p>
          <ul className="text-sm text-text-secondary mb-4 space-y-1 text-left">
            <li>• Your parent account</li>
            <li>• All {children.length} child profiles</li>
            <li>• All progress and statistics</li>
            <li>• All {totalCoins.toLocaleString()} coins</li>
          </ul>

          <p className="text-sm mb-4">
            Type <strong className="text-error">DELETE</strong> to confirm:
          </p>
          <input
            type="text"
            value={deleteConfirmText}
            onChange={(e) => setDeleteConfirmText(e.target.value.toUpperCase())}
            placeholder="DELETE"
            className="w-full px-4 py-2 rounded-lg bg-background-dark border-2 border-error/50 text-center font-mono uppercase"
          />
        </div>

        <div className="flex gap-3 mt-6">
          <Button
            variant="ghost"
            fullWidth
            onClick={() => {
              setShowDeleteConfirm(false)
              setDeleteConfirmText('')
            }}
          >
            Cancel
          </Button>
          <Button
            variant="secondary"
            fullWidth
            className="bg-error hover:bg-error/80"
            disabled={deleteConfirmText !== 'DELETE'}
            onClick={() => {
              // TODO: Implement account deletion
              console.log('Delete account')
            }}
          >
            Delete Forever
          </Button>
        </div>
      </Modal>
    </div>
  )
}

// Helper component
interface InfoRowProps {
  label: string
  value: string
  valueClass?: string
}

function InfoRow({ label, value, valueClass }: InfoRowProps) {
  return (
    <div className="flex justify-between items-center py-2 border-b border-white/5 last:border-0">
      <span className="text-text-secondary">{label}</span>
      <span className={`font-medium ${valueClass || ''}`}>{value}</span>
    </div>
  )
}
