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

// MARK: - HexCellView

/// 3D hexagonal cell with poker chip effect matching web app exactly
struct HexCellView: View {
    let state: CellState
    let expression: String
    let size: CGFloat
    let isClickable: Bool
    let onTap: (() -> Void)?

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

    // Calculate dimensions from radius
    private var cellWidth: CGFloat { size * sqrt(3) }
    private var cellHeight: CGFloat { size * 2 }

    // Layer offsets for 3D poker chip effect (matching web: shadow +14, edge +12, base +6)
    private var shadowOffset: CGFloat { 14 }
    private var edgeOffset: CGFloat { 12 }
    private var baseOffset: CGFloat { 6 }

    // Font size based on expression length (matching web exactly)
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
        .modifier(CellPulseModifier(isPulsing: isPulsing))
    }
}

// MARK: - Electric Glow Overlay

/// Electric energy flow effect for current/start cells matching web connector style exactly
struct ElectricGlowOverlay: View {
    let size: CGFloat

    @State private var flowPhase1: CGFloat = 0
    @State private var flowPhase2: CGFloat = 0
    @State private var glowOpacity: CGFloat = 0.5

    private var cellWidth: CGFloat { size * sqrt(3) }
    private var cellHeight: CGFloat { size * 2 }

    var body: some View {
        ZStack {
            // Layer 1: Glow (blur effect)
            HexagonShape()
                .stroke(Color(hex: "00ff88").opacity(glowOpacity), lineWidth: 18)
                .blur(radius: 6)
                .frame(width: cellWidth, height: cellHeight)

            // Layer 2: Main line
            HexagonShape()
                .stroke(Color(hex: "00dd77"), lineWidth: 10)
                .frame(width: cellWidth, height: cellHeight)

            // Layer 3: Energy flow slow (dash 6 30, 1.2s)
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

            // Layer 4: Energy flow fast (dash 4 20, 0.8s)
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
            // Energy flow animations matching web exactly
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                flowPhase1 = -36
            }
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                flowPhase2 = -36
            }
            // Glow pulse (0.5 to 0.8 over 1.5s)
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowOpacity = 0.8
            }
        }
    }
}

// MARK: - Cell Pulse Modifier

/// Pulsing glow effect for current cells matching web animation exactly
struct CellPulseModifier: ViewModifier {
    let isPulsing: Bool
    @State private var glowAmount: CGFloat = 0.4

    func body(content: Content) -> some View {
        if isPulsing {
            content
                .shadow(color: Color(hex: "00ffc8").opacity(glowAmount), radius: 15)
                .shadow(color: Color(hex: "00ffc8").opacity(glowAmount * 0.5), radius: 30)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        glowAmount = 1.0
                    }
                }
        } else {
            content
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
