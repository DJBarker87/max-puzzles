import SwiftUI

/// Circular icon button for toolbar actions
struct IconButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let icon: String
    let size: CGFloat
    let accessibilityLabelText: String?
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    init(
        _ icon: String,
        size: CGFloat = 44,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.accessibilityLabelText = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(AppTheme.backgroundMid)
                )
                .overlay(
                    Circle()
                        .stroke(AppTheme.textSecondary.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(reduceMotion ? 1 : (isPressed ? 0.9 : (isHovered ? 1.05 : 1.0)))
                .shadow(
                    color: isHovered ? AppTheme.accentPrimary.opacity(0.3) : .clear,
                    radius: 8
                )
        }
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabelText ?? defaultAccessibilityLabel)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var defaultAccessibilityLabel: String {
        switch icon {
        case "arrow.left", "chevron.left": return "Back"
        case "gear", "gearshape": return "Settings"
        case "arrow.clockwise": return "Try again"
        case "printer": return "Print"
        case "xmark": return "Close"
        default: return icon.replacingOccurrences(of: ".", with: " ")
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        IconButton("arrow.left") { }
        IconButton("gear") { }
        IconButton("arrow.clockwise") { }
        IconButton("printer") { }
        IconButton("xmark", size: 36) { }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
