import SwiftUI
import UIKit

// MARK: - Hexagon Shape

/// Pointy-top hexagon shape for cell rendering
/// Matches web app exactly: vertices at top and bottom
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        let centerX = w / 2
        let centerY = h / 2

        // Calculate radius based on height (tip to tip)
        let radius = h / 2

        // Width factor for pointy-top: sqrt(3)/2
        let halfWidth = radius * sqrt(3) / 2
        let quarterHeight = radius / 2

        var path = Path()

        // Start at top point, go clockwise (matching web: top, top-right, bottom-right, bottom, bottom-left, top-left)
        path.move(to: CGPoint(x: centerX, y: centerY - radius))                      // top
        path.addLine(to: CGPoint(x: centerX + halfWidth, y: centerY - quarterHeight)) // top-right
        path.addLine(to: CGPoint(x: centerX + halfWidth, y: centerY + quarterHeight)) // bottom-right
        path.addLine(to: CGPoint(x: centerX, y: centerY + radius))                    // bottom
        path.addLine(to: CGPoint(x: centerX - halfWidth, y: centerY + quarterHeight)) // bottom-left
        path.addLine(to: CGPoint(x: centerX - halfWidth, y: centerY - quarterHeight)) // top-left
        path.closeSubpath()

        return path
    }
}

// MARK: - Hexagon Geometry Calculator

/// Calculates positions and dimensions for hex grid layout
/// Matches web app spacing exactly: 150px horizontal, 140px vertical, 75px padding
struct HexagonGeometry {
    /// Cell radius (half the height)
    let cellRadius: CGFloat

    /// Horizontal spacing between cell centers
    let horizontalSpacing: CGFloat

    /// Vertical spacing between cell centers
    let verticalSpacing: CGFloat

    /// Padding around the grid
    let padding: CGFloat

    /// Default geometry matching web app exactly
    static let standard = HexagonGeometry(
        cellRadius: 42,
        horizontalSpacing: 150,
        verticalSpacing: 140,
        padding: 75
    )

    /// Calculate cell width from radius (for pointy-top hex: width = radius * sqrt(3))
    var cellWidth: CGFloat {
        cellRadius * sqrt(3)
    }

    /// Calculate cell height from radius (height = radius * 2)
    var cellHeight: CGFloat {
        cellRadius * 2
    }

    /// Calculate total grid width
    func gridWidth(cols: Int) -> CGFloat {
        padding + CGFloat(cols - 1) * horizontalSpacing + padding
    }

    /// Calculate total grid height
    func gridHeight(rows: Int) -> CGFloat {
        padding + CGFloat(rows - 1) * verticalSpacing + padding
    }

    /// Get center point for a cell at given row/col
    func cellCenter(row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: padding + CGFloat(col) * horizontalSpacing,
            y: padding + CGFloat(row) * verticalSpacing
        )
    }

    /// Get the frame for a cell at given row/col
    func cellFrame(row: Int, col: Int) -> CGRect {
        let center = cellCenter(row: row, col: col)
        return CGRect(
            x: center.x - cellWidth / 2,
            y: center.y - cellHeight / 2,
            width: cellWidth,
            height: cellHeight
        )
    }
}

// MARK: - Scaled Geometry for Different Devices

extension HexagonGeometry {
    /// Create geometry that maximizes screen usage for the given grid size
    /// Optimized for mobile: minimal padding, maximum grid space
    static func scaled(for size: CGSize, rows: Int, cols: Int) -> HexagonGeometry {
        // Web app base values
        let webCellRadius: CGFloat = 42
        let webHorizontalSpacing: CGFloat = 150
        let webVerticalSpacing: CGFloat = 140

        // Horizontal padding - must be at least half cell width for leftmost/rightmost cells
        let webHorizontalPadding: CGFloat = 50

        // Detect if we're on iPhone (narrow screen)
        let isIPhone = UIDevice.current.userInterfaceIdiom == .phone

        // Vertical padding - needs extra space on iPhone to prevent clipping and show START label
        // iPhone needs more padding because the grid is scaled down more
        let webVerticalPadding: CGFloat
        if isIPhone {
            // iPhone: more generous padding for all row counts
            // Need enough space for START label above first cell
            if rows <= 4 {
                webVerticalPadding = 70  // Extra padding for START label visibility
            } else if rows == 5 {
                webVerticalPadding = 62  // Still generous for 5 rows
            } else {
                webVerticalPadding = 58  // 6 rows need good padding too
            }
        } else {
            // iPad: can use tighter padding
            if rows <= 4 {
                webVerticalPadding = 55
            } else if rows == 5 {
                webVerticalPadding = 48
            } else {
                webVerticalPadding = 44
            }
        }

        // Calculate web grid dimensions with asymmetric padding
        let webGridWidth = webHorizontalPadding * 2 + CGFloat(cols - 1) * webHorizontalSpacing
        let webGridHeight = webVerticalPadding * 2 + CGFloat(rows - 1) * webVerticalSpacing

        // Calculate scale factor to fit available space
        let scaleX = size.width / webGridWidth
        let scaleY = size.height / webGridHeight
        let scale = min(scaleX, scaleY) * 0.99  // 99% to maximize grid size

        // Apply scale uniformly to all measurements
        let scaledRadius = webCellRadius * scale
        let scaledHorizontalSpacing = webHorizontalSpacing * scale
        let scaledVerticalSpacing = webVerticalSpacing * scale
        // Use the larger horizontal padding for both (keeps grid centered)
        let scaledPadding = webHorizontalPadding * scale

        return HexagonGeometry(
            cellRadius: scaledRadius,
            horizontalSpacing: scaledHorizontalSpacing,
            verticalSpacing: scaledVerticalSpacing,
            padding: scaledPadding
        )
    }

    /// Create geometry optimized for iPad landscape
    static func iPad(rows: Int, cols: Int) -> HexagonGeometry {
        HexagonGeometry(
            cellRadius: 60,
            horizontalSpacing: 192,
            verticalSpacing: 178,
            padding: 100
        )
    }

    /// Create compact geometry for smaller screens
    static func compact(rows: Int, cols: Int) -> HexagonGeometry {
        HexagonGeometry(
            cellRadius: 32,
            horizontalSpacing: 102,
            verticalSpacing: 95,
            padding: 58
        )
    }
}

// MARK: - Preview

#Preview("Hexagon Shape") {
    VStack(spacing: 30) {
        // Show hexagon shape
        HexagonShape()
            .fill(Color.green)
            .frame(width: 73, height: 84)  // cellWidth x cellHeight for radius 42

        // Show grid layout info
        let geometry = HexagonGeometry.standard
        VStack(alignment: .leading, spacing: 8) {
            Text("Standard Geometry")
                .font(.headline)
            Text("Cell size: \(Int(geometry.cellWidth)) x \(Int(geometry.cellHeight))")
            Text("Cell radius: \(Int(geometry.cellRadius))")
            Text("Horizontal spacing: \(Int(geometry.horizontalSpacing))")
            Text("Vertical spacing: \(Int(geometry.verticalSpacing))")
            Text("Padding: \(Int(geometry.padding))")
            Text("3x4 grid: \(Int(geometry.gridWidth(cols: 4))) x \(Int(geometry.gridHeight(rows: 3)))")
        }
        .foregroundColor(.white)
        .font(.system(size: 14, design: .monospaced))
    }
    .padding()
    .background(Color(red: 0.06, green: 0.06, blue: 0.14))
}
