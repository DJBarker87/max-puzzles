import type {
  PrintablePuzzle,
  PrintConfig,
  PageLayout,
} from '../types/print'
import { A4_PORTRAIT, LETTER_PORTRAIT } from '../types/print'

/**
 * Get the page layout based on config.
 */
function getPageLayout(config: PrintConfig): PageLayout {
  if (config.pageSize === 'Letter') {
    return LETTER_PORTRAIT
  }
  return A4_PORTRAIT
}

/**
 * Hexagon cell dimensions (matching the exemplar template)
 */
const HEX = {
  // Pointy-top hexagon path centered at origin
  path: 'M 0,-26 L 22.5,-13 L 22.5,13 L 0,26 L -22.5,13 L -22.5,-13 Z',
  width: 45,
  height: 52,
  // Spacing between cell centers
  spacingX: 90,
  spacingY: 80,
}

/**
 * Connector badge dimensions
 */
const BADGE = {
  width: 22,
  height: 18,
  rx: 3,
}

/**
 * Determines the connector type based on cell positions
 */
function getConnectorType(
  fromRow: number,
  fromCol: number,
  toRow: number,
  toCol: number
): 'horizontal' | 'vertical' | 'diagonal' {
  if (fromRow === toRow) return 'horizontal'
  if (fromCol === toCol) return 'vertical'
  return 'diagonal'
}

/**
 * Renders a single puzzle as an SVG string matching the print template exemplar.
 * Uses hexagon cells with math expressions and connector value badges.
 */
export function renderPuzzleSVG(
  puzzle: PrintablePuzzle,
  _config: PrintConfig,
  showSolution: boolean = false
): string {
  const { gridRows, gridCols, cells, connectors } = puzzle

  // Calculate SVG dimensions based on grid size
  // Using exemplar positioning: cells at x=45,135,225,315,405 and y=45,125,205,285
  const firstCellX = 45
  const firstCellY = 45
  const svgWidth = firstCellX + (gridCols - 1) * HEX.spacingX + 45
  const svgHeight = firstCellY + (gridRows - 1) * HEX.spacingY + 45

  // Start SVG
  let svg = `<svg class="puzzle-grid" viewBox="0 0 ${svgWidth} ${svgHeight}" preserveAspectRatio="xMidYMid meet">`

  // Add defs with hexagon path
  svg += `
    <defs>
      <path id="hex" d="${HEX.path}"/>
    </defs>
  `

  // Create solution edge set for highlighting
  const solutionEdges = new Set<string>()
  if (showSolution) {
    for (let i = 0; i < puzzle.solution.length - 1; i++) {
      const fromIdx = puzzle.solution[i]
      const toIdx = puzzle.solution[i + 1]
      solutionEdges.add(`${fromIdx}-${toIdx}`)
      solutionEdges.add(`${toIdx}-${fromIdx}`)
    }
  }

  // Helper to get cell center coordinates
  const getCellCenter = (row: number, col: number) => ({
    x: firstCellX + col * HEX.spacingX,
    y: firstCellY + row * HEX.spacingY,
  })

  // Helper to get cell index
  const getCellIndex = (row: number, col: number) => row * gridCols + col

  // Draw connectors first (under cells)
  for (const connector of connectors) {
    const from = getCellCenter(connector.fromRow, connector.fromCol)
    const to = getCellCenter(connector.toRow, connector.toCol)
    const connType = getConnectorType(
      connector.fromRow,
      connector.fromCol,
      connector.toRow,
      connector.toCol
    )

    // Check if this connector is in solution path
    const fromIdx = getCellIndex(connector.fromRow, connector.fromCol)
    const toIdx = getCellIndex(connector.toRow, connector.toCol)
    const isInSolution = solutionEdges.has(`${fromIdx}-${toIdx}`)

    // Calculate line endpoints (shortened to not overlap with cells)
    let x1 = from.x
    let y1 = from.y
    let x2 = to.x
    let y2 = to.y

    // Shorten lines based on connector type
    if (connType === 'horizontal') {
      x1 += 22
      x2 -= 22
    } else if (connType === 'vertical') {
      y1 += 26
      y2 -= 26
    } else {
      // Diagonal - shorten both dimensions
      const dx = to.x > from.x ? 18 : -18
      const dy = to.y > from.y ? 18 : -18
      x1 += dx
      y1 += dy
      x2 -= dx
      y2 -= dy
    }

    // Draw connector line
    const lineClass = isInSolution ? 'connector-line-solution' : 'connector-line'
    svg += `<line class="${lineClass}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"/>`

    // Calculate badge position (midpoint of the line)
    const midX = (from.x + to.x) / 2
    const midY = (from.y + to.y) / 2

    // Draw connector badge (white rectangle with value)
    const badgeX = midX - BADGE.width / 2
    const badgeY = midY - BADGE.height / 2
    svg += `<rect class="connector-badge" x="${badgeX}" y="${badgeY}" width="${BADGE.width}" height="${BADGE.height}" rx="${BADGE.rx}"/>`
    svg += `<text class="connector-text" x="${midX}" y="${midY}">${connector.value}</text>`
  }

  // Draw cells
  for (const cell of cells) {
    const center = getCellCenter(cell.row, cell.col)
    const isInSolution = showSolution && cell.inSolution

    // Determine cell class
    let cellClass = 'cell'
    if (cell.isStart) cellClass += ' cell-start'
    if (cell.isEnd) cellClass += ' cell-finish'
    if (isInSolution && !cell.isStart && !cell.isEnd) cellClass += ' cell-solution'

    // Draw cell group
    svg += `<g class="${cellClass}" transform="translate(${center.x}, ${center.y})">`

    // Draw hexagon
    const outlineClass = isInSolution ? 'cell-outline-solution' : 'cell-outline'
    svg += `<use href="#hex" class="${outlineClass}"/>`

    // Draw START label above cell
    if (cell.isStart) {
      svg += `<text class="cell-label" y="-11">START</text>`
    }

    // Draw cell content
    if (cell.isEnd) {
      // FINISH cell shows "FINISH" text
      svg += `<text class="cell-text" y="2">FINISH</text>`
    } else if (cell.isStart) {
      // START cell shows expression below the START label
      svg += `<text class="cell-text" y="4">${escapeXml(cell.expression)}</text>`
    } else {
      // Normal cells show expression
      svg += `<text class="cell-text" y="2">${escapeXml(cell.expression)}</text>`
    }

    svg += '</g>'
  }

  svg += '</svg>'

  return svg
}

/**
 * Renders a puzzle section (bordered container) for print layout
 */
function renderPuzzleSection(
  puzzle: PrintablePuzzle,
  config: PrintConfig,
  showSolution: boolean = false
): string {
  const puzzleSVG = renderPuzzleSVG(puzzle, config, showSolution)

  return `
    <section class="puzzle-section">
      <div class="puzzle-container">
        ${puzzleSVG}
      </div>
    </section>
  `
}

/**
 * Renders a full A4/Letter page with 1 or 2 puzzles.
 * Outputs complete HTML matching the print template exemplar.
 */
export function renderPageSVG(
  puzzles: PrintablePuzzle[],
  config: PrintConfig,
  pageNumber: number,
  totalPages: number,
  showSolutions: boolean = false
): string {
  const layout = getPageLayout(config)

  // Build page HTML with embedded CSS
  let html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${escapeXml(config.title)} - Page ${pageNumber}</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    @page {
      size: ${config.pageSize} ${config.orientation};
      margin: 10mm;
    }

    body {
      font-family: Arial, Helvetica, sans-serif;
      background: white;
      color: black;
    }

    .page {
      width: ${layout.width - 20}mm;
      height: ${layout.height - 20}mm;
      display: flex;
      flex-direction: column;
      gap: 5mm;
    }

    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      padding-bottom: 3mm;
      border-bottom: 1pt solid #ccc;
    }

    .page-title {
      font-size: 14pt;
      font-weight: bold;
    }

    .page-date {
      font-size: 10pt;
      color: #666;
    }

    .puzzle-section {
      flex: 1;
      display: flex;
      flex-direction: column;
      border: 1.5pt solid black;
      padding: 3mm;
    }

    .puzzle-container {
      flex: 1;
      display: flex;
      justify-content: center;
      align-items: center;
    }

    .puzzle-grid {
      width: 100%;
      height: 100%;
    }

    /* Cell styles */
    .cell-outline {
      fill: white;
      stroke: black;
      stroke-width: 1.5;
    }

    .cell-outline-solution {
      fill: #e8e8e8;
      stroke: black;
      stroke-width: 2;
    }

    .cell-start .cell-outline,
    .cell-finish .cell-outline {
      stroke-width: 2.5;
    }

    .cell-text {
      font-family: Arial, Helvetica, sans-serif;
      font-size: 11px;
      font-weight: 600;
      fill: black;
      text-anchor: middle;
      dominant-baseline: middle;
    }

    .cell-label {
      font-size: 8px;
      font-weight: 700;
      fill: black;
      text-anchor: middle;
      dominant-baseline: hanging;
    }

    /* Connector styles */
    .connector-line {
      stroke: black;
      stroke-width: 1.5;
      fill: none;
    }

    .connector-line-solution {
      stroke: black;
      stroke-width: 3;
      fill: none;
    }

    .connector-badge {
      fill: white;
      stroke: black;
      stroke-width: 1;
    }

    .connector-text {
      font-family: Arial, Helvetica, sans-serif;
      font-size: 9px;
      font-weight: 700;
      fill: black;
      text-anchor: middle;
      dominant-baseline: middle;
    }

    .page-footer {
      display: flex;
      justify-content: center;
      align-items: center;
      padding-top: 2mm;
      font-size: 9pt;
      color: #666;
    }

    .answer-key-label {
      position: absolute;
      right: 0;
      font-size: 9pt;
      color: #999;
    }

    @media print {
      body {
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
      }
      .page {
        page-break-after: always;
      }
      .page:last-child {
        page-break-after: avoid;
      }
    }
  </style>
</head>
<body>
  <div class="page">
`

  // Page header
  html += `<div class="page-header">`
  html += `<span class="page-title">${escapeXml(config.title)}</span>`
  if (config.showDate) {
    const dateStr = new Date().toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    })
    html += `<span class="page-date">${dateStr}</span>`
  }
  html += `</div>`

  // Render puzzles
  if (config.puzzlesPerPage === 2 && puzzles.length === 2) {
    html += renderPuzzleSection(puzzles[0], config, showSolutions)
    html += renderPuzzleSection(puzzles[1], config, showSolutions)
  } else if (puzzles.length >= 1) {
    html += renderPuzzleSection(puzzles[0], config, showSolutions)
  }

  // Page footer
  if (config.showPageNumbers || showSolutions) {
    html += `<div class="page-footer" style="position: relative;">`
    if (config.showPageNumbers) {
      html += `<span>Page ${pageNumber} of ${totalPages}</span>`
    }
    if (showSolutions) {
      html += `<span class="answer-key-label">ANSWER KEY</span>`
    }
    html += `</div>`
  }

  html += `
  </div>
</body>
</html>`

  return html
}

/**
 * Renders a standalone SVG for embedding (without HTML wrapper).
 * Used for preview components.
 */
export function renderPuzzleSVGStandalone(
  puzzle: PrintablePuzzle,
  config: PrintConfig,
  showSolution: boolean = false
): string {
  const svgContent = renderPuzzleSVG(puzzle, config, showSolution)

  // Add styles inline for standalone use
  const styles = `
    <style>
      .cell-outline {
        fill: white;
        stroke: black;
        stroke-width: 1.5;
      }
      .cell-outline-solution {
        fill: #e8e8e8;
        stroke: black;
        stroke-width: 2;
      }
      .cell-start .cell-outline,
      .cell-finish .cell-outline {
        stroke-width: 2.5;
      }
      .cell-text {
        font-family: Arial, Helvetica, sans-serif;
        font-size: 11px;
        font-weight: 600;
        fill: black;
        text-anchor: middle;
        dominant-baseline: middle;
      }
      .cell-label {
        font-size: 8px;
        font-weight: 700;
        fill: black;
        text-anchor: middle;
        dominant-baseline: hanging;
      }
      .connector-line {
        stroke: black;
        stroke-width: 1.5;
        fill: none;
      }
      .connector-line-solution {
        stroke: black;
        stroke-width: 3;
        fill: none;
      }
      .connector-badge {
        fill: white;
        stroke: black;
        stroke-width: 1;
      }
      .connector-text {
        font-family: Arial, Helvetica, sans-serif;
        font-size: 9px;
        font-weight: 700;
        fill: black;
        text-anchor: middle;
        dominant-baseline: middle;
      }
    </style>
  `

  // Insert styles after the opening svg tag
  return svgContent.replace(/<svg([^>]*)>/, `<svg$1>${styles}`)
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
    .replace(/'/g, '&apos;')
}

/**
 * Generates all pages for a puzzle batch.
 */
export function renderAllPages(
  puzzles: PrintablePuzzle[],
  config: PrintConfig
): { questionPages: string[]; answerPages: string[] } {
  const questionPages: string[] = []
  const answerPages: string[] = []

  const puzzlesPerPage = config.puzzlesPerPage
  const totalQuestionPages = Math.ceil(puzzles.length / puzzlesPerPage)

  // Generate question pages
  for (let i = 0; i < puzzles.length; i += puzzlesPerPage) {
    const pagePuzzles = puzzles.slice(i, i + puzzlesPerPage)
    const pageNumber = Math.floor(i / puzzlesPerPage) + 1

    const pageSVG = renderPageSVG(
      pagePuzzles,
      config,
      pageNumber,
      totalQuestionPages,
      false
    )
    questionPages.push(pageSVG)
  }

  // Generate answer pages if requested
  if (config.showAnswers) {
    const totalAnswerPages = Math.ceil(puzzles.length / puzzlesPerPage)

    for (let i = 0; i < puzzles.length; i += puzzlesPerPage) {
      const pagePuzzles = puzzles.slice(i, i + puzzlesPerPage)
      const pageNumber = Math.floor(i / puzzlesPerPage) + 1

      const pageSVG = renderPageSVG(
        pagePuzzles,
        config,
        pageNumber,
        totalAnswerPages,
        true // Show solutions
      )
      answerPages.push(pageSVG)
    }
  }

  return { questionPages, answerPages }
}
