import { calculateStars } from "@/modules/circuit-challenge/engine/storyDifficulty";

const STORAGE_KEY = "storyProgressV2";

// MARK: - Data Types

export interface LevelProgressData {
  completed: boolean;
  stars: number; // 0-3
  bestTimeSeconds: number | null;
  attempts: number;
}

export interface StoryProgressData {
  levelProgress: Record<string, LevelProgressData>; // Key: "chapter-level" e.g., "3-2"
}

function levelKey(chapter: number, level: number): string {
  return `${chapter}-${level}`;
}

// MARK: - Load/Save

export function getStoryProgress(): StoryProgressData {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      return JSON.parse(stored);
    }
  } catch {
    // Ignore parse errors
  }
  return { levelProgress: {} };
}

export function saveStoryProgress(data: StoryProgressData): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
}

// MARK: - Chapter Progress

/**
 * Get highest unlocked chapter (1 = only Bob, 10 = all unlocked)
 */
export function getHighestUnlockedChapter(progress: StoryProgressData): number {
  let maxCompleted = 0;
  for (let chapter = 1; chapter <= 10; chapter++) {
    if (isChapterCompleted(chapter, progress)) {
      maxCompleted = chapter;
    }
  }
  return Math.min(maxCompleted + 1, 10);
}

/**
 * Check if a chapter is unlocked
 */
export function isChapterUnlocked(
  chapter: number,
  progress: StoryProgressData
): boolean {
  return chapter <= getHighestUnlockedChapter(progress);
}

/**
 * Check if all 5 levels of a chapter are completed
 */
export function isChapterCompleted(
  chapter: number,
  progress: StoryProgressData
): boolean {
  for (let level = 1; level <= 5; level++) {
    if (!isLevelCompleted(chapter, level, progress)) {
      return false;
    }
  }
  return true;
}

/**
 * Get total stars earned in a chapter (0-15)
 */
export function getStarsInChapter(
  chapter: number,
  progress: StoryProgressData
): number {
  let total = 0;
  for (let level = 1; level <= 5; level++) {
    total += getStarsForLevel(chapter, level, progress);
  }
  return total;
}

/**
 * Get total stars earned overall (0-150)
 */
export function getTotalStars(progress: StoryProgressData): number {
  let total = 0;
  for (let chapter = 1; chapter <= 10; chapter++) {
    total += getStarsInChapter(chapter, progress);
  }
  return total;
}

// MARK: - Level Progress

/**
 * Check if a specific level is unlocked
 */
export function isLevelUnlocked(
  chapter: number,
  level: number,
  progress: StoryProgressData
): boolean {
  // Chapter must be unlocked
  if (!isChapterUnlocked(chapter, progress)) {
    return false;
  }

  // Level 1 (A) is always unlocked if chapter is unlocked
  if (level === 1) {
    return true;
  }

  // Otherwise, previous level must be completed
  return isLevelCompleted(chapter, level - 1, progress);
}

/**
 * Check if a specific level is completed
 */
export function isLevelCompleted(
  chapter: number,
  level: number,
  progress: StoryProgressData
): boolean {
  const key = levelKey(chapter, level);
  return progress.levelProgress[key]?.completed ?? false;
}

/**
 * Get stars for a specific level (0-3)
 */
export function getStarsForLevel(
  chapter: number,
  level: number,
  progress: StoryProgressData
): number {
  const key = levelKey(chapter, level);
  return progress.levelProgress[key]?.stars ?? 0;
}

/**
 * Get best time for a level (null if never completed)
 */
export function getBestTimeForLevel(
  chapter: number,
  level: number,
  progress: StoryProgressData
): number | null {
  const key = levelKey(chapter, level);
  return progress.levelProgress[key]?.bestTimeSeconds ?? null;
}

/**
 * Get attempt count for a level
 */
export function getAttemptsForLevel(
  chapter: number,
  level: number,
  progress: StoryProgressData
): number {
  const key = levelKey(chapter, level);
  return progress.levelProgress[key]?.attempts ?? 0;
}

// MARK: - Record Progress

/**
 * Record a level attempt and save to storage
 */
export function recordLevelAttempt(
  chapter: number,
  level: number,
  won: boolean,
  livesLost: number,
  timeSeconds: number,
  tileCount: number
): StoryProgressData {
  const progress = getStoryProgress();
  const key = levelKey(chapter, level);

  const levelData: LevelProgressData = progress.levelProgress[key] ?? {
    completed: false,
    stars: 0,
    bestTimeSeconds: null,
    attempts: 0,
  };

  levelData.attempts++;

  if (won) {
    levelData.completed = true;

    // Calculate stars for this attempt
    const earnedStars = calculateStars(livesLost, timeSeconds, tileCount);

    // Keep best stars
    levelData.stars = Math.max(levelData.stars, earnedStars);

    // Keep best time
    if (levelData.bestTimeSeconds === null) {
      levelData.bestTimeSeconds = timeSeconds;
    } else {
      levelData.bestTimeSeconds = Math.min(
        levelData.bestTimeSeconds,
        timeSeconds
      );
    }
  }

  progress.levelProgress[key] = levelData;
  saveStoryProgress(progress);

  return progress;
}

// MARK: - Reset

/**
 * Reset all progress
 */
export function resetAllProgress(): void {
  saveStoryProgress({ levelProgress: {} });
}

/**
 * Reset progress for a specific chapter
 */
export function resetChapterProgress(chapter: number): void {
  const progress = getStoryProgress();
  for (let level = 1; level <= 5; level++) {
    const key = levelKey(chapter, level);
    delete progress.levelProgress[key];
  }
  saveStoryProgress(progress);
}
