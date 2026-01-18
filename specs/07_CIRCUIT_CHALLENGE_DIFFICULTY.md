# Circuit Challenge - Difficulty & Progression

**Version:** 1.2  
**Last Updated:** January 2025  
**Author:** Dom Barker

---

## Overview

This document specifies the difficulty system for Circuit Challenge, including all difficulty levers, preset levels, and the 30-level progression curve.

---

## Difficulty Levers

Difficulty is controlled by multiple independent parameters:

| Lever | Description | Range |
|-------|-------------|-------|
| Operations | Which operations are enabled | +, −, ×, ÷ |
| Add/Sub Range | Maximum operand for +/− | 5 - 100 |
| Mult/Div Range | Maximum factor/divisor | 2 - 14 |
| Grid Rows | Number of rows | 3 - 8 |
| Grid Columns | Number of columns | 4 - 10 |
| Connector Range | Min/max connector values | Based on answer range |
| Operation Weights | Probability of each operation | 0% - 100% |
| Hidden Mode | Whether mistakes shown | On/Off |
| Time Pressure | 3-star time threshold | Seconds per step |

---

## Difficulty Settings Schema

```typescript
interface DifficultySettings {
  // Operations
  additionEnabled: boolean;
  subtractionEnabled: boolean;
  multiplicationEnabled: boolean;
  divisionEnabled: boolean;
  
  // Ranges
  addSubRange: number;          // Max operand for +/−
  multDivRange: number;         // Max factor for ×/÷
  connectorMin: number;         // Minimum connector value
  connectorMax: number;         // Maximum connector value
  
  // Grid
  gridRows: number;
  gridCols: number;
  
  // Path
  minPathLength: number;
  maxPathLength: number;
  
  // Weights (must sum to 100 for enabled operations)
  weights: {
    addition: number;
    subtraction: number;
    multiplication: number;
    division: number;
  };
  
  // Gameplay
  hiddenMode: boolean;
  secondsPerStep: number;       // For 3-star threshold
}
```

---

## Preset Difficulty Levels

For Quick Play, players can choose from preset levels or customise.

### Level 1: Tiny Tot

**Target:** Reception/Year 1 (ages 4-5)

```
Operations: + only
Add/Sub Range: 10
Grid: 3×4 (12 cells)
Connector Range: 5-10
Weights: addition 100%
Seconds/step: 10
```

Example expressions: 2+3, 4+1, 5+2

---

### Level 2: Beginner

**Target:** Year 1 (ages 5-6)

```
Operations: + only
Add/Sub Range: 15
Grid: 4×4 (16 cells)
Connector Range: 5-15
Weights: addition 100%
Seconds/step: 9
```

Example expressions: 6+4, 8+7, 9+3

---

### Level 3: Easy

**Target:** Year 1-2 (ages 5-7)

```
Operations: +, −
Add/Sub Range: 15
Grid: 4×5 (20 cells)
Connector Range: 5-15
Weights: addition 60%, subtraction 40%
Seconds/step: 8
```

Example expressions: 7+5, 12-4, 8+6

---

### Level 4: Getting There

**Target:** Year 2 (ages 6-7)

```
Operations: +, −
Add/Sub Range: 20
Grid: 4×5 (20 cells)
Connector Range: 5-20
Weights: addition 55%, subtraction 45%
Seconds/step: 7
```

Example expressions: 13+7, 18-5, 9+8

---

### Level 5: Times Tables

**Target:** Year 2-3 (ages 6-8)

```
Operations: +, −, ×
Add/Sub Range: 20
Mult/Div Range: 5
Grid: 4×5 (20 cells)
Connector Range: 5-25
Weights: addition 40%, subtraction 35%, multiplication 25%
Seconds/step: 7
```

Example expressions: 12+8, 15-6, 3×4, 5×2

---

### Level 6: Confident

**Target:** Year 3 (ages 7-8)

```
Operations: +, −, ×
Add/Sub Range: 25
Mult/Div Range: 6
Grid: 5×5 (25 cells)
Connector Range: 5-36
Weights: addition 35%, subtraction 30%, multiplication 35%
Seconds/step: 6
```

Example expressions: 17+8, 23-9, 4×6, 3×7

---

### Level 7: Adventurous

**Target:** Year 3-4 (ages 7-9)

```
Operations: +, −, ×
Add/Sub Range: 30
Mult/Div Range: 8
Grid: 5×6 (30 cells)
Connector Range: 5-64
Weights: addition 30%, subtraction 30%, multiplication 40%
Seconds/step: 6
```

Example expressions: 24+12, 35-18, 7×6, 8×4

---

### Level 8: Division Intro

**Target:** Year 4 (ages 8-9)

```
Operations: +, −, ×, ÷
Add/Sub Range: 30
Mult/Div Range: 6
Grid: 5×6 (30 cells)
Connector Range: 5-36
Weights: addition 30%, subtraction 25%, multiplication 30%, division 15%
Seconds/step: 6
```

Example expressions: 28+15, 42-19, 6×5, 12÷3

---

### Level 9: Challenge

**Target:** Year 4-5 (ages 8-10)

```
Operations: +, −, ×, ÷
Add/Sub Range: 50
Mult/Div Range: 10
Grid: 6×7 (42 cells)
Connector Range: 5-100
Weights: addition 25%, subtraction 25%, multiplication 30%, division 20%
Seconds/step: 5
```

Example expressions: 45+32, 78-29, 8×7, 36÷4

---

### Level 10: Expert

**Target:** Year 5-6 (ages 9-11)

```
Operations: +, −, ×, ÷
Add/Sub Range: 100
Mult/Div Range: 12
Grid: 6×8 (48 cells)
Connector Range: 5-144
Weights: addition 25%, subtraction 25%, multiplication 30%, division 20%
Seconds/step: 5
```

Example expressions: 67+34, 95-48, 11×8, 72÷8

---

## Difficulty Summary Table

| Level | Name | Ops | +/− Range | ×/÷ Range | Grid | Cells |
|-------|------|-----|-----------|-----------|------|-------|
| 1 | Tiny Tot | + | 10 | - | 3×4 | 12 |
| 2 | Beginner | + | 15 | - | 4×4 | 16 |
| 3 | Easy | +− | 15 | - | 4×5 | 20 |
| 4 | Getting There | +− | 20 | - | 4×5 | 20 |
| 5 | Times Tables | +−× | 20 | 5 | 4×5 | 20 |
| 6 | Confident | +−× | 25 | 6 | 5×5 | 25 |
| 7 | Adventurous | +−× | 30 | 8 | 5×6 | 30 |
| 8 | Division Intro | +−×÷ | 30 | 6 | 5×6 | 30 |
| 9 | Challenge | +−×÷ | 50 | 10 | 6×7 | 42 |
| 10 | Expert | +−×÷ | 100 | 12 | 6×8 | 48 |

---

## Custom Difficulty

In Quick Play, players can also set custom difficulty:

### Custom Settings UI

```
┌─────────────────────────────────┐
│ Custom Difficulty               │
├─────────────────────────────────┤
│                                 │
│ Operations                      │
│ [✓] +  [✓] −  [✓] ×  [ ] ÷    │
│                                 │
│ +/− Number Range                │
│ [====●===============] 20      │
│ 5                          100  │
│                                 │
│ ×/÷ Number Range                │
│ [=====●==============] 6       │
│ 2                           14  │
│                                 │
│ Grid Size                       │
│ Rows: [3] [4] [5] [6] [7] [8]  │
│ Cols: [4] [5] [6] [7] [8] [9]  │
│                                 │
│ Hidden Mode                     │
│ [ ] Enable Hidden Mode          │
│                                 │
│ [      Start Puzzle      ]      │
└─────────────────────────────────┘
```

### Custom Settings Rules

1. At least one operation must be enabled
2. Division requires multiplication to also be enabled
3. Grid must be at least 3×4
4. Connector range auto-calculated from other settings

---

## Progression Mode: 30 Levels

Progression Mode consists of 10 main levels, each with 3 sublevels (A, B, C).

### Level Naming Convention

All levels use the format: `{level}-{sublevel}` (e.g., `1-A`, `5-C`, `10-B`)

### Level Structure

```
Level 1: Introduction
├── 1-A: First steps (tutorial hints enabled)
├── 1-B: Building confidence
└── 1-C: Ready for more

Level 2: Addition Mastery
├── 2-A: Larger numbers
├── 2-B: Speed challenge
└── 2-C: First assessment

Level 3: Subtraction
├── 3-A: Taking away
├── 3-B: Mix it up
└── 3-C: Subtraction focus

Level 4: Add/Sub Fluency
├── 4-A: Getting faster
├── 4-B: No mistakes challenge
└── 4-C: Stepping up

Level 5: Times Tables
├── 5-A: Twos and fives
├── 5-B: Threes and fours
└── 5-C: Times tables test

Level 6: Multiplication
├── 6-A: Sixes
├── 6-B: Sevens and eights
└── 6-C: Full tables

Level 7: Hidden Mode (Introduction)
├── 7-A: Introduction to hidden
├── 7-B: Hidden multiplication
└── 7-C: Trust yourself

Level 8: Division
├── 8-A: Sharing equally
├── 8-B: Division practice
└── 8-C: All four operations

Level 9: All Operations
├── 9-A: Bigger grid
├── 9-B: Hidden all-ops
└── 9-C: The challenge

Level 10: Mastery
├── 10-A: Expert numbers
├── 10-B: Expert hidden
└── 10-C: Final challenge
```

### Progression Design Principles

1. **Gradual introduction** - New concepts introduced one at a time
2. **Consolidation** - Practice before adding complexity
3. **Hidden Mode at Level 7** - Introduced mid-game as a new challenge
4. **Grid growth** - Larger grids as skills improve
5. **No sudden jumps** - Smooth difficulty curve

---

## Detailed Level Specifications

### Level 1: Introduction

**1-A: First Steps**
```
Operations: +
Add/Sub Range: 8
Grid: 3×4
Hidden: No
Special: Tutorial hints enabled (valid moves highlighted)
```

**1-B: Building Confidence**
```
Operations: +
Add/Sub Range: 10
Grid: 3×4
Hidden: No
```

**1-C: Ready for More**
```
Operations: +
Add/Sub Range: 12
Grid: 4×4
Hidden: No
```

---

### Level 2: Addition Mastery

**2-A: Bigger Numbers**
```
Operations: +
Add/Sub Range: 15
Grid: 4×4
Hidden: No
```

**2-B: Speed Challenge**
```
Operations: +
Add/Sub Range: 15
Grid: 4×4
Hidden: No
Time: Tight 3-star threshold (5 sec/step)
```

**2-C: Assessment**
```
Operations: +
Add/Sub Range: 18
Grid: 4×5
Hidden: No
```

---

### Level 3: Subtraction

**3-A: Taking Away**
```
Operations: +, −
Weights: 70% +, 30% −
Add/Sub Range: 15
Grid: 4×4
Hidden: No
```

**3-B: Mix It Up**
```
Operations: +, −
Weights: 50% +, 50% −
Add/Sub Range: 15
Grid: 4×5
Hidden: No
```

**3-C: Subtraction Focus**
```
Operations: +, −
Weights: 30% +, 70% −
Add/Sub Range: 18
Grid: 4×5
Hidden: No
```

---

### Level 4: Add/Sub Fluency

**4-A: Getting Faster**
```
Operations: +, −
Add/Sub Range: 20
Grid: 4×5
Hidden: No
Time: Medium threshold (6 sec/step)
```

**4-B: No Mistakes**
```
Operations: +, −
Add/Sub Range: 20
Grid: 4×5
Hidden: No
Note: Designed to encourage clean play (standard 2-star unlock rule applies)
```

**4-C: Stepping Up**
```
Operations: +, −
Add/Sub Range: 25
Grid: 5×5
Hidden: No
```

---

### Level 5: Times Tables

**5-A: Twos and Fives**
```
Operations: +, −, ×
Weights: 40% +, 30% −, 30% ×
Mult/Div Range: 5 (but prefer 2, 5)
Add/Sub Range: 20
Grid: 4×5
Hidden: No
```

**5-B: Threes and Fours**
```
Operations: +, −, ×
Weights: 35% +, 25% −, 40% ×
Mult/Div Range: 5
Add/Sub Range: 20
Grid: 5×5
Hidden: No
```

**5-C: Times Tables Test**
```
Operations: +, −, ×
Weights: 30% +, 20% −, 50% ×
Mult/Div Range: 5
Add/Sub Range: 20
Grid: 5×5
Hidden: No
```

---

### Level 6: Multiplication

**6-A: Sixes**
```
Operations: +, −, ×
Mult/Div Range: 6
Add/Sub Range: 25
Grid: 5×5
Hidden: No
```

**6-B: Sevens and Eights**
```
Operations: +, −, ×
Mult/Div Range: 8
Add/Sub Range: 25
Grid: 5×5
Hidden: No
```

**6-C: Full Tables**
```
Operations: +, −, ×
Mult/Div Range: 8
Add/Sub Range: 30
Grid: 5×6
Hidden: No
```

---

### Level 7: Hidden Mode (Introduction)

**7-A: Introduction to Hidden**
```
Operations: +, −
Add/Sub Range: 15
Grid: 4×4
Hidden: YES
Special: First hidden mode level
```

**7-B: Hidden Multiplication**
```
Operations: +, −, ×
Mult/Div Range: 5
Add/Sub Range: 20
Grid: 4×5
Hidden: YES
```

**7-C: Trust Yourself**
```
Operations: +, −, ×
Mult/Div Range: 6
Add/Sub Range: 25
Grid: 5×5
Hidden: YES
```

---

### Level 8: Division

**8-A: Sharing Equally**
```
Operations: +, −, ×, ÷
Weights: 30% +, 25% −, 25% ×, 20% ÷
Mult/Div Range: 5
Add/Sub Range: 25
Grid: 5×5
Hidden: No
```

**8-B: Division Practice**
```
Operations: +, −, ×, ÷
Weights: 25% +, 20% −, 25% ×, 30% ÷
Mult/Div Range: 6
Add/Sub Range: 30
Grid: 5×5
Hidden: No
```

**8-C: All Four Operations**
```
Operations: +, −, ×, ÷
Weights: 25% each
Mult/Div Range: 6
Add/Sub Range: 30
Grid: 5×6
Hidden: No
```

---

### Level 9: All Operations

**9-A: Bigger Grid**
```
Operations: +, −, ×, ÷
Mult/Div Range: 8
Add/Sub Range: 40
Grid: 6×6
Hidden: No
```

**9-B: Hidden All-Ops**
```
Operations: +, −, ×, ÷
Mult/Div Range: 8
Add/Sub Range: 40
Grid: 5×6
Hidden: YES
```

**9-C: The Challenge**
```
Operations: +, −, ×, ÷
Mult/Div Range: 10
Add/Sub Range: 50
Grid: 6×7
Hidden: No
Time: Tight threshold (5 sec/step)
```

---

### Level 10: Mastery

**10-A: Expert Numbers**
```
Operations: +, −, ×, ÷
Mult/Div Range: 10
Add/Sub Range: 75
Grid: 6×7
Hidden: No
```

**10-B: Expert Hidden**
```
Operations: +, −, ×, ÷
Mult/Div Range: 12
Add/Sub Range: 100
Grid: 6×7
Hidden: YES
```

**10-C: Final Challenge**
```
Operations: +, −, ×, ÷
Mult/Div Range: 12
Add/Sub Range: 100
Grid: 6×8
Hidden: YES
Time: Tight threshold (4 sec/step)
```

---

## Progression Summary Table

| Level | Sublevel | Grid | Operations | +/− | ×/÷ | Hidden |
|-------|----------|------|------------|-----|-----|--------|
| 1 | A | 3×4 | + | 8 | - | ○ |
| 1 | B | 3×4 | + | 10 | - | ○ |
| 1 | C | 4×4 | + | 12 | - | ○ |
| 2 | A | 4×4 | + | 15 | - | ○ |
| 2 | B | 4×4 | + | 15 | - | ○ |
| 2 | C | 4×5 | + | 18 | - | ○ |
| 3 | A | 4×4 | +− | 15 | - | ○ |
| 3 | B | 4×5 | +− | 15 | - | ○ |
| 3 | C | 4×5 | +− | 18 | - | ○ |
| 4 | A | 4×5 | +− | 20 | - | ○ |
| 4 | B | 4×5 | +− | 20 | - | ○ |
| 4 | C | 5×5 | +− | 25 | - | ○ |
| 5 | A | 4×5 | +−× | 20 | 5 | ○ |
| 5 | B | 5×5 | +−× | 20 | 5 | ○ |
| 5 | C | 5×5 | +−× | 20 | 5 | ○ |
| 6 | A | 5×5 | +−× | 25 | 6 | ○ |
| 6 | B | 5×5 | +−× | 25 | 8 | ○ |
| 6 | C | 5×6 | +−× | 30 | 8 | ○ |
| 7 | A | 4×4 | +− | 15 | - | ● |
| 7 | B | 4×5 | +−× | 20 | 5 | ● |
| 7 | C | 5×5 | +−× | 25 | 6 | ● |
| 8 | A | 5×5 | +−×÷ | 25 | 5 | ○ |
| 8 | B | 5×5 | +−×÷ | 30 | 6 | ○ |
| 8 | C | 5×6 | +−×÷ | 30 | 6 | ○ |
| 9 | A | 6×6 | +−×÷ | 40 | 8 | ○ |
| 9 | B | 5×6 | +−×÷ | 40 | 8 | ● |
| 9 | C | 6×7 | +−×÷ | 50 | 10 | ○ |
| 10 | A | 6×7 | +−×÷ | 75 | 10 | ○ |
| 10 | B | 6×7 | +−×÷ | 100 | 12 | ● |
| 10 | C | 6×8 | +−×÷ | 100 | 12 | ● |

Legend: ○ = Standard Mode, ● = Hidden Mode

---

## Time Thresholds for 3 Stars

Time threshold = path length × seconds per step

| Level Range | Seconds per Step |
|-------------|------------------|
| 1-2 | 10 |
| 3-4 | 8 |
| 5-6 | 7 |
| 7-8 | 6 |
| 9-10 | 5 |

**Example:** Level 7-B has a 4×5 grid. Typical path length ~12 steps. 
Time threshold = 12 × 6 = 72 seconds for 3 stars.

**Note:** These values should be playtested with Max and adjusted.

---

## Star Requirements

| Stars | Requirement |
|-------|-------------|
| 1 ⭐ | Complete the puzzle |
| 2 ⭐⭐ | Complete with no mistakes |
| 3 ⭐⭐⭐ | No mistakes AND under time threshold |

**2 stars required to unlock the next sublevel.**

---

## Unlocking Logic

```
Level 1-A: Always unlocked
Level 1-B: Requires 1-A with 2+ stars
Level 1-C: Requires 1-B with 2+ stars
Level 2-A: Requires 1-C with 2+ stars
...and so on
```

A player cannot skip ahead. They must earn at least 2 stars on each level to progress.

---

## Progression Data Structure

```typescript
interface ProgressionLevel {
  id: string;                    // "1-A", "5-C", etc.
  displayName: string;           // "First Steps", "Times Tables Test"
  description: string;           // Brief description
  difficulty: DifficultySettings;
  unlockRequirement: {
    levelId: string;             // Previous level
    minStars: number;            // Usually 2
  } | null;                      // null for 1-A (always unlocked)
  specialRules?: {
    tutorialEnabled?: boolean;   // For 1-A
    mustGetTwoStars?: boolean;   // For "no mistakes" levels
  };
}

interface UserLevelProgress {
  levelId: string;
  completed: boolean;
  stars: number;                 // 0-3
  bestTime: number | null;       // Milliseconds
  attempts: number;
  firstCompletedAt: Date | null;
}
```

---

## Future Expansion

The 30-level structure can be expanded:

- **More sublevels:** Add 1-D, 1-E for more practice
- **Challenge levels:** Optional hard variants
- **Daily challenges:** Randomly generated at set difficulty
- **Seasonal events:** Themed puzzles

The difficulty system is designed to accommodate these additions.

---

*End of Document 7*
