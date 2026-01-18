# Phase 7.3: Child Management & Parent Settings

**Goal:** Build the screens for adding new children, editing child profiles, resetting PINs, and the parent settings/family management screen.

---

## Subphase 7.8: Add Child Screen

### Prompt for Claude Code:

```
Create the add child screen with name and PIN input.

File: src/hub/screens/AddChildScreen.tsx

```typescript
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/app/providers/AuthProvider';
import { Button, Card } from '@/ui';
import { Header } from '../components';

// Avatar options for selection (V1 simple version)
const AVATAR_OPTIONS = ['👽', '🤖', '🦊', '🐱', '🐶', '🦁', '🐼', '🐸'];

export function AddChildScreen() {
  const navigate = useNavigate();
  const { addChild, children } = useAuth();

  // Form state
  const [displayName, setDisplayName] = useState('');
  const [selectedAvatar, setSelectedAvatar] = useState(AVATAR_OPTIONS[0]);
  const [pin, setPin] = useState('');
  const [confirmPin, setConfirmPin] = useState('');
  
  // UI state
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [step, setStep] = useState<'name' | 'pin'>('name');

  // Validation
  const isNameValid = displayName.trim().length >= 1 && displayName.trim().length <= 20;
  const isPinValid = /^\d{4}$/.test(pin);
  const doPinsMatch = pin === confirmPin;
  
  // Check for duplicate names
  const isDuplicateName = children.some(
    (c) => c.displayName.toLowerCase() === displayName.trim().toLowerCase()
  );

  // Handle name submission
  const handleNameSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!displayName.trim()) {
      setError('Please enter a name');
      return;
    }

    if (displayName.trim().length > 20) {
      setError('Name must be 20 characters or less');
      return;
    }

    if (isDuplicateName) {
      setError('A child with this name already exists');
      return;
    }

    // Move to PIN step
    setStep('pin');
  };

  // Handle final submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validate PIN
    if (pin.length !== 4) {
      setError('PIN must be exactly 4 digits');
      return;
    }

    if (!/^\d{4}$/.test(pin)) {
      setError('PIN must contain only numbers');
      return;
    }

    if (pin !== confirmPin) {
      setError('PINs do not match');
      return;
    }

    // Check for common/weak PINs
    const weakPins = ['0000', '1111', '1234', '4321', '0123', '9999'];
    if (weakPins.includes(pin)) {
      setError('Please choose a stronger PIN');
      return;
    }

    setIsLoading(true);

    try {
      const newChild = await addChild(displayName.trim(), pin);

      if (newChild) {
        // Success - navigate to dashboard
        navigate('/parent/dashboard', { 
          state: { message: `${displayName} has been added!` } 
        });
      } else {
        setError('Failed to add child. Please try again.');
      }
    } catch (err) {
      console.error('Error adding child:', err);
      setError('An error occurred. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  // Handle PIN input (digits only)
  const handlePinChange = (value: string, setter: (v: string) => void) => {
    const digitsOnly = value.replace(/\D/g, '').slice(0, 4);
    setter(digitsOnly);
  };

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header 
        title="Add Child" 
        showBack 
      />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-md mx-auto">

          {/* Progress Indicator */}
          <div className="flex items-center justify-center gap-2 mb-8">
            <div className={`w-3 h-3 rounded-full ${step === 'name' ? 'bg-accent-primary' : 'bg-accent-primary'}`} />
            <div className="w-8 h-0.5 bg-white/20" />
            <div className={`w-3 h-3 rounded-full ${step === 'pin' ? 'bg-accent-primary' : 'bg-white/20'}`} />
          </div>

          {/* Step 1: Name & Avatar */}
          {step === 'name' && (
            <Card className="p-6">
              <form onSubmit={handleNameSubmit}>
                {/* Avatar Selection */}
                <div className="text-center mb-6">
                  <div className="text-7xl mb-4">{selectedAvatar}</div>
                  <p className="text-sm text-text-secondary mb-3">Choose an avatar</p>
                  <div className="flex flex-wrap justify-center gap-2">
                    {AVATAR_OPTIONS.map((avatar) => (
                      <button
                        key={avatar}
                        type="button"
                        onClick={() => setSelectedAvatar(avatar)}
                        className={`
                          text-3xl p-2 rounded-lg transition-all
                          ${selectedAvatar === avatar
                            ? 'bg-accent-primary/20 ring-2 ring-accent-primary'
                            : 'bg-background-dark hover:bg-background-light'
                          }
                        `}
                      >
                        {avatar}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Name Input */}
                <div className="mb-6">
                  <label className="block text-sm font-medium mb-2">
                    What's their name?
                  </label>
                  <input
                    type="text"
                    value={displayName}
                    onChange={(e) => setDisplayName(e.target.value)}
                    placeholder="e.g. Max"
                    maxLength={20}
                    autoFocus
                    className={`
                      w-full px-4 py-3 rounded-lg text-lg
                      bg-background-dark border-2 
                      ${error ? 'border-error' : 'border-white/20 focus:border-accent-primary'}
                      outline-none transition-colors
                    `}
                  />
                  <div className="flex justify-between mt-1">
                    <span className="text-xs text-text-secondary">
                      {error || 'This is how they\'ll appear in the app'}
                    </span>
                    <span className="text-xs text-text-secondary">
                      {displayName.length}/20
                    </span>
                  </div>
                </div>

                {/* Continue Button */}
                <Button
                  type="submit"
                  variant="primary"
                  fullWidth
                  disabled={!isNameValid || isDuplicateName}
                >
                  Continue
                </Button>
              </form>
            </Card>
          )}

          {/* Step 2: PIN Setup */}
          {step === 'pin' && (
            <Card className="p-6">
              <form onSubmit={handleSubmit}>
                {/* Header */}
                <div className="text-center mb-6">
                  <div className="text-5xl mb-2">{selectedAvatar}</div>
                  <h2 className="text-xl font-bold">{displayName}</h2>
                  <p className="text-sm text-text-secondary mt-1">
                    Create a 4-digit PIN for {displayName}
                  </p>
                </div>

                {/* PIN Input */}
                <div className="mb-4">
                  <label className="block text-sm font-medium mb-2">
                    4-Digit PIN
                  </label>
                  <input
                    type="password"
                    inputMode="numeric"
                    pattern="\d{4}"
                    maxLength={4}
                    value={pin}
                    onChange={(e) => handlePinChange(e.target.value, setPin)}
                    placeholder="••••"
                    autoFocus
                    className={`
                      w-full px-4 py-4 rounded-lg text-center text-3xl tracking-[0.5em]
                      bg-background-dark border-2 
                      ${error && !isPinValid ? 'border-error' : 'border-white/20 focus:border-accent-primary'}
                      outline-none transition-colors font-mono
                    `}
                  />
                </div>

                {/* Confirm PIN Input */}
                <div className="mb-6">
                  <label className="block text-sm font-medium mb-2">
                    Confirm PIN
                  </label>
                  <input
                    type="password"
                    inputMode="numeric"
                    pattern="\d{4}"
                    maxLength={4}
                    value={confirmPin}
                    onChange={(e) => handlePinChange(e.target.value, setConfirmPin)}
                    placeholder="••••"
                    className={`
                      w-full px-4 py-4 rounded-lg text-center text-3xl tracking-[0.5em]
                      bg-background-dark border-2 
                      ${error && !doPinsMatch ? 'border-error' : 'border-white/20 focus:border-accent-primary'}
                      outline-none transition-colors font-mono
                    `}
                  />
                </div>

                {/* PIN Strength Indicator */}
                {pin.length === 4 && (
                  <div className="mb-4 text-center">
                    {['0000', '1111', '1234', '4321', '0123', '9999'].includes(pin) ? (
                      <span className="text-yellow-400 text-sm">
                        ⚠️ This PIN is too easy to guess
                      </span>
                    ) : (
                      <span className="text-accent-primary text-sm">
                        ✓ Good PIN
                      </span>
                    )}
                  </div>
                )}

                {/* Error Message */}
                {error && (
                  <p className="text-error text-sm text-center mb-4">{error}</p>
                )}

                {/* Info Text */}
                <p className="text-xs text-text-secondary text-center mb-6">
                  {displayName} will use this PIN to log in and play.
                  You can reset it anytime from the parent dashboard.
                </p>

                {/* Buttons */}
                <div className="space-y-3">
                  <Button
                    type="submit"
                    variant="primary"
                    fullWidth
                    loading={isLoading}
                    disabled={!isPinValid || !doPinsMatch || isLoading}
                  >
                    Add {displayName}
                  </Button>

                  <Button
                    type="button"
                    variant="ghost"
                    fullWidth
                    onClick={() => {
                      setStep('name');
                      setPin('');
                      setConfirmPin('');
                      setError(null);
                    }}
                    disabled={isLoading}
                  >
                    ← Back
                  </Button>
                </div>
              </form>
            </Card>
          )}

          {/* Child Limit Warning */}
          {children.length >= 4 && (
            <p className="text-center text-text-secondary text-sm mt-4">
              You can add up to 5 children per family.
            </p>
          )}

        </div>
      </main>
    </div>
  );
}

export default AddChildScreen;
```

Export AddChildScreen component.
```

---

## Subphase 7.9a: Edit Child Screen

### Prompt for Claude Code:

```
Create the edit child display name screen.

File: src/hub/screens/EditChildScreen.tsx

```typescript
import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@/app/providers/AuthProvider';
import { Button, Card } from '@/ui';
import { Header } from '../components';
import { supabase } from '@/shared/services/supabase';

export function EditChildScreen() {
  const { childId } = useParams<{ childId: string }>();
  const navigate = useNavigate();
  const { children } = useAuth();

  // Find the child
  const child = children.find((c) => c.id === childId);

  // Form state
  const [displayName, setDisplayName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isSaved, setIsSaved] = useState(false);

  // Initialize form with current name
  useEffect(() => {
    if (child) {
      setDisplayName(child.displayName);
    }
  }, [child]);

  // Validation
  const isValid = displayName.trim().length >= 1 && displayName.trim().length <= 20;
  const hasChanged = child && displayName.trim() !== child.displayName;
  
  // Check for duplicates (excluding current child)
  const isDuplicate = children.some(
    (c) => c.id !== childId && c.displayName.toLowerCase() === displayName.trim().toLowerCase()
  );

  // Handle save
  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!displayName.trim()) {
      setError('Name cannot be empty');
      return;
    }

    if (displayName.trim().length > 20) {
      setError('Name must be 20 characters or less');
      return;
    }

    if (isDuplicate) {
      setError('Another child already has this name');
      return;
    }

    if (!hasChanged) {
      navigate(-1);
      return;
    }

    setIsLoading(true);

    try {
      if (!supabase || !childId) {
        throw new Error('Unable to save');
      }

      const { error: updateError } = await supabase
        .from('users')
        .update({ display_name: displayName.trim() })
        .eq('id', childId);

      if (updateError) {
        throw updateError;
      }

      // Show success briefly then navigate
      setIsSaved(true);
      setTimeout(() => {
        navigate(`/parent/child/${childId}`);
      }, 1000);

    } catch (err) {
      console.error('Error updating child:', err);
      setError('Failed to save changes. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  // Child not found
  if (!child) {
    return (
      <div className="min-h-screen flex flex-col bg-background-dark">
        <Header title="Edit Profile" showBack />
        <main className="flex-1 flex items-center justify-center">
          <p className="text-text-secondary">Child not found</p>
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Edit Profile" showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-md mx-auto">

          <Card className="p-6">
            {/* Success State */}
            {isSaved ? (
              <div className="text-center py-8">
                <div className="text-5xl mb-4">✓</div>
                <h2 className="text-xl font-bold text-accent-primary">Saved!</h2>
              </div>
            ) : (
              <form onSubmit={handleSave}>
                {/* Avatar Display */}
                <div className="text-center mb-6">
                  <div className="text-6xl mb-2">👽</div>
                  <p className="text-sm text-text-secondary">
                    Editing {child.displayName}'s profile
                  </p>
                </div>

                {/* Name Input */}
                <div className="mb-6">
                  <label className="block text-sm font-medium mb-2">
                    Display Name
                  </label>
                  <input
                    type="text"
                    value={displayName}
                    onChange={(e) => setDisplayName(e.target.value)}
                    maxLength={20}
                    autoFocus
                    className={`
                      w-full px-4 py-3 rounded-lg text-lg
                      bg-background-dark border-2 
                      ${error ? 'border-error' : 'border-white/20 focus:border-accent-primary'}
                      outline-none transition-colors
                    `}
                  />
                  <div className="flex justify-between mt-1">
                    {error ? (
                      <span className="text-xs text-error">{error}</span>
                    ) : (
                      <span className="text-xs text-text-secondary">
                        {hasChanged ? 'Unsaved changes' : 'No changes'}
                      </span>
                    )}
                    <span className="text-xs text-text-secondary">
                      {displayName.length}/20
                    </span>
                  </div>
                </div>

                {/* Buttons */}
                <div className="space-y-3">
                  <Button
                    type="submit"
                    variant="primary"
                    fullWidth
                    loading={isLoading}
                    disabled={!isValid || isDuplicate || isLoading}
                  >
                    {hasChanged ? 'Save Changes' : 'No Changes'}
                  </Button>

                  <Button
                    type="button"
                    variant="ghost"
                    fullWidth
                    onClick={() => navigate(-1)}
                    disabled={isLoading}
                  >
                    Cancel
                  </Button>
                </div>
              </form>
            )}
          </Card>

        </div>
      </main>
    </div>
  );
}

export default EditChildScreen;
```

Export EditChildScreen component.
```

---

## Subphase 7.9b: Reset PIN Screen

### Prompt for Claude Code:

```
Create the reset PIN screen for children.

File: src/hub/screens/ResetPinScreen.tsx

```typescript
import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@/app/providers/AuthProvider';
import { Button, Card } from '@/ui';
import { Header } from '../components';
import { setChildPin } from '@/shared/services/auth';

export function ResetPinScreen() {
  const { childId } = useParams<{ childId: string }>();
  const navigate = useNavigate();
  const { children } = useAuth();

  // Find the child
  const child = children.find((c) => c.id === childId);

  // Form state
  const [newPin, setNewPin] = useState('');
  const [confirmPin, setConfirmPin] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  // Validation
  const isPinValid = /^\d{4}$/.test(newPin);
  const doPinsMatch = newPin === confirmPin;
  const isWeakPin = ['0000', '1111', '1234', '4321', '0123', '9999'].includes(newPin);

  // Handle PIN input
  const handlePinChange = (value: string, setter: (v: string) => void) => {
    const digitsOnly = value.replace(/\D/g, '').slice(0, 4);
    setter(digitsOnly);
    setError(null);
  };

  // Handle submit
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!isPinValid) {
      setError('PIN must be exactly 4 digits');
      return;
    }

    if (!doPinsMatch) {
      setError('PINs do not match');
      return;
    }

    if (isWeakPin) {
      setError('Please choose a stronger PIN');
      return;
    }

    if (!childId) {
      setError('Child not found');
      return;
    }

    setIsLoading(true);

    try {
      const success = await setChildPin(childId, newPin);

      if (success) {
        setIsSuccess(true);
        setTimeout(() => {
          navigate(`/parent/child/${childId}`);
        }, 2000);
      } else {
        setError('Failed to reset PIN. Please try again.');
      }
    } catch (err) {
      console.error('Error resetting PIN:', err);
      setError('An error occurred. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  // Child not found
  if (!child) {
    return (
      <div className="min-h-screen flex flex-col bg-background-dark">
        <Header title="Reset PIN" showBack />
        <main className="flex-1 flex items-center justify-center">
          <p className="text-text-secondary">Child not found</p>
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Reset PIN" showBack />

      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-md mx-auto">

          <Card className="p-6">
            {/* Success State */}
            {isSuccess ? (
              <div className="text-center py-8">
                <div className="text-6xl mb-4">🔐</div>
                <h2 className="text-xl font-bold text-accent-primary mb-2">
                  PIN Updated!
                </h2>
                <p className="text-text-secondary">
                  {child.displayName}'s new PIN is ready to use.
                </p>
              </div>
            ) : (
              <form onSubmit={handleSubmit}>
                {/* Header */}
                <div className="text-center mb-6">
                  <div className="text-5xl mb-2">🔑</div>
                  <h2 className="text-xl font-bold">Reset PIN</h2>
                  <p className="text-sm text-text-secondary mt-1">
                    Create a new 4-digit PIN for {child.displayName}
                  </p>
                </div>

                {/* New PIN */}
                <div className="mb-4">
                  <label className="block text-sm font-medium mb-2">
                    New PIN
                  </label>
                  <input
                    type="password"
                    inputMode="numeric"
                    pattern="\d{4}"
                    maxLength={4}
                    value={newPin}
                    onChange={(e) => handlePinChange(e.target.value, setNewPin)}
                    placeholder="••••"
                    autoFocus
                    className={`
                      w-full px-4 py-4 rounded-lg text-center text-3xl tracking-[0.5em]
                      bg-background-dark border-2 
                      ${error && !isPinValid ? 'border-error' : 'border-white/20 focus:border-accent-primary'}
                      outline-none transition-colors font-mono
                    `}
                  />
                </div>

                {/* Confirm PIN */}
                <div className="mb-4">
                  <label className="block text-sm font-medium mb-2">
                    Confirm New PIN
                  </label>
                  <input
                    type="password"
                    inputMode="numeric"
                    pattern="\d{4}"
                    maxLength={4}
                    value={confirmPin}
                    onChange={(e) => handlePinChange(e.target.value, setConfirmPin)}
                    placeholder="••••"
                    className={`
                      w-full px-4 py-4 rounded-lg text-center text-3xl tracking-[0.5em]
                      bg-background-dark border-2 
                      ${error && !doPinsMatch ? 'border-error' : 'border-white/20 focus:border-accent-primary'}
                      outline-none transition-colors font-mono
                    `}
                  />
                </div>

                {/* PIN Feedback */}
                {newPin.length === 4 && (
                  <div className="text-center mb-4">
                    {isWeakPin ? (
                      <span className="text-yellow-400 text-sm">
                        ⚠️ This PIN is too easy to guess
                      </span>
                    ) : doPinsMatch ? (
                      <span className="text-accent-primary text-sm">
                        ✓ PINs match
                      </span>
                    ) : confirmPin.length === 4 ? (
                      <span className="text-error text-sm">
                        ✗ PINs don't match
                      </span>
                    ) : null}
                  </div>
                )}

                {/* Error */}
                {error && (
                  <p className="text-error text-sm text-center mb-4">{error}</p>
                )}

                {/* Info */}
                <p className="text-xs text-text-secondary text-center mb-6">
                  Make sure to tell {child.displayName} their new PIN so they can log in.
                </p>

                {/* Buttons */}
                <div className="space-y-3">
                  <Button
                    type="submit"
                    variant="primary"
                    fullWidth
                    loading={isLoading}
                    disabled={!isPinValid || !doPinsMatch || isWeakPin || isLoading}
                  >
                    Reset PIN
                  </Button>

                  <Button
                    type="button"
                    variant="ghost"
                    fullWidth
                    onClick={() => navigate(-1)}
                    disabled={isLoading}
                  >
                    Cancel
                  </Button>
                </div>
              </form>
            )}
          </Card>

        </div>
      </main>
    </div>
  );
}

export default ResetPinScreen;
```

Export ResetPinScreen component.
```

---

## Subphase 7.10a: Parent Settings Screen

### Prompt for Claude Code:

```
Create the parent settings and family management screen.

File: src/hub/screens/ParentSettingsScreen.tsx

```typescript
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/app/providers/AuthProvider';
import { Button, Card, Modal } from '@/ui';
import { Header } from '../components';

export function ParentSettingsScreen() {
  const navigate = useNavigate();
  const { user, family, children, signOut } = useAuth();

  // Modal states
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [showResetConfirm, setShowResetConfirm] = useState(false);
  const [deleteConfirmText, setDeleteConfirmText] = useState('');
  
  // Loading states
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  // Handle logout
  const handleLogout = async () => {
    setIsLoggingOut(true);
    try {
      await signOut();
      navigate('/login');
    } catch (err) {
      console.error('Logout error:', err);
    } finally {
      setIsLoggingOut(false);
      setShowLogoutConfirm(false);
    }
  };

  // Calculate family stats
  const totalCoins = children.reduce((sum, c) => sum + c.coins, 0);

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
                onClick={() => {/* TODO: Implement family name edit */}}
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
                onClick={() => {/* TODO: Implement data export */}}
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
                onClick={() => {/* TODO: Implement password change */}}
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
      <Modal
        isOpen={showLogoutConfirm}
        onClose={() => setShowLogoutConfirm(false)}
        title="Log Out?"
      >
        <p className="text-text-secondary mb-6">
          Are you sure you want to log out? You'll need to sign in again to access your family's data.
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
          <Button
            variant="secondary"
            fullWidth
            onClick={handleLogout}
            loading={isLoggingOut}
          >
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
          <p className="text-error text-sm font-medium mb-6">
            This action cannot be undone!
          </p>
        </div>
        <div className="flex gap-3">
          <Button
            variant="ghost"
            fullWidth
            onClick={() => setShowResetConfirm(false)}
          >
            Cancel
          </Button>
          <Button
            variant="secondary"
            fullWidth
            className="bg-yellow-600 hover:bg-yellow-500"
            onClick={() => {
              // TODO: Implement reset
              setShowResetConfirm(false);
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
          setShowDeleteConfirm(false);
          setDeleteConfirmText('');
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
              setShowDeleteConfirm(false);
              setDeleteConfirmText('');
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
              console.log('Delete account');
            }}
          >
            Delete Forever
          </Button>
        </div>
      </Modal>
    </div>
  );
}

// Helper component
interface InfoRowProps {
  label: string;
  value: string;
  valueClass?: string;
}

function InfoRow({ label, value, valueClass }: InfoRowProps) {
  return (
    <div className="flex justify-between items-center py-2 border-b border-white/5 last:border-0">
      <span className="text-text-secondary">{label}</span>
      <span className={`font-medium ${valueClass || ''}`}>{value}</span>
    </div>
  );
}

export default ParentSettingsScreen;
```

Export ParentSettingsScreen component.
```

---

## Subphase 7.10b: Route Registration

### Prompt for Claude Code:

```
Register all parent dashboard routes and create index files.

1. Update src/app/routes.tsx with all parent routes:

```typescript
// Add these imports
import {
  ParentDashboard,
  ChildDetailScreen,
  ActivityHistoryScreen,
  AddChildScreen,
  EditChildScreen,
  ResetPinScreen,
  ParentSettingsScreen,
} from '@/hub/screens';

// Add these routes to the routes array:
{
  path: '/parent/dashboard',
  element: <ParentDashboard />,
},
{
  path: '/parent/child/:childId',
  element: <ChildDetailScreen />,
},
{
  path: '/parent/child/:childId/activity',
  element: <ActivityHistoryScreen />,
},
{
  path: '/parent/child/:childId/edit',
  element: <EditChildScreen />,
},
{
  path: '/parent/child/:childId/reset-pin',
  element: <ResetPinScreen />,
},
{
  path: '/parent/add-child',
  element: <AddChildScreen />,
},
{
  path: '/parent/settings',
  element: <ParentSettingsScreen />,
},
```

2. Update src/hub/screens/index.ts:

```typescript
// Existing exports
export { SplashScreen } from './SplashScreen';
export { LoginScreen } from './LoginScreen';
export { FamilySelectScreen } from './FamilySelectScreen';
export { MainHubScreen } from './MainHubScreen';
export { ModuleSelectScreen } from './ModuleSelectScreen';
export { SettingsScreen } from './SettingsScreen';

// Parent dashboard exports
export { ParentDashboard } from './ParentDashboard';
export { ChildDetailScreen } from './ChildDetailScreen';
export { ActivityHistoryScreen } from './ActivityHistoryScreen';
export { AddChildScreen } from './AddChildScreen';
export { EditChildScreen } from './EditChildScreen';
export { ResetPinScreen } from './ResetPinScreen';
export { ParentSettingsScreen } from './ParentSettingsScreen';
```

3. Update src/hub/components/index.ts:

```typescript
export { Header } from './Header';
export { CoinDisplay } from './CoinDisplay';
export { PinEntryModal } from './PinEntryModal';
export { ChildSummaryCard } from './ChildSummaryCard';
export { ActivityChart } from './ActivityChart';
```

4. Update src/hub/types/index.ts:

```typescript
export * from './dashboard';
```

5. Test the complete parent dashboard flow:
   - Navigate to parent dashboard from family select
   - View children list with weekly stats
   - Click child to see detailed stats
   - View activity chart with metric switching
   - View full activity history with period filtering
   - Add a new child with avatar and PIN
   - Edit child's display name
   - Reset child's PIN
   - Access parent settings
   - Log out from settings
```

---

## Phase 7.3 Completion Checklist

After completing all subphases, verify:

- [ ] Add child: Two-step flow (name → PIN) works
- [ ] Add child: Avatar selection works
- [ ] Add child: Name validation (length, duplicates) works
- [ ] Add child: PIN validation (4 digits, matching, strength) works
- [ ] Add child: Weak PIN warning shows
- [ ] Add child: Successfully creates child and navigates
- [ ] Edit child: Loads current name
- [ ] Edit child: Validates changes
- [ ] Edit child: Saves to database
- [ ] Edit child: Shows success state
- [ ] Reset PIN: Validates new PIN
- [ ] Reset PIN: Confirms matching PINs
- [ ] Reset PIN: Saves new PIN
- [ ] Reset PIN: Shows success state
- [ ] Settings: Shows account info
- [ ] Settings: Family management buttons work
- [ ] Settings: Logout confirmation works
- [ ] Settings: Reset progress confirmation shows
- [ ] Settings: Delete account requires typing DELETE
- [ ] All routes registered correctly
- [ ] Navigation between all screens works

---

## Files Created in Phase 7.3

```
src/hub/screens/
├── AddChildScreen.tsx
├── EditChildScreen.tsx
├── ResetPinScreen.tsx
└── ParentSettingsScreen.tsx

src/hub/screens/index.ts (updated)
src/hub/components/index.ts (updated)
src/hub/types/index.ts (created)
src/app/routes.tsx (updated)
```

---

## Complete Parent Dashboard Flow

```
[Family Select]
       │
       ├── Parent Dashboard ──────────────────────────────────────┐
       │         │                                                │
       │         ├── Child Card ──► [Child Detail]                │
       │         │                       │                        │
       │         │                       ├── Chart (embedded)     │
       │         │                       ├── Module Progress      │
       │         │                       │                        │
       │         │                       ├── Activity ──► [Activity History]
       │         │                       │                        │
       │         │                       ├── Edit ──► [Edit Child]
       │         │                       │                        │
       │         │                       ├── Reset PIN ──► [Reset PIN]
       │         │                       │                        │
       │         │                       └── Remove ──► Modal     │
       │         │                                                │
       │         ├── Add Child ──► [Add Child Screen]             │
       │         │                       │                        │
       │         │                       ├── Step 1: Name/Avatar  │
       │         │                       └── Step 2: PIN          │
       │         │                                                │
       │         └── Settings ──► [Parent Settings]               │
       │                               │                          │
       │                               ├── Manage Children ───────┘
       │                               ├── Add Child
       │                               ├── Rename Family
       │                               ├── Export Data
       │                               ├── Reset Progress ──► Modal
       │                               ├── Change Password
       │                               ├── Log Out ──► Modal
       │                               └── Delete Account ──► Modal
       │
       └── Select Child ──► [Main Hub] (child mode)
```

---

*End of Phase 7.3 - Parent Dashboard Complete*
