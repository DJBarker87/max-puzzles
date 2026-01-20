import SwiftUI

/// Preview view to verify all theme colors render correctly
struct ThemePreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hub Colors
                colorSection("Hub Colors", colors: [
                    ("backgroundDark", AppTheme.backgroundDark),
                    ("backgroundMid", AppTheme.backgroundMid),
                    ("accentPrimary", AppTheme.accentPrimary),
                    ("accentSecondary", AppTheme.accentSecondary),
                    ("accentTertiary", AppTheme.accentTertiary),
                    ("textPrimary", AppTheme.textPrimary),
                    ("textSecondary", AppTheme.textSecondary),
                    ("error", AppTheme.error),
                ])

                // Cell States
                colorSection("Cell States", colors: [
                    ("Normal", AppTheme.cellNormalTop1),
                    ("Start", AppTheme.cellStartTop1),
                    ("Finish", AppTheme.cellFinishTop1),
                    ("Current", AppTheme.cellCurrentTop1),
                    ("Visited", AppTheme.cellVisitedTop1),
                    ("Wrong", AppTheme.cellWrongTop),
                ])

                // Connectors
                colorSection("Connectors", colors: [
                    ("Default", AppTheme.connectorDefault),
                    ("Active", AppTheme.connectorActive),
                    ("Glow", AppTheme.connectorGlow),
                ])

                // Borders
                colorSection("Borders", colors: [
                    ("Normal", AppTheme.cellNormalBorder),
                    ("Start", AppTheme.cellStartBorder),
                    ("Finish", AppTheme.cellFinishBorder),
                    ("Current", AppTheme.cellCurrentBorder),
                    ("Visited", AppTheme.cellVisitedBorder),
                    ("Wrong", AppTheme.cellWrongBorder),
                ])

                // Hearts
                colorSection("Hearts", colors: [
                    ("Active", AppTheme.heartsActive),
                    ("Inactive", AppTheme.heartsInactive),
                ])

                // Gradients
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gradients")
                        .font(AppTypography.titleSmall)
                        .foregroundColor(AppTheme.textPrimary)

                    HStack(spacing: 16) {
                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.gridBackground)
                                .frame(width: 80, height: 60)
                            Text("Grid BG")
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.splashBackground)
                                .frame(width: 80, height: 60)
                            Text("Splash BG")
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.backgroundDark)
    }

    func colorSection(_ title: String, colors: [(String, Color)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(colors, id: \.0) { name, color in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        Text(name)
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    ThemePreview()
}
