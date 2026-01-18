import { useNavigate } from 'react-router-dom'
import Card from '@/ui/Card'
import Header from '../components/Header'

interface Module {
  id: string
  name: string
  description: string
  icon: string
  route: string | null
  available: boolean
  progress?: {
    level: number
    stars: number
  }
}

/**
 * Module selection screen showing available puzzle games
 */
export default function ModuleSelectScreen() {
  const navigate = useNavigate()

  // TODO: Get progress from storage/state
  const modules: Module[] = [
    {
      id: 'circuit-challenge',
      name: 'Circuit Challenge',
      description: 'Navigate the circuit by solving arithmetic!',
      icon: '⚡',
      route: '/play/circuit-challenge',
      available: true,
      progress: { level: 1, stars: 0 }, // Default for new players
    },
    {
      id: 'coming-soon-1',
      name: 'Coming Soon',
      description: 'More puzzles on the way!',
      icon: '🔒',
      route: null,
      available: false,
    },
    {
      id: 'coming-soon-2',
      name: 'Coming Soon',
      description: 'Stay tuned for new challenges!',
      icon: '🔒',
      route: null,
      available: false,
    },
  ]

  const handleModuleClick = (module: Module) => {
    if (module.available && module.route) {
      navigate(module.route)
    }
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Choose a Puzzle" showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-2xl mx-auto space-y-4">
          {modules.map(module => (
            <Card
              key={module.id}
              variant={module.available ? 'interactive' : 'default'}
              className={`p-4 ${!module.available ? 'opacity-50' : 'cursor-pointer'}`}
              onClick={module.available ? () => handleModuleClick(module) : undefined}
            >
              <div className="flex items-center gap-4">
                {/* Icon */}
                <div className="text-4xl">
                  {module.icon}
                </div>

                {/* Info */}
                <div className="flex-1">
                  <h2 className="text-xl font-bold">{module.name}</h2>
                  <p className="text-text-secondary text-sm">
                    {module.description}
                  </p>

                  {/* Progress indicator */}
                  {module.available && module.progress && (
                    <div className="flex items-center gap-2 mt-2 text-sm">
                      <span className="text-yellow-400">
                        {'⭐'.repeat(Math.min(3, Math.floor(module.progress.stars / 10)))}
                        {module.progress.stars === 0 && '☆'}
                      </span>
                      <span className="text-text-secondary">
                        Level {module.progress.level}
                      </span>
                    </div>
                  )}
                </div>

                {/* Arrow */}
                {module.available && (
                  <span className="text-2xl text-text-secondary">→</span>
                )}
              </div>
            </Card>
          ))}
        </div>
      </main>
    </div>
  )
}
