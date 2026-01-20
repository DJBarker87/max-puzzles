import SwiftUI

// MARK: - MusicToggleButton

/// A button that toggles background music on/off
/// Shows a musical note icon that changes appearance based on state
struct MusicToggleButton: View {
    @ObservedObject private var storage = StorageService.shared
    @EnvironmentObject var musicService: MusicService

    /// Size variant for the button
    var size: ButtonSize = .regular

    /// Whether to show a background circle
    var showBackground: Bool = true

    enum ButtonSize {
        case small
        case regular
        case large

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .regular: return 20
            case .large: return 24
            }
        }

        var buttonSize: CGFloat {
            switch self {
            case .small: return 32
            case .regular: return 40
            case .large: return 48
            }
        }
    }

    var body: some View {
        Button(action: toggleMusic) {
            ZStack {
                if showBackground {
                    Circle()
                        .fill(AppTheme.backgroundMid.opacity(0.8))
                        .frame(width: size.buttonSize, height: size.buttonSize)
                }

                Image(systemName: storage.isMusicEnabled ? "music.note" : "speaker.slash.fill")
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundColor(storage.isMusicEnabled ? AppTheme.accentPrimary : AppTheme.textSecondary)
            }
        }
        .accessibilityLabel(storage.isMusicEnabled ? "Turn music off" : "Turn music on")
        .accessibilityHint("Double tap to toggle background music")
    }

    private func toggleMusic() {
        let newState = !storage.isMusicEnabled
        storage.setMusicEnabled(newState)
        musicService.onMusicSettingChanged(enabled: newState)
    }
}

// MARK: - Preview

#Preview("Music Toggle - On") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        MusicToggleButton()
            .environmentObject(MusicService.shared)
    }
}

#Preview("Music Toggle - Small") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        MusicToggleButton(size: .small)
            .environmentObject(MusicService.shared)
    }
}
