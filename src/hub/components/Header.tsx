import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import Button from '@/ui/Button'
import CoinDisplay from './CoinDisplay'

export interface HeaderProps {
  /** Page title (if not showing logo) */
  title?: string
  /** Show back button */
  showBack?: boolean
  /** Show menu button */
  showMenu?: boolean
  /** Show coin display */
  showCoins?: boolean
  /** Coin amount to display */
  coins?: number
  /** Additional CSS classes */
  className?: string
}

interface MenuLinkProps {
  to: string
  icon: string
  label: string
  onClick: () => void
}

function MenuLink({ to, icon, label, onClick }: MenuLinkProps) {
  return (
    <Link
      to={to}
      onClick={onClick}
      className="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-background-light transition-colors"
    >
      <span className="text-xl">{icon}</span>
      <span className="font-medium">{label}</span>
    </Link>
  )
}

interface MobileMenuProps {
  onClose: () => void
}

function MobileMenu({ onClose }: MobileMenuProps) {
  return (
    <div className="fixed inset-0 z-50">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 animate-fade-in"
        onClick={onClose}
      />

      {/* Drawer */}
      <div className="absolute left-0 top-0 bottom-0 w-64 bg-background-mid p-4 shadow-xl animate-slide-in-left">
        <div className="flex justify-between items-center mb-6">
          <span className="text-xl font-bold">Menu</span>
          <button
            onClick={onClose}
            className="text-2xl text-text-secondary hover:text-text-primary transition-colors"
            aria-label="Close menu"
          >
            x
          </button>
        </div>

        <nav className="space-y-2">
          <MenuLink to="/hub" icon="🏠" label="Home" onClick={onClose} />
          <MenuLink to="/modules" icon="🎮" label="Play" onClick={onClose} />
          <MenuLink to="/shop" icon="🛒" label="Shop" onClick={onClose} />
          <MenuLink to="/settings" icon="⚙️" label="Settings" onClick={onClose} />
        </nav>
      </div>
    </div>
  )
}

/**
 * Reusable header component for hub screens
 */
export default function Header({
  title,
  showBack = false,
  showMenu = false,
  showCoins = false,
  coins = 0,
  className = '',
}: HeaderProps) {
  const navigate = useNavigate()
  const [menuOpen, setMenuOpen] = useState(false)

  return (
    <>
      <header
        className={`
          flex items-center justify-between
          px-4 py-3 md:px-8 md:py-4
          bg-gradient-to-b from-black/30 to-transparent
          ${className}
        `}
      >
        {/* Left section */}
        <div className="flex items-center gap-3">
          {showBack && (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => navigate(-1)}
              className="w-10 h-10 rounded-xl"
              aria-label="Go back"
            >
              ←
            </Button>
          )}

          {showMenu && (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setMenuOpen(true)}
              className="w-10 h-10 rounded-xl"
              aria-label="Open menu"
            >
              ☰
            </Button>
          )}

          {title ? (
            <h1 className="text-xl md:text-2xl font-display font-bold">
              {title}
            </h1>
          ) : (
            <Link to="/hub" className="flex items-center gap-2">
              <span className="text-2xl">👽</span>
              <span className="text-xl font-display font-bold hidden md:inline">
                Max's Puzzles
              </span>
            </Link>
          )}
        </div>

        {/* Right section */}
        <div className="flex items-center gap-3">
          {showCoins && (
            <CoinDisplay amount={coins} size="sm" />
          )}
        </div>
      </header>

      {/* Mobile menu drawer */}
      {showMenu && menuOpen && (
        <MobileMenu onClose={() => setMenuOpen(false)} />
      )}
    </>
  )
}
