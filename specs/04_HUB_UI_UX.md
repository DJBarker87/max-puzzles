# Max's Puzzles - Hub UI/UX Specification

**Version:** 1.2  
**Last Updated:** January 2025  
**Author:** Dom Barker

---

## Overview

This document specifies the user interface for the hub (shared screens), not the individual puzzle modules. Module-specific UI is documented separately.

**Version notes:**
- Avatar display and Shop: V3 only
- Stars display: V2 only

---

## Design Principles

1. **Child-friendly** - Large touch targets, clear icons, minimal text
2. **Fun aesthetic** - Colourful, playful, space/alien theme
3. **Simple navigation** - Maximum 2 taps to reach any feature
4. **Responsive** - Works on mobile and desktop
5. **Accessible** - Good contrast, no colour-only information

---

## Colour Palette

| Element | Colour | Hex | Usage |
|---------|--------|-----|-------|
| Background (dark) | Deep space blue | #0f0f23 | Main backgrounds |
| Background (mid) | Space purple | #1a1a3e | Cards, panels |
| Accent primary | Cosmic green | #22c55e | Success, positive |
| Accent secondary | Nebula pink | #e94560 | Buttons, highlights |
| Accent tertiary | Star gold | #fbbf24 | Coins, stars |
| Text primary | White | #ffffff | Headings |
| Text secondary | Light grey | #a1a1aa | Body text |
| Error | Red | #ef4444 | Errors, mistakes |

---

## Typography

| Element | Font | Size (mobile) | Size (desktop) |
|---------|------|---------------|----------------|
| Heading 1 | Rounded sans-serif | 28px | 36px |
| Heading 2 | Rounded sans-serif | 22px | 28px |
| Body | Sans-serif | 16px | 18px |
| Button | Sans-serif bold | 18px | 20px |
| Caption | Sans-serif | 14px | 14px |

Use a playful, rounded font for headings (e.g., Nunito, Quicksand).

---

## Screen Flow

```
┌─────────────┐
│   Splash    │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│   Login /   │────►│   Family    │
│   Signup    │     │   Select    │
└──────┬──────┘     └──────┬──────┘
       │                   │
       │ (guest)           │ (child selected)
       ▼                   ▼
┌─────────────────────────────────┐
│           Main Hub              │
├─────────────────────────────────┤
│  ┌─────┐  ┌─────┐  ┌─────────┐ │
│  │Play │  │Shop │  │Settings │ │
│  └──┬──┘  └──┬──┘  └────┬────┘ │
└─────┼────────┼──────────┼──────┘
      │        │          │
      ▼        ▼          ▼
┌─────────┐ ┌─────┐ ┌──────────┐
│ Module  │ │Shop │ │ Settings │
│ Select  │ │     │ │          │
└────┬────┘ └─────┘ └──────────┘
     │
     ▼
┌──────────────┐
│    Module    │
│  (e.g. CC)   │
└──────────────┘
```

---

## Screen Specifications

### 1. Splash Screen

**Purpose:** Brief loading screen while app initialises

**Elements:**
- App logo (Max's Puzzles with alien mascot)
- Loading indicator (subtle animation)
- Background: Starfield or space scene

**Duration:** Maximum 2 seconds, then auto-advance

---

### 2. Login / Signup Screen

**Purpose:** Account access or guest play

**Layout:**
```
┌─────────────────────────────────┐
│                                 │
│         [App Logo]              │
│                                 │
│   ┌─────────────────────────┐   │
│   │    Play as Guest        │   │  ← Big, prominent
│   └─────────────────────────┘   │
│                                 │
│   ┌────────────┐ ┌────────────┐ │
│   │   Login    │ │  Sign Up   │ │
│   └────────────┘ └────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**Behaviour:**
- "Play as Guest" → Main Hub (no account)
- "Login" → Login form
- "Sign Up" → Signup flow

---

### 3. Family Select Screen

**Purpose:** Choose which family member is playing

**Layout:**
```
┌─────────────────────────────────┐
│  Who's Playing?                 │
├─────────────────────────────────┤
│                                 │
│  ┌─────┐  ┌─────┐  ┌─────┐     │
│  │ 👽  │  │ 👽  │  │ 👽  │     │
│  │ Max │  │ Lily│  │ Tom │     │
│  └─────┘  └─────┘  └─────┘     │
│                                 │
│  ┌─────────────────────────┐   │
│  │   Parent Dashboard  →   │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │   Play as Parent  →     │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

**Behaviour:**
- Tap child → PIN entry → Main Hub
- Tap "Parent Dashboard" → Parent PIN → Dashboard
- Tap "Play as Parent" → Quick Play demo mode (nothing tracked/saved)

---

### 4. PIN Entry

**Purpose:** Simple numeric PIN for child login

**Layout:**
```
┌─────────────────────────────────┐
│                                 │
│         [Child Avatar]          │
│           Max                   │
│                                 │
│        ● ● ○ ○                  │  ← PIN dots
│                                 │
│   ┌───┐ ┌───┐ ┌───┐            │
│   │ 1 │ │ 2 │ │ 3 │            │
│   └───┘ └───┘ └───┘            │
│   ┌───┐ ┌───┐ ┌───┐            │
│   │ 4 │ │ 5 │ │ 6 │            │
│   └───┘ └───┘ └───┘            │
│   ┌───┐ ┌───┐ ┌───┐            │
│   │ 7 │ │ 8 │ │ 9 │            │
│   └───┘ └───┘ └───┘            │
│         ┌───┐                   │
│         │ 0 │                   │
│         └───┘                   │
│                                 │
│         [Back]                  │
└─────────────────────────────────┘
```

**Behaviour:**
- Large number buttons (child-friendly)
- Dots fill as PIN entered
- Auto-submit on 4 digits
- Shake animation on wrong PIN
- Back button returns to family select

---

### 5. Main Hub

**Purpose:** Central navigation point

**Layout:**
```
┌─────────────────────────────────┐
│ ≡  Max's Puzzles       🪙 1,234 │  ← Header
├─────────────────────────────────┤
│                                 │
│         ┌─────────┐             │
│         │   👽    │             │  ← Avatar (tappable)
│         │  Max    │             │
│         └─────────┘             │
│                                 │
│   ┌─────────────────────────┐   │
│   │      🎮 PLAY            │   │  ← Primary action
│   └─────────────────────────┘   │
│                                 │
│   ┌───────────┐ ┌───────────┐   │
│   │ 🛒 Shop   │ │ ⚙ Settings│   │
│   └───────────┘ └───────────┘   │
│                                 │
└─────────────────────────────────┘
```

**Header:**
- Hamburger menu (≡) → Settings, Logout, About
- App title
- Coin balance with icon (always visible)

**Behaviour:**
- Tap avatar → Shop (customisation focus)
- Tap PLAY → Module Select
- Tap Shop → Shop screen
- Tap Settings → Settings screen

---

### 6. Module Select

**Purpose:** Choose which puzzle to play

**Layout:**
```
┌─────────────────────────────────┐
│ ←  Choose a Puzzle     🪙 1,234 │
├─────────────────────────────────┤
│                                 │
│   ┌─────────────────────────┐   │
│   │  ⚡ Circuit Challenge   │   │
│   │  Navigate the circuit!  │   │
│   │  ★★★☆☆ Level 5         │   │
│   └─────────────────────────┘   │
│                                 │
│   ┌─────────────────────────┐   │
│   │  🔒 Coming Soon         │   │  ← Locked/future
│   │  More puzzles on the    │   │
│   │  way!                   │   │
│   └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

**Module Card Contents:**
- Icon
- Name
- Short description
- Progress indicator (stars or level)

**Behaviour:**
- Tap module → Enter module's menu
- Locked modules show teaser, not tappable

---

### 7. Shop Screen

**Purpose:** Browse and purchase avatar items

**Layout:**
```
┌─────────────────────────────────┐
│ ←  Shop                🪙 1,234 │
├─────────────────────────────────┤
│                                 │
│      ┌───────────┐              │
│      │    👽     │              │  ← Live avatar preview
│      └───────────┘              │
│                                 │
│ [Heads][Eyes][Body][Arms][Acc]  │  ← Category tabs
├─────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐│
│ │ ○○○ │ │ ●●● │ │ ◐◐◐ │ │ ○-○ ││  ← Items grid
│ │ 100 │ │ ✓   │ │ 150 │ │ 200 ││
│ └─────┘ └─────┘ └─────┘ └─────┘│
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐│
│ │     │ │     │ │     │ │     ││
│ │     │ │     │ │     │ │     ││
│ └─────┘ └─────┘ └─────┘ └─────┘│
│                                 │
└─────────────────────────────────┘
```

**Item Display:**
- Preview image
- Price (or ✓ if owned)
- Highlight if currently equipped

**Behaviour:**
- Tap item → Preview on avatar
- "Buy" button appears for unowned items
- Confirm purchase modal
- "Equip" button for owned items
- Changes save automatically

---

### 8. Settings Screen

**Purpose:** App configuration

**Layout:**
```
┌─────────────────────────────────┐
│ ←  Settings                     │
├─────────────────────────────────┤
│                                 │
│  Sound Effects          [ON ]   │
│  Music                  [OFF]   │
│  Animations             [ON ]   │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  [  Create Account  ]           │  ← If guest
│                                 │
│  [  Switch User     ]           │  ← If logged in
│  [  Log Out         ]           │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  About Max's Puzzles            │
│  Version 1.0.0                  │
│                                 │
└─────────────────────────────────┘
```

---

### 9. Parent Dashboard

**Purpose:** Monitor children's progress

**Layout:**
```
┌─────────────────────────────────┐
│ ←  Parent Dashboard             │
├─────────────────────────────────┤
│                                 │
│  Your Family                    │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 👽 Max                  │   │
│  │ 🪙 1,234  ⭐ 38  📅 Today│   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 👽 Lily                 │   │
│  │ 🪙 567   ⭐ 12  📅 2d ago│   │
│  └─────────────────────────┘   │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  [  Add Child  ]                │
│  [  Family Settings  ]          │
│                                 │
└─────────────────────────────────┘
```

**Child Detail View (tap child):**
```
┌─────────────────────────────────┐
│ ←  Max's Progress               │
├─────────────────────────────────┤
│                                 │
│      ┌───────────┐              │
│      │    👽     │  🪙 1,234    │
│      │   Max     │  ⭐ 38 stars │
│      └───────────┘              │
│                                 │
│  This Week                      │
│  ├─ Played: 2h 15m              │
│  ├─ Correct: 156                │
│  ├─ Mistakes: 23                │
│  └─ Accuracy: 87%               │
│                                 │
│  Circuit Challenge              │
│  ├─ Levels: 15/30               │
│  ├─ Stars: 38/90                │
│  └─ Games: 47                   │
│                                 │
│  Recent Activity                │
│  ├─ Today 4:30pm - CC - 15min   │
│  ├─ Yesterday - CC - 22min      │
│  └─ [View All]                  │
│                                 │
└─────────────────────────────────┘
```

---

## Responsive Behaviour

### Mobile (< 768px)

- Single column layout
- Full-width buttons
- Bottom navigation optional
- Touch-optimised (44px minimum targets)

### Tablet (768px - 1024px)

- Two-column layouts where appropriate
- Larger touch targets
- Side-by-side buttons

### Desktop (> 1024px)

- Centred content with max-width
- Hover states on interactive elements
- Keyboard navigation support

---

## Animations

| Trigger | Animation | Duration |
|---------|-----------|----------|
| Screen transition | Slide left/right | 300ms |
| Button press | Scale down slightly | 100ms |
| Coin change | Number rolls + sparkle | 500ms |
| Avatar equip | Item slides into place | 300ms |
| Error | Shake horizontally | 300ms |
| Success | Pulse green | 400ms |

---

## Sound Effects (Future)

| Action | Sound |
|--------|-------|
| Button tap | Soft click |
| Coin earned | Cha-ching |
| Purchase | Register ding |
| Error | Soft buzz |
| Navigation | Whoosh |

---

## Accessibility

- All interactive elements have focus states
- Minimum contrast ratio 4.5:1
- No information conveyed by colour alone
- Screen reader labels on all buttons
- Reduced motion option respects system preference

---

*End of Document 4*
