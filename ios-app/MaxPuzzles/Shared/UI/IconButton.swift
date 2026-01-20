import SwiftUI

/// Circular icon button for toolbar actions
struct IconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    init(
        _ icon: String,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
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
                .scaleEffect(isPressed ? 0.9 : (isHovered ? 1.05 : 1.0))
                .shadow(
                    color: isHovered ? AppTheme.accentPrimary.opacity(0.3) : .clear,
                    radius: 8
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
