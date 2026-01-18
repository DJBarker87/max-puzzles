// Types
export type {
  DifficultySettings,
  GenerationResult,
  Operation,
  OperationWeights,
  ValidationResult,
} from './types'

// Difficulty system
export {
  DIFFICULTY_PRESETS,
  LEVEL_1_TINY_TOT,
  LEVEL_2_BEGINNER,
  LEVEL_3_EASY,
  LEVEL_4_GETTING_THERE,
  LEVEL_5_TIMES_TABLES,
  LEVEL_6_CONFIDENT,
  LEVEL_7_ADVENTUROUS,
  LEVEL_8_DIVISION_INTRO,
  LEVEL_9_CHALLENGE,
  LEVEL_10_EXPERT,
  getDifficultyByLevel,
  getDifficultyByName,
  createCustomDifficulty,
  calculateMinPathLength,
  calculateMaxPathLength,
  validateDifficultySettings,
} from './difficulty'

// Path generation
export {
  generatePath,
  coordToKey,
  isInterestingPath,
  manhattanDistance,
} from './pathfinder'
export type { PathResult, DiagonalCommitments, DiagonalKey } from './pathfinder'

// Connectors
export {
  buildDiagonalGrid,
  buildConnectorGraph,
  getCellConnectors,
  getConnectorBetween,
  areAdjacent,
  getOtherCell,
} from './connectors'
export type { UnvaluedConnector, DiagonalGrid } from './connectors'

// Value assignment
export {
  assignConnectorValues,
  shuffle,
  randomChoice,
  randomInt,
} from './valueAssigner'
export type { ValueAssignmentResult } from './valueAssigner'

// Cell assignment
export { assignCellAnswers, getExitCell } from './cellAssigner'
export type { CellGrid } from './cellAssigner'

// Expression generation
export {
  generateExpression,
  applyExpressions,
  evaluateExpression,
  selectOperation,
  generateAddition,
  generateSubtraction,
  generateMultiplication,
  generateDivision,
} from './expressions'
export type { Expression } from './expressions'

// Validation
export {
  validatePuzzle,
  validatePath,
  validateConnectorUniqueness,
  validateCellAnswers,
  validateSolutionPath,
  validateExpressions,
} from './validator'

// Main generator
export { generatePuzzle } from './generator'
export type { GenerationOptions } from './generator'
