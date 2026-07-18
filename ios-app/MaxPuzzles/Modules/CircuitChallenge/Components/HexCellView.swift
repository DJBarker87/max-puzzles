import SwiftUI

// MARK: - Cell Gradients

/// Gradient definitions for each cell state matching web app exactly
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

/// One sampled animation frame drives every active-cell effect. Keeping the original periods and
/// equations here guarantees the electric border and outer pulse retain their existing motion while
/// avoiding two independent 30 fps `TimelineView` trees for the same cell.
struct CircuitCellAnimationFrame: Equatable {
    let fastFlowPhase: CGFloat
    let slowFlowPhase: CGFloat
    let electricGlowOpacity: CGFloat
    let shadowGlowAmount: CGFloat

    static func values(
        at time: TimeInterval,
        size: CGFloat,
        compact: Bool,
        reduceMotion: Bool
    ) -> CircuitCellAnimationFrame {
        let resolvedTime = reduceMotion ? 0 : time
        let sizeScale = size / 42.0
        let fastProgress = resolvedTime.truncatingRemainder(dividingBy: 0.8) / 0.8
        let slowProgress = resolvedTime.truncatingRemainder(dividingBy: 1.2) / 1.2
        let electricPulse = (sin(resolvedTime * 2 * .pi / 1.5) + 1) / 2
        let shadowPulse = (sin(resolvedTime * 2 * .pi) + 1) / 2
        let maximumElectricGlow = compact ? 0.6 : 0.8
        let maximumShadowGlow = compact ? 0.7 : 1.0

        return CircuitCellAnimationFrame(
            fastFlowPhase: reduceMotion ? 0 : CGFloat(-36 * fastProgress) * sizeScale,
            slowFlowPhase: reduceMotion ? 0 : CGFloat(-36 * slowProgress) * sizeScale,
            electricGlowOpacity: reduceMotion
                ? 0.55
                : CGFloat(0.5 + (maximumElectricGlow - 0.5) * electricPulse),
            shadowGlowAmount: reduceMotion
                ? 0.45
                : CGFloat(0.4 + (maximumShadowGlow - 0.4) * shadowPulse)
        )
    }
}

// MARK: - HexCellView

/// 3D hexagonal cell with poker chip effect matching web app exactly
struct HexCellView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let state: CellState
    let expression: String
    let size: CGFloat
    let isClickable: Bool
    let compactGlow: Bool  // Reduced glow for phones with small grids (4 rows)
    let onTap: (() -> Void)?

    init(
        state: CellState,
        expression: String,
        size: CGFloat = 42,
        isClickable: Bool = false,
        compactGlow: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.state = state
        self.expression = expression
        self.size = size
        self.isClickable = isClickable
        self.compactGlow = compactGlow
        self.onTap = onTap
    }

    private var gradients: CellGradients {
        CellGradients.forState(state)
    }

    private var isPulsing: Bool {
        state == .current || state == .start
    }

    // Calculate dimensions from radius
    private var cellWidth: CGFloat { size * sqrt(3) }
    private var cellHeight: CGFloat { size * 2 }

    // Layer offsets for 3D poker chip effect (matching web: shadow +14, edge +12, base +6)
    private var shadowOffset: CGFloat { 14 }
    private var edgeOffset: CGFloat { 12 }
    private var baseOffset: CGFloat { 6 }

    // Font size scales with cell size and expression length
    // Base size is ~45% of cell radius for short text, scales down for longer expressions
    private var fontSize: CGFloat {
        let baseSize = size * 0.45

        // Scale down for longer expressions to fit inside hexagon
        // "FINISH" = 6 chars, "5 + 3" = 5 chars, "20 - 14" = 7 chars, "12 × 12" = 7 chars
        if state == .finish { return baseSize * 0.70 }  // FINISH text
        if expression.count > 8 { return baseSize * 0.60 }  // Very long: "100 - 50"
        if expression.count > 6 { return baseSize * 0.70 }  // Long: "20 - 14"
        if expression.count > 4 { return baseSize * 0.85 }  // Medium: "5 + 3"
        return baseSize  // Short: single numbers
    }

    var body: some View {
        Group {
            if isPulsing {
                if reduceMotion {
                    animatedCell(
                        frame: CircuitCellAnimationFrame.values(
                            at: 0,
                            size: size,
                            compact: compactGlow,
                            reduceMotion: true
                        )
                    )
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                        animatedCell(
                            frame: CircuitCellAnimationFrame.values(
                                at: context.date.timeIntervalSinceReferenceDate,
                                size: size,
                                compact: compactGlow,
                                reduceMotion: false
                            )
                        )
                    }
                }
            } else {
                interactiveCell(animationFrame: nil)
            }
        }
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(isClickable ? "Double tap to select this cell" : "")
        .accessibilityAddTraits(isClickable ? .isButton : [])
    }

    private func animatedCell(frame: CircuitCellAnimationFrame) -> some View {
        let sizeScale = size / 42.0
        let innerRadius = (compactGlow ? 8.0 : 15.0) * sizeScale
        let outerRadius = (compactGlow ? 16.0 : 30.0) * sizeScale

        return interactiveCell(animationFrame: frame)
            .shadow(
                color: Color(hex: "00ffc8").opacity(frame.shadowGlowAmount),
                radius: innerRadius
            )
            .shadow(
                color: Color(hex: "00ffc8").opacity(frame.shadowGlowAmount * 0.5),
                radius: outerRadius
            )
    }

    private func interactiveCell(
        animationFrame: CircuitCellAnimationFrame?
    ) -> some View {
        cellLayers(animationFrame: animationFrame)
            .frame(width: cellWidth + 8, height: cellHeight + shadowOffset + 4)
            .contentShape(Rectangle())
            .onTapGesture {
                if isClickable {
                    onTap?()
                }
            }
            .opacity(isClickable ? 1.0 : 0.85)
    }

    private func cellLayers(
        animationFrame: CircuitCellAnimationFrame?
    ) -> some View {
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

            // Layer 4: Top face with stroke
            HexagonShape()
                .fill(gradients.topGradient)
                .frame(width: cellWidth, height: cellHeight)
                .overlay(
                    HexagonShape()
                        .stroke(gradients.strokeColor, lineWidth: gradients.strokeWidth)
                        .frame(width: cellWidth, height: cellHeight)
                )

            // Layer 5: Inner shadow (radial gradient)
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

            // Expression text - white for all except finish (gold)
            Text(expression)
                .font(.system(size: fontSize, weight: .black))
                .foregroundColor(state == .finish ? Color(hex: "ffdd44") : .white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)

            // Electric glow overlay for current/start cells
            if let animationFrame {
                ElectricGlowOverlay(
                    size: size,
                    compact: compactGlow,
                    animationFrame: animationFrame
                )
            }
        }
    }

    private var accessibilityLabelText: String {
        switch state {
        case .start:
            return "Start cell, \(expression)"
        case .finish:
            return "Finish cell"
        case .current:
            return "Current cell, \(expression)"
        case .visited:
            return "Visited cell, \(expression)"
        case .wrong:
            return "Wrong answer cell"
        case .normal:
            return "Cell showing \(expression)"
        }
    }
}

// MARK: - Electric Glow Overlay

/// Electric energy flow effect for current/start cells matching web connector style exactly
struct ElectricGlowOverlay: View {
    let size: CGFloat
    var compact: Bool = false  // Reduced glow for phones with 4 rows
    let animationFrame: CircuitCellAnimationFrame

    private var cellWidth: CGFloat { size * sqrt(3) }
    private var cellHeight: CGFloat { size * 2 }

    // Scale factor based on cell size (baseline is ~42px radius on phones)
    private var sizeScale: CGFloat { size / 42.0 }

    // Scale down glow for compact mode (phones with small grids)
    private var glowScale: CGFloat { compact ? 0.5 : 1.0 }

    // Scaled line widths
    private var glowLineWidth: CGFloat { (compact ? 10 : 18) * sizeScale }
    private var mainLineWidth: CGFloat { (compact ? 6 : 10) * sizeScale }
    private var energySlowWidth: CGFloat { (compact ? 4 : 6) * sizeScale }
    private var energyFastWidth: CGFloat { (compact ? 2 : 4) * sizeScale }
    private var coreWidth: CGFloat { (compact ? 2 : 3) * sizeScale }
    private var blurRadius: CGFloat { (compact ? 3 : 6) * sizeScale }

    // Scaled dash patterns
    private var dashSlow: [CGFloat] { [6 * sizeScale, 30 * sizeScale] }
    private var dashFast: [CGFloat] { [4 * sizeScale, 20 * sizeScale] }

    var body: some View {
        electricLayers(
            flowPhase1: animationFrame.fastFlowPhase,
            flowPhase2: animationFrame.slowFlowPhase,
            glowOpacity: animationFrame.electricGlowOpacity
        )
    }

    private func electricLayers(
        flowPhase1: CGFloat,
        flowPhase2: CGFloat,
        glowOpacity: CGFloat
    ) -> some View {
        ZStack {
            // Layer 1: Glow (blur effect) - scales with cell size
            HexagonShape()
                .stroke(Color(hex: "00ff88").opacity(glowOpacity * glowScale), lineWidth: glowLineWidth)
                .blur(radius: blurRadius)
                .frame(width: cellWidth, height: cellHeight)

            // Layer 2: Main line
            HexagonShape()
                .stroke(Color(hex: "00dd77"), lineWidth: mainLineWidth)
                .frame(width: cellWidth, height: cellHeight)

            // Layer 3: Energy flow slow (dash 6 30, 1.2s)
            HexagonShape()
                .stroke(
                    Color(hex: "88ffcc"),
                    style: StrokeStyle(
                        lineWidth: energySlowWidth,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: dashSlow,
                        dashPhase: flowPhase2
                    )
                )
                .frame(width: cellWidth, height: cellHeight)

            // Layer 4: Energy flow fast (dash 4 20, 0.8s)
            HexagonShape()
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: energyFastWidth,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: dashFast,
                        dashPhase: flowPhase1
                    )
                )
                .frame(width: cellWidth, height: cellHeight)

            // Layer 5: Bright core
            HexagonShape()
                .stroke(Color(hex: "aaffcc"), lineWidth: coreWidth)
                .frame(width: cellWidth, height: cellHeight)
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
                HexCellView(state: .normal, expression: "7 \u{00D7} 4")
                Text("Normal").font(.caption).foregroundColor(.white)
            }
            VStack {
                HexCellView(state: .current, expression: "12 \u{2212} 5")
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
                HexCellView(state: .wrong, expression: "8 \u{00F7} 2")
                Text("Wrong").font(.caption).foregroundColor(.white)
            }
        }
    }
    .padding(40)
    .background(
        LinearGradient(
            colors: [Color(hex: "0a0a12"), Color(hex: "0d0d18")],
            startPoint: .top,
            endPoint: .bottom
        )
    )
}

#Preview("Clickable Cell") {
    VStack {
        HexCellView(
            state: .normal,
            expression: "5 + 3",
            isClickable: true
        ) {
            print("Cell tapped!")
        }
        Text("Tap me!").foregroundColor(.white)
    }
    .padding()
    .background(Color(hex: "0f0f23"))
}
