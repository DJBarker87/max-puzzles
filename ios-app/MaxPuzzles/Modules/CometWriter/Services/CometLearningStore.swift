import Foundation

/// UserDefaults documents thread-safe access. This narrow wrapper makes that guarantee explicit
/// when immutable learning snapshots are encoded and stored on the serial persistence queue.
private final class CometPersistenceDefaults: @unchecked Sendable {
    let value: UserDefaults

    init(_ value: UserDefaults) {
        self.value = value
    }
}

enum WritingHand: String, Codable, CaseIterable, Identifiable, Sendable {
    case right
    case left

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum CometActivityMode: String, Codable, CaseIterable, Sendable {
    case guided
    case recall
    case word
    case phonics
    case alienMail
    case flightSchool
    case paperTransfer
    case dailyMission

    var title: String {
        switch self {
        case .guided: return "Guided practice"
        case .recall: return "Letter recall"
        case .word: return "Word mission"
        case .phonics: return "Letter sound mission"
        case .alienMail: return "Alien Mail"
        case .flightSchool: return "Flight School"
        case .paperTransfer: return "Paper transfer"
        case .dailyMission: return "Daily mission bonus"
        }
    }
}

struct CometChildProfile: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var writingHand: WritingHand
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        writingHand: WritingHand = .right,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.writingHand = writingHand
        self.createdAt = createdAt
    }
}

struct CometCustomWord: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let profileID: UUID
    var text: String
    var contextSentence: String?
    var recordingFilename: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        profileID: UUID,
        text: String,
        contextSentence: String? = nil,
        recordingFilename: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.profileID = profileID
        self.text = text
        self.contextSentence = contextSentence
        self.recordingFilename = recordingFilename
        self.createdAt = createdAt
    }
}

struct CometCustomWordImportResult: Equatable, Sendable {
    let addedWords: [String]
    let invalidCount: Int
    let duplicateCount: Int
    let overflowCount: Int

    var skippedCount: Int {
        invalidCount + duplicateCount + overflowCount
    }
}

struct StoredLetterPoint: Codable, Hashable, Sendable {
    let x: Double
    let y: Double

    init(_ point: LetterPoint) {
        x = Double(point.x)
        y = Double(point.y)
    }

    var letterPoint: LetterPoint {
        LetterPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

struct CometAttemptRecord: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let profileID: UUID
    let character: String
    let mode: CometActivityMode
    let score: Int
    let breakdown: CometScoreBreakdown
    let correctionCounts: [String: Int]
    let usedHint: Bool
    let wasIndependent: Bool
    let pointsEarned: Int
    let timestamp: Date
    let traces: [[StoredLetterPoint]]
}

struct StarSpellerAttemptRecord: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let profileID: UUID
    let word: String
    let checkAttempts: Int
    let errorCount: Int
    let hintUses: Int
    let wasSuccessful: Bool
    let pointsEarned: Int
    let timestamp: Date
}

struct StarSpellerSessionSnapshot: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let profileID: UUID
    let words: [String]
    var currentIndex: Int
    var score: Int?
    var currentWordIsReadyToWrite: Bool?
    let startedAt: Date

    init(
        id: UUID = UUID(),
        profileID: UUID,
        words: [String],
        currentIndex: Int,
        score: Int = 0,
        currentWordIsReadyToWrite: Bool = false,
        startedAt: Date = Date()
    ) {
        self.id = id
        self.profileID = profileID
        self.words = words
        self.currentIndex = currentIndex
        self.score = score
        self.currentWordIsReadyToWrite = currentWordIsReadyToWrite
        self.startedAt = startedAt
    }
}

struct StarSpellerWordProgress: Identifiable, Sendable {
    let word: String
    let mastery: CometMasteryLevel
    let attempts: Int
    let successes: Int
    let errors: Int
    let hints: Int
    let lastPractisedAt: Date

    var id: String { word }
}

struct StarSpellerProfileSummary: Sendable {
    let totalAttempts: Int
    let successfulAttempts: Int
    let firstTrySuccesses: Int
    let totalErrors: Int
    let totalHints: Int
    let practisedWords: Int
    let secureWords: Int
    let masteredWords: Int

    var firstTryPercentage: Int {
        guard successfulAttempts > 0 else { return 0 }
        return Int(
            (Double(firstTrySuccesses) / Double(successfulAttempts) * 100).rounded()
        )
    }
}

/// Serialises and coalesces the two large, local-only history streams. The shipping app stores
/// them as atomic files rather than copying multi-megabyte JSON blobs through UserDefaults;
/// isolated test stores retain the legacy target for deterministic in-memory tests.
private final class CometDetailedHistoryPersistence: @unchecked Sendable {
    struct LoadResult: Sendable {
        let attempts: [CometAttemptRecord]
        let spellingAttempts: [StarSpellerAttemptRecord]
        let attemptsCameFromLegacyDefaults: Bool
        let spellingAttemptsCameFromLegacyDefaults: Bool
        let recoveredCorruptAttemptsFile: Bool
        let recoveredCorruptSpellingAttemptsFile: Bool
        let attemptsWritesBlocked: Bool
        let spellingAttemptsWritesBlocked: Bool
    }

    private enum Target {
        case defaults(CometPersistenceDefaults)
        case files(directory: URL, legacyDefaults: CometPersistenceDefaults)
    }

    private enum Stream {
        case attempts
        case spellingAttempts
    }

    private let target: Target
    private let queue = DispatchQueue(
        label: "com.maxpuzzles.learning-history-persistence",
        qos: .utility
    )
    private var pendingAttempts: [CometAttemptRecord]?
    private var pendingSpellingAttempts: [StarSpellerAttemptRecord]?
    private var drainScheduled = false
    private var writeBlockedStreams = Set<Stream>()

    private static let attemptsFilename = "writing-attempts.json"
    private static let spellingAttemptsFilename = "spelling-attempts.json"
    private static let attemptsDefaultsKey = "maxpuzzles.cometWriter.attempts"
    private static let spellingAttemptsDefaultsKey = "maxpuzzles.starSpeller.attempts"

    init(defaults: CometPersistenceDefaults, directory: URL?) {
        if let directory {
            target = .files(directory: directory, legacyDefaults: defaults)
        } else {
            target = .defaults(defaults)
        }
    }

    func loadSynchronously() -> LoadResult {
        queue.sync { load() }
    }

    func load(
        completion: @escaping @Sendable (LoadResult) -> Void
    ) {
        queue.async { [self] in
            completion(load())
        }
    }

    func enqueue(attempts: [CometAttemptRecord]) {
        queue.async { [self] in
            pendingAttempts = attempts
            scheduleDrainIfNeeded()
        }
    }

    func enqueue(spellingAttempts: [StarSpellerAttemptRecord]) {
        queue.async { [self] in
            pendingSpellingAttempts = spellingAttempts
            scheduleDrainIfNeeded()
        }
    }

    func waitForPendingWrites() async {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                drainNow()
                continuation.resume()
            }
        }
    }

    /// A confirmed destructive reset is the only operation allowed to replace a history file
    /// that could not be decoded or safely quarantined.
    func resetHistories() {
        queue.async { [self] in
            writeBlockedStreams.removeAll()
            pendingAttempts = []
            pendingSpellingAttempts = []
            drainNow()
        }
    }

    private func scheduleDrainIfNeeded() {
        guard !drainScheduled else { return }
        drainScheduled = true
        // A short debounce collapses rapid lesson updates into one full-history encode.
        queue.asyncAfter(deadline: .now() + 0.12) { [self] in
            guard drainScheduled else { return }
            drainNow()
        }
    }

    private func drainNow() {
        drainScheduled = false
        let attempts = pendingAttempts
        let spellingAttempts = pendingSpellingAttempts
        pendingAttempts = nil
        pendingSpellingAttempts = nil

        if let attempts,
           !writeBlockedStreams.contains(.attempts),
           let data = try? JSONEncoder().encode(attempts) {
            write(data, stream: .attempts)
        }
        if let spellingAttempts,
           !writeBlockedStreams.contains(.spellingAttempts),
           let data = try? JSONEncoder().encode(spellingAttempts) {
            write(data, stream: .spellingAttempts)
        }
    }

    private func load() -> LoadResult {
        let attempts = load([CometAttemptRecord].self, stream: .attempts)
        let spelling = load([StarSpellerAttemptRecord].self, stream: .spellingAttempts)
        if attempts.blocksWrites { writeBlockedStreams.insert(.attempts) }
        if spelling.blocksWrites { writeBlockedStreams.insert(.spellingAttempts) }
        return LoadResult(
            attempts: attempts.value,
            spellingAttempts: spelling.value,
            attemptsCameFromLegacyDefaults: attempts.fromLegacyDefaults,
            spellingAttemptsCameFromLegacyDefaults: spelling.fromLegacyDefaults,
            recoveredCorruptAttemptsFile: attempts.recoveredCorruptFile,
            recoveredCorruptSpellingAttemptsFile: spelling.recoveredCorruptFile,
            attemptsWritesBlocked: attempts.blocksWrites,
            spellingAttemptsWritesBlocked: spelling.blocksWrites
        )
    }

    private func load<Value: Decodable>(
        _ type: Value.Type,
        stream: Stream
    ) -> (
        value: Value,
        fromLegacyDefaults: Bool,
        recoveredCorruptFile: Bool,
        blocksWrites: Bool
    ) where Value: RangeReplaceableCollection {
        let decoder = JSONDecoder()
        switch target {
        case .defaults(let defaults):
            let data = defaults.value.data(forKey: defaultsKey(for: stream))
            guard let data else { return (Value(), false, false, false) }
            guard let decoded = try? decoder.decode(type, from: data) else {
                // Preserve an unreadable isolated-test/defaults blob instead of replacing it with
                // an empty history on the next child action.
                return (Value(), false, false, true)
            }
            return (decoded, false, false, false)

        case .files(let directory, let legacyDefaults):
            // A legacy value is present only before migration or after a newer file write failed;
            // every successful atomic file write removes it. It is therefore authoritative when
            // both sources exist.
            let legacyData = legacyDefaults.value.data(forKey: defaultsKey(for: stream))
            if let legacyData,
               let decoded = try? decoder.decode(type, from: legacyData) {
                return (decoded, true, false, false)
            }

            let url = fileURL(in: directory, for: stream)
            guard FileManager.default.fileExists(atPath: url.path) else {
                // A corrupt legacy blob is left untouched and blocks future writes just as a
                // corrupt file would.
                return (Value(), false, false, legacyData != nil)
            }

            if let data = try? Data(contentsOf: url),
               let decoded = try? decoder.decode(type, from: data) {
                return (decoded, false, false, false)
            }

            // Keep the unreadable bytes for support/recovery. Once safely quarantined, a fresh
            // history can be written without ever overwriting the damaged source.
            let quarantineURL = url
                .deletingPathExtension()
                .appendingPathExtension("corrupt-\(UUID().uuidString).json")
            do {
                try FileManager.default.moveItem(at: url, to: quarantineURL)
                return (Value(), false, true, false)
            } catch {
                return (Value(), false, false, true)
            }
        }
    }

    private func write(_ data: Data, stream: Stream) {
        switch target {
        case .defaults(let defaults):
            defaults.value.set(data, forKey: defaultsKey(for: stream))

        case .files(let directory, let legacyDefaults):
            do {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                try data.write(to: fileURL(in: directory, for: stream), options: .atomic)
                // Remove the old blob only after its atomic replacement is durable.
                legacyDefaults.value.removeObject(forKey: defaultsKey(for: stream))
            } catch {
                // Preserve durability if Application Support is temporarily unavailable. A later
                // launch migrates this fallback blob through the same atomic path.
                legacyDefaults.value.set(data, forKey: defaultsKey(for: stream))
            }
        }
    }

    private func fileURL(in directory: URL, for stream: Stream) -> URL {
        directory.appendingPathComponent(
            stream == .attempts ? Self.attemptsFilename : Self.spellingAttemptsFilename,
            isDirectory: false
        )
    }

    private func defaultsKey(for stream: Stream) -> String {
        stream == .attempts
            ? Self.attemptsDefaultsKey
            : Self.spellingAttemptsDefaultsKey
    }
}

enum CometMasteryLevel: Int, Comparable, Sendable {
    case new
    case practising
    case secure
    case mastered

    static func < (lhs: CometMasteryLevel, rhs: CometMasteryLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .new: return "New"
        case .practising: return "Practising"
        case .secure: return "Secure"
        case .mastered: return "Mastered"
        }
    }
}

/// Local-only learning records. Traces are deliberately downsampled and capped so progress
/// reporting stays responsive and detailed history files never grow without bound.
@MainActor
final class CometLearningStore: ObservableObject {
    static let shared = CometLearningStore(
        detailedHistoryDirectory: applicationSupportHistoryDirectory,
        deferDetailedHistoryLoad: true
    )
    static let maximumCustomWords = 100
    nonisolated static let maximumCustomWordLength = 10
    nonisolated static let maximumContextSentenceLength = 160

    @Published private(set) var profiles: [CometChildProfile]
    @Published private(set) var activeProfileID: UUID
    @Published private(set) var customWords: [CometCustomWord]
    @Published private var storedAttempts: [CometAttemptRecord]
    @Published private var storedSpellingAttempts: [StarSpellerAttemptRecord]
    @Published private(set) var spellingSessions: [StarSpellerSessionSnapshot]
    @Published private(set) var detailedHistoriesAreLoaded: Bool
    @Published private(set) var recoveredDamagedDetailedHistory = false
    @Published private(set) var detailedHistoryNeedsAttention = false

    var attempts: [CometAttemptRecord] {
        return storedAttempts
    }

    var spellingAttempts: [StarSpellerAttemptRecord] {
        return storedSpellingAttempts
    }

    static let coreWords = [
        "a", "I", "am", "an", "as", "at", "be", "by", "go", "he", "in", "is", "it", "me",
        "my", "no", "of", "on", "or", "so", "to", "up", "us", "we", "cat", "dog", "sun",
        "fish", "moon", "book", "star", "home", "mum", "dad", "and", "can", "get", "big",
        "red", "run", "look", "see", "the", "this", "that", "with", "from", "play", "school",
        "friend", "rocket", "comet", "space", "planet"
    ].map { $0.lowercased() }

    private enum Keys {
        static let profiles = "maxpuzzles.cometWriter.profiles"
        static let activeProfileID = "maxpuzzles.cometWriter.activeProfileID"
        static let customWords = "maxpuzzles.cometWriter.customWords"
        static let attempts = "maxpuzzles.cometWriter.attempts"
        static let spellingAttempts = "maxpuzzles.starSpeller.attempts"
        static let spellingSessions = "maxpuzzles.starSpeller.sessions"
    }

    private let defaults: UserDefaults
    private let detailedHistoryPersistence: CometDetailedHistoryPersistence
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var detailedHistoriesLoaded: Bool
    private var detailedHistoryLoadStarted = false
    private var detailedHistoryLoadGeneration = 0
    private var detailedHistoryLoadWaiters: [CheckedContinuation<Void, Never>] = []
    private var profileIDsPendingHistoryDeletion = Set<UUID>()

    nonisolated private static var applicationSupportHistoryDirectory: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("MaxPuzzles", isDirectory: true)
            .appendingPathComponent("LearningHistory", isDirectory: true)
    }

    init(
        defaults: UserDefaults = .standard,
        detailedHistoryDirectory: URL? = nil,
        deferDetailedHistoryLoad: Bool = false
    ) {
        self.defaults = defaults
        let wrappedDefaults = CometPersistenceDefaults(defaults)
        detailedHistoryPersistence = CometDetailedHistoryPersistence(
            defaults: wrappedDefaults,
            directory: detailedHistoryDirectory
        )

        let decodedProfiles: [CometChildProfile] = Self.decode(
            [CometChildProfile].self,
            from: defaults.data(forKey: Keys.profiles),
            using: decoder
        ) ?? []

        let defaultName = StorageService.shared.playerName.isEmpty
            ? "Explorer"
            : StorageService.shared.playerName
        let resolvedProfiles = decodedProfiles.isEmpty
            ? [CometChildProfile(name: defaultName)]
            : decodedProfiles
        profiles = resolvedProfiles

        if let idString = defaults.string(forKey: Keys.activeProfileID),
           let savedID = UUID(uuidString: idString),
           resolvedProfiles.contains(where: { $0.id == savedID }) {
            activeProfileID = savedID
        } else {
            activeProfileID = resolvedProfiles[0].id
        }

        customWords = Self.decode(
            [CometCustomWord].self,
            from: defaults.data(forKey: Keys.customWords),
            using: decoder
        ) ?? []
        if deferDetailedHistoryLoad {
            storedAttempts = []
            storedSpellingAttempts = []
            detailedHistoriesLoaded = false
            detailedHistoriesAreLoaded = false
        } else {
            let histories = detailedHistoryPersistence.loadSynchronously()
            storedAttempts = Self.cappedAttempts(histories.attempts)
            storedSpellingAttempts = Self.cappedSpellingAttempts(histories.spellingAttempts)
            detailedHistoriesLoaded = true
            detailedHistoriesAreLoaded = true
            recoveredDamagedDetailedHistory = histories.recoveredCorruptAttemptsFile
                || histories.recoveredCorruptSpellingAttemptsFile
            detailedHistoryNeedsAttention = histories.attemptsWritesBlocked
                || histories.spellingAttemptsWritesBlocked
        }
        spellingSessions = Self.decode(
            [StarSpellerSessionSnapshot].self,
            from: defaults.data(forKey: Keys.spellingSessions),
            using: decoder
        ) ?? []

        if decodedProfiles.isEmpty {
            persistProfiles()
        } else if defaults.string(forKey: Keys.activeProfileID) != activeProfileID.uuidString {
            defaults.set(activeProfileID.uuidString, forKey: Keys.activeProfileID)
        }
    }

    private func installDetailedHistories(
        _ result: CometDetailedHistoryPersistence.LoadResult
    ) {
        let pendingWriting = storedAttempts
        let pendingSpelling = storedSpellingAttempts
        let deletedProfileIDs = profileIDsPendingHistoryDeletion
        let writingIDs = Set(result.attempts.map(\.id))
        let spellingIDs = Set(result.spellingAttempts.map(\.id))
        let mergedWriting = result.attempts.filter {
            !deletedProfileIDs.contains($0.profileID)
        } + pendingWriting.filter { !writingIDs.contains($0.id) }
        let mergedSpelling = result.spellingAttempts.filter {
            !deletedProfileIDs.contains($0.profileID)
        } + pendingSpelling.filter { !spellingIDs.contains($0.id) }
        let cappedWriting = Self.cappedAttempts(mergedWriting)
        let cappedSpelling = Self.cappedSpellingAttempts(mergedSpelling)
        storedAttempts = cappedWriting
        storedSpellingAttempts = cappedSpelling
        detailedHistoriesLoaded = true
        detailedHistoriesAreLoaded = true
        resumeDetailedHistoryLoadWaiters()
        profileIDsPendingHistoryDeletion.removeAll()
        recoveredDamagedDetailedHistory = result.recoveredCorruptAttemptsFile
            || result.recoveredCorruptSpellingAttemptsFile
        detailedHistoryNeedsAttention = result.attemptsWritesBlocked
            || result.spellingAttemptsWritesBlocked

        if result.attemptsCameFromLegacyDefaults
            || cappedWriting.count != result.attempts.count
            || !pendingWriting.isEmpty
            || !deletedProfileIDs.isEmpty {
            detailedHistoryPersistence.enqueue(attempts: cappedWriting)
        }
        if result.spellingAttemptsCameFromLegacyDefaults
            || cappedSpelling.count != result.spellingAttempts.count
            || !pendingSpelling.isEmpty
            || !deletedProfileIDs.isEmpty {
            detailedHistoryPersistence.enqueue(spellingAttempts: cappedSpelling)
        }
    }

    var activeProfile: CometChildProfile {
        profiles.first(where: { $0.id == activeProfileID }) ?? profiles[0]
    }

    var activeWritingHand: WritingHand { activeProfile.writingHand }

    /// Starts the large history read after the first usable frame. Views remain responsive with an
    /// explicit loading state and publish the merged records when the utility-queue read finishes.
    func preloadDetailedHistoriesAfterLaunch() {
        guard !detailedHistoriesLoaded, !detailedHistoryLoadStarted else { return }
        detailedHistoryLoadStarted = true
        let generation = detailedHistoryLoadGeneration
        detailedHistoryPersistence.load { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self,
                      !self.detailedHistoriesLoaded,
                      self.detailedHistoryLoadGeneration == generation else { return }
                self.installDetailedHistories(result)
            }
        }
    }

    /// Deterministic async barrier for lifecycle work and tests; normal child-facing views observe
    /// `detailedHistoriesAreLoaded` and never block MainActor on file I/O or JSON decoding.
    func waitForDetailedHistoriesToLoad() async {
        if detailedHistoriesLoaded { return }
        preloadDetailedHistoriesAfterLaunch()
        await withCheckedContinuation { continuation in
            if detailedHistoriesLoaded {
                continuation.resume()
            } else {
                detailedHistoryLoadWaiters.append(continuation)
            }
        }
    }

    var activeCustomWords: [CometCustomWord] {
        customWords
            .filter { $0.profileID == activeProfileID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var activeAttempts: [CometAttemptRecord] {
        attempts.filter { $0.profileID == activeProfileID }
    }

    var activeSpellingAttempts: [StarSpellerAttemptRecord] {
        spellingAttempts.filter { $0.profileID == activeProfileID }
    }

    var activeSpellingSession: StarSpellerSessionSnapshot? {
        spellingSessions.first { $0.profileID == activeProfileID }
    }

    var activePoints: Int {
        activeAttempts.reduce(0) { $0 + $1.pointsEarned }
    }

    var activeAverageScore: Int? {
        guard !activeAttempts.isEmpty else { return nil }
        return Int(
            (Double(activeAttempts.reduce(0) { $0 + $1.score })
                / Double(activeAttempts.count)).rounded()
        )
    }

    var activePerfectStreak: Int {
        var count = 0
        for attempt in activeAttempts.sorted(by: { $0.timestamp > $1.timestamp }) {
            guard attempt.score == CometRewardCalculator.maximumScore else { break }
            count += 1
        }
        return count
    }

    var availableWords: [String] {
        var seen = Set<String>()
        return (activeCustomWords.map(\.text) + Self.coreWords).filter { seen.insert($0).inserted }
    }

    func addProfile(name: String, writingHand: WritingHand) {
        let cleaned = Self.cleanName(name)
        let profile = CometChildProfile(
            name: cleaned.isEmpty ? "Explorer \(profiles.count + 1)" : cleaned,
            writingHand: writingHand
        )
        profiles.append(profile)
        markProfileModified(profile.id)
        setActiveProfile(profile.id)
        persistProfiles()
    }

    func setActiveProfile(_ id: UUID) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }
        activeProfileID = id
        defaults.set(id.uuidString, forKey: Keys.activeProfileID)
        StorageService.shared.setPlayerName(profile.name == "Explorer" ? "" : profile.name)
        notifyProgressChanged()
    }

    func renameActiveProfile(_ name: String) {
        guard let index = profiles.firstIndex(where: { $0.id == activeProfileID }) else { return }
        let cleaned = Self.cleanName(name)
        profiles[index].name = cleaned.isEmpty ? "Explorer" : cleaned
        markProfileModified(activeProfileID)
        StorageService.shared.setPlayerName(cleaned)
        persistProfiles()
    }

    func setWritingHand(_ hand: WritingHand) {
        guard let index = profiles.firstIndex(where: { $0.id == activeProfileID }) else { return }
        profiles[index].writingHand = hand
        markProfileModified(activeProfileID)
        persistProfiles()
    }

    func deleteProfile(_ id: UUID) {
        guard profiles.count > 1, let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        if !detailedHistoriesLoaded {
            profileIDsPendingHistoryDeletion.insert(id)
        }
        markProfileDeleted(id)
        StorageService.shared.deleteProgress(for: id)
        profiles.remove(at: index)
        customWords.removeAll { $0.profileID == id }
        storedAttempts.removeAll { $0.profileID == id }
        storedSpellingAttempts.removeAll { $0.profileID == id }
        spellingSessions.removeAll { $0.profileID == id }
        if activeProfileID == id { setActiveProfile(profiles[0].id) }
        persistAll()
    }

    @discardableResult
    func addCustomWord(
        _ word: String,
        contextSentence: String? = nil
    ) -> CometCustomWord? {
        let cleaned = Self.normalizedCustomWord(word)
        guard (1...Self.maximumCustomWordLength).contains(cleaned.count),
              activeCustomWords.count < Self.maximumCustomWords,
              !activeCustomWords.contains(where: { $0.text == cleaned }) else {
            return nil
        }

        let customWord = CometCustomWord(
            profileID: activeProfileID,
            text: cleaned,
            contextSentence: Self.cleanedContextSentence(contextSentence)
        )
        customWords.append(customWord)
        persistCustomWords()
        return customWord
    }

    /// Imports a plain-text or CSV-style list in one pass. Words remain local to the active
    /// child profile and use the same constraints as words entered individually.
    @discardableResult
    func importCustomWords(from rawList: String) -> CometCustomWordImportResult {
        let candidates = Self.customWordImportCandidates(from: rawList)

        let existingWordCount = activeCustomWords.count
        var seen = Set(activeCustomWords.map(\.text))
        var addedWords: [String] = []
        var invalidCount = 0
        var duplicateCount = 0
        var overflowCount = 0

        for candidate in candidates {
            let cleaned = Self.normalizedCustomWord(candidate.word)
            guard (1...Self.maximumCustomWordLength).contains(cleaned.count) else {
                invalidCount += 1
                continue
            }
            guard seen.insert(cleaned).inserted else {
                duplicateCount += 1
                continue
            }
            guard existingWordCount + addedWords.count < Self.maximumCustomWords else {
                overflowCount += 1
                continue
            }

            customWords.append(
                CometCustomWord(
                    profileID: activeProfileID,
                    text: cleaned,
                    contextSentence: Self.cleanedContextSentence(candidate.contextSentence)
                )
            )
            addedWords.append(cleaned)
        }

        if !addedWords.isEmpty {
            persistCustomWords()
        }

        return CometCustomWordImportResult(
            addedWords: addedWords,
            invalidCount: invalidCount,
            duplicateCount: duplicateCount,
            overflowCount: overflowCount
        )
    }

    func setRecordingFilename(_ filename: String?, for wordID: UUID) {
        guard let index = customWords.firstIndex(where: { $0.id == wordID }) else { return }
        customWords[index].recordingFilename = filename
        persistCustomWords()
    }

    func setContextSentence(_ sentence: String?, for wordID: UUID) {
        guard let index = customWords.firstIndex(where: { $0.id == wordID }) else { return }
        customWords[index].contextSentence = Self.cleanedContextSentence(sentence)
        persistCustomWords()
    }

    func deleteCustomWord(_ id: UUID) -> String? {
        guard let index = customWords.firstIndex(where: { $0.id == id }) else { return nil }
        let filename = customWords[index].recordingFilename
        customWords.remove(at: index)
        persistCustomWords()
        return filename
    }

    func recordingFilename(forWord word: String) -> String? {
        activeCustomWords.first(where: { $0.text == word.lowercased() })?.recordingFilename
    }

    func contextSentence(forWord word: String) -> String? {
        let normalizedWord = Self.normalizedCustomWord(word)
        return activeCustomWords
            .first(where: { $0.text == normalizedWord })?
            .contextSentence
    }

    func recordingFilenames(for profileID: UUID) -> [String] {
        customWords
            .filter { $0.profileID == profileID }
            .compactMap(\.recordingFilename)
    }

    func correctionTotals() -> [String: Int] {
        activeAttempts.reduce(into: [:]) { result, attempt in
            for (kind, count) in attempt.correctionCounts {
                result[kind, default: 0] += count
            }
        }
    }

    func recordAttempt(
        character: String,
        mode: CometActivityMode,
        reward: CometReward,
        metrics: CometPerformanceMetrics,
        traces: [[LetterPoint]]
    ) {
        let compactTraces = traces.map(Self.downsample).map { $0.map(StoredLetterPoint.init) }
        let record = CometAttemptRecord(
            id: UUID(),
            profileID: activeProfileID,
            character: character,
            mode: mode,
            score: reward.score,
            breakdown: reward.breakdown,
            correctionCounts: metrics.correctionCounts,
            usedHint: metrics.usedHint,
            wasIndependent: metrics.assistance == .flySolo && !metrics.usedHint,
            pointsEarned: reward.points,
            timestamp: Date(),
            traces: compactTraces
        )
        storedAttempts.append(record)
        let activeIndices = storedAttempts.indices.filter {
            storedAttempts[$0].profileID == activeProfileID
        }
        if activeIndices.count > 300 {
            for index in activeIndices.prefix(activeIndices.count - 300).reversed() {
                storedAttempts.remove(at: index)
            }
        }
        persistAttempts()
    }

    func recordSpellingAttempt(
        word: String,
        checkAttempts: Int,
        errorCount: Int,
        hintUses: Int,
        wasSuccessful: Bool,
        pointsEarned: Int
    ) {
        let normalizedWord = Self.normalizedCustomWord(word)
        guard !normalizedWord.isEmpty else { return }

        storedSpellingAttempts.append(
            StarSpellerAttemptRecord(
                id: UUID(),
                profileID: activeProfileID,
                word: normalizedWord,
                checkAttempts: max(1, checkAttempts),
                errorCount: max(0, errorCount),
                hintUses: max(0, hintUses),
                wasSuccessful: wasSuccessful,
                pointsEarned: max(0, pointsEarned),
                timestamp: Date()
            )
        )

        let activeIndices = storedSpellingAttempts.indices.filter {
            storedSpellingAttempts[$0].profileID == activeProfileID
        }
        if activeIndices.count > 500 {
            for index in activeIndices.prefix(activeIndices.count - 500).reversed() {
                storedSpellingAttempts.remove(at: index)
            }
        }
        persistSpellingAttempts()
    }

    func spellingMastery(for word: String) -> CometMasteryLevel {
        let normalizedWord = Self.normalizedCustomWord(word)
        return Self.spellingMastery(
            from: activeSpellingAttempts.filter { $0.word == normalizedWord }
        )
    }

    func adaptiveSpellingWords(from allowed: [String], count: Int) -> [String] {
        var seen = Set<String>()
        let uniqueWords = allowed.filter { word in
            let normalized = Self.normalizedCustomWord(word)
            return !normalized.isEmpty && seen.insert(normalized).inserted
        }
        guard !uniqueWords.isEmpty else { return [] }

        // Index the bounded attempt history once. The previous comparator repeatedly filtered
        // all 500 records during every sort comparison, which made opening a mixed practice
        // mission do unnecessary O(words log(words) * attempts) work on the main actor.
        let attempts = activeSpellingAttempts
        let attemptsByWord = Dictionary(grouping: attempts, by: \.word)
        let metadata = Dictionary(
            uniqueKeysWithValues: uniqueWords.map { word -> (String, SpellingPracticeMetadata) in
                let normalized = Self.normalizedCustomWord(word)
                let records = attemptsByWord[normalized, default: []]
                let support = records.suffix(3).reduce(0) {
                    $0 + $1.errorCount * 2 + $1.hintUses + ($1.wasSuccessful ? 0 : 3)
                }
                return (
                    normalized,
                    SpellingPracticeMetadata(
                        mastery: Self.spellingMastery(from: records),
                        support: support,
                        lastPractisedAt: records.map(\.timestamp).max() ?? .distantPast
                    )
                )
            }
        )

        let rotation = attempts.count % uniqueWords.count
        let rotated = Array(uniqueWords[rotation...]) + Array(uniqueWords[..<rotation])
        let sourceOrder = Dictionary(
            uniqueKeysWithValues: rotated.enumerated().map {
                (Self.normalizedCustomWord($0.element), $0.offset)
            }
        )

        let ranked = rotated.sorted { left, right in
            let leftKey = Self.normalizedCustomWord(left)
            let rightKey = Self.normalizedCustomWord(right)
            let leftMetadata = metadata[leftKey] ?? .new
            let rightMetadata = metadata[rightKey] ?? .new
            let leftPriority = Self.spellingPracticePriority(leftMetadata.mastery)
            let rightPriority = Self.spellingPracticePriority(rightMetadata.mastery)
            if leftPriority != rightPriority { return leftPriority < rightPriority }

            if leftMetadata.support != rightMetadata.support {
                return leftMetadata.support > rightMetadata.support
            }

            if leftMetadata.lastPractisedAt != rightMetadata.lastPractisedAt {
                return leftMetadata.lastPractisedAt < rightMetadata.lastPractisedAt
            }

            return sourceOrder[leftKey, default: 0] < sourceOrder[rightKey, default: 0]
        }
        let targetCount = max(1, count)
        if ranked.count >= targetCount {
            return Array(ranked.prefix(targetCount))
        }

        var repeated = ranked
        while repeated.count < targetCount {
            repeated.append(ranked[repeated.count % ranked.count])
        }
        return repeated
    }

    private struct SpellingPracticeMetadata {
        let mastery: CometMasteryLevel
        let support: Int
        let lastPractisedAt: Date

        static let new = SpellingPracticeMetadata(
            mastery: .new,
            support: 0,
            lastPractisedAt: .distantPast
        )
    }

    private static func spellingMastery(
        from records: [StarSpellerAttemptRecord]
    ) -> CometMasteryLevel {
        guard !records.isEmpty else { return .new }
        let latestThree = records
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(3)
        if latestThree.count == 3,
           latestThree.allSatisfy({
               $0.wasSuccessful && $0.errorCount == 0 && $0.hintUses == 0
           }) {
            return .mastered
        }

        let successfulCount = latestThree.filter(\.wasSuccessful).count
        let supportCount = latestThree.reduce(0) { partial, attempt in
            partial + attempt.errorCount + attempt.hintUses
        }
        if successfulCount >= 2 && supportCount <= 1 { return .secure }
        return .practising
    }

    func spellingProgress(limit: Int? = nil) -> [StarSpellerWordProgress] {
        let grouped = Dictionary(grouping: activeSpellingAttempts, by: \.word)
        let progress = grouped.compactMap { word, records -> StarSpellerWordProgress? in
            guard let lastPractisedAt = records.map(\.timestamp).max() else { return nil }
            return StarSpellerWordProgress(
                word: word,
                mastery: spellingMastery(for: word),
                attempts: records.count,
                successes: records.filter(\.wasSuccessful).count,
                errors: records.reduce(0) { $0 + $1.errorCount },
                hints: records.reduce(0) { $0 + $1.hintUses },
                lastPractisedAt: lastPractisedAt
            )
        }
        .sorted { left, right in
            if left.mastery != right.mastery { return left.mastery < right.mastery }
            let leftSupport = left.errors + left.hints
            let rightSupport = right.errors + right.hints
            if leftSupport != rightSupport { return leftSupport > rightSupport }
            return left.lastPractisedAt > right.lastPractisedAt
        }

        guard let limit else { return progress }
        return Array(progress.prefix(max(0, limit)))
    }

    var activeSpellingSummary: StarSpellerProfileSummary {
        let records = activeSpellingAttempts
        let words = Set(records.map(\.word))
        return StarSpellerProfileSummary(
            totalAttempts: records.count,
            successfulAttempts: records.filter(\.wasSuccessful).count,
            firstTrySuccesses: records.filter {
                $0.wasSuccessful && $0.errorCount == 0 && $0.hintUses == 0
            }.count,
            totalErrors: records.reduce(0) { $0 + $1.errorCount },
            totalHints: records.reduce(0) { $0 + $1.hintUses },
            practisedWords: words.count,
            secureWords: words.filter { spellingMastery(for: $0) >= .secure }.count,
            masteredWords: words.filter { spellingMastery(for: $0) == .mastered }.count
        )
    }

    func saveSpellingSession(
        words: [String],
        currentIndex: Int,
        score: Int = 0,
        currentWordIsReadyToWrite: Bool = false
    ) {
        guard !words.isEmpty else { return }
        let safeIndex = min(max(0, currentIndex), words.count - 1)
        if let index = spellingSessions.firstIndex(where: { $0.profileID == activeProfileID }) {
            let existing = spellingSessions[index]
            spellingSessions[index] = StarSpellerSessionSnapshot(
                id: existing.id,
                profileID: activeProfileID,
                words: words,
                currentIndex: safeIndex,
                score: score,
                currentWordIsReadyToWrite: currentWordIsReadyToWrite,
                startedAt: existing.startedAt
            )
        } else {
            spellingSessions.append(
                StarSpellerSessionSnapshot(
                    profileID: activeProfileID,
                    words: words,
                    currentIndex: safeIndex,
                    score: score,
                    currentWordIsReadyToWrite: currentWordIsReadyToWrite
                )
            )
        }
        persistSpellingSessions()
    }

    func clearActiveSpellingSession() {
        spellingSessions.removeAll { $0.profileID == activeProfileID }
        persistSpellingSessions()
    }

    /// Waits until every detailed-attempt snapshot already queued for disk has finished writing.
    /// Normal play never blocks the main thread on JSON work; tests and app lifecycle hand-off can
    /// await this barrier when they need a deterministic durability point.
    func waitForPendingAttemptPersistence() async {
        await detailedHistoryPersistence.waitForPendingWrites()
    }

    func mastery(for character: String) -> CometMasteryLevel {
        let records = activeAttempts.filter { $0.character == character }
        guard !records.isEmpty else { return .new }
        if records.contains(where: { $0.wasIndependent && $0.score >= 90 }) { return .mastered }
        if records.contains(where: { $0.wasIndependent && $0.score >= 75 }) { return .secure }
        return .practising
    }

    func bestScore(for character: String) -> Int? {
        activeAttempts.filter { $0.character == character }.map(\.score).max()
    }

    func recentAttempts(limit: Int = 20) -> [CometAttemptRecord] {
        Array(activeAttempts.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }

    func recommendedCharacters(from allowed: [String], count: Int) -> [String] {
        let valid = allowed.filter { LetterLibrary.glyph(for: $0) != nil }
        guard !valid.isEmpty else { return [] }

        let ranked = valid.sorted { left, right in
            let leftLevel = mastery(for: left)
            let rightLevel = mastery(for: right)
            if leftLevel != rightLevel { return leftLevel < rightLevel }
            return (bestScore(for: left) ?? -1) < (bestScore(for: right) ?? -1)
        }
        let rotation = attempts.count % ranked.count
        let rotated = Array(ranked[rotation...]) + Array(ranked[..<rotation])
        return Array(rotated.prefix(max(1, min(count, rotated.count))))
    }

    func resetAfterDataClear() {
        detailedHistoryLoadGeneration += 1
        detailedHistoryLoadStarted = true
        detailedHistoriesLoaded = true
        detailedHistoriesAreLoaded = true
        resumeDetailedHistoryLoadWaiters()
        recoveredDamagedDetailedHistory = false
        detailedHistoryNeedsAttention = false
        profileIDsPendingHistoryDeletion.removeAll()
        let profile = CometChildProfile(name: "Explorer")
        profiles = [profile]
        activeProfileID = profile.id
        customWords = []
        storedAttempts = []
        storedSpellingAttempts = []
        spellingSessions = []
        persistProfiles()
        persistCustomWords()
        persistSpellingSessions()
        // Clear pending snapshots and replace both streams on the utility queue. The parent UI no
        // longer waits behind a large encode; the app lifecycle barrier still awaits durability.
        detailedHistoryPersistence.resetHistories()
    }

    private func resumeDetailedHistoryLoadWaiters() {
        let waiters = detailedHistoryLoadWaiters
        detailedHistoryLoadWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    /// Refreshes observable profile state after the iCloud service has merged a remote family.
    /// Active play remains on the same child whenever that profile still exists.
    func reloadProfilesFromDiskAfterCloudSync() {
        guard let decoded: [CometChildProfile] = Self.decode(
            [CometChildProfile].self,
            from: defaults.data(forKey: Keys.profiles),
            using: decoder
        ), !decoded.isEmpty else { return }

        profiles = decoded
        if !decoded.contains(where: { $0.id == activeProfileID }) {
            activeProfileID = decoded[0].id
            defaults.set(activeProfileID.uuidString, forKey: Keys.activeProfileID)
        }
    }

    private func persistAll() {
        persistProfiles()
        persistCustomWords()
        persistAttempts()
        persistSpellingAttempts()
        persistSpellingSessions()
    }

    private func persistProfiles() {
        defaults.set(try? encoder.encode(profiles), forKey: Keys.profiles)
        defaults.set(activeProfileID.uuidString, forKey: Keys.activeProfileID)
        notifyProgressChanged()
    }

    private func persistCustomWords() {
        defaults.set(try? encoder.encode(customWords), forKey: Keys.customWords)
    }

    private func persistAttempts() {
        guard detailedHistoriesLoaded else { return }
        detailedHistoryPersistence.enqueue(attempts: storedAttempts)
    }

    private func persistSpellingAttempts() {
        guard detailedHistoriesLoaded else { return }
        detailedHistoryPersistence.enqueue(spellingAttempts: storedSpellingAttempts)
    }

    private func persistSpellingSessions() {
        defaults.set(try? encoder.encode(spellingSessions), forKey: Keys.spellingSessions)
    }

    private func notifyProgressChanged() {
        NotificationCenter.default.post(
            name: .maxPuzzlesProgressDidChange,
            object: nil
        )
    }

    private func markProfileModified(_ id: UUID, at date: Date = Date()) {
        var raw = defaults.dictionary(
            forKey: ICloudProgressSyncService.profileModifiedAtKey
        ) as? [String: Double] ?? [:]
        raw[id.uuidString] = date.timeIntervalSince1970
        defaults.set(raw, forKey: ICloudProgressSyncService.profileModifiedAtKey)
    }

    private func markProfileDeleted(_ id: UUID, at date: Date = Date()) {
        var raw = defaults.dictionary(
            forKey: ICloudProgressSyncService.deletedProfileAtKey
        ) as? [String: Double] ?? [:]
        raw[id.uuidString] = date.timeIntervalSince1970
        defaults.set(raw, forKey: ICloudProgressSyncService.deletedProfileAtKey)
    }

    private static func decode<Value: Decodable>(
        _ type: Value.Type,
        from data: Data?,
        using decoder: JSONDecoder
    ) -> Value? {
        guard let data else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private static func cappedAttempts(
        _ records: [CometAttemptRecord]
    ) -> [CometAttemptRecord] {
        cappedPerProfile(records, maximumPerProfile: 300, profileID: \CometAttemptRecord.profileID)
    }

    private static func cappedSpellingAttempts(
        _ records: [StarSpellerAttemptRecord]
    ) -> [StarSpellerAttemptRecord] {
        cappedPerProfile(
            records,
            maximumPerProfile: 500,
            profileID: \StarSpellerAttemptRecord.profileID
        )
    }

    private static func cappedPerProfile<Record>(
        _ records: [Record],
        maximumPerProfile: Int,
        profileID: KeyPath<Record, UUID>
    ) -> [Record] {
        var keptCounts: [UUID: Int] = [:]
        var newestFirst: [Record] = []
        newestFirst.reserveCapacity(records.count)

        for record in records.reversed() {
            let id = record[keyPath: profileID]
            guard keptCounts[id, default: 0] < maximumPerProfile else { continue }
            keptCounts[id, default: 0] += 1
            newestFirst.append(record)
        }
        return newestFirst.reversed()
    }

    private static func cleanName(_ name: String) -> String {
        String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
    }

    nonisolated static func normalizedCustomWord(_ word: String) -> String {
        String(
            word.lowercased().unicodeScalars.filter { scalar in
                (97...122).contains(Int(scalar.value))
            }.map(Character.init)
        )
    }

    nonisolated private static func cleanedContextSentence(
        _ sentence: String?
    ) -> String? {
        guard let sentence else { return nil }
        let cleaned = sentence
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        guard !cleaned.isEmpty else { return nil }
        return String(cleaned.prefix(maximumContextSentenceLength))
    }

    nonisolated private static func customWordImportCandidates(
        from rawList: String
    ) -> [(word: String, contextSentence: String?)] {
        var lines = rawList
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let first = lines.first {
            let headerColumns = first
                .split(separator: ",", omittingEmptySubsequences: false)
                .map { normalizedCustomWord(String($0)) }
            if headerColumns.first.map({ ["word", "words"].contains($0) }) == true,
               headerColumns.dropFirst().contains(where: {
                   ["context", "sentence", "example", "examplesentence"].contains($0)
               }) {
                lines.removeFirst()
                return lines.compactMap {
                    line -> (word: String, contextSentence: String?)? in
                    let columns = line.split(
                        separator: ",",
                        maxSplits: 1,
                        omittingEmptySubsequences: false
                    )
                    guard let word = columns.first else { return nil }
                    let context = columns.count > 1 ? String(columns[1]) : nil
                    return (
                        trimmingImportQuotes(String(word)) ?? "",
                        trimmingImportQuotes(context)
                    )
                }
            }
        }

        var candidates: [(word: String, contextSentence: String?)] = []
        for line in lines {
            if let range = line.range(of: " :: ") {
                candidates.append((
                    String(line[..<range.lowerBound]),
                    String(line[range.upperBound...])
                ))
                continue
            }
            if let tabIndex = line.firstIndex(of: "\t") {
                candidates.append((
                    String(line[..<tabIndex]),
                    String(line[line.index(after: tabIndex)...])
                ))
                continue
            }

            let separators = CharacterSet.whitespacesAndNewlines
                .union(CharacterSet(charactersIn: ",;|"))
            candidates.append(
                contentsOf: line
                    .components(separatedBy: separators)
                    .filter { !$0.isEmpty }
                    .map { ($0, nil) }
            )
        }

        if let first = candidates.first,
           ["word", "words"].contains(normalizedCustomWord(first.word)) {
            candidates.removeFirst()
        }
        return candidates
    }

    nonisolated private static func trimmingImportQuotes(_ value: String?) -> String? {
        guard let value else { return nil }
        return value.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines.union(
                CharacterSet(charactersIn: "\"")
            )
        )
    }

    nonisolated private static func spellingPracticePriority(
        _ mastery: CometMasteryLevel
    ) -> Int {
        switch mastery {
        case .practising: return 0
        case .new: return 1
        case .secure: return 2
        case .mastered: return 3
        }
    }

    private static func downsample(_ trace: [LetterPoint]) -> [LetterPoint] {
        guard trace.count > 90 else { return trace }
        let strideSize = max(1, Int(ceil(Double(trace.count) / 90)))
        var compact = Swift.stride(from: 0, to: trace.count, by: strideSize).map { trace[$0] }
        if compact.last != trace.last, let last = trace.last { compact.append(last) }
        return compact
    }
}
