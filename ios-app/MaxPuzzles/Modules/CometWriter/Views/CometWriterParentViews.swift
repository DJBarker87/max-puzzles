import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CometAdultGateView: View {
    let title: String
    let detail: String
    let onCancel: () -> Void
    let onUnlock: () -> Void

    @State private var left = Int.random(in: 12...19)
    @State private var right = Int.random(in: 6...9)
    @State private var answer = ""
    @State private var errorMessage: String?
    @FocusState private var answerFocused: Bool

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack {
                PremiumIconButton(
                    icon: "chevron.left",
                    action: onCancel,
                    size: 48,
                    accessibilityLabelText: "Go back"
                )
                Spacer()
            }

            Spacer(minLength: 12)

            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 54, weight: .semibold))
                .foregroundColor(AppTheme.cometCyan)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Text(detail)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                Text("Grown-up check")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.cometGold)
                    .textCase(.uppercase)
                Text("What is \(left) × \(right)?")
                    .font(AppTypography.displayMedium)
                    .foregroundColor(AppTheme.textPrimary)

                TextField("Answer", text: $answer)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: 210, minHeight: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.cometPaperTop)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(errorMessage == nil ? AppTheme.cometPurple.opacity(0.45) : AppTheme.error, lineWidth: 1.5)
                    )
                    .focused($answerFocused)
                    .accessibilityLabel("Answer to the grown-up check")

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.error)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("comet-grown-up-check-error")
                }

                PrimaryButton("Continue", icon: "lock.open.fill", size: .large) {
                    validate()
                }
                .accessibilityIdentifier("comet-grown-up-check-continue")
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.backgroundMid.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppTheme.cometCyan.opacity(0.28), lineWidth: 1)
            )

            Text("Compact profile, mastery and progress data may sync privately with Apple iCloud. Detailed attempts, traces, custom words and recordings stay on this device.")
                .font(AppTypography.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppSpacing.md)
        .onAppear { answerFocused = true }
        .accessibilityIdentifier("comet-grown-up-check")
    }

    private func validate() {
        guard Int(answer) == left * right else {
            errorMessage = "That answer is not right. Here is a new check."
            left = Int.random(in: 12...19)
            right = Int.random(in: 6...9)
            answer = ""
            FeedbackManager.shared.haptic(.soft)
            return
        }
        errorMessage = nil
        FeedbackManager.shared.haptic(.success)
        onUnlock()
    }
}

struct CometMissionControlView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CometLearningStore.shared

    @State private var isUnlocked = false
    @State private var showsProfiles = false
    @State private var selectedAttempt: CometAttemptRecord?
    @State private var reportURL: URL?
    @State private var reportError: String?

    private let columns = [GridItem(.adaptive(minimum: 42), spacing: 7)]

    var body: some View {
        ZStack {
            AppTheme.backgroundDark.ignoresSafeArea()
            StarryBackground(starCount: 24, animateStars: false)

            if isUnlocked {
                dashboard
            } else {
                CometAdultGateView(
                    title: "Mission Control",
                    detail: "Progress, profiles, replay and reports are for grown-ups.",
                    onCancel: { dismiss() },
                    onUnlock: { isUnlocked = true }
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showsProfiles) {
            CometProfileManagerView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedAttempt) { attempt in
            CometTraceReplayView(attempt: attempt)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(
            isPresented: Binding(
                get: { reportURL != nil },
                set: { if !$0 { reportURL = nil } }
            )
        ) {
            if let reportURL {
                ShareSheet(items: [reportURL])
            }
        }
        .alert("Could not create report", isPresented: Binding(
            get: { reportError != nil },
            set: { if !$0 { reportError = nil } }
        )) {
            Button("OK", role: .cancel) { reportError = nil }
        } message: {
            Text(reportError ?? "Please try again.")
        }
        .accessibilityIdentifier("comet-mission-control")
    }

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                profileBanner
                summaryCards
                nextStepCard
                masterySection
                correctionSection
                spellingSection
                recentSection
                reportSection
            }
            .frame(maxWidth: 920)
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        HStack(spacing: AppSpacing.md) {
            PremiumIconButton(
                icon: "chevron.left",
                action: { dismiss() },
                size: 48,
                accessibilityLabelText: "Back to Comet Writer"
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("Mission Control")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Clear, local learning evidence")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.top, AppSpacing.md)
    }

    private var profileBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 34))
                .foregroundColor(AppTheme.cometCyan)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(store.activeProfile.name)
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text(
                    "\(store.activeWritingHand.title)-handed · \(store.activeAttempts.count) writing · \(store.activeSpellingAttempts.count) spelling attempts"
                )
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
            Button("Profiles") { showsProfiles = true }
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.cometCyan)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(Capsule().fill(AppTheme.cometPaperTop))
                .buttonStyle(.plain)
                .accessibilityIdentifier("comet-manage-profiles")
        }
        .padding(AppSpacing.md)
        .cometPanel()
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: AppSpacing.sm)], spacing: AppSpacing.sm) {
            metricCard(
                title: "Average",
                value: store.activeAverageScore.map { "\($0)%" } ?? "—",
                icon: "scope",
                color: AppTheme.cometCyan
            )
            metricCard(
                title: "Secure",
                value: "\(secureCount)",
                icon: "checkmark.seal.fill",
                color: AppTheme.accentPrimary
            )
            metricCard(
                title: "Mastered",
                value: "\(masteredCount)",
                icon: "star.fill",
                color: AppTheme.cometGold
            )
            metricCard(
                title: "Points",
                value: "\(store.activePoints)",
                icon: "sparkles",
                color: AppTheme.cometPurple
            )
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(minHeight: 72)
        .cometPanel()
        .accessibilityElement(children: .combine)
    }

    private var nextStepCard: some View {
        let weakest = store.recommendedCharacters(from: LetterLibrary.practiceOrder, count: 3)
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 23, weight: .bold))
                .foregroundColor(AppTheme.cometGold)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text("Suggested next step")
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.textPrimary)
                Text(
                    weakest.isEmpty
                        ? "Complete a first writing mission to unlock a recommendation."
                        : "Practise \(weakest.joined(separator: ", ")) next. These symbols have the least secure evidence."
                )
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.cometGold.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppTheme.cometGold.opacity(0.28), lineWidth: 1)
        )
    }

    private var masterySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionTitle("Formation map", detail: "Tap-free overview: new, practising, secure and mastered.")

            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(LetterLibrary.all) { glyph in
                    let mastery = store.mastery(for: glyph.character)
                    VStack(spacing: 1) {
                        Text(glyph.character)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        if let best = store.bestScore(for: glyph.character) {
                            Text("\(best)")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                        }
                    }
                    .foregroundColor(mastery == .mastered ? AppTheme.backgroundDark : AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 45)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(masteryColor(mastery))
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(glyph.formationName), \(mastery.title), best score \(store.bestScore(for: glyph.character).map(String.init) ?? "none")")
                }
            }

            HStack(spacing: 12) {
                masteryKey(.new)
                masteryKey(.practising)
                masteryKey(.secure)
                masteryKey(.mastered)
            }
            .font(AppTypography.caption)
        }
        .padding(AppSpacing.md)
        .cometPanel()
    }

    private func masteryKey(_ level: CometMasteryLevel) -> some View {
        HStack(spacing: 4) {
            Circle().fill(masteryColor(level)).frame(width: 9, height: 9)
            Text(level.title).foregroundColor(AppTheme.textSecondary)
        }
    }

    private var correctionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionTitle("Helpful corrections", detail: "Counts show what to model, not what a child did ‘wrong’.")
            let totals = store.correctionTotals()
            let items = [
                ("Starting point", "start", 5),
                ("Direction", "direction", 6),
                ("Path control", "track", 2),
                ("Writing line", "baseline", 6),
                ("Finishing point", "finish", 4)
            ]
            ForEach(items, id: \.1) { item in
                correctionRow(title: item.0, count: totals[item.1, default: 0], weight: item.2)
            }
        }
        .padding(AppSpacing.md)
        .cometPanel()
    }

    private func correctionRow(title: String, count: Int, weight: Int) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textPrimary)
                .frame(width: 105, alignment: .leading)
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.cometPurple.opacity(0.18))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(count == 0 ? AppTheme.accentPrimary.opacity(0.55) : AppTheme.cometCyan.opacity(0.72))
                            .frame(width: count == 0 ? 3 : min(geometry.size.width, CGFloat(count * weight + 8)))
                    }
            }
            .frame(height: 8)
            Text("\(count)")
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 28, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private var spellingSection: some View {
        let summary = store.activeSpellingSummary
        let words = store.spellingProgress(limit: 12)

        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionTitle(
                "Spelling progress",
                detail: "Star Speller records attempts, successful spellings, corrections and hint use."
            )

            if summary.totalAttempts == 0 {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppTheme.cometCyan)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No spelling evidence yet")
                            .font(AppTypography.buttonLarge)
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Complete a Star Speller word and its result will appear here.")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 135), spacing: AppSpacing.sm)],
                    spacing: AppSpacing.sm
                ) {
                    spellingMetric(
                        title: "Attempts",
                        value: "\(summary.totalAttempts)",
                        icon: "keyboard.fill"
                    )
                    spellingMetric(
                        title: "First try",
                        value: "\(summary.firstTryPercentage)%",
                        icon: "sparkles"
                    )
                    spellingMetric(
                        title: "Hints",
                        value: "\(summary.totalHints)",
                        icon: "lightbulb.fill"
                    )
                    spellingMetric(
                        title: "Mastered",
                        value: "\(summary.masteredWords)",
                        icon: "star.fill"
                    )
                }

                VStack(spacing: AppSpacing.sm) {
                    ForEach(words) { word in
                        HStack(spacing: 12) {
                            Text(StarSpellerWordLibrary.displayForm(for: word.word))
                                .font(AppTypography.buttonLarge)
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 105, alignment: .leading)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(word.mastery.title)
                                    .font(AppTypography.buttonSmall)
                                    .foregroundColor(masteryTextColor(word.mastery))
                                Text(
                                    "\(word.attempts) attempt\(word.attempts == 1 ? "" : "s") · \(word.errors) error\(word.errors == 1 ? "" : "s") · \(word.hints) hint\(word.hints == 1 ? "" : "s")"
                                )
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            }

                            Spacer(minLength: 0)

                            Circle()
                                .fill(masteryColor(word.mastery))
                                .frame(width: 16, height: 16)
                                .accessibilityHidden(true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "\(word.word), \(word.mastery.title), \(word.attempts) attempts, \(word.successes) successful, \(word.errors) errors, \(word.hints) hints"
                        )
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .cometPanel()
        .accessibilityIdentifier("comet-spelling-summary")
    }

    private func spellingMetric(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.cometGold)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(minHeight: 64)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.backgroundDark.opacity(0.58))
        )
        .accessibilityElement(children: .combine)
    }

    private func masteryTextColor(_ level: CometMasteryLevel) -> Color {
        switch level {
        case .new: return AppTheme.textSecondary
        case .practising: return AppTheme.cometPurple
        case .secure: return AppTheme.cometCyan
        case .mastered: return AppTheme.accentPrimary
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionTitle("Recent flights", detail: "Open a Ghost Trail to replay exactly what was written.")

            if store.recentAttempts(limit: 12).isEmpty {
                Text("No attempts yet. Completed letters and words will appear here.")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.vertical, AppSpacing.md)
            } else {
                ForEach(store.recentAttempts(limit: 12)) { attempt in
                    Button { selectedAttempt = attempt } label: {
                        HStack(spacing: 12) {
                            Text(attempt.character)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                                .foregroundColor(AppTheme.cometCyan)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(AppTheme.cometPurple.opacity(0.18)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(attempt.mode.title)
                                    .font(AppTypography.buttonSmall)
                                    .foregroundColor(AppTheme.textPrimary)
                                Text(attempt.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer(minLength: 0)
                            Text("\(attempt.score)%")
                                .font(AppTypography.buttonLarge)
                                .foregroundColor(attempt.score >= 90 ? AppTheme.accentPrimary : AppTheme.cometGold)
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppTheme.cometCyan)
                        }
                        .padding(.vertical, 7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Replay \(attempt.character), \(attempt.score) out of 100, \(attempt.mode.title)")
                }
            }
        }
        .padding(AppSpacing.md)
        .cometPanel()
    }

    private var reportSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Progress report")
                .font(AppTypography.buttonLarge)
                .foregroundColor(AppTheme.textPrimary)
            Text("Create a printable PDF containing scores and next steps. Nothing is uploaded.")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton("Share / Print PDF", icon: "square.and.arrow.up", size: .medium) {
                do {
                    reportURL = try CometProgressReportRenderer.makeReport(
                        profile: store.activeProfile,
                        attempts: store.activeAttempts
                    )
                } catch {
                    reportError = "The report could not be saved on this device."
                }
            }
            .accessibilityIdentifier("comet-export-progress-report")
        }
        .padding(AppSpacing.md)
        .cometPanel()
    }

    private func sectionTitle(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)
            Text(detail)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var secureCount: Int {
        LetterLibrary.all.filter { store.mastery(for: $0.character) >= .secure }.count
    }

    private var masteredCount: Int {
        LetterLibrary.all.filter { store.mastery(for: $0.character) == .mastered }.count
    }

    private func masteryColor(_ level: CometMasteryLevel) -> Color {
        switch level {
        case .new: return AppTheme.cometPaperTop
        case .practising: return AppTheme.cometPurple.opacity(0.42)
        case .secure: return AppTheme.cometCyan.opacity(0.48)
        case .mastered: return AppTheme.accentPrimary
        }
    }
}

private struct CometProfileManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CometLearningStore.shared

    @State private var name = ""
    @State private var hand: WritingHand = .right
    @State private var profilePendingDeletion: CometChildProfile?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        ForEach(store.profiles) { profile in
                            profileRow(profile)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add a child")
                                .font(AppTypography.titleSmall)
                                .foregroundColor(AppTheme.textPrimary)
                            TextField("Name", text: $name)
                                .textInputAutocapitalization(.words)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .frame(minHeight: 50)
                                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cometPaperTop))
                            Picker("Writing hand", selection: $hand) {
                                ForEach(WritingHand.allCases) { value in
                                    Text(value.title).tag(value)
                                }
                            }
                            .pickerStyle(.segmented)
                            PrimaryButton("Add profile", icon: "person.badge.plus", size: .medium) {
                                store.addProfile(name: name, writingHand: hand)
                                name = ""
                            }
                        }
                        .padding(AppSpacing.md)
                        .cometPanel()
                    }
                    .padding(AppSpacing.md)
                }
            }
            .navigationTitle("Child profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.cometCyan)
                }
            }
        }
        .alert(
            "Delete \(profilePendingDeletion?.name ?? "this profile")?",
            isPresented: Binding(
                get: { profilePendingDeletion != nil },
                set: { isPresented in
                    if !isPresented { profilePendingDeletion = nil }
                }
            )
        ) {
            Button("Delete profile", role: .destructive) {
                deletePendingProfile()
            }
            Button("Keep profile", role: .cancel) {
                profilePendingDeletion = nil
            }
        } message: {
            Text("Writing progress, spelling progress, custom words and voice recordings for this child will be permanently deleted.")
        }
        .preferredColorScheme(.dark)
    }

    private func profileRow(_ profile: CometChildProfile) -> some View {
        HStack(spacing: 12) {
            Button {
                store.setActiveProfile(profile.id)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: profile.id == store.activeProfileID ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(profile.id == store.activeProfileID ? AppTheme.accentPrimary : AppTheme.textSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(AppTypography.buttonLarge)
                            .foregroundColor(AppTheme.textPrimary)
                        Text("\(profile.writingHand.title)-handed")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                profilePendingDeletion = profile
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(store.profiles.count > 1 ? AppTheme.error : AppTheme.textSecondary.opacity(0.35))
                    .frame(width: 44, height: 44)
            }
            .disabled(store.profiles.count <= 1)
            .accessibilityLabel("Delete \(profile.name)'s profile")
        }
        .padding(AppSpacing.md)
        .cometPanel()
    }

    private func deletePendingProfile() {
        guard let profile = profilePendingDeletion else { return }
        for filename in store.recordingFilenames(for: profile.id) {
            CustomPromptAudioService.shared.delete(filename: filename)
        }
        store.deleteProfile(profile.id)
        profilePendingDeletion = nil
    }
}

struct CometCustomWordsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var store = CometLearningStore.shared
    @ObservedObject private var audio = CustomPromptAudioService.shared

    @State private var isUnlocked = false
    @State private var newWord = ""
    @State private var newContextSentence = ""
    @State private var message: String?
    @State private var showsWordImporter = false
    @State private var editingContextWord: CometCustomWord?
    @State private var recordingStartTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            AppTheme.backgroundDark.ignoresSafeArea()
            StarryBackground(starCount: 24, animateStars: false)

            if isUnlocked {
                content
            } else {
                CometAdultGateView(
                    title: "My Words",
                    detail: "A grown-up can add or import spelling words, example sentences and optional voice prompts.",
                    onCancel: { dismiss() },
                    onUnlock: { isUnlocked = true }
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onDisappear { endAudioSession() }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                endAudioSession()
            }
        }
        .fileImporter(
            isPresented: $showsWordImporter,
            allowedContentTypes: [.plainText, .commaSeparatedText]
        ) { result in
            importWordList(result)
        }
        .sheet(item: $editingContextWord) { word in
            CometWordContextEditor(word: word)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .accessibilityIdentifier("comet-custom-words")
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(spacing: AppSpacing.md) {
                    PremiumIconButton(
                        icon: "chevron.left",
                        action: { dismiss() },
                        size: 48,
                        accessibilityLabelText: "Back to Comet Writer"
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("My Words")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(AppTheme.textPrimary)
                        Text("For \(store.activeProfile.name) · used in Comet Writer and Star Speller")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }

                addCard
                wordsCard
                privacyCard
            }
            .frame(maxWidth: 760)
            .padding(AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
        }
        .scrollIndicators(.hidden)
    }

    private var addCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a practice word")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)
            Text("Use 1–10 letters. Add an optional example sentence so sound-alike words are clear.")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showsWordImporter = true
            } label: {
                Label("Import TXT or CSV list", systemImage: "doc.badge.plus")
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.backgroundDark)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.cometCyan)
                    )
            }
            .buttonStyle(.plain)
            .disabled(store.activeCustomWords.count >= CometLearningStore.maximumCustomWords)
            .opacity(
                store.activeCustomWords.count >= CometLearningStore.maximumCustomWords ? 0.45 : 1
            )
            .accessibilityHint("Choose a word list, or a CSV with word and context columns")
            .accessibilityIdentifier("comet-import-word-list")

            HStack(spacing: AppSpacing.sm) {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)
                Text("or add one word")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize()
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)
            }

            HStack(spacing: 10) {
                TextField("e.g. max", text: $newWord)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cometPaperTop))
                    .accessibilityIdentifier("comet-custom-word-input")
                Button {
                    addWord()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.backgroundDark)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(AppTheme.accentPrimary))
                }
                .buttonStyle(.plain)
                .disabled(store.activeCustomWords.count >= CometLearningStore.maximumCustomWords)
                .accessibilityLabel("Add practice word")
            }

            TextField(
                "Example sentence (optional)",
                text: $newContextSentence,
                axis: .vertical
            )
            .lineLimit(2...4)
            .font(AppTypography.bodyMedium)
            .foregroundColor(AppTheme.textPrimary)
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cometPaperTop))
            .accessibilityLabel("Optional example sentence")
            .accessibilityHint("For example, The red ball is over there")
            .accessibilityIdentifier("comet-custom-word-context")

            Text("For contextual imports, use CSV headings “word,context” or write “word :: example sentence” on each line.")
                .font(AppTypography.caption)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let message {
                Text(message)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(messageColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.md)
        .cometPanel()
    }

    private var wordsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Saved words")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(store.activeCustomWords.count)/\(CometLearningStore.maximumCustomWords)")
                    .font(AppTypography.buttonSmall)
                    .foregroundColor(AppTheme.cometCyan)
            }

            if store.activeCustomWords.isEmpty {
                Text("No custom words yet. Star Speller will use its England Year 1 starter list, and Comet Writer’s built-in list is still available.")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.vertical, AppSpacing.md)
            }

            ForEach(store.activeCustomWords) { word in
                wordRow(word)
            }
        }
        .padding(AppSpacing.md)
        .cometPanel()
    }

    private func wordRow(_ word: CometCustomWord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(word.text)
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text(word.contextSentence ?? "No example sentence")
                    .font(AppTypography.caption)
                    .foregroundColor(
                        word.contextSentence == nil
                            ? AppTheme.textSecondary
                            : AppTheme.cometCyan
                    )
                    .lineLimit(2)
            }
            Spacer(minLength: 0)

            Button {
                editingContextWord = word
            } label: {
                Image(systemName: "text.quote")
                    .frame(width: 44, height: 44)
                    .foregroundColor(AppTheme.cometPurple)
                    .background(Circle().fill(AppTheme.cometPaperTop))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                word.contextSentence == nil
                    ? "Add an example sentence for \(word.text)"
                    : "Edit the example sentence for \(word.text)"
            )

            if let filename = word.recordingFilename {
                Button {
                    audio.play(filename: filename)
                } label: {
                    Image(systemName: audio.playingFilename == filename ? "stop.fill" : "play.fill")
                        .frame(width: 44, height: 44)
                        .foregroundColor(AppTheme.cometCyan)
                        .background(Circle().fill(AppTheme.cometPaperTop))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(audio.playingFilename == filename ? "Stop voice prompt" : "Play voice prompt")
            }

            Button {
                toggleRecording(word)
            } label: {
                Image(systemName: audio.recordingWordID == word.id ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 25))
                    .frame(width: 44, height: 44)
                    .foregroundColor(audio.recordingWordID == word.id ? AppTheme.error : AppTheme.cometGold)
            }
            .buttonStyle(.plain)
            .disabled(audio.recordingWordID != nil && audio.recordingWordID != word.id)
            .accessibilityLabel(audio.recordingWordID == word.id ? "Stop recording \(word.text)" : "Record \(word.text)")

            Button(role: .destructive) {
                if audio.recordingWordID == word.id,
                   let unfinishedFilename = audio.stopRecording() {
                    audio.delete(filename: unfinishedFilename)
                }
                if let filename = store.deleteCustomWord(word.id) {
                    audio.delete(filename: filename)
                }
            } label: {
                Image(systemName: "trash")
                    .frame(width: 44, height: 44)
                    .foregroundColor(AppTheme.error)
            }
            .accessibilityLabel("Delete \(word.text)")
        }
        .padding(.vertical, 5)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
        }
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Private by design", systemImage: "lock.shield.fill")
                .font(AppTypography.buttonLarge)
                .foregroundColor(AppTheme.accentPrimary)
            Text("Recordings are optional, made only after a tap, and stored locally inside the app. They are deleted with the word, profile or Clear All Data.")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if audio.permissionDenied {
                Button("Open microphone settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.cometCyan)
                .frame(minHeight: 44)
            }
        }
        .padding(AppSpacing.md)
        .cometPanel()
    }

    private func addWord() {
        guard let word = store.addCustomWord(
            newWord,
            contextSentence: newContextSentence
        ) else {
            message = store.activeCustomWords.count >= CometLearningStore.maximumCustomWords
                ? "This profile already has \(CometLearningStore.maximumCustomWords) custom words."
                : "Use a new word containing 1–10 letters."
            return
        }
        newWord = ""
        newContextSentence = ""
        message = "Added \(word.text)."
        FeedbackManager.shared.haptic(.success)
    }

    private var messageColor: Color {
        guard let message else { return AppTheme.textSecondary }
        return message.hasPrefix("Added") || message.hasPrefix("Imported")
            ? AppTheme.accentPrimary
            : AppTheme.cometGold
    }

    private func importWordList(_ result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess { url.stopAccessingSecurityScopedResource() }
            }

            do {
                let data = try Data(contentsOf: url)
                guard data.count <= 1_000_000 else {
                    message = "That file is too large. Choose a word list smaller than 1 MB."
                    return
                }
                guard let text = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .utf16) else {
                    message = "That file could not be read. Save it as UTF-8 TXT or CSV and try again."
                    return
                }

                let importResult = store.importCustomWords(from: text)
                guard !importResult.addedWords.isEmpty else {
                    message = importResult.overflowCount > 0
                        ? "This profile’s word list is full."
                        : "No new words found. Use unique words containing 1–10 letters."
                    return
                }

                let noun = importResult.addedWords.count == 1 ? "word" : "words"
                var importMessage = "Imported \(importResult.addedWords.count) \(noun)."
                if importResult.skippedCount > 0 {
                    importMessage += " Skipped \(importResult.skippedCount) duplicate or unusable entries."
                }
                message = importMessage
                FeedbackManager.shared.haptic(.success)
            } catch {
                message = "That file could not be opened. Choose it again or try another TXT or CSV file."
            }

        case .failure:
            message = "The word list was not imported. Please choose the file again."
        }
    }

    private func toggleRecording(_ word: CometCustomWord) {
        if audio.recordingWordID == word.id {
            if let filename = audio.stopRecording() {
                store.setRecordingFilename(filename, for: word.id)
                message = "Added your voice prompt for \(word.text)."
            }
            return
        }

        recordingStartTask?.cancel()
        recordingStartTask = Task { @MainActor in
            let started = await audio.startRecording(for: word)
            guard !Task.isCancelled else { return }
            recordingStartTask = nil
            if !started {
                message = audio.permissionDenied
                    ? "Microphone access is off. You can enable it in Settings."
                    : "Recording could not start. Please try again."
            } else {
                message = "Recording \(word.text)… tap stop when finished."
            }
        }
    }

    private func finishRecordingIfNeeded() {
        guard let wordID = audio.recordingWordID,
              let filename = audio.stopRecording() else { return }
        store.setRecordingFilename(filename, for: wordID)
    }

    private func endAudioSession() {
        recordingStartTask?.cancel()
        recordingStartTask = nil
        finishRecordingIfNeeded()
        audio.stopPlayback()
    }
}

private struct CometWordContextEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CometLearningStore.shared

    let word: CometCustomWord
    @State private var sentence: String

    init(word: CometCustomWord) {
        self.word = word
        _sentence = State(initialValue: word.contextSentence ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Example for “\(word.text)”")
                        .font(AppTypography.titleSmall)
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Use a short sentence that makes the meaning obvious, especially for sound-alike words.")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField(
                        "Example sentence (optional)",
                        text: $sentence,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.cometPaperTop)
                    )
                    .accessibilityLabel("Example sentence for \(word.text)")

                    Text("\(sentence.count)/\(CometLearningStore.maximumContextSentenceLength)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Spacer(minLength: 0)
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Word context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setContextSentence(sentence, for: word.id)
                        dismiss()
                    }
                    .foregroundColor(AppTheme.cometCyan)
                }
            }
            .onChange(of: sentence) { value in
                if value.count > CometLearningStore.maximumContextSentenceLength {
                    sentence = String(
                        value.prefix(CometLearningStore.maximumContextSentenceLength)
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct CometTraceReplayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let attempt: CometAttemptRecord
    @State private var progress: Double = 1
    @State private var replayTask: Task<Void, Never>?

    private var glyph: LetterGlyph? { LetterLibrary.glyph(for: attempt.character) }
    private var traces: [[LetterPoint]] { attempt.traces.map { $0.map(\.letterPoint) } }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()
                VStack(spacing: AppSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ghost Trail · \(attempt.character)")
                                .font(AppTypography.titleSmall)
                                .foregroundColor(AppTheme.textPrimary)
                            Text("\(attempt.mode.title) · \(attempt.score) out of 100")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Label("+\(attempt.pointsEarned)", systemImage: "sparkles")
                            .font(AppTypography.buttonSmall)
                            .foregroundColor(AppTheme.cometGold)
                    }

                    Canvas { context, size in
                        drawWritingLines(context: &context, size: size)
                        drawReference(context: &context, size: size)
                        drawTrace(context: &context, size: size)
                    }
                    .frame(minHeight: 330)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.cometPaperTop, AppTheme.cometPaperBottom],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppTheme.cometCyan.opacity(0.35), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .accessibilityLabel("Replay of the saved writing trace for \(attempt.character)")

                    Slider(value: $progress, in: 0...1)
                        .tint(AppTheme.cometCyan)
                        .accessibilityLabel("Replay position")

                    HStack(spacing: AppSpacing.md) {
                        Button {
                            play()
                        } label: {
                            Label("Replay", systemImage: "play.fill")
                                .font(AppTypography.buttonMedium)
                                .foregroundColor(AppTheme.backgroundDark)
                                .padding(.horizontal, 18)
                                .frame(minHeight: 48)
                                .background(Capsule().fill(AppTheme.cometCyan))
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Path \(attempt.breakdown.pathAccuracy)/40 · Moves \(attempt.breakdown.formation)/25")
                            Text("Lines \(attempt.breakdown.linePlacement)/15 · Smooth \(attempt.breakdown.smoothness)/10 · Solo \(attempt.breakdown.independence)/10")
                        }
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Trace replay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.cometCyan)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear { replayTask?.cancel() }
    }

    private func play() {
        replayTask?.cancel()
        if reduceMotion {
            progress = 1
            return
        }
        progress = 0
        replayTask = Task { @MainActor in
            for step in 0...100 {
                guard !Task.isCancelled else { return }
                progress = Double(step) / 100
                try? await Task.sleep(nanoseconds: 24_000_000)
            }
        }
    }

    private func drawWritingLines(context: inout GraphicsContext, size: CGSize) {
        let geometry = LetterCanvasGeometry(size: size, contentInset: 24)
        for (line, opacity, dash) in [
            (LetterWritingMetrics.topLineY, 0.12, [CGFloat(5), 7]),
            (LetterWritingMetrics.xHeightLineY, 0.18, [CGFloat(5), 7]),
            (LetterWritingMetrics.baselineY, 0.32, [CGFloat]()),
            (LetterWritingMetrics.descenderLineY, 0.12, [CGFloat(5), 7])
        ] {
            let y = geometry.render(LetterPoint(x: 0.5, y: line)).y
            var path = Path()
            path.move(to: CGPoint(x: 20, y: y))
            path.addLine(to: CGPoint(x: size.width - 20, y: y))
            context.stroke(
                path,
                with: .color(AppTheme.cometGuide.opacity(opacity)),
                style: StrokeStyle(lineWidth: 1.5, dash: dash)
            )
        }
    }

    private func drawReference(context: inout GraphicsContext, size: CGSize) {
        guard let glyph else { return }
        let geometry = LetterCanvasGeometry(size: size, contentInset: 24)
        for stroke in glyph.strokes {
            let points = stroke.points.map(geometry.render)
            context.stroke(
                path(points),
                with: .color(AppTheme.cometGuide.opacity(0.16)),
                style: StrokeStyle(lineWidth: 13, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func drawTrace(context: inout GraphicsContext, size: CGSize) {
        let geometry = LetterCanvasGeometry(size: size, contentInset: 24)
        let totalPointCount = max(1, traces.reduce(0) { $0 + $1.count })
        var remaining = Int((Double(totalPointCount) * progress).rounded(.down))

        for trace in traces where remaining > 0 {
            let count = min(trace.count, remaining)
            let rendered = trace.prefix(count).map(geometry.render)
            context.stroke(
                path(rendered),
                with: .color(AppTheme.cometCyan.opacity(0.95)),
                style: StrokeStyle(lineWidth: 11, lineCap: .round, lineJoin: .round)
            )
            remaining -= count
        }
    }

    private func path<S: Sequence>(_ points: S) -> Path where S.Element == CGPoint {
        var result = Path()
        var iterator = points.makeIterator()
        guard let first = iterator.next() else { return result }
        result.move(to: first)
        while let next = iterator.next() { result.addLine(to: next) }
        return result
    }
}

private enum CometProgressReportRenderer {
    static func makeReport(profile: CometChildProfile, attempts: [CometAttemptRecord]) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let data = renderer.pdfData { context in
            context.beginPage()
            drawHeader(profile: profile, in: page)
            drawSummary(attempts: attempts)
            drawFormationGrid(attempts: attempts)
            drawFooter(page: 1)

            context.beginPage()
            drawAttemptHistory(attempts: attempts)
            drawFooter(page: 2)
        }

        let safeName = profile.name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Comet-Writer-\(safeName.isEmpty ? "Progress" : safeName)-Report.pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func drawHeader(profile: CometChildProfile, in page: CGRect) {
        UIColor(red: 0.06, green: 0.06, blue: 0.14, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: page.width, height: 118)).fill()
        draw(
            "COMET WRITER",
            at: CGRect(x: 42, y: 30, width: 510, height: 28),
            font: .systemFont(ofSize: 13, weight: .bold),
            color: UIColor(red: 0.40, green: 0.91, blue: 0.98, alpha: 1)
        )
        draw(
            "\(profile.name)’s progress report",
            at: CGRect(x: 42, y: 56, width: 510, height: 42),
            font: .systemFont(ofSize: 26, weight: .bold),
            color: .white
        )
        draw(
            "Generated \(Date().formatted(date: .long, time: .omitted)) · Local learning record",
            at: CGRect(x: 42, y: 126, width: 510, height: 22),
            font: .systemFont(ofSize: 10),
            color: .darkGray
        )
    }

    private static func drawSummary(attempts: [CometAttemptRecord]) {
        let average = attempts.isEmpty
            ? "—"
            : "\(Int((Double(attempts.reduce(0) { $0 + $1.score }) / Double(attempts.count)).rounded()))%"
        let independent = attempts.filter(\.wasIndependent).count
        let points = attempts.reduce(0) { $0 + $1.pointsEarned }
        let values = [("Average score", average), ("Saved attempts", "\(attempts.count)"), ("Independent", "\(independent)"), ("Comet Points", "\(points)")]

        for (index, value) in values.enumerated() {
            let x = 42 + CGFloat(index) * 129
            UIColor(white: 0.95, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: x, y: 164, width: 116, height: 66), cornerRadius: 10).fill()
            draw(value.1, at: CGRect(x: x + 10, y: 175, width: 96, height: 25), font: .systemFont(ofSize: 20, weight: .bold), color: .black)
            draw(value.0, at: CGRect(x: x + 10, y: 203, width: 96, height: 18), font: .systemFont(ofSize: 9), color: .darkGray)
        }
    }

    private static func drawFormationGrid(attempts: [CometAttemptRecord]) {
        draw("Formation map", at: CGRect(x: 42, y: 255, width: 510, height: 28), font: .systemFont(ofSize: 18, weight: .bold), color: .black)
        draw("Best saved score for every lowercase, capital and number formation", at: CGRect(x: 42, y: 282, width: 510, height: 20), font: .systemFont(ofSize: 10), color: .darkGray)

        let best = Dictionary(grouping: attempts, by: \.character).mapValues { records in
            records.map(\.score).max() ?? 0
        }
        let columns = 9
        let cellWidth: CGFloat = 54
        let cellHeight: CGFloat = 53
        for (index, glyph) in LetterLibrary.all.enumerated() {
            let column = index % columns
            let row = index / columns
            let x = 42 + CGFloat(column) * cellWidth
            let y = 312 + CGFloat(row) * cellHeight
            let score = best[glyph.character]
            let fill: UIColor
            switch score ?? 0 {
            case 90...: fill = UIColor(red: 0.13, green: 0.77, blue: 0.37, alpha: 0.18)
            case 75...: fill = UIColor(red: 0.40, green: 0.91, blue: 0.98, alpha: 0.18)
            case 1...: fill = UIColor(red: 0.65, green: 0.55, blue: 0.98, alpha: 0.18)
            default: fill = UIColor(white: 0.94, alpha: 1)
            }
            fill.setFill()
            UIBezierPath(roundedRect: CGRect(x: x, y: y, width: 44, height: 44), cornerRadius: 7).fill()
            draw(glyph.character, at: CGRect(x: x, y: y + 5, width: 44, height: 20), font: .systemFont(ofSize: 16, weight: .bold), color: .black, alignment: .center)
            draw(score.map(String.init) ?? "—", at: CGRect(x: x, y: y + 27, width: 44, height: 12), font: .systemFont(ofSize: 8, weight: .semibold), color: .darkGray, alignment: .center)
        }
    }

    private static func drawAttemptHistory(attempts: [CometAttemptRecord]) {
        draw("Recent writing evidence", at: CGRect(x: 42, y: 42, width: 510, height: 36), font: .systemFont(ofSize: 25, weight: .bold), color: .black)
        draw("Most recent 24 attempts", at: CGRect(x: 42, y: 80, width: 510, height: 18), font: .systemFont(ofSize: 10), color: .darkGray)

        let ordered = attempts.sorted { $0.timestamp > $1.timestamp }.prefix(24)
        if ordered.isEmpty {
            draw("No completed attempts yet.", at: CGRect(x: 42, y: 130, width: 510, height: 24), font: .systemFont(ofSize: 13), color: .darkGray)
            return
        }

        for (index, attempt) in ordered.enumerated() {
            let y = 116 + CGFloat(index) * 27
            if index.isMultiple(of: 2) {
                UIColor(white: 0.96, alpha: 1).setFill()
                UIBezierPath(rect: CGRect(x: 38, y: y - 3, width: 518, height: 26)).fill()
            }
            draw(attempt.character, at: CGRect(x: 44, y: y, width: 34, height: 20), font: .systemFont(ofSize: 13, weight: .bold), color: .black)
            draw(attempt.mode.title, at: CGRect(x: 88, y: y, width: 160, height: 20), font: .systemFont(ofSize: 10), color: .darkGray)
            draw(attempt.timestamp.formatted(date: .numeric, time: .shortened), at: CGRect(x: 255, y: y, width: 165, height: 20), font: .systemFont(ofSize: 9), color: .darkGray)
            draw("\(attempt.score)%", at: CGRect(x: 435, y: y, width: 50, height: 20), font: .systemFont(ofSize: 11, weight: .bold), color: .black, alignment: .right)
            draw("+\(attempt.pointsEarned)", at: CGRect(x: 492, y: y, width: 48, height: 20), font: .systemFont(ofSize: 10, weight: .semibold), color: UIColor(red: 0.60, green: 0.43, blue: 0.04, alpha: 1), alignment: .right)
        }
    }

    private static func drawFooter(page: Int) {
        draw("Comet Writer · Page \(page) · Progress is guidance, not a diagnosis.", at: CGRect(x: 42, y: 808, width: 510, height: 16), font: .systemFont(ofSize: 8), color: .gray, alignment: .center)
    }

    private static func draw(
        _ text: String,
        at rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        (text as NSString).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        )
    }
}

private extension View {
    func cometPanel() -> some View {
        background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.backgroundMid.opacity(0.90))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
