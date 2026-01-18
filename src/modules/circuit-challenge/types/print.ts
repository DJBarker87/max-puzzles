/**
 * Print output configuration.
 */
export interface PrintConfig {
  // Page layout
  pageSize: 'A4' | 'Letter'
  orientation: 'portrait' | 'landscape'
  puzzlesPerPage: 1 | 2

  // Puzzle settings
  difficulty: number // 0-9 (index into DIFFICULTY_PRESETS)
  showAnswers: boolean
  showDifficulty: boolean
  showPuzzleNumber: boolean

  // Styling
  cellSize: number // mm
  lineWidth: number // mm
  fontSize: number // pt

  // Header/Footer
  title: string
  subtitle: string
  showDate: boolean
  showPageNumbers: boolean

  // Batch settings
  puzzleCount: number
  uniquePuzzles: boolean // Generate unique puzzles or repeat
}

/**
 * Default print configuration.
 */
export const DEFAULT_PRINT_CONFIG: PrintConfig = {
  pageSize: 'A4',
  orientation: 'portrait',
  puzzlesPerPage: 2,

  difficulty: 3,
  showAnswers: false,
  showDifficulty: true,
  showPuzzleNumber: true,

  cellSize: 12,
  lineWidth: 0.5,
  fontSize: 10,

  title: 'Circuit Challenge',
  subtitle: '',
  showDate: true,
  showPageNumbers: true,

  puzzleCount: 10,
  uniquePuzzles: true,
}

/**
 * A puzzle prepared for printing.
 */
export interface PrintablePuzzle {
  id: string
  puzzleNumber: number
  difficulty: number
  difficultyName: string

  // Grid data
  gridRows: number
  gridCols: number
  cells: PrintableCell[]

  // Connectors between cells
  connectors: PrintableConnector[]

  // Solution
  targetSum: number
  solution: number[] // Cell indices in solution path
}

/**
 * Cell data for print rendering.
 */
export interface PrintableCell {
  index: number
  row: number
  col: number
  expression: string
  answer: number | null
  isStart: boolean
  isEnd: boolean
  inSolution: boolean
}

/**
 * Connector data for print rendering.
 */
export interface PrintableConnector {
  fromRow: number
  fromCol: number
  toRow: number
  toCol: number
  value: number
  inSolution: boolean
}

/**
 * Page layout measurements (in mm).
 */
export interface PageLayout {
  width: number
  height: number
  marginTop: number
  marginBottom: number
  marginLeft: number
  marginRight: number
  contentWidth: number
  contentHeight: number
  puzzleAreaHeight: number
  gapBetweenPuzzles: number
}

/**
 * A4 page layout (portrait).
 */
export const A4_PORTRAIT: PageLayout = {
  width: 210,
  height: 297,
  marginTop: 15,
  marginBottom: 15,
  marginLeft: 15,
  marginRight: 15,
  contentWidth: 180,
  contentHeight: 267,
  puzzleAreaHeight: 125, // For 2 puzzles per page
  gapBetweenPuzzles: 10,
}

/**
 * Letter page layout (portrait).
 */
export const LETTER_PORTRAIT: PageLayout = {
  width: 216,
  height: 279,
  marginTop: 15,
  marginBottom: 15,
  marginLeft: 15,
  marginRight: 15,
  contentWidth: 186,
  contentHeight: 249,
  puzzleAreaHeight: 115,
  gapBetweenPuzzles: 10,
}

/**
 * Difficulty level names for display.
 */
export const DIFFICULTY_NAMES: Record<number, string> = {
  0: 'Tiny Tot',
  1: 'Beginner',
  2: 'Easy',
  3: 'Getting There',
  4: 'Times Tables',
  5: 'Confident',
  6: 'Adventurous',
  7: 'Division Intro',
  8: 'Challenge',
  9: 'Expert',
}
