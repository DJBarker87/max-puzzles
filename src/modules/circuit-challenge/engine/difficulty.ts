import type { DifficultySettings } from './types'

/**
 * Level 1: Tiny Tot - Addition only, small numbers
 */
export const LEVEL_1_TINY_TOT: DifficultySettings = {
  name: 'Tiny Tot',
  additionEnabled: true,
  subtractionEnabled: false,
  multiplicationEnabled: false,
  divisionEnabled: false,
  addSubRange: 10,
  multDivRange: 0,
  connectorMin: 5,
  connectorMax: 10,
  gridRows: 3,
  gridCols: 4,
  minPathLength: 0, // Will be calculated
  maxPathLength: 0, // Will be calculated
  weights: { addition: 100, subtraction: 0, multiplication: 0, division: 0 },
  hiddenMode: false,
  secondsPerStep: 10,
}

/**
 * Level 2: Beginner - Addition only, slightly larger
 */
export const LEVEL_2_BEGINNER: DifficultySettings = {
  name: 'Beginner',
  additionEnabled: true,
  subtractionEnabled: false,
  multiplicationEnabled: false,
  divisionEnabled: false,
  addSubRange: 15,
  multDivRange: 0,
  connectorMin: 5,
  connectorMax: 15,
  gridRows: 4,
  gridCols: 4,
  minPathLength: 0,
  maxPathLength: 0,
  weights: { addition: 100, subtraction: 0, multiplication: 0, division: 0 },
  hiddenMode: false,
  secondsPerStep: 9,
}

/**
 * Level 3: Easy - Addition and subtraction
 */
export const LEVEL_3_EASY: DifficultySettings = {
  name: 'Easy',
  additionEnabled: true,
  subtractionEnabled: true,
  multiplicationEnabled: false,
  divisionEnabled: false,
  addSubRange: 15,
  multDivRange: 0,
  connectorMin: 5,
  connectorMax: 15,
  gridRows: 4,
  gridCols: 5,
  minPathLength: 0,
  maxPathLength: 0,
  weights: { addition: 60, subtraction: 40, multiplication: 0, division: 0 },
  hiddenMode: false,
  secondsPerStep: 8,
}

/**
 * Level 4: Getting There - Addition and subtraction, larger range
 */
export const LEVEL_4_GETTING_THERE: DifficultySettings = {
  name: 'Getting There',
  additionEnabled: true,
  subtractionEnabled: true,
  multiplicationEnabled: false,
  divisionEnabled: false,
  addSubRange: 20,
  multDivRange: 0,
  connectorMin: 5,
  connectorMax: 20,
  gridRows: 4,
  gridCols: 5,
  minPathLength: 0,
  maxPathLength: 0,
  weights: { addition: 55, subtraction: 45, multiplication: 0, division: 0 },
  hiddenMode: false,
  secondsPerStep: 7,
}

/**
 * Level 5: Times Tables - Introduces multiplication
 */
export const LEVEL_5_TIMES_TABLES: DifficultySettings = {
  name: 'Times Tables',
  additionEnabled: true,
  subtractionEnabled: true,
  multiplicationEnabled: true,
  divisionEnabled: false,
  addSubRange: 20,
  multDivRange: 5,
  connectorMin: 5,
  connectorMax: 25,
  gridRows: 4,
  gridCols: 5,
  minPathLength: 0,
  maxPathLength: 0,
  weights: { addition: 40, subtraction: 35, multiplication: 25, division: 0 },
  hiddenMode: false,
  secondsPerStep: 7,
}

/**
 * Level 6: Confident - More multiplication focus
 */
export const LEVEL_6_CONFIDENT: DifficultySettings = {
  name: 'Confident',
  additionEnabled: true,
  subtractionEnabled: true,
  multiplicationEnabled: true,
  divisionEnabled: false,
  addSubRange: 25,
  multDivRange: 6,
  connectorMin: 5,
  connectorMax: 36,
  gridRows: 5,
  gridCols: 5,
  minPathLength: 0,
  maxPathLength: 0,
  weights: { addition: 35, subtraction: 30, multiplication: 35, division: 0 },
  hiddenMode: false,
  secondsPerStep: 6,
}

/**
 * Level 7: Adventurous - Larger grid, harder multiplication
 */
export const LEVEL_7_ADVENTUROUS: DifficultySettings = {
  name: 'Adventurous',
  additionEnabled: true,
  subtractionEnabled: true,
  multiplicationEnabled: true,
  divisionEnabled: false,
  addSubRange: 30,
  multDivRange: 8,
  connectorMin: 5,
  connectorMax: 64,
  gridRows: 5,
  gridCols: 6,
  minPathLength: 0,
  maxPathLength: 0,
  weights: { addition: 30, subtraction: 30, multiplication: 40, division: 0 },
  hiddenMode: false,
  secondsPerStep: 6,
}

/**
 * Level 8: Division Intro - All four operations
 */
export const LEVEL_8_DIVISION_INTRO: DifficultySettings = {
  name: 'Division Intro',
  additionEnabled: true,
  subtractionEnabled: true,
  multiplicationEnabled: true,
  divisionEnabled: true,
  addSubRange: 30,
  multDivRange: 6,
  connectorMin: 5,
  connectorMax: 36,
  gridRows: 5,
  gridCols: 6,
  minPathLength: 0,
  maxPathLength: 0,
  weights: { addition: 30, subtraction: 25, multiplication: 30, division: 15 },
  hiddenMode: false,
  secondsPerStep: 6,
}

/**
 * Level 9: Challenge - Larger numbers, more complex
 */
export const LEVEL_9_CHALLENGE: DifficultySettings = {
  name: 'Challenge',
  additionEnabled: true,
  subtractionEnabled: true,
  multiplicationEnabled: true,
  divisionEnabled: true,
  addSubRange: 50,
  multDivRange: 10,
  connectorMin: 5,
  connectorMax: 100,
  gridRows: 6,
  gridCols: 7,
  minPathLength: 0,
  maxPathLength: 0,
  weights: { addition: 25, subtraction: 25, multiplication: 30, division: 20 },
  hiddenMode: false,
  secondsPerStep: 5,
}

/**
 * Level 10: Expert - Maximum difficulty
 */
export const LEVEL_10_EXPERT: DifficultySettings = {
  name: 'Expert',
  additionEnabled: true,
  subtractionEnabled: true,
  multiplicationEnabled: true,
  divisionEnabled: true,
  addSubRange: 100,
  multDivRange: 12,
  connectorMin: 5,
  connectorMax: 144,
  gridRows: 6,
  gridCols: 8,
  minPathLength: 0,
  maxPathLength: 0,
  weights: { addition: 25, subtraction: 25, multiplication: 30, division: 20 },
  hiddenMode: false,
  secondsPerStep: 5,
}

/**
 * Array of all difficulty presets in order
 */
export const DIFFICULTY_PRESETS: DifficultySettings[] = [
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
]

/**
 * Calculate minimum path length for a grid (roughly 60% of cells)
 */
export function calculateMinPathLength(rows: number, cols: number): number {
  const totalCells = rows * cols
  return Math.max(4, Math.floor(totalCells * 0.6))
}

/**
 * Calculate maximum path length for a grid (roughly 85% of cells)
 */
export function calculateMaxPathLength(rows: number, cols: number): number {
  const totalCells = rows * cols
  return Math.floor(totalCells * 0.85)
}

/**
 * Get difficulty preset by level number (1-10)
 */
export function getDifficultyByLevel(level: number): DifficultySettings {
  const index = Math.max(0, Math.min(9, level - 1))
  const preset = { ...DIFFICULTY_PRESETS[index] }

  // Calculate path lengths based on grid size
  preset.minPathLength = calculateMinPathLength(preset.gridRows, preset.gridCols)
  preset.maxPathLength = calculateMaxPathLength(preset.gridRows, preset.gridCols)

  return preset
}

/**
 * Get difficulty preset by name
 */
export function getDifficultyByName(name: string): DifficultySettings | undefined {
  const preset = DIFFICULTY_PRESETS.find(p => p.name === name)
  if (!preset) return undefined

  const settings = { ...preset }
  settings.minPathLength = calculateMinPathLength(settings.gridRows, settings.gridCols)
  settings.maxPathLength = calculateMaxPathLength(settings.gridRows, settings.gridCols)

  return settings
}

/**
 * Create a custom difficulty by merging overrides with Level 5 as base
 */
export function createCustomDifficulty(overrides: Partial<DifficultySettings>): DifficultySettings {
  const base = getDifficultyByLevel(5)
  const settings: DifficultySettings = {
    ...base,
    ...overrides,
    name: overrides.name ?? 'Custom',
    weights: {
      ...base.weights,
      ...overrides.weights,
    },
  }

  // Auto-calculate weights based on enabled operations if not explicitly provided
  if (!overrides.weights) {
    const enabledOps: string[] = []
    if (settings.additionEnabled) enabledOps.push('addition')
    if (settings.subtractionEnabled) enabledOps.push('subtraction')
    if (settings.multiplicationEnabled) enabledOps.push('multiplication')
    if (settings.divisionEnabled) enabledOps.push('division')

    // Distribute weight equally among enabled operations
    const weightPerOp = enabledOps.length > 0 ? Math.floor(100 / enabledOps.length) : 0

    settings.weights = {
      addition: settings.additionEnabled ? weightPerOp : 0,
      subtraction: settings.subtractionEnabled ? weightPerOp : 0,
      multiplication: settings.multiplicationEnabled ? weightPerOp : 0,
      division: settings.divisionEnabled ? weightPerOp : 0,
    }
  }

  // Recalculate path lengths if grid size changed
  if (overrides.gridRows || overrides.gridCols) {
    settings.minPathLength = calculateMinPathLength(settings.gridRows, settings.gridCols)
    settings.maxPathLength = calculateMaxPathLength(settings.gridRows, settings.gridCols)
  }

  return settings
}

/**
 * Validation errors for difficulty settings
 */
export interface DifficultyValidationResult {
  valid: boolean
  errors: string[]
}

/**
 * Validate difficulty settings
 */
export function validateDifficultySettings(settings: DifficultySettings): DifficultyValidationResult {
  const errors: string[] = []

  // Check at least one operation is enabled
  if (!settings.additionEnabled && !settings.subtractionEnabled &&
      !settings.multiplicationEnabled && !settings.divisionEnabled) {
    errors.push('At least one operation must be enabled')
  }

  // Check ranges are positive
  if (settings.addSubRange < 1) {
    errors.push('Addition/subtraction range must be at least 1')
  }

  if ((settings.multiplicationEnabled || settings.divisionEnabled) && settings.multDivRange < 2) {
    errors.push('Multiplication/division range must be at least 2')
  }

  // Check connector range
  if (settings.connectorMin < 1) {
    errors.push('Minimum connector value must be at least 1')
  }

  if (settings.connectorMax <= settings.connectorMin) {
    errors.push('Maximum connector value must be greater than minimum')
  }

  // Check grid size
  if (settings.gridRows < 3) {
    errors.push('Grid must have at least 3 rows')
  }

  if (settings.gridCols < 4) {
    errors.push('Grid must have at least 4 columns')
  }

  // Check path lengths
  if (settings.minPathLength < 4) {
    errors.push('Minimum path length must be at least 4')
  }

  if (settings.maxPathLength < settings.minPathLength) {
    errors.push('Maximum path length must be at least equal to minimum')
  }

  // Check weights make sense if operations are enabled
  const { weights } = settings
  if (settings.additionEnabled && weights.addition <= 0) {
    errors.push('Addition weight must be positive when enabled')
  }
  if (settings.subtractionEnabled && weights.subtraction <= 0) {
    errors.push('Subtraction weight must be positive when enabled')
  }
  if (settings.multiplicationEnabled && weights.multiplication <= 0) {
    errors.push('Multiplication weight must be positive when enabled')
  }
  if (settings.divisionEnabled && weights.division <= 0) {
    errors.push('Division weight must be positive when enabled')
  }

  // Check timer
  if (settings.secondsPerStep < 1) {
    errors.push('Seconds per step must be at least 1')
  }

  return {
    valid: errors.length === 0,
    errors,
  }
}
