# Circuit Challenge - Game Design Document

**Version:** 1.2  
**Last Updated:** January 2025  
**Author:** Dom Barker

---

## Overview

Circuit Challenge is the first puzzle module for Max's Puzzles. Players navigate from START to FINISH on a hexagonal grid by solving arithmetic problems. Each cell contains a calculation; the answer determines which connector to follow to the next cell.

---

## Core Gameplay

### Objective

Navigate from the START cell to the FINISH cell by correctly solving arithmetic problems.

### How It Works

1. Player starts on the START cell (top-left)
2. Each cell displays a calculation (e.g., "5 + 8")
3. Player solves the calculation mentally (answer: 13)
4. Connectors between cells display numbers
5. Player taps the adjacent cell connected by the matching number (13)
6. If correct, player moves to that cell
7. If wrong, player loses a life (standard mode only)
8. Reach FINISH to win

### Example

```
[START: 5+8] ──13── [12-5] ──7── [3×4]
     │                │            │
     9               11           12
     │                │            │
  [7+2]  ────8──── [15-6] ──9── [FINISH]
```

Path: START (5+8=13) → (12-5=7) → (3×4=12) → FINISH

### FINISH Cell Entry

The FINISH cell has no calculation (displays "FINISH" text). The cell *before* FINISH has a calculation whose answer equals the connector value leading to FINISH. Player solves that calculation and taps FINISH via the matching connector.

---

## Game Modes

### Quick Play

- Player selects difficulty settings
- Puzzle generated on-demand
- No progression, just practice
- Hidden Mode toggle available
- Coins earned based on performance
- Two buttons: Reset (same puzzle) and New Puzzle

### Progression Mode (V2)

- 30 pre-defined levels (10 levels × 3 sublevels: A, B, C)
- Increasing difficulty curve
- Star ratings (1-3 stars)
- 2 stars required to unlock next level
- Some levels require Hidden Mode (Level 7 onwards)
- Tutorial hints on Level 1-A

### Puzzle Maker

- Generate printable puzzles
- Select difficulty
- Generate 1-10 puzzles
- Output as LaTeX PDF

---

## Lives System (Standard Mode Only)

- Player starts with **5 lives** per puzzle
- Lose 1 life per wrong move
- Lose all 5 lives = game over
- Lives reset when starting a new puzzle
- Lives display: 5 heart icons in header (active hearts pulse)

### Wrong Move Behaviour

1. Screen shakes briefly
2. Heart icon fades from pink to grey
3. Coin penalty applied (-30, floats down in red)
4. Player remains on current cell
5. Can try again

---

## Hidden Mode

In Hidden Mode, mistakes are not immediately revealed. **There is no lives system — player always reaches FINISH.**

**How it works:**
1. Player makes a move
2. Move is accepted regardless of correctness
3. No life lost, no visual feedback, **no coin animations**
4. Player continues to FINISH
5. At end, results revealed:
   - Total moves
   - Correct moves
   - Wrong moves (highlighted on grid)
   - Coins earned (with penalties applied) — V3

**Coin display in Hidden Mode:**
- Header coin counter stays static during gameplay (shows balance from before puzzle)
- No +10/-30 floating animations during play
- All coin changes revealed on summary screen

**Use cases:**
- Toggle in Quick Play
- Required for specific Progression levels (Level 7 onwards)
- Tests genuine understanding (no trial-and-error)

---

## Grid Structure

### Hexagonal Cells (Visual) with Rectangular Logic

Cells are hexagons arranged in a rectangular grid pattern. **Visually** they appear as hexagons, but **logically** they connect like a square grid (up to 8 neighbours).

```
    Col 0   Col 1   Col 2   Col 3   Col 4
    
Row 0  [START] ─────── [   ] ─────── [   ] ─────── [   ] ─────── [   ]
          │  ╲     ╱   │  ╲     ╱   │  ╲     ╱   │  ╲     ╱   │
          │    ╲ ╱     │    ╲ ╱     │    ╲ ╱     │    ╲ ╱     │
          │    ╱ ╲     │    ╱ ╲     │    ╱ ╲     │    ╱ ╲     │
Row 1  [     ] ─────── [   ] ─────── [   ] ─────── [   ] ─────── [   ]
          │  ╲     ╱   │  ╲     ╱   │  ╲     ╱   │  ╲     ╱   │
          │    ╲ ╱     │    ╲ ╱     │    ╲ ╱     │    ╲ ╱     │
          │    ╱ ╲     │    ╱ ╲     │    ╱ ╲     │    ╱ ╲     │
Row 2  [     ] ─────── [   ] ─────── [   ] ─────── [   ] ─────── [   ]
```

### Grid Adjacency

A cell at `(row, col)` can connect to:
- `(row, col-1)` — horizontal left
- `(row, col+1)` — horizontal right
- `(row-1, col)` — vertical up
- `(row+1, col)` — vertical down
- `(row-1, col-1)` — diagonal upper-left
- `(row-1, col+1)` — diagonal upper-right
- `(row+1, col-1)` — diagonal lower-left
- `(row+1, col+1)` — diagonal lower-right

### Default Size

- 4 rows × 5 columns = 20 cells
- Grid size varies with difficulty (see Difficulty document)

### Cell Types

| Type | Position | Visual | Content |
|------|----------|--------|---------|
| START | (0, 0) | Green hexagon | Calculation |
| FINISH | (rows-1, cols-1) | Gold hexagon | "FINISH" text |
| Normal | All others | Grey hexagon | Calculation |

---

## Connectors

Connectors link adjacent cells and display numbers.

### Connector Types

1. **Horizontal** - Between cells in the same row
2. **Vertical** - Between cells in adjacent rows (same column)
3. **Diagonal** - Between diagonally adjacent cells

### Diagonal Rule

Each 2×2 group of cells has **exactly one** diagonal connector:
- Either top-left ↔ bottom-right (DR)
- Or top-right ↔ bottom-left (DL)
- Never both (they would cross)

### Connector Values

- Each connector displays a number
- All connectors touching a cell show **different** numbers
- This ensures unambiguous navigation

---

## Arithmetic Operations

### Supported Operations

| Operation | Symbol | Example |
|-----------|--------|---------|
| Addition | + | 5 + 8 = 13 |
| Subtraction | − | 12 - 5 = 7 |
| Multiplication | × | 3 × 4 = 12 |
| Division | ÷ | 15 ÷ 3 = 5 |

### Constraints

- All numbers are positive integers
- Subtraction never results in negative numbers
- Division always results in whole numbers (no remainders)
- Operation availability depends on difficulty level

---

## Scoring (V3)

### Coins

- **+10 coins** per correct answer (floats up in green)
- **-30 coins** per mistake (floats down in red)
- **Minimum 0 coins per puzzle** (can't go negative, can't lose existing savings)
- Header shows clamped running total (stops at 0, but -30 animation still shows)
- **Hidden Mode exception:** No coin animations during play; all revealed at end

### Stars (Progression Mode)

| Stars | Requirement |
|-------|-------------|
| 1 ⭐ | Completed puzzle |
| 2 ⭐⭐ | Completed with no mistakes |
| 3 ⭐⭐⭐ | No mistakes + under time threshold |

### Time Threshold

Calculated from path length:
- Base: **X seconds per step** (varies by level, see Difficulty document)
- Example: 10-step path with 6 seconds/step = 60 second threshold

### Timer

- Displayed in header (MM:SS format)
- **Starts on first move:** Timer begins when player taps any adjacent cell (regardless of whether the move is correct or wrong)
- Green when under 3-star threshold
- Yellow when approaching threshold
- No colour change in Hidden Mode (no time pressure shown)

---

## Module Menu

When player enters Circuit Challenge:

```
┌─────────────────────────────────┐
│ ←  Circuit Challenge   🪙 1,234 │
├─────────────────────────────────┤
│                                 │
│   ┌─────────────────────────┐   │
│   │      ⚡ Quick Play      │   │
│   └─────────────────────────┘   │
│                                 │
│   ┌─────────────────────────┐   │
│   │      📈 Progression     │   │  ← V2
│   │      Level 5 - 38⭐     │   │
│   └─────────────────────────┘   │
│                                 │
│   ┌─────────────────────────┐   │
│   │      🖨️ Puzzle Maker    │   │
│   └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

---

## Quick Play Flow

1. **Difficulty Selection**
   - Choose preset level OR
   - Custom settings (operations, ranges, grid size)
   - Hidden Mode toggle

2. **Puzzle Generated**
   - Algorithm generates valid puzzle
   - Player sees grid with START highlighted
   - Timer not yet started

3. **Gameplay**
   - Timer starts on first move
   - Solve calculations
   - Tap cells to move
   - Lives displayed in header (standard mode)

4. **Completion**
   - Win: Celebration animation, coins awarded
   - Lose: "Out of Lives" prompt (standard mode only)

5. **Summary**
   - Coins earned this puzzle
   - Accuracy percentage
   - Time taken
   - "Reset" / "New Puzzle" / "Change Difficulty" / "Exit"

---

## Progression Flow (V2)

1. **Level Select**
   - Grid of levels, locked/unlocked state
   - Stars displayed per level
   - Current level highlighted

2. **Level Start**
   - Brief level info (difficulty, special rules)
   - "Start" button

3. **Gameplay**
   - Same as Quick Play
   - May include Hidden Mode requirement
   - Level 1-A includes tutorial hints (valid moves highlighted)

4. **Completion**
   - Stars awarded
   - Coins awarded
   - Unlock next level if 2+ stars
   - "Next Level" / "Retry" / "Back to Map"

---

## Action Buttons

### Button Bar (During Gameplay)

```
┌─────────────────────────────────────────────────────┐
│  [🔄 Reset]  [✨ New Puzzle]  [⚙️ Difficulty]  [🖨️ Print] │
└─────────────────────────────────────────────────────┘
```

| Button | Action |
|--------|--------|
| Reset | Restart the **same puzzle** (same grid, same path). Lives, timer, coins reset. |
| New Puzzle | Generate a **fresh puzzle** at the same difficulty settings. |
| Difficulty | Open difficulty settings (return to difficulty selector). |
| Print | Generate LaTeX PDF of current puzzle → Download. |

---

## Print Features

### Print Current Puzzle

From gameplay screen:
- Tap print icon
- Generate printable HTML/CSS version of current puzzle
- Clean, crisp output suitable for paper (pure black & white)
- No answers shown
- Uses browser's print function (web) or WKWebView rendering (iOS)

### Puzzle Maker

Dedicated screen:
1. Select difficulty settings
2. Choose number of puzzles (1-10)
3. Generate
4. Download/print with 2 puzzles per A4 page
5. Pure black & white, no headers

### PDF Format

- A4 paper size
- 2 puzzles per page
- Clear hexagonal grid
- Readable calculation text
- Pure black & white (no colour required)
- Client-side generation (HTML/CSS → print)

---

## Progress Tracking

Data saved per user:

```typescript
interface CircuitChallengeProgress {
  quickPlay: {
    gamesPlayed: number;
    totalCorrect: number;
    totalMistakes: number;
    bestStreak: number;         // Consecutive correct
  };
  progression: {
    currentLevel: string;       // e.g., "3-B"
    levels: {
      [levelId: string]: {
        completed: boolean;
        stars: number;          // 0-3
        bestTime: number | null;
        attempts: number;
      };
    };
  };
  settings: {
    lastDifficulty: DifficultySettings;
    hiddenModeDefault: boolean;
  };
}
```

---

## Win/Lose States

### Win

**Trigger:** Player reaches FINISH cell

**Standard Mode:**
1. FINISH cell pulses gold
2. Connector animates flow to FINISH
3. Celebration animation (confetti/sparkles)
4. "Puzzle Complete!" message
5. Summary screen

**Hidden Mode:**
1. FINISH reached
2. "Revealing results..." message
3. Correct moves highlighted green
4. Wrong moves highlighted red
5. Summary with detailed breakdown

### Lose (Standard Mode Only)

**Trigger:** Lives reach 0

1. Screen fades slightly
2. "Out of Lives" message
3. Option to see solution path
4. "Try Again" / "Exit" buttons

### View Solution

When player taps "See Solution" after losing:
1. **Instant reveal** - Entire correct path highlights at once
2. All cells on solution path glow green (visited state)
3. All connectors on solution path animate to active/traversed state
4. FINISH cell pulses gold
5. Player can study the path at their own pace

---

## Generation Failure

If puzzle generation fails:

1. Algorithm retries with same settings (up to 20 attempts)
2. If still failing after 20 attempts, show error: "Couldn't generate puzzle. Try different settings."
3. Button to return to difficulty selection

User can manually adjust settings if generation repeatedly fails (rare edge case).

---

## Tutorial Hints (Level 1-A Only)

On Level 1-A, valid moves are highlighted to teach navigation:

- Adjacent, unvisited cells pulse with a subtle outline
- This shows "I can move to these cells"
- The correct answer is NOT revealed — player still solves the maths
- Hints disabled on all other levels

---

## Accessibility

- Large touch targets on cells (minimum 44px)
- High contrast numbers
- No colour-only information (shapes + colours)
- Screen reader support for calculations
- Option to increase text size
- Reduced motion option respects system preference

---

*End of Document 5*
