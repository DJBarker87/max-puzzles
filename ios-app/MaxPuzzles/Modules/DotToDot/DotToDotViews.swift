import AVFoundation
import SwiftUI
import UIKit

/// Puzzle artwork is authored in a square coordinate space. Keeping that square centred prevents
/// familiar shapes (especially animals and vehicles) being stretched on tall or wide devices.
private func fittedDotBoardPoint(
    _ normalized: CGPoint,
    in size: CGSize,
    inset: CGFloat
) -> CGPoint {
    let availableWidth = max(1, size.width - inset * 2)
    let availableHeight = max(1, size.height - inset * 2)
    let side = min(availableWidth, availableHeight)
    let origin = CGPoint(
        x: (size.width - side) / 2,
        y: (size.height - side) / 2
    )
    return CGPoint(
        x: origin.x + normalized.x * side,
        y: origin.y + normalized.y * side
    )
}

private func dotArtworkPath(
    _ normalizedPoints: [CGPoint],
    in size: CGSize,
    inset: CGFloat,
    closes: Bool,
    smooth: Bool
) -> Path {
    Path { path in
        guard !normalizedPoints.isEmpty else { return }
        let points = normalizedPoints.map { fittedDotBoardPoint($0, in: size, inset: inset) }

        guard closes, smooth, points.count >= 3 else {
            path.move(to: points[0])
            for point in points.dropFirst() { path.addLine(to: point) }
            if closes { path.closeSubpath() }
            return
        }

        func midpoint(_ left: CGPoint, _ right: CGPoint) -> CGPoint {
            CGPoint(x: (left.x + right.x) / 2, y: (left.y + right.y) / 2)
        }

        path.move(to: midpoint(points[points.count - 1], points[0]))
        for index in points.indices {
            let current = points[index]
            let next = points[(index + 1) % points.count]
            path.addQuadCurve(to: midpoint(current, next), control: current)
        }
        path.closeSubpath()
    }
}

/// Draws one normalised tile from a source-art atlas in exactly the same fitted square used by
/// the numbered trail. The atlas contains only transparent line work, so it can be recoloured for
/// dark gameplay boards or the light paint-by-number canvas without losing any source details.
private struct DotPuzzleReferenceArtworkView: View {
    let art: DotPuzzleReferenceArt
    let inset: CGFloat
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(1, geometry.size.width - inset * 2)
            let availableHeight = max(1, geometry.size.height - inset * 2)
            let side = min(availableWidth, availableHeight)
            let originX = (geometry.size.width - side) / 2
            let originY = (geometry.size.height - side) / 2

            ZStack(alignment: .topLeading) {
                Image(art.assetName)
                    .renderingMode(.template)
                    .resizable()
                    .interpolation(.high)
                    .foregroundStyle(tint)
                    .frame(
                        width: side * CGFloat(art.columns),
                        height: side * CGFloat(art.rows)
                    )
                    .offset(
                        x: originX - CGFloat(art.column) * side,
                        y: originY - CGFloat(art.row) * side
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct DotToDotMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var musicService: MusicService
    @ObservedObject private var storage = StorageService.shared

    @State private var selectedTier: DotToDotTier = .firstDots
    @State private var selectedPuzzle: DotPuzzle?

    private var puzzles: [DotPuzzle] {
        DotPuzzleCatalog.puzzles(in: selectedTier)
    }

    private var completedPuzzleIDs: Set<String> {
        DotPuzzleCatalog.sanitizedCompletedIDs(storage.dotToDotCompletedPuzzles)
    }

    private var usesAccessibilityLayout: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()
                StarryBackground(starCount: 34, enableShootingStars: true)

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        header
                        if !usesAccessibilityLayout {
                            hero
                        }
                        playStylePicker
                        tierPicker
                        puzzleGallery
                    }
                    .frame(maxWidth: 960)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xxl)
                }
                .scrollIndicators(.hidden)
                .accessibilityIdentifier("dot-menu-scroll")
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(item: $selectedPuzzle) { puzzle in
            DotToDotPlayView(
                puzzle: puzzle,
                interactionMode: storage.dotToDotInteractionMode
            )
                .environmentObject(musicService)
        }
        .onAppear {
            if !musicService.isPlaying {
                musicService.play(track: .hub)
            }
        }
        .accessibilityIdentifier("dot-to-dot-menu")
    }

    @ViewBuilder
    private var header: some View {
        if usesAccessibilityLayout {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.md) {
                    closeButton
                    Spacer(minLength: AppSpacing.sm)
                    progressBadge
                }
                headerCopy
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppSpacing.md)
        } else {
            HStack(spacing: AppSpacing.md) {
                closeButton
                headerCopy
                Spacer(minLength: AppSpacing.sm)
                progressBadge
            }
            .padding(.top, AppSpacing.md)
        }
    }

    private var closeButton: some View {
        PremiumIconButton(
            icon: "xmark",
            action: { dismiss() },
            size: 48,
            accessibilityLabelText: "Close Dot-to-Dot"
        )
    }

    private var headerCopy: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Dot-to-Dot Discovery")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("dot-menu-title")

            Text("Find the next number, reveal it, then colour it")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(usesAccessibilityLayout ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(Color(hex: "5eead4"))
            Text("\(completedPuzzleIDs.count)/\(DotPuzzleCatalog.all.count)")
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .fixedSize(horizontal: true, vertical: false)
        .background(Capsule().fill(AppTheme.backgroundMid.opacity(0.90)))
        .accessibilityLabel("\(completedPuzzleIDs.count) of \(DotPuzzleCatalog.all.count) pictures completed")
        .accessibilityIdentifier("dot-menu-progress")
    }

    @ViewBuilder
    private var hero: some View {
        Group {
            if usesAccessibilityLayout {
                heroCopy
            } else {
                HStack(spacing: AppSpacing.md) {
                    heroIcon
                    heroCopy
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.backgroundMid.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "5eead4").opacity(0.35), lineWidth: 1)
        )
        // This card is explanatory rather than a control. Capping it prevents decorative copy
        // from consuming an entire small screen while the header and choices remain fully scaled.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var heroIcon: some View {
        Image("dot_to_dot_icon")
            .resizable()
            .scaledToFit()
            .frame(width: 78, height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
            )
            .accessibilityHidden(true)
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Can you reveal the hidden picture?")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Every dot belongs to the picture. The next number is shown and spoken, and hints keep the challenge friendly.")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tierPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Choose a number range")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)

            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(DotPuzzleCatalog.availableTiers) { tier in
                        Button {
                            SoundEffectsService.shared.play(.buttonTap)
                            FeedbackManager.shared.haptic(.light)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTier = tier
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: tier.icon)
                                    .font(.system(size: 24, weight: .bold))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tier.title)
                                        .font(AppTypography.buttonMedium)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text("\(tier.rangeLabel) • \(tier.subtitle)")
                                        .font(AppTypography.caption)
                                        .opacity(0.82)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .foregroundColor(selectedTier == tier ? AppTheme.backgroundDark : AppTheme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, usesAccessibilityLayout ? 10 : 0)
                            .frame(minWidth: usesAccessibilityLayout ? 250 : nil)
                            .frame(minHeight: 58)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        selectedTier == tier
                                            ? tier.color
                                            : AppTheme.backgroundMid.opacity(0.88)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(tier.color.opacity(0.55), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(tier.title), numbers \(tier.rangeLabel), \(tier.subtitle)")
                        .accessibilityAddTraits(selectedTier == tier ? .isSelected : [])
                        .accessibilityIdentifier("dot-tier-\(tier.rawValue)")
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var playStylePicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("How would you like to join the dots?")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)

            Group {
                if usesAccessibilityLayout {
                    VStack(spacing: AppSpacing.sm) {
                        playStyleButtons
                    }
                } else {
                    HStack(spacing: AppSpacing.sm) {
                        playStyleButtons
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var playStyleButtons: some View {
                ForEach(DotInteractionMode.allCases) { mode in
                    let selected = storage.dotToDotInteractionMode == mode
                    Button {
                        SoundEffectsService.shared.play(.buttonTap)
                        FeedbackManager.shared.haptic(.selection)
                        storage.setDotToDotInteractionMode(mode)
                    } label: {
                        VStack(spacing: 5) {
                            Label(mode.title, systemImage: mode.icon)
                                .font(AppTypography.buttonMedium)
                            Text(mode.shortInstruction)
                                .font(AppTypography.caption)
                                .multilineTextAlignment(.center)
                                .lineLimit(usesAccessibilityLayout ? nil : 2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(selected ? AppTheme.backgroundDark : AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(selected ? Color(hex: "5eead4") : AppTheme.backgroundMid.opacity(0.88))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(hex: "5eead4").opacity(0.52), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("dot-mode-\(mode.rawValue)")
                }
    }

    private var puzzleGallery: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Group {
                if usesAccessibilityLayout {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        galleryCopy
                        rangeBadge
                    }
                } else {
                    HStack {
                        galleryCopy
                        Spacer()
                        rangeBadge
                    }
                }
            }

            LazyVGrid(
                columns: [GridItem(
                    .adaptive(
                        minimum: usesAccessibilityLayout ? 240 : 145,
                        maximum: usesAccessibilityLayout ? 520 : 210
                    ),
                    spacing: AppSpacing.md
                )],
                spacing: AppSpacing.md
            ) {
                ForEach(puzzles) { puzzle in
                    puzzleCard(puzzle)
                }
            }
        }
    }

    private var galleryCopy: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Picture gallery")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(puzzles.count) pictures in this number range")
                .font(AppTypography.caption)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var rangeBadge: some View {
        Text(selectedTier.rangeLabel)
            .font(AppTypography.buttonSmall)
            .foregroundColor(selectedTier.color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(selectedTier.color.opacity(0.13)))
    }

    private func puzzleCard(_ puzzle: DotPuzzle) -> some View {
        let completed = completedPuzzleIDs.contains(puzzle.id)

        return Button {
            SoundEffectsService.shared.play(.cardTap)
            FeedbackManager.shared.haptic(.medium)
            selectedPuzzle = puzzle
        } label: {
            VStack(spacing: AppSpacing.sm) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    puzzle.palette.primary.opacity(0.26),
                                    puzzle.palette.secondary.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 112)

                    DotPuzzleThumbnail(puzzle: puzzle)
                        .padding(12)

                    if completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "5eead4"))
                            .background(Circle().fill(AppTheme.backgroundDark))
                            .padding(8)
                    }
                }

                Text(puzzle.title)
                    .font(AppTypography.buttonMedium)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(usesAccessibilityLayout ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(puzzle.points.count) numbers")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.backgroundMid.opacity(0.86))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        completed
                            ? Color(hex: "5eead4").opacity(0.55)
                            : Color.white.opacity(0.13),
                        lineWidth: completed ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(puzzle.title), \(puzzle.points.count) numbers\(completed ? ", completed" : "")")
        .accessibilityHint("Opens this dot-to-dot picture")
        .accessibilityIdentifier("dot-puzzle-\(puzzle.id)")
    }
}

private struct DotPuzzleThumbnail: View {
    let puzzle: DotPuzzle

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                dotArtworkPath(
                    puzzle.revealOutline,
                    in: geometry.size,
                    inset: 4,
                    closes: true,
                    smooth: puzzle.referenceArt != nil
                )
                .fill(
                    LinearGradient(
                        colors: [puzzle.palette.primary, puzzle.palette.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: puzzle.palette.primary.opacity(0.34), radius: 8, y: 4)

                dotArtworkPath(
                    puzzle.revealOutline,
                    in: geometry.size,
                    inset: 4,
                    closes: true,
                    smooth: puzzle.referenceArt != nil
                )
                .stroke(
                    Color.white.opacity(0.82),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )

                ForEach(Array((puzzle.guidePaths + puzzle.detailPaths).enumerated()), id: \.offset) { _, line in
                    dotArtworkPath(line, in: geometry.size, inset: 4, closes: false, smooth: false)
                        .stroke(
                            Color.white.opacity(0.84),
                            style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                        )
                }

                if let art = puzzle.referenceArt {
                    DotPuzzleReferenceArtworkView(art: art, inset: 4, tint: .white)
                        .shadow(color: Color.black.opacity(0.34), radius: 1, y: 1)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private enum SemanticColouringDismissAction {
    case showCompletion
    case exitToGallery
}

struct DotToDotPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var musicService: MusicService
    @ObservedObject private var storage = StorageService.shared

    let puzzle: DotPuzzle
    let interactionMode: DotInteractionMode
    let onExit: (() -> Void)?
    private let requestedInitialProgress: Int

    @State private var currentIndex = 0
    @State private var progressSession: DotToDotProgressStore.Session?
    @State private var hasLoadedConnectionProgress = false
    @State private var showsRestartConfirmation = false
    @State private var isRestarting = false
    @State private var showsHint = false
    @State private var statusMessage: String?
    @State private var wrongRealIndex: Int?
    @State private var completionPresented = false
    @State private var subitizingSolved = false
    @State private var wrongSubitizingChoice: Int?
    @State private var coloredRegions: Set<Int> = []
    @State private var colouringSnapshot: DotColouringSnapshot = .empty
    @State private var hasLoadedColouringSnapshot = false
    @State private var colouringSessionToken: UUID?
    @State private var colouringSnapshotRevision = 0
    @State private var showsSemanticColouring = false
    @State private var semanticColouringDismissAction: SemanticColouringDismissAction?
    @State private var wrongSubitizingClearTask: Task<Void, Never>?
    @State private var writingBreakNumeral: Int?
    @State private var showsWritingBreak = false
    @State private var requiredAudioToken: UUID?
    @State private var initialPromptTask: Task<Void, Never>?
    @State private var wrongRealClearTask: Task<Void, Never>?
    @State private var completionTransitionTask: Task<Void, Never>?
    @State private var isExiting = false

    private let progressStore = DotToDotProgressStore.shared
    private let colouringSnapshotStore = DotColouringSnapshotStore.shared
    private let persistenceQueue = DotToDotPersistenceQueue.shared

    init(
        puzzle: DotPuzzle,
        interactionMode: DotInteractionMode,
        initialProgress: Int = 0,
        showsCompletionInitially: Bool = false,
        showsSemanticColouringInitially: Bool = false,
        onExit: (() -> Void)? = nil
    ) {
        self.puzzle = puzzle
        self.interactionMode = interactionMode
        self.onExit = onExit
        requestedInitialProgress = min(max(initialProgress, 0), puzzle.points.count)
        _currentIndex = State(
            initialValue: requestedInitialProgress
        )
        _completionPresented = State(initialValue: showsCompletionInitially)
        _showsSemanticColouring = State(initialValue: showsSemanticColouringInitially)
    }

    private var isComplete: Bool { currentIndex >= puzzle.points.count }
    private var expectedNumeral: Int { min(currentIndex + 1, puzzle.points.count) }
    private var semanticColourPlan: DotSemanticColourPlan? {
        guard let sourceSheet = puzzle.sourceSheet,
              let referenceArt = puzzle.referenceArt else { return nil }
        let slot = referenceArt.row * referenceArt.columns + referenceArt.column + 1
        return DownloadedDotPuzzleColourArtwork.plan(sheet: sourceSheet, slot: slot)
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                AppTheme.backgroundDark
                    .ignoresSafeArea()
                    .accessibilityElement()
                    .accessibilityLabel("Dot-to-dot game")
                    .accessibilityIdentifier("dot-to-dot-game")
                StarryBackground(starCount: 26, animateStars: !reduceMotion)

                VStack(spacing: isLandscape ? AppSpacing.sm : AppSpacing.md) {
                    gameHeader

                    if isLandscape {
                        HStack(spacing: AppSpacing.md) {
                            VStack(spacing: AppSpacing.md) {
                                promptCard(compact: false)
                                controls
                            }
                            .frame(width: min(270, geometry.size.width * 0.32))

                            board
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        promptCard(compact: true)
                        board
                            .aspectRatio(0.82, contentMode: .fit)
                            .frame(maxWidth: 520, maxHeight: geometry.size.height * 0.62)
                        controls
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.md)

                if completionPresented {
                    completionOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .onAppear {
            coloredRegions = storage.coloredDotToDotRegions(for: puzzle.id)
            if requiredAudioToken == nil {
                requiredAudioToken = musicService.beginRequiredAudioSession()
            }
        }
        .onDisappear {
            persistConnectionProgress()
            initialPromptTask?.cancel()
            wrongRealClearTask?.cancel()
            completionTransitionTask?.cancel()
            wrongSubitizingClearTask?.cancel()
            NumeralSpeechService.shared.stop()
            // A full-screen child activity is still part of this spoken-audio game. Keep the
            // suppression token alive so hub music cannot start over colouring or handwriting.
            guard !showsWritingBreak, !showsSemanticColouring else { return }
            if let requiredAudioToken {
                musicService.endRequiredAudioSession(requiredAudioToken)
                self.requiredAudioToken = nil
            }
        }
        .onChange(of: scenePhase) { phase in
            guard phase != .active else { return }
            persistConnectionProgress()
        }
        .fullScreenCover(isPresented: $showsWritingBreak, onDismiss: {
            writingBreakNumeral = nil
            exitGame()
        }) {
            if let writingBreakNumeral,
               let glyph = LetterLibrary.glyph(for: "\(writingBreakNumeral)") {
                CometWriterGameView(startingGlyph: glyph)
            }
        }
        .fullScreenCover(
            isPresented: $showsSemanticColouring,
            onDismiss: handleSemanticColouringDismiss
        ) {
            if let semanticColourPlan, hasLoadedColouringSnapshot {
                DotToDotColouringStage(
                    puzzle: puzzle,
                    plan: semanticColourPlan,
                    initialCompletedRegions: coloredRegions,
                    initialSnapshot: colouringSnapshot,
                    onRegionCompleted: { region in
                        coloredRegions.insert(region)
                        storage.colorDotToDotRegion(region, for: puzzle.id)
                    },
                    onSnapshotChanged: { snapshot in
                        persistColouringSnapshot(snapshot)
                    },
                    onReset: {
                        coloredRegions = []
                        storage.resetDotToDotColoring(for: puzzle.id)
                    },
                    onDone: finishSemanticColouring,
                    onClose: leaveSemanticColouring
                )
            } else {
                ZStack {
                    AppTheme.backgroundDark.ignoresSafeArea()
                    ProgressView("Preparing colours…")
                        .tint(AppTheme.cometCyan)
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        .alert("Start this picture again?", isPresented: $showsRestartConfirmation) {
            Button("Keep going", role: .cancel) {}
            Button("Start again", role: .destructive, action: performRestart)
        } message: {
            Text("Your joined dots will start again from number 1.")
        }
        .task {
            await restoreConnectionProgress()
            await loadColouringSnapshot()
        }
        .task(
            id: DotToDotAutomaticHintTaskID(
                hasLoadedConnectionProgress: hasLoadedConnectionProgress,
                currentIndex: currentIndex
            )
        ) {
            guard hasLoadedConnectionProgress, !isComplete else { return }
            let nanoseconds = UInt64(puzzle.tier.automaticHintDelay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled, !isComplete else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                showsHint = true
            }
        }
    }

    private var gameHeader: some View {
        HStack(spacing: AppSpacing.md) {
            PremiumIconButton(
                icon: "xmark",
                action: exitGame,
                size: 46,
                accessibilityLabelText: "Back to picture gallery"
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(puzzle.title)
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Text("\(interactionMode.title) • \(puzzle.points.count) numbers")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: isComplete ? "checkmark" : "point.3.connected.trianglepath.dotted")
                Text(isComplete ? "Done" : "\(currentIndex)/\(puzzle.points.count)")
            }
            .font(AppTypography.buttonSmall)
            .foregroundColor(puzzle.tier.color)
            .padding(.horizontal, 12)
            .frame(minHeight: 42)
            .background(Capsule().fill(AppTheme.backgroundMid.opacity(0.90)))
            .accessibilityLabel(isComplete ? "Picture complete" : "\(currentIndex) of \(puzzle.points.count) dots found")
        }
    }

    private func promptCard(compact: Bool) -> some View {
        Group {
            if compact {
                HStack(spacing: AppSpacing.md) {
                    targetNumeral
                    promptCopy
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: AppSpacing.md) {
                    targetNumeral
                    promptCopy
                }
            }
        }
        .padding(compact ? 12 : AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.backgroundMid.opacity(0.90))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(puzzle.tier.color.opacity(0.38), lineWidth: 1)
        )
    }

    private var targetNumeral: some View {
        ZStack {
            Circle()
                .fill(puzzle.tier.color)
                .frame(width: 68, height: 68)
                .shadow(color: puzzle.tier.color.opacity(0.4), radius: 12)

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .black))
                    .foregroundColor(AppTheme.backgroundDark)
            } else {
                Text("\(expectedNumeral)")
                    .font(.system(size: expectedNumeral >= 10 ? 30 : 36, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.backgroundDark)
            }
        }
        .accessibilityHidden(true)
    }

    private var promptCopy: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(isComplete ? "Picture revealed!" : promptTitle)
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)

            Text(statusMessage ?? (isComplete
                ? "You followed the whole trail."
                : defaultPromptMessage))
                .font(AppTypography.bodySmall)
                .foregroundColor(statusMessage == nil ? AppTheme.textSecondary : puzzle.tier.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .combine)
    }

    private var board: some View {
        DotToDotBoard(
            puzzle: puzzle,
            interactionMode: interactionMode,
            currentIndex: currentIndex,
            showsHint: showsHint,
            wrongRealIndex: wrongRealIndex,
            onRealDotTap: handleRealDot,
            onTraceMiss: handleTraceMiss
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(hasLoadedConnectionProgress && !isRestarting)
        .overlay {
            if !hasLoadedConnectionProgress || isRestarting {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(AppTheme.backgroundDark.opacity(0.64))
                    ProgressView(isRestarting ? "Starting again…" : "Finding your place…")
                        .tint(puzzle.tier.color)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("dot-to-dot-progress-loading")
            }
        }
    }

    private var controls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.sm) {
                controlButton("Hear", icon: "speaker.wave.2.fill") {
                    NumeralSpeechService.shared.speakPrompt(expectedNumeral)
                }
                controlButton("Hint", icon: "lightbulb.fill") {
                    withAnimation(.easeInOut(duration: 0.2)) { showsHint = true }
                    NumeralSpeechService.shared.speakPrompt(expectedNumeral)
                }
                controlButton("Restart", icon: "arrow.counterclockwise") {
                    requestRestart()
                }
            }

            VStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    controlButton("Hear", icon: "speaker.wave.2.fill") {
                        NumeralSpeechService.shared.speakPrompt(expectedNumeral)
                    }
                    controlButton("Hint", icon: "lightbulb.fill") {
                        withAnimation(.easeInOut(duration: 0.2)) { showsHint = true }
                    }
                }
                controlButton("Restart", icon: "arrow.counterclockwise") {
                    requestRestart()
                }
            }
        }
        .disabled(!hasLoadedConnectionProgress || isRestarting)
    }

    private func controlButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            SoundEffectsService.shared.play(.buttonTap)
            FeedbackManager.shared.haptic(.light)
            action()
        } label: {
            Label(title, systemImage: icon)
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 13)
                .frame(minHeight: 44)
                .background(Capsule().fill(AppTheme.backgroundMid.opacity(0.92)))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func handleRealDot(_ index: Int) {
        guard hasLoadedConnectionProgress, !isRestarting, !isComplete else { return }

        if index == currentIndex {
            let foundNumeral = index + 1
            SoundEffectsService.shared.play(.correctMove)
            FeedbackManager.shared.haptic(.correctMove)
            NumeralSpeechService.shared.speakNumber(foundNumeral)

            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                currentIndex += 1
                showsHint = false
                statusMessage = nil
                wrongRealIndex = nil
            }
            persistConnectionProgress()

            if currentIndex >= puzzle.points.count {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "All \(puzzle.points.count) numbers found. Picture revealed."
                )
                completePuzzle()
            } else {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Correct. Find number \(expectedNumeral)."
                )
            }
            return
        }

        let tappedNumeral = index + 1
        if index < currentIndex {
            statusMessage = "You already found \(tappedNumeral). Find \(expectedNumeral)."
        } else {
            statusMessage = "That says \(tappedNumeral). Find \(expectedNumeral)."
        }
        wrongRealIndex = index
        UIAccessibility.post(notification: .announcement, argument: statusMessage)
        registerGentleMistake()
    }

    private func registerGentleMistake() {
        SoundEffectsService.shared.play(.wrongMove)
        FeedbackManager.shared.haptic(.wrongMove)
        NumeralSpeechService.shared.speakPrompt(expectedNumeral)

        wrongRealClearTask?.cancel()
        let capturedReal = wrongRealIndex
        wrongRealClearTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled else { return }
            if wrongRealIndex == capturedReal { wrongRealIndex = nil }
        }
    }

    private func completePuzzle() {
        SoundEffectsService.shared.play(.levelComplete)
        FeedbackManager.shared.haptic(.levelComplete)
        NumeralSpeechService.shared.speakCelebration(puzzle.title)

        // Let the child see the joined trail dissolve into the finished picture before the
        // next activity takes over. The colouring stage then follows automatically.
        completionTransitionTask?.cancel()
        completionTransitionTask = Task { @MainActor in
            let delay: UInt64 = reduceMotion ? 350_000_000 : 2_000_000_000
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled, isComplete else { return }
            if semanticColourPlan != nil {
                await loadColouringSnapshot()
                showsSemanticColouring = true
            } else {
                recordFinishedPicture()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    completionPresented = true
                }
            }
        }
    }

    private func requestRestart() {
        guard DotToDotRestartPolicy.requiresConfirmation(currentIndex: currentIndex) else {
            performRestart()
            return
        }
        showsRestartConfirmation = true
    }

    @MainActor
    private func performRestart() {
        guard !isRestarting else { return }
        isRestarting = true
        let previousToken = progressSession?.token
        let profileID = storage.activeProfileID
        Task { @MainActor in
            let session = await progressStore.restart(
                puzzleID: puzzle.id,
                profileID: profileID,
                interactionMode: interactionMode,
                sessionToken: previousToken
            )
            guard let session else {
                isRestarting = false
                statusMessage = "Please reopen this picture to start again."
                return
            }
            progressSession = session
            withAnimation(.easeInOut(duration: 0.25)) {
                currentIndex = 0
                showsHint = false
                statusMessage = nil
                wrongRealIndex = nil
                completionPresented = false
                subitizingSolved = false
                wrongSubitizingChoice = nil
                coloredRegions = storage.coloredDotToDotRegions(for: puzzle.id)
                showsSemanticColouring = false
                writingBreakNumeral = nil
            }
            isRestarting = false
            NumeralSpeechService.shared.speakPrompt(1)
        }
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.66).ignoresSafeArea()
            ConfettiView(intensity: .normal)

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    DotPuzzleThumbnail(puzzle: puzzle)
                        .frame(width: 126, height: 126)

                    VStack(spacing: 5) {
                        Text("You revealed a \(puzzle.title.lowercased())!")
                            .font(AppTypography.displayMedium)
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.75)

                        Text("All \(puzzle.points.count) numbers found—and you brought the picture to life with colour!")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AppSpacing.md) {
                            completionPrimaryButton
                            completionSecondaryButton
                        }

                        VStack(spacing: AppSpacing.sm) {
                            completionPrimaryButton
                            completionSecondaryButton
                        }
                    }

                    SubitizingBonusView(
                        quantity: SubitizingChallenge.quantity(for: puzzle.id),
                        choices: SubitizingChallenge.choices(
                            for: SubitizingChallenge.quantity(for: puzzle.id),
                            puzzleID: puzzle.id
                        ),
                        isSolved: subitizingSolved,
                        wrongChoice: wrongSubitizingChoice,
                        onChoice: handleSubitizingChoice
                    )

                    if let writingBreakNumeral {
                        VStack(spacing: AppSpacing.md) {
                            HStack(spacing: AppSpacing.md) {
                                Image(systemName: "pencil.and.outline")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(AppTheme.cometCyan)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Comet Writer pit stop")
                                        .font(AppTypography.buttonLarge)
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("You can also practise drawing number \(writingBreakNumeral).")
                                        .font(AppTypography.bodySmall)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer(minLength: 0)
                            }
                            SecondaryButton("Practise number \(writingBreakNumeral)", icon: "pencil.and.outline") {
                                showsWritingBreak = true
                            }
                        }
                        .padding(AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.cometPurple.opacity(0.16))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.cometCyan.opacity(0.42), lineWidth: 1)
                        )
                    }

                }
                .padding(AppSpacing.xl)
                .frame(maxWidth: 580)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(AppTheme.backgroundDark.opacity(0.97))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(puzzle.palette.primary.opacity(0.65), lineWidth: 2)
                )
                .shadow(color: puzzle.palette.primary.opacity(0.28), radius: 30)
                .padding(AppSpacing.md)
            }
            .scrollIndicators(.hidden)
        }
        .accessibilityIdentifier("dot-to-dot-complete")
    }

    private var promptTitle: String {
        if interactionMode == .trace, currentIndex > 0 {
            return "Trace to number \(expectedNumeral)"
        }
        return "Find number \(expectedNumeral)"
    }

    private var defaultPromptMessage: String {
        if interactionMode == .trace {
            return currentIndex == 0
                ? "Press number 1 to start the trail."
                : "Draw from \(currentIndex) to \(expectedNumeral). Scan the whole picture if you need to."
        }
        return "Scan the whole picture and press the matching number."
    }

    private func handleTraceMiss() {
        guard interactionMode == .trace, !isComplete else { return }
        if currentIndex == 0 {
            statusMessage = "Press number 1 to begin."
        } else {
            statusMessage = "Start at \(currentIndex), then draw to \(expectedNumeral)."
        }
        registerGentleMistake()
    }

    private var completionPrimaryButton: some View {
        PrimaryButton("More pictures", icon: "square.grid.2x2.fill") {
            exitGame()
        }
    }

    private var completionSecondaryButton: some View {
        SecondaryButton("Play again", icon: "arrow.counterclockwise") {
            playAgain()
        }
    }

    private func handleSubitizingChoice(_ choice: Int) {
        let answer = SubitizingChallenge.quantity(for: puzzle.id)
        if choice == answer {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                subitizingSolved = true
                wrongSubitizingChoice = nil
            }
            SoundEffectsService.shared.play(.starReveal)
            FeedbackManager.shared.haptic(.correctMove)
            NumeralSpeechService.shared.speakStarCount(answer)
            UIAccessibility.post(
                notification: .announcement,
                argument: "Correct. There are \(answer) stars."
            )
        } else {
            wrongSubitizingChoice = choice
            SoundEffectsService.shared.play(.wrongMove)
            FeedbackManager.shared.haptic(.light)
            UIAccessibility.post(
                notification: .announcement,
                argument: "Not \(choice). Count the stars and try again."
            )
            wrongSubitizingClearTask?.cancel()
            wrongSubitizingClearTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 550_000_000)
                guard !Task.isCancelled else { return }
                if wrongSubitizingChoice == choice {
                    wrongSubitizingChoice = nil
                }
            }
        }
    }

    private func finishSemanticColouring() {
        recordFinishedPicture()
        semanticColouringDismissAction = .showCompletion
        showsSemanticColouring = false
    }

    private func recordFinishedPicture() {
        let isNewPicture = storage.markDotToDotPuzzleCompleted(puzzle.id)
        let completedPictureCount = DotPuzzleCatalog
            .sanitizedCompletedIDs(storage.dotToDotCompletedPuzzles)
            .count
        if isNewPicture, completedPictureCount.isMultiple(of: 4) {
            let numerals = Array(1...9)
            let milestone = completedPictureCount / 4
            writingBreakNumeral = numerals[(milestone - 1) % numerals.count]
        }
    }

    private func handleSemanticColouringDismiss() {
        let action = semanticColouringDismissAction
        semanticColouringDismissAction = nil
        switch action {
        case .showCompletion:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                completionPresented = true
            }
        case .exitToGallery:
            exitGame()
        case nil:
            break
        }
    }

    private func leaveSemanticColouring() {
        semanticColouringDismissAction = .exitToGallery
        showsSemanticColouring = false
    }

    @MainActor
    private func restoreConnectionProgress() async {
        let profileID = storage.activeProfileID
        let resource = DotToDotPersistenceQueue.Resource.connection(
            puzzleID: puzzle.id,
            profileID: profileID,
            interactionMode: interactionMode
        )
        await persistenceQueue.drain(resource)
        guard !Task.isCancelled else { return }
        let session = await progressStore.beginSession(
            puzzleID: puzzle.id,
            profileID: profileID,
            interactionMode: interactionMode,
            pointCount: puzzle.points.count
        )
        guard !Task.isCancelled else { return }
        progressSession = session
        let restoredIndex = max(requestedInitialProgress, session.currentIndex)
        currentIndex = min(restoredIndex, puzzle.points.count)
        hasLoadedConnectionProgress = true

        if session.recoveredFromCorruptData {
            statusMessage = "We started a fresh trail safely."
        } else if session.currentIndex > 0 {
            statusMessage = "Welcome back! Carry on with number \(expectedNumeral)."
            UIAccessibility.post(
                notification: .announcement,
                argument: "Welcome back. Continue with number \(expectedNumeral)."
            )
        }

        if isComplete {
            _ = await progressStore.clear(
                puzzleID: puzzle.id,
                profileID: profileID,
                interactionMode: interactionMode,
                sessionToken: session.token
            )
        } else if requestedInitialProgress > session.currentIndex {
            _ = await progressStore.save(
                currentIndex: currentIndex,
                puzzleID: puzzle.id,
                profileID: profileID,
                interactionMode: interactionMode,
                pointCount: puzzle.points.count,
                sessionToken: session.token
            )
        }
        scheduleInitialPrompt()
    }

    @MainActor
    private func scheduleInitialPrompt() {
        guard !isComplete else { return }
        initialPromptTask?.cancel()
        initialPromptTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled, hasLoadedConnectionProgress, !isComplete else { return }
            NumeralSpeechService.shared.speakPrompt(expectedNumeral)
        }
    }

    @MainActor
    @discardableResult
    private func persistConnectionProgress() -> DotToDotPersistenceQueue.Resource {
        let profileID = storage.activeProfileID
        let resource = DotToDotPersistenceQueue.Resource.connection(
            puzzleID: puzzle.id,
            profileID: profileID,
            interactionMode: interactionMode
        )
        guard let token = progressSession?.token else { return resource }
        let index = currentIndex
        guard index > 0 else { return resource }
        persistenceQueue.enqueue(for: resource) {
            if index >= puzzle.points.count {
                _ = await progressStore.clear(
                    puzzleID: puzzle.id,
                    profileID: profileID,
                    interactionMode: interactionMode,
                    sessionToken: token
                )
            } else {
                _ = await progressStore.save(
                    currentIndex: index,
                    puzzleID: puzzle.id,
                    profileID: profileID,
                    interactionMode: interactionMode,
                    pointCount: puzzle.points.count,
                    sessionToken: token
                )
            }
        }
        return resource
    }

    @MainActor
    private func flushConnectionProgress() async {
        let resource = persistConnectionProgress()
        await persistenceQueue.drain(resource)
    }

    @MainActor
    private func loadColouringSnapshot() async {
        guard !hasLoadedColouringSnapshot else { return }
        let profileID = storage.activeProfileID
        let resource = DotToDotPersistenceQueue.Resource.colouring(
            puzzleID: puzzle.id,
            profileID: profileID
        )
        await persistenceQueue.drain(resource)
        guard !Task.isCancelled else { return }
        let session = await colouringSnapshotStore.beginSession(
            puzzleID: puzzle.id,
            profileID: profileID
        )
        guard !Task.isCancelled else { return }
        colouringSnapshot = session.snapshot
        colouringSessionToken = session.token
        colouringSnapshotRevision = session.revision
        hasLoadedColouringSnapshot = true
    }

    @MainActor
    private func persistColouringSnapshot(_ snapshot: DotColouringSnapshot) -> Task<Void, Never> {
        colouringSnapshot = snapshot
        guard let token = colouringSessionToken else { return Task {} }
        colouringSnapshotRevision += 1
        let revision = colouringSnapshotRevision
        let profileID = storage.activeProfileID
        let resource = DotToDotPersistenceQueue.Resource.colouring(
            puzzleID: puzzle.id,
            profileID: profileID
        )
        return persistenceQueue.enqueue(for: resource) {
            _ = await colouringSnapshotStore.save(
                snapshot,
                puzzleID: puzzle.id,
                profileID: profileID,
                sessionToken: token,
                revision: revision
            )
        }
    }

    @MainActor
    @discardableResult
    private func resetColouringSnapshot() -> Task<Void, Never> {
        colouringSnapshot = .empty
        guard let token = colouringSessionToken else { return Task {} }
        colouringSnapshotRevision += 1
        let revision = colouringSnapshotRevision
        let profileID = storage.activeProfileID
        let resource = DotToDotPersistenceQueue.Resource.colouring(
            puzzleID: puzzle.id,
            profileID: profileID
        )
        return persistenceQueue.enqueue(for: resource) {
            _ = await colouringSnapshotStore.reset(
                puzzleID: puzzle.id,
                profileID: profileID,
                sessionToken: token,
                revision: revision
            )
        }
    }

    private func playAgain() {
        storage.resetDotToDotColoring(for: puzzle.id)
        coloredRegions = []
        resetColouringSnapshot()
        performRestart()
    }

    @MainActor
    private func exitGame() {
        guard !isExiting else { return }
        isExiting = true
        Task { @MainActor in
            // Do not dismiss until the final index has reached the actor-backed store. The await
            // suspends this task rather than the UI, and the next presentation drains the same
            // resource before rotating its session token.
            await flushConnectionProgress()
            if let onExit {
                onExit()
            } else {
                dismiss()
            }
        }
    }
}

private struct DotToDotBoard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let puzzle: DotPuzzle
    let interactionMode: DotInteractionMode
    let currentIndex: Int
    let showsHint: Bool
    let wrongRealIndex: Int?
    let onRealDotTap: (Int) -> Void
    let onTraceMiss: () -> Void

    @State private var hintPulse = false
    @State private var traceStart: CGPoint?
    @State private var traceCurrent: CGPoint?
    @State private var traceStartedCorrectly = false
    @State private var revealProgress: CGFloat = 0

    private var isComplete: Bool { currentIndex >= puzzle.points.count }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "101a35"), Color(hex: "071020")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                boardArtwork(in: geometry.size)

                if isComplete, let art = puzzle.referenceArt {
                    DotPuzzleReferenceArtworkView(art: art, inset: 24, tint: .white)
                        .opacity(0.96 * revealProgress)
                        .scaleEffect(0.94 + revealProgress * 0.06)
                        .shadow(
                            color: puzzle.palette.primary.opacity(0.45 * revealProgress),
                            radius: 5 * revealProgress
                        )
                }

                liveTrace

                if !isComplete {
                    realDots(in: geometry.size)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [puzzle.palette.primary.opacity(0.7), Color.white.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: puzzle.palette.primary.opacity(0.20), radius: 22, y: 8)
            .dotTraceGesture(
                traceGesture(in: geometry.size),
                isEnabled: interactionMode == .trace && currentIndex > 0 && !isComplete
            )
        }
        .onAppear {
            revealProgress = isComplete ? 1 : 0
            updateHintPulse()
        }
        .onChange(of: showsHint) { _ in
            updateHintPulse()
        }
        .onChange(of: reduceMotion) { _ in
            updateHintPulse()
        }
        .onChange(of: isComplete) { completed in
            updateHintPulse()
            guard completed else {
                revealProgress = 0
                return
            }
            guard !reduceMotion else {
                revealProgress = 1
                return
            }
            revealProgress = 0
            withAnimation(.easeInOut(duration: 0.85)) {
                revealProgress = 1
            }
        }
        .onDisappear {
            withAnimation(nil) {
                hintPulse = false
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(puzzle.title) dot-to-dot board")
    }

    private func updateHintPulse() {
        withAnimation(nil) {
            hintPulse = false
        }
        guard showsHint, !reduceMotion, !isComplete else { return }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            hintPulse = true
        }
    }

    private func boardArtwork(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            for index in 0..<18 {
                let x = CGFloat((index * 67 + 29) % 101) / 101 * canvasSize.width
                let y = CGFloat((index * 43 + 17) % 97) / 97 * canvasSize.height
                let rect = CGRect(x: x, y: y, width: 2, height: 2)
                context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.13)))
            }

            for guide in puzzle.guidePaths {
                context.stroke(
                    path(for: guide, in: canvasSize, closes: false),
                    with: .color(Color.white.opacity(isComplete ? 0.78 : 0.34)),
                    style: StrokeStyle(lineWidth: isComplete ? 3 : 2, lineCap: .round, lineJoin: .round)
                )
            }

            if isComplete {
                let reveal = dotArtworkPath(
                    puzzle.revealOutline,
                    in: canvasSize,
                    inset: 24,
                    closes: true,
                    smooth: puzzle.referenceArt != nil
                )
                context.fill(
                    reveal,
                    with: .linearGradient(
                        Gradient(colors: [
                            puzzle.palette.primary.opacity(0.82 * revealProgress),
                            puzzle.palette.secondary.opacity(0.72 * revealProgress)
                        ]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)
                    )
                )
                context.stroke(
                    reveal,
                    with: .color(Color.white.opacity(0.88 * revealProgress)),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
                for detail in puzzle.detailPaths {
                    context.stroke(
                        path(for: detail, in: canvasSize, closes: false),
                        with: .color(Color.white.opacity(0.92 * revealProgress)),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                }

                let joinedTrail = path(for: puzzle.points, in: canvasSize, closes: true)
                context.stroke(
                    joinedTrail,
                    with: .color(puzzle.palette.primary.opacity(0.30 * (1 - revealProgress))),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                )
                context.stroke(
                    joinedTrail,
                    with: .color(Color.white.opacity(1 - revealProgress)),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
            } else if currentIndex > 0 {
                let selected = Array(puzzle.points.prefix(currentIndex))
                let connected = path(for: selected, in: canvasSize, closes: false)
                context.stroke(
                    connected,
                    with: .color(puzzle.palette.primary.opacity(0.28)),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                )
                context.stroke(
                    connected,
                    with: .linearGradient(
                        Gradient(colors: [Color.white, puzzle.palette.primary]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func realDots(in size: CGSize) -> some View {
        ForEach(Array(puzzle.points.enumerated()), id: \.offset) { index, normalized in
            Button {
                if interactionMode == .tap || currentIndex == 0 || UIAccessibility.isVoiceOverRunning {
                    onRealDotTap(index)
                } else {
                    onTraceMiss()
                }
            } label: {
                DotNumberView(
                    numeral: index + 1,
                    isSelected: index < currentIndex,
                    showsHint: index == currentIndex && showsHint,
                    isWrong: wrongRealIndex == index,
                    tint: puzzle.palette.primary,
                    hintPulse: hintPulse,
                    dense: puzzle.points.count >= 20
                )
            }
            .buttonStyle(.plain)
            .position(boardPoint(normalized, in: size))
            .accessibilityLabel("Number \(index + 1)")
            .accessibilityHint(index == currentIndex ? "This is the number to find" : "Choose only when this number is requested")
            .accessibilitySortPriority(index == currentIndex ? 10 : 1)
            .accessibilityIdentifier("dot-real-\(index + 1)")
        }
    }

    @ViewBuilder
    private var liveTrace: some View {
        if let traceStart, let traceCurrent, traceStartedCorrectly {
            Path { path in
                path.move(to: traceStart)
                path.addLine(to: traceCurrent)
            }
            .stroke(
                puzzle.palette.primary,
                style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: puzzle.palette.primary.opacity(0.55), radius: 7)
            .allowsHitTesting(false)
        }
    }

    private func traceGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .local)
            .onChanged { value in
                guard interactionMode == .trace,
                      currentIndex > 0,
                      currentIndex < puzzle.points.count else { return }

                if traceStart == nil {
                    traceStart = value.startLocation
                    let previous = boardPoint(puzzle.points[currentIndex - 1], in: size)
                    traceStartedCorrectly = distance(value.startLocation, previous) <= 34
                }
                traceCurrent = value.location
            }
            .onEnded { value in
                defer {
                    traceStart = nil
                    traceCurrent = nil
                    traceStartedCorrectly = false
                }

                guard interactionMode == .trace,
                      currentIndex > 0,
                      currentIndex < puzzle.points.count,
                      traceStartedCorrectly else {
                    onTraceMiss()
                    return
                }

                let target = boardPoint(puzzle.points[currentIndex], in: size)
                if distance(value.location, target) <= 40 {
                    onRealDotTap(currentIndex)
                } else {
                    onTraceMiss()
                }
            }
    }

    private func path(for normalizedPoints: [CGPoint], in size: CGSize, closes: Bool) -> Path {
        Path { path in
            guard let first = normalizedPoints.first else { return }
            path.move(to: boardPoint(first, in: size))
            for point in normalizedPoints.dropFirst() {
                path.addLine(to: boardPoint(point, in: size))
            }
            if closes { path.closeSubpath() }
        }
    }

    private func boardPoint(_ normalized: CGPoint, in size: CGSize) -> CGPoint {
        fittedDotBoardPoint(normalized, in: size, inset: 24)
    }

    private func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}

private extension View {
    /// On iOS 16 an attached gesture with a `.none` mask can still prevent nested buttons from
    /// receiving taps. Leave the drag recognizer out of the hierarchy entirely until tracing is
    /// active so Press mode behaves consistently on every supported iPad and iPhone.
    @ViewBuilder
    func dotTraceGesture<G: Gesture>(_ gesture: G, isEnabled: Bool) -> some View {
        if isEnabled {
            simultaneousGesture(gesture, including: .all)
        } else {
            self
        }
    }
}

private struct DotNumberView: View {
    let numeral: Int
    let isSelected: Bool
    let showsHint: Bool
    let isWrong: Bool
    let tint: Color
    let hintPulse: Bool
    let dense: Bool

    private var dotSize: CGFloat { dense ? 31 : 36 }

    var body: some View {
        ZStack {
            if showsHint {
                Circle()
                    .stroke(Color(hex: "fbbf24"), lineWidth: 4)
                    .frame(width: hintPulse ? 51 : 43, height: hintPulse ? 51 : 43)
                    .opacity(hintPulse ? 0.35 : 0.9)
            }

            Circle()
                .fill(
                    isWrong
                        ? Color(hex: "fb7185")
                        : (isSelected ? tint : Color.white)
                )
                .frame(width: dotSize, height: dotSize)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? Color.white.opacity(0.8) : tint.opacity(0.68),
                            lineWidth: isSelected ? 2 : 1.5
                        )
                )
                .shadow(
                    color: (isSelected ? tint : Color.white).opacity(0.48),
                    radius: isWrong ? 9 : 5
                )

            Text("\(numeral)")
                .font(.system(size: dense ? (numeral >= 10 ? 11 : 13) : (numeral >= 10 ? 12 : 15), weight: .black, design: .rounded))
                .foregroundColor(AppTheme.backgroundDark)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 48, height: 48)
        .contentShape(Circle())
        .scaleEffect(isWrong ? 1.13 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.55), value: isWrong)
    }
}

private struct SubitizingBonusView: View {
    let quantity: Int
    let choices: [Int]
    let isSolved: Bool
    let wrongChoice: Int?
    let onChoice: (Int) -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(hex: "fbbf24"))
                Text("Star Spot bonus")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("No timer")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            if isSolved {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(hex: "fbbf24"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You spotted \(quantity)!")
                            .font(AppTypography.buttonLarge)
                            .foregroundColor(AppTheme.textPrimary)
                        Text("That quick quantity spotting is subitising.")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Text("How many stars can you see?")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppTheme.textPrimary)

                SubitizingPatternView(quantity: quantity)
                    .frame(width: 150, height: 92)

                HStack(spacing: AppSpacing.md) {
                    ForEach(choices, id: \.self) { choice in
                        Button {
                            onChoice(choice)
                        } label: {
                            Text("\(choice)")
                                .font(AppTypography.titleMedium)
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 58, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            wrongChoice == choice
                                                ? Color(hex: "fb7185").opacity(0.72)
                                                : AppTheme.backgroundDark.opacity(0.75)
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(choice)")
                    }
                }

                Text(wrongChoice == nil ? "You can count them if you need to." : "Have another look—nothing is lost.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.backgroundMid.opacity(0.90))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(hex: "fbbf24").opacity(0.36), lineWidth: 1)
        )
    }
}

private struct SubitizingPatternView: View {
    let quantity: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.07))

                ForEach(Array(SubitizingChallenge.pattern(for: quantity).enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(Color(hex: "fbbf24"))
                        .frame(width: 22, height: 22)
                        .shadow(color: Color(hex: "fbbf24").opacity(0.45), radius: 5)
                        .position(
                            x: point.x * geometry.size.width,
                            y: point.y * geometry.size.height
                        )
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(quantity) stars")
    }
}

@MainActor
final class NumeralSpeechService {
    static let shared = NumeralSpeechService()

    private var synthesizer: AVSpeechSynthesizer?
    private let storage = StorageService.shared

    private init() {}

    func speakPrompt(_ numeral: Int) {
        speak(Self.promptText(for: numeral))
    }

    static func promptText(for number: Int) -> String {
        "Find number \(number)."
    }

    func speakNumber(_ numeral: Int) {
        speak(Self.numberText(for: numeral))
    }

    static func numberText(for number: Int) -> String {
        "\(number)"
    }

    func speakCelebration(_ picture: String) {
        speak(Self.celebrationText(for: picture))
    }

    static func celebrationText(for picture: String) -> String {
        "Well done! You found the \(picture)."
    }

    func speakStarCount(_ count: Int) {
        speak(Self.starCountText(for: count))
    }

    static func starCountText(for count: Int) -> String {
        "\(count) stars. Great spotting!"
    }

    func stop() {
        synthesizer?.stopSpeaking(at: .immediate)
    }

    private func speak(_ text: String) {
        guard storage.isVoiceEnabled else { return }
        guard !UIAccessibility.isVoiceOverRunning else { return }
        guard AppAudioSessionCoordinator.shared.activate(.spokenPlayback) else { return }

        let engine: AVSpeechSynthesizer
        if let synthesizer {
            engine = synthesizer
        } else {
            let newSynthesizer = AVSpeechSynthesizer()
            synthesizer = newSynthesizer
            engine = newSynthesizer
        }

        engine.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = 0.46
        utterance.pitchMultiplier = 1.04
        utterance.volume = min(max(storage.voiceVolume, 0), 1)
        engine.speak(utterance)
    }
}

#if DEBUG
/// Full-size visual checkpoint for approving one downloaded picture before the entire pack ships.
struct DotToDotSinglePreview: View {
    let index: Int
    @State private var currentIndex = 0
    @State private var showsColourStage = false
    @State private var transitionTask: Task<Void, Never>?

    private var puzzle: DotPuzzle {
        DotPuzzleCatalog.downloadedReferencePuzzles[index]
    }

    var body: some View {
        Group {
            if showsColourStage {
                DotToDotPlayView(
                    puzzle: puzzle,
                    interactionMode: .tap,
                    initialProgress: puzzle.points.count,
                    showsSemanticColouringInitially: true,
                    onExit: {
                        StorageService.shared.resetDotToDotColoring(for: puzzle.id)
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentIndex = 0
                            showsColourStage = false
                        }
                    }
                )
                .transition(.opacity)
            } else {
                revealPreview
                    .transition(.opacity)
            }
        }
        .onDisappear {
            transitionTask?.cancel()
            transitionTask = nil
        }
    }

    private var revealPreview: some View {
        ZStack {
            Color(hex: "050b18").ignoresSafeArea()

            VStack(spacing: 18) {
                VStack(spacing: 5) {
                    Text(puzzle.title)
                        .font(AppTypography.displayMedium)
                        .foregroundColor(.white)
                    Text("Downloaded artwork preview • \(puzzle.tier.rangeLabel)")
                        .font(AppTypography.buttonMedium)
                        .foregroundColor(puzzle.palette.primary)
                }

                DotToDotBoard(
                    puzzle: puzzle,
                    interactionMode: .tap,
                    currentIndex: currentIndex,
                    showsHint: false,
                    wrongRealIndex: nil,
                    onRealDotTap: { index in
                        guard index == currentIndex else { return }
                        currentIndex += 1
                    },
                    onTraceMiss: {}
                )
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 650)

                Button(currentIndex >= puzzle.points.count ? "Show colour by numbers" : "Preview completed reveal") {
                    if currentIndex >= puzzle.points.count {
                        StorageService.shared.resetDotToDotColoring(for: puzzle.id)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showsColourStage = true
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.65)) {
                            currentIndex = puzzle.points.count
                        }
                        transitionTask?.cancel()
                        transitionTask = Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            guard !Task.isCancelled,
                                  currentIndex >= puzzle.points.count else { return }
                            StorageService.shared.resetDotToDotColoring(for: puzzle.id)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showsColourStage = true
                            }
                            transitionTask = nil
                        }
                    }
                }
                .font(AppTypography.buttonMedium)
                .foregroundColor(AppTheme.backgroundDark)
                .padding(.horizontal, 20)
                .frame(minHeight: 48)
                .background(Capsule().fill(puzzle.palette.primary))
                .accessibilityIdentifier("dot-preview-open-colouring")
            }
            .padding(24)
        }
    }
}

/// Internal visual-QA scene: ten actual puzzle fields per page, including every sampled numeral
/// and the partial worksheet art. It is launch-argument-only and is not reachable in release builds.
struct DotToDotReviewSheet: View {
    let page: Int

    private let pageSize = 10
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    private var pageCount: Int {
        max(1, Int(ceil(Double(DotPuzzleCatalog.all.count) / Double(pageSize))))
    }

    private var puzzles: [DotPuzzle] {
        let start = min(max(page, 0) * pageSize, DotPuzzleCatalog.all.count)
        let end = min(start + pageSize, DotPuzzleCatalog.all.count)
        return start < end ? Array(DotPuzzleCatalog.all[start..<end]) : []
    }

    var body: some View {
        ZStack {
            Color(hex: "050b18").ignoresSafeArea()

            VStack(spacing: 9) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dot-to-Dot picture review")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(.white)
                        Text("Page \(min(page + 1, pageCount)) of \(pageCount) • every visible dot belongs to the trail")
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(puzzles.enumerated()), id: \.element.id) { offset, puzzle in
                        DotToDotReviewCard(
                            number: page * pageSize + offset + 1,
                            puzzle: puzzle
                        )
                    }
                }
            }
            .padding(12)
        }
        .accessibilityIdentifier("dot-to-dot-review-page-\(page)")
    }
}

private struct DotToDotReviewCard: View {
    let number: Int
    let puzzle: DotPuzzle

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                Text("\(number).")
                    .foregroundColor(AppTheme.textSecondary)
                Text(puzzle.title)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 0)
                Text(puzzle.tier.rangeLabel)
                    .foregroundColor(puzzle.tier.color)
            }
            .font(AppTypography.caption)

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(Color(hex: "101a35"))

                    silhouette(in: geometry.size)

                    ForEach(Array(puzzle.points.enumerated()), id: \.offset) { index, point in
                        reviewDot(
                            numeral: index + 1,
                            tint: Color.white,
                            in: geometry.size,
                            at: point
                        )
                    }

                }
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(puzzle.palette.primary.opacity(0.52), lineWidth: 1)
                )
            }
        }
        .padding(7)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.backgroundMid.opacity(0.78))
        )
        .frame(height: 390)
    }

    private func silhouette(in size: CGSize) -> some View {
        dotArtworkPath(
            puzzle.revealOutline,
            in: size,
            inset: 10,
            closes: true,
            smooth: puzzle.referenceArt != nil
        )
        .fill(
            LinearGradient(
                colors: [
                    puzzle.palette.primary.opacity(0.38),
                    puzzle.palette.secondary.opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            dotArtworkPath(
                puzzle.revealOutline,
                in: size,
                inset: 10,
                closes: true,
                smooth: puzzle.referenceArt != nil
            )
            .stroke(puzzle.palette.primary.opacity(0.62), lineWidth: 1.5)
        }
        .overlay {
            ForEach(Array((puzzle.guidePaths + puzzle.detailPaths).enumerated()), id: \.offset) { _, line in
                dotArtworkPath(line, in: size, inset: 10, closes: false, smooth: false)
                    .stroke(Color.white.opacity(0.70), lineWidth: 1.2)
            }
        }
        .overlay {
            if let art = puzzle.referenceArt {
                DotPuzzleReferenceArtworkView(art: art, inset: 10, tint: .white)
            }
        }
        .allowsHitTesting(false)
    }

    private func reviewDot(
        numeral: Int,
        tint: Color,
        in size: CGSize,
        at normalized: CGPoint
    ) -> some View {
        ZStack {
            Circle()
                .fill(tint)
                .frame(
                    width: puzzle.points.count >= 20 ? 18 : 20,
                    height: puzzle.points.count >= 20 ? 18 : 20
                )
                .overlay(Circle().stroke(puzzle.palette.primary, lineWidth: 1))
            Text("\(numeral)")
                .font(.system(size: numeral >= 10 ? 8 : 10, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.backgroundDark)
        }
        .position(boardPoint(normalized, in: size))
    }

    private func boardPoint(_ normalized: CGPoint, in size: CGSize) -> CGPoint {
        fittedDotBoardPoint(normalized, in: size, inset: 13)
    }
}
#endif

#Preview("Dot-to-Dot Menu") {
    DotToDotMenuView()
        .environmentObject(MusicService.shared)
}
