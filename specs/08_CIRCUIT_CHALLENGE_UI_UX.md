# Circuit Challenge - UI/UX Specification

**Version:** 1.2  
**Last Updated:** January 2025  
**Author:** Dom Barker

---

## Overview

This document specifies the user interface for the Circuit Challenge module, including the puzzle grid, gameplay screens, animations, and print output.

---

## Design Principles

1. **Clear visibility** - Numbers and calculations easy to read
2. **Satisfying feedback** - Every action has clear response
3. **Circuit aesthetic** - Electric/tech feel with flowing energy
4. **Child-friendly** - Large touch targets, forgiving interactions
5. **Living circuit** - Visited path pulses and flows continuously

---

## Background

### Starry Space Theme

The puzzle sits against a **subtle starry space background** that enhances the electric/tech aesthetic without distracting from gameplay.

**Implementation:**
- Deep gradient background: #0a0a12 → #12121f → #0d0d18
- 80 randomly positioned star elements (1-3px diameter)
- Stars twinkle with staggered animations (3-5 second cycles)
- Very subtle opacity range (0.3 → 0.8) to avoid distraction
- Ambient green glow overlay (3% opacity) for cohesion

```css
@keyframes twinkle {
  0%, 100% { opacity: 0.3; transform: scale(1); }
  50% { opacity: 0.8; transform: scale(1.2); }
}
```

Stars are rendered as absolutely positioned divs with varying twinkle animation delays for a natural, asynchronous effect.

---

## Colour Palette (Module-Specific)

Extends the hub palette with circuit-themed colours:

| Element | Colour | Hex | Usage |
|---------|--------|-----|-------|
| Cell (normal) top | Dark grey gradient | #3a3a4a → #252530 | Unvisited cells |
| Cell (normal) edge | Darker grey | #1a1a25 → #0f0f15 | 3D edge/depth |
| Cell (start) | Bright green | #15803d → #0d5025 | START cell |
| Cell (finish) | Gold | #ca8a04 → #854d0e | FINISH cell |
| Cell (current) | Teal | #0d9488 → #086560 | Player's current position |
| Cell (visited) | Dim green | #1a5c38 → #103822 | Already visited (pulses) |
| Connector (default) | Brown/copper | #3d3428 | Inactive connectors |
| Connector (active) | Electric green | #00dd77 | Traversed connectors |
| Connector glow | Bright green | #00ff88 | Glow effect on active |
| Connector energy | White/cyan | #ffffff, #88ffcc | Flowing energy particles |
| Connector number BG | Dark | #15151f | Number badge background |
| Connector number text | Orange | #ff9f43 | Number text |
| Expression text | White | #ffffff | Calculation text |
| Grid background | Deep space blue | #0a0a12 → #0d0d18 | Behind the grid with stars |
| Hearts (active) | Pink/red | #ff3366 | Lives remaining (pulse) |
| Hearts (inactive) | Dark grey | #2a2a3a | Lives lost |
| Coins | Gold | #fbbf24 | Currency display |

---

## Grid Rendering

### Hexagon Cells

Cells are regular hexagons with flat tops, rendered with a **3D "poker chip" effect** for depth and visual appeal.

```
      ____
     /    \      ← Top face (gradient fill)
    /      \
    \      /     ← Visible edge layers create 3D depth
     \____/
       ▓▓        ← Shadow underneath
```

### 3D Cell Construction

Each hexagon is composed of multiple layered polygons:

| Layer | Offset | Purpose |
|-------|--------|---------|
| Shadow | translate(4, 14) | Soft shadow beneath cell |
| Edge | translate(0, 12) | Visible 3D side/rim |
| Base | translate(0, 6) | Middle depth layer |
| Top | translate(0, 0) | Main face with gradient |
| Inner shadow | (none) | Subtle depth on top face |
| Rim highlight | (none) | Bright edge highlight |

This creates approximately **12px of visible depth**, giving cells a satisfying, tangible quality like game pieces.

### Cell Dimensions

| Screen Size | Hexagon Width | Touch Target |
|-------------|---------------|--------------|
| Mobile (<768px) | 60-70px | 70px |
| Tablet (768-1024px) | 80-90px | 90px |
| Desktop (>1024px) | 90-100px | 100px |

### Cell Contents

Each cell displays:
- Calculation text (e.g., "5 + 8") centred
- Font size scales with cell size
- START cell: "START" text + green fill
- FINISH cell: "FINISH" text + gold fill

### Cell States

| State | Fill (gradient) | Border | Text | Effect |
|-------|-----------------|--------|------|--------|
| Normal | #3a3a4a → #252530 | #4a4a5a | White | None |
| Start | #15803d → #0d5025 | #00ff88 | White | Subtle glow |
| Finish | #ca8a04 → #854d0e | #ffcc00 | Gold (#ffdd44) | Subtle glow |
| Current | #0d9488 → #086560 | #00ffcc | White | Pulsing glow (1.5s cycle) |
| Visited | #1a5c38 → #103822 | #00ff88 | White (70% opacity) | Pulsing glow (2s cycle) |
| Wrong (reveal) | #ef4444 | #dc2626 | White | Flash animation |

**Visited cells pulse** with a subtle glow animation, cycling between 30% and 60% glow intensity over 2 seconds. This provides constant visual feedback showing the path taken.

---

## Connector Rendering

### Connector Appearance

Connectors are lines/paths between cell centres with a number badge at the midpoint. Active connectors feature a **multi-layered electric flow effect**.

```
    [Cell A] ═══●═══ [Cell B]
               12
```

### Connector Dimensions

| Element | Size |
|---------|------|
| Line thickness (default) | 8px |
| Line thickness (active) | 10px + glow layers |
| Number badge | 32×28px rounded rectangle |
| Number font | 14px bold |

### Connector Layer Structure (Active/Traversed)

Active connectors use multiple overlapping lines for the electric effect:

| Layer | Width | Colour | Animation |
|-------|-------|--------|-----------|
| Glow | 18px | #00ff88 (50% opacity, blurred) | Pulses 1.5s |
| Main line | 10px | #00dd77 | Static |
| Energy 2 | 6px | #88ffcc | Flows (dash 6 30, 1.2s) |
| Energy 1 | 4px | #ffffff | Flows (dash 4 20, 0.8s) |
| Core | 3px | #aaffcc | Static |

### Connector Types

**Horizontal:**
```
[Cell] ────●──── [Cell]
```

**Vertical:**
```
[Cell]
   │
   ●
   │
[Cell]
```

**Diagonal (DR):**
```
[Cell]
    ╲
     ●
      ╲
    [Cell]
```

**Diagonal (DL):**
```
     [Cell]
       ╱
      ●
     ╱
[Cell]
```

### Connector States

| State | Line Colour | Badge BG | Badge Text | Animation |
|-------|-------------|----------|------------|-----------|
| Default | #3d3428 | #15151f | #ff9f43 | None |
| Traversed | #00dd77 + layers | #15151f | #ff9f43 | Electric flow + pulse |
| Wrong (reveal) | #ef4444 | #7f1d1d | #ef4444 | Flash |

---

## The "Electric Flow" Animation

**The signature visual effect showing energy flowing through the circuit.**

### Continuous Flow Effect

Once a connector is traversed, it displays a **continuous flowing energy animation** that persists for the remainder of the puzzle. This creates a visual "circuit" showing the complete path taken.

### Animation Layers

The flow effect uses multiple animated layers:

```css
/* Energy particle layer 1 - fast white particles */
.connector-line-energy {
  stroke: #ffffff;
  stroke-width: 4px;
  stroke-dasharray: 4 20;
  animation: electricFlow 0.8s linear infinite;
}

/* Energy particle layer 2 - slower cyan particles */
.connector-line-energy2 {
  stroke: #88ffcc;
  stroke-width: 6px;
  stroke-dasharray: 6 30;
  animation: electricFlow 1.2s linear infinite;
  animation-delay: -0.4s;
}

@keyframes electricFlow {
  0% { stroke-dashoffset: 0; }
  100% { stroke-dashoffset: -36; }
}

/* Overall connector glow pulse */
.connector.traversed {
  animation: connectorPulse 1.5s ease-in-out infinite;
}

@keyframes connectorPulse {
  0%, 100% { filter: drop-shadow(0 0 8px rgba(0,255,136,0.6)); }
  50% { filter: drop-shadow(0 0 16px rgba(0,255,170,0.9)); }
}
```

### Visual Effect Description

1. **Glow layer**: Blurred green glow (18px) pulses in intensity
2. **Main line**: Solid electric green (#00dd77)
3. **Energy particles**: Two layers of dashed lines animate along the connector
   - White particles (small, fast) travel the path
   - Cyan particles (larger, slower, offset) create depth
4. **Bright core**: Thin bright line (#aaffcc) down the centre

### Triggering the Animation

When a player makes a correct move:

1. **Immediate**: Connector transitions from brown to green
2. **Instant start**: Energy flow animation begins immediately
3. **Persists**: Animation continues indefinitely
4. **Cumulative**: Each correct move adds another animated connector, building the complete circuit

### All Visited Cells Pulse

Visited hexagon cells also pulse with a subtle glow (2s cycle), reinforcing the "live circuit" aesthetic. The entire path—cells and connectors—appears to carry flowing energy.

---

## Gameplay Screen Layout

### Mobile Layout (Portrait)

```
┌─────────────────────────────────┐
│ ←  Level 3-2          🪙 1,234  │  ← Header
├─────────────────────────────────┤
│ ♥ ♥ ♥ ♥ ♥              ⏱ 0:45  │  ← Lives + Timer
├─────────────────────────────────┤
│                                 │
│                                 │
│         ┌───────────┐           │
│         │   PUZZLE  │           │
│         │    GRID   │           │
│         │           │           │
│         └───────────┘           │
│                                 │
│                                 │
├─────────────────────────────────┤
│    [🔄 Reset]    [🖨️ Print]    │  ← Action buttons
└─────────────────────────────────┘
```

### Desktop Layout

```
┌─────────────────────────────────────────────────────────┐
│ ←  Circuit Challenge - Level 3-2              🪙 1,234  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│    ♥ ♥ ♥ ♥ ♥                              ⏱ 0:45      │
│                                                         │
│              ┌─────────────────────────┐                │
│              │                         │                │
│              │      PUZZLE GRID        │                │
│              │                         │                │
│              │                         │                │
│              └─────────────────────────┘                │
│                                                         │
│              [🔄 Reset]  [🖨️ Print]                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Header Bar

| Element | Position | Content |
|---------|----------|---------|
| Back arrow | Left | Returns to module menu |
| Title | Centre | "Level X-Y" or "Quick Play" |
| Coins | Right | Current balance with icon |

---

## Lives Display

Five heart icons representing lives:

| State | Appearance |
|-------|------------|
| Full | ♥ (pink #ff3366, pulsing glow) |
| Lost | ♥ (dark grey #2a2a3a, no animation) |
| Losing | ♥ → ♥ (fade + shake animation) |

**Active hearts pulse** continuously with a gentle scale animation (1.0 → 1.15 → 1.0 over 1.2s), providing a "heartbeat" effect that adds life to the UI.

```css
@keyframes heartPulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.15); }
}
```

When a life is lost:
1. Heart shakes horizontally (3 oscillations)
2. Fades from pink to dark grey (0.3s)
3. Stops pulsing, stays grey

---

## Timer Display

- Shows elapsed time: MM:SS format
- Ticks every second
- Green when under 3-star threshold
- Yellow when approaching threshold
- No colour change in Hidden Mode (no time pressure shown)

---

## Action Buttons

Action buttons are displayed in a **fixed button bar** at the bottom of the screen.

### Button Bar Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  [🔄 Reset]  [✨ New Puzzle]  [⚙️ Difficulty]  [🖨️ Print]          │
└─────────────────────────────────────────────────────────────────────┘
```

### Button Styles

| Button | Style | Action |
|--------|-------|--------|
| Reset | Secondary (dark gradient) | Restart **same puzzle** (same grid, same path) |
| New Puzzle | Primary (green gradient) | Generate **fresh puzzle** at current difficulty |
| Difficulty | Secondary (dark gradient) | Open difficulty settings |
| Print Puzzle | Secondary (dark gradient) | Generate LaTeX PDF → Download |

**Reset Button:**
- Restarts the exact same puzzle
- Lives, timer, coins reset to initial state
- Player can retry and learn from mistakes
- No confirmation dialog needed

**New Puzzle Button:**
- Generates a completely new puzzle
- Same difficulty settings as current
- Fresh grid, new calculations, new path

**Primary button:**
- Background: linear-gradient(#22c55e, #16a34a)
- Green glow shadow
- White text

**Secondary button:**
- Background: linear-gradient(#2a2a40, #1a1a2a)
- Subtle border (15% white)
- White text

All buttons:
- 12px 24px padding
- 12px border radius
- Hover: lift 2px with enhanced shadow
- Icon + text layout with 8px gap

### Print Button

- Icon: 🖨️ or printer
- Action: Generate LaTeX PDF → Download
- Available during gameplay

---

## Interaction Feedback

### Tapping a Cell

**Adjacent, unvisited cell:**
- Slight scale-up on press (1.05×)
- Release triggers move evaluation

**Non-adjacent cell:**
- Nothing happens (ignored)

**Visited cell:**
- Brief flash/shake to indicate can't revisit
- No penalty

**Current cell:**
- Nothing happens

### Correct Move

1. Current cell returns to "visited" state
2. Connector flow animation (1s)
3. New cell becomes "current"
4. Coin counter: +10 (float up animation)
5. Subtle success sound (if enabled)

### Wrong Move

1. Screen shakes (0.3s)
2. Current cell flashes red briefly
3. Life heart breaks
4. Coin counter: -30 (float up in red)
5. Error sound (if enabled)
6. Player stays on current cell

### Reaching FINISH

1. Connector flow animation
2. FINISH cell pulses gold
3. Celebration animation (confetti/sparkles)
4. Pause (0.5s)
5. Transition to summary screen

---

## Summary Screen

### Standard Mode Win

```
┌─────────────────────────────────┐
│                                 │
│        🎉 Puzzle Complete! 🎉   │
│                                 │
│           ⭐ ⭐ ⭐               │  ← Stars earned
│                                 │
│        Time: 1:23               │
│        Coins: +80               │
│        Mistakes: 0              │
│                                 │
│    ┌─────────────────────────┐  │
│    │      Next Level →       │  │  ← Or "Play Again"
│    └─────────────────────────┘  │
│                                 │
│    [Retry]        [Exit]        │
│                                 │
└─────────────────────────────────┘
```

### Hidden Mode Win

```
┌─────────────────────────────────┐
│                                 │
│        Puzzle Complete!         │
│                                 │
│        Results:                 │
│        ✓ Correct: 12            │
│        ✗ Mistakes: 2            │
│        Accuracy: 86%            │
│                                 │
│        Coins: +60               │
│        (120 earned - 60 penalty)│
│                                 │
│    [View Mistakes]  [Continue]  │
│                                 │
└─────────────────────────────────┘
```

"View Mistakes" shows the grid with wrong moves highlighted in red.

### Game Over (Lost)

```
┌─────────────────────────────────┐
│                                 │
│          Out of Lives           │
│                                 │
│             💔                  │
│                                 │
│        Coins: +0                │
│                                 │
│    ┌─────────────────────────┐  │
│    │       Try Again         │  │
│    └─────────────────────────┘  │
│                                 │
│    [See Solution]   [Exit]      │
│                                 │
└─────────────────────────────────┘
```

---

## Quick Play Difficulty Selector

```
┌─────────────────────────────────┐
│ ←  Quick Play                   │
├─────────────────────────────────┤
│                                 │
│  Difficulty                     │
│  ┌─────────────────────────┐    │
│  │ [▼] Level 5: Times Tables │  │
│  └─────────────────────────┘    │
│                                 │
│  Or customise:                  │
│                                 │
│  Operations                     │
│  [✓] +  [✓] −  [✓] ×  [ ] ÷   │
│                                 │
│  +/− Range: 20                  │
│  [====●===================]     │
│                                 │
│  ×/÷ Range: 5                   │
│  [===●====================]     │
│                                 │
│  Grid: 4 × 5                    │
│  Rows [4]  Cols [5]             │
│                                 │
│  [ ] Hidden Mode                │
│                                 │
│  ┌─────────────────────────┐    │
│  │      Start Puzzle       │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

---

## Progression Level Select

```
┌─────────────────────────────────┐
│ ←  Progression          🪙 1,234│
├─────────────────────────────────┤
│                                 │
│  Level 1: First Steps           │
│  ┌─────┐ ┌─────┐ ┌─────┐       │
│  │ 1a  │ │ 1b  │ │ 1c  │       │
│  │ ⭐⭐⭐│ │ ⭐⭐ │ │ ⭐  │       │
│  └─────┘ └─────┘ └─────┘       │
│                                 │
│  Level 2: Building Confidence   │
│  ┌─────┐ ┌─────┐ ┌─────┐       │
│  │ 2a  │ │ 2b  │ │ 🔒  │       │
│  │ ⭐⭐ │ │     │ │     │       │
│  └─────┘ └─────┘ └─────┘       │
│                                 │
│  Level 3: Introducing −         │
│  ┌─────┐ ┌─────┐ ┌─────┐       │
│  │ 🔒  │ │ 🔒  │ │ 🔒  │       │
│  └─────┘ └─────┘ └─────┘       │
│                                 │
│  ...                            │
└─────────────────────────────────┘
```

Level cards show:
- Level name and number
- Stars earned (if completed)
- Lock icon (if not yet unlocked)
- Current level highlighted

---

## Puzzle Maker Screen

```
┌─────────────────────────────────┐
│ ←  Puzzle Maker                 │
├─────────────────────────────────┤
│                                 │
│  Generate printable puzzles     │
│                                 │
│  Difficulty                     │
│  ┌─────────────────────────┐    │
│  │ [▼] Level 5: Times Tables │  │
│  └─────────────────────────┘    │
│                                 │
│  Number of puzzles              │
│  [ 1 ] [ 2 ] [ 5 ] [10]        │
│                                 │
│  ┌─────────────────────────┐    │
│  │   Generate & Download   │    │
│  └─────────────────────────┘    │
│                                 │
│  Preview:                       │
│  ┌─────────────────────────┐    │
│  │   [Mini puzzle preview] │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

---

## Print Output (LaTeX PDF)

### Single Puzzle Print

One puzzle per page:
- A4 paper, portrait orientation
- Title: "Circuit Challenge" + difficulty name
- Clean hexagonal grid
- All calculations clearly visible
- Black and white friendly
- No solution shown

### Batch Print (Puzzle Maker)

Multiple puzzles, one per page:
- Same format as single puzzle
- Page numbers: "Puzzle 1 of 10"
- Consistent difficulty across batch

### LaTeX Grid Rendering

The grid is rendered using TikZ:
- Clean hexagonal shapes
- Precise connector lines
- Numbers in circles at midpoints
- Professional mathematical typography

---

## Responsive Behaviour

### Mobile Optimisations

- Grid fits within viewport (scales down if needed)
- Horizontal scroll if grid is very wide (rare)
- Touch targets minimum 44px
- Buttons at bottom for thumb reach

### Tablet Optimisations

- Grid centred with comfortable margins
- Larger cells for easier tapping
- Side-by-side buttons possible

### Desktop Optimisations

- Grid centred, doesn't stretch too wide
- Hover states on cells (subtle glow)
- Keyboard support (arrow keys + enter)

---

## Accessibility

### Visual

- Minimum contrast 4.5:1 for all text
- Cell states not colour-only (also use borders/icons)
- Animations can be disabled (reduced motion preference)

### Motor

- Large touch targets (minimum 44px)
- No time limits that can't be extended
- No rapid tapping required

### Cognitive

- Clear visual feedback for all actions
- Consistent interaction patterns
- Option to show calculation hints (future consideration)

---

*End of Document 8*
