# Phase 5: Hub Screens & Navigation

**Goal:** Build the hub screens that wrap the puzzle modules - splash screen, login/guest mode, main hub, settings, and the parent dashboard structure. This creates the complete app shell that users navigate through.

---

## Subphase 5.1: Splash Screen

### Prompt for Claude Code:

```
Create the splash screen that displays briefly when the app loads.

File: src/hub/screens/SplashScreen.tsx

Import:
- useEffect, useState from 'react'
- useNavigate from 'react-router-dom'
- useAuth from '@/app/providers/AuthProvider'

1. Component logic:
   - Display for minimum 1.5 seconds (for branding)
   - Check auth state while showing
   - Navigate based on auth:
     * If logged in parent → Family Select
     * If guest with saved progress → Main Hub
     * Otherwise → Login Screen

2. Layout:
   
   return (
     <div className="min-h-screen flex flex-col items-center justify-center bg-background-dark">
       {/* Logo and Title */}
       <div className="text-center animate-fade-in">
         {/* Alien mascot */}
         <div className="text-8xl mb-6 animate-bounce-slow">
           👽
         </div>
         
         <h1 className="text-4xl md:text-5xl font-display font-bold mb-2">
           <span className="text-accent-primary">Max's</span>{' '}
           <span className="text-white">Puzzles</span>
         </h1>
         
         <p className="text-text-secondary text-lg">
           Fun maths adventures!
         </p>
       </div>
       
       {/* Loading indicator */}
       <div className="mt-12">
         <div className="flex gap-2">
           {[0, 1, 2].map(i => (
             <div
               key={i}
               className="w-3 h-3 rounded-full bg-accent-primary animate-pulse"
               style={{ animationDelay: `${i * 0.2}s` }}
             />
           ))}
         </div>
       </div>
     </div>
   );

3. Navigation effect:
   
   useEffect(() => {
     const timer = setTimeout(() => {
       if (isLoading) return; // Still checking auth
       
       if (user && user.role === 'parent') {
         navigate('/family-select');
       } else if (isGuest) {
         navigate('/hub');
       } else {
         navigate('/login');
       }
     }, 1500);
     
     return () => clearTimeout(timer);
   }, [isLoading, user, isGuest, navigate]);

4. CSS animations (add to globals.css):
   
   @keyframes fade-in {
     from { opacity: 0; transform: translateY(20px); }
     to { opacity: 1; transform: translateY(0); }
   }
   
   @keyframes bounce-slow {
     0%, 100% { transform: translateY(0); }
     50% { transform: translateY(-10px); }
   }
   
   .animate-fade-in {
     animation: fade-in 0.6s ease-out;
   }
   
   .animate-bounce-slow {
     animation: bounce-slow 2s ease-in-out infinite;
   }

Export SplashScreen component.
```

---

## Subphase 5.2: Login Screen

### Prompt for Claude Code:

```
Create the login/signup screen with guest play option.

File: src/hub/screens/LoginScreen.tsx

Import:
- useState from 'react'
- useNavigate from 'react-router-dom'
- useAuth from '@/app/providers/AuthProvider'
- Button, Card, Input from '@/ui'

1. Component state:
   - mode: 'choice' | 'login' | 'signup'
   - email: string
   - password: string
   - confirmPassword: string (signup only)
   - displayName: string (signup only)
   - error: string | null
   - isLoading: boolean

2. Choice mode layout (initial):
   
   return (
     <div className="min-h-screen flex flex-col items-center justify-center p-4 bg-background-dark">
       {/* Logo */}
       <div className="text-center mb-8">
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
         🎮 Play as Guest
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
           onClick={() => setMode('login')}
         >
           Log In
         </Button>
         <Button
           variant="secondary"
           fullWidth
           onClick={() => setMode('signup')}
         >
           Sign Up
         </Button>
       </div>
       
       {/* Benefits of account */}
       <div className="mt-8 text-center text-text-secondary text-sm max-w-sm">
         <p className="mb-2">With a family account you can:</p>
         <ul className="space-y-1">
           <li>✓ Save progress across devices</li>
           <li>✓ Track multiple children</li>
           <li>✓ View parent dashboard</li>
         </ul>
       </div>
     </div>
   );

3. Login form layout:
   
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
       />
       
       <Input
         type="password"
         label="Password"
         value={password}
         onChange={e => setPassword(e.target.value)}
         required
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
       className="mt-4 text-text-secondary text-sm underline w-full text-center"
       onClick={() => setMode('choice')}
     >
       ← Back
     </button>
   </Card>

4. Signup form layout (similar to login with additional fields):
   - displayName field
   - confirmPassword field
   - Terms acceptance checkbox (optional for V1)

5. Handlers:
   
   const handleGuestPlay = () => {
     setGuestMode(true);
     navigate('/hub');
   };
   
   const handleLogin = async (e: FormEvent) => {
     e.preventDefault();
     setError(null);
     setIsLoading(true);
     
     try {
       await login(email, password);
       navigate('/family-select');
     } catch (err) {
       setError('Invalid email or password');
     } finally {
       setIsLoading(false);
     }
   };
   
   const handleSignup = async (e: FormEvent) => {
     e.preventDefault();
     
     if (password !== confirmPassword) {
       setError('Passwords do not match');
       return;
     }
     
     setError(null);
     setIsLoading(true);
     
     try {
       await signup(email, password, displayName);
       navigate('/family-select');
     } catch (err) {
       setError('Could not create account');
     } finally {
       setIsLoading(false);
     }
   };

Export LoginScreen component.
```

---

## Subphase 5.3: Family Select Screen

### Prompt for Claude Code:

```
Create the family member selection screen for logged-in families.

File: src/hub/screens/FamilySelectScreen.tsx

Import:
- useState from 'react'
- useNavigate from 'react-router-dom'
- useAuth from '@/app/providers/AuthProvider'
- Button, Card from '@/ui'
- PinEntryModal from '../components/PinEntryModal'

1. Get family data from auth context:
   
   const { user, family, children, selectChild, enterDemoMode } = useAuth();

2. Component state:
   - selectedChild: Child | null
   - showPinEntry: boolean
   - pinError: string | null

3. Layout:
   
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
             className="w-32 h-40 flex flex-col items-center justify-center p-4"
             onClick={() => handleChildSelect(child)}
           >
             {/* Avatar placeholder */}
             <div className="text-5xl mb-2">
               👽
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
             className="w-32 h-40 flex flex-col items-center justify-center p-4 border-dashed"
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
           📊 Parent Dashboard
         </Button>
         
         <Button
           variant="ghost"
           fullWidth
           onClick={handleDemoMode}
         >
           🎮 Play as Parent (Demo)
         </Button>
         
         <Button
           variant="ghost"
           fullWidth
           onClick={() => navigate('/settings')}
         >
           ⚙️ Settings
         </Button>
       </div>
       
       {/* PIN Entry Modal */}
       <PinEntryModal
         isOpen={showPinEntry}
         onClose={() => {
           setShowPinEntry(false);
           setSelectedChild(null);
           setPinError(null);
         }}
         childName={selectedChild?.displayName || ''}
         onSubmit={handlePinSubmit}
         error={pinError}
       />
     </div>
   );

4. Handlers:
   
   const handleChildSelect = (child: Child) => {
     setSelectedChild(child);
     setShowPinEntry(true);
   };
   
   const handlePinSubmit = async (pin: string) => {
     if (!selectedChild) return;
     
     try {
       await selectChild(selectedChild.id, pin);
       navigate('/hub');
     } catch (err) {
       setPinError('Wrong PIN. Try again!');
     }
   };
   
   const handleDemoMode = () => {
     enterDemoMode();
     navigate('/hub');
   };

Export FamilySelectScreen component.
```

---

## Subphase 5.4: PIN Entry Modal Component

### Prompt for Claude Code:

```
Create the PIN entry modal for child authentication.

File: src/hub/components/PinEntryModal.tsx

Import:
- useState, useEffect, useRef from 'react'
- Modal from '@/ui'

Props interface PinEntryModalProps:
  - isOpen: boolean
  - onClose: () => void
  - childName: string
  - onSubmit: (pin: string) => void
  - error?: string | null

1. Component state:
   - pin: string (4 characters max)
   - isShaking: boolean (for wrong PIN animation)

2. Layout:
   
   return (
     <Modal isOpen={isOpen} onClose={onClose} size="sm">
       <div className="text-center">
         {/* Child avatar/name */}
         <div className="text-5xl mb-2">👽</div>
         <h2 className="text-xl font-bold mb-6">{childName}</h2>
         
         {/* PIN dots display */}
         <div 
           className={`flex justify-center gap-3 mb-6 ${isShaking ? 'animate-shake' : ''}`}
         >
           {[0, 1, 2, 3].map(i => (
             <div
               key={i}
               className={`
                 w-4 h-4 rounded-full border-2
                 ${i < pin.length 
                   ? 'bg-accent-primary border-accent-primary' 
                   : 'border-white/30'}
                 transition-all duration-150
               `}
             />
           ))}
         </div>
         
         {/* Error message */}
         {error && (
           <p className="text-error text-sm mb-4">{error}</p>
         )}
         
         {/* Number pad */}
         <div className="grid grid-cols-3 gap-3 max-w-[240px] mx-auto">
           {[1, 2, 3, 4, 5, 6, 7, 8, 9, null, 0, 'back'].map((num, i) => (
             <button
               key={i}
               onClick={() => handleKeyPress(num)}
               disabled={num === null}
               className={`
                 h-14 rounded-xl font-bold text-xl
                 ${num === null 
                   ? 'invisible' 
                   : num === 'back'
                     ? 'bg-background-dark text-text-secondary'
                     : 'bg-background-mid hover:bg-background-light active:scale-95'}
                 transition-all duration-150
               `}
             >
               {num === 'back' ? '←' : num}
             </button>
           ))}
         </div>
         
         {/* Cancel button */}
         <button
           onClick={onClose}
           className="mt-6 text-text-secondary underline"
         >
           Cancel
         </button>
       </div>
     </Modal>
   );

3. Key press handler:
   
   const handleKeyPress = (key: number | string | null) => {
     if (key === null) return;
     
     if (key === 'back') {
       setPin(prev => prev.slice(0, -1));
       return;
     }
     
     if (pin.length >= 4) return;
     
     const newPin = pin + key.toString();
     setPin(newPin);
     
     // Auto-submit on 4 digits
     if (newPin.length === 4) {
       onSubmit(newPin);
     }
   };

4. Reset PIN when modal opens/closes or on error:
   
   useEffect(() => {
     if (isOpen) {
       setPin('');
     }
   }, [isOpen]);
   
   useEffect(() => {
     if (error) {
       setIsShaking(true);
       setPin('');
       setTimeout(() => setIsShaking(false), 300);
     }
   }, [error]);

5. Keyboard support (optional enhancement):
   - Listen for number keys
   - Listen for backspace
   - Listen for escape to close

Export PinEntryModal component.
```

---

## Subphase 5.5: Main Hub Screen

### Prompt for Claude Code:

```
Create the main hub screen - the central navigation point.

File: src/hub/screens/MainHubScreen.tsx

Import:
- useNavigate from 'react-router-dom'
- useAuth from '@/app/providers/AuthProvider'
- Button, Card from '@/ui'
- Header, CoinDisplay from '../components'

1. Get user data:
   
   const { user, isGuest, isDemoMode } = useAuth();
   const displayName = user?.displayName || 'Guest';
   const coins = user?.coins || 0;

2. Layout:
   
   return (
     <div className="min-h-screen flex flex-col bg-background-dark">
       {/* Header */}
       <Header
         showMenu
         showCoins={!isDemoMode}
         coins={coins}
       />
       
       {/* Main content */}
       <main className="flex-1 flex flex-col items-center justify-center p-4">
         {/* Avatar and greeting */}
         <div className="text-center mb-8">
           <div 
             className="text-7xl mb-4 cursor-pointer hover:scale-110 transition-transform"
             onClick={() => !isDemoMode && navigate('/shop')}
             title={isDemoMode ? undefined : "Customise your alien!"}
           >
             👽
           </div>
           <h1 className="text-2xl font-display font-bold">
             Hi, {displayName}!
           </h1>
           {isDemoMode && (
             <p className="text-text-secondary text-sm mt-1">
               Demo Mode - Progress not saved
             </p>
           )}
         </div>
         
         {/* Main action - Play */}
         <Button
           variant="primary"
           size="lg"
           className="mb-6 px-12"
           onClick={() => navigate('/modules')}
         >
           🎮 PLAY
         </Button>
         
         {/* Secondary actions */}
         <div className="flex gap-4">
           {!isDemoMode && (
             <Button
               variant="secondary"
               onClick={() => navigate('/shop')}
             >
               🛒 Shop
             </Button>
           )}
           <Button
             variant="ghost"
             onClick={() => navigate('/settings')}
           >
             ⚙️ Settings
           </Button>
         </div>
       </main>
       
       {/* Guest prompt */}
       {isGuest && (
         <div className="p-4 text-center bg-background-mid/50">
           <p className="text-text-secondary mb-2">
             Playing as guest - progress saved locally
           </p>
           <Button
             variant="ghost"
             size="sm"
             onClick={() => navigate('/login')}
           >
             Create Account to Save Progress
           </Button>
         </div>
       )}
     </div>
   );

Export MainHubScreen component.
```

---

## Subphase 5.6: Module Select Screen

### Prompt for Claude Code:

```
Create the module selection screen showing available puzzle games.

File: src/hub/screens/ModuleSelectScreen.tsx

Import:
- useNavigate from 'react-router-dom'
- Card, Button from '@/ui'
- Header from '../components'

1. Define available modules:
   
   const modules = [
     {
       id: 'circuit-challenge',
       name: 'Circuit Challenge',
       description: 'Navigate the circuit by solving arithmetic!',
       icon: '⚡',
       route: '/play/circuit-challenge',
       available: true,
       progress: { level: 5, stars: 38 }, // Would come from storage
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
   ];

2. Layout:
   
   return (
     <div className="min-h-screen flex flex-col bg-background-dark">
       <Header title="Choose a Puzzle" showBack />
       
       <main className="flex-1 p-4 md:p-8">
         <div className="max-w-2xl mx-auto space-y-4">
           {modules.map(module => (
             <Card
               key={module.id}
               variant={module.available ? 'interactive' : 'default'}
               className={`p-4 ${!module.available ? 'opacity-50' : ''}`}
               onClick={module.available ? () => navigate(module.route!) : undefined}
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
   );

Export ModuleSelectScreen component.
```

---

## Subphase 5.7: Settings Screen

### Prompt for Claude Code:

```
Create the settings screen for app preferences.

File: src/hub/screens/SettingsScreen.tsx

Import:
- useState from 'react'
- useNavigate from 'react-router-dom'
- useAuth from '@/app/providers/AuthProvider'
- useSound from '@/app/providers/SoundProvider'
- Button, Card, Toggle from '@/ui'
- Header from '../components'

1. Get current settings:
   
   const { user, isGuest, logout } = useAuth();
   const { isMuted, toggleMute } = useSound();
   const [settings, setSettings] = useState({
     soundEffects: !isMuted,
     music: true,
     animations: 'full' as 'full' | 'reduced',
   });

2. Layout:
   
   return (
     <div className="min-h-screen flex flex-col bg-background-dark">
       <Header title="Settings" showBack />
       
       <main className="flex-1 p-4 md:p-8">
         <div className="max-w-md mx-auto space-y-6">
           
           {/* Audio Settings */}
           <Card className="p-4">
             <h2 className="text-lg font-bold mb-4">Audio</h2>
             
             <div className="space-y-4">
               <Toggle
                 label="Sound Effects"
                 checked={settings.soundEffects}
                 onChange={(checked) => {
                   setSettings(s => ({ ...s, soundEffects: checked }));
                   toggleMute();
                 }}
               />
               
               <Toggle
                 label="Music"
                 checked={settings.music}
                 onChange={(checked) => setSettings(s => ({ ...s, music: checked }))}
               />
             </div>
           </Card>
           
           {/* Display Settings */}
           <Card className="p-4">
             <h2 className="text-lg font-bold mb-4">Display</h2>
             
             <div>
               <label className="text-sm text-text-secondary mb-2 block">
                 Animations
               </label>
               <div className="flex gap-2">
                 <Button
                   variant={settings.animations === 'full' ? 'primary' : 'ghost'}
                   size="sm"
                   onClick={() => setSettings(s => ({ ...s, animations: 'full' }))}
                 >
                   Full
                 </Button>
                 <Button
                   variant={settings.animations === 'reduced' ? 'primary' : 'ghost'}
                   size="sm"
                   onClick={() => setSettings(s => ({ ...s, animations: 'reduced' }))}
                 >
                   Reduced
                 </Button>
               </div>
             </div>
           </Card>
           
           {/* Account Section */}
           <Card className="p-4">
             <h2 className="text-lg font-bold mb-4">Account</h2>
             
             {isGuest ? (
               <div className="space-y-3">
                 <p className="text-text-secondary text-sm">
                   Playing as guest. Create an account to save your progress!
                 </p>
                 <Button
                   variant="secondary"
                   fullWidth
                   onClick={() => navigate('/login')}
                 >
                   Create Account
                 </Button>
               </div>
             ) : (
               <div className="space-y-3">
                 <p className="text-text-secondary text-sm">
                   Logged in as {user?.email}
                 </p>
                 <Button
                   variant="ghost"
                   fullWidth
                   onClick={() => navigate('/family-select')}
                 >
                   Switch User
                 </Button>
                 <Button
                   variant="ghost"
                   fullWidth
                   onClick={handleLogout}
                 >
                   Log Out
                 </Button>
               </div>
             )}
           </Card>
           
           {/* About Section */}
           <Card className="p-4">
             <h2 className="text-lg font-bold mb-2">About</h2>
             <p className="text-text-secondary text-sm">
               Max's Puzzles v1.0.0
             </p>
             <p className="text-text-secondary text-sm mt-1">
               Made with ❤️ for Max
             </p>
           </Card>
           
         </div>
       </main>
     </div>
   );

3. Logout handler:
   
   const handleLogout = async () => {
     await logout();
     navigate('/login');
   };

Export SettingsScreen component.
```

---

## Subphase 5.8: Header Component

### Prompt for Claude Code:

```
Create the reusable header component for hub screens.

File: src/hub/components/Header.tsx

Import:
- useState from 'react'
- useNavigate from 'react-router-dom'
- Button from '@/ui'
- CoinDisplay from './CoinDisplay'

Props interface HeaderProps:
  - title?: string
  - showBack?: boolean
  - showMenu?: boolean
  - showCoins?: boolean
  - coins?: number
  - className?: string

1. Layout:
   
   return (
     <header 
       className={`
         flex items-center justify-between
         px-4 py-3 md:px-8 md:py-4
         bg-gradient-to-b from-black/30 to-transparent
         ${className || ''}
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
             ≡
           </Button>
         )}
         
         {title ? (
           <h1 className="text-xl md:text-2xl font-display font-bold">
             {title}
           </h1>
         ) : (
           <div className="flex items-center gap-2">
             <span className="text-2xl">👽</span>
             <span className="text-xl font-display font-bold hidden md:inline">
               Max's Puzzles
             </span>
           </div>
         )}
       </div>
       
       {/* Right section */}
       <div className="flex items-center gap-3">
         {showCoins && (
           <CoinDisplay amount={coins || 0} size="sm" />
         )}
       </div>
       
       {/* Mobile menu drawer (if showMenu) */}
       {showMenu && menuOpen && (
         <MobileMenu onClose={() => setMenuOpen(false)} />
       )}
     </header>
   );

2. Mobile menu component (inline or separate):
   
   const MobileMenu = ({ onClose }: { onClose: () => void }) => (
     <div className="fixed inset-0 z-50">
       {/* Backdrop */}
       <div 
         className="absolute inset-0 bg-black/50"
         onClick={onClose}
       />
       
       {/* Drawer */}
       <div className="absolute left-0 top-0 bottom-0 w-64 bg-background-mid p-4 shadow-xl">
         <div className="flex justify-between items-center mb-6">
           <span className="text-xl font-bold">Menu</span>
           <button onClick={onClose} className="text-2xl">×</button>
         </div>
         
         <nav className="space-y-2">
           <MenuLink to="/hub" icon="🏠" label="Home" onClick={onClose} />
           <MenuLink to="/modules" icon="🎮" label="Play" onClick={onClose} />
           <MenuLink to="/shop" icon="🛒" label="Shop" onClick={onClose} />
           <MenuLink to="/settings" icon="⚙️" label="Settings" onClick={onClose} />
         </nav>
       </div>
     </div>
   );

Export Header component.
```

---

## Subphase 5.9: Hub Coin Display Component

### Prompt for Claude Code:

```
Create the coin display component for the hub header.

File: src/hub/components/CoinDisplay.tsx

Note: This is a simpler version than the game's CoinDisplay - no animations needed.

Props interface CoinDisplayProps:
  - amount: number
  - size?: 'sm' | 'md' | 'lg'
  - className?: string

1. Size configurations:
   const sizes = {
     sm: { icon: 16, text: 'text-sm', padding: 'px-2.5 py-1' },
     md: { icon: 20, text: 'text-base', padding: 'px-3 py-1.5' },
     lg: { icon: 24, text: 'text-lg', padding: 'px-4 py-2' },
   };

2. Layout:
   
   return (
     <div 
       className={`
         inline-flex items-center gap-1.5
         bg-gradient-to-br from-[#2a2518] to-[#1a1810]
         ${sizes[size || 'md'].padding}
         rounded-full
         border border-accent-tertiary/30
         ${className || ''}
       `}
     >
       <span style={{ fontSize: sizes[size || 'md'].icon }}>🪙</span>
       <span 
         className={`
           font-bold text-accent-tertiary tabular-nums
           ${sizes[size || 'md'].text}
         `}
       >
         {amount.toLocaleString()}
       </span>
     </div>
   );

Export CoinDisplay component.
```

---

## Subphase 5.10: Route Updates and Hub Index

### Prompt for Claude Code:

```
Update routes and create hub component index files.

1. Update src/app/routes.tsx with all hub routes:
   
   import {
     SplashScreen,
     LoginScreen,
     FamilySelectScreen,
     MainHubScreen,
     ModuleSelectScreen,
     SettingsScreen,
   } from '@/hub/screens';
   
   const routes = [
     // Splash
     { path: '/', element: <SplashScreen /> },
     
     // Auth
     { path: '/login', element: <LoginScreen /> },
     { path: '/family-select', element: <FamilySelectScreen /> },
     
     // Hub
     { path: '/hub', element: <MainHubScreen /> },
     { path: '/modules', element: <ModuleSelectScreen /> },
     { path: '/settings', element: <SettingsScreen /> },
     { path: '/shop', element: <ShopScreen /> }, // Placeholder for V3
     
     // Circuit Challenge routes (from Phase 4)
     { path: '/play/circuit-challenge', element: <ModuleMenu /> },
     { path: '/play/circuit-challenge/quick', element: <QuickPlaySetup /> },
     { path: '/play/circuit-challenge/game', element: <GameScreen /> },
     { path: '/play/circuit-challenge/summary', element: <SummaryScreen /> },
     
     // Parent routes (placeholders)
     { path: '/parent/dashboard', element: <ParentDashboard /> },
     { path: '/parent/add-child', element: <AddChildScreen /> },
     
     // Fallback
     { path: '*', element: <Navigate to="/" replace /> },
   ];

2. Create src/hub/screens/index.ts:
   
   export { SplashScreen } from './SplashScreen';
   export { LoginScreen } from './LoginScreen';
   export { FamilySelectScreen } from './FamilySelectScreen';
   export { MainHubScreen } from './MainHubScreen';
   export { ModuleSelectScreen } from './ModuleSelectScreen';
   export { SettingsScreen } from './SettingsScreen';
   
   // Placeholders for V3/later
   export { default as ShopScreen } from './ShopScreen';

3. Create src/hub/components/index.ts:
   
   export { Header } from './Header';
   export { CoinDisplay } from './CoinDisplay';
   export { PinEntryModal } from './PinEntryModal';

4. Create placeholder ShopScreen:
   
   // src/hub/screens/ShopScreen.tsx
   export default function ShopScreen() {
     return (
       <div className="min-h-screen flex items-center justify-center bg-background-dark">
         <div className="text-center">
           <div className="text-6xl mb-4">🛒</div>
           <h1 className="text-2xl font-bold mb-2">Shop</h1>
           <p className="text-text-secondary">Coming in V3!</p>
         </div>
       </div>
     );
   }

5. Create placeholder parent screens:
   
   // src/hub/screens/ParentDashboard.tsx
   // src/hub/screens/AddChildScreen.tsx
   // Basic placeholders - will be built out in Phase 7
```

---

## Phase 5 Completion Checklist

After completing all subphases, verify:

- [ ] Splash screen displays and navigates correctly
- [ ] Guest play works (skips login, goes to hub)
- [ ] Login form shows and handles input
- [ ] Signup form shows and handles input
- [ ] Family select shows children cards
- [ ] PIN entry modal works with number pad
- [ ] PIN auto-submits on 4 digits
- [ ] Wrong PIN shows error and shakes
- [ ] Main hub displays user greeting
- [ ] Demo mode label shows when applicable
- [ ] Module select shows Circuit Challenge
- [ ] Settings toggles work
- [ ] Navigation between all screens works
- [ ] Back buttons navigate correctly
- [ ] Header shows on all hub screens

---

## Files Created in This Phase

```
src/hub/
├── screens/
│   ├── index.ts
│   ├── SplashScreen.tsx
│   ├── LoginScreen.tsx
│   ├── FamilySelectScreen.tsx
│   ├── MainHubScreen.tsx
│   ├── ModuleSelectScreen.tsx
│   ├── SettingsScreen.tsx
│   ├── ShopScreen.tsx (placeholder)
│   ├── ParentDashboard.tsx (placeholder)
│   └── AddChildScreen.tsx (placeholder)
└── components/
    ├── index.ts
    ├── Header.tsx
    ├── CoinDisplay.tsx
    └── PinEntryModal.tsx
```

---

## Navigation Flow Diagram

```
[Splash Screen]
       │
       ├── Guest ──────────────────────► [Main Hub]
       │                                      │
       ├── Logged In Parent ──► [Family Select]    ├──► [Module Select] ──► [Circuit Challenge]
       │                              │           │
       └── No Session ──► [Login]     ├── Child + PIN ──► [Main Hub]
                              │       │
                              │       ├── Parent Dashboard ──► [Dashboard]
                              │       │
                              │       └── Demo Mode ──► [Main Hub] (demo)
                              │
                              └── Sign Up ──► [Family Select]

[Main Hub]
    │
    ├──► [Module Select] ──► [Play Circuit Challenge]
    │
    ├──► [Shop] (V3)
    │
    └──► [Settings]
             │
             └──► [Login] (if guest wants account)
```

---

*End of Phase 5*
