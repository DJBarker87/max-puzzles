# Phase 3: Grid Rendering

**Goal:** Create the visual puzzle grid with 3D hex cells, connectors, and animations matching the web app exactly.

**Prerequisites:** Phase 1 (UI foundation), Phase 2 (engine types)

**Estimated Subphases:** 5

**Reference Web Files:**
- `src/modules/circuit-challenge/components/HexCell.tsx`
- `src/modules/circuit-challenge/components/Connector.tsx`
- `src/modules/circuit-challenge/components/PuzzleGrid.tsx`
- `src/modules/circuit-challenge/components/GridDefs.tsx`
- `src/modules/circuit-challenge/components/animations.css`

---

## Subphase 3.1: Hexagon Shape & Geometry

### Objective
Create the hexagon shape and geometry calculations for cell rendering.

### Technical Prompt for Claude Code

```
Create the hexagon shape and geometry utilities for Circuit Challenge cells.

FILE: Modules/CircuitChallenge/Components/HexagonGeometry.swift

```swift
import SwiftUI

// MARK: - Hexagon Shape

/// Pointy-top hexagon shape for cell rendering
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        // Pointy-top hexagon
        // For a pointy-top hex with width w:
        // Height should be h = w / (sqrt(3)/2) = w * 2/sqrt(3)
        // But we'll work with whatever rect we're given

        let centerX = w / 2
        let centerY = h / 2

        // Calculate radius based on height (tip to tip)
        let radius = h / 2

        // Width factor for pointy-top: sqrt(3)/2
        let halfWidth = radius * sqrt(3) / 2
        let quarterHeight = radius / 2

        var path = Path()

        // Start at top point, go clockwise
        path.move(to: CGPoint(x: centerX, y: centerY - radius))                    // top
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
struct HexagonGeometry {
    /// Cell radius (half the height)
    let cellRadius: CGFloat

    /// Horizontal spacing between cell centers
    let horizontalSpacing: CGFloat

    /// Vertical spacing between cell centers
    let verticalSpacing: CGFloat

    /// Padding around the grid
    let padding: CGFloat

    /// Default geometry matching web app
    static let standard = HexagonGeometry(
        cellRadius: 42,
        horizontalSpacing: 150,
        verticalSpacing: 140,
        padding: 75
    )

    /// Calculate cell width from radius
    var cellWidth: CGFloat {
        cellRadius * sqrt(3)  // For pointy-top hex
    }

    /// Calculate cell height from radius
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
    /// Create geometry scaled for device size
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

    /// iPad-optimized geometry
    static func iPad(rows: Int, cols: Int) -> HexagonGeometry {
        // Larger cells for iPad
        HexagonGeometry(
            cellRadius: 60,
            horizontalSpacing: 200,
            verticalSpacing: 190,
            padding: 100
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        // Show hexagon shape
        HexagonShape()
            .fill(Color.green)
            .frame(width: 80, height: 92)

        // Show grid layout preview
        let geometry = HexagonGeometry.standard
        Text("Cell size: \(Int(geometry.cellWidth)) × \(Int(geometry.cellHeight))")
        Text("Spacing: \(Int(geometry.horizontalSpacing)) × \(Int(geometry.verticalSpacing))")
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
```

Ensure:
1. Hexagon vertices match web app exactly (pointy-top orientation)
2. Grid spacing matches web: 150px horizontal, 140px vertical
3. Padding matches: 75px
```

### Acceptance Criteria
- [ ] Hexagon shape renders correctly
- [ ] Pointy-top orientation (vertices at top and bottom)
- [ ] Grid geometry calculations match web app
- [ ] Scaling works for different device sizes

---

## Subphase 3.2: 3D Hex Cell Component

### Objective
Create the 3D "poker chip" hex cell with all state variants and the electric pulse animation.

### Technical Prompt for Claude Code

```
Create the 3D hex cell component with poker chip effect matching the web app exactly.

FILE: Modules/CircuitChallenge/Components/HexCellView.swift

```swift
import SwiftUI

// MARK: - Cell Gradients

/// Gradient definitions for each cell state
struct CellGradients {
    let topGradient: LinearGradient
    let baseGradient: LinearGradient
    let strokeColor: Color
    let strokeWidth: CGFloat

    static func forState(_ state: CellState) -> CellGradients {
        switch state {
        case .normal:
            return CellGradients(
                topGradient: LinearGradient(
                    colors: [Color(hex: "3a3a4a"), Color(hex: "252530")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                baseGradient: LinearGradient(
                    colors: [Color(hex: "2a2a3a"), Color(hex: "1a1a25")],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                strokeColor: Color(hex: "4a4a5a"),
                strokeWidth: 2
            )

        case .start:
            return CellGradients(
                topGradient: LinearGradient(
                    colors: [Color(hex: "15803d"), Color(hex: "0d5025")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                baseGradient: LinearGradient(
                    colors: [Color(hex: "0d5025"), Color(hex: "073518")],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                strokeColor: Color(hex: "00ff88"),
                strokeWidth: 2
            )

        case .finish:
            return CellGradients(
                topGradient: LinearGradient(
                    colors: [Color(hex: "ca8a04"), Color(hex: "854d0e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                baseGradient: LinearGradient(
                    colors: [Color(hex: "854d0e"), Color(hex: "5c3508")],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                strokeColor: Color(hex: "ffcc00"),
                strokeWidth: 2
            )

        case .current:
            return CellGradients(
                topGradient: LinearGradient(
                    colors: [Color(hex: "0d9488"), Color(hex: "086560")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                baseGradient: LinearGradient(
                    colors: [Color(hex: "086560"), Color(hex: "054540")],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                strokeColor: Color(hex: "00ffcc"),
                strokeWidth: 3
            )

        case .visited:
            return CellGradients(
                topGradient: LinearGradient(
                    colors: [Color(hex: "1a5c38"), Color(hex: "103822")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                baseGradient: LinearGradient(
                    colors: [Color(hex: "103822"), Color(hex: "082515")],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                strokeColor: Color(hex: "00ff88"),
                strokeWidth: 2
            )

        case .wrong:
            return CellGradients(
                topGradient: LinearGradient(
                    colors: [Color(hex: "ef4444"), Color(hex: "b91c1c")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                baseGradient: LinearGradient(
                    colors: [Color(hex: "b91c1c"), Color(hex: "7f1d1d")],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                strokeColor: Color(hex: "dc2626"),
                strokeWidth: 2
            )
        }
    }
}

// MARK: - Edge Gradient

private let edgeGradient = LinearGradient(
    colors: [Color(hex: "1a1a25"), Color(hex: "0f0f15")],
    startPoint: .top,
    endPoint: .bottom
)

// MARK: - HexCellView

/// 3D hexagonal cell with poker chip effect
struct HexCellView: View {
    let state: CellState
    let expression: String
    let size: CGFloat
    let onTap: (() -> Void)?
    let isClickable: Bool

    @State private var glowIntensity: CGFloat = 0.4

    init(
        state: CellState,
        expression: String,
        size: CGFloat = 42,
        isClickable: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.state = state
        self.expression = expression
        self.size = size
        self.isClickable = isClickable
        self.onTap = onTap
    }

    private var gradients: CellGradients {
        CellGradients.forState(state)
    }

    private var isPulsing: Bool {
        state == .current || state == .start
    }

    // Calculate dimensions
    private var cellWidth: CGFloat { size * sqrt(3) }
    private var cellHeight: CGFloat { size * 2 }

    // Layer offsets for 3D effect
    private var shadowOffset: CGFloat { 14 }
    private var edgeOffset: CGFloat { 12 }
    private var baseOffset: CGFloat { 6 }

    // Font size based on expression length
    private var fontSize: CGFloat {
        if state == .finish { return 13 }
        if expression.count > 7 { return 13 }
        if expression.count > 5 { return 15 }
        return 17
    }

    var body: some View {
        ZStack {
            // Layer 1: Shadow
            HexagonShape()
                .fill(Color.black.opacity(0.6))
                .frame(width: cellWidth, height: cellHeight)
                .offset(x: 4, y: shadowOffset)

            // Layer 2: Edge (3D depth)
            HexagonShape()
                .fill(edgeGradient)
                .frame(width: cellWidth, height: cellHeight)
                .offset(y: edgeOffset)

            // Layer 3: Base
            HexagonShape()
                .fill(gradients.baseGradient)
                .frame(width: cellWidth, height: cellHeight)
                .offset(y: baseOffset)

            // Layer 4: Top face
            HexagonShape()
                .fill(gradients.topGradient)
                .frame(width: cellWidth, height: cellHeight)
                .overlay(
                    HexagonShape()
                        .stroke(gradients.strokeColor, lineWidth: gradients.strokeWidth)
                        .frame(width: cellWidth, height: cellHeight)
                )

            // Layer 5: Inner shadow (radial)
            HexagonShape()
                .fill(
                    RadialGradient(
                        colors: [.clear, .clear, Color.black.opacity(0.3)],
                        center: .center,
                        startRadius: 0,
                        endRadius: cellWidth * 0.45
                    )
                )
                .frame(width: cellWidth * 0.9, height: cellHeight * 0.9)

            // Layer 6: Rim highlight
            HexagonShape()
                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                .frame(width: cellWidth, height: cellHeight)

            // Expression text
            Text(expression)
                .font(.system(size: fontSize, weight: .black))
                .foregroundColor(state == .finish ? Color(hex: "ffdd44") : .white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)

            // Electric glow for current/start cells
            if isPulsing {
                ElectricGlowOverlay(size: size)
            }
        }
        .frame(width: cellWidth + 8, height: cellHeight + shadowOffset + 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isClickable {
                onTap?()
            }
        }
        .opacity(isClickable ? 1.0 : 0.85)
        .modifier(isPulsing ? CellPulseModifier() : nil)
    }
}

// MARK: - Electric Glow Overlay

/// Electric energy flow effect for current/start cells
struct ElectricGlowOverlay: View {
    let size: CGFloat

    @State private var flowPhase1: CGFloat = 0
    @State private var flowPhase2: CGFloat = 0
    @State private var glowOpacity: CGFloat = 0.5

    private var cellWidth: CGFloat { size * sqrt(3) }
    private var cellHeight: CGFloat { size * 2 }

    var body: some View {
        ZStack {
            // Layer 1: Glow
            HexagonShape()
                .stroke(Color(hex: "00ff88").opacity(glowOpacity), lineWidth: 18)
                .blur(radius: 6)
                .frame(width: cellWidth, height: cellHeight)

            // Layer 2: Main line
            HexagonShape()
                .stroke(Color(hex: "00dd77"), lineWidth: 10)
                .frame(width: cellWidth, height: cellHeight)

            // Layer 3: Energy flow slow
            HexagonShape()
                .stroke(
                    Color(hex: "88ffcc"),
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: [6, 30],
                        dashPhase: flowPhase2
                    )
                )
                .frame(width: cellWidth, height: cellHeight)

            // Layer 4: Energy flow fast
            HexagonShape()
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: [4, 20],
                        dashPhase: flowPhase1
                    )
                )
                .frame(width: cellWidth, height: cellHeight)

            // Layer 5: Bright core
            HexagonShape()
                .stroke(Color(hex: "aaffcc"), lineWidth: 3)
                .frame(width: cellWidth, height: cellHeight)
        }
        .onAppear {
            // Energy flow animations
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                flowPhase1 = -36
            }
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                flowPhase2 = -36
            }
            // Glow pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowOpacity = 0.8
            }
        }
    }
}

// MARK: - Cell Pulse Modifier

/// Pulsing glow effect for current cells
struct CellPulseModifier: ViewModifier {
    @State private var glowAmount: CGFloat = 0.4

    func body(content: Content) -> some View {
        content
            .shadow(color: Color(hex: "00ffc8").opacity(glowAmount), radius: 15)
            .shadow(color: Color(hex: "00ffc8").opacity(glowAmount * 0.5), radius: 30)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    glowAmount = 1.0
                }
            }
    }
}

// MARK: - Optional Modifier Extension

extension View {
    @ViewBuilder
    func modifier<T: ViewModifier>(_ modifier: T?) -> some View {
        if let modifier = modifier {
            self.modifier(modifier)
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview("Cell States") {
    VStack(spacing: 30) {
        HStack(spacing: 40) {
            VStack {
                HexCellView(state: .start, expression: "3 + 5")
                Text("Start").font(.caption).foregroundColor(.white)
            }
            VStack {
                HexCellView(state: .normal, expression: "7 × 4")
                Text("Normal").font(.caption).foregroundColor(.white)
            }
            VStack {
                HexCellView(state: .current, expression: "12 − 5")
                Text("Current").font(.caption).foregroundColor(.white)
            }
        }
        HStack(spacing: 40) {
            VStack {
                HexCellView(state: .visited, expression: "6 + 9")
                Text("Visited").font(.caption).foregroundColor(.white)
            }
            VStack {
                HexCellView(state: .finish, expression: "FINISH")
                Text("Finish").font(.caption).foregroundColor(.white)
            }
            VStack {
                HexCellView(state: .wrong, expression: "8 ÷ 2")
                Text("Wrong").font(.caption).foregroundColor(.white)
            }
        }
    }
    .padding(40)
    .background(AppTheme.gridBackground)
}
```

Ensure:
1. All 6 cell states match web app colors exactly
2. 3D poker chip effect with correct layer offsets
3. Electric glow animation for current/start cells
4. Text is white (#ffffff) except finish (gold #ffdd44)
```

### Acceptance Criteria
- [ ] All 6 cell states render correctly
- [ ] 3D depth effect visible
- [ ] Electric glow animation works
- [ ] Text visibility is good
- [ ] Colors match web app exactly

---

## Subphase 3.3: Connector Component

### Objective
Create the connector lines with electric flow animation for traversed state.

### Technical Prompt for Claude Code

```
Create the connector component with electric flow animation.

FILE: Modules/CircuitChallenge/Components/ConnectorView.swift

```swift
import SwiftUI

// MARK: - ConnectorView

/// Connector line between two cells
struct ConnectorView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let value: Int
    let isTraversed: Bool
    let isWrong: Bool
    let animationDelay: Double

    @State private var flowPhase1: CGFloat = 0
    @State private var flowPhase2: CGFloat = 0
    @State private var glowOpacity: CGFloat = 0.5

    init(
        startPoint: CGPoint,
        endPoint: CGPoint,
        value: Int,
        isTraversed: Bool = false,
        isWrong: Bool = false,
        animationDelay: Double = 0
    ) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.value = value
        self.isTraversed = isTraversed
        self.isWrong = isWrong
        self.animationDelay = animationDelay
    }

    // Shorten endpoints to not overlap with cells
    private var shortenBy: CGFloat { 25 }

    private var direction: CGPoint {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let length = sqrt(dx * dx + dy * dy)
        return CGPoint(x: dx / length, y: dy / length)
    }

    private var shortenedStart: CGPoint {
        CGPoint(
            x: startPoint.x + direction.x * shortenBy,
            y: startPoint.y + direction.y * shortenBy
        )
    }

    private var shortenedEnd: CGPoint {
        CGPoint(
            x: endPoint.x - direction.x * shortenBy,
            y: endPoint.y - direction.y * shortenBy
        )
    }

    private var midPoint: CGPoint {
        CGPoint(
            x: (shortenedStart.x + shortenedEnd.x) / 2,
            y: (shortenedStart.y + shortenedEnd.y) / 2
        )
    }

    var body: some View {
        ZStack {
            if isWrong {
                wrongConnector
            } else if isTraversed {
                traversedConnector
            } else {
                defaultConnector
            }
        }
        .onAppear {
            if isTraversed {
                startAnimations()
            }
        }
        .onChange(of: isTraversed) { _, newValue in
            if newValue {
                startAnimations()
            }
        }
    }

    // MARK: - Default Connector

    private var defaultConnector: some View {
        ZStack {
            // Main line
            ConnectorLine(start: shortenedStart, end: shortenedEnd)
                .stroke(Color(hex: "3d3428"), lineWidth: 8)
                .strokeStyle(StrokeStyle(lineWidth: 8, lineCap: .round))

            // Value badge
            ConnectorBadge(
                value: value,
                position: midPoint,
                backgroundColor: Color(hex: "15151f"),
                borderColor: Color(hex: "2a2a3a"),
                textColor: Color(hex: "ff9f43")
            )
        }
    }

    // MARK: - Traversed Connector

    private var traversedConnector: some View {
        ZStack {
            // Layer 1: Glow
            ConnectorLine(start: shortenedStart, end: shortenedEnd)
                .stroke(Color(hex: "00ff88").opacity(glowOpacity), lineWidth: 18)
                .blur(radius: 6)

            // Layer 2: Main line
            ConnectorLine(start: shortenedStart, end: shortenedEnd)
                .stroke(Color(hex: "00dd77"), lineWidth: 10)
                .strokeStyle(StrokeStyle(lineWidth: 10, lineCap: .round))

            // Layer 3: Energy flow slow
            ConnectorLine(start: shortenedStart, end: shortenedEnd)
                .stroke(
                    Color(hex: "88ffcc"),
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round,
                        dash: [6, 30],
                        dashPhase: flowPhase2
                    )
                )

            // Layer 4: Energy flow fast
            ConnectorLine(start: shortenedStart, end: shortenedEnd)
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round,
                        dash: [4, 20],
                        dashPhase: flowPhase1
                    )
                )

            // Layer 5: Bright core
            ConnectorLine(start: shortenedStart, end: shortenedEnd)
                .stroke(Color(hex: "aaffcc"), lineWidth: 3)
                .strokeStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

            // Value badge
            ConnectorBadge(
                value: value,
                position: midPoint,
                backgroundColor: Color(hex: "0a3020"),
                borderColor: Color(hex: "00ff88"),
                textColor: Color(hex: "00ff88")
            )
        }
    }

    // MARK: - Wrong Connector

    private var wrongConnector: some View {
        ZStack {
            // Main line
            ConnectorLine(start: shortenedStart, end: shortenedEnd)
                .stroke(Color(hex: "ef4444"), lineWidth: 8)
                .strokeStyle(StrokeStyle(lineWidth: 8, lineCap: .round))

            // Value badge
            ConnectorBadge(
                value: value,
                position: midPoint,
                backgroundColor: Color(hex: "7f1d1d"),
                borderColor: Color(hex: "ef4444"),
                textColor: Color(hex: "ef4444")
            )
        }
    }

    // MARK: - Animation

    private func startAnimations() {
        // Small delay for staggered effect
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay / 1000) {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                flowPhase1 = -36
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (animationDelay + 200) / 1000) {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                flowPhase2 = -36
            }
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }
    }
}

// MARK: - Connector Line Shape

struct ConnectorLine: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}

// MARK: - Connector Badge

struct ConnectorBadge: View {
    let value: Int
    let position: CGPoint
    let backgroundColor: Color
    let borderColor: Color
    let textColor: Color

    private let badgeWidth: CGFloat = 32
    private let badgeHeight: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .frame(width: badgeWidth, height: badgeHeight)

            RoundedRectangle(cornerRadius: 6)
                .stroke(borderColor, lineWidth: 2)
                .frame(width: badgeWidth, height: badgeHeight)

            Text("\(value)")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(textColor)
        }
        .position(position)
    }
}

// MARK: - Preview

#Preview("Connector States") {
    ZStack {
        AppTheme.gridBackground
            .ignoresSafeArea()

        VStack(spacing: 60) {
            // Default connector
            ZStack {
                ConnectorView(
                    startPoint: CGPoint(x: 50, y: 50),
                    endPoint: CGPoint(x: 200, y: 50),
                    value: 15,
                    isTraversed: false,
                    isWrong: false
                )
                Text("Default").position(x: 125, y: 80).foregroundColor(.white)
            }
            .frame(width: 250, height: 100)

            // Traversed connector
            ZStack {
                ConnectorView(
                    startPoint: CGPoint(x: 50, y: 50),
                    endPoint: CGPoint(x: 200, y: 50),
                    value: 24,
                    isTraversed: true,
                    isWrong: false
                )
                Text("Traversed").position(x: 125, y: 80).foregroundColor(.white)
            }
            .frame(width: 250, height: 100)

            // Wrong connector
            ZStack {
                ConnectorView(
                    startPoint: CGPoint(x: 50, y: 50),
                    endPoint: CGPoint(x: 200, y: 50),
                    value: 8,
                    isTraversed: false,
                    isWrong: true
                )
                Text("Wrong").position(x: 125, y: 80).foregroundColor(.white)
            }
            .frame(width: 250, height: 100)
        }
    }
}
```

Ensure:
1. Three connector states: default, traversed, wrong
2. Electric flow animation matches web exactly
3. Value badges positioned at midpoint
4. Endpoints shortened to not overlap cells
```

### Acceptance Criteria
- [ ] Default connector renders with brown color
- [ ] Traversed connector has electric glow effect
- [ ] Wrong connector renders red
- [ ] Value badges display correctly
- [ ] Animation timing matches web app

---

## Subphase 3.4: Complete Puzzle Grid

### Objective
Compose the complete puzzle grid with cells and connectors.

### Technical Prompt for Claude Code

```
Create the complete puzzle grid view that composes cells and connectors.

FILE: Modules/CircuitChallenge/Components/PuzzleGridView.swift

```swift
import SwiftUI

// MARK: - PuzzleGridView

/// Complete puzzle grid with cells and connectors
struct PuzzleGridView: View {
    let puzzle: Puzzle
    let currentPosition: Coordinate
    let visitedCells: [Coordinate]
    let traversedConnectors: [(cellA: Coordinate, cellB: Coordinate)]
    let wrongMoves: [Coordinate]
    let wrongConnectors: [(cellA: Coordinate, cellB: Coordinate)]
    let showSolution: Bool
    let disabled: Bool
    let onCellTap: ((Coordinate) -> Void)?

    @State private var geometry: HexagonGeometry = .standard

    init(
        puzzle: Puzzle,
        currentPosition: Coordinate,
        visitedCells: [Coordinate] = [],
        traversedConnectors: [(cellA: Coordinate, cellB: Coordinate)] = [],
        wrongMoves: [Coordinate] = [],
        wrongConnectors: [(cellA: Coordinate, cellB: Coordinate)] = [],
        showSolution: Bool = false,
        disabled: Bool = false,
        onCellTap: ((Coordinate) -> Void)? = nil
    ) {
        self.puzzle = puzzle
        self.currentPosition = currentPosition
        self.visitedCells = visitedCells
        self.traversedConnectors = traversedConnectors
        self.wrongMoves = wrongMoves
        self.wrongConnectors = wrongConnectors
        self.showSolution = showSolution
        self.disabled = disabled
        self.onCellTap = onCellTap
    }

    var body: some View {
        GeometryReader { geo in
            let scaledGeometry = HexagonGeometry.scaled(
                for: geo.size,
                rows: puzzle.rows,
                cols: puzzle.cols
            )

            ZStack(alignment: .topLeading) {
                // START label
                startLabel(geometry: scaledGeometry)

                // Connectors layer (behind cells)
                connectorsLayer(geometry: scaledGeometry)

                // Cells layer (on top)
                cellsLayer(geometry: scaledGeometry)
            }
            .frame(
                width: scaledGeometry.gridWidth(cols: puzzle.cols),
                height: scaledGeometry.gridHeight(rows: puzzle.rows)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                geometry = scaledGeometry
            }
            .onChange(of: geo.size) { _, newSize in
                geometry = HexagonGeometry.scaled(for: newSize, rows: puzzle.rows, cols: puzzle.cols)
            }
        }
    }

    // MARK: - START Label

    private func startLabel(geometry: HexagonGeometry) -> some View {
        let startCenter = geometry.cellCenter(row: 0, col: 0)
        return Text("START")
            .font(.system(size: 11, weight: .bold))
            .tracking(2)
            .foregroundColor(Color(hex: "00ff88"))
            .shadow(color: Color(hex: "00ff88").opacity(0.6), radius: 6)
            .position(x: startCenter.x, y: 20)
    }

    // MARK: - Connectors Layer

    private func connectorsLayer(geometry: HexagonGeometry) -> some View {
        ForEach(Array(puzzle.connectors.enumerated()), id: \.offset) { index, connector in
            let isTraversed = isConnectorTraversed(connector.cellA, connector.cellB)
            let traversalDir = isTraversed ? getTraversalDirection(connector.cellA, connector.cellB) : nil

            let fromCoord = traversalDir?.from ?? connector.cellA
            let toCoord = traversalDir?.to ?? connector.cellB

            let startPoint = geometry.cellCenter(row: fromCoord.row, col: fromCoord.col)
            let endPoint = geometry.cellCenter(row: toCoord.row, col: toCoord.col)

            ConnectorView(
                startPoint: startPoint,
                endPoint: endPoint,
                value: connector.value,
                isTraversed: isTraversed,
                isWrong: isConnectorWrong(connector.cellA, connector.cellB),
                animationDelay: Double(index * 50)
            )
        }
    }

    // MARK: - Cells Layer

    private func cellsLayer(geometry: HexagonGeometry) -> some View {
        ForEach(0..<puzzle.rows, id: \.self) { row in
            ForEach(0..<puzzle.cols, id: \.self) { col in
                let cell = puzzle.grid[row][col]
                let center = geometry.cellCenter(row: row, col: col)
                let state = getCellState(row: row, col: col)
                let clickable = isCellClickable(row: row, col: col)
                let displayExpression = cell.isFinish ? "FINISH" : cell.expression

                HexCellView(
                    state: state,
                    expression: displayExpression,
                    size: geometry.cellRadius,
                    isClickable: clickable,
                    onTap: clickable ? { onCellTap?(Coordinate(row: row, col: col)) } : nil
                )
                .position(center)
            }
        }
    }

    // MARK: - State Helpers

    private func getCellState(row: Int, col: Int) -> CellState {
        let coord = Coordinate(row: row, col: col)
        let isStart = row == 0 && col == 0
        let isFinish = row == puzzle.rows - 1 && col == puzzle.cols - 1
        let isCurrent = currentPosition == coord
        let isVisited = visitedCells.contains(coord)
        let isWrong = wrongMoves.contains(coord)

        if isWrong { return .wrong }
        if isCurrent { return .current }
        if isStart && isVisited { return .visited }
        if isStart { return .start }
        if isFinish { return .finish }
        if isVisited { return .visited }
        return .normal
    }

    private func isCellClickable(row: Int, col: Int) -> Bool {
        guard !disabled, let _ = onCellTap else { return false }
        let rowDiff = abs(row - currentPosition.row)
        let colDiff = abs(col - currentPosition.col)
        return rowDiff <= 1 && colDiff <= 1 && !(rowDiff == 0 && colDiff == 0)
    }

    // MARK: - Connector Helpers

    private func isConnectorTraversed(_ cellA: Coordinate, _ cellB: Coordinate) -> Bool {
        // If showing solution, highlight all solution path connectors
        if showSolution && isConnectorOnSolutionPath(cellA, cellB) {
            return true
        }

        return traversedConnectors.contains { tc in
            (tc.cellA == cellA && tc.cellB == cellB) ||
            (tc.cellA == cellB && tc.cellB == cellA)
        }
    }

    private func isConnectorOnSolutionPath(_ cellA: Coordinate, _ cellB: Coordinate) -> Bool {
        let path = puzzle.solution.path
        for i in 0..<(path.count - 1) {
            let from = path[i]
            let to = path[i + 1]
            if (from == cellA && to == cellB) || (from == cellB && to == cellA) {
                return true
            }
        }
        return false
    }

    private func getTraversalDirection(_ cellA: Coordinate, _ cellB: Coordinate) -> (from: Coordinate, to: Coordinate)? {
        // Check traversed connectors first
        if let match = traversedConnectors.first(where: { tc in
            (tc.cellA == cellA && tc.cellB == cellB) ||
            (tc.cellA == cellB && tc.cellB == cellA)
        }) {
            return (from: match.cellA, to: match.cellB)
        }

        // If showing solution, get direction from path
        if showSolution {
            let path = puzzle.solution.path
            for i in 0..<(path.count - 1) {
                let from = path[i]
                let to = path[i + 1]
                if (from == cellA && to == cellB) || (from == cellB && to == cellA) {
                    return (from: from, to: to)
                }
            }
        }

        return nil
    }

    private func isConnectorWrong(_ cellA: Coordinate, _ cellB: Coordinate) -> Bool {
        wrongConnectors.contains { wc in
            (wc.cellA == cellA && wc.cellB == cellB) ||
            (wc.cellA == cellB && wc.cellB == cellA)
        }
    }
}

// MARK: - Preview

#Preview("Puzzle Grid") {
    // Create a mock puzzle for preview
    let mockPuzzle = createMockPuzzle()

    ZStack {
        StarryBackground()

        PuzzleGridView(
            puzzle: mockPuzzle,
            currentPosition: Coordinate(row: 0, col: 0),
            visitedCells: [],
            traversedConnectors: [],
            showSolution: false,
            disabled: false
        ) { coord in
            print("Tapped cell: \(coord.row), \(coord.col)")
        }
    }
}

// MARK: - Mock Puzzle for Preview

private func createMockPuzzle() -> Puzzle {
    // Create a simple 3x4 puzzle for preview
    var cells: [[Cell]] = []
    for row in 0..<3 {
        var rowCells: [Cell] = []
        for col in 0..<4 {
            let isStart = row == 0 && col == 0
            let isFinish = row == 2 && col == 3
            let expression = isStart ? "5 + 3" : (isFinish ? "" : "\(row * 4 + col + 5) + \(col + 1)")
            let answer = isFinish ? nil : (row * 4 + col + 5 + col + 1)

            rowCells.append(Cell(
                row: row,
                col: col,
                expression: expression,
                answer: answer,
                isStart: isStart,
                isFinish: isFinish
            ))
        }
        cells.append(rowCells)
    }

    // Create some mock connectors
    var connectors: [Connector] = []
    // Horizontal connectors
    for row in 0..<3 {
        for col in 0..<3 {
            connectors.append(Connector(
                type: .horizontal,
                cellA: Coordinate(row: row, col: col),
                cellB: Coordinate(row: row, col: col + 1),
                value: row * 3 + col + 8
            ))
        }
    }
    // Vertical connectors
    for row in 0..<2 {
        for col in 0..<4 {
            connectors.append(Connector(
                type: .vertical,
                cellA: Coordinate(row: row, col: col),
                cellB: Coordinate(row: row + 1, col: col),
                value: row * 4 + col + 15
            ))
        }
    }

    return Puzzle(
        id: "preview",
        difficulty: 1,
        grid: cells,
        connectors: connectors,
        solution: Solution(path: [
            Coordinate(row: 0, col: 0),
            Coordinate(row: 0, col: 1),
            Coordinate(row: 1, col: 1),
            Coordinate(row: 2, col: 2),
            Coordinate(row: 2, col: 3)
        ])
    )
}
```

Ensure:
1. Grid scales properly for different screen sizes
2. START label positioned correctly
3. Connectors render behind cells
4. Cell tap detection works for adjacent cells only
5. View Solution mode highlights solution path
```

### Acceptance Criteria
- [ ] Grid renders with correct spacing
- [ ] Cells and connectors properly layered
- [ ] START label visible above grid
- [ ] Cell tap only works for adjacent cells
- [ ] Show Solution mode works

---

## Subphase 3.5: Lives & Timer Display

### Objective
Create the lives display (hearts) and timer display components.

### Technical Prompt for Claude Code

```
Create the lives display (hearts) and timer display components.

FILE: Modules/CircuitChallenge/Components/LivesDisplay.swift

```swift
import SwiftUI

// MARK: - LivesDisplay

/// Display of remaining lives as hearts
struct LivesDisplay: View {
    let lives: Int
    let maxLives: Int
    let vertical: Bool
    let onLifeLost: (() -> Void)?

    @State private var breakingHeartIndex: Int?

    init(
        lives: Int,
        maxLives: Int = 5,
        vertical: Bool = false,
        onLifeLost: (() -> Void)? = nil
    ) {
        self.lives = lives
        self.maxLives = maxLives
        self.vertical = vertical
        self.onLifeLost = onLifeLost
    }

    var body: some View {
        Group {
            if vertical {
                VStack(spacing: 8) {
                    heartStack
                }
            } else {
                HStack(spacing: 8) {
                    heartStack
                }
            }
        }
    }

    private var heartStack: some View {
        ForEach(0..<maxLives, id: \.self) { index in
            HeartView(
                isActive: index < lives,
                isBreaking: breakingHeartIndex == index
            )
        }
    }

    /// Trigger heart break animation when life is lost
    func loseLife(at index: Int) {
        breakingHeartIndex = index
        onLifeLost?()

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            breakingHeartIndex = nil
        }
    }
}

// MARK: - HeartView

struct HeartView: View {
    let isActive: Bool
    let isBreaking: Bool

    @State private var scale: CGFloat = 1.0

    private let activeColor = Color(hex: "ff3366")
    private let inactiveColor = Color(hex: "2a2a3a")

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 20))
            .foregroundColor(isActive ? activeColor : inactiveColor)
            .scaleEffect(scale)
            .animation(isBreaking ? .easeOut(duration: 0.5) : nil, value: isBreaking)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        scale = 1.15
                    }
                }
            }
            .onChange(of: isBreaking) { _, breaking in
                if breaking {
                    // Heart break animation
                    withAnimation(.easeOut(duration: 0.1)) {
                        scale = 1.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            scale = 0.5
                        }
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview("Lives Display") {
    VStack(spacing: 40) {
        VStack {
            Text("5 Lives").foregroundColor(.white)
            LivesDisplay(lives: 5)
        }

        VStack {
            Text("3 Lives").foregroundColor(.white)
            LivesDisplay(lives: 3)
        }

        VStack {
            Text("1 Life").foregroundColor(.white)
            LivesDisplay(lives: 1)
        }

        VStack {
            Text("0 Lives").foregroundColor(.white)
            LivesDisplay(lives: 0)
        }

        VStack {
            Text("Vertical").foregroundColor(.white)
            LivesDisplay(lives: 4, vertical: true)
        }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
```

FILE: Modules/CircuitChallenge/Components/TimerDisplay.swift

```swift
import SwiftUI

// MARK: - TimerDisplay

/// Timer display showing elapsed time
struct TimerDisplay: View {
    let elapsedSeconds: Int
    let isRunning: Bool
    let compact: Bool

    init(elapsedSeconds: Int, isRunning: Bool = true, compact: Bool = false) {
        self.elapsedSeconds = elapsedSeconds
        self.isRunning = isRunning
        self.compact = compact
    }

    private var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack(spacing: compact ? 4 : 8) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: compact ? 16 : 20))
                .foregroundColor(AppTheme.textSecondary)

            Text(formattedTime)
                .font(.system(size: compact ? 16 : 20, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.backgroundMid.opacity(0.8))
        )
    }
}

// MARK: - Timer Manager

/// Observable timer for game timing
@MainActor
class GameTimer: ObservableObject {
    @Published var elapsedSeconds: Int = 0
    @Published var isRunning: Bool = false

    private var timer: Timer?

    func start() {
        guard !isRunning else { return }
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedSeconds += 1
            }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        elapsedSeconds = 0
    }

    func stop() -> Int {
        pause()
        return elapsedSeconds
    }
}

// MARK: - Preview

#Preview("Timer Display") {
    VStack(spacing: 20) {
        TimerDisplay(elapsedSeconds: 0)
        TimerDisplay(elapsedSeconds: 45)
        TimerDisplay(elapsedSeconds: 125)
        TimerDisplay(elapsedSeconds: 3661)
        TimerDisplay(elapsedSeconds: 45, compact: true)
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
```

FILE: Modules/CircuitChallenge/Components/ActionButtons.swift

```swift
import SwiftUI

// MARK: - ActionButtons

/// Game action buttons (Reset, New Puzzle, etc.)
struct ActionButtons: View {
    let onReset: () -> Void
    let onNewPuzzle: () -> Void
    let onViewSolution: (() -> Void)?
    let onContinue: (() -> Void)?
    let showViewSolution: Bool
    let showContinue: Bool
    let vertical: Bool

    init(
        onReset: @escaping () -> Void,
        onNewPuzzle: @escaping () -> Void,
        onViewSolution: (() -> Void)? = nil,
        onContinue: (() -> Void)? = nil,
        showViewSolution: Bool = false,
        showContinue: Bool = false,
        vertical: Bool = false
    ) {
        self.onReset = onReset
        self.onNewPuzzle = onNewPuzzle
        self.onViewSolution = onViewSolution
        self.onContinue = onContinue
        self.showViewSolution = showViewSolution
        self.showContinue = showContinue
        self.vertical = vertical
    }

    var body: some View {
        Group {
            if vertical {
                VStack(spacing: 12) {
                    buttonContent
                }
            } else {
                HStack(spacing: 16) {
                    buttonContent
                }
            }
        }
    }

    @ViewBuilder
    private var buttonContent: some View {
        // Reset button
        ActionButton(
            icon: "arrow.clockwise",
            label: vertical ? nil : "Reset",
            action: onReset
        )

        // New Puzzle button
        ActionButton(
            icon: "sparkles",
            label: vertical ? nil : "New",
            action: onNewPuzzle
        )

        // View Solution button (when game over)
        if showViewSolution, let viewSolution = onViewSolution {
            ActionButton(
                icon: "eye",
                label: vertical ? nil : "Solution",
                action: viewSolution,
                highlighted: true
            )
        }

        // Continue button (after viewing solution)
        if showContinue, let continueAction = onContinue {
            ActionButton(
                icon: "arrow.right",
                label: vertical ? nil : "Continue",
                action: continueAction,
                highlighted: true
            )
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let label: String?
    let action: () -> Void
    let highlighted: Bool

    @State private var isPressed = false

    init(icon: String, label: String? = nil, action: @escaping () -> Void, highlighted: Bool = false) {
        self.icon = icon
        self.label = label
        self.action = action
        self.highlighted = highlighted
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))

                if let label = label {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(highlighted ? AppTheme.accentPrimary : AppTheme.textPrimary)
            .padding(.horizontal, label != nil ? 16 : 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(highlighted ? AppTheme.accentPrimary.opacity(0.2) : AppTheme.backgroundMid)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(highlighted ? AppTheme.accentPrimary.opacity(0.5) : AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview("Action Buttons") {
    VStack(spacing: 40) {
        VStack {
            Text("Horizontal").foregroundColor(.white)
            ActionButtons(
                onReset: {},
                onNewPuzzle: {}
            )
        }

        VStack {
            Text("With Solution").foregroundColor(.white)
            ActionButtons(
                onReset: {},
                onNewPuzzle: {},
                onViewSolution: {},
                showViewSolution: true
            )
        }

        VStack {
            Text("With Continue").foregroundColor(.white)
            ActionButtons(
                onReset: {},
                onNewPuzzle: {},
                onContinue: {},
                showContinue: true
            )
        }

        VStack {
            Text("Vertical").foregroundColor(.white)
            ActionButtons(
                onReset: {},
                onNewPuzzle: {},
                vertical: true
            )
        }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
```

Ensure:
1. Hearts pulse when active
2. Heart break animation on life loss
3. Timer displays in M:SS format
4. Action buttons have press feedback
5. Vertical mode for landscape layout
```

### Acceptance Criteria
- [ ] Hearts display with correct colors
- [ ] Hearts pulse animation works
- [ ] Timer format is correct (M:SS)
- [ ] GameTimer class works for timing
- [ ] Action buttons have press feedback
- [ ] Vertical layouts work for landscape

---

## Phase 3 Completion Checklist

- [ ] Hexagon shape renders correctly (pointy-top)
- [ ] All 6 cell states match web colors exactly
- [ ] 3D poker chip effect visible
- [ ] Electric glow animation for current/start cells
- [ ] All 3 connector states render correctly
- [ ] Electric flow animation on traversed connectors
- [ ] Complete grid composes properly
- [ ] Grid scales for different devices
- [ ] Lives display with pulse animation
- [ ] Timer display works correctly
- [ ] Action buttons have feedback

---

## Files Created in Phase 3

```
Modules/CircuitChallenge/Components/
├── HexagonGeometry.swift
├── HexCellView.swift
├── ConnectorView.swift
├── PuzzleGridView.swift
├── LivesDisplay.swift
├── TimerDisplay.swift
└── ActionButtons.swift
```

---

*End of Phase 3*
