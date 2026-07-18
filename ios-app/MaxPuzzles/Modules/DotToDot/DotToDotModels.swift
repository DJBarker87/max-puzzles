import Foundation
import SwiftUI

enum DotInteractionMode: String, CaseIterable, Identifiable, Sendable {
    case tap
    case trace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tap: return "Tap dots"
        case .trace: return "Trace lines"
        }
    }

    var shortInstruction: String {
        switch self {
        case .tap: return "Press the next number"
        case .trace: return "Draw from the last dot to the next"
        }
    }

    var icon: String {
        switch self {
        case .tap: return "hand.tap.fill"
        case .trace: return "pencil.and.outline"
        }
    }
}

/// Serialises persistence work for one Dot-to-Dot activity without making interaction wait for
/// UserDefaults. Registering a write is synchronous on the main actor, so a newly presented view
/// can drain the resource before it creates a replacement session token. This closes the narrow
/// close/reopen race where an older unstructured Task used to arrive just after `beginSession`.
@MainActor
final class DotToDotPersistenceQueue {
    static let shared = DotToDotPersistenceQueue()

    enum Resource: Hashable {
        case connection(
            puzzleID: String,
            profileID: UUID?,
            interactionMode: DotInteractionMode
        )
        case colouring(puzzleID: String, profileID: UUID?)
    }

    private struct Entry {
        let id: UUID
        let task: Task<Void, Never>
    }

    private var entries: [Resource: Entry] = [:]

    /// Adds work to the resource's FIFO and returns a handle callers may await at a durability
    /// boundary such as Close or Finished. Normal taps only enqueue, keeping the UI responsive.
    @discardableResult
    func enqueue(
        for resource: Resource,
        operation: @escaping () async -> Void
    ) -> Task<Void, Never> {
        let previous = entries[resource]?.task
        let id = UUID()
        let task = Task { @MainActor [weak self] in
            await previous?.value
            await operation()
            guard let self, self.entries[resource]?.id == id else { return }
            self.entries.removeValue(forKey: resource)
        }
        entries[resource] = Entry(id: id, task: task)
        return task
    }

    /// Waits for every write registered for this resource, including work appended while an
    /// earlier operation is suspended in its persistence actor.
    func drain(_ resource: Resource) async {
        while let task = entries[resource]?.task {
            await task.value
        }
    }
}

/// SwiftUI restarts a `.task(id:)` only when its identity changes. Including load state ensures a
/// fresh puzzle moves from `(not loaded, 0)` to `(loaded, 0)` and therefore schedules dot 1's hint.
struct DotToDotAutomaticHintTaskID: Equatable {
    let hasLoadedConnectionProgress: Bool
    let currentIndex: Int
}

/// Persists an unfinished numbered trail without ever making the main actor wait for disk-backed
/// preferences. A session token prevents a delayed write from an old screen from bringing back
/// progress after the child has completed or restarted the picture.
actor DotToDotProgressStore {
    static let shared = DotToDotProgressStore()

    struct Session: Equatable, Sendable {
        let token: UUID
        let currentIndex: Int
        let recoveredFromCorruptData: Bool
    }

    private struct Envelope: Codable {
        let token: UUID
        var currentIndex: Int
        var acceptsUpdates: Bool
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func beginSession(
        puzzleID: String,
        profileID: UUID?,
        interactionMode: DotInteractionMode,
        pointCount: Int
    ) -> Session {
        let storageKey = key(
            puzzleID: puzzleID,
            profileID: profileID,
            interactionMode: interactionMode
        )
        let decoded = decodeEnvelope(forKey: storageKey)
        let restoredIndex: Int
        if let envelope = decoded.envelope,
           envelope.acceptsUpdates,
           envelope.currentIndex > 0,
           envelope.currentIndex < pointCount {
            restoredIndex = envelope.currentIndex
        } else {
            restoredIndex = 0
        }

        let token = UUID()
        persist(
            Envelope(token: token, currentIndex: restoredIndex, acceptsUpdates: true),
            forKey: storageKey
        )
        return Session(
            token: token,
            currentIndex: restoredIndex,
            recoveredFromCorruptData: decoded.wasCorrupt
        )
    }

    /// Returns false when the write belongs to a screen that has already completed, restarted,
    /// or been superseded by a newer presentation of the same activity.
    @discardableResult
    func save(
        currentIndex: Int,
        puzzleID: String,
        profileID: UUID?,
        interactionMode: DotInteractionMode,
        pointCount: Int,
        sessionToken: UUID
    ) -> Bool {
        guard currentIndex > 0, currentIndex < pointCount else { return false }
        let storageKey = key(
            puzzleID: puzzleID,
            profileID: profileID,
            interactionMode: interactionMode
        )
        guard let existing = decodeEnvelope(forKey: storageKey).envelope,
              existing.token == sessionToken,
              existing.acceptsUpdates else { return false }
        persist(
            Envelope(
                token: sessionToken,
                currentIndex: max(existing.currentIndex, currentIndex),
                acceptsUpdates: true
            ),
            forKey: storageKey
        )
        return true
    }

    /// Closes the current session. Keeping a tiny tombstone instead of deleting the key means a
    /// delayed save carrying the same token is safely rejected.
    @discardableResult
    func clear(
        puzzleID: String,
        profileID: UUID?,
        interactionMode: DotInteractionMode,
        sessionToken: UUID
    ) -> Bool {
        let storageKey = key(
            puzzleID: puzzleID,
            profileID: profileID,
            interactionMode: interactionMode
        )
        guard let existing = decodeEnvelope(forKey: storageKey).envelope,
              existing.token == sessionToken else { return false }
        persist(
            Envelope(token: sessionToken, currentIndex: 0, acceptsUpdates: false),
            forKey: storageKey
        )
        return true
    }

    /// Starts a clean, writable session and invalidates every outstanding write from the old one.
    func restart(
        puzzleID: String,
        profileID: UUID?,
        interactionMode: DotInteractionMode,
        sessionToken: UUID?
    ) -> Session? {
        let storageKey = key(
            puzzleID: puzzleID,
            profileID: profileID,
            interactionMode: interactionMode
        )
        if let sessionToken,
           let existing = decodeEnvelope(forKey: storageKey).envelope,
           existing.token != sessionToken {
            return nil
        }
        let token = UUID()
        persist(
            Envelope(token: token, currentIndex: 0, acceptsUpdates: true),
            forKey: storageKey
        )
        return Session(token: token, currentIndex: 0, recoveredFromCorruptData: false)
    }

    private func decodeEnvelope(forKey storageKey: String) -> (envelope: Envelope?, wasCorrupt: Bool) {
        guard let data = defaults.data(forKey: storageKey) else { return (nil, false) }
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else {
            defaults.removeObject(forKey: storageKey)
            return (nil, true)
        }
        return (envelope, false)
    }

    private func persist(_ envelope: Envelope, forKey storageKey: String) {
        guard let data = try? JSONEncoder().encode(envelope) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func key(
        puzzleID: String,
        profileID: UUID?,
        interactionMode: DotInteractionMode
    ) -> String {
        let profileComponent = profileID?.uuidString ?? "guest"
        return "maxpuzzles.profile.\(profileComponent).dotToDot.connectionProgress.v1.\(interactionMode.rawValue).\(puzzleID)"
    }
}

enum DotToDotRestartPolicy {
    static func requiresConfirmation(currentIndex: Int) -> Bool {
        currentIndex > 0
    }
}

enum DotToDotTier: String, CaseIterable, Identifiable {
    case firstDots
    case numberTrail
    case numberExplorer
    case bigNumberAdventure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstDots: return "First Dots"
        case .numberTrail: return "Number Trail"
        case .numberExplorer: return "Number Explorer"
        case .bigNumberAdventure: return "Big Number Adventure"
        }
    }

    var subtitle: String {
        switch self {
        case .firstDots: return "A gentle start"
        case .numberTrail: return "Growing confidence"
        case .numberExplorer: return "Numbers to 20"
        case .bigNumberAdventure: return "A special challenge"
        }
    }

    var maxNumeral: Int {
        switch self {
        case .firstDots: return 10
        case .numberTrail: return 15
        case .numberExplorer: return 20
        case .bigNumberAdventure: return 25
        }
    }

    var automaticHintDelay: TimeInterval {
        switch self {
        case .firstDots: return 3.5
        case .numberTrail: return 5
        case .numberExplorer: return 7
        case .bigNumberAdventure: return 9
        }
    }

    var rangeLabel: String { "1–\(maxNumeral)" }

    var color: Color {
        switch self {
        case .firstDots: return Color(hex: "5eead4")
        case .numberTrail: return Color(hex: "fbbf24")
        case .numberExplorer: return Color(hex: "c084fc")
        case .bigNumberAdventure: return Color(hex: "fb7185")
        }
    }

    var icon: String {
        switch self {
        case .firstDots: return "1.circle.fill"
        case .numberTrail: return "circle.grid.2x2.fill"
        case .numberExplorer: return "circle.grid.3x3.fill"
        case .bigNumberAdventure: return "sparkles"
        }
    }
}

enum DotPuzzlePalette: CaseIterable {
    case aqua
    case gold
    case coral
    case violet
    case lime
    case sky

    var primary: Color {
        switch self {
        case .aqua: return Color(hex: "2dd4bf")
        case .gold: return Color(hex: "fbbf24")
        case .coral: return Color(hex: "fb7185")
        case .violet: return Color(hex: "c084fc")
        case .lime: return Color(hex: "a3e635")
        case .sky: return Color(hex: "38bdf8")
        }
    }

    var secondary: Color {
        switch self {
        case .aqua: return Color(hex: "0f766e")
        case .gold: return Color(hex: "d97706")
        case .coral: return Color(hex: "be123c")
        case .violet: return Color(hex: "7e22ce")
        case .lime: return Color(hex: "4d7c0f")
        case .sky: return Color(hex: "0369a1")
        }
    }
}

/// A square tile inside one of the downloaded-art atlases.
struct DotPuzzleReferenceArt {
    let assetName: String
    let column: Int
    let row: Int
    let columns: Int
    let rows: Int
}

struct DotPuzzle: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let tier: DotToDotTier
    let palette: DotPuzzlePalette
    let points: [CGPoint]
    let revealOutline: [CGPoint]
    let guidePaths: [[CGPoint]]
    let detailPaths: [[CGPoint]]
    let sourceSheet: String?
    let referenceArt: DotPuzzleReferenceArt?

    init(
        id: String,
        title: String,
        emoji: String,
        tier: DotToDotTier,
        palette: DotPuzzlePalette,
        outline: [CGPoint],
        trail: [CGPoint]? = nil,
        guidePaths: [[CGPoint]] = [],
        detailPaths: [[CGPoint]] = [],
        sourceSheet: String? = nil,
        referenceArt: DotPuzzleReferenceArt? = nil
    ) {
        let numberedTrail = trail ?? outline
        precondition(
            numberedTrail.count == tier.maxNumeral,
            "\(id) must provide exactly \(tier.maxNumeral) extracted trail points"
        )

        self.id = id
        self.title = title
        self.emoji = emoji
        self.tier = tier
        self.palette = palette
        self.sourceSheet = sourceSheet
        self.referenceArt = referenceArt
        self.guidePaths = guidePaths
        self.detailPaths = detailPaths
        self.points = DotPuzzleGeometry.withMeaningfulNumeralStart(numberedTrail)
        // The exterior is only revealed after every numbered segment is joined.
        self.revealOutline = self.points
    }
}

enum DotPuzzleCatalog {
    /// The public catalogue is the 84 audited pictures extracted from d1–d7. There is no generic
    /// strip-colouring fallback and no hidden legacy pack mixed into progress totals.
    static let all: [DotPuzzle] = downloadedReferencePuzzles
    static let validPuzzleIDs = Set(all.map(\.id))
    static let availableTiers = DotToDotTier.allCases.filter { !puzzles(in: $0).isEmpty }

    static func puzzles(in tier: DotToDotTier) -> [DotPuzzle] {
        all.filter { $0.tier == tier }
    }

    /// Old pre-release IDs can remain in storage without inflating the visible 84-picture total.
    static func sanitizedCompletedIDs(_ IDs: Set<String>) -> Set<String> {
        IDs.intersection(validPuzzleIDs)
    }
}

enum DotPuzzleGeometry {
    /// Number of moments where a later dot is as spatially plausible as the true next dot. It is
    /// a QA signal rather than a scoring rule; the spoken numeral always identifies the target.
    static func meaningfulChoiceCount(in points: [CGPoint]) -> Int {
        guard points.count >= 3 else { return 0 }
        return (0..<(points.count - 2)).reduce(into: 0) { count, index in
            let nextDistance = distance(points[index], points[index + 1])
            let hasPlausibleAlternative = points[(index + 2)...].contains {
                distance(points[index], $0) <= nextDistance * 1.18
            }
            if hasPlausibleAlternative { count += 1 }
        }
    }

    /// Rotate a closed extracted trail when that improves the numeral-search challenge, without
    /// inventing or regenerating any geometry from the downloaded picture.
    static func withMeaningfulNumeralStart(_ points: [CGPoint]) -> [CGPoint] {
        guard meaningfulChoiceCount(in: points) == 0, points.count >= 3 else { return points }
        for offset in 1..<points.count {
            let rotated = Array(points[offset...]) + Array(points[..<offset])
            if meaningfulChoiceCount(in: rotated) > 0 { return rotated }
        }
        return points
    }

    private static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}

enum SubitizingChallenge {
    static func quantity(for puzzleID: String) -> Int {
        let value = puzzleID.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return value % 5 + 1
    }

    static func choices(for quantity: Int, puzzleID: String) -> [Int] {
        let rawChoices = [quantity, quantity % 5 + 1, (quantity + 2) % 5 + 1]
        let rotation = puzzleID.count % rawChoices.count
        return Array(rawChoices[rotation...] + rawChoices[..<rotation])
    }

    static func pattern(for quantity: Int) -> [CGPoint] {
        switch quantity {
        case 1:
            return [CGPoint(x: 0.50, y: 0.50)]
        case 2:
            return [CGPoint(x: 0.30, y: 0.30), CGPoint(x: 0.70, y: 0.70)]
        case 3:
            return [
                CGPoint(x: 0.28, y: 0.28), CGPoint(x: 0.50, y: 0.50),
                CGPoint(x: 0.72, y: 0.72)
            ]
        case 4:
            return [
                CGPoint(x: 0.28, y: 0.28), CGPoint(x: 0.72, y: 0.28),
                CGPoint(x: 0.28, y: 0.72), CGPoint(x: 0.72, y: 0.72)
            ]
        default:
            return [
                CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25),
                CGPoint(x: 0.50, y: 0.50), CGPoint(x: 0.25, y: 0.75),
                CGPoint(x: 0.75, y: 0.75)
            ]
        }
    }
}
