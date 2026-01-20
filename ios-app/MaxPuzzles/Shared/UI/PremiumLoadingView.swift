import SwiftUI

// MARK: - Premium Loading View

/// Hexagonal loading indicator with animated energy flow
struct PremiumLoadingView: View {
    let message: String
    var size: CGFloat = 80

    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1
    @State private var dotProgress: CGFloat = 0
    @State private var messageIndex: Int = 0

    private let messages = [
        "Generating puzzle...",
        "Calculating path...",
        "Building circuit...",
        "Almost ready..."
    ]

    private var displayMessage: String {
        message.isEmpty ? messages[messageIndex % messages.count] : message
    }

    var body: some View {
        VStack(spacing: 24) {
            // Hexagonal loader
            ZStack {
                // Outer glow pulse
                HexagonShape()
                    .fill(AppTheme.connectorGlow.opacity(0.2))
                    .frame(width: size * 1.3, height: size * 1.3)
                    .blur(radius: 15)
                    .scaleEffect(pulseScale)

                // Rotating outer ring
                HexagonShape()
                    .stroke(
                        AngularGradient(
                            colors: [
                                AppTheme.connectorGlow.opacity(0),
                                AppTheme.connectorGlow,
                                AppTheme.connectorGlow.opacity(0)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(rotation))

                // Inner hexagon
                HexagonShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.backgroundMid,
                                AppTheme.backgroundDark
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.7, height: size * 0.7)

                // Energy dots orbiting
                ForEach(0..<6, id: \.self) { i in
                    let angle = (Double(i) / 6.0 * 360 + rotation * 2).truncatingRemainder(dividingBy: 360)
                    let radians = angle * .pi / 180
                    let radius = size * 0.35

                    Circle()
                        .fill(AppTheme.connectorGlow)
                        .frame(width: 6, height: 6)
                        .shadow(color: AppTheme.connectorGlow, radius: 4)
                        .offset(
                            x: cos(radians) * radius,
                            y: sin(radians) * radius
                        )
                        .opacity(0.6 + 0.4 * sin(radians + dotProgress * .pi * 2))
                }

                // Center bolt icon
                Image(systemName: "bolt.fill")
                    .font(.system(size: size * 0.25))
                    .foregroundColor(AppTheme.connectorGlow)
                    .shadow(color: AppTheme.connectorGlow.opacity(0.8), radius: 6)
            }

            // Loading message with animated dots
            HStack(spacing: 4) {
                Text(displayMessage)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)

                // Animated dots
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(AppTheme.textSecondary)
                            .frame(width: 4, height: 4)
                            .opacity(dotAnimation(for: i))
                    }
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func dotAnimation(for index: Int) -> Double {
        let phase = (dotProgress + Double(index) * 0.3).truncatingRemainder(dividingBy: 1)
        return 0.3 + 0.7 * sin(phase * .pi)
    }

    private func startAnimations() {
        // Rotation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotation = 360
        }

        // Pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }

        // Dot progress
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            dotProgress = 1
        }

        // Cycle messages
        if message.isEmpty {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation {
                    messageIndex += 1
                }
            }
        }
    }
}

// MARK: - Mini Hexagon Loader

/// Compact loading indicator for inline use
struct MiniHexLoader: View {
    var size: CGFloat = 24
    var color: Color = AppTheme.connectorGlow

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            HexagonShape()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .frame(width: size, height: size)

            HexagonShape()
                .trim(from: 0, to: 0.6)
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Generating Puzzle Overlay

/// Full-screen overlay shown while generating puzzles
struct GeneratingPuzzleOverlay: View {
    @State private var gridOpacity: [Double] = Array(repeating: 0.2, count: 9)

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Animated mini grid
                VStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { col in
                                let index = row * 3 + col
                                HexagonShape()
                                    .fill(AppTheme.connectorGlow.opacity(gridOpacity[index]))
                                    .frame(width: 30, height: 30)
                                    .shadow(
                                        color: AppTheme.connectorGlow.opacity(gridOpacity[index] * 0.5),
                                        radius: 6
                                    )
                            }
                        }
                    }
                }

                PremiumLoadingView(message: "", size: 60)
            }
        }
        .onAppear {
            animateGrid()
        }
    }

    private func animateGrid() {
        // Animate cells in sequence
        let sequence = [0, 1, 2, 5, 8, 7, 6, 3, 4]

        for (i, cellIndex) in sequence.enumerated() {
            withAnimation(
                .easeInOut(duration: 0.3)
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.15)
            ) {
                gridOpacity[cellIndex] = 0.8
            }
        }
    }
}

#Preview("Premium Loading") {
    ZStack {
        AppTheme.backgroundDark.ignoresSafeArea()
        PremiumLoadingView(message: "Generating puzzle...")
    }
}

#Preview("Mini Loader") {
    ZStack {
        AppTheme.backgroundDark.ignoresSafeArea()
        HStack {
            Text("Loading")
                .foregroundColor(.white)
            MiniHexLoader()
        }
    }
}

#Preview("Generating Overlay") {
    GeneratingPuzzleOverlay()
}
