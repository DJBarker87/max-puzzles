import { useNavigate } from 'react-router-dom'
import { Button, Card } from '@/ui'
import { StarryBackground } from '../components'

/**
 * Circuit Challenge module menu screen
 */
export default function ModuleMenu() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen flex flex-col relative">
      <StarryBackground />

      {/* Header */}
      <header className="flex items-center gap-4 p-4 md:p-8 relative z-10">
        <Button
          variant="ghost"
          size="sm"
          onClick={() => navigate('/hub')}
          className="w-11 h-11 rounded-xl !p-0 flex items-center justify-center"
          aria-label="Go back"
        >
          <span className="text-xl">←</span>
        </Button>
        <div>
          <h1 className="text-2xl md:text-3xl font-display font-bold">
            <span className="text-accent-primary">⚡</span> Circuit Challenge
          </h1>
          <p className="text-text-secondary">Navigate the circuit!</p>
        </div>
      </header>

      {/* Menu Options */}
      <div className="flex-1 flex flex-col items-center justify-center p-4 gap-4 relative z-10">
        {/* Quick Play */}
        <Card
          variant="interactive"
          className="w-full max-w-md p-6 cursor-pointer hover:scale-[1.02] transition-transform"
          onClick={() => navigate('/play/circuit-challenge/quick')}
        >
          <div className="flex items-center gap-4">
            <span className="text-4xl">⚡</span>
            <div>
              <h2 className="text-xl font-bold">Quick Play</h2>
              <p className="text-text-secondary">Play at any difficulty</p>
            </div>
          </div>
        </Card>

        {/* Progression (V2 - disabled) */}
        <Card variant="default" className="w-full max-w-md p-6 opacity-50">
          <div className="flex items-center gap-4">
            <span className="text-4xl">📈</span>
            <div>
              <h2 className="text-xl font-bold">Progression</h2>
              <p className="text-text-secondary">Coming in V2</p>
              <div className="flex items-center gap-1 mt-1">
                <span className="text-yellow-400">🔒</span>
                <span className="text-sm text-text-secondary">
                  30 levels to master
                </span>
              </div>
            </div>
          </div>
        </Card>

        {/* Puzzle Maker */}
        <Card
          variant="interactive"
          className="w-full max-w-md p-6 cursor-pointer hover:scale-[1.02] transition-transform"
          onClick={() => navigate('/play/circuit-challenge/puzzle-maker')}
        >
          <div className="flex items-center gap-4">
            <span className="text-4xl">🖨️</span>
            <div>
              <h2 className="text-xl font-bold">Puzzle Maker</h2>
              <p className="text-text-secondary">Print puzzles for class</p>
            </div>
          </div>
        </Card>
      </div>

      {/* Stats summary */}
      <footer className="p-4 text-center text-text-secondary relative z-10">
        <p>Games played: 0 | Best streak: 0</p>
      </footer>
    </div>
  )
}
