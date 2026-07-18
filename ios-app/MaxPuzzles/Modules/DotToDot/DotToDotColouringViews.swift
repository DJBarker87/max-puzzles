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

/// Keeps the completion status from replacing the longer opening instruction when mask loading
/// finishes immediately, while still reporting a genuinely visible loading transition.
enum DotColouringAccessibilityAnnouncementPolicy {
    static let minimumReadyStatusDelay: TimeInterval = 1

    static func opening(for mode: DotColouringMode) -> String {
        "Colouring opened. \(mode.instruction)"
    }

    static func ready(afterPrewarm elapsed: TimeInterval, mode: DotColouringMode) -> String? {
        guard elapsed >= minimumReadyStatusDelay else { return nil }
        return "Colours ready. \(mode.instruction)"
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

    private struct DecodedSnapshot {
        let snapshot: DotColouringSnapshot
        let wasCorrupt: Bool
        let migratedDefaultsKeys: [String]
    }

    private let defaults: UserDefaults
    private let fileManager: FileManager
    private let storageDirectory: URL
    /// The current session envelope is kept in actor-isolated memory so a transient filesystem
    /// failure never makes a valid on-screen token look stale until the next launch.
    private var liveEnvelopes: [String: Envelope] = [:]

    init(
        defaults: UserDefaults = .standard,
        fileManager: FileManager = .default,
        storageDirectory: URL? = nil
    ) {
        self.defaults = defaults
        self.fileManager = fileManager
        if let storageDirectory {
            self.storageDirectory = storageDirectory
        } else {
            let applicationSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? fileManager.temporaryDirectory
            let namespace = Bundle.main.bundleIdentifier ?? "MaxPuzzles"
            self.storageDirectory = applicationSupport
                .appendingPathComponent(namespace, isDirectory: true)
                .appendingPathComponent("DotColouringSnapshots", isDirectory: true)
                .appendingPathComponent("v3", isDirectory: true)
        }
    }

    func beginSession(puzzleID: String, profileID: UUID?) -> Session {
        let resourceKey = key(puzzleID: puzzleID, profileID: profileID)
        let decoded = decodeSnapshot(
            resourceKey: resourceKey,
            puzzleID: puzzleID,
            profileID: profileID
        )
        let token = UUID()
        let envelope = Envelope(token: token, revision: 0, snapshot: decoded.snapshot)
        if persist(envelope, resourceKey: resourceKey) {
            for defaultsKey in decoded.migratedDefaultsKeys {
                defaults.removeObject(forKey: defaultsKey)
            }
        }
        liveEnvelopes[resourceKey] = envelope
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
        let resourceKey = key(puzzleID: puzzleID, profileID: profileID)
        // Disk is authoritative across store instances (for example after a scene rebuild); the
        // actor-local envelope is only the fallback when a transient read cannot reach the file.
        guard let existing = decodeFileEnvelope(resourceKey: resourceKey) ?? liveEnvelopes[resourceKey],
              existing.token == sessionToken,
              revision > existing.revision else { return false }
        let envelope = Envelope(
            token: sessionToken,
            revision: revision,
            snapshot: bounded(snapshot)
        )
        guard persist(envelope, resourceKey: resourceKey) else { return false }
        liveEnvelopes[resourceKey] = envelope
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
        resourceKey: String,
        puzzleID: String,
        profileID: UUID?
    ) -> DecodedSnapshot {
        let fileURL = fileURL(resourceKey: resourceKey)
        if fileManager.fileExists(atPath: fileURL.path) {
            guard let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else {
                try? fileManager.removeItem(at: fileURL)
                return DecodedSnapshot(
                    snapshot: .empty,
                    wasCorrupt: true,
                    migratedDefaultsKeys: []
                )
            }
            return DecodedSnapshot(
                snapshot: bounded(envelope.snapshot),
                wasCorrupt: false,
                migratedDefaultsKeys: []
            )
        }

        let defaultsV2Key = key(puzzleID: puzzleID, profileID: profileID)
        if let data = defaults.data(forKey: defaultsV2Key) {
            guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else {
                defaults.removeObject(forKey: defaultsV2Key)
                return DecodedSnapshot(
                    snapshot: .empty,
                    wasCorrupt: true,
                    migratedDefaultsKeys: []
                )
            }
            return DecodedSnapshot(
                snapshot: bounded(envelope.snapshot),
                wasCorrupt: false,
                migratedDefaultsKeys: [defaultsV2Key]
            )
        }

        let defaultsV1Key = legacyKey(puzzleID: puzzleID, profileID: profileID)
        guard let legacyData = defaults.data(forKey: defaultsV1Key) else {
            return DecodedSnapshot(snapshot: .empty, wasCorrupt: false, migratedDefaultsKeys: [])
        }
        guard let legacySnapshot = try? JSONDecoder().decode(DotColouringSnapshot.self, from: legacyData) else {
            defaults.removeObject(forKey: defaultsV1Key)
            return DecodedSnapshot(snapshot: .empty, wasCorrupt: true, migratedDefaultsKeys: [])
        }
        return DecodedSnapshot(
            snapshot: bounded(legacySnapshot),
            wasCorrupt: false,
            migratedDefaultsKeys: [defaultsV1Key]
        )
    }

    private func decodeFileEnvelope(resourceKey: String) -> Envelope? {
        guard let data = try? Data(contentsOf: fileURL(resourceKey: resourceKey), options: .mappedIfSafe)
        else { return nil }
        return try? JSONDecoder().decode(Envelope.self, from: data)
    }

    @discardableResult
    private func persist(_ envelope: Envelope, resourceKey: String) -> Bool {
        do {
            try fileManager.createDirectory(
                at: storageDirectory,
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(envelope)
            try data.write(to: fileURL(resourceKey: resourceKey), options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private func fileURL(resourceKey: String) -> URL {
        let filename = Data(resourceKey.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
        return storageDirectory.appendingPathComponent("\(filename).json", isDirectory: false)
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

/// Immutable 30×30 occupancy sampled from a semantic mask once, when its 512×512 bitmap is decoded.
/// The former evaluator performed the same 900 alpha lookups after every completed Pencil stroke.
struct DotColourCoverageMask: Sendable {
    static let gridSize = 30

    let occupied: [Bool]
    let sampleCount: Int

    init(width: Int, height: Int, alpha: [UInt8]) {
        var occupied = Array(repeating: false, count: Self.gridSize * Self.gridSize)
        var sampleCount = 0
        guard width > 0, height > 0, alpha.count >= width * height else {
            self.occupied = occupied
            self.sampleCount = 0
            return
        }

        for row in 0..<Self.gridSize {
            for column in 0..<Self.gridSize {
                let point = Self.gridPoint(column: column, row: row)
                let x = min(max(Int(point.x * CGFloat(width)), 0), width - 1)
                let y = min(max(Int(point.y * CGFloat(height)), 0), height - 1)
                let index = row * Self.gridSize + column
                if alpha[y * width + x] > 24 {
                    occupied[index] = true
                    sampleCount += 1
                }
            }
        }
        self.occupied = occupied
        self.sampleCount = sampleCount
    }

    static func gridPoint(column: Int, row: Int) -> CGPoint {
        CGPoint(
            x: (CGFloat(column) + 0.5) / CGFloat(gridSize),
            y: (CGFloat(row) + 0.5) / CGFloat(gridSize)
        )
    }
}

/// Retains the union of covered samples for one semantic region. Normal play appends one immutable
/// stroke, so only that stroke is evaluated. If bounded history evicts an old stroke, the small grid
/// is rebuilt from the retained vectors to preserve the previous completion result exactly.
struct DotColourCoverageAccumulator {
    private let mask: DotColourCoverageMask
    private var coveredGrid: [Bool]
    private(set) var strokeIDs: [UUID] = []

    init(mask: DotColourCoverageMask) {
        self.mask = mask
        coveredGrid = Array(repeating: false, count: DotColourCoverageMask.gridSize * DotColourCoverageMask.gridSize)
    }

    mutating func replaceStrokes(_ strokes: [DotColourStroke]) -> CGFloat {
        let relevantStrokes = DotColourStrokeSampler.bounded(strokes)
        let nextIDs = relevantStrokes.map(\.id)

        if nextIDs == strokeIDs { return coverage }
        if nextIDs.count == strokeIDs.count + 1,
           Array(nextIDs.dropLast()) == strokeIDs,
           let appended = relevantStrokes.last {
            mark(appended)
        } else {
            coveredGrid = Array(
                repeating: false,
                count: DotColourCoverageMask.gridSize * DotColourCoverageMask.gridSize
            )
            for stroke in relevantStrokes { mark(stroke) }
        }
        strokeIDs = nextIDs
        return coverage
    }

    var coverage: CGFloat {
        guard mask.sampleCount > 0 else { return 0 }
        let coveredSampleCount = coveredGrid.enumerated().reduce(into: 0) { count, entry in
            if mask.occupied[entry.offset], entry.element { count += 1 }
        }
        return CGFloat(coveredSampleCount) / CGFloat(mask.sampleCount)
    }

    private mutating func mark(_ stroke: DotColourStroke) {
        let radius = max(stroke.normalizedLineWidth / 2, 0.012) + 0.006
        if stroke.points.count == 1, let point = stroke.points.first {
            markCoveredSamples(from: point, to: point, radius: radius)
        } else {
            for (start, end) in zip(stroke.points, stroke.points.dropFirst()) {
                markCoveredSamples(from: start, to: end, radius: radius)
            }
        }
    }

    private mutating func markCoveredSamples(
        from start: CGPoint,
        to end: CGPoint,
        radius: CGFloat
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
                let index = row * DotColourCoverageMask.gridSize + column
                guard mask.occupied[index], !coveredGrid[index] else { continue }
                let sample = DotColourCoverageMask.gridPoint(column: column, row: row)
                if squaredDistance(from: sample, toSegmentFrom: start, to: end) <= squaredRadius {
                    coveredGrid[index] = true
                }
            }
        }
    }

    private func gridRange(from lowerValue: CGFloat, through upperValue: CGFloat) -> ClosedRange<Int>? {
        let scale = CGFloat(DotColourCoverageMask.gridSize)
        let lower = max(0, Int(ceil(lowerValue * scale - 0.5)))
        let upper = min(DotColourCoverageMask.gridSize - 1, Int(floor(upperValue * scale - 0.5)))
        guard lower <= upper else { return nil }
        return lower...upper
    }

    private func squaredDistance(
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

enum DotColourCoverageEvaluator {
    static let completionThreshold: CGFloat = 0.18

    static func makeAccumulator(
        in maskArt: DotPuzzleReferenceArt
    ) -> DotColourCoverageAccumulator? {
        DotSemanticMaskHitTester.coverageMask(for: maskArt).map(DotColourCoverageAccumulator.init)
    }

    static func coverage(
        of strokes: [DotColourStroke],
        in maskArt: DotPuzzleReferenceArt
    ) -> CGFloat {
        guard var accumulator = makeAccumulator(in: maskArt) else { return 0 }
        return accumulator.replaceStrokes(strokes)
    }
}

/// A committed stroke's geometry is immutable. Converting its normalised samples into a Path once
/// avoids remapping every historical sample whenever a pot, status label, or accessibility value
/// changes elsewhere in the stage.
private struct DotCommittedStrokeRenderPath {
    let normalizedPath: Path?
    let singlePoint: CGPoint?
    let normalizedLineWidth: CGFloat

    init(stroke: DotColourStroke) {
        normalizedLineWidth = stroke.normalizedLineWidth
        if stroke.points.count == 1 {
            normalizedPath = nil
            singlePoint = stroke.points.first
        } else if let first = stroke.points.first {
            var path = Path()
            path.move(to: first)
            for point in stroke.points.dropFirst() { path.addLine(to: point) }
            normalizedPath = path
            singlePoint = nil
        } else {
            normalizedPath = nil
            singlePoint = nil
        }
    }
}

private struct DotCommittedStrokeRenderGroup {
    let revision: Int
    let strokeIDs: [UUID]
    let paths: [DotCommittedStrokeRenderPath]
}

/// Groups committed paths by swatch and gives only a changed group a new revision. SwiftUI can
/// consequently retain every other masked Canvas layer when one region receives another stroke.
private struct DotCommittedStrokeRenderCache {
    private(set) var groups: [Int: DotCommittedStrokeRenderGroup] = [:]
    private var nextRevision = 0

    init(strokes: [DotColourStroke]) {
        replace(with: strokes)
    }

    mutating func replace(with strokes: [DotColourStroke]) {
        let grouped = Dictionary(grouping: strokes, by: \DotColourStroke.swatchID)
        let allSwatchIDs = Set(groups.keys).union(grouped.keys)

        for swatchID in allSwatchIDs {
            let nextStrokes = grouped[swatchID] ?? []
            let nextIDs = nextStrokes.map(\.id)
            if groups[swatchID]?.strokeIDs == nextIDs { continue }

            nextRevision += 1
            if nextStrokes.isEmpty {
                groups.removeValue(forKey: swatchID)
            } else {
                groups[swatchID] = DotCommittedStrokeRenderGroup(
                    revision: nextRevision,
                    strokeIDs: nextIDs,
                    paths: nextStrokes.map(DotCommittedStrokeRenderPath.init)
                )
            }
        }
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
    @State private var committedStrokeCache: DotCommittedStrokeRenderCache
    @State private var coverageAccumulators: [Int: DotColourCoverageAccumulator] = [:]
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
        _committedStrokeCache = State(
            initialValue: DotCommittedStrokeRenderCache(strokes: boundedStrokes)
        )
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
            let prewarmStartedAt = ProcessInfo.processInfo.systemUptime
            announce(DotColouringAccessibilityAnnouncementPolicy.opening(for: mode))
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
            let prewarmElapsed = ProcessInfo.processInfo.systemUptime - prewarmStartedAt
            if let readyAnnouncement = DotColouringAccessibilityAnnouncementPolicy.ready(
                afterPrewarm: prewarmElapsed,
                mode: mode
            ) {
                announce(readyAnnouncement, queueBehindExistingSpeech: true)
            }
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
                committedStrokeCache: committedStrokeCache,
                wrongRegionID: wrongRegionID,
                onTap: applyTap,
                onShadeBegin: beginShadeStroke,
                onShadeComplete: commitShadeStroke
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

    private func beginShadeStroke(_ point: CGPoint) -> Bool {
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
            return false
        }

        wrongRegionID = nil
        message = "Keep shading—your pencil stays inside \(swatchName(selectedSwatchID))."
        return true
    }

    private func commitShadeStroke(_ finished: DotColourStroke) {
        guard isMeaningfulInMaskStroke(finished) else {
            message = "Make a longer shading stroke inside the numbered space."
            FeedbackManager.shared.haptic(.light)
            announce(message ?? "Make a longer stroke")
            return
        }

        strokes.append(finished)
        strokes = DotColourStrokeSampler.bounded(strokes)
        committedStrokeCache.replace(with: strokes)

        let regionStrokes = strokes.filter { $0.regionID == finished.regionID }
        let coverage: CGFloat
        if let swatch = plan.swatches.first(where: { $0.id == finished.regionID }),
           var accumulator = coverageAccumulators[finished.regionID]
                ?? DotColourCoverageEvaluator.makeAccumulator(in: swatch.maskArt) {
            coverage = accumulator.replaceStrokes(regionStrokes)
            coverageAccumulators[finished.regionID] = accumulator
        } else {
            coverage = 0
        }

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
    }

    private func reset() {
        snapshotPersistenceTask?.cancel()
        snapshotPersistenceTask = nil
        pendingSnapshot = nil
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.20)) {
            progress.reset()
            strokes = []
            committedStrokeCache.replace(with: [])
            coverageAccumulators = [:]
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
        var restoredAccumulators: [Int: DotColourCoverageAccumulator] = [:]
        var shadedRegions: Set<Int> = []
        for swatch in plan.swatches {
            guard var accumulator = DotColourCoverageEvaluator.makeAccumulator(in: swatch.maskArt)
            else { continue }
            let coverage = accumulator.replaceStrokes(
                strokes.filter { $0.regionID == swatch.id }
            )
            restoredAccumulators[swatch.id] = accumulator
            if coverage >= DotColourCoverageEvaluator.completionThreshold {
                shadedRegions.insert(swatch.id)
            }
        }
        coverageAccumulators = restoredAccumulators
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

    private func announce(_ value: String, queueBehindExistingSpeech: Bool = false) {
        guard queueBehindExistingSpeech else {
            UIAccessibility.post(notification: .announcement, argument: value)
            return
        }

        let announcement = NSMutableAttributedString(string: value)
        let fullRange = NSRange(location: 0, length: announcement.length)
        if #available(iOS 17.0, *) {
            announcement.addAttribute(
                .accessibilitySpeechAnnouncementPriority,
                value: UIAccessibilityPriority.low,
                range: fullRange
            )
        } else {
            announcement.addAttribute(
                .accessibilitySpeechQueueAnnouncement,
                value: true,
                range: fullRange
            )
        }
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

private struct SemanticColourCanvas: View {
    let puzzle: DotPuzzle
    let plan: DotSemanticColourPlan
    let mode: DotColouringMode
    let selectedSwatchID: Int
    let tapFilledRegionIDs: Set<Int>
    let completedRegionIDs: Set<Int>
    let committedStrokeCache: DotCommittedStrokeRenderCache
    let wrongRegionID: Int?
    let onTap: (Int?) -> Void
    let onShadeBegin: (CGPoint) -> Bool
    let onShadeComplete: (DotColourStroke) -> Void

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
                    if let group = committedStrokeCache.groups[swatch.id] {
                        DotMaskedCommittedStrokeLayer(
                            group: group,
                            colorHex: swatch.hex,
                            maskArt: swatch.maskArt
                        )
                        .equatable()
                    }
                }

                if mode == .shade,
                   let selectedSwatch = plan.swatches.first(where: { $0.id == selectedSwatchID }) {
                    DotShadeTouchCapture(
                        swatchID: selectedSwatchID,
                        color: UIColor(Color(hex: selectedSwatch.hex)),
                        maskImage: DotSemanticMaskHitTester.croppedImage(for: selectedSwatch.maskArt),
                        onBegin: onShadeBegin,
                        onComplete: onShadeComplete
                    )
                    .accessibilityLabel("\(puzzle.title) shading canvas")
                    .accessibilityHint("Choose a numbered pot, then draw in its matching space with a finger or Apple Pencil")
                    .accessibilityAction(named: "Colour selected number") {
                        onTap(selectedSwatchID)
                    }
                }

                semanticLabels(in: geometry.size)

                DotColourLineArtworkView(puzzle: puzzle)

                if mode == .tapToFill {
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
}

private struct DotMaskedCommittedStrokeLayer: View, Equatable {
    let group: DotCommittedStrokeRenderGroup
    let colorHex: String
    let maskArt: DotPuzzleReferenceArt

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let transform = CGAffineTransform(scaleX: size.width, y: size.height)
            for renderPath in group.paths {
                let width = max(5, renderPath.normalizedLineWidth * side)

                if let normalizedPoint = renderPath.singlePoint {
                    let point = normalizedPoint.applying(transform)
                    let mark = CGRect(
                        x: point.x - width / 2,
                        y: point.y - width / 2,
                        width: width,
                        height: width
                    )
                    context.fill(
                        Path(ellipseIn: mark),
                        with: .color(Color(hex: colorHex).opacity(0.92))
                    )
                } else if let normalizedPath = renderPath.normalizedPath {
                    context.stroke(
                        normalizedPath.applying(transform),
                        with: .color(Color(hex: colorHex).opacity(0.92)),
                        style: StrokeStyle(
                            lineWidth: width,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }
        }
        .mask {
            DotColourAtlasTileView(art: maskArt, tint: .white)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.group.revision == rhs.group.revision
            && lhs.colorHex == rhs.colorHex
            && lhs.maskArt.assetName == rhs.maskArt.assetName
            && lhs.maskArt.column == rhs.maskArt.column
            && lhs.maskArt.row == rhs.maskArt.row
            && lhs.maskArt.columns == rhs.maskArt.columns
            && lhs.maskArt.rows == rhs.maskArt.rows
    }
}

/// Keeps the in-progress gesture, coalesced touch samples, and live CAShapeLayer entirely inside
/// UIKit. SwiftUI receives one begin decision and one immutable completed stroke instead of
/// rebuilding the whole colouring stage for every Pencil sample.
private struct DotShadeTouchCapture: UIViewRepresentable {
    let swatchID: Int
    let color: UIColor
    let maskImage: UIImage?
    let onBegin: (CGPoint) -> Bool
    let onComplete: (DotColourStroke) -> Void

    func makeUIView(context: Context) -> DotShadeTouchView {
        let view = DotShadeTouchView()
        update(view)
        return view
    }

    func updateUIView(_ uiView: DotShadeTouchView, context: Context) {
        update(uiView)
    }

    private func update(_ view: DotShadeTouchView) {
        view.configure(
            swatchID: swatchID,
            color: color,
            maskImage: maskImage,
            onBegin: onBegin,
            onComplete: onComplete
        )
    }
}

private final class DotShadeTouchView: UIView {
    private let strokeLayer = CAShapeLayer()
    private let maskLayer = CALayer()
    private var activeTouch: UITouch?
    private var activeStroke: DotColourStroke?
    private var configuredSwatchID: Int?
    private var configuredColor = UIColor.clear
    private var onBegin: ((CGPoint) -> Bool)?
    private var onComplete: ((DotColourStroke) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepareLayers()
    }

    func configure(
        swatchID: Int,
        color: UIColor,
        maskImage: UIImage?,
        onBegin: @escaping (CGPoint) -> Bool,
        onComplete: @escaping (DotColourStroke) -> Void
    ) {
        if configuredSwatchID != nil, configuredSwatchID != swatchID {
            cancelActiveStroke()
        }
        configuredSwatchID = swatchID
        configuredColor = color
        self.onBegin = onBegin
        self.onComplete = onComplete
        maskLayer.contents = maskImage?.cgImage
        maskLayer.contentsScale = maskImage?.scale ?? UIScreen.main.scale
        updateStrokeLayer()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        strokeLayer.frame = bounds
        maskLayer.frame = strokeLayer.bounds
        updateStrokeLayer()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil,
              bounds.width > 0,
              bounds.height > 0,
              let swatchID = configuredSwatchID,
              let touch = touches.first(where: {
                  TraceInputPolicy.accepts($0.type, pencilOnly: false)
              }) else { return }

        let point = normalized(touch.location(in: self))
        guard onBegin?(point) == true else { return }
        activeTouch = touch
        activeStroke = DotColourStroke(
            regionID: swatchID,
            swatchID: swatchID,
            points: [point]
        )
        updateStrokeLayer()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = matchingActiveTouch(in: touches), var stroke = activeStroke else {
            return
        }
        let samples = event?.coalescedTouches(for: touch) ?? [touch]
        var changed = false
        for sample in samples {
            changed = DotColourStrokeSampler.append(
                normalized(sample.location(in: self)),
                to: &stroke
            ) || changed
        }
        guard changed else { return }
        activeStroke = stroke
        updateStrokeLayer()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = matchingActiveTouch(in: touches), var stroke = activeStroke else {
            return
        }
        _ = DotColourStrokeSampler.append(normalized(touch.location(in: self)), to: &stroke)
        clearActiveStroke()
        onComplete?(stroke)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard matchingActiveTouch(in: touches) != nil else { return }
        cancelActiveStroke()
    }

    private func prepareLayers() {
        backgroundColor = .clear
        isOpaque = false
        isMultipleTouchEnabled = false
        strokeLayer.contentsScale = UIScreen.main.scale
        strokeLayer.lineCap = .round
        strokeLayer.lineJoin = .round
        strokeLayer.mask = maskLayer
        maskLayer.contentsGravity = .resize
        layer.addSublayer(strokeLayer)
    }

    private func updateStrokeLayer() {
        guard let stroke = activeStroke, let first = stroke.points.first else {
            strokeLayer.path = nil
            return
        }

        let lineWidth = max(5, stroke.normalizedLineWidth * min(bounds.width, bounds.height))
        strokeLayer.lineWidth = lineWidth
        strokeLayer.opacity = 0.92
        if stroke.points.count == 1 {
            let centre = denormalized(first)
            strokeLayer.fillColor = configuredColor.cgColor
            strokeLayer.strokeColor = nil
            strokeLayer.path = UIBezierPath(
                ovalIn: CGRect(
                    x: centre.x - lineWidth / 2,
                    y: centre.y - lineWidth / 2,
                    width: lineWidth,
                    height: lineWidth
                )
            ).cgPath
        } else {
            let path = UIBezierPath()
            path.move(to: denormalized(first))
            for point in stroke.points.dropFirst() { path.addLine(to: denormalized(point)) }
            strokeLayer.fillColor = nil
            strokeLayer.strokeColor = configuredColor.cgColor
            strokeLayer.path = path.cgPath
        }
    }

    private func cancelActiveStroke() {
        clearActiveStroke()
    }

    private func clearActiveStroke() {
        activeTouch = nil
        activeStroke = nil
        strokeLayer.path = nil
    }

    private func matchingActiveTouch(in touches: Set<UITouch>) -> UITouch? {
        guard let activeTouch else { return nil }
        return touches.first(where: { $0 === activeTouch })
    }

    private func normalized(_ point: CGPoint) -> CGPoint {
        DotColouringInteractionPolicy.normalizedPoint(point, in: bounds.size)
    }

    private func denormalized(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * bounds.width, y: point.y * bounds.height)
    }
}

/// Renders one independently shipped transparent tile. The same primitive renders semantic masks
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
/// each direct tile, so a tap or Pencil start can identify spots, body, detail or background without
/// reducing them to generic vertical strips.
enum DotSemanticMaskHitTester {
    static let maximumCacheCostBytes = 24 * 1_024 * 1_024

    private final class Bitmap {
        let width: Int
        let height: Int
        let alpha: [UInt8]
        let coverageMask: DotColourCoverageMask
        let image: UIImage

        init(width: Int, height: Int, alpha: [UInt8], image: UIImage) {
            self.width = width
            self.height = height
            self.alpha = alpha
            coverageMask = DotColourCoverageMask(width: width, height: height, alpha: alpha)
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

    static func coverageMask(for art: DotPuzzleReferenceArt) -> DotColourCoverageMask? {
        bitmap(for: art)?.coverageMask
    }

    /// Every colouring tile is shipped independently so semantic colouring never asks ImageIO to
    /// decode a 2560×1536 worksheet just to retain one 512×512 square.
    static func tileAssetName(for art: DotPuzzleReferenceArt) -> String {
        "\(art.assetName)_tile_r\(art.row)_c\(art.column)"
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
                  let tile = UIImage(named: tileAssetName(for: art))?.cgImage else { return nil }

            let tileWidth = tile.width
            let tileHeight = tile.height
            guard tileWidth > 0, tileHeight > 0 else { return nil }

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
