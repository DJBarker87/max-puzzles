# Phase 4: Game Logic & Screens

**Goal:** Implement the complete gameplay loop including state management, the useGame hook, Quick Play setup screen, main game screen, and summary screen. This phase brings together the engine (Phase 2) and UI components (Phase 3) into a playable game.

---

## Subphase 4.1: Game State Types

### Prompt for Claude Code:

```
Create the game state types and interfaces for Circuit Challenge.

File: src/modules/circuit-challenge/types/gameState.ts

1. Game status enum:
   
   type GameStatus = 
     | 'setup'      // Choosing difficulty
     | 'ready'      // Puzzle generated, waiting for first move
     | 'playing'    // Timer running, game in progress
     | 'won'        // Reached FINISH
     | 'lost'       // Out of lives (standard mode only)
     | 'revealing'; // Hidden mode: showing results

2. Move result type:
   
   interface MoveResult {
     correct: boolean;
     fromCell: Coordinate;
     toCell: Coordinate;
     connectorValue: number;
     cellAnswer: number;
   }

3. Game state interface:
   
   interface GameState {
     // Core state
     status: GameStatus;
     puzzle: Puzzle | null;
     difficulty: DifficultySettings;
     
     // Position tracking
     currentPosition: Coordinate;
     visitedCells: Coordinate[];
     traversedConnectors: Array<{ cellA: Coordinate, cellB: Coordinate }>;
     moveHistory: MoveResult[];
     
     // Lives (standard mode)
     lives: number;
     maxLives: number;
     
     // Timer
     startTime: number | null;      // Timestamp when timer started
     elapsedMs: number;             // Current elapsed time
     isTimerRunning: boolean;
     
     // Coins (for this puzzle)
     puzzleCoins: number;           // Running total for current puzzle (clamped to min 0)
     coinAnimations: Array<{ id: string, value: number, type: 'earn' | 'penalty', timestamp: number }>;
     
     // Mode flags
     isHiddenMode: boolean;
     
     // Hidden mode tracking
     hiddenModeResults: {
       moves: MoveResult[];
       correctCount: number;
       mistakeCount: number;
     } | null;
     
     // For solution reveal
     showingSolution: boolean;
   }

4. Game actions type:
   
   type GameAction =
     | { type: 'SET_DIFFICULTY'; payload: DifficultySettings }
     | { type: 'GENERATE_PUZZLE' }
     | { type: 'PUZZLE_GENERATED'; payload: Puzzle }
     | { type: 'PUZZLE_GENERATION_FAILED'; payload: string }
     | { type: 'MAKE_MOVE'; payload: Coordinate }
     | { type: 'START_TIMER' }
     | { type: 'TICK_TIMER'; payload: number }
     | { type: 'RESET_PUZZLE' }
     | { type: 'NEW_PUZZLE' }
     | { type: 'SHOW_SOLUTION' }
     | { type: 'HIDE_SOLUTION' }
     | { type: 'REVEAL_HIDDEN_RESULTS' }
     | { type: 'CLEAR_COIN_ANIMATION'; payload: string };

5. Initial state factory:
   
   const createInitialGameState = (difficulty?: DifficultySettings): GameState => ({
     status: 'setup',
     puzzle: null,
     difficulty: difficulty || DIFFICULTY_PRESETS[4], // Default to Level 5
     currentPosition: { row: 0, col: 0 },
     visitedCells: [],
     traversedConnectors: [],
     moveHistory: [],
     lives: 5,
     maxLives: 5,
     startTime: null,
     elapsedMs: 0,
     isTimerRunning: false,
     puzzleCoins: 0,
     coinAnimations: [],
     isHiddenMode: false,
     hiddenModeResults: null,
     showingSolution: false,
   });

Export all types and the initial state factory.
```

---

## Subphase 4.2: Game Reducer

### Prompt for Claude Code:

```
Create the game reducer for state management.

File: src/modules/circuit-challenge/hooks/gameReducer.ts

Import types from ../types/gameState and engine modules

1. Helper function - isAdjacent(from: Coordinate, to: Coordinate): boolean
   // Check if two cells are adjacent (including diagonals)

2. Helper function - getConnectorBetweenCells(
     from: Coordinate, 
     to: Coordinate, 
     connectors: Connector[]
   ): Connector | undefined

3. Helper function - checkMoveCorrectness(
     fromCell: Cell,
     toCell: Coordinate,
     connectors: Connector[]
   ): { correct: boolean, connector: Connector | undefined }
   
   // A move is correct if:
   // 1. The cells are adjacent
   // 2. There's a connector between them
   // 3. The connector's value equals the fromCell's answer

4. Main reducer function:
   
   function gameReducer(state: GameState, action: GameAction): GameState {
     switch (action.type) {
       
       case 'SET_DIFFICULTY':
         return {
           ...state,
           difficulty: action.payload,
           isHiddenMode: action.payload.hiddenMode,
         };
       
       case 'PUZZLE_GENERATED':
         return {
           ...state,
           status: 'ready',
           puzzle: action.payload,
           currentPosition: { row: 0, col: 0 },
           visitedCells: [{ row: 0, col: 0 }], // START is initially visited
           traversedConnectors: [],
           moveHistory: [],
           lives: state.maxLives,
           startTime: null,
           elapsedMs: 0,
           isTimerRunning: false,
           puzzleCoins: 0,
           coinAnimations: [],
           hiddenModeResults: state.isHiddenMode ? { moves: [], correctCount: 0, mistakeCount: 0 } : null,
           showingSolution: false,
         };
       
       case 'PUZZLE_GENERATION_FAILED':
         return {
           ...state,
           status: 'setup',
           // Could add error message to state
         };
       
       case 'START_TIMER':
         if (state.isTimerRunning) return state;
         return {
           ...state,
           status: 'playing',
           startTime: Date.now(),
           isTimerRunning: true,
         };
       
       case 'TICK_TIMER':
         if (!state.isTimerRunning) return state;
         return {
           ...state,
           elapsedMs: action.payload,
         };
       
       case 'MAKE_MOVE': {
         if (!state.puzzle || state.status === 'won' || state.status === 'lost') {
           return state;
         }
         
         const targetCoord = action.payload;
         const fromCell = state.puzzle.grid[state.currentPosition.row][state.currentPosition.col];
         
         // Check if target is adjacent
         if (!isAdjacent(state.currentPosition, targetCoord)) {
           return state; // Invalid move, ignore
         }
         
         // Check if already visited
         if (state.visitedCells.some(c => c.row === targetCoord.row && c.col === targetCoord.col)) {
           return state; // Can't revisit
         }
         
         // Check move correctness
         const { correct, connector } = checkMoveCorrectness(fromCell, targetCoord, state.puzzle.connectors);
         
         if (!connector) return state; // No connector exists (shouldn't happen)
         
         const moveResult: MoveResult = {
           correct,
           fromCell: state.currentPosition,
           toCell: targetCoord,
           connectorValue: connector.value,
           cellAnswer: fromCell.answer!,
         };
         
         // Check if reached FINISH
         const isFinish = targetCoord.row === state.puzzle.grid.length - 1 && 
                          targetCoord.col === state.puzzle.grid[0].length - 1;
         
         // Handle based on mode
         if (state.isHiddenMode) {
           // Hidden mode: always accept move, track results
           const newHiddenResults = {
             moves: [...state.hiddenModeResults!.moves, moveResult],
             correctCount: state.hiddenModeResults!.correctCount + (correct ? 1 : 0),
             mistakeCount: state.hiddenModeResults!.mistakeCount + (correct ? 0 : 1),
           };
           
           return {
             ...state,
             currentPosition: targetCoord,
             visitedCells: [...state.visitedCells, targetCoord],
             traversedConnectors: [...state.traversedConnectors, { cellA: state.currentPosition, cellB: targetCoord }],
             moveHistory: [...state.moveHistory, moveResult],
             hiddenModeResults: newHiddenResults,
             status: isFinish ? 'revealing' : state.status,
           };
         } else {
           // Standard mode
           if (correct) {
             // Correct move
             const coinId = `coin-${Date.now()}`;
             const newPuzzleCoins = state.puzzleCoins + 10;
             
             return {
               ...state,
               currentPosition: targetCoord,
               visitedCells: [...state.visitedCells, targetCoord],
               traversedConnectors: [...state.traversedConnectors, { cellA: state.currentPosition, cellB: targetCoord }],
               moveHistory: [...state.moveHistory, moveResult],
               puzzleCoins: newPuzzleCoins,
               coinAnimations: [...state.coinAnimations, { id: coinId, value: 10, type: 'earn', timestamp: Date.now() }],
               status: isFinish ? 'won' : state.status,
             };
           } else {
             // Wrong move
             const newLives = state.lives - 1;
             const coinId = `coin-${Date.now()}`;
             const newPuzzleCoins = Math.max(0, state.puzzleCoins - 30); // Clamp to 0
             
             return {
               ...state,
               lives: newLives,
               moveHistory: [...state.moveHistory, moveResult],
               puzzleCoins: newPuzzleCoins,
               coinAnimations: [...state.coinAnimations, { id: coinId, value: -30, type: 'penalty', timestamp: Date.now() }],
               status: newLives <= 0 ? 'lost' : state.status,
             };
           }
         }
       }
       
       case 'RESET_PUZZLE':
         // Reset to start of same puzzle
         if (!state.puzzle) return state;
         return {
           ...state,
           status: 'ready',
           currentPosition: { row: 0, col: 0 },
           visitedCells: [{ row: 0, col: 0 }],
           traversedConnectors: [],
           moveHistory: [],
           lives: state.maxLives,
           startTime: null,
           elapsedMs: 0,
           isTimerRunning: false,
           puzzleCoins: 0,
           coinAnimations: [],
           hiddenModeResults: state.isHiddenMode ? { moves: [], correctCount: 0, mistakeCount: 0 } : null,
           showingSolution: false,
         };
       
       case 'NEW_PUZZLE':
         return {
           ...state,
           status: 'setup',
           puzzle: null,
         };
       
       case 'SHOW_SOLUTION':
         return {
           ...state,
           showingSolution: true,
         };
       
       case 'HIDE_SOLUTION':
         return {
           ...state,
           showingSolution: false,
         };
       
       case 'REVEAL_HIDDEN_RESULTS':
         // Calculate final coins for hidden mode
         if (!state.hiddenModeResults) return state;
         const { correctCount, mistakeCount } = state.hiddenModeResults;
         const earnedCoins = correctCount * 10;
         const penaltyCoins = mistakeCount * 30;
         const finalCoins = Math.max(0, earnedCoins - penaltyCoins);
         
         return {
           ...state,
           status: 'won',
           puzzleCoins: finalCoins,
         };
       
       case 'CLEAR_COIN_ANIMATION':
         return {
           ...state,
           coinAnimations: state.coinAnimations.filter(a => a.id !== action.payload),
         };
       
       default:
         return state;
     }
   }

Export gameReducer and helper functions.
```

---

## Subphase 4.3: useGame Hook

### Prompt for Claude Code:

```
Create the main useGame hook that manages game state and provides actions.

File: src/modules/circuit-challenge/hooks/useGame.ts

Import:
- useReducer, useCallback, useEffect, useRef from 'react'
- gameReducer, createInitialGameState from ./gameReducer
- generatePuzzle from ../engine
- DifficultySettings, GameState, Coordinate from types

1. Hook interface:
   
   interface UseGameReturn {
     // State
     state: GameState;
     
     // Computed values
     canMove: boolean;
     isGameOver: boolean;
     timeThresholdMs: number | null;
     
     // Actions
     setDifficulty: (difficulty: DifficultySettings) => void;
     generateNewPuzzle: () => Promise<void>;
     makeMove: (coord: Coordinate) => void;
     resetPuzzle: () => void;
     requestNewPuzzle: () => void;
     showSolution: () => void;
     hideSolution: () => void;
     revealHiddenResults: () => void;
   }

2. Main hook implementation:
   
   function useGame(initialDifficulty?: DifficultySettings): UseGameReturn {
     const [state, dispatch] = useReducer(
       gameReducer,
       initialDifficulty,
       createInitialGameState
     );
     
     const timerRef = useRef<number | null>(null);
     const startTimeRef = useRef<number | null>(null);
     
     // Timer effect
     useEffect(() => {
       if (state.isTimerRunning && state.startTime) {
         startTimeRef.current = state.startTime;
         
         const tick = () => {
           if (startTimeRef.current) {
             const elapsed = Date.now() - startTimeRef.current;
             dispatch({ type: 'TICK_TIMER', payload: elapsed });
           }
           timerRef.current = requestAnimationFrame(tick);
         };
         
         timerRef.current = requestAnimationFrame(tick);
         
         return () => {
           if (timerRef.current) {
             cancelAnimationFrame(timerRef.current);
           }
         };
       }
     }, [state.isTimerRunning, state.startTime]);
     
     // Stop timer when game ends
     useEffect(() => {
       if (state.status === 'won' || state.status === 'lost' || state.status === 'revealing') {
         if (timerRef.current) {
           cancelAnimationFrame(timerRef.current);
           timerRef.current = null;
         }
       }
     }, [state.status]);
     
     // Clear coin animations after delay
     useEffect(() => {
       state.coinAnimations.forEach(anim => {
         const age = Date.now() - anim.timestamp;
         if (age < 1000) {
           setTimeout(() => {
             dispatch({ type: 'CLEAR_COIN_ANIMATION', payload: anim.id });
           }, 1000 - age);
         }
       });
     }, [state.coinAnimations]);
     
     // Actions
     const setDifficulty = useCallback((difficulty: DifficultySettings) => {
       dispatch({ type: 'SET_DIFFICULTY', payload: difficulty });
     }, []);
     
     const generateNewPuzzle = useCallback(async () => {
       dispatch({ type: 'GENERATE_PUZZLE' });
       
       // Run generation (could be async in web worker for large puzzles)
       const result = generatePuzzle(state.difficulty);
       
       if (result.success) {
         dispatch({ type: 'PUZZLE_GENERATED', payload: result.puzzle });
       } else {
         dispatch({ type: 'PUZZLE_GENERATION_FAILED', payload: result.error || 'Unknown error' });
         // Could show error toast here
       }
     }, [state.difficulty]);
     
     const makeMove = useCallback((coord: Coordinate) => {
       // Start timer on first move if not already running
       if (state.status === 'ready') {
         dispatch({ type: 'START_TIMER' });
       }
       
       dispatch({ type: 'MAKE_MOVE', payload: coord });
     }, [state.status]);
     
     const resetPuzzle = useCallback(() => {
       dispatch({ type: 'RESET_PUZZLE' });
     }, []);
     
     const requestNewPuzzle = useCallback(() => {
       dispatch({ type: 'NEW_PUZZLE' });
     }, []);
     
     const showSolution = useCallback(() => {
       dispatch({ type: 'SHOW_SOLUTION' });
     }, []);
     
     const hideSolution = useCallback(() => {
       dispatch({ type: 'HIDE_SOLUTION' });
     }, []);
     
     const revealHiddenResults = useCallback(() => {
       dispatch({ type: 'REVEAL_HIDDEN_RESULTS' });
     }, []);
     
     // Computed values
     const canMove = state.status === 'ready' || state.status === 'playing';
     const isGameOver = state.status === 'won' || state.status === 'lost';
     
     const timeThresholdMs = state.puzzle 
       ? state.puzzle.solution.steps * state.difficulty.secondsPerStep * 1000
       : null;
     
     return {
       state,
       canMove,
       isGameOver,
       timeThresholdMs,
       setDifficulty,
       generateNewPuzzle,
       makeMove,
       resetPuzzle,
       requestNewPuzzle,
       showSolution,
       hideSolution,
       revealHiddenResults,
     };
   }

Export useGame hook.
```

---

## Subphase 4.4: Quick Play Setup Screen

### Prompt for Claude Code:

```
Create the Quick Play setup screen for selecting difficulty.

File: src/modules/circuit-challenge/screens/QuickPlaySetup.tsx

Import:
- useState from 'react'
- useNavigate from 'react-router-dom'
- Button, Card, Toggle, Slider from '@/ui'
- DIFFICULTY_PRESETS, DifficultySettings from '../engine/difficulty'

1. Component state:
   - selectedPreset: number (0-9 for levels 1-10)
   - isCustomMode: boolean
   - customSettings: Partial<DifficultySettings>
   - hiddenMode: boolean

2. Layout structure:
   
   <div className="min-h-screen bg-background-dark p-4 md:p-8">
     {/* Header */}
     <div className="flex items-center gap-4 mb-8">
       <Button variant="ghost" onClick={goBack}>←</Button>
       <h1 className="text-2xl font-display font-bold">Quick Play</h1>
     </div>
     
     {/* Difficulty Selection */}
     <Card className="mb-6">
       <h2 className="text-lg font-bold mb-4">Difficulty</h2>
       
       {/* Preset selector dropdown or grid */}
       <select 
         value={selectedPreset}
         onChange={e => setSelectedPreset(Number(e.target.value))}
         className="w-full p-3 rounded-lg bg-background-dark border border-white/20"
       >
         {DIFFICULTY_PRESETS.map((preset, i) => (
           <option key={i} value={i}>
             Level {i + 1}: {preset.name}
           </option>
         ))}
       </select>
       
       {/* Preset description */}
       <p className="mt-2 text-text-secondary text-sm">
         {getPresetDescription(DIFFICULTY_PRESETS[selectedPreset])}
       </p>
     </Card>
     
     {/* Custom Settings Toggle */}
     <Card className="mb-6">
       <Toggle
         checked={isCustomMode}
         onChange={setIsCustomMode}
         label="Customise Settings"
       />
       
       {isCustomMode && (
         <div className="mt-4 space-y-4">
           {/* Operations checkboxes */}
           <div>
             <label className="text-sm font-medium mb-2 block">Operations</label>
             <div className="flex flex-wrap gap-3">
               {['+', '−', '×', '÷'].map(op => (
                 <label key={op} className="flex items-center gap-2">
                   <input
                     type="checkbox"
                     checked={isOperationEnabled(op)}
                     onChange={() => toggleOperation(op)}
                     className="w-5 h-5"
                   />
                   <span className="text-lg">{op}</span>
                 </label>
               ))}
             </div>
           </div>
           
           {/* Add/Sub Range slider */}
           <Slider
             label="+/− Number Range"
             min={5}
             max={100}
             value={customSettings.addSubRange || 20}
             onChange={v => setCustomSettings(s => ({ ...s, addSubRange: v }))}
             showValue
           />
           
           {/* Mult/Div Range slider (if enabled) */}
           {(customSettings.multiplicationEnabled || customSettings.divisionEnabled) && (
             <Slider
               label="×/÷ Number Range"
               min={2}
               max={12}
               value={customSettings.multDivRange || 5}
               onChange={v => setCustomSettings(s => ({ ...s, multDivRange: v }))}
               showValue
             />
           )}
           
           {/* Grid size selectors */}
           <div className="grid grid-cols-2 gap-4">
             <div>
               <label className="text-sm font-medium mb-2 block">Rows</label>
               <div className="flex gap-2">
                 {[3, 4, 5, 6, 7, 8].map(n => (
                   <button
                     key={n}
                     onClick={() => setCustomSettings(s => ({ ...s, gridRows: n }))}
                     className={`w-10 h-10 rounded ${customSettings.gridRows === n ? 'bg-accent-primary' : 'bg-background-dark border border-white/20'}`}
                   >
                     {n}
                   </button>
                 ))}
               </div>
             </div>
             <div>
               <label className="text-sm font-medium mb-2 block">Columns</label>
               <div className="flex gap-2">
                 {[4, 5, 6, 7, 8, 9, 10].map(n => (
                   <button
                     key={n}
                     onClick={() => setCustomSettings(s => ({ ...s, gridCols: n }))}
                     className={`w-10 h-10 rounded ${customSettings.gridCols === n ? 'bg-accent-primary' : 'bg-background-dark border border-white/20'}`}
                   >
                     {n}
                   </button>
                 ))}
               </div>
             </div>
           </div>
         </div>
       )}
     </Card>
     
     {/* Hidden Mode Toggle */}
     <Card className="mb-8">
       <Toggle
         checked={hiddenMode}
         onChange={setHiddenMode}
         label="Hidden Mode"
       />
       <p className="mt-2 text-text-secondary text-sm">
         Mistakes aren't revealed until the end. No lives - always reach FINISH.
       </p>
     </Card>
     
     {/* Start Button */}
     <Button
       variant="primary"
       size="lg"
       fullWidth
       onClick={handleStart}
     >
       Start Puzzle
     </Button>
   </div>

3. Helper functions:
   
   getPresetDescription(preset: DifficultySettings): string
   // Returns human-readable description like "Addition only, numbers up to 10, 3×4 grid"
   
   getFinalDifficulty(): DifficultySettings
   // Merges preset with custom settings and hiddenMode flag

4. Navigation:
   - On start: navigate to '/play/circuit-challenge/game' with difficulty in location state
   - Or use a context/store to pass difficulty

Export QuickPlaySetup component.
```

---

## Subphase 4.5: Starry Background Component

### Prompt for Claude Code:

```
Create the starry background component for the game screen.

File: src/modules/circuit-challenge/components/StarryBackground.tsx

1. Component that generates random stars:
   
   interface Star {
     id: number;
     x: number;      // percentage 0-100
     y: number;      // percentage 0-100
     size: number;   // 1-3 pixels
     twinkleClass: string;
   }

2. Generate stars on mount (or use useMemo):
   
   const generateStars = (count: number = 80): Star[] => {
     return Array.from({ length: count }, (_, i) => ({
       id: i,
       x: Math.random() * 100,
       y: Math.random() * 100,
       size: Math.random() < 0.6 ? 1 : Math.random() < 0.9 ? 2 : 3,
       twinkleClass: `animate-twinkle`,
       twinkleDuration: 3 + Math.random() * 2, // 3-5 seconds
       twinkleDelay: Math.random() * 5, // 0-5 seconds
     }));
   };

3. Render:
   
   return (
     <div className="fixed inset-0 overflow-hidden pointer-events-none z-0">
       {/* Gradient background */}
       <div className="absolute inset-0 bg-gradient-to-br from-[#0a0a12] via-[#12121f] to-[#0d0d18]" />
       
       {/* Ambient glow */}
       <div 
         className="absolute inset-0"
         style={{
           background: 'radial-gradient(circle at 50% 50%, rgba(0,255,128,0.03) 0%, transparent 50%)'
         }}
       />
       
       {/* Stars */}
       {stars.map(star => (
         <div
           key={star.id}
           className="absolute rounded-full bg-white animate-twinkle"
           style={{
             left: `${star.x}%`,
             top: `${star.y}%`,
             width: star.size,
             height: star.size,
             '--twinkle-duration': `${star.twinkleDuration}s`,
             animationDelay: `${star.twinkleDelay}s`,
           } as React.CSSProperties}
         />
       ))}
     </div>
   );

4. CSS (add to animations.css):
   
   @keyframes twinkle {
     0%, 100% { opacity: 0.3; transform: scale(1); }
     50% { opacity: 0.8; transform: scale(1.2); }
   }
   
   .animate-twinkle {
     animation: twinkle var(--twinkle-duration, 4s) ease-in-out infinite;
   }

Export StarryBackground component.
```

---

## Subphase 4.6: Game Screen - Main Layout

### Prompt for Claude Code:

```
Create the main game screen that renders the playable puzzle.

File: src/modules/circuit-challenge/screens/GameScreen.tsx

Import:
- useEffect from 'react'
- useLocation, useNavigate from 'react-router-dom'
- useGame from '../hooks/useGame'
- PuzzleGrid, GameHeader, ActionButtons, StarryBackground from '../components'
- Modal from '@/ui'
- DifficultySettings from '../engine/types'

1. Get difficulty from navigation state or default:
   
   const location = useLocation();
   const navigate = useNavigate();
   const difficulty = (location.state as { difficulty?: DifficultySettings })?.difficulty;
   
   // Redirect to setup if no difficulty
   useEffect(() => {
     if (!difficulty) {
       navigate('/play/circuit-challenge/quick');
     }
   }, [difficulty, navigate]);

2. Initialize game hook:
   
   const {
     state,
     canMove,
     isGameOver,
     timeThresholdMs,
     generateNewPuzzle,
     makeMove,
     resetPuzzle,
     requestNewPuzzle,
     showSolution,
   } = useGame(difficulty);

3. Generate puzzle on mount:
   
   useEffect(() => {
     if (difficulty && !state.puzzle) {
       generateNewPuzzle();
     }
   }, [difficulty, state.puzzle, generateNewPuzzle]);

4. Modal states:
   - showExitConfirm: boolean
   - showGameOverModal: boolean (auto-show when isGameOver)

5. Layout:
   
   return (
     <div className="min-h-screen flex flex-col relative">
       <StarryBackground />
       
       {/* Game Header */}
       <GameHeader
         title={state.isHiddenMode ? "Hidden Mode" : "Quick Play"}
         lives={state.lives}
         maxLives={state.maxLives}
         elapsedMs={state.elapsedMs}
         isTimerRunning={state.isTimerRunning}
         timeThresholdMs={timeThresholdMs}
         coins={state.puzzleCoins}
         coinChange={state.coinAnimations[0] ? {
           value: state.coinAnimations[0].value,
           type: state.coinAnimations[0].type
         } : undefined}
         isHiddenMode={state.isHiddenMode}
         onBackClick={() => setShowExitConfirm(true)}
       />
       
       {/* Puzzle Grid */}
       <div className="flex-1 flex items-center justify-center p-4 relative z-10">
         {state.puzzle ? (
           <PuzzleGrid
             puzzle={state.puzzle}
             currentPosition={state.currentPosition}
             visitedCells={state.visitedCells}
             traversedConnectors={state.traversedConnectors}
             onCellClick={canMove ? makeMove : () => {}}
             disabled={!canMove}
             showSolution={state.showingSolution}
             wrongMoves={state.showingSolution && state.hiddenModeResults 
               ? state.hiddenModeResults.moves.filter(m => !m.correct).map(m => m.toCell)
               : undefined}
             className={state.status === 'lost' ? 'animate-shake' : ''}
           />
         ) : (
           <div className="text-center">
             <div className="animate-spin text-4xl mb-4">⚡</div>
             <p className="text-text-secondary">Generating puzzle...</p>
           </div>
         )}
       </div>
       
       {/* Action Buttons */}
       <ActionButtons
         onReset={resetPuzzle}
         onNewPuzzle={handleNewPuzzle}
         onChangeDifficulty={() => navigate('/play/circuit-challenge/quick')}
         onPrint={handlePrint}
         onViewSolution={state.status === 'lost' ? showSolution : undefined}
         showViewSolution={state.status === 'lost'}
         disabled={!state.puzzle}
       />
       
       {/* Exit Confirmation Modal */}
       <Modal
         isOpen={showExitConfirm}
         onClose={() => setShowExitConfirm(false)}
         title="Exit Puzzle?"
       >
         <p className="mb-4">Your progress on this puzzle will be lost.</p>
         <div className="flex gap-3">
           <Button variant="ghost" onClick={() => setShowExitConfirm(false)}>
             Continue Playing
           </Button>
           <Button variant="secondary" onClick={() => navigate('/play/circuit-challenge')}>
             Exit
           </Button>
         </div>
       </Modal>
       
       {/* Game Over handled by navigation to Summary */}
     </div>
   );

6. Effects:
   - Navigate to summary screen when game ends
   - Handle screen shake on wrong move

7. Handlers:
   
   const handleNewPuzzle = () => {
     requestNewPuzzle();
     generateNewPuzzle();
   };
   
   const handlePrint = () => {
     // Navigate to print view or trigger print
     window.print(); // Simple approach for now
   };

Export GameScreen component.
```

---

## Subphase 4.7: Summary Screen

### Prompt for Claude Code:

```
Create the summary screen shown after completing or losing a puzzle.

File: src/modules/circuit-challenge/screens/SummaryScreen.tsx

Import:
- useLocation, useNavigate from 'react-router-dom'
- Button, Card from '@/ui'
- StarryBackground from '../components'

1. Get game results from location state:
   
   interface SummaryData {
     won: boolean;
     isHiddenMode: boolean;
     elapsedMs: number;
     puzzleCoins: number;
     moveHistory: MoveResult[];
     hiddenModeResults?: {
       correctCount: number;
       mistakeCount: number;
     };
     difficulty: DifficultySettings;
   }

2. Calculate statistics:
   
   const totalMoves = data.moveHistory.length;
   const correctMoves = data.moveHistory.filter(m => m.correct).length;
   const mistakes = totalMoves - correctMoves;
   const accuracy = totalMoves > 0 ? Math.round((correctMoves / totalMoves) * 100) : 0;
   const timeFormatted = formatTime(data.elapsedMs);

3. Layout for Standard Mode Win:
   
   <div className="min-h-screen flex flex-col items-center justify-center p-4 relative">
     <StarryBackground />
     
     <Card className="w-full max-w-md text-center relative z-10">
       {/* Celebration */}
       <div className="text-6xl mb-4">🎉</div>
       <h1 className="text-3xl font-display font-bold mb-2">Puzzle Complete!</h1>
       
       {/* Stars (V2 - placeholder for now) */}
       <div className="text-4xl mb-6">⭐ ⭐ ⭐</div>
       
       {/* Stats */}
       <div className="space-y-2 mb-6 text-lg">
         <p>Time: <span className="font-bold">{timeFormatted}</span></p>
         <p>Coins: <span className="font-bold text-accent-tertiary">+{data.puzzleCoins}</span></p>
         <p>Mistakes: <span className="font-bold">{mistakes}</span></p>
       </div>
       
       {/* Actions */}
       <div className="space-y-3">
         <Button variant="primary" fullWidth onClick={handlePlayAgain}>
           Play Again
         </Button>
         <Button variant="ghost" fullWidth onClick={handleChangeDifficulty}>
           Change Difficulty
         </Button>
         <Button variant="ghost" fullWidth onClick={handleExit}>
           Exit
         </Button>
       </div>
     </Card>
   </div>

4. Layout for Hidden Mode Win:
   
   <Card className="w-full max-w-md text-center relative z-10">
     <h1 className="text-2xl font-display font-bold mb-4">Puzzle Complete!</h1>
     
     <h2 className="text-lg font-medium mb-4">Results:</h2>
     
     <div className="space-y-2 mb-6">
       <p className="flex justify-between">
         <span>✓ Correct:</span>
         <span className="font-bold text-accent-primary">{data.hiddenModeResults.correctCount}</span>
       </p>
       <p className="flex justify-between">
         <span>✗ Mistakes:</span>
         <span className="font-bold text-error">{data.hiddenModeResults.mistakeCount}</span>
       </p>
       <p className="flex justify-between">
         <span>Accuracy:</span>
         <span className="font-bold">{accuracy}%</span>
       </p>
     </div>
     
     <div className="border-t border-white/10 pt-4 mb-6">
       <p className="text-lg">
         Coins: <span className="font-bold text-accent-tertiary">+{data.puzzleCoins}</span>
       </p>
       <p className="text-sm text-text-secondary">
         ({data.hiddenModeResults.correctCount * 10} earned − {data.hiddenModeResults.mistakeCount * 30} penalty)
       </p>
     </div>
     
     <div className="space-y-3">
       <Button variant="secondary" onClick={handleViewMistakes}>
         View Mistakes
       </Button>
       <Button variant="primary" fullWidth onClick={handlePlayAgain}>
         Play Again
       </Button>
     </div>
   </Card>

5. Layout for Game Over (Lost):
   
   <Card className="w-full max-w-md text-center relative z-10">
     <div className="text-6xl mb-4">💔</div>
     <h1 className="text-2xl font-display font-bold mb-4">Out of Lives</h1>
     
     <p className="text-text-secondary mb-6">
       Coins: <span className="font-bold">+{data.puzzleCoins}</span>
     </p>
     
     <div className="space-y-3">
       <Button variant="primary" fullWidth onClick={handleTryAgain}>
         Try Again
       </Button>
       <Button variant="secondary" fullWidth onClick={handleViewSolution}>
         See Solution
       </Button>
       <Button variant="ghost" fullWidth onClick={handleExit}>
         Exit
       </Button>
     </div>
   </Card>

6. Navigation handlers:
   
   const handlePlayAgain = () => {
     navigate('/play/circuit-challenge/game', { 
       state: { difficulty: data.difficulty } 
     });
   };
   
   const handleChangeDifficulty = () => {
     navigate('/play/circuit-challenge/quick');
   };
   
   const handleExit = () => {
     navigate('/play/circuit-challenge');
   };
   
   const handleViewSolution = () => {
     navigate('/play/circuit-challenge/game', {
       state: { 
         difficulty: data.difficulty,
         showSolution: true,
         puzzle: data.puzzle // Pass the puzzle to show solution
       }
     });
   };

Export SummaryScreen component.
```

---

## Subphase 4.8: Module Menu Screen

### Prompt for Claude Code:

```
Create the Circuit Challenge module menu screen.

File: src/modules/circuit-challenge/screens/ModuleMenu.tsx

Import:
- useNavigate from 'react-router-dom'
- Button, Card from '@/ui'
- StarryBackground from '../components'

1. Layout:
   
   return (
     <div className="min-h-screen flex flex-col relative">
       <StarryBackground />
       
       {/* Header */}
       <header className="flex items-center gap-4 p-4 md:p-8 relative z-10">
         <Button variant="ghost" onClick={() => navigate('/hub')}>
           ←
         </Button>
         <div>
           <h1 className="text-2xl md:text-3xl font-display font-bold">
             ⚡ Circuit Challenge
           </h1>
           <p className="text-text-secondary">Navigate the circuit!</p>
         </div>
       </header>
       
       {/* Menu Options */}
       <div className="flex-1 flex flex-col items-center justify-center p-4 gap-4 relative z-10">
         
         {/* Quick Play */}
         <Card 
           variant="interactive"
           className="w-full max-w-md p-6"
           onClick={() => navigate('/play/circuit-challenge/quick')}
         >
           <div className="flex items-center gap-4">
             <span className="text-4xl">⚡</span>
             <div>
               <h2 className="text-xl font-bold">Quick Play</h2>
               <p className="text-text-secondary">Play at any difficulty</p>
             </div>
           </div>
         </Card>
         
         {/* Progression (V2 - disabled) */}
         <Card 
           variant="default"
           className="w-full max-w-md p-6 opacity-50"
         >
           <div className="flex items-center gap-4">
             <span className="text-4xl">📈</span>
             <div>
               <h2 className="text-xl font-bold">Progression</h2>
               <p className="text-text-secondary">Coming in V2</p>
               <div className="flex items-center gap-1 mt-1">
                 <span className="text-yellow-400">🔒</span>
                 <span className="text-sm text-text-secondary">30 levels to master</span>
               </div>
             </div>
           </div>
         </Card>
         
         {/* Puzzle Maker */}
         <Card 
           variant="interactive"
           className="w-full max-w-md p-6"
           onClick={() => navigate('/play/circuit-challenge/puzzle-maker')}
         >
           <div className="flex items-center gap-4">
             <span className="text-4xl">🖨️</span>
             <div>
               <h2 className="text-xl font-bold">Puzzle Maker</h2>
               <p className="text-text-secondary">Print puzzles for class</p>
             </div>
           </div>
         </Card>
         
       </div>
       
       {/* Stats summary (optional) */}
       <footer className="p-4 text-center text-text-secondary relative z-10">
         <p>Games played: 0 | Best streak: 0</p>
       </footer>
     </div>
   );

Export ModuleMenu component.
```

---

## Subphase 4.9: Screen Shake and Wrong Move Feedback

### Prompt for Claude Code:

```
Create utilities for visual feedback on wrong moves.

File: src/modules/circuit-challenge/hooks/useFeedback.ts

1. Hook for managing screen shake:
   
   interface UseFeedbackReturn {
     isShaking: boolean;
     triggerShake: () => void;
     shakeClassName: string;
   }
   
   function useFeedback(): UseFeedbackReturn {
     const [isShaking, setIsShaking] = useState(false);
     
     const triggerShake = useCallback(() => {
       setIsShaking(true);
       setTimeout(() => setIsShaking(false), 300);
     }, []);
     
     const shakeClassName = isShaking ? 'animate-shake' : '';
     
     return { isShaking, triggerShake, shakeClassName };
   }

2. Update GameScreen to use feedback:
   
   const { triggerShake, shakeClassName } = useFeedback();
   
   // Watch for wrong moves
   useEffect(() => {
     const lastMove = state.moveHistory[state.moveHistory.length - 1];
     if (lastMove && !lastMove.correct && !state.isHiddenMode) {
       triggerShake();
     }
   }, [state.moveHistory, state.isHiddenMode, triggerShake]);

3. Add sound effect hook placeholder:
   
   function useGameSounds() {
     const { playSound } = useSound(); // From context
     
     const playCorrect = useCallback(() => {
       playSound('correct');
     }, [playSound]);
     
     const playWrong = useCallback(() => {
       playSound('wrong');
     }, [playSound]);
     
     const playWin = useCallback(() => {
       playSound('win');
     }, [playSound]);
     
     return { playCorrect, playWrong, playWin };
   }

Export hooks.
```

---

## Subphase 4.10: Route Registration and Module Index

### Prompt for Claude Code:

```
Register all screens in the routing system and create module index.

1. Update src/app/routes.tsx:
   
   import {
     ModuleMenu,
     QuickPlaySetup,
     GameScreen,
     SummaryScreen,
   } from '@/modules/circuit-challenge/screens';
   
   // Add routes:
   {
     path: '/play/circuit-challenge',
     element: <ModuleMenu />,
   },
   {
     path: '/play/circuit-challenge/quick',
     element: <QuickPlaySetup />,
   },
   {
     path: '/play/circuit-challenge/game',
     element: <GameScreen />,
   },
   {
     path: '/play/circuit-challenge/summary',
     element: <SummaryScreen />,
   },

2. Update src/modules/circuit-challenge/screens/index.ts:
   
   export { ModuleMenu } from './ModuleMenu';
   export { QuickPlaySetup } from './QuickPlaySetup';
   export { GameScreen } from './GameScreen';
   export { SummaryScreen } from './SummaryScreen';

3. Update src/modules/circuit-challenge/hooks/index.ts:
   
   export { useGame } from './useGame';
   export { gameReducer, createInitialGameState } from './gameReducer';
   export { useFeedback } from './useFeedback';

4. Update src/modules/circuit-challenge/index.ts (module registration):
   
   import { PuzzleModule } from '@/shared/types/module';
   
   export const CircuitChallengeModule: PuzzleModule = {
     id: 'circuit-challenge',
     name: 'Circuit Challenge',
     description: 'Navigate the circuit by solving arithmetic!',
     icon: '⚡',
     
     init(hub) {
       // Initialize module resources
       console.log('Circuit Challenge initialized');
     },
     
     destroy() {
       // Cleanup
       console.log('Circuit Challenge destroyed');
     },
     
     renderMenu() {
       // Return the menu component type
       return ModuleMenu;
     },
     
     renderGame(config) {
       // Return the game component type
       return GameScreen;
     },
     
     getProgressSummary(userId) {
       // Return progress data (stub for V1)
       return {
         totalLevels: 30,
         completedLevels: 0,
         totalStars: 90,
         earnedStars: 0,
         lastPlayed: null,
       };
     },
   };

5. Test the complete flow:
   - Navigate to /play/circuit-challenge
   - Select Quick Play
   - Choose difficulty and start
   - Play through a puzzle
   - Verify win/lose flow
   - Check summary screen navigation
```

---

## Phase 4 Completion Checklist

After completing all subphases, verify:

- [ ] Quick Play setup screen shows all difficulty options
- [ ] Custom difficulty settings work correctly
- [ ] Hidden mode toggle works
- [ ] Puzzle generates and displays correctly
- [ ] Timer starts on first move
- [ ] Correct moves: cell transitions, connector animates, +10 coins
- [ ] Wrong moves: screen shakes, life lost, -30 coins (clamped to 0)
- [ ] Lives display updates correctly
- [ ] Game over triggers at 0 lives
- [ ] Win triggers when reaching FINISH
- [ ] Summary screen shows correct stats
- [ ] Reset button works (same puzzle)
- [ ] New Puzzle button works (fresh puzzle)
- [ ] Hidden mode: no lives, no coin animations, reveal at end
- [ ] Navigation between screens works correctly

---

## Files Created in This Phase

```
src/modules/circuit-challenge/
├── types/
│   └── gameState.ts
├── hooks/
│   ├── index.ts
│   ├── gameReducer.ts
│   ├── useGame.ts
│   └── useFeedback.ts
├── screens/
│   ├── index.ts
│   ├── ModuleMenu.tsx
│   ├── QuickPlaySetup.tsx
│   ├── GameScreen.tsx
│   └── SummaryScreen.tsx
├── components/
│   └── StarryBackground.tsx (added)
└── index.ts (module registration)
```

---

## Game Flow Diagram

```
[Module Menu]
     │
     ├──► [Quick Play Setup]
     │         │
     │         ▼
     │    [Game Screen] ◄────────┐
     │         │                 │
     │         ├── Win ──────────┤
     │         │                 │
     │         ├── Lose ─────────┤
     │         │                 │
     │         └── Reset ────────┘
     │         │
     │         ▼
     │    [Summary Screen]
     │         │
     │         ├── Play Again ───► [Game Screen]
     │         ├── Change Difficulty ───► [Quick Play Setup]
     │         └── Exit ───► [Module Menu]
     │
     ├──► [Progression] (V2)
     │
     └──► [Puzzle Maker] (Phase 8)
```

---

*End of Phase 4*
