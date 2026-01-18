import { faker } from '@faker-js/faker'
import type { Cell, Puzzle, Connector, Coordinate } from '@/modules/circuit-challenge/types'
import type { PrintablePuzzle, PrintableCell } from '@/modules/circuit-challenge/types/print'

export function createMockCell(overrides: Partial<Cell> = {}): Cell {
  return {
    row: 0,
    col: 0,
    expression: String(faker.number.int({ min: 1, max: 20 })),
    answer: faker.number.int({ min: 1, max: 20 }),
    isStart: false,
    isFinish: false,
    ...overrides,
  }
}

export function createMockConnector(overrides: Partial<Connector> = {}): Connector {
  return {
    type: 'horizontal',
    cellA: { row: 0, col: 0 },
    cellB: { row: 0, col: 1 },
    value: faker.number.int({ min: 5, max: 20 }),
    ...overrides,
  }
}

export function createMockPuzzle(overrides: Partial<Puzzle> = {}): Puzzle {
  const gridRows = 3
  const gridCols = 4

  // Create a simple grid
  const grid: Cell[][] = []
  for (let row = 0; row < gridRows; row++) {
    const rowCells: Cell[] = []
    for (let col = 0; col < gridCols; col++) {
      rowCells.push(
        createMockCell({
          row,
          col,
          isStart: row === 0 && col === 0,
          isFinish: row === gridRows - 1 && col === gridCols - 1,
        })
      )
    }
    grid.push(rowCells)
  }

  // Simple solution path
  const solution: Coordinate[] = [
    { row: 0, col: 0 },
    { row: 0, col: 1 },
    { row: 0, col: 2 },
    { row: 1, col: 2 },
    { row: 2, col: 2 },
    { row: 2, col: 3 },
  ]

  return {
    id: faker.string.uuid(),
    difficulty: 3,
    grid,
    connectors: [],
    solution: {
      path: solution,
      steps: solution.length - 1,
    },
    ...overrides,
  }
}

export function createMockPrintablePuzzle(
  overrides: Partial<PrintablePuzzle> = {}
): PrintablePuzzle {
  const gridRows = 3
  const gridCols = 4
  const cells: PrintableCell[] = []

  for (let row = 0; row < gridRows; row++) {
    for (let col = 0; col < gridCols; col++) {
      const index = row * gridCols + col
      cells.push({
        index,
        row,
        col,
        expression: String(faker.number.int({ min: 1, max: 20 })),
        answer: faker.number.int({ min: 1, max: 20 }),
        isStart: index === 0,
        isEnd: index === gridRows * gridCols - 1,
        inSolution: false,
      })
    }
  }

  return {
    id: faker.string.uuid(),
    puzzleNumber: 1,
    difficulty: 3,
    difficultyName: 'Getting There',
    gridRows,
    gridCols,
    cells,
    connectors: [],
    targetSum: faker.number.int({ min: 20, max: 50 }),
    solution: [0, 1, 2, 6, 10, 11],
    ...overrides,
  }
}

export function createMockChild(overrides = {}) {
  return {
    id: faker.string.uuid(),
    displayName: faker.person.firstName(),
    coins: faker.number.int({ min: 0, max: 1000 }),
    role: 'child',
    ...overrides,
  }
}

export function createMockActivityEntry(overrides = {}) {
  return {
    id: faker.string.uuid(),
    moduleId: 'circuit-challenge',
    moduleName: 'Circuit Challenge',
    date: faker.date.recent().toISOString(),
    duration: faker.number.int({ min: 60, max: 1800 }),
    gamesPlayed: faker.number.int({ min: 1, max: 10 }),
    correctAnswers: faker.number.int({ min: 5, max: 20 }),
    mistakes: faker.number.int({ min: 0, max: 5 }),
    coinsEarned: faker.number.int({ min: 10, max: 100 }),
    ...overrides,
  }
}
