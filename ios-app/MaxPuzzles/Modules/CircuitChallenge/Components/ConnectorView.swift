import SwiftUI

// MARK: - ConnectorView

/// Connector line between two cells with electric flow animation
/// Matches web app exactly with 5 animation layers
struct ConnectorView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let value: Int
    let isTraversed: Bool
    let isWrong: Bool
    let animationDelay: Double
    let cellRadius: CGFloat  // Added to scale shortening
    let verticalBadgeAtBottom: Bool  // For iPhone 6-row grids: put badge at bottom of vertical connectors

    @State private var flowPhase1: CGFloat = 0
    @State private var flowPhase2: CGFloat = 0
    @State private var glowOpacity: CGFloat = 0.5
    @State private var animationsStarted: Bool = false

    init(
        startPoint: CGPoint,
        endPoint: CGPoint,
        value: Int,
        isTraversed: Bool = false,
        isWrong: Bool = false,
        animationDelay: Double = 0,
        cellRadius: CGFloat = 42,  // Default for backwards compatibility
        verticalBadgeAtBottom: Bool = false
    ) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.value = value
        self.isTraversed = isTraversed
        self.isWrong = isWrong
        self.animationDelay = animationDelay
        self.cellRadius = cellRadius
        self.verticalBadgeAtBottom = verticalBadgeAtBottom
    }

    // Shorten endpoints so connectors extend close to cell edges
    // Reduced from 0.595 to 0.45 to make connectors longer and more visible
    private var shortenBy: CGFloat {
        return cellRadius * 0.45
    }

    private var direction: CGPoint {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return .zero }
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

    /// Check if this connector is primarily vertical (more vertical than horizontal)
    private var isVertical: Bool {
        let dx = abs(endPoint.x - startPoint.x)
        let dy = abs(endPoint.y - startPoint.y)
        return dy > dx * 2  // Vertical if Y delta is more than 2x X delta
    }

    private var badgePosition: CGPoint {
        // For vertical connectors on iPhone 6-row grids, position badge toward bottom
        if verticalBadgeAtBottom && isVertical {
            // Position at 72% down the connector
            return CGPoint(
                x: (shortenedStart.x + shortenedEnd.x) / 2,
                y: shortenedStart.y + (shortenedEnd.y - shortenedStart.y) * 0.72
            )
        }
        // Default: center position
        return CGPoint(
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
            if isTraversed && !animationsStarted {
                startAnimations()
            }
        }
        .onChange(of: isTraversed) { newValue in
            if newValue && !animationsStarted {
                startAnimations()
            }
        }
    }

    // MARK: - Default Connector

    private var defaultConnector: some View {
        ZStack {
            // Main line
            ConnectorLine(start: shortenedStart, end: shortenedEnd)
                .stroke(Color(hex: "3d3428"), style: StrokeStyle(lineWidth: 8, lineCap: .round))

            // Value badge - scales with cell size
            ConnectorBadge(
                value: value,
                position: badgePosition,
                backgroundColor: Color(hex: "15151f"),
                borderColor: Color(hex: "2a2a3a"),
                textColor: Color(hex: "ff9f43"),
                scale: cellRadius / 42  // Scale relative to default 42px radius
            )
        }
    }

    // MARK: - Traversed Connector

    private var traversedConnector: some View {
        ZStack {
            // Layer 1: Glow
            ConnectorLine(start: shortenedStart, end: shortenedEnd)
                .stroke(Color(hex: "00ff88").opacity(glowOpacity), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .blur(radius: 6)

            // Layer 2: Main line
            ConnectorLine(start: shortenedStart, end: shortenedEnd)
                .stroke(Color(hex: "00dd77"), style: StrokeStyle(lineWidth: 10, lineCap: .round))

            // Layer 3: Energy flow slow (dash 6 30, 1.2s)
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

            // Layer 4: Energy flow fast (dash 4 20, 0.8s)
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
                .stroke(Color(hex: "aaffcc"), style: StrokeStyle(lineWidth: 3, lineCap: .round))

            // Value badge - scales with cell size
            ConnectorBadge(
                value: value,
                position: badgePosition,
                backgroundColor: Color(hex: "0a3020"),
                borderColor: Color(hex: "00ff88"),
                textColor: Color(hex: "00ff88"),
                scale: cellRadius / 42
            )
        }
    }

    // MARK: - Wrong Connector

    private var wrongConnector: some View {
        ZStack {
            // Main line
            ConnectorLine(start: shortenedStart, end: shortenedEnd)
                .stroke(Color(hex: "ef4444"), style: StrokeStyle(lineWidth: 8, lineCap: .round))

            // Value badge - scales with cell size
            ConnectorBadge(
                value: value,
                position: badgePosition,
                backgroundColor: Color(hex: "7f1d1d"),
                borderColor: Color(hex: "ef4444"),
                textColor: Color(hex: "ef4444"),
                scale: cellRadius / 42
            )
        }
    }

    // MARK: - Animation

    private func startAnimations() {
        animationsStarted = true

        // Staggered start for energy flow animations
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

        // Glow pulse (matching web: 0.5 to 0.8 over 1.5s)
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }
    }
}

// MARK: - Connector Line Shape

/// Simple line shape between two points
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

/// Value badge displayed at connector midpoint
/// Matches web app exactly: 32x28px base, 14pt font, 6px radius
struct ConnectorBadge: View {
    let value: Int
    let position: CGPoint
    let backgroundColor: Color
    let borderColor: Color
    let textColor: Color
    let scale: CGFloat

    // Web app base sizes (from Connector.tsx)
    // Badge: 32x28px, font: 14pt, radius: 6px, border: 2px
    private var badgeWidth: CGFloat { 32 * scale }
    private var badgeHeight: CGFloat { 28 * scale }
    private var fontSize: CGFloat { 14 * scale }
    private var cornerRadius: CGFloat { 6 * scale }
    private var borderWidth: CGFloat { 2 * scale }

    init(
        value: Int,
        position: CGPoint,
        backgroundColor: Color,
        borderColor: Color,
        textColor: Color,
        scale: CGFloat = 1.0
    ) {
        self.value = value
        self.position = position
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.textColor = textColor
        self.scale = scale
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .frame(width: badgeWidth, height: badgeHeight)

            // Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: borderWidth)
                .frame(width: badgeWidth, height: badgeHeight)

            // Value text
            Text("\(value)")
                .font(.system(size: fontSize, weight: .heavy))
                .foregroundColor(textColor)
        }
        .position(position)
    }
}

// MARK: - Preview

#Preview("Connector States") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "0a0a12"), Color(hex: "0d0d18")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 80) {
            // Default connector
            ZStack {
                ConnectorView(
                    startPoint: CGPoint(x: 50, y: 50),
                    endPoint: CGPoint(x: 250, y: 50),
                    value: 15,
                    isTraversed: false,
                    isWrong: false
                )
                Text("Default").position(x: 150, y: 90).foregroundColor(.white)
            }
            .frame(width: 300, height: 100)

            // Traversed connector
            ZStack {
                ConnectorView(
                    startPoint: CGPoint(x: 50, y: 50),
                    endPoint: CGPoint(x: 250, y: 50),
                    value: 24,
                    isTraversed: true,
                    isWrong: false
                )
                Text("Traversed").position(x: 150, y: 90).foregroundColor(.white)
            }
            .frame(width: 300, height: 100)

            // Wrong connector
            ZStack {
                ConnectorView(
                    startPoint: CGPoint(x: 50, y: 50),
                    endPoint: CGPoint(x: 250, y: 50),
                    value: 8,
                    isTraversed: false,
                    isWrong: true
                )
                Text("Wrong").position(x: 150, y: 90).foregroundColor(.white)
            }
            .frame(width: 300, height: 100)

            // Diagonal connector
            ZStack {
                ConnectorView(
                    startPoint: CGPoint(x: 50, y: 20),
                    endPoint: CGPoint(x: 250, y: 80),
                    value: 12,
                    isTraversed: true,
                    isWrong: false
                )
                Text("Diagonal").position(x: 150, y: 100).foregroundColor(.white)
            }
            .frame(width: 300, height: 120)
        }
    }
}
