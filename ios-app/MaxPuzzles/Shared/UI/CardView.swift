import SwiftUI

/// Reusable card container with consistent styling
struct CardView<Content: View>: View {
    let content: Content
    let padding: CGFloat

    init(
        padding: CGFloat = AppSpacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.backgroundMid)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    VStack(spacing: 20) {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Circuit Challenge")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Path-finding puzzle with arithmetic")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        CardView(padding: AppSpacing.lg) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(AppTheme.accentTertiary)
                Text("Achievement Unlocked!")
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
