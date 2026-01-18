# Phase 10.2: Testing Suite - UI, Integration & E2E

**Goal:** Complete the testing suite with UI component tests, integration tests for user flows, print/PDF tests, and accessibility tests.

---

## Subphase 10.4: UI Component Tests

### Prompt for Claude Code:

```
Create tests for UI components.

File: src/ui/__tests__/Button.test.tsx

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { Button } from '../Button';

describe('Button Component', () => {
  it('renders with text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('calls onClick when clicked', async () => {
    const user = userEvent.setup();
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    
    await user.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('does not call onClick when disabled', async () => {
    const user = userEvent.setup();
    const handleClick = vi.fn();
    render(<Button onClick={handleClick} disabled>Click me</Button>);
    
    await user.click(screen.getByRole('button'));
    expect(handleClick).not.toHaveBeenCalled();
  });

  it('shows loading state', () => {
    render(<Button loading>Submit</Button>);
    expect(screen.getByRole('button')).toHaveAttribute('disabled');
  });

  it('applies variant classes', () => {
    const { rerender } = render(<Button variant="primary">Primary</Button>);
    expect(screen.getByRole('button')).toHaveClass('bg-accent-primary');

    rerender(<Button variant="secondary">Secondary</Button>);
    expect(screen.getByRole('button')).toHaveClass('bg-accent-secondary');

    rerender(<Button variant="ghost">Ghost</Button>);
    expect(screen.getByRole('button')).toHaveClass('bg-transparent');
  });

  it('applies size classes', () => {
    const { rerender } = render(<Button size="sm">Small</Button>);
    expect(screen.getByRole('button')).toHaveClass('py-2');

    rerender(<Button size="lg">Large</Button>);
    expect(screen.getByRole('button')).toHaveClass('py-4');
  });

  it('spans full width when fullWidth is true', () => {
    render(<Button fullWidth>Full Width</Button>);
    expect(screen.getByRole('button')).toHaveClass('w-full');
  });
});
```

File: src/ui/__tests__/Modal.test.tsx

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { Modal } from '../Modal';

describe('Modal Component', () => {
  it('renders when open', () => {
    render(
      <Modal isOpen={true} onClose={() => {}} title="Test Modal">
        Modal content
      </Modal>
    );
    expect(screen.getByText('Test Modal')).toBeInTheDocument();
    expect(screen.getByText('Modal content')).toBeInTheDocument();
  });

  it('does not render when closed', () => {
    render(
      <Modal isOpen={false} onClose={() => {}} title="Test Modal">
        Modal content
      </Modal>
    );
    expect(screen.queryByText('Test Modal')).not.toBeInTheDocument();
  });

  it('calls onClose when backdrop clicked', async () => {
    const user = userEvent.setup();
    const handleClose = vi.fn();
    render(
      <Modal isOpen={true} onClose={handleClose} title="Test">Content</Modal>
    );
    
    await user.click(screen.getByTestId('modal-backdrop'));
    expect(handleClose).toHaveBeenCalled();
  });

  it('calls onClose when close button clicked', async () => {
    const user = userEvent.setup();
    const handleClose = vi.fn();
    render(
      <Modal isOpen={true} onClose={handleClose} title="Test">Content</Modal>
    );
    
    await user.click(screen.getByLabelText(/close/i));
    expect(handleClose).toHaveBeenCalled();
  });

  it('calls onClose on Escape key', async () => {
    const user = userEvent.setup();
    const handleClose = vi.fn();
    render(
      <Modal isOpen={true} onClose={handleClose} title="Test">Content</Modal>
    );
    
    await user.keyboard('{Escape}');
    expect(handleClose).toHaveBeenCalled();
  });

  it('has role dialog', () => {
    render(
      <Modal isOpen={true} onClose={() => {}} title="Test">Content</Modal>
    );
    expect(screen.getByRole('dialog')).toBeInTheDocument();
  });
});
```

File: src/modules/circuit-challenge/components/__tests__/HexCell.test.tsx

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { HexCell } from '../HexCell';

describe('HexCell Component', () => {
  const defaultProps = {
    index: 0,
    value: 5,
    isStart: false,
    isEnd: false,
    isSelected: false,
    onClick: vi.fn(),
  };

  it('renders the cell value', () => {
    render(<HexCell {...defaultProps} />);
    expect(screen.getByText('5')).toBeInTheDocument();
  });

  it('shows START label for start cell', () => {
    render(<HexCell {...defaultProps} isStart={true} />);
    expect(screen.getByText(/start/i)).toBeInTheDocument();
  });

  it('shows END label for end cell', () => {
    render(<HexCell {...defaultProps} isEnd={true} />);
    expect(screen.getByText(/end/i)).toBeInTheDocument();
  });

  it('applies selected styles when selected', () => {
    const { container } = render(<HexCell {...defaultProps} isSelected={true} />);
    expect(container.firstChild).toHaveClass('selected');
  });

  it('calls onClick with index when clicked', async () => {
    const user = userEvent.setup();
    const handleClick = vi.fn();
    render(<HexCell {...defaultProps} onClick={handleClick} />);
    
    await user.click(screen.getByText('5'));
    expect(handleClick).toHaveBeenCalledWith(0);
  });

  it('has accessible button role', () => {
    render(<HexCell {...defaultProps} />);
    expect(screen.getByRole('button')).toBeInTheDocument();
  });

  it('indicates selected state via aria-pressed', () => {
    render(<HexCell {...defaultProps} isSelected={true} />);
    expect(screen.getByRole('button')).toHaveAttribute('aria-pressed', 'true');
  });
});
```

File: src/modules/circuit-challenge/components/__tests__/CoinDisplay.test.tsx

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, waitFor } from '@/test/utils';
import { CoinDisplay } from '../CoinDisplay';

describe('CoinDisplay Component', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('displays the coin count', () => {
    render(<CoinDisplay count={100} />);
    expect(screen.getByText('100')).toBeInTheDocument();
  });

  it('formats large numbers with commas', () => {
    render(<CoinDisplay count={1234567} />);
    expect(screen.getByText('1,234,567')).toBeInTheDocument();
  });

  it('shows coin icon', () => {
    render(<CoinDisplay count={50} />);
    expect(screen.getByText('🪙')).toBeInTheDocument();
  });

  it('shows +amount on increase', async () => {
    const { rerender } = render(<CoinDisplay count={100} />);
    rerender(<CoinDisplay count={125} />);
    
    await waitFor(() => {
      expect(screen.getByText('+25')).toBeInTheDocument();
    });
  });
});
```
```

---

## Subphase 10.5: Integration Tests

### Prompt for Claude Code:

```
Create integration tests for complete user flows.

File: src/test/integration/gameplay.test.tsx

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { GameScreen } from '@/modules/circuit-challenge/screens/GameScreen';
import { MemoryRouter, Route, Routes } from 'react-router-dom';

function renderGameScreen() {
  return render(
    <MemoryRouter initialEntries={['/circuit-challenge/play?difficulty=3']}>
      <Routes>
        <Route path="/circuit-challenge/play" element={<GameScreen />} />
        <Route path="/hub" element={<div>Hub Screen</div>} />
      </Routes>
    </MemoryRouter>
  );
}

describe('Gameplay Integration', () => {
  beforeEach(() => vi.useFakeTimers({ shouldAdvanceTime: true }));

  it('loads and displays a puzzle', async () => {
    renderGameScreen();
    
    await waitFor(() => {
      expect(screen.getByText(/target/i)).toBeInTheDocument();
    });
    
    const cells = screen.getAllByRole('button');
    expect(cells.length).toBeGreaterThan(0);
  });

  it('allows selecting cells to build a path', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    renderGameScreen();
    
    await waitFor(() => {
      expect(screen.getByText(/target/i)).toBeInTheDocument();
    });
    
    const startCell = screen.getByLabelText(/start/i);
    await user.click(startCell);
    
    expect(screen.getByTestId('current-sum')).not.toHaveTextContent('0');
  });

  it('shows quit confirmation when quit clicked', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    renderGameScreen();
    
    await waitFor(() => {
      expect(screen.getByText(/target/i)).toBeInTheDocument();
    });
    
    await user.click(screen.getByRole('button', { name: /quit/i }));
    expect(screen.getByText(/are you sure/i)).toBeInTheDocument();
  });

  it('resets path when reset clicked', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    renderGameScreen();
    
    await waitFor(() => {
      expect(screen.getByText(/target/i)).toBeInTheDocument();
    });
    
    const startCell = screen.getByLabelText(/start/i);
    await user.click(startCell);
    await user.click(screen.getByRole('button', { name: /reset/i }));
    
    expect(screen.getByTestId('current-sum')).toHaveTextContent('0');
  });

  it('timer counts up during gameplay', async () => {
    renderGameScreen();
    
    await waitFor(() => {
      expect(screen.getByText(/target/i)).toBeInTheDocument();
    });
    
    const timer = screen.getByTestId('game-timer');
    const initialTime = timer.textContent;
    
    vi.advanceTimersByTime(5000);
    
    await waitFor(() => {
      expect(timer.textContent).not.toBe(initialTime);
    });
  });
});
```

File: src/test/integration/authentication.test.tsx

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { LoginScreen } from '@/hub/screens/LoginScreen';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { server } from '../mocks/server';
import { http, HttpResponse } from 'msw';

function renderLoginScreen() {
  return render(
    <MemoryRouter initialEntries={['/login']}>
      <Routes>
        <Route path="/login" element={<LoginScreen />} />
        <Route path="/family-select" element={<div>Family Select</div>} />
        <Route path="/hub" element={<div>Hub</div>} />
      </Routes>
    </MemoryRouter>
  );
}

describe('Authentication Integration', () => {
  describe('Guest Mode', () => {
    it('allows playing as guest', async () => {
      const user = userEvent.setup();
      renderLoginScreen();
      
      await user.click(screen.getByRole('button', { name: /play as guest/i }));
      
      await waitFor(() => {
        expect(screen.getByText(/hub/i)).toBeInTheDocument();
      });
    });
  });

  describe('Login', () => {
    it('shows login form', () => {
      renderLoginScreen();
      expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
    });

    it('shows error on failed login', async () => {
      server.use(
        http.post('*/auth/v1/token', () => {
          return HttpResponse.json({ error: 'Invalid' }, { status: 401 });
        })
      );
      
      const user = userEvent.setup();
      renderLoginScreen();
      
      await user.type(screen.getByLabelText(/email/i), 'test@example.com');
      await user.type(screen.getByLabelText(/password/i), 'wrong');
      await user.click(screen.getByRole('button', { name: /log in/i }));
      
      await waitFor(() => {
        expect(screen.getByText(/invalid/i)).toBeInTheDocument();
      });
    });

    it('navigates on successful login', async () => {
      const user = userEvent.setup();
      renderLoginScreen();
      
      await user.type(screen.getByLabelText(/email/i), 'test@example.com');
      await user.type(screen.getByLabelText(/password/i), 'correct');
      await user.click(screen.getByRole('button', { name: /log in/i }));
      
      await waitFor(() => {
        expect(screen.getByText(/family select/i)).toBeInTheDocument();
      });
    });
  });

  describe('Signup', () => {
    it('validates passwords match', async () => {
      const user = userEvent.setup();
      renderLoginScreen();
      
      await user.click(screen.getByText(/create account/i));
      await user.type(screen.getByLabelText(/^email/i), 'new@example.com');
      await user.type(screen.getByLabelText(/^password/i), 'password123');
      await user.type(screen.getByLabelText(/confirm/i), 'different');
      await user.click(screen.getByRole('button', { name: /sign up/i }));
      
      expect(screen.getByText(/match/i)).toBeInTheDocument();
    });
  });
});
```

File: src/test/integration/parentDashboard.test.tsx

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { ParentDashboard } from '@/hub/screens/ParentDashboard';
import { MemoryRouter, Route, Routes } from 'react-router-dom';

vi.mock('@/app/providers/AuthProvider', () => ({
  useAuth: () => ({
    user: { id: 'parent-1', email: 'parent@example.com' },
    family: { id: 'family-1', name: 'Test Family' },
    children: [
      { id: 'child-1', displayName: 'Max', coins: 500 },
      { id: 'child-2', displayName: 'Emma', coins: 300 },
    ],
  }),
}));

function renderDashboard() {
  return render(
    <MemoryRouter initialEntries={['/parent/dashboard']}>
      <Routes>
        <Route path="/parent/dashboard" element={<ParentDashboard />} />
        <Route path="/parent/child/:childId" element={<div>Child Detail</div>} />
        <Route path="/parent/add-child" element={<div>Add Child</div>} />
      </Routes>
    </MemoryRouter>
  );
}

describe('Parent Dashboard Integration', () => {
  it('displays family name', async () => {
    renderDashboard();
    await waitFor(() => {
      expect(screen.getByText('Test Family')).toBeInTheDocument();
    });
  });

  it('displays all children', async () => {
    renderDashboard();
    await waitFor(() => {
      expect(screen.getByText('Max')).toBeInTheDocument();
      expect(screen.getByText('Emma')).toBeInTheDocument();
    });
  });

  it('shows child coins', async () => {
    renderDashboard();
    await waitFor(() => {
      expect(screen.getByText('500')).toBeInTheDocument();
      expect(screen.getByText('300')).toBeInTheDocument();
    });
  });

  it('navigates to child detail on card click', async () => {
    const user = userEvent.setup();
    renderDashboard();
    
    await waitFor(() => expect(screen.getByText('Max')).toBeInTheDocument());
    
    const maxCard = screen.getByText('Max').closest('[role="button"]');
    await user.click(maxCard!);
    
    await waitFor(() => {
      expect(screen.getByText('Child Detail')).toBeInTheDocument();
    });
  });

  it('navigates to add child on button click', async () => {
    const user = userEvent.setup();
    renderDashboard();
    
    await user.click(screen.getByRole('button', { name: /add child/i }));
    
    await waitFor(() => {
      expect(screen.getByText('Add Child')).toBeInTheDocument();
    });
  });
});
```
```

---

## Subphase 10.6: Print/PDF Tests

### Prompt for Claude Code:

```
Create tests for print and PDF generation.

File: src/modules/circuit-challenge/services/__tests__/printGenerator.test.ts

```typescript
import { describe, it, expect } from 'vitest';
import { generatePrintablePuzzles, validatePrintConfig } from '../printGenerator';
import { DEFAULT_PRINT_CONFIG } from '../../types/print';

describe('Print Generator', () => {
  describe('generatePrintablePuzzles', () => {
    it('generates correct number of puzzles', () => {
      const config = { ...DEFAULT_PRINT_CONFIG, puzzleCount: 5 };
      const puzzles = generatePrintablePuzzles(config);
      expect(puzzles).toHaveLength(5);
    });

    it('assigns sequential puzzle numbers', () => {
      const config = { ...DEFAULT_PRINT_CONFIG, puzzleCount: 3 };
      const puzzles = generatePrintablePuzzles(config);
      expect(puzzles.map(p => p.puzzleNumber)).toEqual([1, 2, 3]);
    });

    it('uses correct difficulty', () => {
      const config = { ...DEFAULT_PRINT_CONFIG, difficulty: 7, puzzleCount: 3 };
      const puzzles = generatePrintablePuzzles(config);
      puzzles.forEach(p => expect(p.difficulty).toBe(7));
    });

    it('includes difficulty name', () => {
      const config = { ...DEFAULT_PRINT_CONFIG, difficulty: 5 };
      const puzzles = generatePrintablePuzzles(config);
      expect(puzzles[0].difficultyName).toBe('Challenging');
    });

    it('has exactly one start and one end cell', () => {
      const puzzles = generatePrintablePuzzles({ ...DEFAULT_PRINT_CONFIG, puzzleCount: 1 });
      const puzzle = puzzles[0];
      expect(puzzle.cells.filter(c => c.isStart)).toHaveLength(1);
      expect(puzzle.cells.filter(c => c.isEnd)).toHaveLength(1);
    });

    it('generates connector data', () => {
      const puzzles = generatePrintablePuzzles({ ...DEFAULT_PRINT_CONFIG, puzzleCount: 1 });
      expect(puzzles[0].connectors.length).toBeGreaterThan(0);
    });

    it('marks solution cells correctly', () => {
      const puzzles = generatePrintablePuzzles({ ...DEFAULT_PRINT_CONFIG, puzzleCount: 1 });
      const puzzle = puzzles[0];
      const solutionSet = new Set(puzzle.solution);
      
      puzzle.cells.forEach(cell => {
        expect(cell.inSolution).toBe(solutionSet.has(cell.index));
      });
    });
  });

  describe('validatePrintConfig', () => {
    it('accepts valid config', () => {
      expect(validatePrintConfig(DEFAULT_PRINT_CONFIG)).toHaveLength(0);
    });

    it('rejects invalid difficulty', () => {
      const errors = validatePrintConfig({ difficulty: 15 });
      expect(errors).toContain('Difficulty must be between 0 and 9');
    });

    it('rejects invalid puzzle count', () => {
      expect(validatePrintConfig({ puzzleCount: -5 })).toContain('Puzzle count must be between 1 and 100');
      expect(validatePrintConfig({ puzzleCount: 500 })).toContain('Puzzle count must be between 1 and 100');
    });

    it('rejects invalid cell size', () => {
      expect(validatePrintConfig({ cellSize: 5 })).toContain('Cell size must be between 8mm and 20mm');
    });
  });
});
```

File: src/modules/circuit-challenge/services/__tests__/svgRenderer.test.ts

```typescript
import { describe, it, expect } from 'vitest';
import { renderPuzzleSVG, renderPageSVG, renderAllPages } from '../svgRenderer';
import { generatePrintablePuzzles } from '../printGenerator';
import { DEFAULT_PRINT_CONFIG } from '../../types/print';

describe('SVG Renderer', () => {
  describe('renderPuzzleSVG', () => {
    it('generates valid SVG', () => {
      const puzzles = generatePrintablePuzzles({ ...DEFAULT_PRINT_CONFIG, puzzleCount: 1 });
      const svg = renderPuzzleSVG(puzzles[0], DEFAULT_PRINT_CONFIG);
      expect(svg).toContain('<svg');
      expect(svg).toContain('</svg>');
    });

    it('includes target sum', () => {
      const puzzles = generatePrintablePuzzles({ ...DEFAULT_PRINT_CONFIG, puzzleCount: 1 });
      const svg = renderPuzzleSVG(puzzles[0], DEFAULT_PRINT_CONFIG);
      expect(svg).toContain(`Target: ${puzzles[0].targetSum}`);
    });

    it('includes puzzle number when enabled', () => {
      const config = { ...DEFAULT_PRINT_CONFIG, showPuzzleNumber: true };
      const puzzles = generatePrintablePuzzles({ ...config, puzzleCount: 1 });
      const svg = renderPuzzleSVG(puzzles[0], config);
      expect(svg).toContain('Puzzle 1');
    });

    it('highlights solution when showSolution true', () => {
      const puzzles = generatePrintablePuzzles({ ...DEFAULT_PRINT_CONFIG, puzzleCount: 1 });
      const withSolution = renderPuzzleSVG(puzzles[0], DEFAULT_PRINT_CONFIG, true);
      const withoutSolution = renderPuzzleSVG(puzzles[0], DEFAULT_PRINT_CONFIG, false);
      
      expect(withSolution).toContain('connector-solution');
      expect(withoutSolution).not.toContain('connector-solution');
    });

    it('includes START and END labels', () => {
      const puzzles = generatePrintablePuzzles({ ...DEFAULT_PRINT_CONFIG, puzzleCount: 1 });
      const svg = renderPuzzleSVG(puzzles[0], DEFAULT_PRINT_CONFIG);
      expect(svg).toContain('START');
      expect(svg).toContain('END');
    });
  });

  describe('renderAllPages', () => {
    it('generates correct number of question pages', () => {
      const config = { ...DEFAULT_PRINT_CONFIG, puzzleCount: 10, puzzlesPerPage: 2 };
      const puzzles = generatePrintablePuzzles(config);
      const { questionPages } = renderAllPages(puzzles, config);
      expect(questionPages).toHaveLength(5);
    });

    it('generates answer pages when enabled', () => {
      const config = { ...DEFAULT_PRINT_CONFIG, puzzleCount: 4, puzzlesPerPage: 2, showAnswers: true };
      const puzzles = generatePrintablePuzzles(config);
      const { answerPages } = renderAllPages(puzzles, config);
      expect(answerPages).toHaveLength(2);
    });

    it('skips answer pages when disabled', () => {
      const config = { ...DEFAULT_PRINT_CONFIG, puzzleCount: 4, showAnswers: false };
      const puzzles = generatePrintablePuzzles(config);
      const { answerPages } = renderAllPages(puzzles, config);
      expect(answerPages).toHaveLength(0);
    });

    it('handles odd puzzle count', () => {
      const config = { ...DEFAULT_PRINT_CONFIG, puzzleCount: 5, puzzlesPerPage: 2 };
      const puzzles = generatePrintablePuzzles(config);
      const { questionPages } = renderAllPages(puzzles, config);
      expect(questionPages).toHaveLength(3);
    });
  });
});
```
```

---

## Subphase 10.7: Accessibility Tests

### Prompt for Claude Code:

```
Create accessibility tests.

1. Install axe-core:

```bash
npm install -D vitest-axe @axe-core/react
```

2. Create src/test/a11y.ts:

```typescript
import { configureAxe, toHaveNoViolations } from 'vitest-axe';
import { expect } from 'vitest';

expect.extend(toHaveNoViolations);

export const axe = configureAxe({
  rules: { 'region': { enabled: false } },
});

export async function checkA11y(container: HTMLElement) {
  const results = await axe(container);
  expect(results).toHaveNoViolations();
}
```

3. Create src/test/accessibility/screens.test.tsx:

```typescript
import { describe, it } from 'vitest';
import { render } from '@/test/utils';
import { checkA11y } from '../a11y';
import { LoginScreen } from '@/hub/screens/LoginScreen';
import { MainHubScreen } from '@/hub/screens/MainHubScreen';
import { SettingsScreen } from '@/hub/screens/SettingsScreen';

describe('Screen Accessibility', () => {
  it('LoginScreen has no a11y violations', async () => {
    const { container } = render(<LoginScreen />);
    await checkA11y(container);
  });

  it('MainHubScreen has no a11y violations', async () => {
    const { container } = render(<MainHubScreen />);
    await checkA11y(container);
  });

  it('SettingsScreen has no a11y violations', async () => {
    const { container } = render(<SettingsScreen />);
    await checkA11y(container);
  });
});
```

4. Create src/test/accessibility/components.test.tsx:

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@/test/utils';
import { checkA11y } from '../a11y';
import { Button } from '@/ui/Button';
import { Modal } from '@/ui/Modal';
import { HexCell } from '@/modules/circuit-challenge/components/HexCell';

describe('Component Accessibility', () => {
  describe('Button', () => {
    it('has no a11y violations', async () => {
      const { container } = render(<Button>Click</Button>);
      await checkA11y(container);
    });

    it('is focusable', () => {
      render(<Button>Click</Button>);
      const button = screen.getByRole('button');
      button.focus();
      expect(button).toHaveFocus();
    });

    it('indicates disabled state', () => {
      render(<Button disabled>Disabled</Button>);
      expect(screen.getByRole('button')).toBeDisabled();
    });
  });

  describe('Modal', () => {
    it('has no a11y violations when open', async () => {
      const { container } = render(
        <Modal isOpen={true} onClose={() => {}} title="Test">Content</Modal>
      );
      await checkA11y(container);
    });

    it('has role dialog', () => {
      render(<Modal isOpen={true} onClose={() => {}} title="Test">Content</Modal>);
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });

    it('has accessible title', () => {
      render(<Modal isOpen={true} onClose={() => {}} title="Test">Content</Modal>);
      expect(screen.getByRole('dialog')).toHaveAttribute('aria-labelledby');
    });
  });

  describe('HexCell', () => {
    it('has no a11y violations', async () => {
      const { container } = render(
        <HexCell index={0} value={5} isStart={false} isEnd={false} isSelected={false} onClick={() => {}} />
      );
      await checkA11y(container);
    });

    it('has accessible name', () => {
      render(<HexCell index={0} value={7} isStart={false} isEnd={false} isSelected={false} onClick={() => {}} />);
      expect(screen.getByRole('button')).toHaveAccessibleName();
    });
  });
});
```

5. Create src/test/accessibility/keyboard.test.tsx:

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { Modal } from '@/ui/Modal';

describe('Keyboard Navigation', () => {
  it('Tab navigates through focusable elements', async () => {
    const user = userEvent.setup();
    render(
      <div>
        <button>First</button>
        <button>Second</button>
        <button>Third</button>
      </div>
    );
    
    await user.tab();
    expect(screen.getByText('First')).toHaveFocus();
    
    await user.tab();
    expect(screen.getByText('Second')).toHaveFocus();
  });

  it('Escape closes modal', async () => {
    const user = userEvent.setup();
    const onClose = vi.fn();
    render(<Modal isOpen={true} onClose={onClose} title="Test">Content</Modal>);
    
    await user.keyboard('{Escape}');
    expect(onClose).toHaveBeenCalled();
  });

  it('Enter activates buttons', async () => {
    const user = userEvent.setup();
    const onClick = vi.fn();
    render(<button onClick={onClick}>Click me</button>);
    
    screen.getByRole('button').focus();
    await user.keyboard('{Enter}');
    
    expect(onClick).toHaveBeenCalled();
  });
});
```
```

---

## Subphase 10.8: Test Coverage & CI Configuration

### Prompt for Claude Code:

```
Configure test coverage and CI.

1. Update vitest.config.ts coverage thresholds:

```typescript
coverage: {
  provider: 'v8',
  reporter: ['text', 'json', 'html', 'lcov'],
  exclude: [
    'node_modules/',
    'src/test/',
    '**/*.d.ts',
    '**/*.config.*',
    '**/types/*',
    '**/index.ts',
  ],
  thresholds: {
    lines: 70,
    functions: 70,
    branches: 60,
    statements: 70,
  },
},
```

2. Create .github/workflows/test.yml:

```yaml
name: Test

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Type check
        run: npm run type-check
      
      - name: Lint
        run: npm run lint
      
      - name: Run tests
        run: npm run test:coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          fail_ci_if_error: true
```

3. Create TESTING.md documentation:

```markdown
# Testing Guide

## Running Tests

```bash
# Run all tests
npm test

# Run with UI
npm run test:ui

# Run once (CI mode)
npm run test:run

# Run with coverage
npm run test:coverage
```

## Test Structure

```
src/
├── test/
│   ├── setup.ts          # Test setup
│   ├── utils.tsx          # Custom render
│   ├── factories.ts       # Test data factories
│   ├── a11y.ts           # A11y helpers
│   ├── mocks/
│   │   ├── server.ts     # MSW server
│   │   └── handlers.ts   # API mocks
│   ├── integration/      # Integration tests
│   └── accessibility/    # A11y tests
└── **/__tests__/         # Unit tests (co-located)
```

## Coverage Targets

- Lines: 70%
- Functions: 70%
- Branches: 60%
- Statements: 70%

## Writing Tests

### Unit Tests
- Test one thing at a time
- Use factories for test data
- Mock external dependencies

### Integration Tests
- Test user flows
- Use MSW for API mocking
- Test realistic scenarios

### Accessibility Tests
- Use axe-core for automated checks
- Test keyboard navigation
- Test screen reader compatibility
```
```

---

## Phase 10 Completion Checklist

- [ ] Testing dependencies installed
- [ ] Vitest configured with coverage
- [ ] MSW mocks set up for Supabase
- [ ] Test factories created
- [ ] Puzzle generator tests pass
- [ ] Path validation tests pass
- [ ] useGame hook tests pass
- [ ] useGameTimer tests pass
- [ ] Button component tests pass
- [ ] Modal component tests pass
- [ ] HexCell component tests pass
- [ ] CoinDisplay tests pass
- [ ] Gameplay integration tests pass
- [ ] Authentication integration tests pass
- [ ] Parent dashboard integration tests pass
- [ ] Print generator tests pass
- [ ] SVG renderer tests pass
- [ ] Accessibility tests pass
- [ ] Coverage thresholds met (70%)
- [ ] CI workflow configured

---

## Files Created in Phase 10.2

```
src/ui/__tests__/
├── Button.test.tsx
├── Card.test.tsx
└── Modal.test.tsx

src/modules/circuit-challenge/components/__tests__/
├── HexCell.test.tsx
└── CoinDisplay.test.tsx

src/modules/circuit-challenge/services/__tests__/
├── printGenerator.test.ts
└── svgRenderer.test.ts

src/test/
├── a11y.ts
├── integration/
│   ├── gameplay.test.tsx
│   ├── authentication.test.tsx
│   └── parentDashboard.test.tsx
└── accessibility/
    ├── screens.test.tsx
    ├── components.test.tsx
    └── keyboard.test.tsx

.github/workflows/test.yml
TESTING.md
```

---

*End of Phase 10 - Testing Suite Complete*
