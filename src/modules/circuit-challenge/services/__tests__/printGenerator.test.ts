import { describe, it, expect } from 'vitest'
import {
  generatePrintablePuzzles,
  generateBatchId,
  validatePrintConfig,
} from '../printGenerator'
import type { PrintConfig } from '../../types/print'

const defaultConfig: PrintConfig = {
  pageSize: 'A4',
  orientation: 'portrait',
  puzzlesPerPage: 2,
  difficulty: 3,
  showAnswers: false,
  puzzleCount: 2,
  title: 'Test Puzzles',
  subtitle: '',
  showPuzzleNumber: true,
  showDifficulty: true,
  showDate: false,
  showPageNumbers: false,
  cellSize: 12,
  lineWidth: 1,
  fontSize: 10,
  uniquePuzzles: true,
}

describe('Print Generator', () => {
  describe('generatePrintablePuzzles', () => {
    it('generates requested number of puzzles', () => {
      const puzzles = generatePrintablePuzzles({ ...defaultConfig, puzzleCount: 3 })
      expect(puzzles.length).toBe(3)
    })

    it('generates puzzles with correct structure', () => {
      const puzzles = generatePrintablePuzzles({ ...defaultConfig, puzzleCount: 1 })
      expect(puzzles.length).toBe(1)

      const puzzle = puzzles[0]
      expect(puzzle).toHaveProperty('id')
      expect(puzzle).toHaveProperty('puzzleNumber', 1)
      expect(puzzle).toHaveProperty('difficulty')
      expect(puzzle).toHaveProperty('difficultyName')
      expect(puzzle).toHaveProperty('gridRows')
      expect(puzzle).toHaveProperty('gridCols')
      expect(puzzle).toHaveProperty('cells')
      expect(puzzle).toHaveProperty('connectors')
      expect(puzzle).toHaveProperty('targetSum')
      expect(puzzle).toHaveProperty('solution')
    })

    it('includes all cells in the grid', () => {
      const puzzles = generatePrintablePuzzles({ ...defaultConfig, puzzleCount: 1 })
      const puzzle = puzzles[0]

      const expectedCellCount = puzzle.gridRows * puzzle.gridCols
      expect(puzzle.cells.length).toBe(expectedCellCount)
    })

    it('marks start and end cells correctly', () => {
      const puzzles = generatePrintablePuzzles({ ...defaultConfig, puzzleCount: 1 })
      const puzzle = puzzles[0]

      const startCells = puzzle.cells.filter(c => c.isStart)
      const endCells = puzzle.cells.filter(c => c.isEnd)

      expect(startCells.length).toBe(1)
      expect(endCells.length).toBe(1)

      // Start cell should be at (0,0)
      expect(startCells[0].row).toBe(0)
      expect(startCells[0].col).toBe(0)

      // End cell should be at (rows-1, cols-1)
      expect(endCells[0].row).toBe(puzzle.gridRows - 1)
      expect(endCells[0].col).toBe(puzzle.gridCols - 1)
    })

    it('has at least one solution cell marked', () => {
      const puzzles = generatePrintablePuzzles({ ...defaultConfig, puzzleCount: 1 })
      const puzzle = puzzles[0]

      const solutionCells = puzzle.cells.filter(c => c.inSolution)
      expect(solutionCells.length).toBeGreaterThanOrEqual(2) // At least start and end
    })

    it('assigns sequential puzzle numbers', () => {
      const puzzles = generatePrintablePuzzles({ ...defaultConfig, puzzleCount: 5 })

      for (let i = 0; i < puzzles.length; i++) {
        expect(puzzles[i].puzzleNumber).toBe(i + 1)
      }
    })

    it('respects difficulty setting', () => {
      const easyPuzzles = generatePrintablePuzzles({ ...defaultConfig, difficulty: 0 })
      const hardPuzzles = generatePrintablePuzzles({ ...defaultConfig, difficulty: 9 })

      // Different difficulties should produce different grid sizes
      // Level 0 (Tiny Tot) is 3x4, Level 9 (Expert) is 6x8
      expect(easyPuzzles[0].gridRows).toBeLessThanOrEqual(hardPuzzles[0].gridRows)
    })

    it('has connectors with solution markers', () => {
      const puzzles = generatePrintablePuzzles({ ...defaultConfig, puzzleCount: 1 })
      const puzzle = puzzles[0]

      // Should have some solution connectors
      const solutionConnectors = puzzle.connectors.filter(c => c.inSolution)
      expect(solutionConnectors.length).toBeGreaterThan(0)
    })

    it('generates valid solution indices', () => {
      const puzzles = generatePrintablePuzzles({ ...defaultConfig, puzzleCount: 1 })
      const puzzle = puzzles[0]

      const maxIndex = puzzle.gridRows * puzzle.gridCols - 1

      for (const index of puzzle.solution) {
        expect(index).toBeGreaterThanOrEqual(0)
        expect(index).toBeLessThanOrEqual(maxIndex)
      }

      // Solution should start at 0 (START cell)
      expect(puzzle.solution[0]).toBe(0)

      // Solution should end at last cell (FINISH)
      expect(puzzle.solution[puzzle.solution.length - 1]).toBe(maxIndex)
    })
  })

  describe('generateBatchId', () => {
    it('generates unique IDs', () => {
      const ids = new Set<string>()
      for (let i = 0; i < 100; i++) {
        ids.add(generateBatchId())
      }
      expect(ids.size).toBe(100)
    })

    it('generates IDs with correct prefix', () => {
      const id = generateBatchId()
      expect(id.startsWith('batch-')).toBe(true)
    })
  })

  describe('validatePrintConfig', () => {
    it('accepts valid configuration', () => {
      const errors = validatePrintConfig(defaultConfig)
      expect(errors.length).toBe(0)
    })

    it('rejects invalid difficulty', () => {
      const errors = validatePrintConfig({ difficulty: -1 })
      expect(errors).toContain('Difficulty must be between 0 and 9')

      const errors2 = validatePrintConfig({ difficulty: 10 })
      expect(errors2).toContain('Difficulty must be between 0 and 9')
    })

    it('rejects invalid puzzle count', () => {
      const errors = validatePrintConfig({ puzzleCount: 0 })
      expect(errors).toContain('Puzzle count must be between 1 and 100')

      const errors2 = validatePrintConfig({ puzzleCount: 101 })
      expect(errors2).toContain('Puzzle count must be between 1 and 100')
    })

    it('rejects invalid cell size', () => {
      const errors = validatePrintConfig({ cellSize: 5 })
      expect(errors).toContain('Cell size must be between 8mm and 20mm')

      const errors2 = validatePrintConfig({ cellSize: 25 })
      expect(errors2).toContain('Cell size must be between 8mm and 20mm')
    })

    it('accepts valid ranges', () => {
      expect(validatePrintConfig({ difficulty: 0 })).toHaveLength(0)
      expect(validatePrintConfig({ difficulty: 9 })).toHaveLength(0)
      expect(validatePrintConfig({ puzzleCount: 1 })).toHaveLength(0)
      expect(validatePrintConfig({ puzzleCount: 100 })).toHaveLength(0)
      expect(validatePrintConfig({ cellSize: 8 })).toHaveLength(0)
      expect(validatePrintConfig({ cellSize: 20 })).toHaveLength(0)
    })
  })
})
