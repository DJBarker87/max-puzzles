import Combine
import Foundation

enum CometTraceEvent: Equatable {
    case none
    case mistake
    case strokeCompleted
    case roundCompleted
    case letterCompleted
}

enum CometFeedbackTone {
    case instruction
    case success
    case correction
}

enum CometCorrectionKind: String, Equatable, Hashable {
    case start
    case direction
    case track
    case baseline
    case finish
}

/// High-frequency input state observed by the drawing surface, not by the surrounding mission UI.
///
/// `CometWriterViewModel` deliberately does not forward this object's change notifications. That
/// keeps each accepted Pencil/finger sample from invalidating prompts, controls and overlays while
/// preserving the exact point sequence used for rendering, validation and scoring.
@MainActor
final class CometTraceSurfaceState: ObservableObject {
    @Published private(set) var points: [LetterPoint] = []

    func begin(at point: LetterPoint) {
        points = [point]
    }

    func append(_ point: LetterPoint) {
        points.append(point)
    }

    func clear() {
        guard !points.isEmpty else { return }
        points = []
    }
}

@MainActor
final class CometWriterViewModel: ObservableObject {
    /// Allows a small natural dip below the ruled baseline without relaxing Flight School or the
    /// validator's general-purpose default.
    private static let productionHandwritingBaselineTolerance: CGFloat = 0.08

    @Published private(set) var glyph: LetterGlyph
    @Published private(set) var assistance: TraceAssistance = .followTheGlow
    @Published private(set) var currentStrokeIndex = 0
    @Published private(set) var completedTraces: [[LetterPoint]] = []
    let traceSurfaceState = CometTraceSurfaceState()
    // Internal scoring state. Keeping this out of @Published avoids a second full Canvas update
    // for every sampled touch; traceSurfaceState drives the one redraw we actually need.
    private(set) var strokeProgress: CGFloat = 0
    @Published private(set) var isRoundComplete = false
    @Published private(set) var isLetterComplete = false
    @Published private(set) var isHintVisible = false
    @Published private(set) var demonstrationStartedAt: Date?
    @Published private(set) var feedbackMessage: String
    @Published private(set) var feedbackTone: CometFeedbackTone = .instruction
    @Published private(set) var correctionKind: CometCorrectionKind?
    @Published private(set) var mistakeCount = 0
    @Published private(set) var hintCount = 0

    private(set) var correctionCounts: [CometCorrectionKind: Int] = [:]
    private var completedQuality: [StrokeQuality] = []

    private var validator: LetterPathValidator?
    private var warnedDuringGesture = false
    private var hintTask: Task<Void, Never>?

    init(glyph: LetterGlyph, assistance: TraceAssistance = .followTheGlow) {
        self.glyph = glyph
        self.assistance = assistance
        feedbackMessage = "Start at the green star."
    }

    var currentStroke: LetterStroke {
        glyph.strokes[min(currentStrokeIndex, glyph.strokes.count - 1)]
    }

    var activeTrace: [LetterPoint] {
        traceSurfaceState.points
    }

    var roundNumber: Int { assistance.rawValue + 1 }

    var isDemonstrating: Bool { demonstrationStartedAt != nil }

    var demonstrationTimeline: LetterDemonstrationTimeline {
        LetterDemonstrationTimeline(glyph: glyph)
    }

    var overallProgress: CGFloat {
        let completedRounds = CGFloat(assistance.rawValue)
        let strokePart = (CGFloat(currentStrokeIndex) + strokeProgress) / CGFloat(glyph.strokes.count)
        return min((completedRounds + strokePart) / CGFloat(TraceAssistance.allCases.count), 1)
    }

    var earnedStars: Int {
        max(1, 3 - mistakeCount / 3)
    }

    var performanceMetrics: CometPerformanceMetrics {
        let qualityCount = CGFloat(max(completedQuality.count, 1))
        let averageDeviation = completedQuality.reduce(0) { $0 + $1.averageDeviation } / qualityCount
        let averageSpread = completedQuality.reduce(0) { $0 + $1.deviationSpread } / qualityCount
        let averageLengthRatio = completedQuality.reduce(0) { $0 + $1.lengthRatio } / qualityCount

        return CometPerformanceMetrics(
            averagePathDeviation: averageDeviation,
            pathDeviationSpread: averageSpread,
            averageLengthRatio: completedQuality.isEmpty ? 1 : averageLengthRatio,
            correctionCounts: Dictionary(
                uniqueKeysWithValues: correctionCounts.map { ($0.key.rawValue, $0.value) }
            ),
            assistance: assistance,
            usedHint: hintCount > 0
        )
    }

    func beginTrace(at point: LetterPoint) -> CometTraceEvent {
        guard !isRoundComplete else { return .none }

        warnedDuringGesture = false
        var nextValidator = LetterPathValidator(
            stroke: currentStroke,
            baselineTolerance: Self.productionHandwritingBaselineTolerance
        )
        let result = nextValidator.begin(at: point)

        guard result == .ready else {
            recordMistake(kind: .start, message: "Begin on the green star.")
            warnedDuringGesture = true
            return .mistake
        }

        validator = nextValidator
        traceSurfaceState.begin(at: point)
        strokeProgress = 0
        correctionKind = nil
        feedbackTone = .instruction
        feedbackMessage = currentStroke.isDot ? "Tap the dot." : "Now follow the arrow."
        return .none
    }

    func continueTrace(at point: LetterPoint) -> CometTraceEvent {
        guard var nextValidator = validator else { return .none }

        let result = nextValidator.add(point)
        validator = nextValidator

        switch result {
        case let .advanced(progress):
            let recoveredFromCorrection = correctionKind != nil
            if recoveredFromCorrection {
                correctionKind = nil
            }
            strokeProgress = progress
            appendIfNeeded(point)
            if recoveredFromCorrection {
                feedbackTone = .instruction
                feedbackMessage = "That’s it — keep going."
            } else if progress > 0.55, feedbackMessage != "Keep going to the end." {
                feedbackTone = .instruction
                feedbackMessage = "Keep going to the end."
            }
            return .none

        case .wrongDirection:
            return warnOnce(kind: .direction, message: "Turn around — follow the arrow.")

        case .belowBaseline:
            return warnOnce(kind: .baseline, message: "Keep this one above the writing line.")

        case .offTrack:
            return warnOnce(kind: .track, message: "Stay close to the glowing trail.")

        default:
            return .none
        }
    }

    func endTrace(at point: LetterPoint) -> CometTraceEvent {
        guard var nextValidator = validator else { return .none }
        let result = nextValidator.end(at: point)
        validator = nil

        guard result == .complete else {
            traceSurfaceState.clear()
            strokeProgress = 0
            if !warnedDuringGesture {
                switch result {
                case .wrongDirection:
                    recordMistake(kind: .direction, message: "Turn around — follow the arrow.")
                case .belowBaseline:
                    recordMistake(kind: .baseline, message: "Keep this one above the writing line.")
                case .offTrack:
                    recordMistake(kind: .track, message: "Stay close to the glowing trail.")
                default:
                    recordMistake(kind: .finish, message: "Reach the glowing end of the trail.")
                }
            }
            return .mistake
        }

        appendIfNeeded(point)
        completedQuality.append(Self.quality(of: activeTrace, against: currentStroke))
        completedTraces.append(activeTrace)
        traceSurfaceState.clear()
        strokeProgress = 0
        correctionKind = nil
        currentStrokeIndex += 1

        if currentStrokeIndex < glyph.strokes.count {
            feedbackTone = .success
            feedbackMessage = "Lovely! Find star \(currentStrokeIndex + 1)."
            return .strokeCompleted
        }

        isRoundComplete = true
        if assistance == .flySolo {
            isLetterComplete = true
            feedbackMessage = "You formed \(glyph.character)!"
            return .letterCompleted
        }

        feedbackTone = .success
        feedbackMessage = "Trail complete!"
        return .roundCompleted
    }

    func retryCurrentStroke() {
        cancelHint()
        validator = nil
        traceSurfaceState.clear()
        strokeProgress = 0
        warnedDuringGesture = false
        correctionKind = nil
        feedbackTone = .instruction
        feedbackMessage = "Start again at the green star."
    }

    /// A system touch cancellation is not a child's mistake and must not affect their score.
    func cancelActiveTrace() {
        validator = nil
        traceSurfaceState.clear()
        strokeProgress = 0
        warnedDuringGesture = false
        correctionKind = nil
        feedbackTone = .instruction
        feedbackMessage = "Start again at the green star."
    }

    func showHint(animated: Bool) {
        hintTask?.cancel()
        validator = nil
        traceSurfaceState.clear()
        strokeProgress = 0
        warnedDuringGesture = false
        correctionKind = nil
        isHintVisible = true
        hintCount += 1
        demonstrationStartedAt = animated ? Date() : nil
        feedbackTone = .instruction
        feedbackMessage = animated
            ? "Watch the comet write \(glyph.character)."
            : "Follow the shown path from the green star."

        let visibleDuration = animated ? demonstrationTimeline.totalDuration + 0.55 : 2.0

        hintTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(visibleDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.demonstrationStartedAt = nil
            self?.isHintVisible = false
            self?.feedbackMessage = "Now you try. Begin on the green star."
        }
    }

    func stopHint() {
        cancelHint()
    }

    func advanceRound() {
        guard isRoundComplete, assistance != .flySolo,
              let next = TraceAssistance(rawValue: assistance.rawValue + 1) else {
            return
        }

        assistance = next
        resetRound()
    }

    func load(_ nextGlyph: LetterGlyph, assistance nextAssistance: TraceAssistance = .followTheGlow) {
        cancelHint()
        glyph = nextGlyph
        assistance = nextAssistance
        mistakeCount = 0
        isLetterComplete = false
        resetRound()
    }

    private func resetRound() {
        cancelHint()
        validator = nil
        currentStrokeIndex = 0
        completedTraces = []
        traceSurfaceState.clear()
        strokeProgress = 0
        isRoundComplete = false
        warnedDuringGesture = false
        correctionKind = nil
        mistakeCount = 0
        hintCount = 0
        correctionCounts = [:]
        completedQuality = []
        feedbackTone = .instruction
        feedbackMessage = "Start at the green star."
    }

    private func cancelHint() {
        hintTask?.cancel()
        hintTask = nil
        demonstrationStartedAt = nil
        isHintVisible = false
    }

    private func appendIfNeeded(_ point: LetterPoint) {
        if activeTrace.last?.distance(to: point) ?? .greatestFiniteMagnitude > 0.006 {
            traceSurfaceState.append(point)
        }
    }

    private func warnOnce(kind: CometCorrectionKind, message: String) -> CometTraceEvent {
        guard !warnedDuringGesture else { return .none }
        warnedDuringGesture = true
        recordMistake(kind: kind, message: message)
        return .mistake
    }

    private func recordMistake(kind: CometCorrectionKind, message: String) {
        mistakeCount += 1
        correctionCounts[kind, default: 0] += 1
        correctionKind = kind
        feedbackTone = .correction
        feedbackMessage = message
    }

    private struct StrokeQuality {
        let averageDeviation: CGFloat
        let deviationSpread: CGFloat
        let lengthRatio: CGFloat
    }

    private static func quality(of trace: [LetterPoint], against stroke: LetterStroke) -> StrokeQuality {
        guard !trace.isEmpty else {
            return StrokeQuality(averageDeviation: 0.105, deviationSpread: 0.055, lengthRatio: 2)
        }

        let deviations = trace.map { point in
            stroke.points.map { point.distance(to: $0) }.min() ?? 0.105
        }
        let averageDeviation = deviations.reduce(0, +) / CGFloat(deviations.count)
        let variance = deviations.reduce(CGFloat.zero) { partial, value in
            let delta = value - averageDeviation
            return partial + delta * delta
        } / CGFloat(deviations.count)

        let tracedLength = zip(trace, trace.dropFirst()).reduce(CGFloat.zero) {
            $0 + $1.0.distance(to: $1.1)
        }
        let lengthRatio = stroke.length > 0 ? tracedLength / stroke.length : 1

        return StrokeQuality(
            averageDeviation: averageDeviation,
            deviationSpread: sqrt(variance),
            lengthRatio: lengthRatio
        )
    }
}
