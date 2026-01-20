import SwiftUI

// MARK: - TimerDisplay

/// Timer display showing elapsed time in M:SS format
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
                .foregroundColor(Color(hex: "a1a1aa"))

            Text(formattedTime)
                .font(.system(size: compact ? 16 : 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "1a1a3e").opacity(0.8))
        )
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
        TimerDisplay(elapsedSeconds: 0)
        TimerDisplay(elapsedSeconds: 45)
        TimerDisplay(elapsedSeconds: 125)
        TimerDisplay(elapsedSeconds: 3661)

        Divider()

        TimerDisplay(elapsedSeconds: 45, compact: true)
        TimerDisplay(elapsedSeconds: 125, compact: true)
    }
    .padding()
    .background(Color(hex: "0f0f23"))
}
