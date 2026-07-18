import SwiftUI

/// Premium card displaying a puzzle module with glass effect and micro-interactions
struct ModuleCardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let description: String
    let iconName: String
    var imageName: String? = nil  // Optional custom image instead of SF Symbol
    var iconGlowColor: Color = AppTheme.accentPrimary
    let isLocked: Bool
    let action: () -> Void

    @State private var isHovered = false
    @State private var iconBounce = false
    @State private var bounceTask: Task<Void, Never>?

    private var isCompactHeight: Bool { verticalSizeClass == .compact }
    private var isCompactWidth: Bool { horizontalSizeClass == .compact }
    private var iconFrameSize: CGFloat {
        if isCompactWidth { return isCompactHeight ? 52 : 72 }
        return isCompactHeight ? 88 : 120
    }
    private var symbolGlowSize: CGFloat {
        if isCompactWidth { return isCompactHeight ? 48 : 68 }
        return isCompactHeight ? 80 : 104
    }
    private var symbolCircleSize: CGFloat {
        if isCompactWidth { return isCompactHeight ? 44 : 62 }
        return isCompactHeight ? 72 : 96
    }

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: isCompactWidth || isCompactHeight ? 8 : AppSpacing.md) {
                // Icon with glow
                ZStack {
                    // Custom image or SF Symbol icon
                    if let imageName = imageName {
                        // Custom image (like the electric hexagon)
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: iconFrameSize,
                                height: iconFrameSize
                            )
                            .shadow(color: iconGlowColor.opacity(0.62), radius: 15)
                            .scaleEffect(iconBounce ? 1.08 : 1.0)
                    } else {
                        // Outer glow
                        Circle()
                            .fill(AppTheme.accentPrimary.opacity(0.28))
                            .frame(width: symbolGlowSize, height: symbolGlowSize)
                            .blur(radius: 12)

                        // Glass circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppTheme.accentPrimary.opacity(0.35),
                                        AppTheme.accentPrimary.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: symbolCircleSize, height: symbolCircleSize)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )

                        // Icon
                        Image(systemName: iconName)
                            .font(
                                .system(
                                    size: isCompactWidth ? 26 : (isCompactHeight ? 32 : 42),
                                    weight: .semibold
                                )
                            )
                            .foregroundColor(AppTheme.accentPrimary)
                            .shadow(color: AppTheme.accentPrimary.opacity(0.5), radius: 6)
                            .scaleEffect(iconBounce ? 1.1 : 1.0)
                    }
                }
                .frame(width: iconFrameSize, height: iconFrameSize)

                // Title with electric typography - bold with glow effect
                Text(title)
                    .font(isCompactWidth ? AppTypography.buttonLarge : AppTypography.titleSmall)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.82)
                    .shadow(color: AppTheme.connectorGlow.opacity(0.8), radius: 8)
                    .shadow(color: AppTheme.accentPrimary.opacity(0.5), radius: 4)

                // The compact hub relies on a recognisable icon and short game name. Keeping the
                // longer description in the accessibility hint avoids four reading-heavy cards
                // and leaves all games visible for younger children.
                if !isCompactWidth {
                    Text(description)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(isCompactHeight ? 1 : 2, reservesSpace: true)
                }

                // Lock indicator or play button
                if isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                } else {
                    Text("Play")
                        .font(AppTypography.buttonMedium)
                        .foregroundColor(AppTheme.accentPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentPrimary.opacity(isHovered ? 0.2 : 0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.accentPrimary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.vertical, isCompactWidth || isCompactHeight ? 12 : AppSpacing.lg)
            .padding(.horizontal, isCompactWidth ? 8 : AppSpacing.md)
            .frame(maxWidth: .infinity)
            // Glass effect background
            .background(
                ZStack {
                    // Base material
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial.opacity(0.7))

                    // Gradient overlay for glass shine
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Dark tint
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppTheme.backgroundMid.opacity(0.5))
                }
            )
            // Glass border
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                isHovered && !isLocked ? AppTheme.accentPrimary.opacity(0.6) : Color.white.opacity(0.3),
                                isHovered && !isLocked ? AppTheme.accentPrimary.opacity(0.2) : Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered && !isLocked ? 2 : 1
                    )
            )
            // Shadows
            .shadow(
                color: isHovered && !isLocked ? AppTheme.accentPrimary.opacity(0.3) : .black.opacity(0.3),
                radius: isHovered ? 20 : 12,
                y: 6
            )
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 4,
                y: 2
            )
            // Micro-interactions
            .scaleEffect(isHovered && !isLocked && !reduceMotion ? 1.03 : 1.0)
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .buttonStyle(ScrollFriendlyPressStyle(scale: 0.97, yOffset: 2))
        .disabled(isLocked)
        .accessibilityLabel(title)
        .accessibilityHint(isLocked ? "This module is locked" : "\(description). Double tap to play")
        .accessibilityAddTraits(.isButton)
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                isHovered = hovering
            }
            bounceTask?.cancel()
            if hovering && !isLocked && !reduceMotion {
                // Bounce icon on hover
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    iconBounce = true
                }
                bounceTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        iconBounce = false
                    }
                }
            } else {
                iconBounce = false
            }
        }
        .onDisappear {
            bounceTask?.cancel()
            bounceTask = nil
        }
    }

    private func handleTap() {
        guard !isLocked else { return }

        SoundEffectsService.shared.play(.cardTap)
        FeedbackManager.shared.haptic(.medium)
        action()
    }
}

// MARK: - Menu Option Card

/// Smaller card for menu options (Quick Play, Story Mode, etc.)
struct MenuOptionCard: View {
    let title: String
    let subtitle: String?
    let iconName: String
    let color: Color
    let action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        iconName: String,
        color: Color = AppTheme.accentPrimary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.buttonLarge)
                        .foregroundColor(.white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.5))
            )
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.backgroundMid.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(ScrollFriendlyPressStyle(scale: 0.98, yOffset: 1))
        .accessibilityLabel(subtitle != nil ? "\(title). \(subtitle!)" : title)
        .accessibilityAddTraits(.isButton)
    }

    private func handleTap() {
        SoundEffectsService.shared.play(.buttonTap)
        action()
    }
}

/// Uses `ButtonStyle.Configuration.isPressed` instead of a zero-distance drag gesture. The old
/// gesture looked good but intercepted the parent carousel's pan recognizer on iPhone.
private struct ScrollFriendlyPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let scale: CGFloat
    let yOffset: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .offset(y: configuration.isPressed && !reduceMotion ? yOffset : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
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

        VStack(spacing: 12) {
            MenuOptionCard(
                title: "Quick Play",
                subtitle: "Jump right in",
                iconName: "play.fill"
            ) { }

            MenuOptionCard(
                title: "Story Mode",
                subtitle: "10 chapters to complete",
                iconName: "book.fill",
                color: AppTheme.accentTertiary
            ) { }
        }
        .padding(.horizontal)
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
