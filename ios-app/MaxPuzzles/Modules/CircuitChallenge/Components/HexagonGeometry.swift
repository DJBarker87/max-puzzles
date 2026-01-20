import SwiftUI

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
        padding + CGFloat(cols - 1) * horizontalSpacing + padding + 30
    }

    /// Calculate total grid height
    func gridHeight(rows: Int) -> CGFloat {
        padding + CGFloat(rows - 1) * verticalSpacing + padding + 50
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
    /// Create geometry scaled for available size while maintaining aspect ratio
    static func scaled(for size: CGSize, rows: Int, cols: Int) -> HexagonGeometry {
        let standard = HexagonGeometry.standard

        // Calculate the scale factor needed to fit the grid
        let standardWidth = standard.gridWidth(cols: cols)
        let standardHeight = standard.gridHeight(rows: rows)

        let scaleX = size.width / standardWidth
        let scaleY = size.height / standardHeight
        let scale = min(scaleX, scaleY, 1.5)  // Cap at 1.5x for large screens

        return HexagonGeometry(
            cellRadius: standard.cellRadius * scale,
            horizontalSpacing: standard.horizontalSpacing * scale,
            verticalSpacing: standard.verticalSpacing * scale,
            padding: standard.padding * scale
        )
    }

    /// Create geometry optimized for iPad
    static func iPad(rows: Int, cols: Int) -> HexagonGeometry {
        HexagonGeometry(
            cellRadius: 60,
            horizontalSpacing: 200,
            verticalSpacing: 190,
            padding: 100
        )
    }

    /// Create compact geometry for smaller screens
    static func compact(rows: Int, cols: Int) -> HexagonGeometry {
        HexagonGeometry(
            cellRadius: 32,
            horizontalSpacing: 115,
            verticalSpacing: 107,
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
