import SwiftUI
import UIKit

enum TraceInputPolicy {
    static func accepts(_ touchType: UITouch.TouchType, pencilOnly: Bool) -> Bool {
        !pencilOnly || touchType == .pencil
    }

    static func resolvedPencilOnly(_ requested: Bool, supportsApplePencil: Bool) -> Bool {
        requested && supportsApplePencil
    }
}

enum TraceTouchPhase {
    case began
    case moved
    case ended
    case cancelled
}

enum LetterTraceMotionPolicy {
    static func animatesDemonstration(isDemonstrating: Bool, reduceMotion: Bool) -> Bool {
        isDemonstrating && !reduceMotion
    }
}

struct LetterTracePad: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var viewModel: CometWriterViewModel
    let letterScale: CGFloat
    let pencilOnly: Bool
    let showsWritingLines: Bool
    var showsSurface = true
    var contentInset: CGFloat = 24

    @State private var correctionShake: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                if LetterTraceMotionPolicy.animatesDemonstration(
                    isDemonstrating: viewModel.isDemonstrating,
                    reduceMotion: reduceMotion
                ) {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        traceCanvas(at: timeline.date)
                    }
                } else {
                    traceCanvas(at: nil)
                }

                TraceTouchCapture(pencilOnly: pencilOnly) { phase, location in
                    handleTouch(phase, at: location, in: size)
                }
                .contentShape(Rectangle())
                .allowsHitTesting(!viewModel.isDemonstrating)
            }
            // Resizing the surface during a live stroke changes UIKit's physical coordinates.
            // Cancel that one unfinished stroke rather than joining points from two layouts.
            .onChange(of: size) { _ in
                if !viewModel.activeTrace.isEmpty {
                    viewModel.cancelActiveTrace()
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.cometPaperTop, AppTheme.cometPaperBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(showsSurface ? 1 : 0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(AppTheme.cometCyan.opacity(showsSurface ? 0.38 : 0), lineWidth: 1)
        )
        .shadow(color: AppTheme.cometCyan.opacity(showsSurface ? 0.14 : 0), radius: 18, y: 8)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        // A precision input surface must never inherit a navigation/button animation transaction.
        .transaction { transaction in
            transaction.animation = nil
        }
        .modifier(
            ShakeEffect(
                amount: 4,
                shakesPerUnit: 2.5,
                animatableData: reduceMotion ? 0 : correctionShake
            )
        )
        .accessibilityRepresentation {
            Text("Writing pad for \(viewModel.glyph.formationName)")
                .accessibilityLabel("Writing pad for \(viewModel.glyph.formationName)")
                .accessibilityValue(
                    viewModel.isDemonstrating
                        ? "Showing the correct stroke order"
                        : "Stroke \(min(viewModel.currentStrokeIndex + 1, viewModel.glyph.strokes.count)) of \(viewModel.glyph.strokes.count)"
                )
                .accessibilityHint("Trace from the green star in the direction of the arrow")
                .accessibilityAddTraits(.allowsDirectInteraction)
                .accessibilityIdentifier("comet-writer-trace-pad")
        }
    }

    private func traceCanvas(at date: Date?) -> some View {
        Canvas { context, canvasSize in
            if showsWritingLines {
                drawWritingLines(in: &context, size: canvasSize)
            }
            drawGuides(in: &context, size: canvasSize)
            drawCompletedTraces(in: &context, size: canvasSize)
            drawActiveTrace(in: &context, size: canvasSize)
            drawCorrection(in: &context, size: canvasSize)
            drawStartMarkers(in: &context, size: canvasSize)
            if let date {
                drawDemonstration(in: &context, size: canvasSize, at: date)
            }
        }
    }

    private func handleTouch(_ phase: TraceTouchPhase, at location: CGPoint, in size: CGSize) {
        let point = normalized(location, in: size)

        switch phase {
        case .began:
            handle(viewModel.beginTrace(at: point))
        case .moved:
            handle(viewModel.continueTrace(at: point))
        case .ended:
            handle(viewModel.endTrace(at: point))
        case .cancelled:
            viewModel.cancelActiveTrace()
        }
    }

    private func handle(_ event: CometTraceEvent) {
        switch event {
        case .mistake:
            if !reduceMotion {
                withAnimation(.linear(duration: 0.22)) {
                    correctionShake += 1
                }
            }
            FeedbackManager.shared.haptic(.soft)
            SoundEffectsService.shared.play(.wrongMove)
        case .strokeCompleted:
            FeedbackManager.shared.haptic(.soft)
            SoundEffectsService.shared.play(.correctMove)
        case .roundCompleted:
            FeedbackManager.shared.haptic(.success)
            SoundEffectsService.shared.play(.starReveal)
        case .letterCompleted:
            FeedbackManager.shared.haptic(.levelComplete)
            SoundEffectsService.shared.play(.levelComplete)
        case .none:
            break
        }
    }

    private func normalized(_ point: CGPoint, in size: CGSize) -> LetterPoint {
        LetterTraceCoordinateMapper(
            size: size,
            contentInset: contentInset,
            letterScale: letterScale
        ).modelPoint(for: point)
    }

    private func renderedGlyph(_ point: LetterPoint, in size: CGSize) -> CGPoint {
        LetterTraceCoordinateMapper(
            size: size,
            contentInset: contentInset,
            letterScale: letterScale
        ).location(for: point)
    }

    private func renderedRaw(_ point: LetterPoint, in size: CGSize) -> CGPoint {
        LetterCanvasGeometry(size: size, contentInset: contentInset).render(point)
    }

    private func drawWritingLines(in context: inout GraphicsContext, size: CGSize) {
        let linePositions = LetterWritingLineLayout.renderedYPositions(
            size: size,
            contentInset: contentInset
        )
        let startX = contentInset + 8
        let endX = size.width - contentInset - 8

        let writingLines: [(y: CGFloat, opacity: Double, dash: [CGFloat])] = [
            (linePositions[0], 0.13, [5, 7]),
            (linePositions[1], 0.18, [5, 7]),
            (linePositions[2], 0.30, []),
            (linePositions[3], 0.13, [5, 7])
        ]

        for (y, opacity, dash) in writingLines {
            var path = Path()
            path.move(to: CGPoint(x: startX, y: y))
            path.addLine(to: CGPoint(x: endX, y: y))
            context.stroke(
                path,
                with: .color(AppTheme.cometGuide.opacity(opacity)),
                style: StrokeStyle(lineWidth: 1.5, dash: dash)
            )
        }
    }

    /// Keeps correction feedback on the writing surface where the child is already looking.
    /// These cues are deliberately static: precision practice must not move or zoom the pad.
    private func drawCorrection(in context: inout GraphicsContext, size: CGSize) {
        guard let correction = viewModel.correctionKind else { return }

        let stroke = viewModel.currentStroke
        let cueColor = AppTheme.cometGold

        switch correction {
        case .baseline:
            let baselineY = renderedRaw(
                LetterPoint(x: 0, y: LetterWritingMetrics.baselineY),
                in: size
            ).y
            let startX = contentInset + 8
            let endX = size.width - contentInset - 8

            context.fill(
                Path(CGRect(x: startX, y: baselineY, width: endX - startX, height: max(0, size.height - baselineY))),
                with: .color(cueColor.opacity(0.08))
            )

            var baseline = Path()
            baseline.move(to: CGPoint(x: startX, y: baselineY))
            baseline.addLine(to: CGPoint(x: endX, y: baselineY))
            context.stroke(
                baseline,
                with: .color(cueColor.opacity(0.95)),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )

            let arrowX = endX - 18
            var arrow = Path()
            arrow.move(to: CGPoint(x: arrowX, y: baselineY + 34))
            arrow.addLine(to: CGPoint(x: arrowX, y: baselineY + 6))
            arrow.addLine(to: CGPoint(x: arrowX - 7, y: baselineY + 14))
            arrow.move(to: CGPoint(x: arrowX, y: baselineY + 6))
            arrow.addLine(to: CGPoint(x: arrowX + 7, y: baselineY + 14))
            context.stroke(
                arrow,
                with: .color(cueColor),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )

        case .start:
            drawCorrectionRing(at: stroke.start, in: &context, size: size, color: cueColor)

        case .direction:
            let directionPoints = stride(from: CGFloat(0), through: 0.30, by: 0.04).map {
                stroke.point(at: $0)
            }
            context.stroke(
                path(for: directionPoints, in: size),
                with: .color(cueColor.opacity(0.58)),
                style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
            )
            drawDirectionArrow(for: stroke, in: &context, size: size)

        case .track:
            context.stroke(
                path(for: stroke.points, in: size),
                with: .color(cueColor.opacity(0.52)),
                style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
            )

        case .finish:
            drawCorrectionRing(at: stroke.end, in: &context, size: size, color: cueColor)
        }
    }

    private func drawCorrectionRing(
        at point: LetterPoint,
        in context: inout GraphicsContext,
        size: CGSize,
        color: Color
    ) {
        let center = renderedGlyph(point, in: size)
        context.stroke(
            Path(ellipseIn: CGRect(x: center.x - 19, y: center.y - 19, width: 38, height: 38)),
            with: .color(color.opacity(0.95)),
            style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
    }

    private func drawGuides(in context: inout GraphicsContext, size: CGSize) {
        let shouldRevealPath = viewModel.assistance == .followTheGlow || viewModel.isHintVisible

        for (index, stroke) in viewModel.glyph.strokes.enumerated() where index >= viewModel.currentStrokeIndex {
            let isCurrent = index == viewModel.currentStrokeIndex
            let opacity = isCurrent ? 1.0 : 0.24

            if shouldRevealPath {
                let path = path(for: stroke.points, in: size)
                context.stroke(
                    path,
                    with: .color(AppTheme.cometCyan.opacity(0.12 * opacity)),
                    style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round)
                )
                context.stroke(
                    path,
                    with: .color(AppTheme.cometGuide.opacity(0.74 * opacity)),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [8, 7])
                )
            }

            if (isCurrent && viewModel.assistance != .flySolo) || viewModel.isHintVisible {
                drawCheckpoints(for: stroke, in: &context, size: size)
                drawDirectionArrow(for: stroke, in: &context, size: size)
            }

            if viewModel.assistance != .flySolo || viewModel.isHintVisible {
                let end = renderedGlyph(stroke.end, in: size)
                context.stroke(
                    Path(ellipseIn: CGRect(x: end.x - 7, y: end.y - 7, width: 14, height: 14)),
                    with: .color(AppTheme.cometGold.opacity(0.82 * opacity)),
                    lineWidth: 2
                )
            }
        }
    }

    private func drawCheckpoints(for stroke: LetterStroke, in context: inout GraphicsContext, size: CGSize) {
        guard !stroke.isDot else { return }

        for progress in [CGFloat(0.27), 0.52, 0.76] {
            let center = renderedGlyph(stroke.point(at: progress), in: size)
            let rect = CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: rect), with: .color(AppTheme.cometGold.opacity(0.88)))
        }
    }

    private func drawDirectionArrow(for stroke: LetterStroke, in context: inout GraphicsContext, size: CGSize) {
        guard !stroke.isDot, stroke.points.count > 1 else { return }

        let from = renderedGlyph(stroke.point(at: 0.10), in: size)
        let to = renderedGlyph(stroke.point(at: 0.18), in: size)
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 9

        var arrow = Path()
        arrow.move(to: from)
        arrow.addLine(to: to)
        arrow.move(to: to)
        arrow.addLine(to: CGPoint(
            x: to.x - arrowLength * cos(angle - .pi / 6),
            y: to.y - arrowLength * sin(angle - .pi / 6)
        ))
        arrow.move(to: to)
        arrow.addLine(to: CGPoint(
            x: to.x - arrowLength * cos(angle + .pi / 6),
            y: to.y - arrowLength * sin(angle + .pi / 6)
        ))

        context.stroke(
            arrow,
            with: .color(AppTheme.cometGold),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawCompletedTraces(in context: inout GraphicsContext, size: CGSize) {
        for points in viewModel.completedTraces {
            drawCometTrail(points, in: &context, size: size, isActive: false)
        }
    }

    private func drawActiveTrace(in context: inout GraphicsContext, size: CGSize) {
        guard !viewModel.activeTrace.isEmpty else { return }
        drawCometTrail(viewModel.activeTrace, in: &context, size: size, isActive: true)
    }

    private func drawDemonstration(
        in context: inout GraphicsContext,
        size: CGSize,
        at date: Date
    ) {
        guard let startedAt = viewModel.demonstrationStartedAt else { return }

        let timeline = viewModel.demonstrationTimeline
        let frame = timeline.frame(at: date.timeIntervalSince(startedAt))

        for index in 0..<min(frame.completedStrokeCount, timeline.strokes.count) {
            drawDemonstrationTrail(
                timeline.strokes[index].points,
                in: &context,
                size: size,
                showsCometHead: false
            )
        }

        if let activeIndex = frame.activeStrokeIndex,
           timeline.strokes.indices.contains(activeIndex) {
            let activeStroke = timeline.strokes[activeIndex]
            drawDemonstrationTrail(
                activeStroke.points(upTo: frame.activeProgress),
                in: &context,
                size: size,
                showsCometHead: true
            )
        }
    }

    private func drawDemonstrationTrail(
        _ points: [LetterPoint],
        in context: inout GraphicsContext,
        size: CGSize,
        showsCometHead: Bool
    ) {
        guard let last = points.last else { return }
        let head = renderedGlyph(last, in: size)

        if points.count > 1 {
            let demonstrationPath = path(for: points, in: size)
            context.stroke(
                demonstrationPath,
                with: .color(AppTheme.cometPurple.opacity(0.30)),
                style: StrokeStyle(lineWidth: 22, lineCap: .round, lineJoin: .round)
            )
            context.stroke(
                demonstrationPath,
                with: .linearGradient(
                    Gradient(colors: [AppTheme.cometGold, AppTheme.cometCyan, .white]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                ),
                style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
            )
        } else {
            context.fill(
                Path(ellipseIn: CGRect(x: head.x - 5, y: head.y - 5, width: 10, height: 10)),
                with: .color(AppTheme.cometGold)
            )
        }

        guard showsCometHead else { return }
        context.fill(
            Path(ellipseIn: CGRect(x: head.x - 14, y: head.y - 14, width: 28, height: 28)),
            with: .color(AppTheme.cometGold.opacity(0.30))
        )
        context.fill(
            Path(ellipseIn: CGRect(x: head.x - 6, y: head.y - 6, width: 12, height: 12)),
            with: .color(.white)
        )
    }

    private func drawCometTrail(
        _ points: [LetterPoint],
        in context: inout GraphicsContext,
        size: CGSize,
        isActive: Bool
    ) {
        if points.count == 1 {
            let center = renderedGlyph(points[0], in: size)
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16)),
                with: .color(AppTheme.cometCyan)
            )
            return
        }

        let tracePath = path(for: points, in: size)
        context.stroke(
            tracePath,
            with: .color(AppTheme.cometCyan.opacity(0.24)),
            style: StrokeStyle(lineWidth: 22, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            tracePath,
            with: .linearGradient(
                Gradient(colors: [AppTheme.cometPurple, AppTheme.cometCyan, .white]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: size.width, y: size.height)
            ),
            style: StrokeStyle(lineWidth: 11, lineCap: .round, lineJoin: .round)
        )

        if isActive, let last = points.last {
            let head = renderedGlyph(last, in: size)
            context.fill(
                Path(ellipseIn: CGRect(x: head.x - 12, y: head.y - 12, width: 24, height: 24)),
                with: .color(AppTheme.cometCyan.opacity(0.24))
            )
            context.fill(
                Path(ellipseIn: CGRect(x: head.x - 5, y: head.y - 5, width: 10, height: 10)),
                with: .color(.white)
            )
        }
    }

    private func drawStartMarkers(in context: inout GraphicsContext, size: CGSize) {
        let markerIndices: Range<Int>
        if viewModel.assistance == .flySolo {
            // Recall and word missions intentionally reveal only the next taught start point.
            markerIndices = viewModel.currentStrokeIndex..<min(viewModel.currentStrokeIndex + 1, viewModel.glyph.strokes.count)
        } else {
            markerIndices = viewModel.currentStrokeIndex..<viewModel.glyph.strokes.count
        }

        for index in markerIndices {
            let center = renderedGlyph(viewModel.glyph.strokes[index].start, in: size)
            let isCurrent = index == viewModel.currentStrokeIndex
            let glowSize: CGFloat = isCurrent ? 36 : 32

            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - glowSize / 2,
                    y: center.y - glowSize / 2,
                    width: glowSize,
                    height: glowSize
                )),
                with: .color(AppTheme.accentPrimary.opacity(isCurrent ? 0.24 : 0.08))
            )
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22)),
                with: .color(isCurrent ? AppTheme.accentPrimary : AppTheme.cometGuide.opacity(0.55))
            )
            context.draw(
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.backgroundDark),
                at: center
            )
        }
    }

    private func path(for points: [LetterPoint], in size: CGSize) -> Path {
        var result = Path()
        guard let first = points.first else { return result }
        result.move(to: renderedGlyph(first, in: size))
        for point in points.dropFirst() {
            result.addLine(to: renderedGlyph(point, in: size))
        }
        return result
    }
}

enum WordMissionLayout {
    /// Four generous writing slots keep long words finger-friendly on a compact iPhone.
    static let maximumVisibleCharacters = 4

    static func visibleIndices(characterCount: Int, activeIndex: Int) -> [Int] {
        let count = max(characterCount, 0)
        guard count > 0 else { return [] }
        let visibleCount = min(count, maximumVisibleCharacters)
        guard count > visibleCount else { return Array(0..<count) }

        let clampedActiveIndex = min(max(activeIndex, 0), count - 1)
        let preferredStart = clampedActiveIndex - 1
        let start = min(max(preferredStart, 0), count - visibleCount)
        return Array(start..<(start + visibleCount))
    }

    static func aspectRatio(characterCount: Int) -> CGFloat {
        CGFloat(min(max(characterCount, 1), maximumVisibleCharacters)) / 1.18
    }
}

/// Keeps a word on one ruled surface. Long words move through a four-letter window so every
/// active slot remains large enough for a child's finger while completed letters stay visible.
struct WordMissionTracePad: View {
    @ObservedObject var viewModel: CometWriterViewModel
    let characters: [String]
    let activeIndex: Int
    let completedAttempts: [WordLetterAttempt]
    let letterScale: CGFloat
    let pencilOnly: Bool
    let showsWritingLines: Bool

    var body: some View {
        GeometryReader { geometry in
            let visibleIndices = WordMissionLayout.visibleIndices(
                characterCount: characters.count,
                activeIndex: activeIndex
            )
            let visibleCount = max(visibleIndices.count, 1)
            let slotWidth = geometry.size.width / CGFloat(visibleCount)
            let inset = min(12, max(6, slotWidth * 0.08))

            ZStack {
                if showsWritingLines {
                    wordWritingLines(inset: inset)
                }

                HStack(spacing: 0) {
                    ForEach(Array(visibleIndices.enumerated()), id: \.element) { position, index in
                        let character = characters[index]
                        wordSlot(
                            at: index,
                            character: character,
                            contentInset: inset
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(alignment: .trailing) {
                            if position < visibleIndices.count - 1 {
                                Rectangle()
                                    .fill(AppTheme.cometGuide.opacity(0.12))
                                    .frame(width: 1)
                            }
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.cometPaperTop, AppTheme.cometPaperBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.cometCyan.opacity(0.38), lineWidth: 1)
        )
        .shadow(color: AppTheme.cometCyan.opacity(0.14), radius: 18, y: 8)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .transaction { transaction in
            transaction.animation = nil
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Writing surface for the word \(characters.joined())")
        .accessibilityIdentifier("comet-writer-word-trace-pad")
    }

    @ViewBuilder
    private func wordSlot(at index: Int, character: String, contentInset: CGFloat) -> some View {
        if let attempt = completedAttempts[safe: index] {
            CompletedWordLetterView(
                attempt: attempt,
                letterScale: letterScale,
                contentInset: contentInset
            )
        } else if index == activeIndex {
            LetterTracePad(
                viewModel: viewModel,
                letterScale: letterScale,
                pencilOnly: pencilOnly,
                showsWritingLines: false,
                showsSurface: false,
                contentInset: contentInset
            )
            .accessibilityLabel("Write \(character), letter \(index + 1) of \(characters.count)")
        } else {
            ZStack(alignment: .bottom) {
                Color.clear
                Text("\(index + 1)")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundColor(AppTheme.cometGuide.opacity(0.34))
                    .padding(.bottom, 5)
                    .accessibilityHidden(true)
            }
        }
    }

    private func wordWritingLines(inset: CGFloat) -> some View {
        Canvas { context, size in
            let geometry = LetterCanvasGeometry(size: size, contentInset: inset)
            let startX = inset
            let endX = size.width - inset
            let lines: [(position: CGFloat, opacity: Double, dash: [CGFloat])] = [
                (LetterWritingMetrics.topLineY, 0.13, [5, 7]),
                (LetterWritingMetrics.xHeightLineY, 0.18, [5, 7]),
                (LetterWritingMetrics.baselineY, 0.30, []),
                (LetterWritingMetrics.descenderLineY, 0.13, [5, 7])
            ]

            for line in lines {
                let y = geometry.render(LetterPoint(x: 0.5, y: line.position)).y
                var path = Path()
                path.move(to: CGPoint(x: startX, y: y))
                path.addLine(to: CGPoint(x: endX, y: y))
                context.stroke(
                    path,
                    with: .color(AppTheme.cometGuide.opacity(line.opacity)),
                    style: StrokeStyle(lineWidth: 1.5, dash: line.dash)
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct CompletedWordLetterView: View {
    let attempt: WordLetterAttempt
    let letterScale: CGFloat
    let contentInset: CGFloat

    private var displayTransform: LetterDisplayTransform {
        LetterDisplayTransform(scale: letterScale)
    }

    var body: some View {
        Canvas { context, size in
            let lineWidth = min(11, max(5, size.width * 0.10))

            for trace in attempt.traces {
                if trace.count == 1, let point = trace.first {
                    let center = rendered(point, in: size)
                    let diameter = lineWidth * 1.35
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: center.x - diameter / 2,
                            y: center.y - diameter / 2,
                            width: diameter,
                            height: diameter
                        )),
                        with: .color(AppTheme.cometCyan)
                    )
                } else {
                    let tracePath = path(for: trace, in: size)
                    context.stroke(
                        tracePath,
                        with: .color(AppTheme.cometCyan.opacity(0.20)),
                        style: StrokeStyle(
                            lineWidth: lineWidth * 1.8,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    context.stroke(
                        tracePath,
                        with: .linearGradient(
                            Gradient(colors: [AppTheme.cometPurple, AppTheme.cometCyan, .white]),
                            startPoint: .zero,
                            endPoint: CGPoint(x: size.width, y: size.height)
                        ),
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Text("\(attempt.reward.score)")
                .font(.system(.caption2, design: .rounded, weight: .heavy))
                .foregroundColor(AppTheme.backgroundDark)
                .padding(.horizontal, 5)
                .frame(minHeight: 20)
                .background(Capsule().fill(AppTheme.accentPrimary))
                .padding(4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(attempt.character), score \(attempt.reward.score) out of 100")
    }

    private func rendered(_ point: LetterPoint, in size: CGSize) -> CGPoint {
        let displayed = displayTransform.display(point)
        return LetterCanvasGeometry(size: size, contentInset: contentInset).render(displayed)
    }

    private func path(for points: [LetterPoint], in size: CGSize) -> Path {
        var result = Path()
        guard let first = points.first else { return result }
        result.move(to: rendered(first, in: size))
        for point in points.dropFirst() {
            result.addLine(to: rendered(point, in: size))
        }
        return result
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// A UIKit bridge is required here because SwiftUI's DragGesture does not expose whether a touch
/// came from a finger or Apple Pencil. The bridge tracks exactly one accepted touch at a time.
struct TraceTouchCapture: UIViewRepresentable {
    let pencilOnly: Bool
    let onTouch: (TraceTouchPhase, CGPoint) -> Void

    func makeUIView(context: Context) -> TraceTouchView {
        let view = TraceTouchView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = false
        view.pencilOnly = pencilOnly
        view.onTouch = onTouch
        return view
    }

    func updateUIView(_ uiView: TraceTouchView, context: Context) {
        uiView.onTouch = onTouch
        uiView.pencilOnly = pencilOnly
    }
}

final class TraceTouchView: UIView {
    var onTouch: ((TraceTouchPhase, CGPoint) -> Void)?
    var pencilOnly = false {
        didSet {
            guard oldValue != pencilOnly,
                  let activeTouch,
                  !TraceInputPolicy.accepts(activeTouch.type, pencilOnly: pencilOnly) else {
                return
            }
            onTouch?(.cancelled, activeTouch.location(in: self))
            self.activeTouch = nil
        }
    }

    private var activeTouch: UITouch?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil,
              let touch = touches.first(where: {
                  TraceInputPolicy.accepts($0.type, pencilOnly: pencilOnly)
              }) else {
            return
        }

        activeTouch = touch
        onTouch?(.began, touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = matchingActiveTouch(in: touches) else { return }
        // Deliver the system's coalesced Pencil/finger samples in order. This produces a smoother
        // trail without inventing predicted points that the child has not actually drawn.
        let samples = event?.coalescedTouches(for: touch) ?? [touch]
        for sample in samples {
            onTouch?(.moved, sample.location(in: self))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = matchingActiveTouch(in: touches) else { return }
        onTouch?(.ended, touch.location(in: self))
        activeTouch = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = matchingActiveTouch(in: touches) else { return }
        onTouch?(.cancelled, touch.location(in: self))
        activeTouch = nil
    }

    private func matchingActiveTouch(in touches: Set<UITouch>) -> UITouch? {
        guard let activeTouch else { return nil }
        return touches.first(where: { $0 === activeTouch })
    }
}
