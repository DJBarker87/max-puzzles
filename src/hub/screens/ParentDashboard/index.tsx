import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import Button from '@/ui/Button'
import Card from '@/ui/Card'
import Header from '../../components/Header'

/**
 * Parent dashboard screen - shows overview of children's progress
 * Will be expanded in Phase 7
 */
export default function ParentDashboard() {
  const navigate = useNavigate()
  const { children } = useAuth()

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Parent Dashboard" showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-2xl mx-auto">
          {/* Overview Section */}
          <h2 className="text-xl font-bold mb-4">Your Children</h2>

          {children.length === 0 ? (
            <Card className="p-6 text-center">
              <p className="text-text-secondary mb-4">
                No children added yet
              </p>
              <Button
                variant="primary"
                onClick={() => navigate('/parent/add-child')}
              >
                Add Your First Child
              </Button>
            </Card>
          ) : (
            <div className="space-y-4">
              {children.map(child => (
                <Card key={child.id} className="p-4">
                  <div className="flex items-center gap-4">
                    <div className="text-4xl">
                      {child.avatarEmoji || '👽'}
                    </div>
                    <div className="flex-1">
                      <h3 className="font-bold">{child.displayName}</h3>
                      <p className="text-text-secondary text-sm">
                        Stats coming in Phase 7
                      </p>
                    </div>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => navigate(`/parent/children/${child.id}`)}
                    >
                      View
                    </Button>
                  </div>
                </Card>
              ))}

              {children.length < 5 && (
                <Button
                  variant="secondary"
                  fullWidth
                  onClick={() => navigate('/parent/add-child')}
                >
                  Add Another Child
                </Button>
              )}
            </div>
          )}

          {/* Placeholder for future features */}
          <div className="mt-8">
            <Card className="p-6 text-center opacity-50">
              <p className="text-text-secondary">
                Detailed activity history and stats coming in Phase 7
              </p>
            </Card>
          </div>
        </div>
      </main>
    </div>
  )
}
