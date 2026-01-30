import SwiftUI

/// Displays coin amount with icon
struct CoinDisplay: View {
    let amount: Int
    let showPlus: Bool
    let size: CoinDisplaySize

    enum CoinDisplaySize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            case .large: return 28
            }
        }

        var font: Font {
            switch self {
            case .small: return AppTypography.bodySmall
            case .medium: return AppTypography.bodyMedium
            case .large: return AppTypography.titleSmall
            }
        }
    }

    init(_ amount: Int, showPlus: Bool = false, size: CoinDisplaySize = .medium) {
        self.amount = amount
        self.showPlus = showPlus
        self.size = size
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: size.iconSize))
                .foregroundColor(AppTheme.accentTertiary)

            Text(formattedAmount)
                .font(size.font)
                .fontWeight(.bold)
                .foregroundColor(textColor)
        }
    }

    private var formattedAmount: String {
        if showPlus && amount > 0 {
            return "+\(amount)"
        } else if showPlus && amount < 0 {
            return "\(amount)"
        } else {
            return "\(amount)"
        }
    }

    private var textColor: Color {
        if showPlus && amount > 0 {
            return AppTheme.accentPrimary
        } else if showPlus && amount < 0 {
            return AppTheme.error
        } else {
            return AppTheme.textPrimary
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CoinDisplay(1234, size: .small)
        CoinDisplay(1234, size: .medium)
        CoinDisplay(1234, size: .large)
        CoinDisplay(80, showPlus: true, size: .medium)
        CoinDisplay(-30, showPlus: true, size: .medium)
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
