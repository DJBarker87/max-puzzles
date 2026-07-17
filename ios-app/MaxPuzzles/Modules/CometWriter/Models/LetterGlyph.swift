import CoreGraphics
import Foundation

/// A point in a letter's coordinate space. Width is normalized from 0 to 1; height includes a
/// small dedicated descender band below 1 so tails can extend without squeezing the letter body.
struct LetterPoint: Hashable, Sendable {
    let x: CGFloat
    let y: CGFloat

    func distance(to other: LetterPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }

    static func interpolate(from start: LetterPoint, to end: LetterPoint, amount: CGFloat) -> LetterPoint {
        LetterPoint(
            x: start.x + (end.x - start.x) * amount,
            y: start.y + (end.y - start.y) * amount
        )
    }
}

enum LetterWritingMetrics {
    static let canvasHeight: CGFloat = 1.08

    static let topLineY: CGFloat = 0.08
    static let xHeightLineY: CGFloat = 0.35
    static let baselineY: CGFloat = 0.82
    static let descenderLineY: CGFloat = 1.04

    static func renderedY(_ modelY: CGFloat) -> CGFloat {
        modelY / canvasHeight
    }

    static func modelY(_ renderedY: CGFloat) -> CGFloat {
        renderedY * canvasHeight
    }
}

/// Maps the pedagogical letter coordinate system into the actual writing surface.
///
/// X and Y deliberately use the same physical scale. This is the important bit: a circular
/// stroke stays circular on a full-size practice pad, a compact word slot, portrait, landscape,
/// and every supported iPhone/iPad size. The spare horizontal space is centred rather than
/// being used to stretch or squash the glyph.
struct LetterCanvasGeometry: Hashable {
    let size: CGSize
    let contentInset: CGFloat

    private var usableHeight: CGFloat {
        max(1, size.height - contentInset * 2)
    }

    var pointsPerModelUnit: CGFloat {
        usableHeight / LetterWritingMetrics.canvasHeight
    }

    func render(_ point: LetterPoint) -> CGPoint {
        CGPoint(
            x: size.width / 2 + (point.x - 0.5) * pointsPerModelUnit,
            y: contentInset + point.y * pointsPerModelUnit
        )
    }

    func unrender(_ point: CGPoint) -> LetterPoint {
        LetterPoint(
            x: 0.5 + (point.x - size.width / 2) / pointsPerModelUnit,
            y: (point.y - contentInset) / pointsPerModelUnit
        )
    }
}

/// Keeps the visible guide and the validator in the same coordinate space at every chosen size.
/// Scaling around the writing area's optical centre preserves stroke proportions and direction.
struct LetterDisplayTransform: Hashable, Sendable {
    static let minimumScale: CGFloat = 0.70
    static let maximumScale: CGFloat = 1.05
    static let defaultScale: CGFloat = 1.00

    // Size changes stay anchored to the ruled baseline so letters never appear to float above it.
    private static let centre = LetterPoint(x: 0.50, y: LetterWritingMetrics.baselineY)

    let scale: CGFloat

    init(scale: CGFloat) {
        self.scale = min(max(scale, Self.minimumScale), Self.maximumScale)
    }

    func display(_ point: LetterPoint) -> LetterPoint {
        LetterPoint(
            x: Self.centre.x + (point.x - Self.centre.x) * scale,
            y: Self.centre.y + (point.y - Self.centre.y) * scale
        )
    }

    func model(_ point: LetterPoint) -> LetterPoint {
        LetterPoint(
            x: Self.centre.x + (point.x - Self.centre.x) / scale,
            y: Self.centre.y + (point.y - Self.centre.y) / scale
        )
    }
}

enum LetterStrokeStyle: Hashable, Sendable {
    /// Rounded handwriting movement, sampled once so drawing and validation use the same curve.
    case smooth
    /// A densely sampled mathematical arc whose curvature must remain constant.
    case circular
    /// Deliberately straight joins for letters such as v, w, x, z, and k.
    case angular
}

struct LetterStroke: Hashable, Sendable {
    let points: [LetterPoint]
    let isDot: Bool
    let style: LetterStrokeStyle
    private let segmentLengths: [CGFloat]
    private let totalLength: CGFloat

    init(
        points sourcePoints: [LetterPoint],
        isDot: Bool = false,
        style: LetterStrokeStyle = .smooth
    ) {
        precondition(!sourcePoints.isEmpty, "A letter stroke needs at least one point")
        let preparedPoints: [LetterPoint]
        switch style {
        case .smooth:
            preparedPoints = Self.smoothed(sourcePoints)
        case .circular, .angular:
            preparedPoints = sourcePoints
        }
        let preparedLengths = zip(preparedPoints, preparedPoints.dropFirst()).map { $0.distance(to: $1) }

        self.points = preparedPoints
        self.isDot = isDot
        self.style = style
        self.segmentLengths = preparedLengths
        self.totalLength = preparedLengths.reduce(0, +)
    }

    var start: LetterPoint { points[0] }
    var end: LetterPoint { points[points.count - 1] }
    var length: CGFloat { totalLength }

    /// Returns a point a given distance through the polyline. Used for guide stars and arrows.
    func point(at progress: CGFloat) -> LetterPoint {
        guard points.count > 1 else { return start }

        guard totalLength > 0 else { return start }

        let target = min(max(progress, 0), 1) * totalLength
        var travelled: CGFloat = 0

        for (index, length) in segmentLengths.enumerated() {
            if travelled + length >= target {
                let amount = length == 0 ? 0 : (target - travelled) / length
                return .interpolate(from: points[index], to: points[index + 1], amount: amount)
            }
            travelled += length
        }

        return end
    }

    /// Returns the visible portion of this stroke without rebuilding its length table.
    /// The on-demand formation demonstration uses this to reveal only the path already travelled.
    func points(upTo progress: CGFloat) -> [LetterPoint] {
        guard points.count > 1, totalLength > 0 else { return [start] }

        let target = min(max(progress, 0), 1) * totalLength
        guard target > 0 else { return [start] }

        var result: [LetterPoint] = [start]
        result.reserveCapacity(points.count)
        var travelled: CGFloat = 0

        for (index, length) in segmentLengths.enumerated() {
            let nextTravelled = travelled + length
            if nextTravelled < target {
                result.append(points[index + 1])
                travelled = nextTravelled
                continue
            }

            let amount = length == 0 ? 0 : (target - travelled) / length
            result.append(.interpolate(from: points[index], to: points[index + 1], amount: amount))
            break
        }

        return result
    }

    /// Catmull-Rom sampling removes visible corners while retaining every taught waypoint.
    /// The generated points are cached in the value, so Canvas never recalculates the curve
    /// during a child's drag and the validator follows exactly what is drawn.
    private static func smoothed(_ source: [LetterPoint]) -> [LetterPoint] {
        guard source.count > 2 else { return source }

        let isClosed = source.first!.distance(to: source.last!) < 0.001
        let controls = isClosed ? Array(source.dropLast()) : source
        guard controls.count > 2 else { return source }

        let segmentCount = isClosed ? controls.count : controls.count - 1
        // Ten samples keeps even the longest capital downstrokes visually continuous on a
        // full-size iPad pad. Eight left a perceptible final jump in J and U.
        let samplesPerSegment = 10
        var result: [LetterPoint] = [controls[0]]
        result.reserveCapacity(segmentCount * samplesPerSegment + 1)

        for index in 0..<segmentCount {
            let p1 = controls[index]
            let p2 = controls[(index + 1) % controls.count]
            let p0: LetterPoint
            let p3: LetterPoint

            if isClosed {
                p0 = controls[(index - 1 + controls.count) % controls.count]
                p3 = controls[(index + 2) % controls.count]
            } else {
                p0 = index == 0 ? p1 : controls[index - 1]
                p3 = index + 2 < controls.count ? controls[index + 2] : p2
            }

            for sample in 1...samplesPerSegment {
                let t = CGFloat(sample) / CGFloat(samplesPerSegment)
                result.append(catmullRom(p0: p0, p1: p1, p2: p2, p3: p3, t: t))
            }
        }

        // Avoid floating-point drift at the places children are explicitly taught to start/end.
        result[0] = source[0]
        result[result.count - 1] = source[source.count - 1]
        return result
    }

    private static func catmullRom(
        p0: LetterPoint,
        p1: LetterPoint,
        p2: LetterPoint,
        p3: LetterPoint,
        t: CGFloat
    ) -> LetterPoint {
        let t2 = t * t
        let t3 = t2 * t

        func component(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
            0.5 * (
                2 * b
                + (-a + c) * t
                + (2 * a - 5 * b + 4 * c - d) * t2
                + (-a + 3 * b - 3 * c + d) * t3
            )
        }

        return LetterPoint(
            x: min(max(component(p0.x, p1.x, p2.x, p3.x), 0), 1),
            y: min(
                max(component(p0.y, p1.y, p2.y, p3.y), 0),
                LetterWritingMetrics.canvasHeight
            )
        )
    }
}

struct LetterDemonstrationFrame: Equatable, Sendable {
    let completedStrokeCount: Int
    let activeStrokeIndex: Int?
    let activeProgress: CGFloat
}

/// A deterministic teaching timeline for any glyph. The screen never transforms: only a partial
/// stroke and its comet head are redrawn, which keeps the writing surface visually stationary.
struct LetterDemonstrationTimeline: Sendable {
    let strokes: [LetterStroke]

    private let gapDuration: TimeInterval = 0.18

    init(glyph: LetterGlyph) {
        strokes = glyph.strokes
    }

    var totalDuration: TimeInterval {
        let drawingTime = strokes.reduce(0) { $0 + duration(for: $1) }
        let gaps = gapDuration * Double(max(0, strokes.count - 1))
        return drawingTime + gaps
    }

    func frame(at elapsed: TimeInterval) -> LetterDemonstrationFrame {
        guard !strokes.isEmpty else {
            return LetterDemonstrationFrame(completedStrokeCount: 0, activeStrokeIndex: nil, activeProgress: 0)
        }

        var remaining = max(0, elapsed)

        for (index, stroke) in strokes.enumerated() {
            let strokeDuration = duration(for: stroke)
            if remaining <= strokeDuration {
                return LetterDemonstrationFrame(
                    completedStrokeCount: index,
                    activeStrokeIndex: index,
                    activeProgress: CGFloat(min(max(remaining / strokeDuration, 0), 1))
                )
            }

            remaining -= strokeDuration
            if index < strokes.count - 1 {
                if remaining < gapDuration {
                    return LetterDemonstrationFrame(
                        completedStrokeCount: index + 1,
                        activeStrokeIndex: nil,
                        activeProgress: 0
                    )
                }
                remaining -= gapDuration
            }
        }

        return LetterDemonstrationFrame(
            completedStrokeCount: strokes.count,
            activeStrokeIndex: nil,
            activeProgress: 1
        )
    }

    private func duration(for stroke: LetterStroke) -> TimeInterval {
        guard !stroke.isDot else { return 0.30 }

        // Formation needs to be slow enough for a child to copy, but every single stroke stays brief.
        return min(max(TimeInterval(stroke.length / 0.90), 0.65), 1.35)
    }
}

enum LetterFamily: String, CaseIterable, Identifiable, Sendable {
    case magicC
    case downstrokes
    case scoops
    case bumps
    case specials
    case numbers
    case capitals

    var id: String { rawValue }

    var title: String {
        switch self {
        case .magicC: return "Magic C Comets"
        case .downstrokes: return "Downstroke Rockets"
        case .scoops: return "Scoop & Slant Stars"
        case .bumps: return "Bump Robots"
        case .specials: return "Special Shapes"
        case .numbers: return "Number Nebula"
        case .capitals: return "Capital Constellation"
        }
    }

    var formationHint: String {
        switch self {
        case .magicC: return "Back and around"
        case .downstrokes: return "Start high and go down"
        case .scoops: return "Scoop or slant"
        case .bumps: return "Down, back up, and over"
        case .specials: return "Watch each movement"
        case .numbers: return "Write 0 to 9"
        case .capitals: return "Tall, clear capital letters"
        }
    }

    var symbol: String {
        switch self {
        case .magicC: return "arrow.counterclockwise"
        case .downstrokes: return "arrow.down"
        case .scoops: return "arrow.down.right"
        case .bumps: return "waveform.path"
        case .specials: return "scribble.variable"
        case .numbers: return "number"
        case .capitals: return "textformat.abc"
        }
    }
}

struct LetterGlyph: Identifiable, Hashable, Sendable {
    let character: String
    let exampleWord: String
    let family: LetterFamily
    let strokes: [LetterStroke]

    var id: String { character }

    var isNumber: Bool {
        character.count == 1 && character.first?.wholeNumberValue != nil
    }

    var isUppercase: Bool {
        guard character.count == 1, let scalar = character.unicodeScalars.first else { return false }
        return (65...90).contains(Int(scalar.value))
    }

    var formationName: String {
        if isNumber { return "number \(character)" }
        return isUppercase ? "capital \(character)" : "lowercase \(character)"
    }

    var promptTitle: String {
        isNumber ? "\(character) is \(exampleWord)" : "\(character) is for \(exampleWord)"
    }

    var spokenPrompt: String {
        if isNumber {
            return "Number \(character). \(promptTitle). \(formationCue)"
        }
        return "Letter \(character). \(promptTitle). \(formationCue)"
    }
}

enum TraceAssistance: Int, CaseIterable, Sendable {
    case followTheGlow
    case connectTheStars
    case flySolo

    var title: String {
        switch self {
        case .followTheGlow: return "Follow the glow"
        case .connectTheStars: return "Connect the stars"
        case .flySolo: return "Fly solo"
        }
    }

    var instruction: String {
        switch self {
        case .followTheGlow: return "Stay on the comet trail."
        case .connectTheStars: return "Fly through each star in order."
        case .flySolo: return "Use the start star and remember the shape."
        }
    }
}

struct CometReward: Equatable, Sendable {
    let score: Int
    let characterPoints: Int
    let wordBonusPoints: Int
    let breakdown: CometScoreBreakdown

    init(
        score: Int,
        characterPoints: Int,
        wordBonusPoints: Int,
        breakdown: CometScoreBreakdown? = nil
    ) {
        self.score = score
        self.characterPoints = characterPoints
        self.wordBonusPoints = wordBonusPoints
        self.breakdown = breakdown ?? .legacy(total: score)
    }

    var points: Int {
        characterPoints + wordBonusPoints
    }

    var isPerfect: Bool {
        score == CometRewardCalculator.maximumScore
    }

    var includesWordBonus: Bool {
        wordBonusPoints > 0
    }

    var encouragement: String {
        switch score {
        case 100: return "Brilliant formation!"
        case 90...: return "Excellent control!"
        case 80...: return "Strong writing!"
        case 70...: return "Good progress!"
        default: return "Mission complete!"
        }
    }
}

struct CometScoreBreakdown: Codable, Equatable, Hashable, Sendable {
    let pathAccuracy: Int
    let formation: Int
    let linePlacement: Int
    let smoothness: Int
    let independence: Int

    var total: Int {
        pathAccuracy + formation + linePlacement + smoothness + independence
    }

    static func legacy(total: Int) -> CometScoreBreakdown {
        let clamped = min(max(total, 0), 100)
        let path = Int((Double(clamped) * 0.40).rounded())
        let formation = Int((Double(clamped) * 0.25).rounded())
        let line = Int((Double(clamped) * 0.15).rounded())
        let smooth = Int((Double(clamped) * 0.10).rounded())
        return CometScoreBreakdown(
            pathAccuracy: path,
            formation: formation,
            linePlacement: line,
            smoothness: smooth,
            independence: max(0, clamped - path - formation - line - smooth)
        )
    }
}

struct CometPerformanceMetrics: Equatable, Sendable {
    let averagePathDeviation: CGFloat
    let pathDeviationSpread: CGFloat
    let averageLengthRatio: CGFloat
    let correctionCounts: [String: Int]
    let assistance: TraceAssistance
    let usedHint: Bool
}

enum CometRewardCalculator {
    static let maximumScore = 100
    static let minimumCompletionScore = 50
    static let correctionPenalty = 8
    static let completedWordPoints = 25

    /// A completed character always earns a positive score. Corrections affect precision,
    /// while the floor keeps practice rewarding for a child who perseveres.
    static func score(mistakes: Int) -> Int {
        max(
            minimumCompletionScore,
            maximumScore - max(0, mistakes) * correctionPenalty
        )
    }

    /// Ten formation-score points translate directly into one Comet Point.
    static func characterPoints(for score: Int) -> Int {
        let clampedScore = min(max(score, minimumCompletionScore), maximumScore)
        return clampedScore / 10
    }

    static func reward(mistakes: Int, completedWord: Bool = false) -> CometReward {
        let formationScore = score(mistakes: mistakes)
        return CometReward(
            score: formationScore,
            characterPoints: characterPoints(for: formationScore),
            wordBonusPoints: completedWord ? completedWordPoints : 0
        )
    }

    static func reward(metrics: CometPerformanceMetrics, completedWord: Bool = false) -> CometReward {
        let pathRatio = 1 - min(max(metrics.averagePathDeviation / 0.105, 0), 1)
        let pathScore = Int((pathRatio * 40).rounded())

        let corrections = metrics.correctionCounts
        let formationPenalty =
            (corrections["start", default: 0] * 5)
            + (corrections["direction", default: 0] * 6)
            + (corrections["finish", default: 0] * 4)
            + (corrections["track", default: 0] * 2)
        let formationScore = max(0, 25 - formationPenalty)

        let lineScore = max(0, 15 - corrections["baseline", default: 0] * 6)

        let excessLength = abs(metrics.averageLengthRatio - 1)
        let smoothnessRatio = 1
            - min(max(excessLength / 0.65, 0), 1) * 0.65
            - min(max(metrics.pathDeviationSpread / 0.055, 0), 1) * 0.35
        let smoothnessScore = Int((max(0, smoothnessRatio) * 10).rounded())

        let independenceScore: Int
        switch metrics.assistance {
        case .flySolo:
            independenceScore = metrics.usedHint ? 2 : 10
        case .connectTheStars:
            independenceScore = metrics.usedHint ? 2 : 5
        case .followTheGlow:
            independenceScore = metrics.usedHint ? 0 : 2
        }

        let rawBreakdown = CometScoreBreakdown(
            pathAccuracy: pathScore,
            formation: formationScore,
            linePlacement: lineScore,
            smoothness: smoothnessScore,
            independence: independenceScore
        )
        // Perseverance earns a 50-point completion floor. Keep the visible category rows honest
        // by distributing that floor across the normal category caps instead of returning a
        // headline score that does not match its breakdown.
        var remainingFloor = max(0, minimumCompletionScore - rawBreakdown.total)
        let pathBoost = min(remainingFloor, 40 - rawBreakdown.pathAccuracy)
        remainingFloor -= pathBoost
        let formationBoost = min(remainingFloor, 25 - rawBreakdown.formation)
        remainingFloor -= formationBoost
        let lineBoost = min(remainingFloor, 15 - rawBreakdown.linePlacement)
        remainingFloor -= lineBoost
        let smoothnessBoost = min(remainingFloor, 10 - rawBreakdown.smoothness)
        remainingFloor -= smoothnessBoost
        let independenceBoost = min(remainingFloor, 10 - rawBreakdown.independence)

        let breakdown = CometScoreBreakdown(
            pathAccuracy: rawBreakdown.pathAccuracy + pathBoost,
            formation: rawBreakdown.formation + formationBoost,
            linePlacement: rawBreakdown.linePlacement + lineBoost,
            smoothness: rawBreakdown.smoothness + smoothnessBoost,
            independence: rawBreakdown.independence + independenceBoost
        )
        let formationScoreTotal = min(maximumScore, breakdown.total)

        return CometReward(
            score: formationScoreTotal,
            characterPoints: characterPoints(for: formationScoreTotal),
            wordBonusPoints: completedWord ? completedWordPoints : 0,
            breakdown: breakdown
        )
    }
}

struct WordLetterAttempt: Sendable {
    let character: String
    let traces: [[LetterPoint]]
    let reward: CometReward
}

enum LetterRecallCatalog {
    static let alphabet = "abcdefghijklmnopqrstuvwxyz".map(String.init)
    static let teachingOrder = "msatpincoegdrhflubkvywjqxz".map(String.init)
    static let allLetters = Set(alphabet)

    static func orderedSelection(_ selection: Set<String>) -> [String] {
        teachingOrder.filter { selection.contains($0) }
    }
}

enum AdvancedWritingMission: String, Hashable, Sendable {
    case letterRecall
    case wordWriting
    case phonics
    case alienMail
}
