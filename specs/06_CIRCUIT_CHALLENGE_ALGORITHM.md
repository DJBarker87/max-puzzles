# Circuit Challenge - Algorithm Specification

**Version:** 1.2  
**Last Updated:** January 2025  
**Author:** Dom Barker

---

## Overview

This document specifies the puzzle generation algorithm for Circuit Challenge. The algorithm must produce puzzles that are:

1. **Solvable** - Exactly one path from START to FINISH
2. **Unambiguous** - Each cell has exactly one valid exit
3. **Fair** - All cells are navigable (no dead ends by design)
4. **Varied** - Different puzzles each time

---

## Core Philosophy: Connectors First

The key insight is to assign connector values **before** cell answers. This guarantees uniqueness by construction rather than requiring complex constraint satisfaction.

**Why this works:**
1. Generate a solution path
2. Assign connector values ensuring uniqueness per cell
3. Set each cell's answer to match its exit connector
4. Generate arithmetic expressions for each answer

---

## Algorithm Overview

```
Input: DifficultySettings
Output: Puzzle (grid, connectors, solution path)

STEP 1: Generate Solution Path
STEP 2: Set Diagonal Directions  
STEP 3: Build Connector Graph
STEP 4: Assign Connector Values
STEP 5: Assign Cell Answers
STEP 6: Generate Arithmetic Expressions
STEP 7: Validate Puzzle
```

---

## Step 1: Generate Solution Path

Create a path from START (0,0) to FINISH (rows-1, cols-1).

### Requirements

- Path visits each cell at most once
- Path length between `minPathLength` and `maxPathLength`
- Path must reach FINISH
- Path should be "interesting" (not just straight lines)

### Algorithm

```
function generatePath(rows, cols, minLength, maxLength):
    for attempt in 1..MAX_ATTEMPTS:
        path = [START]
        current = START
        diagonalCommitments = {}
        
        while current != FINISH:
            if path.length > maxLength:
                break  // Path too long, retry
            
            neighbours = getValidMoves(current, path, diagonalCommitments)
            
            if neighbours is empty:
                break  // Stuck, retry
            
            // Bias toward FINISH as path lengthens
            next = selectNext(neighbours, FINISH, path.length / maxLength)
            
            // Track diagonal commitments
            if isDiagonalMove(current, next):
                commitDiagonal(current, next, diagonalCommitments)
            
            path.append(next)
            current = next
        
        if current == FINISH and path.length >= minLength:
            if isInteresting(path):
                return {path, diagonalCommitments}
    
    throw "Failed to generate path after MAX_ATTEMPTS"
```

### Valid Moves

A move from cell A to cell B is valid if:
1. B is adjacent to A (horizontally, vertically, or diagonally)
2. B has not been visited
3. If diagonal, the required diagonal direction doesn't conflict with existing commitments

```
function getValidMoves(current, visited, diagonalCommitments):
    moves = []
    for each adjacent cell B:
        if B in visited:
            continue
        
        if isDiagonalMove(current, B):
            diagKey = getDiagonalKey(current, B)
            requiredDir = getDiagonalDirection(current, B)
            
            if diagKey in diagonalCommitments:
                if diagonalCommitments[diagKey] != requiredDir:
                    continue  // Conflict
        
        moves.append(B)
    
    return moves
```

### Selecting Next Cell

Bias selection toward FINISH as the path gets longer:

```
function selectNext(neighbours, finish, progressRatio):
    // progressRatio: 0 at start, 1 at maxLength
    
    if random() < progressRatio * 0.7:
        // Sort by distance to FINISH, pick closest
        neighbours.sort(by: distance to finish)
        return neighbours[0]
    else:
        // Random selection
        return random(neighbours)
```

### Interesting Path Check

Reject boring straight-line paths:

```
function isInteresting(path):
    directionChanges = 0
    prevDirection = null
    
    for i in 0..path.length-2:
        direction = (path[i+1].row - path[i].row, 
                     path[i+1].col - path[i].col)
        
        if prevDirection != null and direction != prevDirection:
            directionChanges++
        
        prevDirection = direction
    
    return directionChanges >= 3
```

---

## Step 2: Set Diagonal Directions

Each 2×2 group of cells has exactly one diagonal.

```
function setDiagonalDirections(rows, cols, diagonalCommitments):
    diagonals = 2D array of size (rows-1) × (cols-1)
    
    for row in 0..rows-2:
        for col in 0..cols-2:
            key = (row, col)
            
            if key in diagonalCommitments:
                // Path requires this direction
                diagonals[row][col] = diagonalCommitments[key]
            else:
                // Random choice
                diagonals[row][col] = random(['DR', 'DL'])
    
    return diagonals
```

Diagonal meanings:
- **DR** (Down-Right): connects (row, col) ↔ (row+1, col+1)
- **DL** (Down-Left): connects (row, col+1) ↔ (row+1, col)

---

## Step 3: Build Connector Graph

Create all connectors with references to their adjacent cells.

```
function buildConnectors(rows, cols, diagonals):
    connectors = []
    
    // Horizontal connectors
    for row in 0..rows-1:
        for col in 0..cols-2:
            connectors.append({
                type: 'horizontal',
                cellA: (row, col),
                cellB: (row, col+1),
                value: null
            })
    
    // Vertical connectors
    for row in 0..rows-2:
        for col in 0..cols-1:
            connectors.append({
                type: 'vertical',
                cellA: (row, col),
                cellB: (row+1, col),
                value: null
            })
    
    // Diagonal connectors
    for row in 0..rows-2:
        for col in 0..cols-2:
            if diagonals[row][col] == 'DR':
                cellA = (row, col)
                cellB = (row+1, col+1)
            else:  // 'DL'
                cellA = (row, col+1)
                cellB = (row+1, col)
            
            connectors.append({
                type: 'diagonal',
                direction: diagonals[row][col],
                cellA: cellA,
                cellB: cellB,
                value: null
            })
    
    return connectors
```

---

## Step 4: Assign Connector Values

Assign unique values to connectors such that no cell has duplicate connector values.

### Value Range

The value range depends on difficulty:

| Difficulty | Min Value | Max Value | Available Values |
|------------|-----------|-----------|------------------|
| Level 1-2  | 5         | 15        | 11 values        |
| Level 3-4  | 5         | 20        | 16 values        |
| Level 5-7  | 5         | 30        | 26 values        |
| Level 8-9  | 5         | 50        | 46 values        |
| Level 10   | 5         | 100       | 96 values        |

### Algorithm

```
function assignConnectorValues(connectors, minValue, maxValue):
    // Build cell → connectors map
    cellConnectors = {}
    for each connector:
        addToMap(cellConnectors, connector.cellA, connector)
        addToMap(cellConnectors, connector.cellB, connector)
    
    // Shuffle for variety
    shuffle(connectors)
    
    for each connector:
        cellA = connector.cellA
        cellB = connector.cellB
        
        // Collect values used by either cell's connectors
        usedValues = set()
        for c in cellConnectors[cellA]:
            if c.value != null:
                usedValues.add(c.value)
        for c in cellConnectors[cellB]:
            if c.value != null:
                usedValues.add(c.value)
        
        // Find available values
        available = []
        for v in minValue..maxValue:
            if v not in usedValues:
                available.append(v)
        
        if available is empty:
            return FAILURE  // Retry with new path
        
        connector.value = random(available)
    
    return SUCCESS
```

### Connector Count Analysis

Maximum connectors per cell:

| Cell Position | Orthogonal | Diagonal | Total |
|---------------|------------|----------|-------|
| Corner        | 2          | 1        | 3     |
| Edge          | 3          | 1-2      | 4-5   |
| Interior      | 4          | 2        | 6     |

With a minimum of 11 values (easiest difficulty), value exhaustion should never occur.

---

## Step 5: Assign Cell Answers

Each cell's answer determines its exit connector.

```
function assignCellAnswers(grid, connectors, solutionPath):
    // Build cell → connectors map
    cellConnectors = buildCellConnectorMap(connectors)
    
    // For path cells: answer = connector to next cell
    for i in 0..solutionPath.length-2:
        current = solutionPath[i]
        next = solutionPath[i+1]
        
        connector = findConnectorBetween(current, next, connectors)
        grid[current.row][current.col].answer = connector.value
        grid[current.row][current.col].exitCell = next
    
    // For non-path cells: answer = any random connector
    for each cell not in solutionPath (except FINISH):
        connectors = cellConnectors[cell]
        chosen = random(connectors)
        grid[cell.row][cell.col].answer = chosen.value
        grid[cell.row][cell.col].exitCell = getOtherCell(chosen, cell)
    
    // FINISH has no answer
    grid[FINISH.row][FINISH.col].answer = null
    grid[FINISH.row][FINISH.col].isFinish = true
```

---

## Step 6: Generate Arithmetic Expressions

Create expressions that evaluate to each cell's answer.

### Operation Weights by Difficulty

| Difficulty | Addition | Subtraction | Multiplication | Division |
|------------|----------|-------------|----------------|----------|
| Level 1-2  | 100%     | 0%          | 0%             | 0%       |
| Level 3-4  | 60%      | 40%         | 0%             | 0%       |
| Level 5-6  | 40%      | 35%         | 25%            | 0%       |
| Level 7    | 35%      | 30%         | 35%            | 0%       |
| Level 8-9  | 30%      | 25%         | 30%            | 15%      |
| Level 10   | 25%      | 25%         | 30%            | 20%      |

### Expression Generation

```
function generateExpression(target, difficulty):
    operation = selectOperation(difficulty.weights)
    
    switch operation:
        case ADDITION:
            return generateAddition(target, difficulty)
        case SUBTRACTION:
            return generateSubtraction(target, difficulty)
        case MULTIPLICATION:
            return generateMultiplication(target, difficulty)
        case DIVISION:
            return generateDivision(target, difficulty)
```

### Addition

```
function generateAddition(target, difficulty):
    // target = a + b
    maxOperand = difficulty.addSubRange
    
    // a can be 1 to min(target-1, maxOperand)
    maxA = min(target - 1, maxOperand)
    a = random(1, maxA)
    b = target - a
    
    // Ensure b is also within range
    if b > maxOperand:
        // Try again with different split
        return generateAddition(target, difficulty)
    
    return "{a} + {b}"
```

### Subtraction

```
function generateSubtraction(target, difficulty):
    // a - b = target, so a = target + b
    maxOperand = difficulty.addSubRange
    
    // b can be 1 to (maxOperand - target)
    maxB = maxOperand - target
    if maxB < 1:
        // Can't generate subtraction, fallback to addition
        return generateAddition(target, difficulty)
    
    b = random(1, maxB)
    a = target + b
    
    return "{a} − {b}"
```

### Multiplication

```
function generateMultiplication(target, difficulty):
    // a × b = target
    maxFactor = difficulty.multDivRange
    
    // Find factor pairs where both are within range
    factors = []
    for a in 2..maxFactor:
        if target % a == 0:
            b = target / a
            if b >= 2 and b <= maxFactor:
                factors.append((a, b))
    
    if factors is empty:
        // Target has no valid factor pairs, fallback
        return generateAddition(target, difficulty)
    
    (a, b) = random(factors)
    
    // Randomly swap order
    if random() > 0.5:
        (a, b) = (b, a)
    
    return "{a} × {b}"
```

### Division

```
function generateDivision(target, difficulty):
    // a ÷ b = target, so a = target × b
    maxDivisor = min(difficulty.multDivRange, 14)  // Cap at 14 (times tables)
    
    // Find valid divisors
    divisors = []
    for b in 2..maxDivisor:
        a = target * b
        if a <= difficulty.maxDividend:  // Keep dividend reasonable
            divisors.append((a, b))
    
    if divisors is empty:
        // No valid division, fallback
        return generateMultiplication(target, difficulty)
    
    (a, b) = random(divisors)
    
    return "{a} ÷ {b}"
```

---

## Step 7: Validate Puzzle

After generation, validate all constraints.

```
function validatePuzzle(puzzle):
    errors = []
    
    // 1. Path validity
    if not validatePath(puzzle.path):
        errors.append("Invalid path")
    
    // 2. Connector uniqueness per cell
    for each cell:
        connectors = getConnectorsForCell(cell)
        values = connectors.map(c => c.value)
        if hasDuplicates(values):
            errors.append("Duplicate connectors at {cell}")
    
    // 3. One matching connector per cell
    for each cell except FINISH:
        answer = cell.answer
        matching = getConnectorsForCell(cell).filter(c => c.value == answer)
        if matching.length != 1:
            errors.append("Wrong number of matching connectors at {cell}")
    
    // 4. Path arithmetic correctness
    for each step in path:
        cell = step.cell
        nextCell = step.next
        connector = getConnectorBetween(cell, nextCell)
        if cell.answer != connector.value:
            errors.append("Path arithmetic wrong at {cell}")
    
    // 5. Expression evaluation
    for each cell except FINISH:
        evaluated = evaluate(cell.expression)
        if evaluated != cell.answer:
            errors.append("Expression {cell.expression} != {cell.answer}")
    
    return errors
```

---

## Edge Cases

### Value Exhaustion

If `assignConnectorValues` returns FAILURE:
1. Retry with new random path (up to 10 times)
2. If still failing, increase value range
3. If still failing, reduce grid size

### Path Generation Stuck

If path generation exceeds MAX_ATTEMPTS:
1. Log warning
2. Reduce minimum path length
3. Retry

### No Valid Expression

If no arithmetic expression can be generated for a target:
1. Always fall back to addition (always possible for targets ≥ 2)
2. For target = 1: use 2 - 1

### Prime Number Targets

Prime numbers > maxFactor can't use multiplication/division. Algorithm falls back automatically.

---

## Performance Considerations

- Path generation: O(path_length × neighbours) per attempt
- Connector assignment: O(connectors × cells)
- Expression generation: O(maxFactor) per cell

For a 4×5 grid:
- ~20 cells
- ~50 connectors
- Generation time: < 50ms typically

For larger grids (8×10):
- ~80 cells
- ~200 connectors
- Generation time: < 200ms typically

---

## Data Structures

### Puzzle Output

```typescript
interface Puzzle {
  id: string;
  difficulty: DifficultySettings;
  grid: Cell[][];
  connectors: {
    horizontal: number[][];    // [row][col] = value
    vertical: number[][];      // [row][col] = value
    diagonals: Diagonal[][];   // [row][col] = {dir, value}
  };
  solution: {
    path: Coordinate[];
    description: string;       // Human-readable solution
  };
}

interface Cell {
  row: number;
  col: number;
  expression: string;         // "5 + 8"
  answer: number | null;      // 13, or null for FINISH
  isStart: boolean;
  isFinish: boolean;
}

interface Diagonal {
  direction: 'DR' | 'DL';
  value: number;
}

interface Coordinate {
  row: number;
  col: number;
}
```

---

## Testing Requirements

### Unit Tests

1. Path generation produces valid paths
2. Diagonal commitments are respected
3. Connector values are unique per cell
4. All expressions evaluate correctly
5. Solution path is arithmetically valid

### Property-Based Tests

1. Generate 1000 random puzzles at each difficulty
2. Verify all pass validation
3. Verify solution paths are unique
4. Measure generation time distribution

### Edge Case Tests

1. Minimum grid size (3×3)
2. Maximum grid size (10×10)
3. All operations disabled except one
4. Extreme value ranges

---

*End of Document 6*
