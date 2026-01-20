import type { DifficultySettings } from "./types";
import { calculateMinPathLength, calculateMaxPathLength } from "./difficulty";

// MARK: - Story Level Identifier

export interface StoryLevel {
  chapter: number; // 1-10
  level: number; // 1-5 (A=1, B=2, C=3, D=4, E=5)
}

/** Get level letter (A-E) */
export function getLevelLetter(level: number): string {
  return ["A", "B", "C", "D", "E"][level - 1] ?? "A";
}

/** Get display name (e.g., "3-C") */
export function getStoryLevelDisplayName(storyLevel: StoryLevel): string {
  return `${storyLevel.chapter}-${getLevelLetter(storyLevel.level)}`;
}

/** Create StoryLevel from chapter and letter */
export function createStoryLevel(
  chapter: number,
  letter: string
): StoryLevel | null {
  const index = ["A", "B", "C", "D", "E"].indexOf(letter.toUpperCase());
  if (index === -1) return null;
  return { chapter, level: index + 1 };
}

// MARK: - Chapter Configuration

type Operation = "add" | "subtract" | "multiply" | "divide";

interface ChapterConfig {
  operations: Set<Operation>;
  addSubMax: number;
  multDivMax: number;
  startGrid: { rows: number; cols: number };
  endGrid: { rows: number; cols: number };
  allHidden: boolean;
}

const CHAPTER_CONFIGS: Record<number, ChapterConfig> = {
  1: {
    operations: new Set(["add"]),
    addSubMax: 10,
    multDivMax: 0,
    startGrid: { rows: 3, cols: 4 },
    endGrid: { rows: 6, cols: 7 },
    allHidden: false,
  },
  2: {
    operations: new Set(["add", "subtract"]),
    addSubMax: 15,
    multDivMax: 0,
    startGrid: { rows: 4, cols: 5 },
    endGrid: { rows: 6, cols: 7 },
    allHidden: false,
  },
  3: {
    operations: new Set(["add", "subtract"]),
    addSubMax: 20,
    multDivMax: 0,
    startGrid: { rows: 4, cols: 5 },
    endGrid: { rows: 6, cols: 7 },
    allHidden: false,
  },
  4: {
    operations: new Set(["add", "subtract"]),
    addSubMax: 35,
    multDivMax: 0,
    startGrid: { rows: 4, cols: 5 },
    endGrid: { rows: 6, cols: 7 },
    allHidden: false,
  },
  5: {
    operations: new Set(["add", "subtract", "multiply"]),
    addSubMax: 20,
    multDivMax: 20,
    startGrid: { rows: 4, cols: 5 },
    endGrid: { rows: 6, cols: 7 },
    allHidden: false,
  },
  6: {
    operations: new Set(["add", "subtract", "multiply"]),
    addSubMax: 30,
    multDivMax: 50,
    startGrid: { rows: 4, cols: 5 },
    endGrid: { rows: 6, cols: 7 },
    allHidden: false,
  },
  7: {
    operations: new Set(["add", "subtract", "multiply"]),
    addSubMax: 40,
    multDivMax: 100,
    startGrid: { rows: 4, cols: 5 },
    endGrid: { rows: 6, cols: 7 },
    allHidden: false,
  },
  8: {
    operations: new Set(["add", "subtract", "multiply", "divide"]),
    addSubMax: 50,
    multDivMax: 100,
    startGrid: { rows: 4, cols: 5 },
    endGrid: { rows: 6, cols: 7 },
    allHidden: false,
  },
  9: {
    operations: new Set(["add", "subtract", "multiply", "divide"]),
    addSubMax: 100,
    multDivMax: 144,
    startGrid: { rows: 6, cols: 7 },
    endGrid: { rows: 6, cols: 7 },
    allHidden: false,
  },
  10: {
    operations: new Set(["add", "subtract", "multiply", "divide"]),
    addSubMax: 100,
    multDivMax: 144,
    startGrid: { rows: 8, cols: 9 },
    endGrid: { rows: 8, cols: 9 },
    allHidden: true,
  },
};

// MARK: - Grid Calculation

function calculateGrid(
  level: number,
  start: { rows: number; cols: number },
  end: { rows: number; cols: number }
): { rows: number; cols: number } {
  // Level 5 always gets end grid
  if (level === 5) {
    return end;
  }

  // If start == end (chapters 9, 10), return that size
  if (start.rows === end.rows && start.cols === end.cols) {
    return start;
  }

  // Progressive growth for levels 1-4
  const rowGrowth = end.rows - start.rows;
  const colGrowth = end.cols - start.cols;
  const totalGrowth = rowGrowth + colGrowth;

  // Distribute growth across levels 1-4
  const growthPerLevel = Math.floor(totalGrowth / 4);
  const growthForThisLevel = (level - 1) * growthPerLevel;

  // Alternate between adding rows and cols
  let rows = start.rows;
  let cols = start.cols;

  for (let i = 0; i < growthForThisLevel; i++) {
    if (i % 2 === 0 && rows < end.rows) {
      rows++;
    } else if (cols < end.cols) {
      cols++;
    } else if (rows < end.rows) {
      rows++;
    }
  }

  return { rows, cols };
}

// MARK: - Weight Calculation

function calculateWeights(operations: Set<Operation>) {
  const count = operations.size;
  if (count === 0) {
    return { addition: 100, subtraction: 0, multiplication: 0, division: 0 };
  }

  const baseWeight = Math.floor(100 / count);

  return {
    addition: operations.has("add") ? baseWeight : 0,
    subtraction: operations.has("subtract") ? baseWeight : 0,
    multiplication: operations.has("multiply") ? baseWeight : 0,
    division: operations.has("divide") ? baseWeight : 0,
  };
}

// MARK: - Generate Settings

/**
 * Generate DifficultySettings for a specific story level
 */
export function getStoryDifficulty(storyLevel: StoryLevel): DifficultySettings {
  const config = CHAPTER_CONFIGS[storyLevel.chapter];
  if (!config) {
    // Fallback to chapter 1 if invalid
    return getStoryDifficulty({ chapter: 1, level: 1 });
  }

  // Calculate grid size based on level progression
  const grid = calculateGrid(storyLevel.level, config.startGrid, config.endGrid);

  // Determine if hidden mode
  const isHidden = config.allHidden || storyLevel.level === 5;

  // Calculate operation weights
  const weights = calculateWeights(config.operations);

  // Calculate connector range based on max values
  const connectorMax = Math.max(config.addSubMax, config.multDivMax);

  // Calculate mult/div range (for operands, derive from max answer)
  // e.g., max answer 50 → operands up to ~7 (7×7=49)
  const multDivRange =
    config.multDivMax > 0 ? Math.floor(Math.sqrt(config.multDivMax)) : 0;

  const settings: DifficultySettings = {
    name: `Story ${getStoryLevelDisplayName(storyLevel)}`,
    additionEnabled: config.operations.has("add"),
    subtractionEnabled: config.operations.has("subtract"),
    multiplicationEnabled: config.operations.has("multiply"),
    divisionEnabled: config.operations.has("divide"),
    addSubRange: config.addSubMax,
    multDivRange,
    connectorMin: 5,
    connectorMax,
    gridRows: grid.rows,
    gridCols: grid.cols,
    minPathLength: calculateMinPathLength(grid.rows, grid.cols),
    maxPathLength: calculateMaxPathLength(grid.rows, grid.cols),
    weights,
    hiddenMode: isHidden,
    secondsPerStep: 5, // Used for 3-star calculation
  };

  return settings;
}

// MARK: - Star Calculation

/**
 * Calculate stars earned for a completed level
 * @param livesLost - Number of lives lost during the level
 * @param timeSeconds - Total time to complete in seconds
 * @param tileCount - Number of tiles in the puzzle
 * @returns Stars earned (1-3)
 */
export function calculateStars(
  livesLost: number,
  timeSeconds: number,
  tileCount: number
): number {
  // 1 star: Completed
  let stars = 1;

  // 2 stars: No lives lost
  if (livesLost === 0) {
    stars = 2;

    // 3 stars: Under 5 seconds per tile
    const targetTime = tileCount * 5;
    if (timeSeconds < targetTime) {
      stars = 3;
    }
  }

  return stars;
}

// MARK: - Level Progress

export interface StoryLevelProgress {
  chapter: number;
  level: number;
  completed: boolean;
  stars: number; // 0-3
  bestTimeSeconds: number | null;
  attempts: number;
}

/**
 * Create initial progress for a level
 */
export function createLevelProgress(
  chapter: number,
  level: number
): StoryLevelProgress {
  return {
    chapter,
    level,
    completed: false,
    stars: 0,
    bestTimeSeconds: null,
    attempts: 0,
  };
}

/**
 * Record an attempt and update progress
 */
export function recordAttempt(
  progress: StoryLevelProgress,
  won: boolean,
  livesLost: number,
  timeSeconds: number,
  tileCount: number
): StoryLevelProgress {
  const updated = { ...progress };
  updated.attempts++;

  if (won) {
    updated.completed = true;

    // Calculate stars for this attempt
    const earnedStars = calculateStars(livesLost, timeSeconds, tileCount);

    // Keep best stars
    updated.stars = Math.max(updated.stars, earnedStars);

    // Keep best time
    if (updated.bestTimeSeconds === null) {
      updated.bestTimeSeconds = timeSeconds;
    } else {
      updated.bestTimeSeconds = Math.min(updated.bestTimeSeconds, timeSeconds);
    }
  }

  return updated;
}
