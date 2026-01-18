# Phase 2: Puzzle Generation Engine

**Goal:** Implement the complete puzzle generation algorithm that creates valid, solvable Circuit Challenge puzzles. This is the core algorithmic heart of the game.

**Philosophy:** "Connectors first" - We generate the solution path, assign connector values to guarantee uniqueness, then set cell answers to match their exit connectors, and finally generate arithmetic expressions.

---

## Subphase 2.1: Difficulty Presets

### Prompt for Claude Code:

```
Create the difficulty configuration system for Circuit Challenge.

File: src/modules/circuit-challenge/engine/difficulty.ts

1. Import DifficultySettings from ./types

2. Create the 10 preset difficulty levels as constants:

LEVEL_1_TINY_TOT:
  - name: "Tiny Tot"
  - operations: addition only
  - addSubRange: 10, multDivRange: 0
  - connectorMin: 5, connectorMax: 10
  - gridRows: 3, gridCols: 4
  - weights: { addition: 100, subtraction: 0, multiplication: 0, division: 0 }
  - secondsPerStep: 10

LEVEL_2_BEGINNER:
  - name: "Beginner"
  - operations: addition only
  - addSubRange: 15, multDivRange: 0
  - connectorMin: 5, connectorMax: 15
  - gridRows: 4, gridCols: 4
  - weights: { addition: 100, subtraction: 0, multiplication: 0, division: 0 }
  - secondsPerStep: 9

LEVEL_3_EASY:
  - name: "Easy"
  - operations: addition, subtraction
  - addSubRange: 15, multDivRange: 0
  - connectorMin: 5, connectorMax: 15
  - gridRows: 4, gridCols: 5
  - weights: { addition: 60, subtraction: 40, multiplication: 0, division: 0 }
  - secondsPerStep: 8

LEVEL_4_GETTING_THERE:
  - name: "Getting There"
  - operations: addition, subtraction
  - addSubRange: 20, multDivRange: 0
  - connectorMin: 5, connectorMax: 20
  - gridRows: 4, gridCols: 5
  - weights: { addition: 55, subtraction: 45, multiplication: 0, division: 0 }
  - secondsPerStep: 7

LEVEL_5_TIMES_TABLES:
  - name: "Times Tables"
  - operations: addition, subtraction, multiplication
  - addSubRange: 20, multDivRange: 5
  - connectorMin: 5, connectorMax: 25
  - gridRows: 4, gridCols: 5
  - weights: { addition: 40, subtraction: 35, multiplication: 25, division: 0 }
  - secondsPerStep: 7

LEVEL_6_CONFIDENT:
  - name: "Confident"
  - operations: addition, subtraction, multiplication
  - addSubRange: 25, multDivRange: 6
  - connectorMin: 5, connectorMax: 36
  - gridRows: 5, gridCols: 5
  - weights: { addition: 35, subtraction: 30, multiplication: 35, division: 0 }
  - secondsPerStep: 6

LEVEL_7_ADVENTUROUS:
  - name: "Adventurous"
  - operations: addition, subtraction, multiplication
  - addSubRange: 30, multDivRange: 8
  - connectorMin: 5, connectorMax: 64
  - gridRows: 5, gridCols: 6
  - weights: { addition: 30, subtraction: 30, multiplication: 40, division: 0 }
  - secondsPerStep: 6

LEVEL_8_DIVISION_INTRO:
  - name: "Division Intro"
  - operations: all four
  - addSubRange: 30, multDivRange: 6
  - connectorMin: 5, connectorMax: 36
  - gridRows: 5, gridCols: 6
  - weights: { addition: 30, subtraction: 25, multiplication: 30, division: 15 }
  - secondsPerStep: 6

LEVEL_9_CHALLENGE:
  - name: "Challenge"
  - operations: all four
  - addSubRange: 50, multDivRange: 10
  - connectorMin: 5, connectorMax: 100
  - gridRows: 6, gridCols: 7
  - weights: { addition: 25, subtraction: 25, multiplication: 30, division: 20 }
  - secondsPerStep: 5

LEVEL_10_EXPERT:
  - name: "Expert"
  - operations: all four
  - addSubRange: 100, multDivRange: 12
  - connectorMin: 5, connectorMax: 144
  - gridRows: 6, gridCols: 8
  - weights: { addition: 25, subtraction: 25, multiplication: 30, division: 20 }
  - secondsPerStep: 5

3. Create DIFFICULTY_PRESETS array containing all 10 levels in order

4. Create helper functions:
   - getDifficultyByLevel(level: number): DifficultySettings
   - getDifficultyByName(name: string): DifficultySettings | undefined
   - calculateMinPathLength(rows: number, cols: number): number
     // Returns roughly 60% of cells as minimum path
   - calculateMaxPathLength(rows: number, cols: number): number
     // Returns roughly 85% of cells as maximum path
   - createCustomDifficulty(overrides: Partial<DifficultySettings>): DifficultySettings
     // Merges overrides with LEVEL_5 as base

5. Add validation function:
   - validateDifficultySettings(settings: DifficultySettings): { valid: boolean, errors: string[] }
     // Checks: at least one operation enabled, ranges are positive, grid is at least 3x4, etc.

Export all presets, the array, and helper functions.
```

---

## Subphase 2.2: Path Generation

### Prompt for Claude Code:

```
Create the solution path generation algorithm for Circuit Challenge.

File: src/modules/circuit-challenge/engine/pathfinder.ts

Import types: Coordinate, DiagonalDirection from ../types

1. Create type for diagonal commitments tracking:
   type DiagonalKey = string; // Format: "row,col" of the 2x2 block's top-left
   type DiagonalCommitments = Map<DiagonalKey, DiagonalDirection>;

2. Create type for path generation result:
   interface PathResult {
     success: boolean;
     path: Coordinate[];
     diagonalCommitments: DiagonalCommitments;
     error?: string;
   }

3. Helper function - getDiagonalKey(cellA: Coordinate, cellB: Coordinate): DiagonalKey
   // For a diagonal move, returns the key of the 2x2 block it belongs to
   // The key is the top-left corner of that 2x2 block
   // Example: diagonal from (0,0) to (1,1) has key "0,0"
   // Example: diagonal from (1,2) to (2,1) has key "1,1"

4. Helper function - getDiagonalDirection(from: Coordinate, to: Coordinate): DiagonalDirection
   // Returns 'DR' if moving down-right or up-left (same diagonal)
   // Returns 'DL' if moving down-left or up-right (same diagonal)

5. Helper function - isDiagonalMove(from: Coordinate, to: Coordinate): boolean
   // True if both row and col change

6. Helper function - getAdjacent(pos: Coordinate, rows: number, cols: number): Coordinate[]
   // Returns all 8 possible neighbors (filtered to valid grid positions)
   // Order: up, down, left, right, up-left, up-right, down-left, down-right

7. Helper function - manhattanDistance(a: Coordinate, b: Coordinate): number

8. Helper function - coordToKey(c: Coordinate): string
   // Returns "row,col" string for use in Sets

9. Main function - generatePath(
     rows: number,
     cols: number,
     minLength: number,
     maxLength: number,
     maxAttempts: number = 100
   ): PathResult

   Algorithm:
   a. START is always (0, 0)
   b. FINISH is always (rows-1, cols-1)
   
   For each attempt:
   c. Initialize: path = [START], visited = Set containing START key, diagonalCommitments = new Map()
   d. current = START
   
   e. While current is not FINISH:
      - If path.length > maxLength, break (path too long)
      
      - Get all adjacent cells to current
      - Filter to valid moves:
        * Not in visited set
        * If diagonal move, check diagonal commitment doesn't conflict
      
      - If no valid moves, break (stuck)
      
      - Select next cell using biased selection:
        * progressRatio = path.length / maxLength
        * If random() < progressRatio * 0.7: pick closest to FINISH
        * Else: pick random from valid moves
      
      - If move is diagonal:
        * Get the diagonal key
        * Record the commitment in diagonalCommitments
      
      - Add next to path and visited
      - current = next
   
   f. After loop:
      - If current === FINISH and path.length >= minLength:
        * Check if path is "interesting" (at least 3 direction changes)
        * If yes, return success with path and commitments
      - Else continue to next attempt
   
   g. After all attempts fail, return { success: false, error: "Failed to generate path" }

10. Helper function - isInterestingPath(path: Coordinate[]): boolean
    // Count direction changes, require at least 3
    // Direction = (deltaRow, deltaCol) between consecutive cells

Export: generatePath, PathResult, DiagonalCommitments, and helper functions needed by other modules.
```

---

## Subphase 2.3: Connector Graph Builder

### Prompt for Claude Code:

```
Create the connector graph building system for Circuit Challenge.

File: src/modules/circuit-challenge/engine/connectors.ts

Import types from ../types and DiagonalCommitments from ./pathfinder

1. Create type for connector before value assignment:
   interface UnvaluedConnector {
     type: 'horizontal' | 'vertical' | 'diagonal';
     cellA: Coordinate;
     cellB: Coordinate;
     direction?: DiagonalDirection; // Only for diagonals
   }

2. Create type for the diagonal grid:
   type DiagonalGrid = DiagonalDirection[][]; // [row][col] for each 2x2 block

3. Function - buildDiagonalGrid(
     rows: number,
     cols: number,
     commitments: DiagonalCommitments
   ): DiagonalGrid
   
   // Create a (rows-1) x (cols-1) grid of diagonal directions
   // For each 2x2 block:
   //   - If commitment exists for this block, use it
   //   - Otherwise, randomly choose 'DR' or 'DL'
   // Return the grid

4. Function - buildConnectorGraph(
     rows: number,
     cols: number,
     diagonalGrid: DiagonalGrid
   ): UnvaluedConnector[]
   
   Algorithm:
   a. Initialize empty connectors array
   
   b. Add horizontal connectors:
      For row 0 to rows-1:
        For col 0 to cols-2:
          Add connector: type 'horizontal', cellA (row, col), cellB (row, col+1)
   
   c. Add vertical connectors:
      For row 0 to rows-2:
        For col 0 to cols-1:
          Add connector: type 'vertical', cellA (row, col), cellB (row+1, col)
   
   d. Add diagonal connectors:
      For row 0 to rows-2:
        For col 0 to cols-2:
          direction = diagonalGrid[row][col]
          If direction === 'DR':
            cellA = (row, col), cellB = (row+1, col+1)
          Else: // 'DL'
            cellA = (row, col+1), cellB = (row+1, col)
          Add connector with type 'diagonal' and direction
   
   e. Return connectors array

5. Function - getCellConnectors(
     cell: Coordinate,
     connectors: UnvaluedConnector[] | Connector[]
   ): (UnvaluedConnector | Connector)[]
   
   // Return all connectors that touch this cell (where cell equals cellA or cellB)

6. Function - getConnectorBetween(
     cellA: Coordinate,
     cellB: Coordinate,
     connectors: Connector[]
   ): Connector | undefined
   
   // Find connector that connects these two cells (order independent)

7. Function - areAdjacent(a: Coordinate, b: Coordinate): boolean
   // True if cells are horizontally, vertically, or diagonally adjacent

Export all functions and types.
```

---

## Subphase 2.4: Connector Value Assignment

### Prompt for Claude Code:

```
Create the connector value assignment algorithm for Circuit Challenge.

File: src/modules/circuit-challenge/engine/valueAssigner.ts

Import types and functions from ./connectors and ../types

1. Create result type:
   interface ValueAssignmentResult {
     success: boolean;
     connectors: Connector[];
     error?: string;
   }

2. Function - assignConnectorValues(
     unvaluedConnectors: UnvaluedConnector[],
     minValue: number,
     maxValue: number
   ): ValueAssignmentResult

   Algorithm:
   a. Build a map: cellKey -> list of connector indices touching that cell
      cellConnectorMap: Map<string, number[]>
   
   b. Create a copy of connectors with null values:
      connectors: (UnvaluedConnector & { value: number | null })[]
   
   c. Shuffle the connector indices for variety:
      indices = shuffle([0, 1, 2, ..., connectors.length - 1])
   
   d. For each index in shuffled order:
      connector = connectors[index]
      cellAKey = coordToKey(connector.cellA)
      cellBKey = coordToKey(connector.cellB)
      
      // Collect all values already used by connectors touching cellA or cellB
      usedValues = new Set<number>()
      For each connector index touching cellA (from cellConnectorMap):
        if that connector has a value, add to usedValues
      For each connector index touching cellB (from cellConnectorMap):
        if that connector has a value, add to usedValues
      
      // Find available values
      available: number[] = []
      For v from minValue to maxValue:
        if v not in usedValues:
          available.push(v)
      
      // If no available values, assignment failed
      if available.length === 0:
        return { success: false, error: `No available values for connector at ${cellAKey}-${cellBKey}` }
      
      // Randomly select from available
      connector.value = randomChoice(available)
   
   e. Convert to proper Connector type (value is now guaranteed non-null)
   
   f. Return { success: true, connectors }

3. Helper function - shuffle<T>(array: T[]): T[]
   // Fisher-Yates shuffle, returns new array

4. Helper function - randomChoice<T>(array: T[]): T
   // Returns random element from array

5. Helper function - randomInt(min: number, max: number): number
   // Returns random integer in [min, max] inclusive

Export all functions and types.
```

---

## Subphase 2.5: Cell Answer Assignment

### Prompt for Claude Code:

```
Create the cell answer assignment system for Circuit Challenge.

File: src/modules/circuit-challenge/engine/cellAssigner.ts

Import types from ../types and ./connectors

1. Create the Cell grid type:
   interface CellGrid {
     cells: Cell[][];
     rows: number;
     cols: number;
   }

2. Function - assignCellAnswers(
     rows: number,
     cols: number,
     solutionPath: Coordinate[],
     connectors: Connector[]
   ): CellGrid

   Algorithm:
   a. Initialize cells grid: Cell[rows][cols]
      Each cell starts with:
        - row, col from position
        - expression: "" (to be filled later)
        - answer: null
        - isStart: (row === 0 && col === 0)
        - isFinish: (row === rows-1 && col === cols-1)
   
   b. Create a Set of solution path coordinates for quick lookup:
      pathSet = new Set(solutionPath.map(c => coordToKey(c)))
   
   c. Assign answers for cells ON the solution path:
      For i from 0 to solutionPath.length - 2: // Exclude FINISH
        current = solutionPath[i]
        next = solutionPath[i + 1]
        
        // Find the connector between current and next
        connector = getConnectorBetween(current, next, connectors)
        
        // The cell's answer is the connector's value (so player follows this connector)
        cells[current.row][current.col].answer = connector.value
   
   d. Assign answers for cells NOT on the solution path (except FINISH):
      For each cell in grid:
        if cell is FINISH: continue (answer stays null)
        if coordToKey(cell) is in pathSet: continue (already assigned)
        
        // Get all connectors touching this cell
        cellConnectors = getCellConnectors(cell, connectors)
        
        // Pick a random connector's value as this cell's answer
        // This creates a "wrong path" that leads somewhere
        randomConnector = randomChoice(cellConnectors)
        cell.answer = randomConnector.value
   
   e. Return { cells, rows, cols }

3. Function - getExitCell(
     cell: Coordinate,
     connectors: Connector[]
   ): Coordinate | null
   
   // Given a cell, find which cell it leads to based on its answer
   // Returns null for FINISH or if no matching connector

Export functions and types.
```

---

## Subphase 2.6: Expression Generation

### Prompt for Claude Code:

```
Create the arithmetic expression generator for Circuit Challenge.

File: src/modules/circuit-challenge/engine/expressions.ts

Import types from ./types (DifficultySettings, Operation)

1. Create expression result type:
   interface Expression {
     text: string;      // e.g., "5 + 8"
     operation: Operation;
     operandA: number;
     operandB: number;
     result: number;
   }

2. Function - selectOperation(weights: DifficultySettings['weights']): Operation
   // Weighted random selection based on non-zero weights
   // Sum all weights, pick random point, find which operation it falls in
   // Only consider operations with weight > 0

3. Function - generateAddition(target: number, maxOperand: number): Expression | null
   // target = a + b
   // a can be 1 to min(target - 1, maxOperand)
   // b = target - a
   // Ensure b <= maxOperand, else return null
   // Return { text: `${a} + ${b}`, operation: '+', operandA: a, operandB: b, result: target }

4. Function - generateSubtraction(target: number, maxOperand: number): Expression | null
   // a - b = target, so a = target + b
   // b can be 1 to (maxOperand - target)
   // If no valid b exists (maxOperand <= target), return null
   // Return { text: `${a} − ${b}`, ... } // Note: use proper minus sign −

5. Function - generateMultiplication(target: number, maxFactor: number): Expression | null
   // a × b = target
   // Find all factor pairs where both a and b are in [2, maxFactor]
   // If no valid pairs, return null
   // Pick random pair, randomly swap order
   // Return { text: `${a} × ${b}`, ... }

6. Function - generateDivision(target: number, maxDivisor: number, maxDividend: number = 144): Expression | null
   // a ÷ b = target, so a = target × b
   // Find valid divisors b in [2, min(maxDivisor, 12)] where a <= maxDividend
   // If no valid divisors, return null
   // Return { text: `${a} ÷ ${b}`, ... }

7. Main function - generateExpression(
     target: number,
     difficulty: DifficultySettings
   ): Expression

   Algorithm:
   a. Determine which operations are enabled based on difficulty settings
   
   b. Try up to 10 times:
      - Select operation using weights
      - Attempt to generate expression for that operation:
        * '+': generateAddition(target, difficulty.addSubRange)
        * '−': generateSubtraction(target, difficulty.addSubRange)
        * '×': generateMultiplication(target, difficulty.multDivRange)
        * '÷': generateDivision(target, difficulty.multDivRange)
      - If successful, return the expression
   
   c. Fallback: Always use addition (guaranteed to work for target >= 2)
      - If target === 1: return { text: "2 − 1", operation: '−', ... }
      - Else: force generateAddition with relaxed constraints

8. Function - applyExpressions(
     cells: Cell[][],
     difficulty: DifficultySettings
   ): void
   
   // Mutates cells in place
   // For each cell:
   //   If cell.answer is not null (not FINISH):
   //     expression = generateExpression(cell.answer, difficulty)
   //     cell.expression = expression.text

Export all functions.
```

---

## Subphase 2.7: Puzzle Validation

### Prompt for Claude Code:

```
Create the puzzle validation system for Circuit Challenge.

File: src/modules/circuit-challenge/engine/validator.ts

Import all necessary types from ../types and other engine modules

1. Create validation result type:
   interface ValidationResult {
     valid: boolean;
     errors: string[];
     warnings: string[];
   }

2. Function - validatePath(
     path: Coordinate[],
     rows: number,
     cols: number
   ): ValidationResult
   
   Checks:
   - Path has at least 2 elements
   - First element is (0, 0) - START
   - Last element is (rows-1, cols-1) - FINISH
   - Each consecutive pair is adjacent (no teleporting)
   - No coordinate appears twice (no loops)

3. Function - validateConnectorUniqueness(
     connectors: Connector[],
     rows: number,
     cols: number
   ): ValidationResult
   
   Checks:
   - For each cell in the grid:
     * Get all connectors touching that cell
     * Extract their values
     * Check for duplicates
     * If duplicates found, add error

4. Function - validateCellAnswers(
     cells: Cell[][],
     connectors: Connector[]
   ): ValidationResult
   
   Checks:
   - For each cell (except FINISH):
     * Cell has a non-null answer
     * Exactly one connector touching this cell has that value
   - FINISH cell has null answer

5. Function - validateSolutionPath(
     path: Coordinate[],
     cells: Cell[][],
     connectors: Connector[]
   ): ValidationResult
   
   Checks:
   - For each step in path (except last):
     * Current cell's answer equals the connector value to next cell
     * The connector between current and next exists

6. Function - validateExpressions(cells: Cell[][]): ValidationResult
   
   Checks:
   - For each cell with an answer:
     * Expression is not empty
     * Parse and evaluate the expression
     * Result equals cell.answer
   
   Helper: evaluateExpression(expr: string): number | null
     // Parse "5 + 8" or "12 − 3" etc. and compute result
     // Handle the proper unicode operators: +, −, ×, ÷
     // Return null if parsing fails

7. Main function - validatePuzzle(puzzle: Puzzle): ValidationResult
   
   Run all validations and aggregate results:
   - validatePath
   - validateConnectorUniqueness
   - validateCellAnswers
   - validateSolutionPath
   - validateExpressions
   
   Return combined errors and warnings, valid = (errors.length === 0)

Export all validation functions.
```

---

## Subphase 2.8: Main Generator Orchestration

### Prompt for Claude Code:

```
Create the main puzzle generator that orchestrates all components.

File: src/modules/circuit-challenge/engine/generator.ts

Import all engine modules:
- DifficultySettings, GenerationResult from ./types
- generatePath from ./pathfinder
- buildDiagonalGrid, buildConnectorGraph from ./connectors
- assignConnectorValues from ./valueAssigner
- assignCellAnswers from ./cellAssigner
- applyExpressions from ./expressions
- validatePuzzle from ./validator
- Puzzle, Cell, Connector from ../types

1. Create generation options type:
   interface GenerationOptions {
     maxAttempts?: number;      // Default: 20
     validateResult?: boolean;  // Default: true
   }

2. Main function - generatePuzzle(
     difficulty: DifficultySettings,
     options: GenerationOptions = {}
   ): GenerationResult

   Algorithm:
   const maxAttempts = options.maxAttempts ?? 20;
   const validateResult = options.validateResult ?? true;
   
   const { gridRows, gridCols, connectorMin, connectorMax } = difficulty;
   const minPath = calculateMinPathLength(gridRows, gridCols);
   const maxPath = calculateMaxPathLength(gridRows, gridCols);
   
   For attempt from 1 to maxAttempts:
     try:
       // Step 1: Generate solution path
       const pathResult = generatePath(gridRows, gridCols, minPath, maxPath);
       if (!pathResult.success) continue;
       
       // Step 2: Build diagonal grid from path commitments
       const diagonalGrid = buildDiagonalGrid(gridRows, gridCols, pathResult.diagonalCommitments);
       
       // Step 3: Build connector graph
       const unvaluedConnectors = buildConnectorGraph(gridRows, gridCols, diagonalGrid);
       
       // Step 4: Assign connector values
       const valueResult = assignConnectorValues(unvaluedConnectors, connectorMin, connectorMax);
       if (!valueResult.success) continue;
       
       // Step 5: Assign cell answers based on solution path
       const cellGrid = assignCellAnswers(gridRows, gridCols, pathResult.path, valueResult.connectors);
       
       // Step 6: Generate arithmetic expressions for each cell
       applyExpressions(cellGrid.cells, difficulty);
       
       // Step 7: Construct puzzle object
       const puzzle: Puzzle = {
         id: generatePuzzleId(),
         difficulty,
         grid: cellGrid.cells,
         connectors: valueResult.connectors,
         solution: {
           path: pathResult.path,
           steps: pathResult.path.length - 1
         }
       };
       
       // Step 8: Validate if requested
       if (validateResult) {
         const validation = validatePuzzle(puzzle);
         if (!validation.valid) {
           console.warn(`Attempt ${attempt} failed validation:`, validation.errors);
           continue;
         }
       }
       
       // Success!
       return { success: true, puzzle };
       
     catch (error):
       console.warn(`Attempt ${attempt} threw error:`, error);
       continue;
   
   // All attempts failed
   return {
     success: false,
     error: `Failed to generate puzzle after ${maxAttempts} attempts. Try adjusting difficulty settings.`
   };

3. Helper function - generatePuzzleId(): string
   // Return a unique ID using uuid or timestamp + random

4. Export generatePuzzle and GenerationOptions

5. Update src/modules/circuit-challenge/engine/index.ts to export:
   - generatePuzzle
   - All difficulty presets and helpers
   - Types needed by other parts of the app
```

---

## Subphase 2.9: Engine Unit Tests

### Prompt for Claude Code:

```
Create comprehensive unit tests for the puzzle generation engine.

File: src/modules/circuit-challenge/engine/__tests__/generator.test.ts

Using Vitest, create tests for:

1. Difficulty Tests:
   - All 10 presets load correctly
   - getDifficultyByLevel returns correct preset
   - validateDifficultySettings catches invalid configs
   - createCustomDifficulty merges correctly

2. Path Generation Tests:
   - Generates path from (0,0) to (rows-1, cols-1)
   - Path length is within min/max bounds
   - All path coordinates are within grid
   - No duplicate coordinates in path
   - Consecutive coordinates are adjacent
   - Diagonal commitments don't conflict

3. Connector Tests:
   - Correct number of horizontal connectors: rows * (cols - 1)
   - Correct number of vertical connectors: (rows - 1) * cols
   - Correct number of diagonal connectors: (rows - 1) * (cols - 1)
   - Each 2x2 block has exactly one diagonal
   - All connector values are unique per cell

4. Expression Tests:
   - generateAddition produces valid expressions
   - generateSubtraction produces valid expressions (no negatives)
   - generateMultiplication finds factor pairs correctly
   - generateDivision produces whole number results
   - Fallback to addition works for edge cases
   - All expressions evaluate to their target

5. Validation Tests:
   - Valid puzzle passes all checks
   - Invalid path is detected
   - Duplicate connector values detected
   - Wrong cell answers detected
   - Expression mismatches detected

6. Full Generation Tests:
   - Generate 10 puzzles at each difficulty level (1-10)
   - All should succeed (success: true)
   - All should pass validation
   - Generation time under 500ms per puzzle
   - Test with hidden mode enabled/disabled

7. Edge Cases:
   - Minimum grid size (3x3)
   - Large grid size (8x10)
   - Single operation enabled
   - Very narrow connector range

Create helper function to run property-based style tests:
  - generateAndValidateMany(difficulty, count): { passed: number, failed: number, errors: string[] }

Add test script to package.json: "test:engine": "vitest run src/modules/circuit-challenge/engine"
```

---

## Phase 2 Completion Checklist

After completing all subphases, verify:

- [ ] All 10 difficulty presets are correctly defined
- [ ] Path generation creates valid paths consistently
- [ ] Connector values are always unique per cell
- [ ] Expressions evaluate correctly to cell answers
- [ ] Full puzzle validation passes
- [ ] `npm run test:engine` passes all tests
- [ ] Can generate 100 puzzles at Level 5 without failures
- [ ] Generation time is under 200ms for typical puzzles

---

## Files Created in This Phase

```
src/modules/circuit-challenge/engine/
├── index.ts              # Re-exports all engine functionality
├── types.ts              # Updated with full type definitions
├── difficulty.ts         # 10 presets + helpers
├── pathfinder.ts         # Solution path generation
├── connectors.ts         # Connector graph building
├── valueAssigner.ts      # Connector value assignment
├── cellAssigner.ts       # Cell answer assignment
├── expressions.ts        # Arithmetic expression generation
├── validator.ts          # Puzzle validation
├── generator.ts          # Main orchestration
└── __tests__/
    └── generator.test.ts # Comprehensive unit tests
```

---

## Key Algorithm Summary

```
generatePuzzle(difficulty)
    │
    ├── 1. generatePath() ──────────────────────► PathResult { path, diagonalCommitments }
    │
    ├── 2. buildDiagonalGrid() ─────────────────► DiagonalGrid[][]
    │
    ├── 3. buildConnectorGraph() ───────────────► UnvaluedConnector[]
    │
    ├── 4. assignConnectorValues() ─────────────► Connector[] (with unique values)
    │
    ├── 5. assignCellAnswers() ─────────────────► CellGrid { cells[][] }
    │       └── Path cells: answer = exit connector value
    │       └── Other cells: answer = random connector value
    │
    ├── 6. applyExpressions() ──────────────────► cells[].expression filled
    │       └── Generate arithmetic for each answer
    │
    ├── 7. validatePuzzle() ────────────────────► ValidationResult
    │
    └── 8. Return Puzzle object
```

---

*End of Phase 2*
