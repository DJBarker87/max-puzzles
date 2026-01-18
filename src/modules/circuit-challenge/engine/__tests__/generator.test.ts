import { describe, it, expect } from 'vitest'
import {
  DIFFICULTY_PRESETS,
  getDifficultyByLevel,
  getDifficultyByName,
  validateDifficultySettings,
  createCustomDifficulty,
  calculateMinPathLength,
  calculateMaxPathLength,
} from '../difficulty'
import { generatePath, coordToKey, isInterestingPath } from '../pathfinder'
import { buildDiagonalGrid, buildConnectorGraph, getCellConnectors, areAdjacent } from '../connectors'
import { assignConnectorValues } from '../valueAssigner'
import {
  generateAddition,
  generateSubtraction,
  generateMultiplication,
  generateDivision,
  evaluateExpression,
} from '../expressions'
import { validatePuzzle } from '../validator'
import { generatePuzzle } from '../generator'

describe('Difficulty System', () => {
  it('has 10 preset levels', () => {
    expect(DIFFICULTY_PRESETS).toHaveLength(10)
  })

  it('getDifficultyByLevel returns correct preset', () => {
    const level1 = getDifficultyByLevel(1)
    expect(level1.name).toBe('Tiny Tot')

    const level5 = getDifficultyByLevel(5)
    expect(level5.name).toBe('Times Tables')

    const level10 = getDifficultyByLevel(10)
    expect(level10.name).toBe('Expert')
  })

  it('getDifficultyByName returns correct preset', () => {
    const difficulty = getDifficultyByName('Beginner')
    expect(difficulty).toBeDefined()
    expect(difficulty?.gridRows).toBe(4)
    expect(difficulty?.gridCols).toBe(4)
  })

  it('validateDifficultySettings catches invalid configs', () => {
    const invalidNoOps = createCustomDifficulty({
      additionEnabled: false,
      subtractionEnabled: false,
      multiplicationEnabled: false,
      divisionEnabled: false,
    })
    const result = validateDifficultySettings(invalidNoOps)
    expect(result.valid).toBe(false)
    expect(result.errors).toContain('At least one operation must be enabled')
  })

  it('createCustomDifficulty merges correctly', () => {
    const custom = createCustomDifficulty({
      gridRows: 6,
      gridCols: 7,
    })
    expect(custom.gridRows).toBe(6)
    expect(custom.gridCols).toBe(7)
    expect(custom.name).toBe('Custom')
    // Should calculate path lengths
    expect(custom.minPathLength).toBeGreaterThan(0)
    expect(custom.maxPathLength).toBeGreaterThan(custom.minPathLength)
  })

  it('path length calculations are reasonable', () => {
    const minPath = calculateMinPathLength(4, 5)
    const maxPath = calculateMaxPathLength(4, 5)
    expect(minPath).toBeGreaterThanOrEqual(4)
    expect(maxPath).toBeGreaterThan(minPath)
    expect(maxPath).toBeLessThanOrEqual(20) // 4*5 = 20
  })
})

describe('Path Generation', () => {
  it('generates path from START to FINISH', () => {
    const result = generatePath(4, 5, 8, 15)
    expect(result.success).toBe(true)
    expect(result.path.length).toBeGreaterThanOrEqual(8)
    expect(result.path[0]).toEqual({ row: 0, col: 0 })
    expect(result.path[result.path.length - 1]).toEqual({ row: 3, col: 4 })
  })

  it('path has no duplicate coordinates', () => {
    const result = generatePath(4, 5, 8, 15)
    expect(result.success).toBe(true)
    const keys = new Set(result.path.map(coordToKey))
    expect(keys.size).toBe(result.path.length)
  })

  it('consecutive coordinates are adjacent', () => {
    const result = generatePath(4, 5, 8, 15)
    expect(result.success).toBe(true)
    for (let i = 1; i < result.path.length; i++) {
      expect(areAdjacent(result.path[i - 1], result.path[i])).toBe(true)
    }
  })

  it('generates interesting paths', () => {
    const result = generatePath(4, 5, 8, 15)
    expect(result.success).toBe(true)
    expect(isInterestingPath(result.path)).toBe(true)
  })
})

describe('Connector System', () => {
  it('generates correct number of horizontal connectors', () => {
    const rows = 4
    const cols = 5
    const diagonalGrid = buildDiagonalGrid(rows, cols, new Map())
    const connectors = buildConnectorGraph(rows, cols, diagonalGrid)
    const horizontal = connectors.filter(c => c.type === 'horizontal')
    expect(horizontal.length).toBe(rows * (cols - 1)) // 4 * 4 = 16
  })

  it('generates correct number of vertical connectors', () => {
    const rows = 4
    const cols = 5
    const diagonalGrid = buildDiagonalGrid(rows, cols, new Map())
    const connectors = buildConnectorGraph(rows, cols, diagonalGrid)
    const vertical = connectors.filter(c => c.type === 'vertical')
    expect(vertical.length).toBe((rows - 1) * cols) // 3 * 5 = 15
  })

  it('generates correct number of diagonal connectors', () => {
    const rows = 4
    const cols = 5
    const diagonalGrid = buildDiagonalGrid(rows, cols, new Map())
    const connectors = buildConnectorGraph(rows, cols, diagonalGrid)
    const diagonal = connectors.filter(c => c.type === 'diagonal')
    expect(diagonal.length).toBe((rows - 1) * (cols - 1)) // 3 * 4 = 12
  })

  it('assigns unique values per cell', () => {
    const rows = 4
    const cols = 5
    const diagonalGrid = buildDiagonalGrid(rows, cols, new Map())
    const unvaluedConnectors = buildConnectorGraph(rows, cols, diagonalGrid)
    const result = assignConnectorValues(unvaluedConnectors, 5, 30)

    expect(result.success).toBe(true)

    // Check each cell has unique connector values
    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        const cellConnectors = getCellConnectors({ row, col }, result.connectors)
        const values = cellConnectors.map(c => c.value)
        const uniqueValues = new Set(values)
        expect(uniqueValues.size).toBe(values.length)
      }
    }
  })
})

describe('Expression Generation', () => {
  it('generateAddition produces valid expressions', () => {
    const expr = generateAddition(15, 10)
    expect(expr).not.toBeNull()
    expect(expr!.result).toBe(15)
    expect(expr!.operandA + expr!.operandB).toBe(15)
  })

  it('generateSubtraction produces valid expressions', () => {
    const expr = generateSubtraction(7, 15)
    expect(expr).not.toBeNull()
    expect(expr!.result).toBe(7)
    expect(expr!.operandA - expr!.operandB).toBe(7)
    expect(expr!.operandA).toBeGreaterThan(expr!.operandB)
  })

  it('generateMultiplication finds factor pairs', () => {
    const expr = generateMultiplication(12, 6)
    expect(expr).not.toBeNull()
    expect(expr!.result).toBe(12)
    expect(expr!.operandA * expr!.operandB).toBe(12)
  })

  it('generateDivision produces whole number results', () => {
    const expr = generateDivision(6, 12)
    expect(expr).not.toBeNull()
    expect(expr!.result).toBe(6)
    expect(expr!.operandA / expr!.operandB).toBe(6)
    expect(expr!.operandA % expr!.operandB).toBe(0) // Whole number
  })

  it('evaluateExpression handles all operations', () => {
    expect(evaluateExpression('5 + 3')).toBe(8)
    expect(evaluateExpression('10 − 4')).toBe(6)
    expect(evaluateExpression('6 × 7')).toBe(42)
    expect(evaluateExpression('24 ÷ 4')).toBe(6)
  })

  it('evaluateExpression handles START and FINISH', () => {
    expect(evaluateExpression('START')).toBeNull()
    expect(evaluateExpression('FINISH')).toBeNull()
  })
})

describe('Full Puzzle Generation', () => {
  it('generates valid puzzle at Level 1', () => {
    const difficulty = getDifficultyByLevel(1)
    const result = generatePuzzle(difficulty)
    expect(result.success).toBe(true)
    if (result.success) {
      const validation = validatePuzzle(result.puzzle)
      expect(validation.valid).toBe(true)
    }
  })

  it('generates valid puzzle at Level 5', () => {
    const difficulty = getDifficultyByLevel(5)
    const result = generatePuzzle(difficulty)
    expect(result.success).toBe(true)
    if (result.success) {
      const validation = validatePuzzle(result.puzzle)
      expect(validation.valid).toBe(true)
    }
  })

  it('generates valid puzzle at Level 10', () => {
    const difficulty = getDifficultyByLevel(10)
    const result = generatePuzzle(difficulty)
    expect(result.success).toBe(true)
    if (result.success) {
      const validation = validatePuzzle(result.puzzle)
      expect(validation.valid).toBe(true)
    }
  })

  it('generates 10 puzzles at each difficulty level', () => {
    for (let level = 1; level <= 10; level++) {
      const difficulty = getDifficultyByLevel(level)
      let successCount = 0
      for (let i = 0; i < 10; i++) {
        const result = generatePuzzle(difficulty)
        if (result.success) {
          successCount++
        }
      }
      // Allow some failures but expect most to succeed
      expect(successCount).toBeGreaterThanOrEqual(7)
    }
  })
})

describe('Edge Cases', () => {
  it('handles minimum grid size (3x4)', () => {
    const difficulty = createCustomDifficulty({
      gridRows: 3,
      gridCols: 4,
    })
    const result = generatePuzzle(difficulty)
    expect(result.success).toBe(true)
  })

  it('handles larger grid size (6x8)', () => {
    const difficulty = createCustomDifficulty({
      gridRows: 6,
      gridCols: 8,
    })
    const result = generatePuzzle(difficulty)
    expect(result.success).toBe(true)
  })

  it('handles single operation enabled', () => {
    const difficulty = createCustomDifficulty({
      additionEnabled: true,
      subtractionEnabled: false,
      multiplicationEnabled: false,
      divisionEnabled: false,
      weights: { addition: 100, subtraction: 0, multiplication: 0, division: 0 },
    })
    const result = generatePuzzle(difficulty)
    expect(result.success).toBe(true)
  })
})
