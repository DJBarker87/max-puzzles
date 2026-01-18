import { useState, FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/app/providers/AuthProvider'
import Button from '@/ui/Button'
import Card from '@/ui/Card'
import Input from '@/ui/Input'

type Mode = 'choice' | 'login' | 'signup'

/**
 * Login/signup screen with guest play option
 */
export default function LoginScreen() {
  const navigate = useNavigate()
  const { login, signup, setGuestMode } = useAuth()

  const [mode, setMode] = useState<Mode>('choice')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const handleGuestPlay = () => {
    setGuestMode()
    navigate('/hub')
  }

  const handleLogin = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    setIsLoading(true)

    try {
      await login(email, password)
      navigate('/family-select')
    } catch {
      setError('Invalid email or password')
    } finally {
      setIsLoading(false)
    }
  }

  const handleSignup = async (e: FormEvent) => {
    e.preventDefault()

    if (password !== confirmPassword) {
      setError('Passwords do not match')
      return
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters')
      return
    }

    setError(null)
    setIsLoading(true)

    try {
      await signup(email, password, displayName)
      navigate('/family-select')
    } catch {
      setError('Could not create account')
    } finally {
      setIsLoading(false)
    }
  }

  const resetForm = () => {
    setEmail('')
    setPassword('')
    setConfirmPassword('')
    setDisplayName('')
    setError(null)
  }

  // Choice mode - initial screen
  if (mode === 'choice') {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-4 bg-background-dark">
        {/* Logo */}
        <div className="text-center mb-8 animate-fade-in">
          <div className="text-6xl mb-4">👽</div>
          <h1 className="text-3xl font-display font-bold">
            <span className="text-accent-primary">Max's</span> Puzzles
          </h1>
        </div>

        {/* Main action - Guest play */}
        <Button
          variant="primary"
          size="lg"
          fullWidth
          className="max-w-sm mb-6"
          onClick={handleGuestPlay}
        >
          Play as Guest
        </Button>

        <p className="text-text-secondary mb-6">
          No account needed - jump right in!
        </p>

        {/* Divider */}
        <div className="flex items-center gap-4 w-full max-w-sm mb-6">
          <div className="flex-1 h-px bg-white/20" />
          <span className="text-text-secondary text-sm">or</span>
          <div className="flex-1 h-px bg-white/20" />
        </div>

        {/* Login/Signup buttons */}
        <div className="flex gap-3 w-full max-w-sm">
          <Button
            variant="ghost"
            fullWidth
            onClick={() => {
              resetForm()
              setMode('login')
            }}
          >
            Log In
          </Button>
          <Button
            variant="secondary"
            fullWidth
            onClick={() => {
              resetForm()
              setMode('signup')
            }}
          >
            Sign Up
          </Button>
        </div>

        {/* Benefits of account */}
        <div className="mt-8 text-center text-text-secondary text-sm max-w-sm">
          <p className="mb-2">With a family account you can:</p>
          <ul className="space-y-1">
            <li>Save progress across devices</li>
            <li>Track multiple children</li>
            <li>View parent dashboard</li>
          </ul>
        </div>
      </div>
    )
  }

  // Login form
  if (mode === 'login') {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-4 bg-background-dark">
        <Card className="w-full max-w-sm p-6">
          <h2 className="text-2xl font-display font-bold mb-6 text-center">
            Welcome Back!
          </h2>

          <form onSubmit={handleLogin} className="space-y-4">
            <Input
              type="email"
              label="Email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              autoFocus
              autoComplete="email"
            />

            <Input
              type="password"
              label="Password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              autoComplete="current-password"
            />

            {error && (
              <p className="text-error text-sm">{error}</p>
            )}

            <Button
              type="submit"
              variant="primary"
              fullWidth
              loading={isLoading}
            >
              Log In
            </Button>
          </form>

          <button
            className="mt-4 text-text-secondary text-sm underline w-full text-center hover:text-text-primary transition-colors"
            onClick={() => {
              resetForm()
              setMode('choice')
            }}
          >
            Back
          </button>
        </Card>
      </div>
    )
  }

  // Signup form
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-4 bg-background-dark">
      <Card className="w-full max-w-sm p-6">
        <h2 className="text-2xl font-display font-bold mb-6 text-center">
          Create Account
        </h2>

        <form onSubmit={handleSignup} className="space-y-4">
          <Input
            type="text"
            label="Your Name"
            value={displayName}
            onChange={e => setDisplayName(e.target.value)}
            required
            autoFocus
            autoComplete="name"
            placeholder="e.g., Mum, Dad, Parent"
          />

          <Input
            type="email"
            label="Email"
            value={email}
            onChange={e => setEmail(e.target.value)}
            required
            autoComplete="email"
          />

          <Input
            type="password"
            label="Password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            required
            autoComplete="new-password"
            placeholder="At least 6 characters"
          />

          <Input
            type="password"
            label="Confirm Password"
            value={confirmPassword}
            onChange={e => setConfirmPassword(e.target.value)}
            required
            autoComplete="new-password"
          />

          {error && (
            <p className="text-error text-sm">{error}</p>
          )}

          <Button
            type="submit"
            variant="primary"
            fullWidth
            loading={isLoading}
          >
            Create Account
          </Button>
        </form>

        <button
          className="mt-4 text-text-secondary text-sm underline w-full text-center hover:text-text-primary transition-colors"
          onClick={() => {
            resetForm()
            setMode('choice')
          }}
        >
          Back
        </button>
      </Card>
    </div>
  )
}
