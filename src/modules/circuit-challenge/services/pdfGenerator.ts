import type { PrintConfig } from '../types/print'
import { A4_PORTRAIT, LETTER_PORTRAIT } from '../types/print'

/**
 * Get the page layout based on config.
 */
function getPageLayout(config: PrintConfig) {
  if (config.pageSize === 'Letter') {
    return LETTER_PORTRAIT
  }
  return A4_PORTRAIT
}

/**
 * Opens a print preview window with all SVG pages.
 * Uses browser's native print functionality for best quality.
 */
export function openPrintPreview(
  questionPages: string[],
  answerPages: string[],
  config: PrintConfig
): void {
  const layout = getPageLayout(config)

  // Create print document HTML
  const printHTML = createPrintDocument(questionPages, answerPages, config, layout)

  // Open in new window
  const printWindow = window.open('', '_blank', 'width=800,height=1100')
  if (!printWindow) {
    alert('Please allow pop-ups to preview the PDF')
    return
  }

  printWindow.document.write(printHTML)
  printWindow.document.close()

  // Auto-trigger print after content loads
  printWindow.onload = () => {
    printWindow.focus()
    // Small delay to ensure SVGs are rendered
    setTimeout(() => {
      printWindow.print()
    }, 500)
  }
}

/**
 * Opens a preview window without auto-triggering print.
 */
export function openPreview(
  questionPages: string[],
  answerPages: string[],
  config: PrintConfig
): void {
  const layout = getPageLayout(config)

  // Create print document HTML
  const printHTML = createPrintDocument(questionPages, answerPages, config, layout)

  // Open in new window
  const previewWindow = window.open('', '_blank', 'width=800,height=1100')
  if (!previewWindow) {
    alert('Please allow pop-ups to preview the document')
    return
  }

  previewWindow.document.write(printHTML)
  previewWindow.document.close()
}

/**
 * Creates the HTML document for printing.
 */
function createPrintDocument(
  questionPages: string[],
  answerPages: string[],
  config: PrintConfig,
  layout: typeof A4_PORTRAIT
): string {
  // Add answer key separator if there are answer pages
  let pagesWithSeparator = [...questionPages]
  if (answerPages.length > 0) {
    // Add a separator page
    const separatorSVG = createSeparatorPage(config, layout)
    pagesWithSeparator.push(separatorSVG)
    pagesWithSeparator.push(...answerPages)
  }

  const pagesHTML = pagesWithSeparator
    .map(
      (svg, index) => `
      <div class="page${index > 0 ? ' page-break' : ''}">
        ${svg}
      </div>
    `
    )
    .join('\n')

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${escapeHtml(config.title)} - Printable Worksheets</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    @page {
      size: ${config.pageSize} ${config.orientation};
      margin: 0;
    }

    body {
      font-family: Arial, Helvetica, sans-serif;
      background: #f0f0f0;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }

    .page {
      width: ${layout.width}mm;
      height: ${layout.height}mm;
      background: white;
      margin: 20px auto;
      box-shadow: 0 2px 8px rgba(0,0,0,0.15);
      overflow: hidden;
    }

    .page svg {
      width: 100%;
      height: 100%;
      display: block;
    }

    .page-break {
      page-break-before: always;
    }

    @media print {
      body {
        background: white;
      }

      .page {
        margin: 0;
        box-shadow: none;
        width: 100%;
        height: 100%;
      }
    }

    /* Print button for preview mode */
    .print-controls {
      position: fixed;
      top: 20px;
      right: 20px;
      z-index: 1000;
      display: flex;
      gap: 10px;
    }

    .print-controls button {
      padding: 12px 24px;
      font-size: 16px;
      font-weight: bold;
      border: none;
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.2s;
    }

    .print-controls .print-btn {
      background: #22c55e;
      color: white;
    }

    .print-controls .print-btn:hover {
      background: #16a34a;
    }

    .print-controls .close-btn {
      background: #6b7280;
      color: white;
    }

    .print-controls .close-btn:hover {
      background: #4b5563;
    }

    @media print {
      .print-controls {
        display: none;
      }
    }
  </style>
</head>
<body>
  <div class="print-controls">
    <button class="print-btn" onclick="window.print()">Print / Save as PDF</button>
    <button class="close-btn" onclick="window.close()">Close</button>
  </div>
  ${pagesHTML}
</body>
</html>`
}

/**
 * Creates a separator page for the answer key section.
 */
function createSeparatorPage(
  config: PrintConfig,
  layout: typeof A4_PORTRAIT
): string {
  const width = layout.width
  const height = layout.height

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" width="${width}mm" height="${height}mm">
    <rect width="100%" height="100%" fill="white" />
    <text x="${width / 2}" y="${height / 2 - 10}" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="28pt" font-weight="bold" fill="#000">
      Answer Key
    </text>
    <text x="${width / 2}" y="${height / 2 + 20}" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="12pt" fill="#666">
      ${escapeHtml(config.title)}
    </text>
    <line x1="${width / 2 - 40}" y1="${height / 2 + 35}" x2="${width / 2 + 40}" y2="${height / 2 + 35}" stroke="#ccc" stroke-width="1" />
  </svg>`
}

/**
 * Escapes HTML special characters.
 */
function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

/**
 * Downloads the SVG pages as individual files (alternative to PDF).
 */
export function downloadSVGs(
  questionPages: string[],
  _answerPages: string[],
  config: PrintConfig
): void {
  // Create a zip file would require additional library
  // For now, we download each page individually
  questionPages.forEach((svg, index) => {
    const blob = new Blob([svg], { type: 'image/svg+xml' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `${config.title.replace(/\s+/g, '-')}-puzzle-${index + 1}.svg`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(url)
  })
}

/**
 * Converts an SVG string to a PNG data URL via canvas.
 * Useful for environments where SVG rendering is problematic.
 */
export async function svgToDataURL(
  svgString: string,
  width: number,
  height: number,
  scale: number = 2
): Promise<string> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    const blob = new Blob([svgString], { type: 'image/svg+xml' })
    const url = URL.createObjectURL(blob)

    img.onload = () => {
      const canvas = document.createElement('canvas')
      canvas.width = width * scale
      canvas.height = height * scale

      const ctx = canvas.getContext('2d')
      if (!ctx) {
        reject(new Error('Canvas context not available'))
        return
      }

      // White background
      ctx.fillStyle = 'white'
      ctx.fillRect(0, 0, canvas.width, canvas.height)

      // Scale and draw SVG
      ctx.scale(scale, scale)
      ctx.drawImage(img, 0, 0, width, height)

      URL.revokeObjectURL(url)
      resolve(canvas.toDataURL('image/png', 1.0))
    }

    img.onerror = () => {
      URL.revokeObjectURL(url)
      reject(new Error('Failed to load SVG'))
    }

    img.src = url
  })
}
