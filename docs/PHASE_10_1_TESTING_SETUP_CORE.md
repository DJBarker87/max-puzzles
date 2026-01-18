# Phase 10.1: Testing Suite - Setup & Core Tests

**Goal:** Implement comprehensive testing with Vitest and React Testing Library. This part covers setup, puzzle engine tests, and game logic tests.

---

## Subphase 10.1: Testing Setup & Configuration

### Prompt for Claude Code:

```
Set up the testing framework with Vitest and React Testing Library.

1. Install testing dependencies:

```bash
npm install -D vitest @vitest/coverage-v8 @vitest/ui
npm install -D @testing-library/react @testing-library/jest-dom @testing-library/user-event
npm install -D jsdom msw @faker-js/faker
```

2. Create vitest.config.ts:

```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    exclude: ['node_modules', 'dist'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'src/test/', '**/*.d.ts'],
      thresholds: {
        lines: 70,
        functions: 70,
        branches: 60,
        statements: 70,
      },
    },
    testTimeout: 10000,
    reporters: ['verbose'],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

3. Create src/test/setup.ts:

```typescript
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach, beforeAll, afterAll, vi } from 'vitest';
import { server } from './mocks/server';
import * as matchers from '@testing-library/jest-dom/matchers';

expect.extend(matchers);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => { cleanup(); server.resetHandlers(); });
afterAll(() => server.close());

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query) => ({
    matches: false, media: query, onchange: null,
    addListener: vi.fn(), removeListener: vi.fn(),
    addEventListener: vi.fn(), removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

// Mock ResizeObserver
global.ResizeObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(), unobserve: vi.fn(), disconnect: vi.fn(),
}));

// Mock Audio
window.HTMLMediaElement.prototype.play = vi.fn().mockResolvedValue(undefined);
window.HTMLMediaElement.prototype.pause = vi.fn();
```

4. Create src/test/mocks/server.ts:

```typescript
import { setupServer } from 'msw/node';
import { handlers } from './handlers';
export const server = setupServer(...handlers);
```

5. Create src/test/mocks/handlers.ts:

```typescript
import { http, HttpResponse } from 'msw';

const SUPABASE_URL = 'http://localhost:54321';

export const handlers = [
  http.post(`${SUPABASE_URL}/auth/v1/token`, () => {
    return HttpResponse.json({
      access_token: 'mock-token',
      user: { id: 'mock-user-id', email: 'test@example.com' },
    });
  }),
  http.get(`${SUPABASE_URL}/rest/v1/users`, () => {
    return HttpResponse.json([
      { id: 'child-1', display_name: 'Max', role: 'child', coins: 100 },
    ]);
  }),
  http.get(`${SUPABASE_URL}/rest/v1/module_progress`, () => HttpResponse.json([])),
  http.get(`${SUPABASE_URL}/rest/v1/activity_log`, () => HttpResponse.json([])),
];
```

6. Create src/test/utils.tsx:

```typescript
import React, { ReactElement } from 'react';
import { render, RenderOptions } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';

function AllProviders({ children }: { children: React.ReactNode }) {
  return <BrowserRouter>{children}</BrowserRouter>;
}

function customRender(ui: ReactElement, options?: Omit<RenderOptions, 'wrapper'>) {
  return render(ui, { wrapper: AllProviders, ...options });
}

export * from '@testing-library/react';
export { customRender as render };
```

7. Create src/test/factories.ts:

```typescript
import { faker } from '@faker-js/faker';

export function createMockCell(overrides = {}) {
  return {
    index: 0, row: 0, col: 0,
    value: faker.number.int({ min: 1, max: 9 }),
    isStart: false, isEnd: false, isSelected: false,
    ...overrides,
  };
}

export function createMockPuzzle(overrides = {}) {
  const gridSize = 3;
  const cells = Array.from({ length: 9 }, (_, i) => 
    createMockCell({ index: i, row: Math.floor(i / 3), col: i % 3 })
  );
  cells[0].isStart = true;
  cells[8].isEnd = true;
  
  return {
    id: faker.string.uuid(),
    difficulty: 3,
    gridSize,
    cells,
    targetSum: 15,
    solution: [0, 1, 2, 5, 8],
    connectors: [],
    ...overrides,
  };
}

export function createMockChild(overrides = {}) {
  return {
    id: faker.string.uuid(),
    displayName: faker.person.firstName(),
    coins: faker.number.int({ min: 0, max: 1000 }),
    role: 'child',
    ...overrides,
  };
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
  };
}
```

8. Update package.json:

```json
{
  "scripts": {
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:run": "vitest run",
    "test:coverage": "vitest run --coverage"
  }
}
```
```

---

## Subphase 10.2: Puzzle Engine Unit Tests

### Prompt for Claude Code:

```
Create unit tests for the puzzle generation engine.

File: src/modules/circuit-challenge/engine/__tests__/puzzleGenerator.test.ts

```typescript
import { describe, it, expect } from 'vitest';
import { generatePuzzle, validatePuzzle } from '../puzzleGenerator';
import { DIFFICULTY_CONFIGS } from '../difficultyConfig';

describe('Puzzle Generator', () => {
  describe('generatePuzzle', () => {
    it('generates puzzle with correct grid size for each difficulty', () => {
      for (let difficulty = 0; difficulty <= 9; difficulty++) {
        const puzzle = generatePuzzle(difficulty);
        const expectedSize = DIFFICULTY_CONFIGS[difficulty].gridSize;
        expect(puzzle.gridSize).toBe(expectedSize);
        expect(puzzle.cells.length).toBe(expectedSize * expectedSize);
      }
    });

    it('has exactly one start and one end cell', () => {
      for (let difficulty = 0; difficulty <= 9; difficulty++) {
        const puzzle = generatePuzzle(difficulty);
        expect(puzzle.cells.filter(c => c.isStart).length).toBe(1);
        expect(puzzle.cells.filter(c => c.isEnd).length).toBe(1);
      }
    });

    it('solution starts at start cell and ends at end cell', () => {
      for (let difficulty = 0; difficulty <= 9; difficulty++) {
        const puzzle = generatePuzzle(difficulty);
        const startCell = puzzle.cells.find(c => c.isStart);
        const endCell = puzzle.cells.find(c => c.isEnd);
        expect(puzzle.solution[0]).toBe(startCell?.index);
        expect(puzzle.solution[puzzle.solution.length - 1]).toBe(endCell?.index);
      }
    });

    it('solution sums to target', () => {
      for (let difficulty = 0; difficulty <= 9; difficulty++) {
        const puzzle = generatePuzzle(difficulty);
        const solutionSum = puzzle.solution.reduce(
          (sum, idx) => sum + puzzle.cells[idx].value, 0
        );
        expect(solutionSum).toBe(puzzle.targetSum);
      }
    });

    it('solution path is connected (adjacent cells)', () => {
      const puzzle = generatePuzzle(5);
      for (let i = 0; i < puzzle.solution.length - 1; i++) {
        const curr = puzzle.solution[i];
        const next = puzzle.solution[i + 1];
        const isAdjacent = areAdjacent(curr, next, puzzle.gridSize);
        expect(isAdjacent).toBe(true);
      }
    });

    it('cell values are within configured range', () => {
      for (let difficulty = 0; difficulty <= 9; difficulty++) {
        const puzzle = generatePuzzle(difficulty);
        const config = DIFFICULTY_CONFIGS[difficulty];
        for (const cell of puzzle.cells) {
          expect(cell.value).toBeGreaterThanOrEqual(config.minValue);
          expect(cell.value).toBeLessThanOrEqual(config.maxValue);
        }
      }
    });

    it('generates unique puzzle IDs', () => {
      const ids = Array.from({ length: 10 }, () => generatePuzzle(5).id);
      expect(new Set(ids).size).toBe(10);
    });

    it('generates puzzles quickly (< 50ms average)', () => {
      const start = performance.now();
      for (let i = 0; i < 100; i++) {
        generatePuzzle(Math.floor(Math.random() * 10));
      }
      const avgTime = (performance.now() - start) / 100;
      expect(avgTime).toBeLessThan(50);
    });
  });

  describe('validatePuzzle', () => {
    it('validates correct puzzles', () => {
      for (let difficulty = 0; difficulty <= 9; difficulty++) {
        const puzzle = generatePuzzle(difficulty);
        const result = validatePuzzle(puzzle);
        expect(result.isValid).toBe(true);
        expect(result.errors).toHaveLength(0);
      }
    });

    it('rejects puzzle with no start cell', () => {
      const puzzle = generatePuzzle(3);
      puzzle.cells.forEach(c => c.isStart = false);
      const result = validatePuzzle(puzzle);
      expect(result.isValid).toBe(false);
    });

    it('rejects puzzle with disconnected solution', () => {
      const puzzle = generatePuzzle(3);
      puzzle.solution = [0, 5, 8]; // Non-adjacent
      const result = validatePuzzle(puzzle);
      expect(result.isValid).toBe(false);
    });
  });
});

function areAdjacent(i1: number, i2: number, gridSize: number): boolean {
  const r1 = Math.floor(i1 / gridSize), c1 = i1 % gridSize;
  const r2 = Math.floor(i2 / gridSize), c2 = i2 % gridSize;
  return (Math.abs(r1-r2) === 1 && c1 === c2) || (Math.abs(c1-c2) === 1 && r1 === r2);
}
```

File: src/modules/circuit-challenge/engine/__tests__/pathValidation.test.ts

```typescript
import { describe, it, expect } from 'vitest';
import { isValidPath, isPathConnected, calculatePathSum } from '../pathValidation';
import { createMockPuzzle, createMockCell } from '@/test/factories';

describe('Path Validation', () => {
  describe('isPathConnected', () => {
    it('returns true for connected horizontal path', () => {
      expect(isPathConnected([0, 1, 2], 3)).toBe(true);
    });

    it('returns true for connected vertical path', () => {
      expect(isPathConnected([0, 3, 6], 3)).toBe(true);
    });

    it('returns true for L-shaped path', () => {
      expect(isPathConnected([0, 1, 4], 3)).toBe(true);
    });

    it('returns false for disconnected path', () => {
      expect(isPathConnected([0, 2], 3)).toBe(false);
    });

    it('returns false for diagonal path', () => {
      expect(isPathConnected([0, 4, 8], 3)).toBe(false);
    });

    it('returns true for single cell', () => {
      expect(isPathConnected([0], 3)).toBe(true);
    });

    it('returns true for empty path', () => {
      expect(isPathConnected([], 3)).toBe(true);
    });
  });

  describe('calculatePathSum', () => {
    it('calculates sum correctly', () => {
      const puzzle = createMockPuzzle();
      puzzle.cells[0].value = 1;
      puzzle.cells[1].value = 2;
      puzzle.cells[2].value = 3;
      expect(calculatePathSum(puzzle, [0, 1, 2])).toBe(6);
    });

    it('returns 0 for empty path', () => {
      const puzzle = createMockPuzzle();
      expect(calculatePathSum(puzzle, [])).toBe(0);
    });
  });

  describe('isValidPath', () => {
    it('returns valid and win for correct solution', () => {
      const puzzle = createMockPuzzle({ targetSum: 15 });
      puzzle.cells[0] = createMockCell({ index: 0, value: 5, isStart: true });
      puzzle.cells[1] = createMockCell({ index: 1, value: 5 });
      puzzle.cells[2] = createMockCell({ index: 2, value: 5, isEnd: true });
      
      const result = isValidPath(puzzle, [0, 1, 2]);
      expect(result.isValid).toBe(true);
      expect(result.isWin).toBe(true);
    });

    it('returns invalid for path not starting at start cell', () => {
      const puzzle = createMockPuzzle();
      const result = isValidPath(puzzle, [1, 2]);
      expect(result.isValid).toBe(false);
    });

    it('returns invalid for disconnected path', () => {
      const puzzle = createMockPuzzle();
      const result = isValidPath(puzzle, [0, 5, 8]);
      expect(result.isValid).toBe(false);
    });
  });
});
```
```

---

## Subphase 10.3: Game Hook Tests

### Prompt for Claude Code:

```
Create tests for the useGame hook.

File: src/modules/circuit-challenge/hooks/__tests__/useGame.test.ts

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { renderHook, act, waitFor } from '@testing-library/react';
import { useGame } from '../useGame';
import { createMockPuzzle } from '@/test/factories';

vi.mock('../../engine/puzzleGenerator', () => ({
  generatePuzzle: vi.fn(() => createMockPuzzle({
    gridSize: 3,
    targetSum: 15,
    solution: [0, 1, 2, 5, 8],
  })),
}));

vi.mock('@/app/providers/SoundProvider', () => ({
  useSound: () => ({
    playSelect: vi.fn(),
    playSuccess: vi.fn(),
    playError: vi.fn(),
  }),
}));

vi.mock('@/app/providers/StorageProvider', () => ({
  useStorage: () => ({
    saveProgress: vi.fn(),
    recordQuickPlayResult: vi.fn(),
    addCoins: vi.fn(),
  }),
}));

describe('useGame Hook', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => { vi.useRealTimers(); vi.clearAllMocks(); });

  describe('Initialization', () => {
    it('initializes with idle status', () => {
      const { result } = renderHook(() => useGame());
      expect(result.current.gameState.status).toBe('idle');
      expect(result.current.gameState.puzzle).toBeNull();
    });

    it('starts game with correct initial state', () => {
      const { result } = renderHook(() => useGame());
      act(() => result.current.startGame(3));
      
      expect(result.current.gameState.status).toBe('playing');
      expect(result.current.gameState.puzzle).not.toBeNull();
      expect(result.current.gameState.selectedPath).toEqual([]);
      expect(result.current.gameState.currentSum).toBe(0);
      expect(result.current.gameState.mistakes).toBe(0);
    });
  });

  describe('Cell Selection', () => {
    it('selects start cell correctly', () => {
      const { result } = renderHook(() => useGame());
      act(() => result.current.startGame(3));
      act(() => result.current.selectCell(0));
      
      expect(result.current.gameState.selectedPath).toEqual([0]);
      expect(result.current.gameState.currentSum).toBeGreaterThan(0);
    });

    it('rejects non-start cell as first selection', () => {
      const { result } = renderHook(() => useGame());
      act(() => result.current.startGame(3));
      act(() => result.current.selectCell(5));
      
      expect(result.current.gameState.selectedPath).toEqual([]);
    });

    it('extends path with adjacent cell', () => {
      const { result } = renderHook(() => useGame());
      act(() => result.current.startGame(3));
      act(() => result.current.selectCell(0));
      act(() => result.current.selectCell(1));
      
      expect(result.current.gameState.selectedPath).toEqual([0, 1]);
    });

    it('rejects non-adjacent cell', () => {
      const { result } = renderHook(() => useGame());
      act(() => result.current.startGame(3));
      act(() => result.current.selectCell(0));
      act(() => result.current.selectCell(5));
      
      expect(result.current.gameState.selectedPath).toEqual([0]);
    });

    it('allows deselecting last cell', () => {
      const { result } = renderHook(() => useGame());
      act(() => result.current.startGame(3));
      act(() => { result.current.selectCell(0); result.current.selectCell(1); });
      act(() => result.current.selectCell(1));
      
      expect(result.current.gameState.selectedPath).toEqual([0]);
    });
  });

  describe('Game Controls', () => {
    it('resets path correctly', () => {
      const { result } = renderHook(() => useGame());
      act(() => result.current.startGame(3));
      act(() => { result.current.selectCell(0); result.current.selectCell(1); });
      act(() => result.current.resetPath());
      
      expect(result.current.gameState.selectedPath).toEqual([]);
      expect(result.current.gameState.currentSum).toBe(0);
    });

    it('quits game and returns to idle', () => {
      const { result } = renderHook(() => useGame());
      act(() => result.current.startGame(3));
      act(() => result.current.quitGame());
      
      expect(result.current.gameState.status).toBe('idle');
    });
  });

  describe('Timer', () => {
    it('tracks elapsed time while playing', () => {
      const { result } = renderHook(() => useGame());
      act(() => result.current.startGame(3));
      
      expect(result.current.gameState.elapsedTime).toBe(0);
      
      act(() => vi.advanceTimersByTime(5000));
      
      expect(result.current.gameState.elapsedTime).toBeGreaterThanOrEqual(5000);
    });

    it('stops timer when game ends', () => {
      const { result } = renderHook(() => useGame());
      act(() => result.current.startGame(3));
      act(() => vi.advanceTimersByTime(5000));
      act(() => result.current.quitGame());
      
      const timeAtEnd = result.current.gameState.elapsedTime;
      act(() => vi.advanceTimersByTime(5000));
      
      expect(result.current.gameState.elapsedTime).toBe(timeAtEnd);
    });
  });
});
```

File: src/modules/circuit-challenge/hooks/__tests__/useGameTimer.test.ts

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useGameTimer } from '../useGameTimer';

describe('useGameTimer Hook', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('starts at 0', () => {
    const { result } = renderHook(() => useGameTimer(true));
    expect(result.current.elapsed).toBe(0);
  });

  it('increments when running', () => {
    const { result } = renderHook(() => useGameTimer(true));
    act(() => vi.advanceTimersByTime(1000));
    expect(result.current.elapsed).toBe(1000);
  });

  it('does not increment when paused', () => {
    const { result } = renderHook(() => useGameTimer(false));
    act(() => vi.advanceTimersByTime(5000));
    expect(result.current.elapsed).toBe(0);
  });

  it('resets correctly', () => {
    const { result } = renderHook(() => useGameTimer(true));
    act(() => vi.advanceTimersByTime(5000));
    act(() => result.current.reset());
    expect(result.current.elapsed).toBe(0);
  });

  it('formats time correctly', () => {
    const { result } = renderHook(() => useGameTimer(true));
    expect(result.current.formatted).toBe('0:00');
    
    act(() => vi.advanceTimersByTime(65000));
    expect(result.current.formatted).toBe('1:05');
  });
});
```
```

---

## Files Created in Phase 10.1

```
src/test/
├── setup.ts
├── utils.tsx
├── factories.ts
└── mocks/
    ├── server.ts
    └── handlers.ts

src/modules/circuit-challenge/engine/__tests__/
├── puzzleGenerator.test.ts
├── difficultyConfig.test.ts
└── pathValidation.test.ts

src/modules/circuit-challenge/hooks/__tests__/
├── useGame.test.ts
└── useGameTimer.test.ts

vitest.config.ts
```

---

*End of Phase 10.1 - Continue to Phase 10.2 for UI and Integration Tests*
