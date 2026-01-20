import SwiftUI

/// Premium card displaying a puzzle module with glass effect and micro-interactions
struct ModuleCardView: View {
    let title: String
    let description: String
    let iconName: String
    var imageName: String? = nil  // Optional custom image instead of SF Symbol
    let isLocked: Bool
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var iconBounce = false
    @State private var glowPulse: CGFloat = 0

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: AppSpacing.md) {
                // Icon with glow
                ZStack {
                    // Custom image or SF Symbol icon
                    if let imageName = imageName {
                        // Custom image (like the electric hexagon)
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .shadow(color: AppTheme.accentPrimary.opacity(0.6), radius: 15)
                            .scaleEffect(iconBounce ? 1.08 : 1.0)
                    } else {
                        // Outer glow
                        Circle()
                            .fill(AppTheme.accentPrimary.opacity(0.2 + glowPulse * 0.15))
                            .frame(width: 90, height: 90)
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
                            .frame(width: 80, height: 80)
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
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(AppTheme.accentPrimary)
                            .shadow(color: AppTheme.accentPrimary.opacity(0.5), radius: 6)
                            .scaleEffect(iconBounce ? 1.1 : 1.0)
                    }
                }

                // Title with electric typography - bold with glow effect
                Text(title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: AppTheme.connectorGlow.opacity(0.8), radius: 8)
                    .shadow(color: AppTheme.accentPrimary.opacity(0.5), radius: 4)

                // Description
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Lock indicator or play button
                if isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                        Text("Coming Soon")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                } else {
                    Text("Play")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
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
            .padding(AppSpacing.lg)
            .frame(width: 200)
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
                y: isPressed ? 2 : 6
            )
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 4,
                y: 2
            )
            // Micro-interactions
            .scaleEffect(isPressed ? 0.97 : (isHovered && !isLocked ? 1.03 : 1.0))
            .offset(y: isPressed ? 2 : 0)
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
            if hovering && !isLocked {
                // Bounce icon on hover
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    iconBounce = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        iconBounce = false
                    }
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && !isLocked {
                        withAnimation(.easeOut(duration: 0.1)) {
                            isPressed = true
                        }
                        FeedbackManager.shared.haptic(.light)
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            // Subtle continuous glow pulse
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPulse = 1
            }
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

    @State private var isPressed = false

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
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
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
                radius: isPressed ? 4 : 8,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .offset(y: isPressed ? 1 : 0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeOut(duration: 0.1)) {
                            isPressed = true
                        }
                        FeedbackManager.shared.haptic(.light)
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }

    private func handleTap() {
        SoundEffectsService.shared.play(.buttonTap)
        action()
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
