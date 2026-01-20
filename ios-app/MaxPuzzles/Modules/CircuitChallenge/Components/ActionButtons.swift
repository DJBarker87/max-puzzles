import SwiftUI
import UIKit

// MARK: - ActionButtons

/// Game action buttons (Reset, New Puzzle, View Solution, Continue)
/// Supports horizontal and vertical layouts for different orientations
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

// MARK: - ActionButton

/// Individual action button with icon and optional label
/// Supports highlighted state for primary actions
struct ActionButton: View {
    let icon: String
    let label: String?
    let action: () -> Void
    let highlighted: Bool

    @State private var isPressed = false

    init(
        icon: String,
        label: String? = nil,
        action: @escaping () -> Void,
        highlighted: Bool = false
    ) {
        self.icon = icon
        self.label = label
        self.action = action
        self.highlighted = highlighted
    }

    private var accentPrimary: Color { Color(hex: "22c55e") }
    private var textPrimary: Color { .white }
    private var textSecondary: Color { Color(hex: "a1a1aa") }
    private var backgroundMid: Color { Color(hex: "1a1a3e") }

    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))

                if let label = label {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(highlighted ? accentPrimary : textPrimary)
            .padding(.horizontal, label != nil ? 16 : 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(highlighted ? accentPrimary.opacity(0.2) : backgroundMid)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        highlighted ? accentPrimary.opacity(0.5) : textSecondary.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

#Preview("Action Buttons") {
    VStack(spacing: 40) {
        VStack {
            Text("Horizontal - Default").foregroundColor(.white)
            ActionButtons(
                onReset: { print("Reset") },
                onNewPuzzle: { print("New Puzzle") }
            )
        }

        VStack {
            Text("With View Solution").foregroundColor(.white)
            ActionButtons(
                onReset: { print("Reset") },
                onNewPuzzle: { print("New Puzzle") },
                onViewSolution: { print("View Solution") },
                showViewSolution: true
            )
        }

        VStack {
            Text("With Continue").foregroundColor(.white)
            ActionButtons(
                onReset: { print("Reset") },
                onNewPuzzle: { print("New Puzzle") },
                onContinue: { print("Continue") },
                showContinue: true
            )
        }

        VStack {
            Text("Vertical").foregroundColor(.white)
            ActionButtons(
                onReset: { print("Reset") },
                onNewPuzzle: { print("New Puzzle") },
                vertical: true
            )
        }

        VStack {
            Text("Vertical with Solution").foregroundColor(.white)
            ActionButtons(
                onReset: { print("Reset") },
                onNewPuzzle: { print("New Puzzle") },
                onViewSolution: { print("View Solution") },
                showViewSolution: true,
                vertical: true
            )
        }
    }
    .padding()
    .background(Color(hex: "0f0f23"))
}
