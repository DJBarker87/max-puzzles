import SwiftUI

/// Primary action button with premium micro-interactions
/// Features: squish animation, glow intensification, haptics, sound
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    let size: ButtonSize

    enum ButtonSize {
        case small, medium, large

        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            }
        }

        var padding: (h: CGFloat, v: CGFloat) {
            switch self {
            case .small: return (16, 10)
            case .medium: return (24, 14)
            case .large: return (32, 18)
            }
        }

        var minWidth: CGFloat {
            switch self {
            case .small: return 80
            case .medium: return 120
            case .large: return 160
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 16
            }
        }
    }

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var glowIntensity: CGFloat = 0.2
    @State private var innerGlow: CGFloat = 0

    init(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.fontSize, weight: .semibold, design: .rounded))
                }

                Text(title)
                    .font(.system(size: size.fontSize, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, size.padding.h)
            .padding(.vertical, size.padding.v)
            .frame(minWidth: size.minWidth)
            .background(
                ZStack {
                    // Base gradient
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.accentPrimary.opacity(isPressed ? 0.9 : 1.0),
                                    AppTheme.accentPrimary.opacity(isPressed ? 0.7 : 0.85)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Inner highlight (top edge shine)
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isPressed ? 0.1 : 0.25),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )

                    // Press darkening
                    if isPressed {
                        RoundedRectangle(cornerRadius: size.cornerRadius)
                            .fill(Color.black.opacity(0.1))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                AppTheme.accentPrimary.opacity(0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            // Outer glow
            .shadow(
                color: AppTheme.accentPrimary.opacity(glowIntensity),
                radius: isPressed ? 6 : (isHovered ? 16 : 10),
                x: 0,
                y: isPressed ? 2 : 4
            )
            // Bottom shadow for depth
            .shadow(
                color: Color.black.opacity(0.3),
                radius: isPressed ? 2 : 4,
                x: 0,
                y: isPressed ? 1 : 3
            )
            // Squish effect: scale + slight Y offset
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .offset(y: isPressed ? 2 : 0)
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading" : (isDisabled ? "Disabled" : "Double tap to activate"))
        .accessibilityAddTraits(.isButton)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: AppAnimation.fast)) {
                isHovered = hovering
                glowIntensity = hovering ? 0.4 : 0.2
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeOut(duration: AppAnimation.buttonPress)) {
                            isPressed = true
                            glowIntensity = 0.5
                        }
                        // Haptic on press
                        FeedbackManager.shared.haptic(.buttonPress)
                    }
                }
                .onEnded { _ in
                    withAnimation(AppAnimation.buttonSpring) {
                        isPressed = false
                        glowIntensity = isHovered ? 0.4 : 0.2
                    }
                    // Haptic on release
                    FeedbackManager.shared.haptic(.buttonRelease)
                }
        )
        .disabled(isDisabled || isLoading)
    }

    private func handleTap() {
        guard !isLoading && !isDisabled else { return }

        // Sound effect
        SoundEffectsService.shared.play(.buttonTap)

        action()
    }
}

// MARK: - Icon Button with Premium Feel

struct PremiumIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44
    var backgroundColor: Color = AppTheme.backgroundMid
    var iconColor: Color = .white
    var accessibilityLabelText: String = ""

    @State private var isPressed = false

    var body: some View {
        Button(action: handleTap) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor.opacity(isPressed ? 0.9 : 0.7))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: isPressed ? 2 : 4,
                    y: isPressed ? 1 : 2
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabelText.isEmpty ? icon : accessibilityLabelText)
        .accessibilityAddTraits(.isButton)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeOut(duration: AppAnimation.buttonPress)) {
                            isPressed = true
                        }
                        FeedbackManager.shared.haptic(.light)
                    }
                }
                .onEnded { _ in
                    withAnimation(AppAnimation.buttonSpring) {
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
        PrimaryButton("Play Now", icon: "play.fill", size: .large) { }
        PrimaryButton("Continue", icon: "arrow.right") { }
        PrimaryButton("Small", size: .small) { }
        PrimaryButton("Loading...", isLoading: true) { }
        PrimaryButton("Disabled", isDisabled: true) { }

        HStack(spacing: 16) {
            PremiumIconButton(icon: "gear") { }
            PremiumIconButton(icon: "speaker.wave.2.fill") { }
            PremiumIconButton(icon: "arrow.left") { }
        }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
