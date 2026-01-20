import SwiftUI

// MARK: - TimerDisplay

/// Premium timer display with glass effect and running animation
struct TimerDisplay: View {
    let elapsedSeconds: Int
    let isRunning: Bool
    let compact: Bool

    @State private var iconRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3

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

    private var iconSize: CGFloat { compact ? 16 : 20 }
    private var fontSize: CGFloat { compact ? 16 : 20 }

    var body: some View {
        HStack(spacing: compact ? 4 : 8) {
            // Animated stopwatch icon
            ZStack {
                // Glow when running
                if isRunning {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: iconSize * 1.3))
                        .foregroundColor(AppTheme.accentPrimary)
                        .blur(radius: 6)
                        .opacity(glowOpacity)
                }

                Image(systemName: "stopwatch.fill")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(isRunning ? AppTheme.accentPrimary : AppTheme.textSecondary)
                    .rotationEffect(.degrees(isRunning ? iconRotation : 0))
            }
            .scaleEffect(pulseScale)

            // Time display with monospace font
            Text(formattedTime)
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: elapsedSeconds)
        }
        .padding(.horizontal, compact ? 10 : 14)
        .padding(.vertical, compact ? 6 : 10)
        // Glass effect background
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 10 : 12)
                    .fill(.ultraThinMaterial.opacity(0.6))

                RoundedRectangle(cornerRadius: compact ? 10 : 12)
                    .fill(AppTheme.backgroundMid.opacity(0.4))

                // Subtle gradient shine
                RoundedRectangle(cornerRadius: compact ? 10 : 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.02),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        // Border
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 10 : 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            isRunning ? AppTheme.accentPrimary.opacity(0.4) : Color.white.opacity(0.2),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        // Subtle shadow
        .shadow(color: isRunning ? AppTheme.accentPrimary.opacity(0.2) : Color.black.opacity(0.2), radius: 6, y: 2)
        .onAppear {
            if isRunning {
                startAnimations()
            }
        }
        .onChange(of: isRunning) { running in
            if running {
                startAnimations()
            } else {
                stopAnimations()
            }
        }
    }

    private func startAnimations() {
        // Subtle icon movement
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            iconRotation = 5
        }

        // Pulse effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
            glowOpacity = 0.5
        }
    }

    private func stopAnimations() {
        withAnimation(.easeOut(duration: 0.3)) {
            iconRotation = 0
            pulseScale = 1.0
            glowOpacity = 0.3
        }
    }
}

// MARK: - GameTimer

/// Observable timer for game timing
/// Starts on first move, can be paused and reset
@MainActor
class GameTimer: ObservableObject {
    @Published var elapsedSeconds: Int = 0
    @Published var isRunning: Bool = false

    private var timer: Timer?

    /// Start the timer (call on first move)
    func start() {
        guard !isRunning else { return }
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedSeconds += 1
            }
        }
    }

    /// Pause the timer
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    /// Reset the timer to zero
    func reset() {
        pause()
        elapsedSeconds = 0
    }

    /// Stop timer and return final time
    func stop() -> Int {
        pause()
        return elapsedSeconds
    }

    deinit {
        timer?.invalidate()
    }
}

// MARK: - Preview

#Preview("Timer Display") {
    VStack(spacing: 20) {
        VStack {
            Text("Running").foregroundColor(.white)
            TimerDisplay(elapsedSeconds: 45, isRunning: true)
        }

        VStack {
            Text("Paused").foregroundColor(.white)
            TimerDisplay(elapsedSeconds: 125, isRunning: false)
        }

        VStack {
            Text("Long Time").foregroundColor(.white)
            TimerDisplay(elapsedSeconds: 3661)
        }

        Divider()

        VStack {
            Text("Compact Running").foregroundColor(.white)
            TimerDisplay(elapsedSeconds: 45, isRunning: true, compact: true)
        }

        VStack {
            Text("Compact Paused").foregroundColor(.white)
            TimerDisplay(elapsedSeconds: 125, isRunning: false, compact: true)
        }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
