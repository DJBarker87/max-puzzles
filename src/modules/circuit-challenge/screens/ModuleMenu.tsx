import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useSound } from '@/app/providers/SoundProvider'
import Header from '@/hub/components/Header'
import { SplashBackground, MusicToggleButton } from '../components'

/**
 * Circuit Challenge module menu screen
 */
export default function ModuleMenu() {
  const navigate = useNavigate()
  const { playMusic } = useSound()

  // Continue hub music on this screen
  useEffect(() => {
    playMusic('hub', true)
  }, [playMusic])

  return (
    <div className="min-h-screen flex flex-col relative">
      <SplashBackground overlayOpacity={0.35} />

      {/* Header with menu button for settings/shop access */}
      <Header showMenu className="relative z-10" />

      {/* Title section with circuit challenge icon */}
      <div className="px-4 md:px-8 pb-4 relative z-10 flex flex-col items-center pt-4">
        {/* Electric hexagon icon */}
        <img
          src="/icons/circuit_challenge_icon.png"
          alt=""
          className="w-28 h-28 md:w-32 md:h-32 object-contain mb-4"
          style={{ filter: 'drop-shadow(0 0 15px rgba(0, 255, 136, 0.5))' }}
        />

        <h1
          className="text-2xl md:text-3xl font-bold text-white text-center"
          style={{
            textShadow:
              '0 0 8px rgba(0, 255, 136, 0.8), 0 0 4px rgba(34, 197, 94, 0.5)',
          }}
        >
          Circuit Challenge
        </h1>

        <p className="text-white/90 text-center text-sm mt-2 px-8">
          Find the path from START to FINISH by solving arithmetic problems!
        </p>

        {/* Music toggle */}
        <div className="absolute top-4 right-4">
          <MusicToggleButton size="md" />
        </div>
      </div>

      {/* Menu Options */}
      <div className="flex-1 flex flex-col items-center justify-center p-4 gap-4 relative z-10">
        {/* Quick Play */}
        <button
          onClick={() => navigate('/play/circuit-challenge/quick')}
          className="w-full max-w-md p-4 rounded-2xl bg-background-mid/80 cursor-pointer hover:scale-[1.02] transition-transform flex items-center gap-4"
          style={{
            border: '1px solid rgba(34, 197, 94, 0.3)',
          }}
        >
          <img
            src="/icons/quick_play_icon.png"
            alt=""
            className="w-14 h-14 object-contain"
          />
          <div className="flex-1 text-left">
            <h2
              className="text-lg font-bold text-white"
              style={{
                textShadow: '0 0 4px rgba(0, 255, 136, 0.6)',
              }}
            >
              Quick Play
            </h2>
            <p className="text-white/80 text-sm">Play at any difficulty level</p>
          </div>
          <span className="text-white/70 text-lg">›</span>
        </button>

        {/* Story Mode */}
        <button
          onClick={() => navigate('/play/circuit-challenge/story')}
          className="w-full max-w-md p-4 rounded-2xl bg-background-mid/80 cursor-pointer hover:scale-[1.02] transition-transform flex items-center gap-4"
          style={{
            border: '1px solid rgba(251, 191, 36, 0.3)',
          }}
        >
          <img
            src="/icons/story_mode_icon.png"
            alt=""
            className="w-14 h-14 object-contain"
          />
          <div className="flex-1 text-left">
            <h2
              className="text-lg font-bold text-white"
              style={{
                textShadow: '0 0 4px rgba(0, 255, 136, 0.6)',
              }}
            >
              Story Mode
            </h2>
            <p className="text-white/80 text-sm">Help the aliens solve puzzles!</p>
          </div>
          <span className="text-white/70 text-lg">›</span>
        </button>

        {/* Puzzle Maker */}
        <button
          onClick={() => navigate('/play/circuit-challenge/maker')}
          className="w-full max-w-md p-4 rounded-2xl bg-background-mid/80 cursor-pointer hover:scale-[1.02] transition-transform flex items-center gap-4"
          style={{
            border: '1px solid rgba(251, 191, 36, 0.3)',
          }}
        >
          <img
            src="/icons/puzzle_maker_icon.png"
            alt=""
            className="w-14 h-14 object-contain"
          />
          <div className="flex-1 text-left">
            <h2
              className="text-lg font-bold text-white"
              style={{
                textShadow: '0 0 4px rgba(0, 255, 136, 0.6)',
              }}
            >
              Puzzle Maker
            </h2>
            <p className="text-white/80 text-sm">Print puzzles for offline play</p>
          </div>
          <span className="text-white/70 text-lg">›</span>
        </button>
      </div>

      {/* Stats summary */}
      <footer className="p-4 text-center text-text-secondary relative z-10">
        <p>Games played: 0 | Best streak: 0</p>
        <div className="mt-2 flex justify-center gap-4 text-sm text-text-secondary/70">
          <button
            onClick={() => navigate('/privacy')}
            className="hover:text-accent-primary transition-colors"
          >
            Privacy Policy
          </button>
          <span>|</span>
          <button
            onClick={() => navigate('/support')}
            className="hover:text-accent-primary transition-colors"
          >
            Support
          </button>
        </div>
      </footer>
    </div>
  )
}
