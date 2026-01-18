# Phase 3: UI Components

**Goal:** Create the visual components for Circuit Challenge - the 3D hexagonal cells with "poker chip" effect, connectors with electric flow animations, and the complete puzzle grid composition.

**Reference:** The visual design is based on circuit-challenge-visual-v5.html prototype.

---

## Subphase 3.1: SVG Gradient Definitions

### Prompt for Claude Code:

```
Create the SVG gradient and filter definitions component for Circuit Challenge.

File: src/modules/circuit-challenge/components/GridDefs.tsx

This component renders SVG <defs> containing all gradients and filters used by the puzzle grid.

1. Create component GridDefs that returns an SVG <defs> element containing:

Cell Gradients (for 3D poker chip effect):

a. cellTopGradient (normal cell top face):
   - Linear gradient, 145deg angle
   - Stop 0%: #3a3a4a
   - Stop 100%: #252530

b. cellBaseGradient (normal cell middle layer):
   - Linear gradient, 180deg
   - Stop 0%: #2a2a3a
   - Stop 100%: #1a1a25

c. cellEdgeGradient (normal cell bottom edge):
   - Linear gradient, 180deg
   - Stop 0%: #1a1a25
   - Stop 100%: #0f0f15

d. cellInnerShadow (subtle shadow on top face):
   - Radial gradient, center
   - Stop 0%: transparent
   - Stop 70%: transparent
   - Stop 100%: rgba(0,0,0,0.3)

e. startGradient (START cell top):
   - Linear gradient, 145deg
   - Stop 0%: #15803d
   - Stop 100%: #0d5025

f. startBaseGradient (START cell base/edge):
   - Linear gradient, 180deg
   - Stop 0%: #0d5025
   - Stop 100%: #073518

g. finishGradient (FINISH cell top):
   - Linear gradient, 145deg
   - Stop 0%: #ca8a04
   - Stop 100%: #854d0e

h. finishBaseGradient (FINISH cell base/edge):
   - Linear gradient, 180deg
   - Stop 0%: #854d0e
   - Stop 100%: #5c3508

i. currentGradient (current position top):
   - Linear gradient, 145deg
   - Stop 0%: #0d9488
   - Stop 100%: #086560

j. currentBaseGradient (current position base/edge):
   - Linear gradient, 180deg
   - Stop 0%: #086560
   - Stop 100%: #054540

k. visitedGradient (visited cell top):
   - Linear gradient, 145deg
   - Stop 0%: #1a5c38
   - Stop 100%: #103822

l. visitedBaseGradient (visited cell base/edge):
   - Linear gradient, 180deg
   - Stop 0%: #103822
   - Stop 100%: #082515

m. wrongGradient (wrong answer reveal):
   - Linear gradient, 145deg
   - Stop 0%: #ef4444
   - Stop 100%: #b91c1c

Filters:

n. glowFilter (for cell glow effects):
   - feGaussianBlur stdDeviation="4"
   - feMerge with blur and original

o. connectorGlowFilter (for active connector glow):
   - feGaussianBlur stdDeviation="6"
   - Larger blur for energy effect

2. Export GridDefs component

Note: All gradient IDs should be prefixed with "cc-" (circuit-challenge) to avoid conflicts.
Example: id="cc-cellTopGradient"
```

---

## Subphase 3.2: Hexagon Cell Component

### Prompt for Claude Code:

```
Create the 3D hexagonal cell component for Circuit Challenge.

File: src/modules/circuit-challenge/components/HexCell.tsx

Import: CellState from ../types, GridDefs patterns

Props interface HexCellProps:
  - cx: number (center x position)
  - cy: number (center y position)
  - size: number (hexagon radius, default 40)
  - state: CellState ('normal' | 'start' | 'finish' | 'current' | 'visited' | 'wrong')
  - expression: string (e.g., "5 + 8")
  - label?: string (e.g., "START" or "FINISH")
  - onClick?: () => void
  - disabled?: boolean
  - showAnswer?: boolean (for solution reveal)
  - answer?: number

1. Create hexagon path generator function:
   getHexagonPath(cx: number, cy: number, radius: number): string
   
   // Flat-top hexagon with 6 points
   // Point angles: 0°, 60°, 120°, 180°, 240°, 300°
   // Returns SVG path "M x0,y0 L x1,y1 L x2,y2 ... Z"

2. Create the 3D "poker chip" layers:
   The hexagon is rendered as multiple stacked layers for depth:
   
   Layer 1 - Shadow (translate y+14, x+4):
     - Hexagon filled with rgba(0,0,0,0.6)
     - Slight blur filter
   
   Layer 2 - Edge (translate y+12):
     - Hexagon filled with url(#cc-{state}BaseGradient) or cc-cellEdgeGradient for normal
   
   Layer 3 - Base (translate y+6):
     - Hexagon filled with url(#cc-{state}BaseGradient) or cc-cellBaseGradient
   
   Layer 4 - Top face (no translate):
     - Hexagon filled with url(#cc-{state}Gradient) or cc-cellTopGradient
     - Stroke based on state:
       * normal: #4a4a5a, width 2
       * start: #00ff88, width 2
       * finish: #ffcc00, width 2
       * current: #00ffcc, width 3
       * visited: #00ff88, width 2
       * wrong: #dc2626, width 2
   
   Layer 5 - Inner shadow (on top face):
     - Slightly smaller hexagon with cc-cellInnerShadow gradient
   
   Layer 6 - Rim highlight:
     - Hexagon stroke only, rgba(255,255,255,0.2), width 1.5
     - Creates subtle 3D highlight

3. Text content:
   - If label exists ("START" or "FINISH"):
     * Render label above center: fontSize 11px, fontWeight 700, letterSpacing 2px
     * Color: start=#00ff88, finish=#ffcc00
   
   - Render expression centered:
     * fontSize: 17px (or smaller if expression is long)
     * fontWeight: 700
     * fill: #ffffff (or rgba(255,255,255,0.7) for visited)
     * For FINISH cell, show "FINISH" text in gold #ffdd44

4. Animations (CSS classes):
   - .cell-current: pulsing glow animation (1.5s infinite)
   - .cell-visited: subtle pulsing (2s infinite)
   - Apply glow filter based on state

5. Interaction:
   - If onClick provided and not disabled:
     * cursor-pointer
     * Hover: slight scale up (1.02)
     * Active: scale down (0.98)
   - If disabled: opacity 0.5, no pointer events

6. Wrap in <g> element with:
   - className based on state
   - transform for positioning
   - onClick handler
   - role="button" and aria-label for accessibility

Export HexCell component.
```

---

## Subphase 3.3: Connector Component

### Prompt for Claude Code:

```
Create the connector component with electric flow animation for Circuit Challenge.

File: src/modules/circuit-challenge/components/Connector.tsx

Import: ConnectorType, Coordinate from ../types

Props interface ConnectorProps:
  - cellA: { x: number, y: number } (center of cell A)
  - cellB: { x: number, y: number } (center of cell B)
  - value: number (the connector's number)
  - type: ConnectorType ('horizontal' | 'vertical' | 'diagonal')
  - isTraversed: boolean (whether player has used this connector)
  - isWrong?: boolean (for revealing wrong path in hidden mode)
  - animationDelay?: number (stagger animations)

1. Calculate line endpoints:
   // Don't draw all the way to cell centers - stop short
   // This leaves room for the hexagon edges
   const shortenBy = 25; // pixels to pull back from each end
   
   Calculate direction vector from cellA to cellB
   Normalize and apply shortening to both ends

2. Calculate midpoint for value badge:
   midX = (x1 + x2) / 2
   midY = (y1 + y2) / 2

3. Default (inactive) connector rendering:
   <g className="connector">
     <line 
       x1, y1, x2, y2
       stroke="#3d3428"
       strokeWidth={8}
       strokeLinecap="round"
     />
     {/* Value badge */}
     <rect 
       x={midX - 16} y={midY - 14}
       width={32} height={28}
       rx={6}
       fill="#15151f"
       stroke="#2a2a3a"
       strokeWidth={2}
     />
     <text
       x={midX} y={midY}
       textAnchor="middle"
       dominantBaseline="middle"
       fill="#ff9f43"
       fontSize={14}
       fontWeight={800}
     >
       {value}
     </text>
   </g>

4. Traversed (active) connector - multi-layer electric effect:
   <g className="connector traversed">
     {/* Layer 1: Glow */}
     <line
       x1, y1, x2, y2
       stroke="#00ff88"
       strokeWidth={18}
       strokeLinecap="round"
       opacity={0.5}
       filter="url(#cc-connectorGlowFilter)"
       className="connector-glow"
     />
     
     {/* Layer 2: Main line */}
     <line
       x1, y1, x2, y2
       stroke="#00dd77"
       strokeWidth={10}
       strokeLinecap="round"
     />
     
     {/* Layer 3: Energy flow 2 (slower, larger particles) */}
     <line
       x1, y1, x2, y2
       stroke="#88ffcc"
       strokeWidth={6}
       strokeLinecap="round"
       strokeDasharray="6 30"
       className="energy-flow-slow"
       style={{ animationDelay: `${animationDelay || 0}ms` }}
     />
     
     {/* Layer 4: Energy flow 1 (faster, smaller particles) */}
     <line
       x1, y1, x2, y2
       stroke="#ffffff"
       strokeWidth={4}
       strokeLinecap="round"
       strokeDasharray="4 20"
       className="energy-flow-fast"
       style={{ animationDelay: `${(animationDelay || 0) + 200}ms` }}
     />
     
     {/* Layer 5: Bright core */}
     <line
       x1, y1, x2, y2
       stroke="#aaffcc"
       strokeWidth={3}
       strokeLinecap="round"
     />
     
     {/* Value badge (same as inactive but maybe brighter) */}
     ...same badge code...
   </g>

5. Wrong connector (for hidden mode reveal):
   - Main line: stroke="#ef4444"
   - Badge background: #7f1d1d
   - Badge text: #ef4444
   - Add flash animation class

6. CSS animations (add to component or separate CSS file):
   
   @keyframes electricFlow {
     0% { stroke-dashoffset: 0; }
     100% { stroke-dashoffset: -36; }
   }
   
   .energy-flow-fast {
     animation: electricFlow 0.8s linear infinite;
   }
   
   .energy-flow-slow {
     animation: electricFlow 1.2s linear infinite;
   }
   
   @keyframes connectorPulse {
     0%, 100% { opacity: 0.5; }
     50% { opacity: 0.8; }
   }
   
   .connector-glow {
     animation: connectorPulse 1.5s ease-in-out infinite;
   }

Export Connector component.
```

---

## Subphase 3.4: Puzzle Grid Component

### Prompt for Claude Code:

```
Create the main puzzle grid component that composes cells and connectors.

File: src/modules/circuit-challenge/components/PuzzleGrid.tsx

Import:
- Puzzle, Coordinate, CellState from ../types
- HexCell from ./HexCell
- Connector from ./Connector
- GridDefs from ./GridDefs

Props interface PuzzleGridProps:
  - puzzle: Puzzle
  - currentPosition: Coordinate
  - visitedCells: Coordinate[]
  - traversedConnectors: Array<{ cellA: Coordinate, cellB: Coordinate }>
  - wrongMoves?: Coordinate[] (for hidden mode reveal)
  - wrongConnectors?: Array<{ cellA: Coordinate, cellB: Coordinate }>
  - onCellClick: (coord: Coordinate) => void
  - disabled?: boolean
  - showSolution?: boolean
  - cellSize?: number (default 45)
  - className?: string

1. Calculate grid dimensions and layout:
   
   const cellSize = props.cellSize || 45;
   const hexWidth = cellSize * 2;
   const hexHeight = cellSize * Math.sqrt(3);
   
   // Spacing between cell centers
   const horizontalSpacing = hexWidth * 0.75; // Overlap for hex grid look
   const verticalSpacing = hexHeight;
   
   // Calculate total SVG dimensions
   const gridWidth = (puzzle.grid[0].length - 1) * horizontalSpacing + hexWidth + 40; // +40 for padding
   const gridHeight = (puzzle.grid.length - 1) * verticalSpacing + hexHeight + 40;
   
   // Function to get cell center coordinates
   const getCellCenter = (row: number, col: number) => ({
     x: 20 + col * horizontalSpacing + cellSize,
     y: 20 + row * verticalSpacing + cellSize
   });

2. Determine cell states:
   
   const getCellState = (row: number, col: number): CellState => {
     const coord = { row, col };
     const isStart = row === 0 && col === 0;
     const isFinish = row === puzzle.grid.length - 1 && col === puzzle.grid[0].length - 1;
     const isCurrent = currentPosition.row === row && currentPosition.col === col;
     const isVisited = visitedCells.some(c => c.row === row && c.col === col);
     const isWrong = wrongMoves?.some(c => c.row === row && c.col === col);
     
     if (isWrong) return 'wrong';
     if (isCurrent) return 'current';
     if (isStart && isVisited) return 'visited'; // START becomes visited after leaving
     if (isStart) return 'start';
     if (isFinish) return 'finish';
     if (isVisited) return 'visited';
     return 'normal';
   };

3. Check if connector is traversed:
   
   const isConnectorTraversed = (cellA: Coordinate, cellB: Coordinate): boolean => {
     return traversedConnectors.some(tc =>
       (tc.cellA.row === cellA.row && tc.cellA.col === cellA.col &&
        tc.cellB.row === cellB.row && tc.cellB.col === cellB.col) ||
       (tc.cellA.row === cellB.row && tc.cellA.col === cellB.col &&
        tc.cellB.row === cellA.row && tc.cellB.col === cellA.col)
     );
   };
   
   const isConnectorWrong = (cellA: Coordinate, cellB: Coordinate): boolean => {
     // Similar check for wrongConnectors
   };

4. Check if cell is clickable:
   
   const isCellClickable = (row: number, col: number): boolean => {
     if (disabled) return false;
     // Can only click cells adjacent to current position
     const rowDiff = Math.abs(row - currentPosition.row);
     const colDiff = Math.abs(col - currentPosition.col);
     // Adjacent means diff <= 1 for both, but not both 0
     return rowDiff <= 1 && colDiff <= 1 && !(rowDiff === 0 && colDiff === 0);
   };

5. Render the grid:
   
   return (
     <svg
       viewBox={`0 0 ${gridWidth} ${gridHeight}`}
       className={`puzzle-grid ${className || ''}`}
       style={{ maxWidth: '100%', height: 'auto' }}
     >
       <GridDefs />
       
       {/* Render connectors first (behind cells) */}
       <g className="connectors-layer">
         {puzzle.connectors.map((connector, index) => {
           const centerA = getCellCenter(connector.cellA.row, connector.cellA.col);
           const centerB = getCellCenter(connector.cellB.row, connector.cellB.col);
           
           return (
             <Connector
               key={`connector-${index}`}
               cellA={centerA}
               cellB={centerB}
               value={connector.value}
               type={connector.type}
               isTraversed={isConnectorTraversed(connector.cellA, connector.cellB)}
               isWrong={isConnectorWrong(connector.cellA, connector.cellB)}
               animationDelay={index * 50}
             />
           );
         })}
       </g>
       
       {/* Render cells on top */}
       <g className="cells-layer">
         {puzzle.grid.map((row, rowIndex) =>
           row.map((cell, colIndex) => {
             const center = getCellCenter(rowIndex, colIndex);
             const state = getCellState(rowIndex, colIndex);
             const clickable = isCellClickable(rowIndex, colIndex);
             
             return (
               <HexCell
                 key={`cell-${rowIndex}-${colIndex}`}
                 cx={center.x}
                 cy={center.y}
                 size={cellSize}
                 state={state}
                 expression={cell.expression}
                 label={cell.isStart ? 'START' : cell.isFinish ? 'FINISH' : undefined}
                 onClick={clickable ? () => onCellClick({ row: rowIndex, col: colIndex }) : undefined}
                 disabled={!clickable}
                 answer={cell.answer ?? undefined}
               />
             );
           })
         )}
       </g>
     </svg>
   );

Export PuzzleGrid component.
```

---

## Subphase 3.5: Lives Display Component

### Prompt for Claude Code:

```
Create the lives display component showing heart icons.

File: src/modules/circuit-challenge/components/LivesDisplay.tsx

Props interface LivesDisplayProps:
  - lives: number (0-5, current lives remaining)
  - maxLives: number (default 5)
  - size?: 'sm' | 'md' | 'lg' (default 'md')
  - showAnimation?: boolean (for when life is lost)
  - className?: string

1. Size configurations:
   const sizes = {
     sm: { heart: 20, gap: 4 },
     md: { heart: 28, gap: 8 },
     lg: { heart: 36, gap: 10 }
   };

2. Heart SVG component (inline):
   
   const Heart = ({ active, breaking }: { active: boolean, breaking?: boolean }) => (
     <svg 
       viewBox="0 0 24 24" 
       className={`
         transition-all duration-300
         ${active ? 'text-hearts-active' : 'text-hearts-inactive'}
         ${active ? 'drop-shadow-[0_0_8px_rgba(255,51,102,0.6)]' : ''}
         ${active && !breaking ? 'animate-heart-pulse' : ''}
         ${breaking ? 'animate-heart-break' : ''}
       `}
       fill="currentColor"
     >
       <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
     </svg>
   );

3. CSS animations (add to component or global CSS):
   
   @keyframes heartPulse {
     0%, 100% { transform: scale(1); }
     50% { transform: scale(1.15); }
   }
   
   @keyframes heartBreak {
     0% { transform: scale(1); opacity: 1; }
     25% { transform: scale(1.3); }
     50% { transform: scale(0.8) rotate(10deg); }
     75% { transform: scale(0.5) rotate(-10deg); opacity: 0.5; }
     100% { transform: scale(1); opacity: 1; }
   }
   
   .animate-heart-pulse {
     animation: heartPulse 1.2s ease-in-out infinite;
   }
   
   .animate-heart-break {
     animation: heartBreak 0.5s ease-out forwards;
   }

4. Track breaking heart for animation:
   - Use useRef to track previous lives count
   - When lives decreases, set breakingIndex to the heart that just became inactive
   - Clear breakingIndex after animation completes (500ms)

5. Render:
   
   return (
     <div 
       className={`flex items-center ${className || ''}`}
       style={{ gap: sizes[size].gap }}
       role="status"
       aria-label={`${lives} of ${maxLives} lives remaining`}
     >
       {Array.from({ length: maxLives }, (_, i) => (
         <div
           key={i}
           style={{ width: sizes[size].heart, height: sizes[size].heart }}
         >
           <Heart 
             active={i < lives}
             breaking={i === breakingIndex}
           />
         </div>
       ))}
     </div>
   );

Export LivesDisplay component.
```

---

## Subphase 3.6: Timer Display Component

### Prompt for Claude Code:

```
Create the timer display component for Circuit Challenge.

File: src/modules/circuit-challenge/components/TimerDisplay.tsx

Props interface TimerDisplayProps:
  - elapsedMs: number (milliseconds elapsed)
  - thresholdMs?: number (3-star threshold, for color coding)
  - isRunning: boolean
  - size?: 'sm' | 'md' | 'lg'
  - className?: string

1. Format time helper:
   
   const formatTime = (ms: number): string => {
     const totalSeconds = Math.floor(ms / 1000);
     const minutes = Math.floor(totalSeconds / 60);
     const seconds = totalSeconds % 60;
     return `${minutes}:${seconds.toString().padStart(2, '0')}`;
   };

2. Determine color based on threshold:
   
   const getTimerColor = (): string => {
     if (!thresholdMs) return 'text-white';
     
     const ratio = elapsedMs / thresholdMs;
     
     if (ratio < 0.7) return 'text-accent-primary'; // Green - on track
     if (ratio < 1.0) return 'text-yellow-400';     // Yellow - getting close
     return 'text-text-secondary';                   // Grey - over threshold
   };

3. Size configurations:
   const sizes = {
     sm: 'text-lg',
     md: 'text-2xl',
     lg: 'text-3xl'
   };

4. Render:
   
   return (
     <div 
       className={`
         font-mono font-bold tabular-nums
         ${sizes[size || 'md']}
         ${getTimerColor()}
         ${isRunning ? '' : 'opacity-70'}
         transition-colors duration-300
         ${className || ''}
       `}
       role="timer"
       aria-label={`Time elapsed: ${formatTime(elapsedMs)}`}
     >
       {formatTime(elapsedMs)}
     </div>
   );

Export TimerDisplay component.
```

---

## Subphase 3.7: Coin Display Component (Game Header)

### Prompt for Claude Code:

```
Create the coin display component with animation support for the game header.

File: src/modules/circuit-challenge/components/CoinDisplay.tsx

Props interface CoinDisplayProps:
  - amount: number (current displayed amount)
  - previousAmount?: number (for animation)
  - showChange?: { value: number, type: 'earn' | 'penalty' } (floating +10 or -30)
  - size?: 'sm' | 'md' | 'lg'
  - className?: string

1. Coin icon (inline SVG or emoji):
   
   const CoinIcon = ({ size }: { size: number }) => (
     <span 
       style={{ fontSize: size }}
       className="drop-shadow-[0_0_6px_rgba(251,191,36,0.5)]"
     >
       🪙
     </span>
   );

2. Floating change animation component:
   
   const FloatingChange = ({ value, type }: { value: number, type: 'earn' | 'penalty' }) => {
     const isPositive = type === 'earn';
     
     return (
       <span
         className={`
           absolute -top-2 left-1/2 -translate-x-1/2
           font-bold text-lg
           ${isPositive ? 'text-accent-primary animate-float-up' : 'text-error animate-float-down'}
           pointer-events-none
         `}
       >
         {isPositive ? '+' : ''}{value}
       </span>
     );
   };

3. CSS animations:
   
   @keyframes floatUp {
     0% { 
       opacity: 1; 
       transform: translate(-50%, 0);
     }
     100% { 
       opacity: 0; 
       transform: translate(-50%, -30px);
     }
   }
   
   @keyframes floatDown {
     0% { 
       opacity: 1; 
       transform: translate(-50%, 0);
     }
     100% { 
       opacity: 0; 
       transform: translate(-50%, 20px);
     }
   }
   
   .animate-float-up {
     animation: floatUp 0.8s ease-out forwards;
   }
   
   .animate-float-down {
     animation: floatDown 0.8s ease-out forwards;
   }

4. Number rolling animation (optional enhancement):
   - When amount changes, animate the digits rolling
   - Use CSS or simple counter increment over 300ms

5. Size configurations:
   const sizes = {
     sm: { icon: 18, text: 'text-base', padding: 'px-3 py-1.5' },
     md: { icon: 22, text: 'text-xl', padding: 'px-5 py-2.5' },
     lg: { icon: 28, text: 'text-2xl', padding: 'px-6 py-3' }
   };

6. Render:
   
   return (
     <div 
       className={`
         relative inline-flex items-center gap-2
         bg-gradient-to-br from-[#2a2518] to-[#1a1810]
         ${sizes[size || 'md'].padding}
         rounded-full
         border border-accent-tertiary/30
         shadow-lg
         ${className || ''}
       `}
     >
       <CoinIcon size={sizes[size || 'md'].icon} />
       
       <span 
         className={`
           font-bold text-accent-tertiary
           ${sizes[size || 'md'].text}
           tabular-nums
         `}
       >
         {amount.toLocaleString()}
       </span>
       
       {showChange && (
         <FloatingChange value={showChange.value} type={showChange.type} />
       )}
     </div>
   );

Export CoinDisplay component.
```

---

## Subphase 3.8: Game Header Component

### Prompt for Claude Code:

```
Create the game header component combining all status displays.

File: src/modules/circuit-challenge/components/GameHeader.tsx

Import:
- LivesDisplay from ./LivesDisplay
- TimerDisplay from ./TimerDisplay
- CoinDisplay from ./CoinDisplay
- Button from '@/ui/Button'

Props interface GameHeaderProps:
  - title?: string (e.g., "Quick Play" or "Level 3-A")
  - lives: number
  - maxLives: number
  - elapsedMs: number
  - isTimerRunning: boolean
  - timeThresholdMs?: number
  - coins: number
  - coinChange?: { value: number, type: 'earn' | 'penalty' }
  - isHiddenMode: boolean
  - onBackClick: () => void
  - className?: string

1. Layout structure:
   
   Desktop (>= 768px):
   [Back] [Title]                    [Lives] [Timer] [Coins]
   
   Mobile (< 768px):
   [Back] [Title]                              [Coins]
   [Lives]        [Timer]

2. Back button:
   - Rounded button with ← arrow
   - Opens confirmation modal (handled by parent)

3. Hidden mode adjustments:
   - If isHiddenMode:
     * Don't show lives (no lives system in hidden mode)
     * Timer color doesn't change (no time pressure shown)
     * Coin display is static (no animations during play)

4. Render:
   
   return (
     <header 
       className={`
         flex flex-wrap items-center justify-between
         px-4 md:px-8 py-4
         bg-gradient-to-b from-black/50 to-transparent
         ${className || ''}
       `}
     >
       {/* Left section: Back + Title */}
       <div className="flex items-center gap-4">
         <Button
           variant="ghost"
           size="sm"
           onClick={onBackClick}
           className="w-11 h-11 rounded-xl"
           aria-label="Go back"
         >
           ←
         </Button>
         
         {title && (
           <h1 className="text-xl md:text-2xl font-display font-bold text-white">
             {title}
           </h1>
         )}
       </div>
       
       {/* Right section: Status displays */}
       <div className="flex items-center gap-4 md:gap-6">
         {!isHiddenMode && (
           <LivesDisplay
             lives={lives}
             maxLives={maxLives}
             size="md"
             className="hidden md:flex"
           />
         )}
         
         <TimerDisplay
           elapsedMs={elapsedMs}
           thresholdMs={isHiddenMode ? undefined : timeThresholdMs}
           isRunning={isTimerRunning}
           size="md"
         />
         
         <CoinDisplay
           amount={coins}
           showChange={isHiddenMode ? undefined : coinChange}
           size="md"
         />
       </div>
       
       {/* Mobile-only second row for lives */}
       {!isHiddenMode && (
         <div className="w-full flex justify-center mt-2 md:hidden">
           <LivesDisplay
             lives={lives}
             maxLives={maxLives}
             size="sm"
           />
         </div>
       )}
     </header>
   );

Export GameHeader component.
```

---

## Subphase 3.9: Action Buttons Component

### Prompt for Claude Code:

```
Create the action buttons bar for gameplay controls.

File: src/modules/circuit-challenge/components/ActionButtons.tsx

Import: Button from '@/ui/Button'

Props interface ActionButtonsProps:
  - onReset: () => void
  - onNewPuzzle: () => void
  - onChangeDifficulty: () => void
  - onPrint: () => void
  - onViewSolution?: () => void (only shown after game over)
  - disabled?: boolean
  - showViewSolution?: boolean
  - className?: string

1. Button configurations:
   
   const buttons = [
     { id: 'reset', icon: '🔄', label: 'Reset', onClick: onReset },
     { id: 'new', icon: '✨', label: 'New Puzzle', onClick: onNewPuzzle },
     { id: 'difficulty', icon: '⚙️', label: 'Difficulty', onClick: onChangeDifficulty },
     { id: 'print', icon: '🖨️', label: 'Print', onClick: onPrint },
   ];
   
   if (showViewSolution && onViewSolution) {
     buttons.push({ id: 'solution', icon: '👁️', label: 'Solution', onClick: onViewSolution });
   }

2. Layout:
   - Horizontal bar at bottom of game area
   - On mobile: icons only, labels in tooltip/aria-label
   - On desktop: icons with labels
   - Centered with gap between buttons

3. Render:
   
   return (
     <div 
       className={`
         flex items-center justify-center gap-2 md:gap-4
         px-4 py-3
         bg-background-dark/80 backdrop-blur-sm
         border-t border-white/10
         ${className || ''}
       `}
     >
       {buttons.map(btn => (
         <Button
           key={btn.id}
           variant="ghost"
           size="sm"
           onClick={btn.onClick}
           disabled={disabled}
           className="flex items-center gap-2 px-3 py-2 md:px-4"
           aria-label={btn.label}
         >
           <span className="text-lg">{btn.icon}</span>
           <span className="hidden md:inline text-sm">{btn.label}</span>
         </Button>
       ))}
     </div>
   );

Export ActionButtons component.
```

---

## Subphase 3.10: Component Index and CSS

### Prompt for Claude Code:

```
Create the component index file and consolidated CSS for animations.

1. File: src/modules/circuit-challenge/components/index.ts

Export all components:
- GridDefs
- HexCell
- Connector
- PuzzleGrid
- LivesDisplay
- TimerDisplay
- CoinDisplay
- GameHeader
- ActionButtons

2. File: src/modules/circuit-challenge/components/animations.css

Consolidate all CSS animations used by the components:

/* ============================================
   Circuit Challenge - Animation Styles
   ============================================ */

/* Electric flow animation for connectors */
@keyframes electricFlow {
  0% { stroke-dashoffset: 0; }
  100% { stroke-dashoffset: -36; }
}

.energy-flow-fast {
  animation: electricFlow 0.8s linear infinite;
}

.energy-flow-slow {
  animation: electricFlow 1.2s linear infinite;
}

/* Connector glow pulse */
@keyframes connectorPulse {
  0%, 100% { opacity: 0.5; }
  50% { opacity: 0.8; }
}

.connector-glow {
  animation: connectorPulse 1.5s ease-in-out infinite;
}

/* Cell pulsing for current position */
@keyframes cellPulse {
  0%, 100% { 
    filter: drop-shadow(0 0 20px rgba(0, 255, 200, 0.5)); 
  }
  50% { 
    filter: drop-shadow(0 0 35px rgba(0, 255, 200, 0.9)); 
  }
}

.cell-current {
  animation: cellPulse 1.5s ease-in-out infinite;
}

/* Visited cell subtle pulse */
@keyframes visitedPulse {
  0%, 100% { 
    filter: drop-shadow(0 0 8px rgba(0, 255, 136, 0.3)); 
  }
  50% { 
    filter: drop-shadow(0 0 20px rgba(0, 255, 136, 0.6)); 
  }
}

.cell-visited {
  animation: visitedPulse 2s ease-in-out infinite;
}

/* Heart pulse */
@keyframes heartPulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.15); }
}

.animate-heart-pulse {
  animation: heartPulse 1.2s ease-in-out infinite;
}

/* Heart break animation */
@keyframes heartBreak {
  0% { transform: scale(1); opacity: 1; }
  25% { transform: scale(1.3); }
  50% { transform: scale(0.8) rotate(10deg); }
  75% { transform: scale(0.5) rotate(-10deg); opacity: 0.5; }
  100% { transform: scale(1); opacity: 1; }
}

.animate-heart-break {
  animation: heartBreak 0.5s ease-out forwards;
}

/* Coin floating animations */
@keyframes floatUp {
  0% { 
    opacity: 1; 
    transform: translate(-50%, 0);
  }
  100% { 
    opacity: 0; 
    transform: translate(-50%, -30px);
  }
}

@keyframes floatDown {
  0% { 
    opacity: 1; 
    transform: translate(-50%, 0);
  }
  100% { 
    opacity: 0; 
    transform: translate(-50%, 20px);
  }
}

.animate-float-up {
  animation: floatUp 0.8s ease-out forwards;
}

.animate-float-down {
  animation: floatDown 0.8s ease-out forwards;
}

/* Screen shake for wrong answer */
@keyframes screenShake {
  0%, 100% { transform: translateX(0); }
  10%, 30%, 50%, 70%, 90% { transform: translateX(-5px); }
  20%, 40%, 60%, 80% { transform: translateX(5px); }
}

.animate-shake {
  animation: screenShake 0.3s ease-out;
}

/* Star twinkle for background */
@keyframes twinkle {
  0%, 100% { opacity: 0.3; transform: scale(1); }
  50% { opacity: 0.8; transform: scale(1.2); }
}

.animate-twinkle {
  animation: twinkle var(--twinkle-duration, 4s) ease-in-out infinite;
}

3. Import the CSS in the module's main entry point or in the game screen.

4. Update src/index.css to import the animations:
   @import './modules/circuit-challenge/components/animations.css';
   
   (Or import directly in the components that need it)
```

---

## Phase 3 Completion Checklist

After completing all subphases, verify:

- [ ] HexCell renders with correct 3D effect for all states
- [ ] Connectors show proper electric flow when traversed
- [ ] PuzzleGrid correctly positions all cells and connectors
- [ ] Lives display animates when life is lost
- [ ] Timer updates and changes color based on threshold
- [ ] Coin display shows floating +10/-30 animations
- [ ] All animations are smooth (60fps)
- [ ] Components are responsive (mobile and desktop)
- [ ] SVG gradients render correctly
- [ ] Touch targets are at least 44px

---

## Files Created in This Phase

```
src/modules/circuit-challenge/components/
├── index.ts
├── animations.css
├── GridDefs.tsx
├── HexCell.tsx
├── Connector.tsx
├── PuzzleGrid.tsx
├── LivesDisplay.tsx
├── TimerDisplay.tsx
├── CoinDisplay.tsx
├── GameHeader.tsx
└── ActionButtons.tsx
```

---

## Visual Reference

The 3D hex cell structure (side view):
```
    ___________  ← Top face (gradient fill)
   /           \
  /             \  ← ~6px visible
 /_______________\ ← Base layer
 |               |
 |_______________| ← ~6px visible  
    ▓▓▓▓▓▓▓▓▓▓▓   ← Edge layer (~6px)
       ████        ← Shadow (offset)
```

Total visible depth: ~12-14px

---

*End of Phase 3*
