import Foundation

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
        case .phonics: return "Sound mission"
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
    var recordingFilename: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        profileID: UUID,
        text: String,
        recordingFilename: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.profileID = profileID
        self.text = text
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
/// reporting stays responsive and UserDefaults never grows without bound.
@MainActor
final class CometLearningStore: ObservableObject {
    static let shared = CometLearningStore()
    static let maximumCustomWords = 100
    static let maximumCustomWordLength = 10

    @Published private(set) var profiles: [CometChildProfile]
    @Published private(set) var activeProfileID: UUID
    @Published private(set) var customWords: [CometCustomWord]
    @Published private(set) var attempts: [CometAttemptRecord]

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
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

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
        attempts = Self.decode(
            [CometAttemptRecord].self,
            from: defaults.data(forKey: Keys.attempts),
            using: decoder
        ) ?? []

        persistProfiles()
    }

    var activeProfile: CometChildProfile {
        profiles.first(where: { $0.id == activeProfileID }) ?? profiles[0]
    }

    var activeWritingHand: WritingHand { activeProfile.writingHand }

    var activeCustomWords: [CometCustomWord] {
        customWords
            .filter { $0.profileID == activeProfileID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var activeAttempts: [CometAttemptRecord] {
        attempts.filter { $0.profileID == activeProfileID }
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
        setActiveProfile(profile.id)
        persistProfiles()
    }

    func setActiveProfile(_ id: UUID) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }
        activeProfileID = id
        defaults.set(id.uuidString, forKey: Keys.activeProfileID)
        StorageService.shared.setPlayerName(profile.name == "Explorer" ? "" : profile.name)
    }

    func renameActiveProfile(_ name: String) {
        guard let index = profiles.firstIndex(where: { $0.id == activeProfileID }) else { return }
        let cleaned = Self.cleanName(name)
        profiles[index].name = cleaned.isEmpty ? "Explorer" : cleaned
        StorageService.shared.setPlayerName(cleaned)
        persistProfiles()
    }

    func setWritingHand(_ hand: WritingHand) {
        guard let index = profiles.firstIndex(where: { $0.id == activeProfileID }) else { return }
        profiles[index].writingHand = hand
        persistProfiles()
    }

    func deleteProfile(_ id: UUID) {
        guard profiles.count > 1, let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles.remove(at: index)
        customWords.removeAll { $0.profileID == id }
        attempts.removeAll { $0.profileID == id }
        if activeProfileID == id { setActiveProfile(profiles[0].id) }
        persistAll()
    }

    @discardableResult
    func addCustomWord(_ word: String) -> CometCustomWord? {
        let cleaned = Self.normalizedCustomWord(word)
        guard (1...Self.maximumCustomWordLength).contains(cleaned.count),
              activeCustomWords.count < Self.maximumCustomWords,
              !activeCustomWords.contains(where: { $0.text == cleaned }) else {
            return nil
        }

        let customWord = CometCustomWord(profileID: activeProfileID, text: cleaned)
        customWords.append(customWord)
        persistCustomWords()
        return customWord
    }

    /// Imports a plain-text or CSV-style list in one pass. Words remain local to the active
    /// child profile and use the same constraints as words entered individually.
    @discardableResult
    func importCustomWords(from rawList: String) -> CometCustomWordImportResult {
        let separators = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: ",;|"))
        var candidates = rawList
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }

        if let first = candidates.first,
           ["word", "words"].contains(Self.normalizedCustomWord(first)) {
            candidates.removeFirst()
        }

        let existingWordCount = activeCustomWords.count
        var seen = Set(activeCustomWords.map(\.text))
        var addedWords: [String] = []
        var invalidCount = 0
        var duplicateCount = 0
        var overflowCount = 0

        for candidate in candidates {
            let cleaned = Self.normalizedCustomWord(candidate)
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
                CometCustomWord(profileID: activeProfileID, text: cleaned)
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
        attempts.append(record)
        let activeIndices = attempts.indices.filter { attempts[$0].profileID == activeProfileID }
        if activeIndices.count > 300 {
            for index in activeIndices.prefix(activeIndices.count - 300).reversed() {
                attempts.remove(at: index)
            }
        }
        persistAttempts()
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
        let profile = CometChildProfile(name: "Explorer")
        profiles = [profile]
        activeProfileID = profile.id
        customWords = []
        attempts = []
        persistAll()
    }

    private func persistAll() {
        persistProfiles()
        persistCustomWords()
        persistAttempts()
    }

    private func persistProfiles() {
        defaults.set(try? encoder.encode(profiles), forKey: Keys.profiles)
        defaults.set(activeProfileID.uuidString, forKey: Keys.activeProfileID)
    }

    private func persistCustomWords() {
        defaults.set(try? encoder.encode(customWords), forKey: Keys.customWords)
    }

    private func persistAttempts() {
        defaults.set(try? encoder.encode(attempts), forKey: Keys.attempts)
    }

    private static func decode<Value: Decodable>(
        _ type: Value.Type,
        from data: Data?,
        using decoder: JSONDecoder
    ) -> Value? {
        guard let data else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private static func cleanName(_ name: String) -> String {
        String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
    }

    static func normalizedCustomWord(_ word: String) -> String {
        String(
            word.lowercased().unicodeScalars.filter { scalar in
                (97...122).contains(Int(scalar.value))
            }.map(Character.init)
        )
    }

    private static func downsample(_ trace: [LetterPoint]) -> [LetterPoint] {
        guard trace.count > 90 else { return trace }
        let strideSize = max(1, Int(ceil(Double(trace.count) / 90)))
        var compact = Swift.stride(from: 0, to: trace.count, by: strideSize).map { trace[$0] }
        if compact.last != trace.last, let last = trace.last { compact.append(last) }
        return compact
    }
}
