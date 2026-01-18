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
 * Renders a single puzzle as an SVG string.
 * Optimised for black & white printing.
 */
export function renderPuzzleSVG(
  puzzle: PrintablePuzzle,
  config: PrintConfig,
  showSolution: boolean = false
): string {
  const { gridRows, gridCols, cells, connectors, targetSum } = puzzle
  const cellSize = config.cellSize
  const lineWidth = config.lineWidth

  // Calculate dimensions
  const gridWidth = gridCols * cellSize
  const gridHeight = gridRows * cellSize
  const padding = cellSize * 1.5 // Padding around grid for START/END labels
  const headerHeight = 12 // Space for puzzle number and target

  const svgWidth = gridWidth + padding * 2
  const svgHeight = gridHeight + padding * 2 + headerHeight

  // Start SVG
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${svgWidth} ${svgHeight}" width="${svgWidth}mm" height="${svgHeight}mm">`

  // Add styles
  svg += `
    <style>
      .cell-text {
        font-family: Arial, Helvetica, sans-serif;
        font-size: ${config.fontSize * 0.8}pt;
        font-weight: bold;
        text-anchor: middle;
        dominant-baseline: central;
        fill: #000;
      }
      .header-text {
        font-family: Arial, Helvetica, sans-serif;
        font-size: ${config.fontSize - 1}pt;
        fill: #000;
      }
      .target-text {
        font-family: Arial, Helvetica, sans-serif;
        font-size: ${config.fontSize + 1}pt;
        font-weight: bold;
        fill: #000;
      }
      .label-text {
        font-family: Arial, Helvetica, sans-serif;
        font-size: ${config.fontSize * 0.6}pt;
        text-anchor: middle;
        fill: #000;
      }
      .connector {
        stroke: #000;
        stroke-width: ${lineWidth}mm;
        stroke-linecap: round;
        fill: none;
      }
      .connector-solution {
        stroke: #000;
        stroke-width: ${lineWidth * 2.5}mm;
        stroke-linecap: round;
        fill: none;
      }
      .connector-value {
        font-family: Arial, Helvetica, sans-serif;
        font-size: ${config.fontSize * 0.65}pt;
        text-anchor: middle;
        dominant-baseline: central;
        fill: #000;
      }
    </style>
  `

  // Grid offset (accounting for padding and header)
  const gridOffsetX = padding
  const gridOffsetY = padding + headerHeight

  // Header: Puzzle number and target sum
  if (config.showPuzzleNumber) {
    svg += `<text x="${padding}" y="${headerHeight - 2}" class="header-text">Puzzle ${puzzle.puzzleNumber}</text>`
  }

  svg += `<text x="${svgWidth - padding}" y="${headerHeight - 2}" class="target-text" text-anchor="end">Target: ${targetSum}</text>`

  if (config.showDifficulty) {
    svg += `<text x="${padding}" y="${headerHeight + 5}" class="header-text" style="font-size: ${config.fontSize * 0.7}pt; fill: #666;">${puzzle.difficultyName}</text>`
  }

  // Draw connectors first (under cells)
  for (const connector of connectors) {
    const x1 = gridOffsetX + connector.fromCol * cellSize + cellSize / 2
    const y1 = gridOffsetY + connector.fromRow * cellSize + cellSize / 2
    const x2 = gridOffsetX + connector.toCol * cellSize + cellSize / 2
    const y2 = gridOffsetY + connector.toRow * cellSize + cellSize / 2

    // Determine if this connector should be highlighted (solution mode)
    const isSolutionConnector = showSolution && connector.inSolution
    const connectorClass = isSolutionConnector ? 'connector-solution' : 'connector'

    svg += `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" class="${connectorClass}" />`

    // Add connector value (midpoint)
    const midX = (x1 + x2) / 2
    const midY = (y1 + y2) / 2

    // Small white background for readability
    const bgSize = cellSize * 0.28
    svg += `<rect x="${midX - bgSize}" y="${midY - bgSize * 0.7}" width="${bgSize * 2}" height="${bgSize * 1.4}" fill="white" />`
    svg += `<text x="${midX}" y="${midY}" class="connector-value">${connector.value}</text>`
  }

  // Draw cells (circles for print)
  for (const cell of cells) {
    const cx = gridOffsetX + cell.col * cellSize + cellSize / 2
    const cy = gridOffsetY + cell.row * cellSize + cellSize / 2
    const radius = cellSize * 0.38

    // Determine cell fill
    let fill = 'white'
    let strokeWidth = lineWidth
    if (cell.isStart || cell.isEnd) {
      fill = '#e0e0e0'
      strokeWidth = lineWidth * 1.5
    } else if (showSolution && cell.inSolution) {
      fill = '#f0f0f0'
    }

    // Draw cell circle
    svg += `<circle cx="${cx}" cy="${cy}" r="${radius}" fill="${fill}" stroke="#000" stroke-width="${strokeWidth}mm" />`

    // Draw start/end markers
    if (cell.isStart) {
      svg += `<text x="${cx}" y="${cy - radius - 3}" class="label-text">START</text>`
    }
    if (cell.isEnd) {
      svg += `<text x="${cx}" y="${cy + radius + 4.5}" class="label-text">END</text>`
    }

    // Draw cell expression (for START cell we show the expression, not the answer)
    const displayText = cell.expression || ''
    svg += `<text x="${cx}" y="${cy}" class="cell-text">${escapeXml(displayText)}</text>`
  }

  svg += '</svg>'

  return svg
}

/**
 * Renders a full A4/Letter page with 1 or 2 puzzles.
 */
export function renderPageSVG(
  puzzles: PrintablePuzzle[],
  config: PrintConfig,
  pageNumber: number,
  totalPages: number,
  showSolutions: boolean = false
): string {
  const layout = getPageLayout(config)

  // SVG dimensions in mm
  const svgWidth = layout.width
  const svgHeight = layout.height

  let svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${svgWidth} ${svgHeight}" width="${svgWidth}mm" height="${svgHeight}mm">`

  // White background
  svg += `<rect width="100%" height="100%" fill="white" />`

  // Page styles
  svg += `
    <style>
      .page-title {
        font-family: Arial, Helvetica, sans-serif;
        font-size: 14pt;
        font-weight: bold;
        fill: #000;
      }
      .page-subtitle {
        font-family: Arial, Helvetica, sans-serif;
        font-size: 10pt;
        fill: #666;
      }
      .page-footer {
        font-family: Arial, Helvetica, sans-serif;
        font-size: 8pt;
        fill: #999;
      }
    </style>
  `

  // Page header
  let headerY = layout.marginTop + 4

  if (config.title) {
    svg += `<text x="${layout.marginLeft}" y="${headerY}" class="page-title">${escapeXml(config.title)}</text>`
    headerY += 6
  }

  if (config.subtitle) {
    svg += `<text x="${layout.marginLeft}" y="${headerY}" class="page-subtitle">${escapeXml(config.subtitle)}</text>`
    headerY += 5
  }

  if (config.showDate) {
    const dateStr = new Date().toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    })
    svg += `<text x="${svgWidth - layout.marginRight}" y="${layout.marginTop + 4}" class="page-subtitle" text-anchor="end">${dateStr}</text>`
  }

  // Calculate puzzle positioning
  const puzzleAreaTop = headerY + 8
  const puzzleAreaHeight =
    layout.contentHeight - (puzzleAreaTop - layout.marginTop) - 10

  if (config.puzzlesPerPage === 2 && puzzles.length === 2) {
    // Two puzzles per page
    const puzzleHeight = (puzzleAreaHeight - layout.gapBetweenPuzzles) / 2

    // Puzzle 1
    const puzzle1SVG = renderPuzzleSVG(puzzles[0], config, showSolutions)
    svg += `<g transform="translate(${layout.marginLeft}, ${puzzleAreaTop})">${extractSVGContent(puzzle1SVG)}</g>`

    // Divider line
    const dividerY = puzzleAreaTop + puzzleHeight + layout.gapBetweenPuzzles / 2
    svg += `<line x1="${layout.marginLeft}" y1="${dividerY}" x2="${svgWidth - layout.marginRight}" y2="${dividerY}" stroke="#ccc" stroke-width="0.25" stroke-dasharray="2,2" />`

    // Puzzle 2
    const puzzle2SVG = renderPuzzleSVG(puzzles[1], config, showSolutions)
    svg += `<g transform="translate(${layout.marginLeft}, ${puzzleAreaTop + puzzleHeight + layout.gapBetweenPuzzles})">${extractSVGContent(puzzle2SVG)}</g>`
  } else if (puzzles.length >= 1) {
    // One puzzle per page (centered)
    const puzzleSVG = renderPuzzleSVG(puzzles[0], config, showSolutions)
    svg += `<g transform="translate(${layout.marginLeft}, ${puzzleAreaTop})">${extractSVGContent(puzzleSVG)}</g>`
  }

  // Page footer
  if (config.showPageNumbers) {
    svg += `<text x="${svgWidth / 2}" y="${svgHeight - layout.marginBottom + 5}" class="page-footer" text-anchor="middle">Page ${pageNumber} of ${totalPages}</text>`
  }

  // Answer indicator
  if (showSolutions) {
    svg += `<text x="${svgWidth - layout.marginRight}" y="${svgHeight - layout.marginBottom + 5}" class="page-footer" text-anchor="end">ANSWER KEY</text>`
  }

  svg += '</svg>'

  return svg
}

/**
 * Extracts the inner content from an SVG string (removes outer svg tags).
 */
function extractSVGContent(svg: string): string {
  // Remove the outer <svg> and </svg> tags
  return svg.replace(/<svg[^>]*>/, '').replace(/<\/svg>$/, '')
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
