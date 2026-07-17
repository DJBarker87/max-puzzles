import SwiftUI

// MARK: - SettingsView

/// Settings screen for app preferences
/// Includes sound toggle (architecture only in V1), about section, and logout
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @ObservedObject var storage = StorageService.shared
    @ObservedObject private var profileStore = CometLearningStore.shared
    @ObservedObject private var cloudSync = ICloudProgressSyncService.shared

    @State private var showLogoutConfirmation = false
    @State private var showParentGate = false
    @State private var showAbout = false
    @State private var editingName = false
    @State private var nameInput = ""
    @State private var parentChallengeLeft = 18
    @State private var parentChallengeRight = 27
    @State private var parentChallengeAnswer = ""
    @State private var parentGateError: String?
    @State private var pendingClearConfirmation = false

    var body: some View {
        ZStack {
            SplashBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Profile Section (guest mode)
                    if appState.isGuest {
                        profileSection
                    }

                    // Sound Settings Section
                    soundSection

                    cloudSyncSection

                    // About Section
                    aboutSection

                    // Data Management Section
                    dataSection
                }
                .frame(maxWidth: 400)
                .padding()
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")
            }
        }
        .alert("Clear All Data?", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear Data", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will remove every profile and all progress from this device and synced iCloud devices. This cannot be undone.")
        }
        .sheet(isPresented: $showAbout) {
            AboutSheetView()
        }
        .sheet(isPresented: $showParentGate) {
            ParentGateView(
                left: parentChallengeLeft,
                right: parentChallengeRight,
                answer: $parentChallengeAnswer,
                errorMessage: parentGateError,
                onCancel: {
                    pendingClearConfirmation = false
                    showParentGate = false
                },
                onContinue: validateParentGate
            )
            .presentationDetents([.large])
        }
        .onChange(of: showParentGate) { isPresented in
            guard !isPresented, pendingClearConfirmation else { return }
            pendingClearConfirmation = false
            showLogoutConfirmation = true
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        SettingsCard(title: "Profile", icon: "person.circle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Name")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    if editingName {
                        TextField("Enter name", text: $nameInput)
                            .font(AppTypography.bodyMedium.weight(.medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                            .frame(maxWidth: 150)
                            .onSubmit {
                                saveName()
                            }

                        Button(action: saveName) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppTheme.accentPrimary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Save profile name")
                    } else {
                        Text(profileStore.activeProfile.name)
                            .font(AppTypography.bodyMedium.weight(.medium))
                            .foregroundColor(.white)

                        Button(action: {
                            nameInput = profileStore.activeProfile.name
                            editingName = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppTheme.accentPrimary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Edit profile name")
                    }
                }

                Text("Each profile keeps separate progress and syncs through your private iCloud account.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)

                Divider()
                    .background(Color.white.opacity(0.1))

                Button {
                    appState.requestProfileSelection()
                } label: {
                    SettingsRow(
                        icon: "person.2.fill",
                        title: "Switch player"
                    )
                }
                .accessibilityIdentifier("settings-switch-player")
            }
        }
    }

    private var cloudSyncSection: some View {
        SettingsCard(title: "iCloud Progress", icon: "icloud.fill") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: cloudSyncIcon)
                        .foregroundColor(cloudSyncColor)
                    Text(cloudSync.state.title)
                        .font(AppTypography.bodyMedium.weight(.semibold))
                        .foregroundColor(.white)
                    Spacer(minLength: 0)
                }

                Text("Profiles and a compact progress summary are queued privately for devices using the same Apple Account. Handwriting traces, detailed attempts and voice recordings stay only on this device.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    cloudSync.refresh()
                } label: {
                    Label("Check for updates", systemImage: "arrow.triangle.2.circlepath")
                        .font(AppTypography.buttonSmall)
                        .foregroundColor(AppTheme.accentPrimary)
                        .frame(minHeight: 44)
                }
                .accessibilityIdentifier("icloud-check-for-updates")
            }
        }
    }

    private var cloudSyncIcon: String {
        switch cloudSync.state {
        case .ready: return "checkmark.icloud.fill"
        case .checking: return "arrow.triangle.2.circlepath.icloud.fill"
        case .waitingForICloud: return "icloud.slash.fill"
        case .failed: return "exclamationmark.icloud.fill"
        }
    }

    private var cloudSyncColor: Color {
        switch cloudSync.state {
        case .ready: return Color(hex: "5eead4")
        case .checking: return AppTheme.cometCyan
        case .waitingForICloud, .failed: return AppTheme.cometGold
        }
    }

    private func saveName() {
        profileStore.renameActiveProfile(nameInput)
        editingName = false
    }

    // MARK: - Sound Section

    private var soundSection: some View {
        SettingsCard(title: "Audio", icon: "speaker.wave.2.fill") {
            VStack(spacing: 16) {
                Toggle(isOn: Binding(
                    get: { storage.isSoundEnabled },
                    set: { SoundEffectsService.shared.isEnabled = $0 }
                )) {
                    audioLabel(title: "Sound effects", detail: "Taps, rewards and gentle corrections")
                }
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))

                if storage.isSoundEnabled {
                    audioSlider(
                        title: "Effects volume",
                        value: Binding(
                            get: { Double(storage.soundEffectsVolume) },
                            set: { SoundEffectsService.shared.volume = Float($0) }
                        )
                    )
                }

                Divider().background(Color.white.opacity(0.1))

                Toggle(isOn: Binding(
                    get: { storage.isVoiceEnabled },
                    set: { enabled in
                        storage.setVoiceEnabled(enabled)
                        if !enabled { LetterSpeechService.shared.stop() }
                    }
                )) {
                    audioLabel(title: "Spoken instructions", detail: "Letters, words and formation prompts")
                }
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))

                if storage.isVoiceEnabled {
                    audioSlider(
                        title: "Voice volume",
                        value: Binding(
                            get: { Double(storage.voiceVolume) },
                            set: { storage.setVoiceVolume(Float($0)) }
                        )
                    )
                }

                Divider().background(Color.white.opacity(0.1))

                Toggle(isOn: Binding(
                    get: { storage.isMusicEnabled },
                    set: { enabled in
                        storage.setMusicEnabled(enabled)
                        MusicService.shared.onMusicSettingChanged(enabled: enabled)
                    }
                )) {
                    audioLabel(title: "Music", detail: "Background music")
                }
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))

                // Music Volume Slider
                if storage.isMusicEnabled {
                    audioSlider(
                        title: "Music volume",
                        value: Binding(
                            get: { Double(storage.musicVolume) },
                            set: { MusicService.shared.volume = Float($0) }
                        )
                    )
                }
            }
        }
    }

    private func audioLabel(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(detail)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func audioSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                Slider(value: value, in: 0...1)
                    .tint(AppTheme.accentPrimary)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        SettingsCard(title: "About", icon: "info.circle.fill") {
            VStack(spacing: 12) {
                Button(action: { showAbout = true }) {
                    SettingsRow(icon: "star.fill", title: "About Maxi's Mighty Mindgames")
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                HStack {
                    Text("Version")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text(appVersion)
                        .font(AppTypography.bodySmall.weight(.medium))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        SettingsCard(title: "Data", icon: "externaldrive.fill") {
            VStack(spacing: 12) {
                Button(action: beginParentGate) {
                    SettingsRow(
                        icon: "trash.fill",
                        title: "Clear All Data",
                        destructive: true
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func clearAllData() {
        LetterSpeechService.shared.stop()
        CustomPromptAudioService.shared.deleteAllRecordings()
        MusicService.shared.stop()
        storage.clearAllData()
        CometLearningStore.shared.resetAfterDataClear()
        cloudSync.resetCloudProgressAfterLocalClear()
        MusicService.shared.volume = storage.musicVolume
        // Re-create guest session
        _ = storage.ensureGuestSession()
        appState.needsFirstRun = true
        dismiss()
    }

    private func beginParentGate() {
        parentChallengeLeft = Int.random(in: 14...29)
        parentChallengeRight = Int.random(in: 17...38)
        parentChallengeAnswer = ""
        parentGateError = nil
        pendingClearConfirmation = false
        showParentGate = true
    }

    private func validateParentGate() {
        guard Int(parentChallengeAnswer) == parentChallengeLeft + parentChallengeRight else {
            parentGateError = "That answer isn't right. Please try again."
            return
        }

        parentGateError = nil
        pendingClearConfirmation = true
        showParentGate = false
    }
}

// MARK: - Parent Gate

private struct ParentGateView: View {
    let left: Int
    let right: Int
    @Binding var answer: String
    let errorMessage: String?
    var message = "To protect the player's progress, solve this check before continuing."
    let onCancel: () -> Void
    let onContinue: () -> Void

    @FocusState private var answerFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 44))
                        .foregroundColor(AppTheme.accentPrimary)
                        .accessibilityHidden(true)

                    Text("Grown-ups only")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(.white)

                    Text(message)
                        .font(.body)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("What is \(left) + \(right)?")
                        .font(AppTypography.titleSmall)
                        .foregroundColor(.white)

                    TextField("Answer", text: $answer)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(AppTypography.titleSmall)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(AppTheme.backgroundMid)
                        .cornerRadius(12)
                        .focused($answerFocused)
                        .accessibilityLabel("Answer to \(left) plus \(right)")

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(AppTheme.error)
                            .accessibilityLabel("Error: \(errorMessage)")
                    }

                    Button("Continue") {
                        onContinue()
                    }
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(AppTheme.accentPrimary)
                    .cornerRadius(12)
                }
                .padding(24)
                .frame(maxWidth: 420)
            }
            .navigationTitle("Parent check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
            .onAppear { answerFocused = true }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.accentPrimary)

                Text(title)
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(.white)
            }

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(16)
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    var destructive: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(destructive ? AppTheme.error : AppTheme.textSecondary)
                .frame(width: 24)

            Text(title)
                .font(AppTypography.bodyMedium)
                .foregroundColor(destructive ? AppTheme.error : .white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

// MARK: - About Sheet View

struct AboutSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showsExternalLinkGate = false
    @State private var externalLinkLeft = 16
    @State private var externalLinkRight = 23
    @State private var externalLinkAnswer = ""
    @State private var externalLinkError: String?
    @State private var pendingExternalURL: URL?
    @State private var externalLinkApproved = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // App Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.accentPrimary.opacity(0.3), AppTheme.accentPrimary.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "sparkles")
                                .font(.system(size: 44))
                                .foregroundColor(AppTheme.cometCyan)
                        }
                        .padding(.top, 20)

                        // App Name
                        Text("Maxi's Mighty Mindgames")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(.white)

                        // Description
                        VStack(spacing: 16) {
                            Text("Four offline learning games for early-primary children, with optional advanced arithmetic for older learners.")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)

                            Text("Built with love for Maxi")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppTheme.accentPrimary)
                        }
                        .padding(.horizontal, 24)

                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.horizontal)

                        // Features
                        VStack(alignment: .leading, spacing: 16) {
                            FeatureRow(icon: "point.3.connected.trianglepath.dotted", title: "Dot-to-Dot Discovery", description: "Connect, reveal and colour 84 real pictures")
                            FeatureRow(icon: "character.book.closed.fill", title: "Star Speller", description: "Listen, spell and handwrite Year 1 words")
                            FeatureRow(icon: "pencil.and.outline", title: "Comet Writer", description: "Practise UK letter and number formation")
                            FeatureRow(icon: "bolt.fill", title: "Circuit Challenge", description: "Build paths through arithmetic puzzles")
                        }
                        .padding(.horizontal, 24)

                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.horizontal)

                        VStack(spacing: AppSpacing.sm) {
                            Button {
                                requestExternalLink(
                                    URL(string: "https://maxis-mighty-mindgames-support.vercel.app/support")!
                                )
                            } label: {
                                SettingsRow(icon: "questionmark.circle.fill", title: "Support")
                                    .padding(.horizontal, AppSpacing.md)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Requires a grown-up check, then opens the support website")

                            Button {
                                requestExternalLink(
                                    URL(string: "https://maxis-mighty-mindgames-support.vercel.app/privacy")!
                                )
                            } label: {
                                SettingsRow(icon: "hand.raised.fill", title: "Privacy policy")
                                    .padding(.horizontal, AppSpacing.md)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Requires a grown-up check, then opens the privacy policy")
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showsExternalLinkGate) {
            ParentGateView(
                left: externalLinkLeft,
                right: externalLinkRight,
                answer: $externalLinkAnswer,
                errorMessage: externalLinkError,
                message: "To open a website outside the app, ask a grown-up to solve this check.",
                onCancel: {
                    pendingExternalURL = nil
                    externalLinkApproved = false
                    showsExternalLinkGate = false
                },
                onContinue: approveExternalLink
            )
            .presentationDetents([.large])
        }
        .onChange(of: showsExternalLinkGate) { isPresented in
            guard !isPresented, externalLinkApproved, let pendingExternalURL else { return }
            externalLinkApproved = false
            self.pendingExternalURL = nil
            openURL(pendingExternalURL)
        }
    }

    private func requestExternalLink(_ url: URL) {
        externalLinkLeft = Int.random(in: 14...29)
        externalLinkRight = Int.random(in: 17...38)
        externalLinkAnswer = ""
        externalLinkError = nil
        externalLinkApproved = false
        pendingExternalURL = url
        showsExternalLinkGate = true
    }

    private func approveExternalLink() {
        guard Int(externalLinkAnswer) == externalLinkLeft + externalLinkRight else {
            externalLinkError = "That answer isn't right. Please try again."
            return
        }
        externalLinkError = nil
        externalLinkApproved = true
        showsExternalLinkGate = false
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.accentPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.accentPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.bodyMedium.weight(.semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Settings") {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState())
    }
}

#Preview("About Sheet") {
    AboutSheetView()
}
