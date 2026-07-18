import SwiftUI
import UIKit

/// The two deliberately different ways a child can colour a completed dot-to-dot picture.
/// Tap mode is the accessible, low-friction colour-by-number activity. Shade mode records the
/// child's real finger or Apple Pencil movement instead of replacing it with an automatic fill.
enum DotColouringMode: String, CaseIterable, Identifiable {
    case tapToFill
    case shade

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tapToFill: return "Tap to colour"
        case .shade: return "Shade it yourself"
        }
    }

    var shortTitle: String {
        switch self {
        case .tapToFill: return "Tap"
        case .shade: return "Shade"
        }
    }

    var icon: String {
        switch self {
        case .tapToFill: return "hand.tap.fill"
        case .shade: return "pencil.tip.crop.circle"
        }
    }

    var instruction: String {
        switch self {
        case .tapToFill:
            return "Choose a colour pot, then tap a space with the same number."
        case .shade:
            return "Choose a pot, then colour its space with your finger or Apple Pencil."
        }
    }
}

/// One continuous, genuine input gesture in the free-shading mode. Points and width are stored in
/// the artwork's normalised 0...1 coordinate space so a rotation or a different device never
/// distorts the child's work.
struct DotColourStroke: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let regionID: Int
    let swatchID: Int
    var points: [CGPoint]
    let normalizedLineWidth: CGFloat

    init(
        id: UUID = UUID(),
        regionID: Int,
        swatchID: Int,
        points: [CGPoint],
        normalizedLineWidth: CGFloat = 0.032
    ) {
        self.id = id
        self.regionID = regionID
        self.swatchID = swatchID
        self.points = points
        self.normalizedLineWidth = normalizedLineWidth
    }
}

struct DotColouringSnapshot: Equatable, Codable, Sendable {
    var tapFilledRegionIDs: Set<Int>
    var strokes: [DotColourStroke]

    static let empty = DotColouringSnapshot(tapFilledRegionIDs: [], strokes: [])
}

actor DotColouringSnapshotStore {
    static let shared = DotColouringSnapshotStore()

    struct Session: Equatable, Sendable {
        let token: UUID
        let revision: Int
        let snapshot: DotColouringSnapshot
        let recoveredFromCorruptData: Bool
    }

    private struct Envelope: Codable {
        let token: UUID
        var revision: Int
        var snapshot: DotColouringSnapshot
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func beginSession(puzzleID: String, profileID: UUID?) -> Session {
        let storageKey = key(puzzleID: puzzleID, profileID: profileID)
        let oldStorageKey = legacyKey(
            puzzleID: puzzleID,
            profileID: profileID
        )
        let decoded = decodeSnapshot(forKey: storageKey, legacyKey: oldStorageKey)
        let token = UUID()
        let envelope = Envelope(token: token, revision: 0, snapshot: decoded.snapshot)
        persist(envelope, forKey: storageKey)
        defaults.removeObject(forKey: oldStorageKey)
        return Session(
            token: token,
            revision: 0,
            snapshot: decoded.snapshot,
            recoveredFromCorruptData: decoded.wasCorrupt
        )
    }

    /// Revisions make reset deterministic even if an earlier debounced save reaches the actor
    /// later. Writes from a dismissed/superseded colouring screen are rejected by the token.
    @discardableResult
    func save(
        _ snapshot: DotColouringSnapshot,
        puzzleID: String,
        profileID: UUID?,
        sessionToken: UUID,
        revision: Int
    ) -> Bool {
        let storageKey = key(puzzleID: puzzleID, profileID: profileID)
        guard let existing = decodeEnvelope(forKey: storageKey),
              existing.token == sessionToken,
              revision > existing.revision else { return false }
        persist(
            Envelope(token: sessionToken, revision: revision, snapshot: bounded(snapshot)),
            forKey: storageKey
        )
        return true
    }

    @discardableResult
    func reset(
        puzzleID: String,
        profileID: UUID?,
        sessionToken: UUID,
        revision: Int
    ) -> Bool {
        save(
            .empty,
            puzzleID: puzzleID,
            profileID: profileID,
            sessionToken: sessionToken,
            revision: revision
        )
    }

    private func bounded(_ snapshot: DotColouringSnapshot) -> DotColouringSnapshot {
        DotColouringSnapshot(
            tapFilledRegionIDs: snapshot.tapFilledRegionIDs,
            strokes: DotColourStrokeSampler.bounded(snapshot.strokes)
        )
    }

    private func decodeSnapshot(
        forKey storageKey: String,
        legacyKey: String
    ) -> (snapshot: DotColouringSnapshot, wasCorrupt: Bool) {
        if let data = defaults.data(forKey: storageKey) {
            guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else {
                defaults.removeObject(forKey: storageKey)
                return (.empty, true)
            }
            return (bounded(envelope.snapshot), false)
        }

        guard let legacyData = defaults.data(forKey: legacyKey) else { return (.empty, false) }
        guard let legacySnapshot = try? JSONDecoder().decode(DotColouringSnapshot.self, from: legacyData) else {
            defaults.removeObject(forKey: legacyKey)
            return (.empty, true)
        }
        return (bounded(legacySnapshot), false)
    }

    private func decodeEnvelope(forKey storageKey: String) -> Envelope? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(Envelope.self, from: data)
    }

    private func persist(_ envelope: Envelope, forKey storageKey: String) {
        guard let data = try? JSONEncoder().encode(envelope) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func key(puzzleID: String, profileID: UUID?) -> String {
        if let profileID {
            return "maxpuzzles.profile.\(profileID.uuidString).dotToDot.colouringSnapshot.v2.\(puzzleID)"
        }
        return "maxpuzzles.dotToDot.colouringSnapshot.v2.\(puzzleID)"
    }

    private func legacyKey(puzzleID: String, profileID: UUID?) -> String {
        if let profileID {
            return "maxpuzzles.profile.\(profileID.uuidString).dotToDot.colouringSnapshot.v1.\(puzzleID)"
        }
        return "maxpuzzles.dotToDot.colouringSnapshot.v1.\(puzzleID)"
    }
}

/// Small pure state machine shared by the UI and tests. Progress is counted by unique semantic
/// regions, never by taps or pencil gestures, and tap/shade work contributes to the same result.
struct DotColouringProgress: Equatable {
    let requiredRegionIDs: Set<Int>
    private(set) var tapFilledRegionIDs: Set<Int>
    private(set) var shadedRegionIDs: Set<Int>

    init(
        requiredRegionIDs: Set<Int>,
        initiallyCompletedRegionIDs: Set<Int> = [],
        initiallyTapFilledRegionIDs: Set<Int>? = nil,
        initiallyShadedRegionIDs: Set<Int> = []
    ) {
        self.requiredRegionIDs = requiredRegionIDs
        tapFilledRegionIDs = (initiallyTapFilledRegionIDs ?? initiallyCompletedRegionIDs)
            .intersection(requiredRegionIDs)
        shadedRegionIDs = initiallyShadedRegionIDs.intersection(requiredRegionIDs)
    }

    var completedRegionIDs: Set<Int> {
        tapFilledRegionIDs.union(shadedRegionIDs).intersection(requiredRegionIDs)
    }

    var completedCount: Int { completedRegionIDs.count }
    var requiredCount: Int { requiredRegionIDs.count }
    var isComplete: Bool {
        !requiredRegionIDs.isEmpty && completedRegionIDs == requiredRegionIDs
    }

    @discardableResult
    mutating func recordTap(in regionID: Int) -> Bool {
        guard requiredRegionIDs.contains(regionID) else { return false }
        let previousCount = completedCount
        tapFilledRegionIDs.insert(regionID)
        return completedCount > previousCount
    }

    @discardableResult
    mutating func recordStroke(in regionID: Int, coverage: CGFloat) -> Bool {
        guard requiredRegionIDs.contains(regionID),
              coverage >= DotColourCoverageEvaluator.completionThreshold else { return false }
        let previousCount = completedCount
        shadedRegionIDs.insert(regionID)
        return completedCount > previousCount
    }

    mutating func reset() {
        tapFilledRegionIDs = []
        shadedRegionIDs = []
    }
}

enum DotColouringInteractionPolicy {
    static let minimumShadeSampleCount = 3
    static let minimumNormalizedShadeDistance: CGFloat = 0.012

    static func accepts(selectedSwatchID: Int, semanticRegionID: Int?) -> Bool {
        semanticRegionID == selectedSwatchID
    }

    static func isMeaningfulStroke(
        inMaskSampleCount: Int,
        cumulativeInMaskDistance: CGFloat
    ) -> Bool {
        inMaskSampleCount >= minimumShadeSampleCount
            && cumulativeInMaskDistance >= minimumNormalizedShadeDistance
    }

    static func normalizedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return .zero }
        return CGPoint(
            x: min(max(point.x / size.width, 0), 1),
            y: min(max(point.y / size.height, 0), 1)
        )
    }
}

enum DotColourStrokeSampler {
    static let minimumNormalizedPointDistance: CGFloat = 0.003
    static let maximumPointsPerStroke = 128
    static let maximumStrokesPerRegion = 36
    static let maximumStrokesPerPicture = 160

    @discardableResult
    static func append(_ point: CGPoint, to stroke: inout DotColourStroke) -> Bool {
        if let last = stroke.points.last,
           hypot(point.x - last.x, point.y - last.y) < minimumNormalizedPointDistance {
            return false
        }
        if stroke.points.count >= maximumPointsPerStroke {
            stroke.points = stroke.points.enumerated().compactMap { index, point in
                index.isMultiple(of: 2) ? point : nil
            }
        }
        stroke.points.append(point)
        return true
    }

    static func bounded(_ strokes: [DotColourStroke]) -> [DotColourStroke] {
        var regionCounts: [Int: Int] = [:]
        let regionBounded = strokes.reversed().compactMap { stroke -> DotColourStroke? in
            let count = regionCounts[stroke.regionID, default: 0]
            guard count < maximumStrokesPerRegion else { return nil }
            regionCounts[stroke.regionID] = count + 1
            var copy = stroke
            if copy.points.count > maximumPointsPerStroke {
                let strideSize = Int(ceil(Double(copy.points.count) / Double(maximumPointsPerStroke)))
                copy.points = copy.points.enumerated().compactMap { index, point in
                    index.isMultiple(of: strideSize) ? point : nil
                }
            }
            return copy
        }.reversed()
        return Array(regionBounded.suffix(maximumStrokesPerPicture))
    }
}

enum DotColourCoverageEvaluator {
    static let completionThreshold: CGFloat = 0.18
    private static let gridSize = 30

    static func coverage(
        of strokes: [DotColourStroke],
        in maskArt: DotPuzzleReferenceArt
    ) -> CGFloat {
        let relevantStrokes = DotColourStrokeSampler.bounded(strokes)
        guard !relevantStrokes.isEmpty else { return 0 }

        var maskGrid = Array(repeating: false, count: gridSize * gridSize)
        var maskSampleCount = 0
        for row in 0..<gridSize {
            for column in 0..<gridSize {
                let point = gridPoint(column: column, row: row)
                if DotSemanticMaskHitTester.contains(point, maskArt: maskArt) {
                    maskGrid[row * gridSize + column] = true
                    maskSampleCount += 1
                }
            }
        }
        guard maskSampleCount > 0 else { return 0 }

        var coveredGrid = Array(repeating: false, count: gridSize * gridSize)
        for stroke in relevantStrokes {
            let radius = max(stroke.normalizedLineWidth / 2, 0.012) + 0.006
            if stroke.points.count == 1, let point = stroke.points.first {
                markCoveredSamples(
                    from: point,
                    to: point,
                    radius: radius,
                    maskGrid: maskGrid,
                    coveredGrid: &coveredGrid
                )
            } else {
                for (start, end) in zip(stroke.points, stroke.points.dropFirst()) {
                    markCoveredSamples(
                        from: start,
                        to: end,
                        radius: radius,
                        maskGrid: maskGrid,
                        coveredGrid: &coveredGrid
                    )
                }
            }
        }
        let coveredSampleCount = coveredGrid.enumerated().reduce(into: 0) { count, entry in
            if maskGrid[entry.offset], entry.element { count += 1 }
        }
        return CGFloat(coveredSampleCount) / CGFloat(maskSampleCount)
    }

    private static func markCoveredSamples(
        from start: CGPoint,
        to end: CGPoint,
        radius: CGFloat,
        maskGrid: [Bool],
        coveredGrid: inout [Bool]
    ) {
        guard let columns = gridRange(
            from: min(start.x, end.x) - radius,
            through: max(start.x, end.x) + radius
        ), let rows = gridRange(
            from: min(start.y, end.y) - radius,
            through: max(start.y, end.y) + radius
        ) else { return }

        let squaredRadius = radius * radius
        for row in rows {
            for column in columns {
                let index = row * gridSize + column
                guard maskGrid[index], !coveredGrid[index] else { continue }
                let sample = gridPoint(column: column, row: row)
                if squaredDistance(from: sample, toSegmentFrom: start, to: end) <= squaredRadius {
                    coveredGrid[index] = true
                }
            }
        }
    }

    private static func gridPoint(column: Int, row: Int) -> CGPoint {
        CGPoint(
            x: (CGFloat(column) + 0.5) / CGFloat(gridSize),
            y: (CGFloat(row) + 0.5) / CGFloat(gridSize)
        )
    }

    private static func gridRange(from lowerValue: CGFloat, through upperValue: CGFloat) -> ClosedRange<Int>? {
        let scale = CGFloat(gridSize)
        let lower = max(0, Int(ceil(lowerValue * scale - 0.5)))
        let upper = min(gridSize - 1, Int(floor(upperValue * scale - 0.5)))
        guard lower <= upper else { return nil }
        return lower...upper
    }

    private static func squaredDistance(
        from point: CGPoint,
        toSegmentFrom start: CGPoint,
        to end: CGPoint
    ) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let squaredLength = dx * dx + dy * dy
        guard squaredLength > 0 else {
            let pointDX = point.x - start.x
            let pointDY = point.y - start.y
            return pointDX * pointDX + pointDY * pointDY
        }
        let projection = min(max(
            ((point.x - start.x) * dx + (point.y - start.y) * dy) / squaredLength,
            0
        ), 1)
        let nearestX = start.x + projection * dx
        let nearestY = start.y + projection * dy
        let nearestDX = point.x - nearestX
        let nearestDY = point.y - nearestY
        return nearestDX * nearestDX + nearestDY * nearestDY
    }
}

/// A full-screen activity presented after the numbered trail is complete. Its only model
/// dependency is the semantic plan: every colour owns a precise alpha mask, so animal markings,
/// vehicle details and the background are coloured according to what they actually are.
struct DotToDotColouringStage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    let puzzle: DotPuzzle
    let plan: DotSemanticColourPlan
    let initialCompletedRegions: Set<Int>
    let onRegionCompleted: (Int) -> Void
    /// Registers persistence synchronously and returns the queue task so Close/Finished can await
    /// durable storage before this presentation is allowed to disappear.
    let onSnapshotChanged: (DotColouringSnapshot) -> Task<Void, Never>
    let onReset: () -> Void
    let onDone: () -> Void
    let onClose: () -> Void

    @State private var mode: DotColouringMode = .tapToFill
    @State private var selectedSwatchID: Int
    @State private var progress: DotColouringProgress
    @State private var strokes: [DotColourStroke] = []
    @State private var activeStroke: DotColourStroke?
    @State private var message: String?
    @State private var wrongRegionID: Int?
    @State private var showsLeaveConfirmation = false
    @State private var masksReady = false
    @State private var clearWrongRegionTask: Task<Void, Never>?
    @State private var snapshotPersistenceTask: Task<Void, Never>?
    @State private var pendingSnapshot: DotColouringSnapshot?
    @State private var hasCommittedForDismissal = false
    @State private var isCommittingExit = false

    init(
        puzzle: DotPuzzle,
        plan: DotSemanticColourPlan,
        initialCompletedRegions: Set<Int> = [],
        initialSnapshot: DotColouringSnapshot = .empty,
        onRegionCompleted: @escaping (Int) -> Void,
        onSnapshotChanged: @escaping (DotColouringSnapshot) -> Task<Void, Never> = { _ in Task {} },
        onReset: @escaping () -> Void,
        onDone: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.puzzle = puzzle
        self.plan = plan
        self.initialCompletedRegions = initialCompletedRegions
        self.onRegionCompleted = onRegionCompleted
        self.onSnapshotChanged = onSnapshotChanged
        self.onReset = onReset
        self.onDone = onDone
        self.onClose = onClose

        let regionIDs = Set(plan.swatches.map(\.id))
        let boundedStrokes = DotColourStrokeSampler.bounded(
            initialSnapshot.strokes.filter { regionIDs.contains($0.regionID) }
        )
        _selectedSwatchID = State(initialValue: plan.swatches.first?.id ?? 1)
        _progress = State(
            initialValue: DotColouringProgress(
                requiredRegionIDs: regionIDs,
                initiallyTapFilledRegionIDs: initialSnapshot.tapFilledRegionIDs
            )
        )
        _strokes = State(initialValue: boundedStrokes)
    }

    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height

            ZStack {
                Color(hex: "071020")
                    .ignoresSafeArea()
                    .accessibilityElement()
                    .accessibilityLabel("Colouring activity")
                    .accessibilityIdentifier("dot-colouring-stage")
                LinearGradient(
                    colors: [Color(hex: "122445"), Color(hex: "071020")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: landscape ? 10 : 12) {
                    header

                    if landscape {
                        HStack(spacing: 14) {
                            artworkArea
                                .layoutPriority(2)

                            controlPanel(compact: false)
                                .frame(
                                    minWidth: 250,
                                    idealWidth: min(320, geometry.size.width * 0.30),
                                    maxWidth: 350
                                )
                        }
                    } else {
                        artworkArea

                        controlPanel(compact: true)
                    }
                }
                .padding(.horizontal, landscape ? 16 : 12)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .alert("Leave colouring?", isPresented: $showsLeaveConfirmation) {
            Button("Keep colouring", role: .cancel) {}
            Button("Leave for now", role: .destructive, action: closeStage)
        } message: {
            Text("Your colouring is saved. You can finish it next time.")
        }
        .task {
            announce("Colouring opened. \(mode.instruction)")
            await DotSemanticMaskHitTester.prewarm(
                plan,
                referenceArt: puzzle.referenceArt
            )
            guard !Task.isCancelled else {
                DotSemanticMaskHitTester.release(plan, referenceArt: puzzle.referenceArt)
                return
            }
            restoreInitialProgressAfterPrewarm()
            masksReady = true
            announce("Colours ready")
        }
        .onDisappear {
            clearWrongRegionTask?.cancel()
            clearWrongRegionTask = nil
            snapshotPersistenceTask?.cancel()
            snapshotPersistenceTask = nil
            // Explicit Close and Finished paths have already awaited this exact snapshot. For an
            // external lifecycle teardown, register the final value synchronously so a subsequent
            // presentation's queue drain sees it before rotating the session token.
            if !hasCommittedForDismissal {
                pendingSnapshot = nil
                _ = onSnapshotChanged(currentSnapshot)
            }
            DotSemanticMaskHitTester.release(plan, referenceArt: puzzle.referenceArt)
        }
        .onChange(of: scenePhase) { phase in
            guard phase != .active else { return }
            snapshotPersistenceTask?.cancel()
            snapshotPersistenceTask = nil
            pendingSnapshot = nil
            _ = onSnapshotChanged(currentSnapshot)
        }
        .interactiveDismissDisabled(true)
    }

    @ViewBuilder
    private var artworkArea: some View {
        if masksReady {
            artworkCanvas
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.backgroundMid.opacity(0.92))
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(AppTheme.cometCyan)
                    Text("Preparing your colours…")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Preparing colours")
            .accessibilityIdentifier("dot-colouring-preparing")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                showsLeaveConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close colouring")
            .accessibilityHint("Shows options to keep colouring or leave with your work saved")
            .accessibilityIdentifier("dot-colouring-close")

            VStack(alignment: .leading, spacing: 1) {
                Text("Colour your \(puzzle.title.lowercased())")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("\(progress.completedCount) of \(progress.requiredCount) colours used")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .accessibilityIdentifier("dot-colouring-progress")
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue("\(progress.completedCount) of \(progress.requiredCount) complete")

            Spacer(minLength: 4)

            Button {
                guard progress.isComplete else { return }
                finishStage()
            } label: {
                Label("Finished", systemImage: "checkmark.circle.fill")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(progress.isComplete ? Color(hex: "071020") : Color.white.opacity(0.55))
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(
                        Capsule().fill(progress.isComplete ? Color(hex: "5eead4") : Color.white.opacity(0.10))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!progress.isComplete || isCommittingExit)
            .accessibilityHint(progress.isComplete ? "Completes the picture" : "Use every numbered colour first")
            .accessibilityIdentifier("dot-colouring-finish")
        }
    }

    private var artworkCanvas: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)

            SemanticColourCanvas(
                puzzle: puzzle,
                plan: plan,
                mode: mode,
                selectedSwatchID: selectedSwatchID,
                tapFilledRegionIDs: progress.tapFilledRegionIDs,
                completedRegionIDs: progress.completedRegionIDs,
                strokes: strokes,
                activeStroke: activeStroke,
                wrongRegionID: wrongRegionID,
                onTap: applyTap,
                onShadeTouch: handleShadeTouch
            )
            .frame(width: side, height: side)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .accessibilityIdentifier("dot-colouring-canvas")
    }

    private func controlPanel(compact: Bool) -> some View {
        VStack(spacing: compact ? 9 : 14) {
            modePicker
            colourPots(compact: compact)

            HStack(spacing: 10) {
                Image(systemName: message == nil ? mode.icon : "sparkles")
                    .foregroundStyle(activeSwatchColor)

                Text(message ?? mode.instruction)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if progress.completedCount > 0 || !strokes.isEmpty {
                    Button("Reset", action: reset)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(Color(hex: "5eead4"))
                        .frame(minWidth: 44, minHeight: 44)
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("dot-colouring-reset")
                }
            }
        }
        .padding(compact ? 10 : 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "101a35").opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var modePicker: some View {
        HStack(spacing: 6) {
            ForEach(DotColouringMode.allCases) { candidate in
                Button {
                    guard mode != candidate else { return }
                    SoundEffectsService.shared.play(.buttonTap)
                    FeedbackManager.shared.haptic(.selection)
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.20)) {
                        mode = candidate
                        activeStroke = nil
                        wrongRegionID = nil
                        message = nil
                    }
                    announce("\(candidate.title). \(candidate.instruction)")
                } label: {
                    Label(candidate.shortTitle, systemImage: candidate.icon)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(mode == candidate ? Color(hex: "071020") : Color.white.opacity(0.78))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(mode == candidate ? Color(hex: "5eead4") : Color.white.opacity(0.07))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(candidate.title)
                .accessibilityAddTraits(mode == candidate ? .isSelected : [])
                .accessibilityIdentifier("dot-colouring-mode-\(candidate.rawValue)")
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.24)))
    }

    private func colourPots(compact: Bool) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: compact ? 10 : 12) {
                ForEach(plan.swatches, id: \.id) { swatch in
                    let selected = swatch.id == selectedSwatchID
                    Button {
                        selectSwatch(swatch)
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: swatch.hex))
                                    .frame(width: compact ? 48 : 58, height: compact ? 48 : 58)
                                    .overlay(
                                        Circle().stroke(
                                            selected ? Color.white : Color.white.opacity(0.30),
                                            lineWidth: selected ? 4 : 1.5
                                        )
                                    )
                                    .shadow(color: Color(hex: swatch.hex).opacity(0.38), radius: 7)

                                DotColourQuantityDots(quantity: swatch.id)
                                    .frame(width: compact ? 31 : 37, height: compact ? 31 : 37)
                            }

                            Text(shortSwatchName(swatch))
                                .font(AppTypography.caption)
                                .foregroundStyle(Color.white.opacity(selected ? 1 : 0.72))
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 92)
                        }
                        .frame(minWidth: compact ? 58 : 72, minHeight: compact ? 64 : 78)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Colour \(swatch.id), \(swatch.name)")
                    .accessibilityHint("This pot has \(swatch.id) dots")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("dot-colouring-pot-\(swatch.id)")
                }
            }
            .padding(.horizontal, 3)
        }
        .scrollIndicators(.hidden)
    }

    private var activeSwatchColor: Color {
        guard let swatch = plan.swatches.first(where: { $0.id == selectedSwatchID }) else {
            return Color(hex: "5eead4")
        }
        return Color(hex: swatch.hex)
    }

    private func selectSwatch(_ swatch: DotSemanticColourSwatch) {
        SoundEffectsService.shared.play(.buttonTap)
        FeedbackManager.shared.haptic(.selection)
        selectedSwatchID = swatch.id
        wrongRegionID = nil
        message = "\(swatch.name): find every space marked \(swatch.id)."
        announce(message ?? swatch.name)
    }

    private func applyTap(_ regionID: Int?) {
        guard let regionID else {
            message = "Try a numbered space inside the picture."
            FeedbackManager.shared.haptic(.light)
            announce(message ?? "Try inside the picture")
            return
        }
        guard DotColouringInteractionPolicy.accepts(
            selectedSwatchID: selectedSwatchID,
            semanticRegionID: regionID
        ) else {
            wrongRegionID = regionID
            message = "That space says \(regionID). Choose the pot with \(regionID) dots."
            SoundEffectsService.shared.play(.wrongMove)
            FeedbackManager.shared.haptic(.wrongMove)
            announce(message ?? "Choose the matching colour")
            clearWrongRegion(after: 0.65)
            return
        }

        var updated = progress
        let newlyCompleted = updated.recordTap(in: regionID)
        withAnimation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.78)) {
            progress = updated
            wrongRegionID = nil
            message = progress.isComplete
                ? "Brilliant colouring—your picture is finished!"
                : "Great match! Choose another numbered pot."
        }
        if newlyCompleted { onRegionCompleted(regionID) }
        scheduleSnapshotPersistence()
        SoundEffectsService.shared.play(progress.isComplete ? .starReveal : .correctMove)
        FeedbackManager.shared.haptic(.correctMove)
        announce(message ?? "Colour complete")
    }

    private func handleShadeTouch(_ phase: TraceTouchPhase, _ location: CGPoint, _ size: CGSize) {
        let point = DotColouringInteractionPolicy.normalizedPoint(location, in: size)

        switch phase {
        case .began:
            let touchedRegion = DotSemanticMaskHitTester.regionID(at: point, in: plan)
            guard DotColouringInteractionPolicy.accepts(
                selectedSwatchID: selectedSwatchID,
                semanticRegionID: touchedRegion
            ) else {
                wrongRegionID = touchedRegion
                message = touchedRegion.map {
                    "That space is number \($0). Choose its matching pot first."
                } ?? "Start inside a numbered part of the picture."
                FeedbackManager.shared.haptic(.light)
                clearWrongRegion(after: 0.65)
                activeStroke = nil
                return
            }
            activeStroke = DotColourStroke(
                regionID: selectedSwatchID,
                swatchID: selectedSwatchID,
                points: [point]
            )
            wrongRegionID = nil
            message = "Keep shading—your pencil stays inside \(swatchName(selectedSwatchID))."

        case .moved:
            guard var stroke = activeStroke else { return }
            guard DotColourStrokeSampler.append(point, to: &stroke) else { return }
            activeStroke = stroke

        case .ended:
            guard var finished = activeStroke else { return }
            _ = DotColourStrokeSampler.append(point, to: &finished)
            guard isMeaningfulInMaskStroke(finished) else {
                activeStroke = nil
                message = "Make a longer shading stroke inside the numbered space."
                FeedbackManager.shared.haptic(.light)
                announce(message ?? "Make a longer stroke")
                return
            }
            strokes.append(finished)
            strokes = DotColourStrokeSampler.bounded(strokes)
            activeStroke = nil

            let regionStrokes = strokes.filter { $0.regionID == finished.regionID }
            let coverage = plan.swatches.first(where: { $0.id == finished.regionID }).map {
                DotColourCoverageEvaluator.coverage(of: regionStrokes, in: $0.maskArt)
            } ?? 0
            var updated = progress
            let newlyCompleted = updated.recordStroke(in: finished.regionID, coverage: coverage)
            progress = updated
            if newlyCompleted { onRegionCompleted(finished.regionID) }
            scheduleSnapshotPersistence()

            if progress.isComplete {
                message = "Beautiful shading—your picture is ready!"
                SoundEffectsService.shared.play(.starReveal)
                FeedbackManager.shared.haptic(.correctMove)
            } else if newlyCompleted {
                message = "Colour \(finished.regionID) is shaded. Choose another pot."
                SoundEffectsService.shared.play(.correctMove)
                FeedbackManager.shared.haptic(.correctMove)
            } else {
                let percent = min(Int((coverage * 100).rounded()), 99)
                message = "Keep shading colour \(finished.regionID)—about \(percent)% covered."
                FeedbackManager.shared.haptic(.light)
            }
            announce(message ?? "Shading saved")

        case .cancelled:
            activeStroke = nil
        }
    }

    private func reset() {
        snapshotPersistenceTask?.cancel()
        snapshotPersistenceTask = nil
        pendingSnapshot = nil
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.20)) {
            progress.reset()
            strokes = []
            activeStroke = nil
            wrongRegionID = nil
            selectedSwatchID = plan.swatches.first?.id ?? 1
            message = "Fresh canvas—start with pot 1."
        }
        onReset()
        scheduleSnapshotPersistence()
        FeedbackManager.shared.haptic(.light)
        announce("Colouring reset")
    }

    private func closeStage() {
        guard !isCommittingExit else { return }
        isCommittingExit = true
        Task { @MainActor in
            await flushPendingSnapshot()
            hasCommittedForDismissal = true
            onClose()
            dismiss()
        }
    }

    private func finishStage() {
        guard !isCommittingExit else { return }
        isCommittingExit = true
        Task { @MainActor in
            await flushPendingSnapshot()
            hasCommittedForDismissal = true
            SoundEffectsService.shared.play(.levelComplete)
            FeedbackManager.shared.haptic(.levelComplete)
            onDone()
            // Drive dismissal from the presented view as well as the parent's binding. This
            // avoids a SwiftUI fullScreenCover race where the reward view is updated behind
            // a cover that has not yet begun dismissing.
            dismiss()
        }
    }

    private func swatchName(_ id: Int) -> String {
        plan.swatches.first(where: { $0.id == id })?.name.lowercased() ?? "the colour"
    }

    private func shortSwatchName(_ swatch: DotSemanticColourSwatch) -> String {
        if swatch.isBackground { return "Background" }
        let subjectWords = Set(
            puzzle.title.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
        )
        let semanticWords = swatch.name
            .split(separator: " ")
            .dropFirst() // The first generated word is the colour name.
            .filter { !subjectWords.contains($0.lowercased()) }
        let result = semanticWords.map(String.init).joined(separator: " ")
        return result.isEmpty ? "Colour \(swatch.id)" : result.capitalized
    }

    private func isMeaningfulInMaskStroke(_ stroke: DotColourStroke) -> Bool {
        guard let swatch = plan.swatches.first(where: { $0.id == stroke.regionID }) else {
            return false
        }

        var inMaskSamples = 0
        var inMaskDistance: CGFloat = 0
        for point in stroke.points where DotSemanticMaskHitTester.contains(point, maskArt: swatch.maskArt) {
            inMaskSamples += 1
        }
        for (left, right) in zip(stroke.points, stroke.points.dropFirst())
        where DotSemanticMaskHitTester.contains(left, maskArt: swatch.maskArt)
            && DotSemanticMaskHitTester.contains(right, maskArt: swatch.maskArt) {
            inMaskDistance += hypot(right.x - left.x, right.y - left.y)
        }
        return DotColouringInteractionPolicy.isMeaningfulStroke(
            inMaskSampleCount: inMaskSamples,
            cumulativeInMaskDistance: inMaskDistance
        )
    }

    private func clearWrongRegion(after delay: TimeInterval) {
        clearWrongRegionTask?.cancel()
        let captured = wrongRegionID
        clearWrongRegionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            if wrongRegionID == captured { wrongRegionID = nil }
        }
    }

    private func restoreInitialProgressAfterPrewarm() {
        let shadedRegions = Set(plan.swatches.compactMap { swatch in
            let coverage = DotColourCoverageEvaluator.coverage(
                of: strokes.filter { $0.regionID == swatch.id },
                in: swatch.maskArt
            )
            return coverage >= DotColourCoverageEvaluator.completionThreshold ? swatch.id : nil
        })
        let migratedTapRegions = progress.tapFilledRegionIDs
            .union(initialCompletedRegions.subtracting(shadedRegions))
        progress = DotColouringProgress(
            requiredRegionIDs: Set(plan.swatches.map(\.id)),
            initiallyTapFilledRegionIDs: migratedTapRegions,
            initiallyShadedRegionIDs: shadedRegions
        )
    }

    private func scheduleSnapshotPersistence() {
        pendingSnapshot = currentSnapshot
        snapshotPersistenceTask?.cancel()
        snapshotPersistenceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            guard let snapshot = pendingSnapshot else { return }
            pendingSnapshot = nil
            let persistenceTask = onSnapshotChanged(snapshot)
            await persistenceTask.value
            guard !Task.isCancelled else { return }
            snapshotPersistenceTask = nil
        }
    }

    @MainActor
    private func flushPendingSnapshot() async {
        let scheduledTask = snapshotPersistenceTask
        scheduledTask?.cancel()
        snapshotPersistenceTask = nil
        if let snapshot = pendingSnapshot {
            pendingSnapshot = nil
            let persistenceTask = onSnapshotChanged(snapshot)
            await persistenceTask.value
        } else if let scheduledTask {
            // If the debounce already took ownership of the snapshot, wait for its store write.
            await scheduledTask.value
        }
    }

    private var currentSnapshot: DotColouringSnapshot {
        DotColouringSnapshot(
            tapFilledRegionIDs: progress.tapFilledRegionIDs,
            strokes: DotColourStrokeSampler.bounded(strokes)
        )
    }

    private func announce(_ value: String) {
        UIAccessibility.post(notification: .announcement, argument: value)
    }
}

private struct SemanticColourCanvas: View {
    let puzzle: DotPuzzle
    let plan: DotSemanticColourPlan
    let mode: DotColouringMode
    let selectedSwatchID: Int
    let tapFilledRegionIDs: Set<Int>
    let completedRegionIDs: Set<Int>
    let strokes: [DotColourStroke]
    let activeStroke: DotColourStroke?
    let wrongRegionID: Int?
    let onTap: (Int?) -> Void
    let onShadeTouch: (TraceTouchPhase, CGPoint, CGSize) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: "fffdf7")

                ForEach(plan.swatches, id: \.id) { swatch in
                    if tapFilledRegionIDs.contains(swatch.id) {
                        DotColourAtlasTileView(
                            art: swatch.maskArt,
                            tint: Color(hex: swatch.hex)
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.985)))
                    }
                }

                ForEach(plan.swatches, id: \.id) { swatch in
                    let swatchStrokes = strokesForSwatch(swatch.id)
                    if !swatchStrokes.isEmpty {
                        DotColourStrokeLayer(
                            strokes: swatchStrokes,
                            color: Color(hex: swatch.hex)
                        )
                        .mask {
                            DotColourAtlasTileView(art: swatch.maskArt, tint: .white)
                        }
                    }
                }

                semanticLabels(in: geometry.size)

                DotColourLineArtworkView(puzzle: puzzle)

                if mode == .shade {
                    TraceTouchCapture(pencilOnly: false) { phase, location in
                        onShadeTouch(phase, location, geometry.size)
                    }
                    .accessibilityLabel("\(puzzle.title) shading canvas")
                    .accessibilityHint("Choose a numbered pot, then draw in its matching space with a finger or Apple Pencil")
                    .accessibilityAction(named: "Colour selected number") {
                        onTap(selectedSwatchID)
                    }
                } else {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    let point = DotColouringInteractionPolicy.normalizedPoint(
                                        value.location,
                                        in: geometry.size
                                    )
                                    onTap(DotSemanticMaskHitTester.regionID(at: point, in: plan))
                                }
                        )
                        .accessibilityHidden(true)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.72), lineWidth: 3)
            )
            .shadow(color: Color.black.opacity(0.30), radius: 18, y: 9)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(puzzle.title) colour by numbers picture")
        }
    }

    @ViewBuilder
    private func semanticLabels(in size: CGSize) -> some View {
        let diameter = min(max(size.width * 0.055, 22), 34)
        let edgeInset = diameter / 2 + 5
        ForEach(plan.swatches, id: \.id) { swatch in
            if !completedRegionIDs.contains(swatch.id) {
                // A semantic mask can contain dozens of tiny markings (giraffe spots, zebra
                // stripes). A few well-placed numerals teach the match without hiding the picture.
                ForEach(Array(swatch.labelPoints.prefix(3).enumerated()), id: \.offset) { index, point in
                    Button {
                        onTap(swatch.id)
                    } label: {
                        Text("\(swatch.id)")
                            .font(.system(size: diameter * 0.52, weight: .black, design: .rounded))
                            .foregroundStyle(
                                wrongRegionID == swatch.id ? Color.white : Color(hex: "172033")
                            )
                            .frame(width: diameter, height: diameter)
                            .background(
                                Circle().fill(
                                    wrongRegionID == swatch.id
                                        ? Color(hex: "fb7185")
                                        : Color.white.opacity(0.88)
                                )
                            )
                            .overlay(Circle().stroke(Color(hex: swatch.hex), lineWidth: 2))
                            .shadow(color: Color.black.opacity(0.13), radius: 3, y: 1)
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .position(
                        x: min(max(point.x * size.width, edgeInset), size.width - edgeInset),
                        y: min(max(point.y * size.height, edgeInset), size.height - edgeInset)
                    )
                    .allowsHitTesting(mode == .tapToFill)
                    .accessibilityLabel("Space \(swatch.id), \(swatch.name)")
                    .accessibilityHint("Choose the pot with \(swatch.id) dots")
                    .accessibilityIdentifier("dot-colouring-region-\(swatch.id)-\(index)")
                }
            }
        }
    }

    private func strokesForSwatch(_ swatchID: Int) -> [DotColourStroke] {
        var result = strokes.filter { $0.swatchID == swatchID }
        if let activeStroke, activeStroke.swatchID == swatchID {
            result.append(activeStroke)
        }
        return result
    }
}

private struct DotColourStrokeLayer: View {
    let strokes: [DotColourStroke]
    let color: Color

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            for stroke in strokes {
                let points = stroke.points.map {
                    CGPoint(x: $0.x * size.width, y: $0.y * size.height)
                }
                guard let first = points.first else { continue }
                let width = max(5, stroke.normalizedLineWidth * side)

                if points.count == 1 {
                    let mark = CGRect(
                        x: first.x - width / 2,
                        y: first.y - width / 2,
                        width: width,
                        height: width
                    )
                    context.fill(Path(ellipseIn: mark), with: .color(color.opacity(0.92)))
                } else {
                    var path = Path()
                    path.move(to: first)
                    for point in points.dropFirst() { path.addLine(to: point) }
                    context.stroke(
                        path,
                        with: .color(color.opacity(0.92)),
                        style: StrokeStyle(
                            lineWidth: width,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Crops one normalised tile from a transparent atlas. The same primitive renders semantic masks
/// as solid fills, clips pencil strokes, and restores the original black line art above the colour.
private struct DotColourAtlasTileView: View {
    let art: DotPuzzleReferenceArt
    let tint: Color

    var body: some View {
        Group {
            if let image = DotSemanticMaskHitTester.croppedImage(for: art) {
                Image(uiImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .interpolation(.high)
                    .foregroundStyle(tint)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct DotColourLineArtworkView: View {
    let puzzle: DotPuzzle

    var body: some View {
        Group {
            if let referenceArt = puzzle.referenceArt {
                DotColourAtlasTileView(art: referenceArt, tint: Color(hex: "172033"))
            } else {
                Canvas { context, size in
                    let lines = [puzzle.revealOutline + Array(puzzle.revealOutline.prefix(1))]
                        + puzzle.guidePaths
                        + puzzle.detailPaths
                    for line in lines {
                        guard let first = line.first else { continue }
                        var path = Path()
                        path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
                        for point in line.dropFirst() {
                            path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
                        }
                        context.stroke(
                            path,
                            with: .color(Color(hex: "172033")),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct DotColourQuantityDots: View {
    let quantity: Int

    var body: some View {
        GeometryReader { geometry in
            ForEach(Array(SubitizingChallenge.pattern(for: quantity).enumerated()), id: \.offset) { _, point in
                Circle()
                    .fill(Color(hex: "071020"))
                    .frame(width: 7, height: 7)
                    .position(
                        x: point.x * geometry.size.width,
                        y: point.y * geometry.size.height
                    )
            }
        }
        .accessibilityHidden(true)
    }
}

/// Pixel-accurate hit testing for alpha-only semantic masks. A tiny immutable bitmap is cached for
/// each atlas tile, so a tap or Pencil start can identify spots, body, detail or background without
/// reducing them to generic vertical strips.
enum DotSemanticMaskHitTester {
    static let maximumCacheCostBytes = 24 * 1_024 * 1_024

    private final class Bitmap {
        let width: Int
        let height: Int
        let alpha: [UInt8]
        let image: UIImage

        init(width: Int, height: Int, alpha: [UInt8], image: UIImage) {
            self.width = width
            self.height = height
            self.alpha = alpha
            self.image = image
        }

        func contains(_ point: CGPoint) -> Bool {
            guard width > 0, height > 0,
                  point.x >= 0, point.x <= 1,
                  point.y >= 0, point.y <= 1 else { return false }
            let x = min(max(Int(point.x * CGFloat(width)), 0), width - 1)
            // Drawing an upright PNG into this RGBA bitmap preserves its top-to-bottom row order,
            // matching the normalised coordinates used by SwiftUI and the mask generator.
            let y = min(max(Int(point.y * CGFloat(height)), 0), height - 1)
            return alpha[y * width + x] > 24
        }
    }

    private static let cache: NSCache<NSString, Bitmap> = {
        let cache = NSCache<NSString, Bitmap>()
        // Six independent 512×512 RGBA tiles plus compact alpha hit maps fit comfortably here.
        // Full 2560×1536 worksheet atlases are never retained by this cache or rendered by SwiftUI.
        cache.totalCostLimit = maximumCacheCostBytes
        return cache
    }()

    static func regionID(at point: CGPoint, in plan: DotSemanticColourPlan) -> Int? {
        // Check smaller foreground detail layers first, then the broad body layer, and leave the
        // generated background mask until last at antialiased shared boundaries.
        let foreground = plan.swatches.filter { !$0.isBackground }.reversed()
        for swatch in foreground where contains(point, maskArt: swatch.maskArt) {
            return swatch.id
        }
        for background in plan.swatches where background.isBackground {
            if contains(point, maskArt: background.maskArt) { return background.id }
        }
        return nil
    }

    static func contains(_ point: CGPoint, maskArt: DotPuzzleReferenceArt) -> Bool {
        bitmap(for: maskArt)?.contains(point) ?? false
    }

    static func croppedImage(for art: DotPuzzleReferenceArt) -> UIImage? {
        bitmap(for: art)?.image
    }

    static func hasCachedImage(for art: DotPuzzleReferenceArt) -> Bool {
        cache.object(forKey: cacheKey(for: art)) != nil
    }

    static func prewarm(
        _ plan: DotSemanticColourPlan,
        referenceArt: DotPuzzleReferenceArt?
    ) async {
        var artwork = plan.swatches.map(\.maskArt)
        if let referenceArt { artwork.append(referenceArt) }
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                for art in artwork {
                    _ = bitmap(for: art)
                }
                continuation.resume()
            }
        }
    }

    static func release(
        _ plan: DotSemanticColourPlan,
        referenceArt: DotPuzzleReferenceArt?
    ) {
        for art in plan.swatches.map(\.maskArt) {
            cache.removeObject(forKey: cacheKey(for: art))
        }
        if let referenceArt {
            cache.removeObject(forKey: cacheKey(for: referenceArt))
        }
    }

    private static func bitmap(for art: DotPuzzleReferenceArt) -> Bitmap? {
        let key = cacheKey(for: art)
        if let cached = cache.object(forKey: key) { return cached }

        let result: Bitmap? = autoreleasepool {
            guard art.columns > 0, art.rows > 0,
                  art.column >= 0, art.column < art.columns,
                  art.row >= 0, art.row < art.rows,
                  let atlas = UIImage(named: art.assetName)?.cgImage else { return nil }

            let tileWidth = atlas.width / art.columns
            let tileHeight = atlas.height / art.rows
            guard tileWidth > 0, tileHeight > 0,
                  let tile = atlas.cropping(
                    to: CGRect(
                        x: art.column * tileWidth,
                        y: art.row * tileHeight,
                        width: tileWidth,
                        height: tileHeight
                    )
                  ) else { return nil }

            var rgba = [UInt8](repeating: 0, count: tileWidth * tileHeight * 4)
            let rendered = rgba.withUnsafeMutableBytes { storage -> Bool in
                guard let context = CGContext(
                    data: storage.baseAddress,
                    width: tileWidth,
                    height: tileHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: tileWidth * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ) else { return false }
                context.interpolationQuality = .none
                context.draw(tile, in: CGRect(x: 0, y: 0, width: tileWidth, height: tileHeight))
                return true
            }
            guard rendered else { return nil }

            var alpha = [UInt8](repeating: 0, count: tileWidth * tileHeight)
            for pixel in alpha.indices { alpha[pixel] = rgba[pixel * 4 + 3] }

            let data = Data(rgba) as CFData
            guard let provider = CGDataProvider(data: data),
                  let independentTile = CGImage(
                    width: tileWidth,
                    height: tileHeight,
                    bitsPerComponent: 8,
                    bitsPerPixel: 32,
                    bytesPerRow: tileWidth * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                    provider: provider,
                    decode: nil,
                    shouldInterpolate: true,
                    intent: .defaultIntent
                  ) else { return nil }
            return Bitmap(
                width: tileWidth,
                height: tileHeight,
                alpha: alpha,
                image: UIImage(cgImage: independentTile)
            )
        }
        guard let result else { return nil }
        cache.setObject(
            result,
            forKey: key,
            cost: result.alpha.count + result.width * result.height * 4
        )
        return result
    }

    private static func cacheKey(for art: DotPuzzleReferenceArt) -> NSString {
        "\(art.assetName):\(art.column):\(art.row):\(art.columns):\(art.rows)" as NSString
    }
}
