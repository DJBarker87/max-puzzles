import SwiftUI

/// Card displaying a puzzle module with hover effects
struct ModuleCardView: View {
    let title: String
    let description: String
    let iconName: String
    let isLocked: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: {
            if !isLocked { action() }
        }) {
            VStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.accentPrimary.opacity(0.3),
                                    AppTheme.accentPrimary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: iconName)
                        .font(.system(size: 36))
                        .foregroundColor(AppTheme.accentPrimary)
                }

                // Title
                Text(title)
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)

                // Description
                Text(description)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Lock indicator or play button
                if isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                        Text("Coming Soon")
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                } else {
                    Text("Play")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentPrimary)
                }
            }
            .padding(AppSpacing.lg)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.backgroundMid)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isHovered && !isLocked ? AppTheme.accentPrimary.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: isHovered && !isLocked ? 2 : 1
                    )
            )
            .shadow(
                color: isHovered && !isLocked ? AppTheme.accentPrimary.opacity(0.2) : .black.opacity(0.2),
                radius: isHovered ? 15 : 10
            )
            .scaleEffect(isHovered && !isLocked ? 1.02 : 1.0)
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: AppAnimation.fast), value: isHovered)
    }
}

#Preview {
    HStack(spacing: 20) {
        ModuleCardView(
            title: "Circuit Challenge",
            description: "Path-finding puzzle with arithmetic",
            iconName: "bolt.fill",
            isLocked: false
        ) { }

        ModuleCardView(
            title: "Number Maze",
            description: "Coming in V2",
            iconName: "square.grid.3x3",
            isLocked: true
        ) { }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
