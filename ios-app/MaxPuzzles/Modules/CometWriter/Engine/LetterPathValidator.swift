import CoreGraphics
import Foundation

enum StrokeValidationResult: Equatable {
    case ready
    case advanced(progress: CGFloat)
    case wrongStart
    case offTrack
    case wrongDirection
    case belowBaseline
    case incomplete
    case complete
}

/// Validates one handwriting stroke against an ordered polyline.
///
/// The validator deliberately scores formation rather than visual similarity: a trace must begin
/// near the taught start, move forward through a forgiving corridor, and finish near the endpoint.
struct LetterPathValidator {
    private let stroke: LetterStroke
    private let startTolerance: CGFloat
    private let corridorTolerance: CGFloat
    private let endTolerance: CGFloat
    private let reverseTolerance: CGFloat
    private let maximumForwardJump: CGFloat
    private let writingBaseline: CGFloat
    private let baselineTolerance: CGFloat
    private let allowsDescender: Bool

    private let segmentLengths: [CGFloat]
    private let cumulativeLengths: [CGFloat]
    private let totalLength: CGFloat

    private(set) var progress: CGFloat = 0
    private(set) var hasStarted = false
    private var lastAcceptedPoint: LetterPoint?

    init(
        stroke: LetterStroke,
        startTolerance: CGFloat = 0.13,
        corridorTolerance: CGFloat = 0.105,
        endTolerance: CGFloat = 0.14,
        reverseTolerance: CGFloat = 0.055,
        maximumForwardJump: CGFloat = 0.28,
        writingBaseline: CGFloat = 0.82,
        baselineTolerance: CGFloat = 0.06
    ) {
        self.stroke = stroke
        self.startTolerance = startTolerance
        self.corridorTolerance = corridorTolerance
        self.endTolerance = endTolerance
        self.reverseTolerance = reverseTolerance
        self.maximumForwardJump = maximumForwardJump
        self.writingBaseline = writingBaseline
        self.baselineTolerance = baselineTolerance
        // A stroke that is taught below the line (g, j, p, q, y, and f) must keep its
        // descender space. Other strokes get a forgiving buffer for natural Pencil wobble.
        allowsDescender = stroke.points.contains { $0.y > writingBaseline + baselineTolerance }

        let lengths = zip(stroke.points, stroke.points.dropFirst()).map { $0.distance(to: $1) }
        segmentLengths = lengths

        var cumulative: [CGFloat] = [0]
        for length in lengths {
            cumulative.append(cumulative.last! + length)
        }
        cumulativeLengths = cumulative
        totalLength = cumulative.last ?? 0
    }

    mutating func begin(at point: LetterPoint) -> StrokeValidationResult {
        guard point.distance(to: stroke.start) <= startTolerance else {
            return .wrongStart
        }

        hasStarted = true
        progress = 0
        lastAcceptedPoint = point
        return .ready
    }

    mutating func add(_ point: LetterPoint) -> StrokeValidationResult {
        guard hasStarted else { return .wrongStart }

        if !allowsDescender, point.y > writingBaseline + baselineTolerance {
            return .belowBaseline
        }

        if stroke.isDot || stroke.points.count == 1 || totalLength == 0 {
            return point.distance(to: stroke.start) <= corridorTolerance ? .advanced(progress: 1) : .offTrack
        }

        let travelled = lastAcceptedPoint?.distance(to: point) ?? 0
        let expectedAdvance = travelled / totalLength
        let preferredProgress = min(1, progress + expectedAdvance)
        let localStart = max(0, progress - reverseTolerance)
        // A broad fixed look-ahead can snap a slightly wobbly point onto a later overlapping
        // downstroke (notably the retraces in m, n and h), then reject the child's next point as
        // backwards. Scale the search window to the actual movement while retaining a generous
        // floor for normal event coalescing and the existing cap for genuinely large moves.
        let forwardAllowance = min(
            maximumForwardJump,
            max(0.08, expectedAdvance * 2.5)
        )
        let localEnd = min(1, progress + forwardAllowance)

        guard let projection = closestProjection(
            to: point,
            progressRange: localStart...localEnd,
            preferredProgress: preferredProgress
        ) else {
            return .offTrack
        }

        guard projection.distance <= corridorTolerance else {
            if let earlier = closestProjection(
                to: point,
                progressRange: 0...max(0, progress - reverseTolerance),
                preferredProgress: nil
            ),
               earlier.distance <= corridorTolerance {
                return .wrongDirection
            }
            return .offTrack
        }

        guard projection.progress + reverseTolerance >= progress else {
            return .wrongDirection
        }

        progress = max(progress, projection.progress)
        lastAcceptedPoint = point
        return .advanced(progress: progress)
    }

    mutating func end(at point: LetterPoint) -> StrokeValidationResult {
        guard hasStarted else { return .wrongStart }

        if stroke.isDot || totalLength == 0 {
            hasStarted = false
            return point.distance(to: stroke.start) <= startTolerance ? .complete : .incomplete
        }

        let finalResult = add(point)
        hasStarted = false

        if progress >= 0.86 && point.distance(to: stroke.end) <= endTolerance {
            progress = 1
            return .complete
        }

        switch finalResult {
        case .belowBaseline, .wrongDirection, .offTrack:
            return finalResult
        default:
            break
        }

        return .incomplete
    }

    private func closestProjection(
        to point: LetterPoint,
        progressRange: ClosedRange<CGFloat>,
        preferredProgress: CGFloat?
    ) -> (distance: CGFloat, progress: CGFloat)? {
        guard !segmentLengths.isEmpty, totalLength > 0 else { return nil }

        var best: (distance: CGFloat, progress: CGFloat)?

        for index in segmentLengths.indices {
            let segmentStartProgress = cumulativeLengths[index] / totalLength
            let segmentEndProgress = cumulativeLengths[index + 1] / totalLength

            guard segmentEndProgress >= progressRange.lowerBound,
                  segmentStartProgress <= progressRange.upperBound else {
                continue
            }

            let start = stroke.points[index]
            let end = stroke.points[index + 1]
            let dx = end.x - start.x
            let dy = end.y - start.y
            let squaredLength = dx * dx + dy * dy
            guard squaredLength > 0 else { continue }

            let rawAmount = ((point.x - start.x) * dx + (point.y - start.y) * dy) / squaredLength
            let amount = min(max(rawAmount, 0), 1)
            let projected = LetterPoint(x: start.x + dx * amount, y: start.y + dy * amount)
            let distance = point.distance(to: projected)
            let projectedLength = cumulativeLengths[index] + segmentLengths[index] * amount
            let projectedProgress = projectedLength / totalLength

            guard progressRange.contains(projectedProgress) else { continue }

            let isCloser = best == nil || distance < best!.distance - 0.002
            let isEquivalentDistance = best.map { abs(distance - $0.distance) <= 0.002 } ?? false
            let isCloserToExpectedProgress: Bool
            if let preferredProgress, let best {
                isCloserToExpectedProgress = abs(projectedProgress - preferredProgress)
                    < abs(best.progress - preferredProgress)
            } else {
                isCloserToExpectedProgress = false
            }

            if isCloser || (isEquivalentDistance && isCloserToExpectedProgress) {
                best = (distance, projectedProgress)
            }
        }

        return best
    }
}
