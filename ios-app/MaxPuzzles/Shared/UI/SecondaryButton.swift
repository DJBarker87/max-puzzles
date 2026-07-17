import SwiftUI

/// Secondary action button with outline styling
struct SecondaryButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let icon: String?
    let action: () -> Void
    let isDisabled: Bool

    @State private var isHovered = false
    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }

                Text(title)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)
            }
            .foregroundColor(AppTheme.textPrimary)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .frame(minWidth: 120, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.backgroundMid)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed && !reduceMotion ? 0.97 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .brightness(isHovered ? 0.1 : 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(isDisabled ? "Disabled" : "Double tap to activate")
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeInOut(duration: AppAnimation.fast)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        SecondaryButton("Settings", icon: "gear") { }
        SecondaryButton("Cancel") { }
        SecondaryButton("Disabled", isDisabled: true) { }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
