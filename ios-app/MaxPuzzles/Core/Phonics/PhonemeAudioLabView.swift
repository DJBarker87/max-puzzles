#if DEBUG
import SwiftUI

/// An internal audition surface for the app-level phoneme foundation. It is reachable only with
/// a Debug launch argument and is intentionally not linked from any child-facing game.
struct PhonemeAudioLabView: View {
    private enum Filter: String, CaseIterable, Identifiable {
        case all = "All 44"
        case consonants = "Consonants"
        case vowels = "Vowels"

        var id: String { rawValue }
    }

    @ObservedObject private var audio = PhonemeAudioService.shared
    @State private var filter: Filter = .all
    @State private var assetAudit: PhonemeAudioAssetAudit?

    private let columns = [
        GridItem(.adaptive(minimum: 158, maximum: 230), spacing: AppSpacing.md)
    ]

    private var visiblePhonemes: [BritishEnglishPhoneme] {
        switch filter {
        case .all:
            return BritishEnglishPhonemeCatalogue.all
        case .consonants:
            return BritishEnglishPhonemeCatalogue.all.filter { $0.category == .consonant }
        case .vowels:
            return BritishEnglishPhonemeCatalogue.all.filter { $0.category == .vowel }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundDark.ignoresSafeArea()
            decorativeBackground

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    header
                    recordingSourceNotice
                    filterControl
                    playbackStatus
                    phonemeGrid
                }
                .frame(maxWidth: 920)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .accessibilityIdentifier("phoneme-audio-lab")
        .onAppear {
            assetAudit = audio.auditApprovedRecordingAssets()
        }
        .onDisappear {
            audio.stop()
        }
    }

    private var decorativeBackground: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(AppTheme.cometPurple.opacity(0.16))
                    .frame(width: proxy.size.width * 0.8)
                    .blur(radius: 70)
                    .offset(x: proxy.size.width * 0.34, y: -proxy.size.height * 0.32)

                Circle()
                    .fill(AppTheme.cometCyan.opacity(0.12))
                    .frame(width: proxy.size.width * 0.7)
                    .blur(radius: 80)
                    .offset(x: -proxy.size.width * 0.38, y: proxy.size.height * 0.38)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var header: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "waveform.circle.fill")
                    .foregroundStyle(AppTheme.cometCyan)
                Text("Phoneme Audio Lab")
            }
            .font(AppTypography.displayMedium)
            .foregroundStyle(AppTheme.textPrimary)

            Text("44 British-English sounds")
                .font(AppTypography.titleSmall)
                .foregroundStyle(AppTheme.textSecondary)

            Text("24 consonants • 20 vowels • catalogue v1")
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.textSecondary.opacity(0.76))
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("phoneme-audio-lab-heading")
    }

    private var recordingSourceNotice: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(
                systemName: hasAnyRecordings
                    ? "waveform.badge.checkmark"
                    : "wrench.and.screwdriver.fill"
            )
                .font(.title3)
                .foregroundStyle(AppTheme.accentTertiary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(recordingSourceTitle)
                    .font(AppTypography.buttonMedium)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(recordingSourceDetail)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(recordingCoverageText)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.accentTertiary)
                    .accessibilityIdentifier("phoneme-recording-coverage")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppTheme.backgroundMid.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.accentTertiary.opacity(0.45), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("phoneme-audio-source-notice")
    }

    private var filterControl: some View {
        Picker("Sound group", selection: $filter) {
            ForEach(Filter.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("phoneme-audio-filter")
    }

    @ViewBuilder
    private var playbackStatus: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: playbackStatusIcon)
                .foregroundStyle(playbackStatusColor)
                .accessibilityHidden(true)
            Text(playbackStatusText)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("phoneme-audio-status")
    }

    private var phonemeGrid: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
            ForEach(visiblePhonemes) { phoneme in
                phonemeCard(phoneme)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: filter)
    }

    private func phonemeCard(_ phoneme: BritishEnglishPhoneme) -> some View {
        let isPlaying = currentlyPlayingID == phoneme.id.rawValue

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(phoneme.teachingGrapheme)
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: AppSpacing.sm)

                Text("/\(phoneme.curriculumIPA)/")
                    .font(.system(.headline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(AppTheme.cometCyan)
            }

            Text("as in \(phoneme.exampleWord)")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppTheme.textSecondary)

            Text(phoneme.commonGraphemes.prefix(5).joined(separator: " • "))
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.textSecondary.opacity(0.76))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            recordingStatus(for: phoneme)

            if phoneme.isDialectDependent {
                Label("Accent-dependent", systemImage: "person.wave.2.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.accentTertiary)
            }

            Button {
                if isPlaying {
                    audio.stop()
                } else if hasRecording(for: phoneme) {
                    audio.play(phoneme)
                } else {
                    audio.previewIPAInLab(phoneme)
                }
            } label: {
                Label(
                    isPlaying ? "Stop" : playbackButtonTitle(for: phoneme),
                    systemImage: isPlaying ? "stop.fill" : "speaker.wave.2.fill"
                )
                .font(AppTypography.buttonSmall)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .foregroundStyle(AppTheme.backgroundDark)
                .background(isPlaying ? AppTheme.accentTertiary : AppTheme.cometCyan)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                "\(isPlaying ? "Stop sound" : playbackButtonTitle(for: phoneme)) "
                    + "as in \(phoneme.exampleWord)"
            )
            .accessibilityHint(playbackAccessibilityHint(for: phoneme))
            .accessibilityIdentifier("phoneme-play-\(phoneme.id.rawValue)")
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 236, alignment: .topLeading)
        .background(AppTheme.backgroundMid.opacity(isPlaying ? 1 : 0.88))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    isPlaying ? AppTheme.cometCyan : Color.white.opacity(0.12),
                    lineWidth: isPlaying ? 2 : 1
                )
        )
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func recordingStatus(for phoneme: BritishEnglishPhoneme) -> some View {
        if assetAudit != nil {
            let isAvailable = hasRecording(for: phoneme)
            Label(
                isAvailable ? "Audio clip ready" : "Audio clip not installed",
                systemImage: isAvailable ? "checkmark.seal.fill" : "waveform.badge.exclamationmark"
            )
            .font(AppTypography.caption)
            .foregroundStyle(isAvailable ? AppTheme.cometCyan : AppTheme.accentTertiary)
            .accessibilityLabel(
                isAvailable ? "Recording available" : "Recording not installed"
            )
            .accessibilityIdentifier("phoneme-recording-\(phoneme.id.rawValue)")
        } else {
            Label("Checking audio clip…", systemImage: "hourglass")
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityIdentifier("phoneme-recording-\(phoneme.id.rawValue)")
        }
    }

    private var recordingCoverageText: String {
        guard let assetAudit else { return "Checking recordings…" }
        return "Recordings: \(assetAudit.available.count) of \(assetAudit.expected.count)"
    }

    private var hasAnyRecordings: Bool {
        assetAudit?.available.isEmpty == false
    }

    private func hasRecording(for phoneme: BritishEnglishPhoneme) -> Bool {
        assetAudit?.available.contains {
            $0.stableID == phoneme.id.rawValue
        } == true
    }

    private var recordingSourceTitle: String {
        hasAnyRecordings
            ? "Phoneme recordings"
            : "IPA preview — recordings not installed"
    }

    private var recordingSourceDetail: String {
        hasAnyRecordings
            ? "Use this private screen to listen to every imported clip before any game adopts the audio foundation."
            : "This clean source build uses an IPA-controlled preview. Future games accept only reviewed audio files."
    }

    private func playbackButtonTitle(for phoneme: BritishEnglishPhoneme) -> String {
        hasRecording(for: phoneme) ? "Play recording" : "Preview IPA"
    }

    private func playbackAccessibilityHint(for phoneme: BritishEnglishPhoneme) -> String {
        hasRecording(for: phoneme)
            ? "Plays the imported phoneme recording"
            : "Uses the internal IPA preview voice because the recording is not installed"
    }

    private var currentlyPlayingID: String? {
        guard case let .playing(stableID, _, _) = audio.state else { return nil }
        return stableID
    }

    private var playbackStatusText: String {
        switch audio.state {
        case .idle:
            return hasAnyRecordings
                ? "Tap Play recording to audition an imported phoneme clip."
                : "Tap Preview IPA to audition an IPA-controlled pronunciation."
        case let .playing(stableID, source, _):
            let symbol = BritishEnglishPhonemeCatalogue.all
                .first { $0.id.rawValue == stableID }?
                .curriculumIPA ?? stableID
            switch source {
            case .approvedRecording:
                return "Playing recording /\(symbol)/."
            case .ipaLabPreview:
                return "Playing IPA preview /\(symbol)/."
            }
        case let .missingApprovedRecording(reference):
            return "No recording for \(reference.stableID)."
        case let .failed(stableID, reason):
            if reason == .voiceDisabled {
                return "Spoken instructions are disabled in Settings."
            }
            return "Preview failed for \(stableID). Try again on a device."
        }
    }

    private var playbackStatusIcon: String {
        switch audio.state {
        case .idle: return "hand.tap.fill"
        case .playing: return "waveform"
        case .missingApprovedRecording: return "waveform.badge.exclamationmark"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var playbackStatusColor: Color {
        switch audio.state {
        case .idle: return AppTheme.textSecondary.opacity(0.76)
        case .playing: return AppTheme.cometCyan
        case .missingApprovedRecording, .failed: return AppTheme.accentTertiary
        }
    }
}
#endif
