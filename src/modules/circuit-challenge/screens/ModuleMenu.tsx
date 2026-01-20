import { useNavigate } from 'react-router-dom'
import { Card } from '@/ui'
import Header from '@/hub/components/Header'
import { StarryBackground, MusicToggleButton } from '../components'

/**
 * Circuit Challenge module menu screen
 */
export default function ModuleMenu() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen flex flex-col relative">
      <StarryBackground />

      {/* Header with menu button for settings/shop access */}
      <Header showMenu className="relative z-10" />

      {/* Title section */}
      <div className="px-4 md:px-8 pb-4 relative z-10">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl md:text-3xl font-display font-bold">
            <span className="text-accent-primary">⚡</span> Circuit Challenge
          </h1>
          <MusicToggleButton size="md" />
        </div>
        <p className="text-text-secondary">Navigate the circuit!</p>
      </div>

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

        {/* Story Mode */}
        <Card
          variant="interactive"
          className="w-full max-w-md p-6 cursor-pointer hover:scale-[1.02] transition-transform"
          onClick={() => navigate('/play/circuit-challenge/story')}
        >
          <div className="flex items-center gap-4">
            <span className="text-4xl">⭐</span>
            <div>
              <h2 className="text-xl font-bold">Story Mode</h2>
              <p className="text-text-secondary">Help the aliens solve puzzles!</p>
            </div>
          </div>
        </Card>

        {/* Puzzle Maker */}
        <Card
          variant="interactive"
          className="w-full max-w-md p-6 cursor-pointer hover:scale-[1.02] transition-transform"
          onClick={() => navigate('/play/circuit-challenge/maker')}
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
