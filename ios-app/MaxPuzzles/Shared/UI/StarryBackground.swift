import SwiftUI

/// Animated starry background matching web app exactly
struct StarryBackground: View {
    let starCount: Int

    init(starCount: Int = 80) {
        self.starCount = starCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                AppTheme.gridBackground

                // Stars
                ForEach(0..<starCount, id: \.self) { index in
                    StarView(
                        seed: index,
                        bounds: geometry.size
                    )
                }

                // Ambient green glow
                AppTheme.connectorGlow.opacity(0.03)
            }
        }
        .ignoresSafeArea()
    }
}

/// Individual twinkling star
struct StarView: View {
    let seed: Int
    let bounds: CGSize

    @State private var opacity: Double = 0.3

    private var position: CGPoint {
        // Use seed for deterministic random position
        let x = CGFloat((seed * 7919) % 1000) / 1000.0 * bounds.width
        let y = CGFloat((seed * 6271) % 1000) / 1000.0 * bounds.height
        return CGPoint(x: x, y: y)
    }

    private var size: CGFloat {
        CGFloat((seed * 3571) % 3 + 1)
    }

    private var animationDuration: Double {
        Double((seed * 2311) % 20 + 30) / 10.0  // 3-5 seconds
    }

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .position(position)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
                    .delay(Double(seed % 50) * 0.1)
                ) {
                    opacity = 0.8
                }
            }
    }
}

#Preview {
    StarryBackground()
}
