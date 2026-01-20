import UIKit
import PDFKit

// MARK: - Print Renderer

/// Renders puzzles to PDF format
enum PrintRenderer {

    // MARK: - Hexagon Constants

    private enum Hex {
        // Pointy-top hexagon dimensions
        static let width: CGFloat = 45
        static let height: CGFloat = 52
        // Spacing between cell centers
        static let spacingX: CGFloat = 90
        static let spacingY: CGFloat = 80
    }

    private enum Badge {
        static let width: CGFloat = 22
        static let height: CGFloat = 18
        static let cornerRadius: CGFloat = 3
    }

    // MARK: - PDF Generation

    /// Generates a PDF document containing all puzzles
    static func generatePDF(
        puzzles: [PrintablePuzzle],
        config: PrintConfig
    ) -> Data? {
        let layout = PageLayout.forConfig(config)

        // Convert mm to points (1 mm = 2.83465 points)
        let mmToPoints: CGFloat = 2.83465
        let pageWidth = layout.width * mmToPoints
        let pageHeight = layout.height * mmToPoints
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = pdfRenderer.pdfData { context in
            let puzzlesPerPage = config.puzzlesPerPage
            let totalQuestionPages = Int(ceil(Double(puzzles.count) / Double(puzzlesPerPage)))

            // Generate question pages
            for pageIndex in 0..<totalQuestionPages {
                let startIndex = pageIndex * puzzlesPerPage
                let endIndex = min(startIndex + puzzlesPerPage, puzzles.count)
                let pagePuzzles = Array(puzzles[startIndex..<endIndex])

                context.beginPage()
                drawPage(
                    context: context.cgContext,
                    puzzles: pagePuzzles,
                    config: config,
                    layout: layout,
                    pageNumber: pageIndex + 1,
                    totalPages: totalQuestionPages,
                    showSolution: false
                )
            }

            // Generate answer pages if requested
            if config.showAnswers {
                for pageIndex in 0..<totalQuestionPages {
                    let startIndex = pageIndex * puzzlesPerPage
                    let endIndex = min(startIndex + puzzlesPerPage, puzzles.count)
                    let pagePuzzles = Array(puzzles[startIndex..<endIndex])

                    context.beginPage()
                    drawPage(
                        context: context.cgContext,
                        puzzles: pagePuzzles,
                        config: config,
                        layout: layout,
                        pageNumber: pageIndex + 1,
                        totalPages: totalQuestionPages,
                        showSolution: true
                    )
                }
            }
        }

        return data
    }

    // MARK: - Page Drawing

    private static func drawPage(
        context: CGContext,
        puzzles: [PrintablePuzzle],
        config: PrintConfig,
        layout: PageLayout,
        pageNumber: Int,
        totalPages: Int,
        showSolution: Bool
    ) {
        let mmToPoints: CGFloat = 2.83465
        let margin = layout.marginTop * mmToPoints
        let contentWidth = layout.contentWidth * mmToPoints
        _ = layout.contentHeight * mmToPoints  // contentHeight available for future use
        let puzzleAreaHeight = layout.puzzleAreaHeight * mmToPoints
        let gap = layout.gapBetweenPuzzles * mmToPoints

        // Draw each puzzle
        for (index, puzzle) in puzzles.enumerated() {
            let yOffset = margin + CGFloat(index) * (puzzleAreaHeight + gap)
            let puzzleRect = CGRect(
                x: margin,
                y: yOffset,
                width: contentWidth,
                height: puzzleAreaHeight
            )

            // Draw puzzle border
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(1.5)
            context.stroke(puzzleRect)

            // Draw puzzle content
            drawPuzzle(
                context: context,
                puzzle: puzzle,
                rect: puzzleRect.insetBy(dx: 10, dy: 10),
                showSolution: showSolution
            )
        }

        // Draw page footer
        if config.showPageNumbers {
            let footerY = layout.height * mmToPoints - margin + 10
            let footerText = showSolution
                ? "ANSWER KEY - Page \(pageNumber) of \(totalPages)"
                : "Page \(pageNumber) of \(totalPages)"

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.darkGray
            ]
            let textSize = (footerText as NSString).size(withAttributes: attributes)
            let textX = (layout.width * mmToPoints - textSize.width) / 2
            (footerText as NSString).draw(
                at: CGPoint(x: textX, y: footerY),
                withAttributes: attributes
            )
        }
    }

    // MARK: - Puzzle Drawing

    private static func drawPuzzle(
        context: CGContext,
        puzzle: PrintablePuzzle,
        rect: CGRect,
        showSolution: Bool
    ) {
        let gridRows = puzzle.gridRows
        let gridCols = puzzle.gridCols

        // Calculate scale to fit puzzle in rect
        let naturalWidth = CGFloat(gridCols - 1) * Hex.spacingX + Hex.width + 40
        let naturalHeight = CGFloat(gridRows - 1) * Hex.spacingY + Hex.height + 40
        let scaleX = rect.width / naturalWidth
        let scaleY = rect.height / naturalHeight
        let scale = min(scaleX, scaleY) * 0.9

        // Calculate centered offset
        let scaledWidth = naturalWidth * scale
        let scaledHeight = naturalHeight * scale
        let offsetX = rect.minX + (rect.width - scaledWidth) / 2 + 20 * scale
        let offsetY = rect.minY + (rect.height - scaledHeight) / 2 + 20 * scale

        // Create solution edge set for highlighting
        var solutionEdges = Set<String>()
        if showSolution {
            for i in 0..<(puzzle.solution.count - 1) {
                let fromIdx = puzzle.solution[i]
                let toIdx = puzzle.solution[i + 1]
                solutionEdges.insert("\(fromIdx)-\(toIdx)")
                solutionEdges.insert("\(toIdx)-\(fromIdx)")
            }
        }

        // Helper to get cell center coordinates
        func getCellCenter(row: Int, col: Int) -> CGPoint {
            CGPoint(
                x: offsetX + CGFloat(col) * Hex.spacingX * scale,
                y: offsetY + CGFloat(row) * Hex.spacingY * scale
            )
        }

        // Helper to get cell index
        func getCellIndex(row: Int, col: Int) -> Int {
            row * gridCols + col
        }

        // Draw connectors first (under cells)
        for connector in puzzle.connectors {
            let from = getCellCenter(row: connector.fromRow, col: connector.fromCol)
            let to = getCellCenter(row: connector.toRow, col: connector.toCol)

            // Check if connector is in solution
            let fromIdx = getCellIndex(row: connector.fromRow, col: connector.fromCol)
            let toIdx = getCellIndex(row: connector.toRow, col: connector.toCol)
            let isInSolution = solutionEdges.contains("\(fromIdx)-\(toIdx)")

            drawConnector(
                context: context,
                from: from,
                to: to,
                value: connector.value,
                scale: scale,
                isInSolution: isInSolution
            )
        }

        // Draw cells
        for cell in puzzle.cells {
            let center = getCellCenter(row: cell.row, col: cell.col)
            let isInSolution = showSolution && cell.inSolution

            drawCell(
                context: context,
                center: center,
                expression: cell.expression,
                isStart: cell.isStart,
                isEnd: cell.isEnd,
                isInSolution: isInSolution,
                scale: scale
            )
        }
    }

    // MARK: - Cell Drawing

    private static func drawCell(
        context: CGContext,
        center: CGPoint,
        expression: String,
        isStart: Bool,
        isEnd: Bool,
        isInSolution: Bool,
        scale: CGFloat
    ) {
        let scaledWidth = Hex.width * scale
        let scaledHeight = Hex.height * scale

        // Create hexagon path (pointy-top)
        let path = CGMutablePath()
        let points: [CGPoint] = [
            CGPoint(x: center.x, y: center.y - scaledHeight / 2),
            CGPoint(x: center.x + scaledWidth / 2, y: center.y - scaledHeight / 4),
            CGPoint(x: center.x + scaledWidth / 2, y: center.y + scaledHeight / 4),
            CGPoint(x: center.x, y: center.y + scaledHeight / 2),
            CGPoint(x: center.x - scaledWidth / 2, y: center.y + scaledHeight / 4),
            CGPoint(x: center.x - scaledWidth / 2, y: center.y - scaledHeight / 4)
        ]
        path.addLines(between: points)
        path.closeSubpath()

        // Fill cell
        let fillColor = isInSolution ? UIColor(white: 0.91, alpha: 1.0) : UIColor.white
        context.setFillColor(fillColor.cgColor)
        context.addPath(path)
        context.fillPath()

        // Stroke cell
        let strokeWidth: CGFloat = (isStart || isEnd) ? 2.5 * scale : (isInSolution ? 2.0 * scale : 1.5 * scale)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(strokeWidth)
        context.addPath(path)
        context.strokePath()

        // Draw START label above cell
        if isStart {
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 8 * scale),
                .foregroundColor: UIColor.black
            ]
            let label = "START"
            let labelSize = (label as NSString).size(withAttributes: labelAttributes)
            (label as NSString).draw(
                at: CGPoint(x: center.x - labelSize.width / 2, y: center.y - scaledHeight / 2 - labelSize.height - 2 * scale),
                withAttributes: labelAttributes
            )
        }

        // Draw cell text
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11 * scale),
            .foregroundColor: UIColor.black
        ]

        let text = isEnd ? "FINISH" : expression
        let textSize = (text as NSString).size(withAttributes: textAttributes)
        let textY = isStart ? center.y - textSize.height / 2 + 4 * scale : center.y - textSize.height / 2
        (text as NSString).draw(
            at: CGPoint(x: center.x - textSize.width / 2, y: textY),
            withAttributes: textAttributes
        )
    }

    // MARK: - Connector Drawing

    private static func drawConnector(
        context: CGContext,
        from: CGPoint,
        to: CGPoint,
        value: Int,
        scale: CGFloat,
        isInSolution: Bool
    ) {
        // Determine connector type
        let isHorizontal = abs(from.y - to.y) < 1
        let isVertical = abs(from.x - to.x) < 1

        // Calculate shortened line endpoints
        var x1 = from.x
        var y1 = from.y
        var x2 = to.x
        var y2 = to.y

        let shortenH: CGFloat = 22 * scale
        let shortenV: CGFloat = 26 * scale
        let shortenD: CGFloat = 18 * scale

        if isHorizontal {
            x1 += shortenH * (x2 > x1 ? 1 : -1)
            x2 -= shortenH * (x2 > x1 ? 1 : -1)
        } else if isVertical {
            y1 += shortenV * (y2 > y1 ? 1 : -1)
            y2 -= shortenV * (y2 > y1 ? 1 : -1)
        } else {
            // Diagonal
            let dx: CGFloat = x2 > x1 ? shortenD : -shortenD
            let dy: CGFloat = y2 > y1 ? shortenD : -shortenD
            x1 += dx
            y1 += dy
            x2 -= dx
            y2 -= dy
        }

        // Draw line
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(isInSolution ? 3.0 * scale : 1.5 * scale)
        context.move(to: CGPoint(x: x1, y: y1))
        context.addLine(to: CGPoint(x: x2, y: y2))
        context.strokePath()

        // Draw badge
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        let badgeWidth = Badge.width * scale
        let badgeHeight = Badge.height * scale
        let badgeRect = CGRect(
            x: midX - badgeWidth / 2,
            y: midY - badgeHeight / 2,
            width: badgeWidth,
            height: badgeHeight
        )

        // Badge background
        let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: Badge.cornerRadius * scale)
        context.setFillColor(UIColor.white.cgColor)
        context.addPath(badgePath.cgPath)
        context.fillPath()

        // Badge border
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0 * scale)
        context.addPath(badgePath.cgPath)
        context.strokePath()

        // Badge text
        let valueText = "\(value)"
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 9 * scale),
            .foregroundColor: UIColor.black
        ]
        let textSize = (valueText as NSString).size(withAttributes: textAttributes)
        (valueText as NSString).draw(
            at: CGPoint(x: midX - textSize.width / 2, y: midY - textSize.height / 2),
            withAttributes: textAttributes
        )
    }

    // MARK: - Page Info

    /// Returns total page count for a batch of puzzles
    static func pageCount(puzzleCount: Int, puzzlesPerPage: Int, includeAnswers: Bool) -> Int {
        let questionPages = Int(ceil(Double(puzzleCount) / Double(puzzlesPerPage)))
        return includeAnswers ? questionPages * 2 : questionPages
    }
}
