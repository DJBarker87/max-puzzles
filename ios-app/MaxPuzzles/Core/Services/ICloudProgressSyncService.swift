import Foundation

private final class ICloudMutationEpoch: @unchecked Sendable {
    private let lock = NSLock()
    private var value: UInt64 = 0

    @discardableResult
    func advance() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        value &+= 1
        return value
    }

    func current() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

private struct ICloudProfileSnapshotInput: Sendable {
    let profile: CometChildProfile
    let dotToDotCompletedPuzzles: [String]
    let dotToDotInteractionMode: String
    let dotToDotColoredRegionsData: Data?
    let cometWriterCompletedLetters: [String]
    let cometWriterBestScores: [String: Int]
    let lastCometWriterLetter: String?
    let storyData: Data?
    let totalCoinsEarned: Int
    let puzzlesCompletedCount: Int
    let totalGamesPlayed: Int
    let bestTimeByLevel: [String: Int]
    let hasCompletedCircuitTutorial: Bool
    let lastPlayedDifficulty: Int
}

private struct ICloudProgressSnapshotInput: Sendable {
    let resetAt: Date?
    let profiles: [ICloudProfileSnapshotInput]
    let profileModifiedAt: [String: Date]
    let deletedProfileAt: [String: Date]
}

enum ICloudProgressSyncState: Equatable {
    case checking
    case ready(Date)
    case waitingForICloud
    case failed

    var title: String {
        switch self {
        case .checking: return "Checking iCloud…"
        case .ready: return "iCloud progress is ready"
        case .waitingForICloud: return "Sign in to iCloud to sync progress"
        case .failed: return "iCloud sync will retry"
        }
    }
}

struct CloudLevelProgress: Codable, Equatable, Sendable {
    var completed: Bool
    var stars: Int
    var bestTimeSeconds: Double?
    var attempts: Int
}

struct CloudProfileProgress: Codable, Equatable, Sendable {
    var dotToDotCompletedPuzzles: [String] = []
    var dotToDotInteractionMode: String = DotInteractionMode.tap.rawValue
    /// Optional keeps version-one envelopes readable on devices that have not seen colouring yet.
    var dotToDotColoredRegions: [String: [Int]]? = nil
    var cometWriterCompletedLetters: [String] = []
    var cometWriterBestScores: [String: Int] = [:]
    var lastCometWriterLetter: String?
    var storyLevels: [String: CloudLevelProgress] = [:]
    var totalCoinsEarned = 0
    var puzzlesCompletedCount = 0
    var totalGamesPlayed = 0
    var bestTimeByLevel: [String: Int] = [:]
    var hasCompletedCircuitTutorial = false
    var lastPlayedDifficulty = 1
}

struct CloudProgressEnvelope: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version = currentVersion
    var resetAt: Date? = nil
    var profiles: [CometChildProfile]
    var profileModifiedAt: [String: Date]
    var deletedProfileAt: [String: Date]
    var progressByProfile: [String: CloudProfileProgress]

    func normalized() -> CloudProgressEnvelope {
        var copy = self
        copy.profiles.sort { $0.id.uuidString < $1.id.uuidString }
        for key in copy.progressByProfile.keys {
            copy.progressByProfile[key]?.dotToDotCompletedPuzzles.sort()
            if let regions = copy.progressByProfile[key]?.dotToDotColoredRegions {
                copy.progressByProfile[key]?.dotToDotColoredRegions = regions.mapValues {
                    Array(Set($0)).sorted()
                }
            }
            copy.progressByProfile[key]?.cometWriterCompletedLetters.sort()
        }
        return copy
    }

    func retainingDotPuzzles(in allowedIDs: Set<String>) -> CloudProgressEnvelope {
        var copy = self
        for profileID in copy.progressByProfile.keys {
            copy.progressByProfile[profileID]?.dotToDotCompletedPuzzles.removeAll {
                !allowedIDs.contains($0)
            }
            if let regions = copy.progressByProfile[profileID]?.dotToDotColoredRegions {
                copy.progressByProfile[profileID]?.dotToDotColoredRegions = regions.filter {
                    allowedIDs.contains($0.key)
                }
            }
        }
        return copy
    }
}

enum CloudProgressMerger {
    static func merge(
        local: CloudProgressEnvelope,
        remote: CloudProgressEnvelope
    ) -> CloudProgressEnvelope {
        let localReset = local.resetAt ?? .distantPast
        let remoteReset = remote.resetAt ?? .distantPast
        if localReset > remoteReset { return local.normalized() }
        if remoteReset > localReset { return remote.normalized() }

        let localProfiles = Dictionary(uniqueKeysWithValues: local.profiles.map { ($0.id.uuidString, $0) })
        let remoteProfiles = Dictionary(uniqueKeysWithValues: remote.profiles.map { ($0.id.uuidString, $0) })
        let allIDs = Set(localProfiles.keys).union(remoteProfiles.keys)

        var modifiedAt = local.profileModifiedAt
        for (id, date) in remote.profileModifiedAt {
            modifiedAt[id] = max(modifiedAt[id] ?? .distantPast, date)
        }

        var deletedAt = local.deletedProfileAt
        for (id, date) in remote.deletedProfileAt {
            deletedAt[id] = max(deletedAt[id] ?? .distantPast, date)
        }

        var profiles: [CometChildProfile] = []
        var progress: [String: CloudProfileProgress] = [:]

        for id in allIDs.sorted() {
            let localProfile = localProfiles[id]
            let remoteProfile = remoteProfiles[id]
            let localDate = local.profileModifiedAt[id] ?? localProfile?.createdAt ?? .distantPast
            let remoteDate = remote.profileModifiedAt[id] ?? remoteProfile?.createdAt ?? .distantPast

            let selectedProfile: CometChildProfile?
            if remoteDate > localDate {
                selectedProfile = remoteProfile ?? localProfile
            } else {
                selectedProfile = localProfile ?? remoteProfile
            }

            guard let selectedProfile else { continue }
            let newestProfileDate = max(localDate, remoteDate)
            if let deletionDate = deletedAt[id], deletionDate >= newestProfileDate {
                continue
            }

            profiles.append(selectedProfile)
            progress[id] = merge(
                local: local.progressByProfile[id],
                remote: remote.progressByProfile[id]
            )
        }

        // Concurrent deletion must never leave the family without a usable profile.
        if profiles.isEmpty, let fallback = (local.profiles + remote.profiles).min(by: { $0.createdAt < $1.createdAt }) {
            profiles = [fallback]
            deletedAt.removeValue(forKey: fallback.id.uuidString)
            progress[fallback.id.uuidString] = merge(
                local: local.progressByProfile[fallback.id.uuidString],
                remote: remote.progressByProfile[fallback.id.uuidString]
            )
        }

        return CloudProgressEnvelope(
            resetAt: local.resetAt ?? remote.resetAt,
            profiles: profiles,
            profileModifiedAt: modifiedAt,
            deletedProfileAt: deletedAt,
            progressByProfile: progress
        ).normalized()
    }

    private static func merge(
        local: CloudProfileProgress?,
        remote: CloudProfileProgress?
    ) -> CloudProfileProgress {
        guard let local else { return remote ?? CloudProfileProgress() }
        guard let remote else { return local }

        var bestScores = local.cometWriterBestScores
        for (symbol, score) in remote.cometWriterBestScores {
            bestScores[symbol] = max(bestScores[symbol] ?? 0, score)
        }

        var bestTimes = local.bestTimeByLevel
        for (level, time) in remote.bestTimeByLevel {
            bestTimes[level] = min(bestTimes[level] ?? time, time)
        }

        var story = local.storyLevels
        for (level, remoteLevel) in remote.storyLevels {
            guard let localLevel = story[level] else {
                story[level] = remoteLevel
                continue
            }
            let bestTime: Double?
            switch (localLevel.bestTimeSeconds, remoteLevel.bestTimeSeconds) {
            case let (.some(left), .some(right)): bestTime = min(left, right)
            case let (.some(left), .none): bestTime = left
            case let (.none, .some(right)): bestTime = right
            case (.none, .none): bestTime = nil
            }
            story[level] = CloudLevelProgress(
                completed: localLevel.completed || remoteLevel.completed,
                stars: max(localLevel.stars, remoteLevel.stars),
                bestTimeSeconds: bestTime,
                attempts: max(localLevel.attempts, remoteLevel.attempts)
            )
        }

        var coloredRegions = local.dotToDotColoredRegions ?? [:]
        for (puzzleID, remoteRegions) in remote.dotToDotColoredRegions ?? [:] {
            coloredRegions[puzzleID] = Array(
                Set(coloredRegions[puzzleID] ?? []).union(remoteRegions)
            ).sorted()
        }

        return CloudProfileProgress(
            dotToDotCompletedPuzzles: Array(
                Set(local.dotToDotCompletedPuzzles).union(remote.dotToDotCompletedPuzzles)
            ).sorted(),
            dotToDotInteractionMode: remote.dotToDotInteractionMode,
            dotToDotColoredRegions: coloredRegions,
            cometWriterCompletedLetters: Array(
                Set(local.cometWriterCompletedLetters).union(remote.cometWriterCompletedLetters)
            ).sorted(),
            cometWriterBestScores: bestScores,
            lastCometWriterLetter: remote.lastCometWriterLetter ?? local.lastCometWriterLetter,
            storyLevels: story,
            totalCoinsEarned: max(local.totalCoinsEarned, remote.totalCoinsEarned),
            puzzlesCompletedCount: max(local.puzzlesCompletedCount, remote.puzzlesCompletedCount),
            totalGamesPlayed: max(local.totalGamesPlayed, remote.totalGamesPlayed),
            bestTimeByLevel: bestTimes,
            hasCompletedCircuitTutorial: local.hasCompletedCircuitTutorial || remote.hasCompletedCircuitTutorial,
            lastPlayedDifficulty: remote.lastPlayedDifficulty
        )
    }
}

/// Small, merge-only iCloud payload for profiles and durable achievements. It deliberately does
/// not upload handwriting traces, custom voice recordings, or other child-created content.
/// `NSUbiquitousKeyValueStore` keeps this private to devices using the same iCloud/Apple account.
@MainActor
final class ICloudProgressSyncService: ObservableObject {
    static let shared = ICloudProgressSyncService()

    @Published private(set) var state: ICloudProgressSyncState = .checking

    nonisolated static let profileModifiedAtKey = "maxpuzzles.cloud.profileModifiedAt"
    nonisolated static let deletedProfileAtKey = "maxpuzzles.cloud.deletedProfileAt"
    nonisolated static let resetAtKey = "maxpuzzles.cloud.resetAt"
    nonisolated private static let allowedDotPuzzleIDs = Set(DotPuzzleCatalog.all.map(\.id))

    private let cloudKey = "maxpuzzles.progress.envelope.v1"
    private let store: NSUbiquitousKeyValueStore
    private let defaults: UserDefaults
    private let localMutationEpoch = ICloudMutationEpoch()
    /// The existing on-device stores use Foundation's default date representation. The iCloud
    /// envelope deliberately uses milliseconds, so local payloads need their own compatible codec.
    private let localEncoder = JSONEncoder()
    private var progressObserver: NSObjectProtocol?
    private var cloudObserver: NSObjectProtocol?
    private var pendingUpload: Task<Void, Never>?
    private var processingTask: Task<Void, Never>?
    private var lastCloudData: Data?
    private var isStarted = false
    private var isApplyingCloud = false

    init(
        store: NSUbiquitousKeyValueStore = .default,
        defaults: UserDefaults = .standard
    ) {
        self.store = store
        self.defaults = defaults
    }

    deinit {
        pendingUpload?.cancel()
        processingTask?.cancel()
        if let progressObserver {
            NotificationCenter.default.removeObserver(progressObserver)
        }
        if let cloudObserver {
            NotificationCenter.default.removeObserver(cloudObserver)
        }
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true

        progressObserver = NotificationCenter.default.addObserver(
            forName: .maxPuzzlesProgressDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.localMutationEpoch.advance()
            Task { @MainActor in self?.durableProgressChanged() }
        }

        cloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in self?.cloudStoreChanged(notification) }
        }

        state = .checking
        if let data = store.data(forKey: cloudKey) {
            beginReceiving(data)
        } else {
            beginUpload()
        }
    }

    func refresh() {
        guard isStarted else {
            start()
            return
        }
        state = .checking
        if let data = store.data(forKey: cloudKey), data != lastCloudData {
            beginReceiving(data)
        } else {
            updateAvailabilityState()
        }
    }

    func flush() {
        pendingUpload?.cancel()
        pendingUpload = nil
        beginUpload()
    }

    /// Replaces, rather than merges, earlier family progress after the grown-up confirms the
    /// destructive Clear All Data action. The timestamp stops a stale device resurrecting it.
    func resetCloudProgressAfterLocalClear(at date: Date = Date()) {
        pendingUpload?.cancel()
        pendingUpload = nil
        defaults.set(date.timeIntervalSince1970, forKey: Self.resetAtKey)
        beginUpload()
    }

    private func durableProgressChanged() {
        guard !isApplyingCloud else { return }
        processingTask?.cancel()
        processingTask = nil
        pendingUpload?.cancel()
        pendingUpload = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            self?.beginUpload()
        }
    }

    private func cloudStoreChanged(_ notification: Notification) {
        if let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
           !changedKeys.contains(cloudKey) {
            return
        }
        guard let data = store.data(forKey: cloudKey), data != lastCloudData else { return }
        beginReceiving(data)
    }

    private func beginReceiving(_ data: Data) {
        processingTask?.cancel()
        processingTask = Task { @MainActor [weak self] in
            await self?.receiveCloudData(data)
        }
    }

    private func beginUpload() {
        processingTask?.cancel()
        processingTask = Task { @MainActor [weak self] in
            await self?.uploadNow()
        }
    }

    private func receiveCloudData(_ data: Data) async {
        let startingMutationEpoch = localMutationEpoch.current()
        guard let decodedRemote = await Self.decodeEnvelope(data),
              decodedRemote.version == CloudProgressEnvelope.currentVersion else {
            guard !Task.isCancelled else { return }
            state = .failed
            return
        }

        let allowedDotPuzzleIDs = Self.allowedDotPuzzleIDs
        let remote = decodedRemote.retainingDotPuzzles(in: allowedDotPuzzleIDs)
        let local = await snapshot()
        guard !Task.isCancelled,
              localMutationEpoch.current() == startingMutationEpoch else { return }
        let mergeResult = await Task.detached(priority: .utility) {
            let remoteResetIsNewer = (remote.resetAt ?? .distantPast)
                > (local.resetAt ?? .distantPast)
            let merged = CloudProgressMerger.merge(local: local, remote: remote)
                .retainingDotPuzzles(in: allowedDotPuzzleIDs)
            let encoded = Self.encodeEnvelope(merged.normalized())
            return (remoteResetIsNewer, merged, encoded)
        }.value
        guard !Task.isCancelled,
              localMutationEpoch.current() == startingMutationEpoch else { return }

        let (remoteResetIsNewer, merged, mergedData) = mergeResult
        if remoteResetIsNewer {
            clearLocalLearningHistoryForRemoteReset()
        }
        apply(merged)

        guard let mergedData else {
            state = .failed
            return
        }
        lastCloudData = mergedData
        if mergedData != data {
            store.set(mergedData, forKey: cloudKey)
        }
        updateAvailabilityState()
    }

    private func uploadNow() async {
        let startingMutationEpoch = localMutationEpoch.current()
        let envelope = await snapshot()
        guard !Task.isCancelled,
              localMutationEpoch.current() == startingMutationEpoch else { return }
        let data = await Task.detached(priority: .utility) {
            Self.encodeEnvelope(envelope)
        }.value
        guard !Task.isCancelled,
              localMutationEpoch.current() == startingMutationEpoch else { return }
        guard let data else {
            state = .failed
            return
        }
        guard data != lastCloudData else {
            updateAvailabilityState()
            return
        }

        lastCloudData = data
        store.set(data, forKey: cloudKey)
        updateAvailabilityState()
    }

    private func updateAvailabilityState() {
        if FileManager.default.ubiquityIdentityToken == nil {
            state = .waitingForICloud
        } else {
            state = .ready(Date())
        }
    }

    private nonisolated static func decodeEnvelope(_ data: Data) async -> CloudProgressEnvelope? {
        await Task.detached(priority: .utility) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            return try? decoder.decode(CloudProgressEnvelope.self, from: data)
        }.value
    }

    private nonisolated static func encodeEnvelope(_ envelope: CloudProgressEnvelope) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return try? encoder.encode(envelope)
    }

    private func snapshot() async -> CloudProgressEnvelope {
        let input = captureSnapshotInput(profiles: CometLearningStore.shared.profiles)
        return await Task.detached(priority: .utility) {
            Self.snapshot(input: input)
        }.value
    }

    /// Copies every related preference in one uninterrupted MainActor turn. The detached worker
    /// receives immutable values rather than reading live `UserDefaults` key by key.
    private func captureSnapshotInput(
        profiles: [CometChildProfile]
    ) -> ICloudProgressSnapshotInput {
        let inputs = profiles.map { profile in
            func key(_ suffix: String) -> String {
                "maxpuzzles.profile.\(profile.id.uuidString).\(suffix)"
            }

            return ICloudProfileSnapshotInput(
                profile: profile,
                dotToDotCompletedPuzzles: defaults.stringArray(
                    forKey: key("dotToDot.completedPuzzles")
                ) ?? [],
                dotToDotInteractionMode: defaults.string(
                    forKey: key("dotToDot.interactionMode")
                ) ?? DotInteractionMode.tap.rawValue,
                dotToDotColoredRegionsData: defaults.data(
                    forKey: key("dotToDot.coloredRegions")
                ),
                cometWriterCompletedLetters: defaults.stringArray(
                    forKey: key("cometWriter.completedLetters")
                ) ?? [],
                cometWriterBestScores: Self.intDictionary(
                    forKey: key("cometWriter.bestScores"),
                    defaults: defaults
                ),
                lastCometWriterLetter: defaults.string(
                    forKey: key("cometWriter.lastLetter")
                ),
                storyData: defaults.data(forKey: key("storyProgressV2")),
                totalCoinsEarned: defaults.integer(forKey: key("stats.totalCoinsEarned")),
                puzzlesCompletedCount: defaults.integer(forKey: key("stats.puzzlesCompleted")),
                totalGamesPlayed: defaults.integer(forKey: key("stats.totalGamesPlayed")),
                bestTimeByLevel: Self.intDictionary(
                    forKey: key("stats.bestTimeByLevel"),
                    defaults: defaults
                ),
                hasCompletedCircuitTutorial: defaults.bool(
                    forKey: key("tutorial.circuitChallenge.completed")
                ),
                lastPlayedDifficulty: defaults.object(
                    forKey: key("settings.lastDifficulty")
                ) as? Int ?? 1
            )
        }

        return ICloudProgressSnapshotInput(
            resetAt: Self.resetDate(defaults: defaults),
            profiles: inputs,
            profileModifiedAt: Self.decodeDateDictionary(
                forKey: Self.profileModifiedAtKey,
                defaults: defaults
            ),
            deletedProfileAt: Self.decodeDateDictionary(
                forKey: Self.deletedProfileAtKey,
                defaults: defaults
            )
        )
    }

    private nonisolated static func snapshot(
        input: ICloudProgressSnapshotInput
    ) -> CloudProgressEnvelope {
        let decoder = JSONDecoder()
        var progress: [String: CloudProfileProgress] = [:]
        progress.reserveCapacity(input.profiles.count)
        for profileInput in input.profiles {
            progress[profileInput.profile.id.uuidString] = snapshotProgress(
                input: profileInput,
                decoder: decoder
            )
        }

        return CloudProgressEnvelope(
            resetAt: input.resetAt,
            profiles: input.profiles.map(\.profile),
            profileModifiedAt: input.profileModifiedAt,
            deletedProfileAt: input.deletedProfileAt,
            progressByProfile: progress
        ).normalized()
    }

    private nonisolated static func snapshotProgress(
        input: ICloudProfileSnapshotInput,
        decoder: JSONDecoder
    ) -> CloudProfileProgress {
        let story: StoryProgressData = {
            guard let data = input.storyData,
                  let decoded = try? decoder.decode(StoryProgressData.self, from: data) else {
                return StoryProgressData()
            }
            return decoded
        }()
        let cloudStory = story.levelProgress.mapValues {
            CloudLevelProgress(
                completed: $0.completed,
                stars: $0.stars,
                bestTimeSeconds: $0.bestTimeSeconds,
                attempts: $0.attempts
            )
        }
        let coloredRegions: [String: [Int]] = {
            guard let data = input.dotToDotColoredRegionsData,
                  let decoded = try? decoder.decode([String: [Int]].self, from: data) else {
                return [:]
            }
            return decoded.mapValues { Array(Set($0)).sorted() }
        }()

        let currentDotPuzzleIDs = allowedDotPuzzleIDs
        return CloudProfileProgress(
            dotToDotCompletedPuzzles: input.dotToDotCompletedPuzzles
                .filter(currentDotPuzzleIDs.contains),
            dotToDotInteractionMode: input.dotToDotInteractionMode,
            dotToDotColoredRegions: coloredRegions.filter {
                currentDotPuzzleIDs.contains($0.key)
            },
            cometWriterCompletedLetters: input.cometWriterCompletedLetters,
            cometWriterBestScores: input.cometWriterBestScores,
            lastCometWriterLetter: input.lastCometWriterLetter,
            storyLevels: cloudStory,
            totalCoinsEarned: input.totalCoinsEarned,
            puzzlesCompletedCount: input.puzzlesCompletedCount,
            totalGamesPlayed: input.totalGamesPlayed,
            bestTimeByLevel: input.bestTimeByLevel,
            hasCompletedCircuitTutorial: input.hasCompletedCircuitTutorial,
            lastPlayedDifficulty: input.lastPlayedDifficulty
        )
    }

    private func apply(_ envelope: CloudProgressEnvelope) {
        guard !envelope.profiles.isEmpty else { return }
        isApplyingCloud = true
        defer { isApplyingCloud = false }

        let profileData = try? localEncoder.encode(envelope.profiles)
        defaults.set(profileData, forKey: "maxpuzzles.cometWriter.profiles")
        if let resetAt = envelope.resetAt {
            defaults.set(resetAt.timeIntervalSince1970, forKey: Self.resetAtKey)
        }
        defaults.set(encodeDateDictionary(envelope.profileModifiedAt), forKey: Self.profileModifiedAtKey)
        defaults.set(encodeDateDictionary(envelope.deletedProfileAt), forKey: Self.deletedProfileAtKey)

        let liveIDs = Set(envelope.profiles.map { $0.id.uuidString })
        for (id, deletionDate) in envelope.deletedProfileAt where !liveIDs.contains(id) {
            _ = deletionDate
            let prefix = "maxpuzzles.profile.\(id)."
            for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
                defaults.removeObject(forKey: key)
            }
        }

        for profile in envelope.profiles {
            guard let progress = envelope.progressByProfile[profile.id.uuidString] else { continue }
            apply(progress, profileID: profile.id)
        }

        if let activeID = UUID(uuidString: defaults.string(forKey: "maxpuzzles.cometWriter.activeProfileID") ?? ""),
           !envelope.profiles.contains(where: { $0.id == activeID }) {
            defaults.set(envelope.profiles[0].id.uuidString, forKey: "maxpuzzles.cometWriter.activeProfileID")
        }

        CometLearningStore.shared.reloadProfilesFromDiskAfterCloudSync()
        StorageService.shared.reloadActiveProfileAfterCloudSync()
        NotificationCenter.default.post(name: .maxPuzzlesCloudProgressDidChange, object: nil)
    }

    private func apply(_ progress: CloudProfileProgress, profileID: UUID) {
        func key(_ suffix: String) -> String {
            "maxpuzzles.profile.\(profileID.uuidString).\(suffix)"
        }

        let currentDotPuzzleIDs = Self.allowedDotPuzzleIDs
        defaults.set(
            progress.dotToDotCompletedPuzzles.filter(currentDotPuzzleIDs.contains).sorted(),
            forKey: key("dotToDot.completedPuzzles")
        )
        defaults.set(progress.dotToDotInteractionMode, forKey: key("dotToDot.interactionMode"))
        let coloredRegions = (progress.dotToDotColoredRegions ?? [:])
            .filter { currentDotPuzzleIDs.contains($0.key) }
            .mapValues { Array(Set($0)).sorted() }
        defaults.set(try? localEncoder.encode(coloredRegions), forKey: key("dotToDot.coloredRegions"))
        defaults.set(progress.cometWriterCompletedLetters.sorted(), forKey: key("cometWriter.completedLetters"))
        defaults.set(progress.cometWriterBestScores, forKey: key("cometWriter.bestScores"))
        defaults.set(progress.lastCometWriterLetter, forKey: key("cometWriter.lastLetter"))
        defaults.set(progress.totalCoinsEarned, forKey: key("stats.totalCoinsEarned"))
        defaults.set(progress.puzzlesCompletedCount, forKey: key("stats.puzzlesCompleted"))
        defaults.set(progress.totalGamesPlayed, forKey: key("stats.totalGamesPlayed"))
        defaults.set(progress.bestTimeByLevel, forKey: key("stats.bestTimeByLevel"))
        defaults.set(progress.hasCompletedCircuitTutorial, forKey: key("tutorial.circuitChallenge.completed"))
        defaults.set(progress.lastPlayedDifficulty, forKey: key("settings.lastDifficulty"))

        var story = StoryProgressData()
        story.levelProgress = progress.storyLevels.mapValues {
            LevelProgressData(
                completed: $0.completed,
                stars: $0.stars,
                bestTimeSeconds: $0.bestTimeSeconds,
                attempts: $0.attempts
            )
        }
        defaults.set(try? localEncoder.encode(story), forKey: key("storyProgressV2"))
    }

    private nonisolated static func intDictionary(
        forKey key: String,
        defaults: UserDefaults
    ) -> [String: Int] {
        (defaults.dictionary(forKey: key) ?? [:]).reduce(into: [:]) { result, entry in
            if let number = entry.value as? NSNumber {
                result[entry.key] = number.intValue
            }
        }
    }

    private nonisolated static func decodeDateDictionary(
        forKey key: String,
        defaults: UserDefaults
    ) -> [String: Date] {
        (defaults.dictionary(forKey: key) ?? [:]).reduce(into: [:]) { result, entry in
            if let number = entry.value as? NSNumber {
                result[entry.key] = Date(timeIntervalSince1970: number.doubleValue)
            }
        }
    }

    private func encodeDateDictionary(_ dates: [String: Date]) -> [String: Double] {
        dates.mapValues(\.timeIntervalSince1970)
    }

    private nonisolated static func resetDate(defaults: UserDefaults) -> Date? {
        guard defaults.object(forKey: resetAtKey) != nil else { return nil }
        return Date(timeIntervalSince1970: defaults.double(forKey: resetAtKey))
    }

    private func clearLocalLearningHistoryForRemoteReset() {
        let learningKeys = defaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix("maxpuzzles.profile.")
                || $0 == "maxpuzzles.cometWriter.profiles"
                || $0 == "maxpuzzles.cometWriter.activeProfileID"
                || $0 == "maxpuzzles.cometWriter.customWords"
                || $0 == "maxpuzzles.cometWriter.attempts"
                || $0 == "maxpuzzles.starSpeller.attempts"
                || $0 == Self.profileModifiedAtKey
                || $0 == Self.deletedProfileAtKey
        }
        for key in learningKeys {
            defaults.removeObject(forKey: key)
        }
        CustomPromptAudioService.shared.deleteAllRecordings()
        CometLearningStore.shared.resetAfterDataClear()
    }
}

extension Notification.Name {
    /// Posted only when durable child progress or profile data changes. Preferences such as
    /// volume no longer trigger a complete iCloud snapshot and JSON encode.
    static let maxPuzzlesProgressDidChange = Notification.Name(
        "maxpuzzles.progressDidChange"
    )

    static let maxPuzzlesCloudProgressDidChange = Notification.Name(
        "maxpuzzles.cloudProgressDidChange"
    )
}
