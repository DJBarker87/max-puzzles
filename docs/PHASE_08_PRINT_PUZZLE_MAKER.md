# Phase 8: Print & Puzzle Maker

**Goal:** Build the classroom-ready print system that generates professional A4 worksheets with 2 puzzles per page, pure black & white output optimised for photocopying, and a batch puzzle generator for teachers.

---

## Subphase 8.1: Print Types and Configuration

### Prompt for Claude Code:

```
Create types and configuration for the print system.

File: src/modules/circuit-challenge/types/print.ts

```typescript
/**
 * Print output configuration.
 */
export interface PrintConfig {
  // Page layout
  pageSize: 'A4' | 'Letter';
  orientation: 'portrait' | 'landscape';
  puzzlesPerPage: 1 | 2;
  
  // Puzzle settings
  difficulty: number; // 0-9
  showAnswers: boolean;
  showDifficulty: boolean;
  showPuzzleNumber: boolean;
  
  // Styling
  cellSize: number; // mm
  lineWidth: number; // mm
  fontSize: number; // pt
  
  // Header/Footer
  title: string;
  subtitle: string;
  showDate: boolean;
  showPageNumbers: boolean;
  
  // Batch settings
  puzzleCount: number;
  uniquePuzzles: boolean; // Generate unique puzzles or repeat
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
};

/**
 * A puzzle prepared for printing.
 */
export interface PrintablePuzzle {
  id: string;
  puzzleNumber: number;
  difficulty: number;
  difficultyName: string;
  
  // Grid data
  gridSize: number;
  cells: PrintableCell[];
  connectors: PrintableConnector[];
  
  // Solution
  targetSum: number;
  solution: number[]; // Cell indices in solution path
}

/**
 * Cell data for print rendering.
 */
export interface PrintableCell {
  index: number;
  row: number;
  col: number;
  value: number;
  isStart: boolean;
  isEnd: boolean;
  inSolution: boolean;
}

/**
 * Connector data for print rendering.
 */
export interface PrintableConnector {
  fromIndex: number;
  toIndex: number;
  inSolution: boolean;
}

/**
 * Page layout measurements (in mm).
 */
export interface PageLayout {
  width: number;
  height: number;
  marginTop: number;
  marginBottom: number;
  marginLeft: number;
  marginRight: number;
  contentWidth: number;
  contentHeight: number;
  puzzleAreaHeight: number;
  gapBetweenPuzzles: number;
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
};

/**
 * Difficulty level names for display.
 */
export const DIFFICULTY_NAMES: Record<number, string> = {
  0: 'Beginner',
  1: 'Easy',
  2: 'Simple',
  3: 'Medium',
  4: 'Moderate',
  5: 'Challenging',
  6: 'Hard',
  7: 'Advanced',
  8: 'Expert',
  9: 'Master',
};
```

Export all types and constants.
```

---

## Subphase 8.2: Print Puzzle Generator Service

### Prompt for Claude Code:

```
Create a service to generate puzzles formatted for printing.

File: src/modules/circuit-challenge/services/printGenerator.ts

```typescript
import { generatePuzzle } from '../engine/puzzleGenerator';
import { DIFFICULTY_CONFIGS } from '../engine/difficultyConfig';
import type { 
  PrintConfig, 
  PrintablePuzzle, 
  PrintableCell, 
  PrintableConnector,
  DIFFICULTY_NAMES 
} from '../types/print';

/**
 * Generates a batch of puzzles formatted for printing.
 */
export function generatePrintablePuzzles(
  config: PrintConfig
): PrintablePuzzle[] {
  const puzzles: PrintablePuzzle[] = [];
  const difficulty = config.difficulty;
  const diffConfig = DIFFICULTY_CONFIGS[difficulty];
  
  for (let i = 0; i < config.puzzleCount; i++) {
    // Generate a puzzle using the existing engine
    const puzzle = generatePuzzle(difficulty);
    
    // Convert to printable format
    const printable = convertToPrintable(puzzle, i + 1, difficulty);
    puzzles.push(printable);
  }
  
  return puzzles;
}

/**
 * Converts a generated puzzle to printable format.
 */
function convertToPrintable(
  puzzle: ReturnType<typeof generatePuzzle>,
  puzzleNumber: number,
  difficulty: number
): PrintablePuzzle {
  const { grid, solution, targetSum } = puzzle;
  const gridSize = grid.length;
  
  // Create solution set for quick lookup
  const solutionSet = new Set(solution);
  
  // Create solution edges for connector highlighting
  const solutionEdges = new Set<string>();
  for (let i = 0; i < solution.length - 1; i++) {
    const from = solution[i];
    const to = solution[i + 1];
    // Store both directions for easy lookup
    solutionEdges.add(`${from}-${to}`);
    solutionEdges.add(`${to}-${from}`);
  }
  
  // Convert cells
  const cells: PrintableCell[] = [];
  for (let row = 0; row < gridSize; row++) {
    for (let col = 0; col < gridSize; col++) {
      const index = row * gridSize + col;
      const value = grid[row][col];
      
      cells.push({
        index,
        row,
        col,
        value,
        isStart: index === solution[0],
        isEnd: index === solution[solution.length - 1],
        inSolution: solutionSet.has(index),
      });
    }
  }
  
  // Generate connectors (edges between adjacent cells)
  const connectors: PrintableConnector[] = [];
  const addedEdges = new Set<string>();
  
  for (let row = 0; row < gridSize; row++) {
    for (let col = 0; col < gridSize; col++) {
      const index = row * gridSize + col;
      
      // Right neighbor
      if (col < gridSize - 1) {
        const rightIndex = index + 1;
        const edgeKey = `${Math.min(index, rightIndex)}-${Math.max(index, rightIndex)}`;
        
        if (!addedEdges.has(edgeKey)) {
          addedEdges.add(edgeKey);
          connectors.push({
            fromIndex: index,
            toIndex: rightIndex,
            inSolution: solutionEdges.has(`${index}-${rightIndex}`),
          });
        }
      }
      
      // Bottom neighbor
      if (row < gridSize - 1) {
        const bottomIndex = index + gridSize;
        const edgeKey = `${Math.min(index, bottomIndex)}-${Math.max(index, bottomIndex)}`;
        
        if (!addedEdges.has(edgeKey)) {
          addedEdges.add(edgeKey);
          connectors.push({
            fromIndex: index,
            toIndex: bottomIndex,
            inSolution: solutionEdges.has(`${index}-${bottomIndex}`),
          });
        }
      }
    }
  }
  
  return {
    id: `puzzle-${puzzleNumber}-${Date.now()}`,
    puzzleNumber,
    difficulty,
    difficultyName: DIFFICULTY_NAMES[difficulty] || `Level ${difficulty + 1}`,
    gridSize,
    cells,
    connectors,
    targetSum,
    solution,
  };
}

/**
 * Generates a unique ID for a puzzle batch.
 */
export function generateBatchId(): string {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 6);
  return `batch-${timestamp}-${random}`;
}

/**
 * Validates print configuration.
 */
export function validatePrintConfig(config: Partial<PrintConfig>): string[] {
  const errors: string[] = [];
  
  if (config.difficulty !== undefined) {
    if (config.difficulty < 0 || config.difficulty > 9) {
      errors.push('Difficulty must be between 0 and 9');
    }
  }
  
  if (config.puzzleCount !== undefined) {
    if (config.puzzleCount < 1 || config.puzzleCount > 100) {
      errors.push('Puzzle count must be between 1 and 100');
    }
  }
  
  if (config.cellSize !== undefined) {
    if (config.cellSize < 8 || config.cellSize > 20) {
      errors.push('Cell size must be between 8mm and 20mm');
    }
  }
  
  return errors;
}
```

Export all functions.
```

---

## Subphase 8.3: SVG Print Renderer

### Prompt for Claude Code:

```
Create an SVG renderer for print-quality puzzle output.

File: src/modules/circuit-challenge/services/svgRenderer.ts

```typescript
import type { 
  PrintablePuzzle, 
  PrintConfig, 
  PageLayout,
  A4_PORTRAIT 
} from '../types/print';

/**
 * Renders a single puzzle as an SVG string.
 * Optimised for black & white printing.
 */
export function renderPuzzleSVG(
  puzzle: PrintablePuzzle,
  config: PrintConfig,
  showSolution: boolean = false
): string {
  const { gridSize, cells, connectors, targetSum } = puzzle;
  const cellSize = config.cellSize;
  const lineWidth = config.lineWidth;
  
  // Calculate dimensions
  const gridWidth = gridSize * cellSize;
  const gridHeight = gridSize * cellSize;
  const padding = cellSize; // Padding around grid
  const headerHeight = 15; // Space for puzzle number and target
  
  const svgWidth = gridWidth + padding * 2;
  const svgHeight = gridHeight + padding * 2 + headerHeight;
  
  // Start SVG
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${svgWidth} ${svgHeight}" width="${svgWidth}mm" height="${svgHeight}mm">`;
  
  // Add styles
  svg += `
    <style>
      .cell-text { 
        font-family: Arial, sans-serif; 
        font-size: ${config.fontSize}pt; 
        font-weight: bold;
        text-anchor: middle; 
        dominant-baseline: central;
      }
      .header-text {
        font-family: Arial, sans-serif;
        font-size: ${config.fontSize - 1}pt;
      }
      .target-text {
        font-family: Arial, sans-serif;
        font-size: ${config.fontSize + 2}pt;
        font-weight: bold;
      }
      .connector { 
        stroke: #000; 
        stroke-width: ${lineWidth}mm;
        stroke-linecap: round;
      }
      .connector-solution {
        stroke: #000;
        stroke-width: ${lineWidth * 3}mm;
        stroke-linecap: round;
      }
      .cell-border {
        fill: white;
        stroke: #000;
        stroke-width: ${lineWidth}mm;
      }
      .cell-start, .cell-end {
        fill: #e0e0e0;
        stroke: #000;
        stroke-width: ${lineWidth * 1.5}mm;
      }
      .cell-solution {
        fill: #f0f0f0;
      }
    </style>
  `;
  
  // Grid offset (accounting for padding and header)
  const gridOffsetX = padding;
  const gridOffsetY = padding + headerHeight;
  
  // Header: Puzzle number and target sum
  if (config.showPuzzleNumber) {
    svg += `<text x="${padding}" y="${padding}" class="header-text">Puzzle ${puzzle.puzzleNumber}</text>`;
  }
  
  svg += `<text x="${svgWidth - padding}" y="${padding}" class="target-text" text-anchor="end">Target: ${targetSum}</text>`;
  
  if (config.showDifficulty) {
    svg += `<text x="${padding}" y="${padding + 8}" class="header-text" style="font-size: ${config.fontSize - 2}pt; fill: #666;">${puzzle.difficultyName}</text>`;
  }
  
  // Draw connectors first (under cells)
  for (const connector of connectors) {
    const fromCell = cells[connector.fromIndex];
    const toCell = cells[connector.toIndex];
    
    const x1 = gridOffsetX + fromCell.col * cellSize + cellSize / 2;
    const y1 = gridOffsetY + fromCell.row * cellSize + cellSize / 2;
    const x2 = gridOffsetX + toCell.col * cellSize + cellSize / 2;
    const y2 = gridOffsetY + toCell.row * cellSize + cellSize / 2;
    
    // Determine if this connector should be highlighted (solution mode)
    const isSolutionConnector = showSolution && connector.inSolution;
    const connectorClass = isSolutionConnector ? 'connector-solution' : 'connector';
    
    svg += `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" class="${connectorClass}" />`;
  }
  
  // Draw cells (hexagons rendered as circles for simplicity in print)
  for (const cell of cells) {
    const cx = gridOffsetX + cell.col * cellSize + cellSize / 2;
    const cy = gridOffsetY + cell.row * cellSize + cellSize / 2;
    const radius = cellSize * 0.4;
    
    // Determine cell class
    let cellClass = 'cell-border';
    if (cell.isStart || cell.isEnd) {
      cellClass = 'cell-start';
    } else if (showSolution && cell.inSolution) {
      cellClass = 'cell-border cell-solution';
    }
    
    // Draw cell circle
    svg += `<circle cx="${cx}" cy="${cy}" r="${radius}" class="${cellClass}" />`;
    
    // Draw start/end markers
    if (cell.isStart) {
      svg += `<text x="${cx}" y="${cy - radius - 3}" class="header-text" text-anchor="middle" style="font-size: 7pt;">START</text>`;
    }
    if (cell.isEnd) {
      svg += `<text x="${cx}" y="${cy + radius + 6}" class="header-text" text-anchor="middle" style="font-size: 7pt;">END</text>`;
    }
    
    // Draw cell value
    svg += `<text x="${cx}" y="${cy}" class="cell-text">${cell.value}</text>`;
  }
  
  svg += '</svg>';
  
  return svg;
}

/**
 * Renders a full A4 page with 1 or 2 puzzles.
 */
export function renderPageSVG(
  puzzles: PrintablePuzzle[],
  config: PrintConfig,
  pageNumber: number,
  totalPages: number,
  showSolutions: boolean = false
): string {
  const layout = A4_PORTRAIT;
  
  // SVG dimensions in mm
  const svgWidth = layout.width;
  const svgHeight = layout.height;
  
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${svgWidth} ${svgHeight}" width="${svgWidth}mm" height="${svgHeight}mm">`;
  
  // White background
  svg += `<rect width="100%" height="100%" fill="white" />`;
  
  // Page styles
  svg += `
    <style>
      .page-title {
        font-family: Arial, sans-serif;
        font-size: 14pt;
        font-weight: bold;
      }
      .page-subtitle {
        font-family: Arial, sans-serif;
        font-size: 10pt;
        fill: #666;
      }
      .page-footer {
        font-family: Arial, sans-serif;
        font-size: 8pt;
        fill: #999;
      }
    </style>
  `;
  
  // Page header
  let headerY = layout.marginTop;
  
  if (config.title) {
    svg += `<text x="${layout.marginLeft}" y="${headerY}" class="page-title">${escapeXml(config.title)}</text>`;
    headerY += 6;
  }
  
  if (config.subtitle) {
    svg += `<text x="${layout.marginLeft}" y="${headerY}" class="page-subtitle">${escapeXml(config.subtitle)}</text>`;
    headerY += 5;
  }
  
  if (config.showDate) {
    const dateStr = new Date().toLocaleDateString('en-GB', { 
      day: 'numeric', 
      month: 'long', 
      year: 'numeric' 
    });
    svg += `<text x="${svgWidth - layout.marginRight}" y="${layout.marginTop}" class="page-subtitle" text-anchor="end">${dateStr}</text>`;
  }
  
  // Calculate puzzle positioning
  const puzzleAreaTop = headerY + 10;
  const puzzleAreaHeight = layout.contentHeight - (puzzleAreaTop - layout.marginTop) - 10;
  
  if (config.puzzlesPerPage === 2 && puzzles.length === 2) {
    // Two puzzles per page
    const puzzleHeight = (puzzleAreaHeight - config.cellSize) / 2;
    
    // Puzzle 1
    const puzzle1SVG = renderPuzzleSVG(puzzles[0], config, showSolutions);
    svg += `<g transform="translate(${layout.marginLeft}, ${puzzleAreaTop})">${extractSVGContent(puzzle1SVG)}</g>`;
    
    // Puzzle 2
    const puzzle2SVG = renderPuzzleSVG(puzzles[1], config, showSolutions);
    svg += `<g transform="translate(${layout.marginLeft}, ${puzzleAreaTop + puzzleHeight + config.cellSize})">${extractSVGContent(puzzle2SVG)}</g>`;
    
  } else if (puzzles.length >= 1) {
    // One puzzle per page (centered)
    const puzzleSVG = renderPuzzleSVG(puzzles[0], config, showSolutions);
    svg += `<g transform="translate(${layout.marginLeft}, ${puzzleAreaTop})">${extractSVGContent(puzzleSVG)}</g>`;
  }
  
  // Page footer
  if (config.showPageNumbers) {
    svg += `<text x="${svgWidth / 2}" y="${svgHeight - layout.marginBottom + 8}" class="page-footer" text-anchor="middle">Page ${pageNumber} of ${totalPages}</text>`;
  }
  
  // Answer indicator
  if (showSolutions) {
    svg += `<text x="${svgWidth - layout.marginRight}" y="${svgHeight - layout.marginBottom + 8}" class="page-footer" text-anchor="end">ANSWER KEY</text>`;
  }
  
  svg += '</svg>';
  
  return svg;
}

/**
 * Extracts the inner content from an SVG string (removes outer svg tags).
 */
function extractSVGContent(svg: string): string {
  // Remove the outer <svg> and </svg> tags
  return svg
    .replace(/<svg[^>]*>/, '')
    .replace(/<\/svg>$/, '');
}

/**
 * Escapes XML special characters.
 */
function escapeXml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

/**
 * Generates all pages for a puzzle batch.
 */
export function renderAllPages(
  puzzles: PrintablePuzzle[],
  config: PrintConfig
): { questionPages: string[]; answerPages: string[] } {
  const questionPages: string[] = [];
  const answerPages: string[] = [];
  
  const puzzlesPerPage = config.puzzlesPerPage;
  const totalQuestionPages = Math.ceil(puzzles.length / puzzlesPerPage);
  
  // Generate question pages
  for (let i = 0; i < puzzles.length; i += puzzlesPerPage) {
    const pagePuzzles = puzzles.slice(i, i + puzzlesPerPage);
    const pageNumber = Math.floor(i / puzzlesPerPage) + 1;
    
    const pageSVG = renderPageSVG(
      pagePuzzles, 
      config, 
      pageNumber, 
      totalQuestionPages,
      false
    );
    questionPages.push(pageSVG);
  }
  
  // Generate answer pages if requested
  if (config.showAnswers) {
    const totalAnswerPages = Math.ceil(puzzles.length / puzzlesPerPage);
    
    for (let i = 0; i < puzzles.length; i += puzzlesPerPage) {
      const pagePuzzles = puzzles.slice(i, i + puzzlesPerPage);
      const pageNumber = Math.floor(i / puzzlesPerPage) + 1;
      
      const pageSVG = renderPageSVG(
        pagePuzzles,
        config,
        pageNumber,
        totalAnswerPages,
        true // Show solutions
      );
      answerPages.push(pageSVG);
    }
  }
  
  return { questionPages, answerPages };
}
```

Export all functions.
```

---

## Subphase 8.4: PDF Generation Service

### Prompt for Claude Code:

```
Create a service to convert SVG pages to a printable PDF.

File: src/modules/circuit-challenge/services/pdfGenerator.ts

```typescript
import { jsPDF } from 'jspdf';
import 'svg2pdf.js';
import type { PrintConfig, PageLayout, A4_PORTRAIT } from '../types/print';

/**
 * Generates a PDF from SVG page strings.
 * Uses jsPDF with svg2pdf.js for high-quality vector output.
 */
export async function generatePDF(
  questionPages: string[],
  answerPages: string[],
  config: PrintConfig
): Promise<Blob> {
  // Create PDF document
  const pdf = new jsPDF({
    orientation: config.orientation,
    unit: 'mm',
    format: config.pageSize.toLowerCase() as 'a4' | 'letter',
  });
  
  const layout = A4_PORTRAIT;
  
  // Add question pages
  for (let i = 0; i < questionPages.length; i++) {
    if (i > 0) {
      pdf.addPage();
    }
    
    await addSVGPageToPDF(pdf, questionPages[i], layout);
  }
  
  // Add answer pages if present
  if (answerPages.length > 0) {
    // Add a separator page (optional)
    pdf.addPage();
    pdf.setFontSize(24);
    pdf.text('Answer Key', layout.width / 2, layout.height / 2, { align: 'center' });
    
    for (const answerPage of answerPages) {
      pdf.addPage();
      await addSVGPageToPDF(pdf, answerPage, layout);
    }
  }
  
  // Return as blob
  return pdf.output('blob');
}

/**
 * Adds a single SVG page to the PDF document.
 */
async function addSVGPageToPDF(
  pdf: jsPDF,
  svgString: string,
  layout: PageLayout
): Promise<void> {
  // Parse SVG string to DOM element
  const parser = new DOMParser();
  const svgDoc = parser.parseFromString(svgString, 'image/svg+xml');
  const svgElement = svgDoc.documentElement;
  
  // Use svg2pdf to add the SVG to the PDF
  await pdf.svg(svgElement, {
    x: 0,
    y: 0,
    width: layout.width,
    height: layout.height,
  });
}

/**
 * Alternative: Generate PDF using canvas rendering.
 * Fallback for browsers without svg2pdf support.
 */
export async function generatePDFCanvas(
  questionPages: string[],
  answerPages: string[],
  config: PrintConfig
): Promise<Blob> {
  const pdf = new jsPDF({
    orientation: config.orientation,
    unit: 'mm',
    format: config.pageSize.toLowerCase() as 'a4' | 'letter',
  });
  
  const layout = A4_PORTRAIT;
  
  // Process each page
  const allPages = [...questionPages, ...answerPages];
  
  for (let i = 0; i < allPages.length; i++) {
    if (i > 0) {
      pdf.addPage();
    }
    
    // Convert SVG to image via canvas
    const imgData = await svgToDataURL(allPages[i], layout.width * 4, layout.height * 4);
    
    // Add image to PDF
    pdf.addImage(imgData, 'PNG', 0, 0, layout.width, layout.height);
  }
  
  return pdf.output('blob');
}

/**
 * Converts an SVG string to a data URL via canvas.
 */
async function svgToDataURL(
  svgString: string,
  width: number,
  height: number
): Promise<string> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const blob = new Blob([svgString], { type: 'image/svg+xml' });
    const url = URL.createObjectURL(blob);
    
    img.onload = () => {
      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      
      const ctx = canvas.getContext('2d');
      if (!ctx) {
        reject(new Error('Canvas context not available'));
        return;
      }
      
      // White background
      ctx.fillStyle = 'white';
      ctx.fillRect(0, 0, width, height);
      
      // Draw SVG
      ctx.drawImage(img, 0, 0, width, height);
      
      URL.revokeObjectURL(url);
      resolve(canvas.toDataURL('image/png'));
    };
    
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Failed to load SVG'));
    };
    
    img.src = url;
  });
}

/**
 * Triggers a download of the PDF blob.
 */
export function downloadPDF(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/**
 * Opens the PDF in a new browser tab for preview.
 */
export function previewPDF(blob: Blob): void {
  const url = URL.createObjectURL(blob);
  window.open(url, '_blank');
}
```

Export all functions.

Note: This requires installing jsPDF and svg2pdf.js:
```bash
npm install jspdf svg2pdf.js
```
```

---

## Subphase 8.5: Puzzle Maker Screen

### Prompt for Claude Code:

```
Create the main Puzzle Maker screen for teachers.

File: src/modules/circuit-challenge/screens/PuzzleMakerScreen.tsx

```typescript
import React, { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Card, Modal } from '@/ui';
import { Header } from '@/hub/components';
import { PuzzlePreview } from '../components/PuzzlePreview';
import { generatePrintablePuzzles, generateBatchId } from '../services/printGenerator';
import { renderAllPages } from '../services/svgRenderer';
import { generatePDF, downloadPDF, previewPDF } from '../services/pdfGenerator';
import { 
  DEFAULT_PRINT_CONFIG, 
  DIFFICULTY_NAMES,
  type PrintConfig, 
  type PrintablePuzzle 
} from '../types/print';

export function PuzzleMakerScreen() {
  const navigate = useNavigate();
  
  // Configuration state
  const [config, setConfig] = useState<PrintConfig>(DEFAULT_PRINT_CONFIG);
  
  // Generation state
  const [puzzles, setPuzzles] = useState<PrintablePuzzle[]>([]);
  const [isGenerating, setIsGenerating] = useState(false);
  const [isExporting, setIsExporting] = useState(false);
  const [previewIndex, setPreviewIndex] = useState(0);
  
  // Modal state
  const [showPreviewModal, setShowPreviewModal] = useState(false);
  
  // Update config helper
  const updateConfig = (updates: Partial<PrintConfig>) => {
    setConfig((prev) => ({ ...prev, ...updates }));
    // Clear puzzles when config changes
    setPuzzles([]);
  };
  
  // Generate puzzles
  const handleGenerate = useCallback(() => {
    setIsGenerating(true);
    
    // Use setTimeout to allow UI to update
    setTimeout(() => {
      try {
        const newPuzzles = generatePrintablePuzzles(config);
        setPuzzles(newPuzzles);
        setPreviewIndex(0);
      } catch (err) {
        console.error('Error generating puzzles:', err);
      } finally {
        setIsGenerating(false);
      }
    }, 100);
  }, [config]);
  
  // Export to PDF
  const handleExportPDF = useCallback(async () => {
    if (puzzles.length === 0) return;
    
    setIsExporting(true);
    
    try {
      // Render all pages
      const { questionPages, answerPages } = renderAllPages(puzzles, config);
      
      // Generate PDF
      const pdfBlob = await generatePDF(questionPages, answerPages, config);
      
      // Create filename
      const date = new Date().toISOString().split('T')[0];
      const difficulty = DIFFICULTY_NAMES[config.difficulty] || 'Mixed';
      const filename = `Circuit-Challenge-${difficulty}-${config.puzzleCount}puzzles-${date}.pdf`;
      
      // Download
      downloadPDF(pdfBlob, filename);
      
    } catch (err) {
      console.error('Error exporting PDF:', err);
    } finally {
      setIsExporting(false);
    }
  }, [puzzles, config]);
  
  // Preview PDF
  const handlePreviewPDF = useCallback(async () => {
    if (puzzles.length === 0) return;
    
    setIsExporting(true);
    
    try {
      const { questionPages, answerPages } = renderAllPages(puzzles, config);
      const pdfBlob = await generatePDF(questionPages, answerPages, config);
      previewPDF(pdfBlob);
    } catch (err) {
      console.error('Error previewing PDF:', err);
    } finally {
      setIsExporting(false);
    }
  }, [puzzles, config]);
  
  // Calculate stats
  const totalPages = Math.ceil(puzzles.length / config.puzzlesPerPage);
  const totalPagesWithAnswers = config.showAnswers ? totalPages * 2 + 1 : totalPages;
  
  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Puzzle Maker" showBack />
      
      <main className="flex-1 p-4 md:p-8">
        <div className="max-w-4xl mx-auto">
          
          {/* Introduction */}
          <Card className="p-6 mb-6">
            <h2 className="text-xl font-bold mb-2">🖨️ Create Printable Worksheets</h2>
            <p className="text-text-secondary">
              Generate professional Circuit Challenge worksheets perfect for classroom use. 
              Each A4 page contains 2 puzzles, optimised for black & white printing.
            </p>
          </Card>
          
          {/* Configuration */}
          <div className="grid md:grid-cols-2 gap-6 mb-6">
            
            {/* Puzzle Settings */}
            <Card className="p-4">
              <h3 className="font-bold mb-4">Puzzle Settings</h3>
              
              {/* Difficulty */}
              <div className="mb-4">
                <label className="block text-sm font-medium mb-2">
                  Difficulty Level
                </label>
                <select
                  value={config.difficulty}
                  onChange={(e) => updateConfig({ difficulty: Number(e.target.value) })}
                  className="w-full px-3 py-2 rounded-lg bg-background-dark border border-white/20 focus:border-accent-primary outline-none"
                >
                  {Object.entries(DIFFICULTY_NAMES).map(([level, name]) => (
                    <option key={level} value={level}>
                      {name} (Level {Number(level) + 1})
                    </option>
                  ))}
                </select>
              </div>
              
              {/* Puzzle Count */}
              <div className="mb-4">
                <label className="block text-sm font-medium mb-2">
                  Number of Puzzles: {config.puzzleCount}
                </label>
                <input
                  type="range"
                  min={2}
                  max={50}
                  step={2}
                  value={config.puzzleCount}
                  onChange={(e) => updateConfig({ puzzleCount: Number(e.target.value) })}
                  className="w-full"
                />
                <div className="flex justify-between text-xs text-text-secondary">
                  <span>2</span>
                  <span>50</span>
                </div>
              </div>
              
              {/* Include Answers */}
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={config.showAnswers}
                  onChange={(e) => updateConfig({ showAnswers: e.target.checked })}
                  className="w-5 h-5 rounded"
                />
                <span>Include answer key pages</span>
              </label>
            </Card>
            
            {/* Page Settings */}
            <Card className="p-4">
              <h3 className="font-bold mb-4">Page Settings</h3>
              
              {/* Title */}
              <div className="mb-4">
                <label className="block text-sm font-medium mb-2">
                  Worksheet Title
                </label>
                <input
                  type="text"
                  value={config.title}
                  onChange={(e) => updateConfig({ title: e.target.value })}
                  placeholder="Circuit Challenge"
                  className="w-full px-3 py-2 rounded-lg bg-background-dark border border-white/20 focus:border-accent-primary outline-none"
                />
              </div>
              
              {/* Subtitle */}
              <div className="mb-4">
                <label className="block text-sm font-medium mb-2">
                  Subtitle (optional)
                </label>
                <input
                  type="text"
                  value={config.subtitle}
                  onChange={(e) => updateConfig({ subtitle: e.target.value })}
                  placeholder="e.g., Year 5 Maths - Week 3"
                  className="w-full px-3 py-2 rounded-lg bg-background-dark border border-white/20 focus:border-accent-primary outline-none"
                />
              </div>
              
              {/* Options */}
              <div className="space-y-2">
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={config.showDate}
                    onChange={(e) => updateConfig({ showDate: e.target.checked })}
                    className="w-5 h-5 rounded"
                  />
                  <span>Show date on pages</span>
                </label>
                
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={config.showPageNumbers}
                    onChange={(e) => updateConfig({ showPageNumbers: e.target.checked })}
                    className="w-5 h-5 rounded"
                  />
                  <span>Show page numbers</span>
                </label>
                
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={config.showDifficulty}
                    onChange={(e) => updateConfig({ showDifficulty: e.target.checked })}
                    className="w-5 h-5 rounded"
                  />
                  <span>Show difficulty label</span>
                </label>
              </div>
            </Card>
          </div>
          
          {/* Generate Button */}
          <div className="mb-6">
            <Button
              variant="primary"
              fullWidth
              size="lg"
              onClick={handleGenerate}
              loading={isGenerating}
              disabled={isGenerating}
            >
              {isGenerating 
                ? 'Generating Puzzles...' 
                : `Generate ${config.puzzleCount} Puzzles`}
            </Button>
          </div>
          
          {/* Preview Section */}
          {puzzles.length > 0 && (
            <Card className="p-4 mb-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-bold">Preview</h3>
                <span className="text-sm text-text-secondary">
                  {puzzles.length} puzzles • {totalPages} pages
                  {config.showAnswers && ` + ${totalPages} answer pages`}
                </span>
              </div>
              
              {/* Puzzle Navigator */}
              <div className="flex items-center justify-between mb-4">
                <Button
                  variant="ghost"
                  onClick={() => setPreviewIndex(Math.max(0, previewIndex - 1))}
                  disabled={previewIndex === 0}
                >
                  ← Previous
                </Button>
                
                <span className="text-sm">
                  Puzzle {previewIndex + 1} of {puzzles.length}
                </span>
                
                <Button
                  variant="ghost"
                  onClick={() => setPreviewIndex(Math.min(puzzles.length - 1, previewIndex + 1))}
                  disabled={previewIndex === puzzles.length - 1}
                >
                  Next →
                </Button>
              </div>
              
              {/* Puzzle Preview */}
              <div className="bg-white rounded-lg p-4 mb-4">
                <PuzzlePreview 
                  puzzle={puzzles[previewIndex]} 
                  config={config}
                  showSolution={false}
                />
              </div>
              
              {/* Full Page Preview Button */}
              <Button
                variant="secondary"
                fullWidth
                onClick={() => setShowPreviewModal(true)}
              >
                👁️ Full Page Preview
              </Button>
            </Card>
          )}
          
          {/* Export Buttons */}
          {puzzles.length > 0 && (
            <div className="space-y-3">
              <Button
                variant="primary"
                fullWidth
                size="lg"
                onClick={handleExportPDF}
                loading={isExporting}
                disabled={isExporting}
              >
                📄 Download PDF ({totalPagesWithAnswers} pages)
              </Button>
              
              <Button
                variant="secondary"
                fullWidth
                onClick={handlePreviewPDF}
                disabled={isExporting}
              >
                👁️ Preview PDF in Browser
              </Button>
            </div>
          )}
          
          {/* Tips */}
          <Card className="p-4 mt-6 bg-accent-primary/10">
            <h3 className="font-bold mb-2">💡 Tips for Teachers</h3>
            <ul className="text-sm text-text-secondary space-y-1">
              <li>• 2 puzzles per A4 page = easy to cut in half for individual work</li>
              <li>• Black & white design = perfect for photocopying</li>
              <li>• Answer key at the back for quick marking</li>
              <li>• Mix difficulty levels by generating multiple batches</li>
            </ul>
          </Card>
          
        </div>
      </main>
      
      {/* Full Page Preview Modal */}
      <Modal
        isOpen={showPreviewModal}
        onClose={() => setShowPreviewModal(false)}
        title="Page Preview"
        size="lg"
      >
        <div className="bg-white rounded-lg p-2 overflow-auto max-h-[70vh]">
          {/* Render a sample page */}
          {puzzles.length >= 2 && (
            <div 
              className="border border-gray-300"
              dangerouslySetInnerHTML={{
                __html: renderAllPages(
                  puzzles.slice(0, 2), 
                  { ...config, puzzleCount: 2 }
                ).questionPages[0]
              }}
            />
          )}
        </div>
      </Modal>
    </div>
  );
}

export default PuzzleMakerScreen;
```

Export PuzzleMakerScreen component.
```

---

## Subphase 8.6: Puzzle Preview Component

### Prompt for Claude Code:

```
Create a preview component for individual puzzles in the maker.

File: src/modules/circuit-challenge/components/PuzzlePreview.tsx

```typescript
import React from 'react';
import type { PrintablePuzzle, PrintConfig } from '../types/print';

interface PuzzlePreviewProps {
  puzzle: PrintablePuzzle;
  config: PrintConfig;
  showSolution?: boolean;
}

/**
 * Renders a preview of a single printable puzzle.
 * Used in the Puzzle Maker screen.
 */
export function PuzzlePreview({ 
  puzzle, 
  config, 
  showSolution = false 
}: PuzzlePreviewProps) {
  const { gridSize, cells, connectors, targetSum } = puzzle;
  
  // Calculate dimensions
  const cellSize = 40; // px for preview
  const gridWidth = gridSize * cellSize;
  const gridHeight = gridSize * cellSize;
  const padding = 20;
  
  const svgWidth = gridWidth + padding * 2;
  const svgHeight = gridHeight + padding * 2;
  
  // Create solution set for highlighting
  const solutionSet = new Set(puzzle.solution);
  const solutionEdges = new Set<string>();
  for (let i = 0; i < puzzle.solution.length - 1; i++) {
    const from = puzzle.solution[i];
    const to = puzzle.solution[i + 1];
    solutionEdges.add(`${from}-${to}`);
    solutionEdges.add(`${to}-${from}`);
  }
  
  return (
    <div className="flex flex-col items-center">
      {/* Header */}
      <div className="flex justify-between w-full mb-2 px-2">
        <div className="text-sm text-gray-600">
          {config.showPuzzleNumber && `Puzzle ${puzzle.puzzleNumber}`}
          {config.showDifficulty && (
            <span className="ml-2 text-gray-400">({puzzle.difficultyName})</span>
          )}
        </div>
        <div className="text-lg font-bold text-gray-800">
          Target: {targetSum}
        </div>
      </div>
      
      {/* Grid */}
      <svg 
        width={svgWidth} 
        height={svgHeight}
        viewBox={`0 0 ${svgWidth} ${svgHeight}`}
        className="border border-gray-200 rounded"
      >
        {/* Background */}
        <rect width="100%" height="100%" fill="white" />
        
        {/* Connectors */}
        {connectors.map((connector, i) => {
          const fromCell = cells[connector.fromIndex];
          const toCell = cells[connector.toIndex];
          
          const x1 = padding + fromCell.col * cellSize + cellSize / 2;
          const y1 = padding + fromCell.row * cellSize + cellSize / 2;
          const x2 = padding + toCell.col * cellSize + cellSize / 2;
          const y2 = padding + toCell.row * cellSize + cellSize / 2;
          
          const isInSolution = showSolution && 
            solutionEdges.has(`${connector.fromIndex}-${connector.toIndex}`);
          
          return (
            <line
              key={`connector-${i}`}
              x1={x1}
              y1={y1}
              x2={x2}
              y2={y2}
              stroke={isInSolution ? '#000' : '#ccc'}
              strokeWidth={isInSolution ? 4 : 2}
              strokeLinecap="round"
            />
          );
        })}
        
        {/* Cells */}
        {cells.map((cell) => {
          const cx = padding + cell.col * cellSize + cellSize / 2;
          const cy = padding + cell.row * cellSize + cellSize / 2;
          const radius = cellSize * 0.35;
          
          const isInSolution = showSolution && solutionSet.has(cell.index);
          
          // Determine fill color
          let fill = 'white';
          if (cell.isStart || cell.isEnd) {
            fill = '#e5e5e5';
          } else if (isInSolution) {
            fill = '#f0f0f0';
          }
          
          return (
            <g key={`cell-${cell.index}`}>
              {/* Cell circle */}
              <circle
                cx={cx}
                cy={cy}
                r={radius}
                fill={fill}
                stroke="#000"
                strokeWidth={cell.isStart || cell.isEnd ? 2.5 : 1.5}
              />
              
              {/* Cell value */}
              <text
                x={cx}
                y={cy}
                textAnchor="middle"
                dominantBaseline="central"
                fontSize={14}
                fontWeight="bold"
                fill="#000"
              >
                {cell.value}
              </text>
              
              {/* Start/End labels */}
              {cell.isStart && (
                <text
                  x={cx}
                  y={cy - radius - 8}
                  textAnchor="middle"
                  fontSize={9}
                  fill="#666"
                >
                  START
                </text>
              )}
              {cell.isEnd && (
                <text
                  x={cx}
                  y={cy + radius + 12}
                  textAnchor="middle"
                  fontSize={9}
                  fill="#666"
                >
                  END
                </text>
              )}
            </g>
          );
        })}
      </svg>
      
      {/* Solution indicator */}
      {showSolution && (
        <div className="mt-2 text-sm text-green-600 font-medium">
          ✓ Solution shown
        </div>
      )}
    </div>
  );
}

export default PuzzlePreview;
```

Export PuzzlePreview component.
```

---

## Subphase 8.7: Print Route and Navigation

### Prompt for Claude Code:

```
Add the Puzzle Maker route and navigation entry point.

1. Update src/app/routes.tsx:

```typescript
// Add import
import { PuzzleMakerScreen } from '@/modules/circuit-challenge/screens/PuzzleMakerScreen';

// Add route
{
  path: '/circuit-challenge/maker',
  element: <PuzzleMakerScreen />,
},
```

2. Update src/modules/circuit-challenge/screens/index.ts:

```typescript
export { GameScreen } from './GameScreen';
export { PuzzleMakerScreen } from './PuzzleMakerScreen';
```

3. Add navigation to Module Select or Main Hub:

In ModuleSelectScreen.tsx, add a "For Teachers" section:

```typescript
{/* Teacher Tools Section */}
<div className="mt-8 pt-8 border-t border-white/10">
  <h3 className="text-lg font-bold mb-4 text-text-secondary">
    🍎 For Teachers
  </h3>
  
  <Card
    variant="interactive"
    className="p-4"
    onClick={() => navigate('/circuit-challenge/maker')}
  >
    <div className="flex items-center gap-4">
      <span className="text-4xl">🖨️</span>
      <div className="flex-1">
        <h4 className="font-bold">Puzzle Maker</h4>
        <p className="text-sm text-text-secondary">
          Generate printable worksheets for classroom use
        </p>
      </div>
      <span className="text-2xl text-text-secondary">→</span>
    </div>
  </Card>
</div>
```

4. Update src/modules/circuit-challenge/components/index.ts:

```typescript
export { HexCell } from './HexCell';
export { HexGrid } from './HexGrid';
export { Connector } from './Connector';
export { CoinDisplay } from './CoinDisplay';
export { PuzzlePreview } from './PuzzlePreview';
```

5. Update src/modules/circuit-challenge/types/index.ts:

```typescript
export * from './game';
export * from './print';
```

6. Update src/modules/circuit-challenge/services/index.ts:

```typescript
export * from './printGenerator';
export * from './svgRenderer';
export * from './pdfGenerator';
```

7. Test the complete print workflow:
   - Navigate to Module Select
   - Click "Puzzle Maker" in For Teachers section
   - Configure difficulty and puzzle count
   - Generate puzzles
   - Preview individual puzzles
   - View full page preview
   - Download PDF
   - Verify PDF contains correct number of pages
   - Verify answer key is included if selected
   - Print a test page to verify black & white quality
```

---

## Subphase 8.8: Package Dependencies

### Prompt for Claude Code:

```
Install required packages for PDF generation.

Run these commands:

```bash
# PDF generation
npm install jspdf svg2pdf.js

# TypeScript types
npm install -D @types/jspdf
```

Verify package.json includes:
```json
{
  "dependencies": {
    "jspdf": "^2.5.1",
    "svg2pdf.js": "^2.2.3"
  }
}
```

If svg2pdf.js causes issues, the fallback canvas method in pdfGenerator.ts will work.
```

---

## Phase 8 Completion Checklist

After completing all subphases, verify:

- [ ] Print types and config defined correctly
- [ ] generatePrintablePuzzles creates correct puzzle format
- [ ] Puzzles have correct start/end cells marked
- [ ] Connectors track solution path correctly
- [ ] renderPuzzleSVG creates valid SVG output
- [ ] SVG is black & white only (no colors)
- [ ] renderPageSVG creates full A4 page
- [ ] 2 puzzles fit properly on one page
- [ ] Page header shows title, subtitle, date
- [ ] Page footer shows page numbers
- [ ] Answer pages highlight solution path
- [ ] PDF generates without errors
- [ ] PDF downloads with correct filename
- [ ] PDF preview opens in new tab
- [ ] Puzzle Maker screen loads correctly
- [ ] Difficulty selector works
- [ ] Puzzle count slider works
- [ ] Generate button creates puzzles
- [ ] Preview navigation works
- [ ] Full page preview modal works
- [ ] Print output is photocopy-friendly

---

## Files Created in Phase 8

```
src/modules/circuit-challenge/
├── types/
│   └── print.ts
├── services/
│   ├── printGenerator.ts
│   ├── svgRenderer.ts
│   └── pdfGenerator.ts
├── screens/
│   └── PuzzleMakerScreen.tsx
└── components/
    └── PuzzlePreview.tsx
```

---

## Print Output Specifications

### Page Layout (A4 Portrait)
```
┌─────────────────────────────────────┐
│  Circuit Challenge          15 Jan  │  <- Header (title + date)
│  Year 5 Maths                       │  <- Subtitle
├─────────────────────────────────────┤
│                                     │
│         ┌─────────────┐             │
│         │  Puzzle 1   │             │
│         │             │             │
│         │   [GRID]    │             │
│         │             │             │
│         └─────────────┘             │
│                                     │
├─────────────────────────────────────┤
│                                     │
│         ┌─────────────┐             │
│         │  Puzzle 2   │             │
│         │             │             │
│         │   [GRID]    │             │
│         │             │             │
│         └─────────────┘             │
│                                     │
├─────────────────────────────────────┤
│              Page 1 of 5            │  <- Footer
└─────────────────────────────────────┘
```

### Black & White Design
- Cell borders: Black (#000)
- Cell fill: White
- Start/End cells: Light grey fill (#e0e0e0)
- Connectors: Black lines
- Solution connectors: Thicker black lines
- Text: Black only
- No gradients, shadows, or colors

### Answer Key
- Same layout as question pages
- Solution path highlighted with:
  - Thicker connector lines
  - Light grey fill on solution cells
- "ANSWER KEY" label in footer

---

*End of Phase 8*
