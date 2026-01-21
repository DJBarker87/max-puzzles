import SwiftUI

// MARK: - SettingsView

/// Settings screen for app preferences
/// Includes sound toggle (architecture only in V1), about section, and logout
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @ObservedObject var storage = StorageService.shared

    @State private var showLogoutConfirmation = false
    @State private var showAbout = false
    @State private var editingName = false
    @State private var nameInput = ""

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

                    // Guest Mode Info Section (only shown in guest mode)
                    if appState.isGuest {
                        guestInfoSection
                    }

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
                }
            }
        }
        .alert("Clear All Data?", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear Data", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will remove all your progress and reset the app. This cannot be undone.")
        }
        .sheet(isPresented: $showAbout) {
            AboutSheetView()
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        SettingsCard(title: "Profile", icon: "person.circle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Name")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    if editingName {
                        TextField("Enter name", text: $nameInput)
                            .font(.system(size: 16, weight: .medium))
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
                        }
                    } else {
                        Text(storage.guestDisplayName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        Button(action: {
                            nameInput = storage.guestDisplayName == "Guest" ? "" : storage.guestDisplayName
                            editingName = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppTheme.accentPrimary)
                        }
                    }
                }

                Text("This name is stored locally on your device.")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    private func saveName() {
        storage.setGuestDisplayName(nameInput)
        editingName = false
    }

    // MARK: - Sound Section

    private var soundSection: some View {
        SettingsCard(title: "Audio", icon: "speaker.wave.2.fill") {
            VStack(spacing: 16) {
                // Music Toggle
                Toggle(isOn: Binding(
                    get: { storage.isMusicEnabled },
                    set: { enabled in
                        storage.setMusicEnabled(enabled)
                        MusicService.shared.onMusicSettingChanged(enabled: enabled)
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Music")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        Text("Background music")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))

                // Music Volume Slider
                if storage.isMusicEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Music Volume")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)

                        HStack(spacing: 12) {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)

                            Slider(
                                value: Binding(
                                    get: { Double(storage.musicVolume) },
                                    set: { MusicService.shared.volume = Float($0) }
                                ),
                                in: 0...1
                            )
                            .tint(AppTheme.accentPrimary)

                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Sound Effects Toggle
                Toggle(isOn: Binding(
                    get: { storage.isSoundEnabled },
                    set: { storage.setSoundEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sound Effects")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        Text("Coming soon!")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))
                .disabled(true)
                .opacity(0.6)
            }
        }
    }

    // MARK: - Guest Info Section

    private var guestInfoSection: some View {
        SettingsCard(title: "Playing as Guest", icon: "person.fill.questionmark") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your progress is saved locally on this device.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 16) {
                    StatBox(label: "Puzzles", value: "\(storage.puzzlesCompletedCount)")
                    StatBox(label: "Games", value: "\(storage.totalGamesPlayed)")
                    StatBox(label: "Coins", value: "\(storage.totalCoinsEarned)")
                }

                Button(action: {
                    // Navigate to create account (Phase 6)
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Create Account to Sync Progress")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.accentPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentPrimary.opacity(0.15))
                    .cornerRadius(10)
                }
                .disabled(true) // Phase 6
                .opacity(0.6)

                Text("Account creation coming in a future update!")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .italic()
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

                Button(action: {
                    // Open privacy policy (would be a web link)
                }) {
                    SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy")
                }
                .disabled(true)
                .opacity(0.6)

                Divider()
                    .background(Color.white.opacity(0.1))

                HStack {
                    Text("Version")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text(appVersion)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        SettingsCard(title: "Data", icon: "externaldrive.fill") {
            VStack(spacing: 12) {
                Button(action: { showLogoutConfirmation = true }) {
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
        storage.clearAllData()
        // Re-create guest session
        _ = storage.ensureGuestSession()
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
                    .font(.system(size: 18, weight: .semibold))
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
                .font(.system(size: 15))
                .foregroundColor(destructive ? AppTheme.error : .white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.backgroundDark)
        .cornerRadius(10)
    }
}

// MARK: - About Sheet View

struct AboutSheetView: View {
    @Environment(\.dismiss) private var dismiss

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

                            Image(systemName: "bolt.fill")
                                .font(.system(size: 44))
                                .foregroundColor(AppTheme.connectorGlow)
                        }
                        .padding(.top, 20)

                        // App Name
                        Text("Maxi's Mighty Mindgames")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        // Description
                        VStack(spacing: 16) {
                            Text("A fun, educational puzzle platform for children aged 5-11.")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)

                            Text("Built with love for Maxi")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.accentPrimary)
                        }
                        .padding(.horizontal, 24)

                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.horizontal)

                        // Features
                        VStack(alignment: .leading, spacing: 16) {
                            FeatureRow(icon: "bolt.fill", title: "Circuit Challenge", description: "Find the path using arithmetic")
                            FeatureRow(icon: "star.fill", title: "10 Difficulty Levels", description: "From simple addition to advanced operations")
                            FeatureRow(icon: "eye.slash.fill", title: "Hidden Mode", description: "Test yourself without seeing mistakes")
                            FeatureRow(icon: "printer.fill", title: "Print Puzzles", description: "Generate worksheets for offline practice")
                        }
                        .padding(.horizontal, 24)

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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13))
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
