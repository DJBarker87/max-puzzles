import SwiftUI

/// Primary action button with green gradient styling
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool

    @State private var isHovered = false
    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .frame(minWidth: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.accentPrimary,
                                AppTheme.accentPrimary.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.accentPrimary.opacity(0.5), lineWidth: 1)
            )
            .shadow(
                color: AppTheme.accentPrimary.opacity(isHovered ? 0.4 : 0.2),
                radius: isHovered ? 12 : 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: AppAnimation.fast)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton("Play Now", icon: "play.fill") { }
        PrimaryButton("Loading...", isLoading: true) { }
        PrimaryButton("Disabled", isDisabled: true) { }
        PrimaryButton("No Icon") { }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
