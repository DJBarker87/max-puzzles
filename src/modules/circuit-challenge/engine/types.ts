import type { Puzzle } from '../types'

/**
 * Arithmetic operations used in expressions
 */
export type Operation = '+' | '−' | '×' | '÷'

/**
 * Weights for operation selection
 */
export interface OperationWeights {
  addition: number
  subtraction: number
  multiplication: number
  division: number
}

/**
 * Difficulty settings for puzzle generation
 */
export interface DifficultySettings {
  /** Display name for this difficulty */
  name: string

  /** Whether addition is enabled */
  additionEnabled: boolean
  /** Whether subtraction is enabled */
  subtractionEnabled: boolean
  /** Whether multiplication is enabled */
  multiplicationEnabled: boolean
  /** Whether division is enabled */
  divisionEnabled: boolean

  /** Range for addition/subtraction operands */
  addSubRange: number
  /** Range for multiplication/division operands */
  multDivRange: number

  /** Minimum connector value */
  connectorMin: number
  /** Maximum connector value */
  connectorMax: number

  /** Number of rows in the grid */
  gridRows: number
  /** Number of columns in the grid */
  gridCols: number

  /** Minimum path length */
  minPathLength: number
  /** Maximum path length */
  maxPathLength: number

  /** Weights for operation selection */
  weights: OperationWeights

  /** Whether to use hidden mode (no lives, reveal at end) */
  hiddenMode: boolean

  /** Seconds allowed per step for timer calculation */
  secondsPerStep: number
}

/**
 * Result of puzzle generation
 */
export type GenerationResult =
  | { success: true; puzzle: Puzzle }
  | { success: false; error: string }

/**
 * Expression component for building arithmetic expressions
 */
export interface ExpressionPart {
  /** The numeric value */
  value: number
  /** The operation to apply (for subsequent parts) */
  operation?: Operation
}

/**
 * Validation result for a generated puzzle
 */
export interface ValidationResult {
  /** Whether the puzzle is valid */
  valid: boolean
  /** Error messages if invalid */
  errors: string[]
}
