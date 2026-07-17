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
struct DotColourStroke: Identifiable, Equatable {
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

/// Small pure state machine shared by the UI and tests. Progress is counted by unique semantic
/// regions, never by taps or pencil gestures, and tap/shade work contributes to the same result.
struct DotColouringProgress: Equatable {
    let requiredRegionIDs: Set<Int>
    private(set) var tapFilledRegionIDs: Set<Int>
    private(set) var shadedRegionIDs: Set<Int>

    init(
        requiredRegionIDs: Set<Int>,
        initiallyCompletedRegionIDs: Set<Int> = []
    ) {
        self.requiredRegionIDs = requiredRegionIDs
        let validInitial = initiallyCompletedRegionIDs.intersection(requiredRegionIDs)
        tapFilledRegionIDs = validInitial
        shadedRegionIDs = []
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
    mutating func recordStroke(in regionID: Int) -> Bool {
        guard requiredRegionIDs.contains(regionID) else { return false }
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
    static let minimumNormalizedShadeDistance: CGFloat = 0.02

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

/// A full-screen activity presented after the numbered trail is complete. Its only model
/// dependency is the semantic plan: every colour owns a precise alpha mask, so animal markings,
/// vehicle details and the background are coloured according to what they actually are.
struct DotToDotColouringStage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let puzzle: DotPuzzle
    let plan: DotSemanticColourPlan
    let onRegionCompleted: (Int) -> Void
    let onStrokeRecorded: (DotColourStroke) -> Void
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

    init(
        puzzle: DotPuzzle,
        plan: DotSemanticColourPlan,
        initialCompletedRegions: Set<Int> = [],
        onRegionCompleted: @escaping (Int) -> Void,
        onStrokeRecorded: @escaping (DotColourStroke) -> Void = { _ in },
        onReset: @escaping () -> Void,
        onDone: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.puzzle = puzzle
        self.plan = plan
        self.onRegionCompleted = onRegionCompleted
        self.onStrokeRecorded = onStrokeRecorded
        self.onReset = onReset
        self.onDone = onDone
        self.onClose = onClose

        let regionIDs = Set(plan.swatches.map(\.id))
        _selectedSwatchID = State(initialValue: plan.swatches.first?.id ?? 1)
        _progress = State(
            initialValue: DotColouringProgress(
                requiredRegionIDs: regionIDs,
                initiallyCompletedRegionIDs: initialCompletedRegions
            )
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
                            artworkCanvas
                                .layoutPriority(2)

                            controlPanel(compact: false)
                                .frame(
                                    minWidth: 250,
                                    idealWidth: min(320, geometry.size.width * 0.30),
                                    maxWidth: 350
                                )
                        }
                    } else {
                        artworkCanvas
                            .layoutPriority(2)

                        controlPanel(compact: true)
                    }
                }
                .padding(.horizontal, landscape ? 16 : 12)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: closeStage) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close colouring")
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

            Spacer(minLength: 4)

            Button {
                guard progress.isComplete else { return }
                SoundEffectsService.shared.play(.levelComplete)
                FeedbackManager.shared.haptic(.levelComplete)
                onDone()
                // Drive dismissal from the presented view as well as the parent's binding. This
                // avoids a SwiftUI fullScreenCover race where the reward view is updated behind
                // a cover that has not yet begun dismissing.
                dismiss()
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
            .disabled(!progress.isComplete)
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
                } label: {
                    Label(candidate.shortTitle, systemImage: candidate.icon)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(mode == candidate ? Color(hex: "071020") : Color.white.opacity(0.78))
                        .frame(maxWidth: .infinity, minHeight: 42)
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
                                .font(.system(size: compact ? 10 : 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(selected ? 1 : 0.72))
                                .lineLimit(2)
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
    }

    private func applyTap(_ regionID: Int?) {
        guard let regionID else {
            message = "Try a numbered space inside the picture."
            FeedbackManager.shared.haptic(.light)
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
        SoundEffectsService.shared.play(progress.isComplete ? .starReveal : .correctMove)
        FeedbackManager.shared.haptic(.correctMove)
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
            if let last = stroke.points.last {
                let distance = hypot(point.x - last.x, point.y - last.y)
                guard distance >= 0.0015 else { return }
            }
            stroke.points.append(point)
            activeStroke = stroke

        case .ended:
            guard var finished = activeStroke else { return }
            if finished.points.last != point { finished.points.append(point) }
            guard isMeaningfulInMaskStroke(finished) else {
                activeStroke = nil
                message = "Make a longer shading stroke inside the numbered space."
                FeedbackManager.shared.haptic(.light)
                return
            }
            strokes.append(finished)
            activeStroke = nil
            onStrokeRecorded(finished)

            var updated = progress
            let newlyCompleted = updated.recordStroke(in: finished.regionID)
            progress = updated
            if newlyCompleted { onRegionCompleted(finished.regionID) }
            message = progress.isComplete
                ? "Beautiful shading—your picture is ready!"
                : "Lovely shading. Pick another numbered colour when you are ready."
            SoundEffectsService.shared.play(progress.isComplete ? .starReveal : .correctMove)
            FeedbackManager.shared.haptic(.correctMove)

        case .cancelled:
            activeStroke = nil
        }
    }

    private func reset() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.20)) {
            progress.reset()
            strokes = []
            activeStroke = nil
            wrongRegionID = nil
            selectedSwatchID = plan.swatches.first?.id ?? 1
            message = "Fresh canvas—start with pot 1."
        }
        onReset()
        FeedbackManager.shared.haptic(.light)
    }

    private func closeStage() {
        onClose()
        dismiss()
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
        let captured = wrongRegionID
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if wrongRegionID == captured { wrongRegionID = nil }
        }
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
                    DotColourStrokeLayer(
                        strokes: strokesForSwatch(swatch.id),
                        color: Color(hex: swatch.hex)
                    )
                    .mask {
                        DotColourAtlasTileView(art: swatch.maskArt, tint: .white)
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
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Image(art.assetName)
                    .renderingMode(.template)
                    .resizable()
                    .interpolation(.high)
                    .foregroundStyle(tint)
                    .frame(
                        width: geometry.size.width * CGFloat(art.columns),
                        height: geometry.size.height * CGFloat(art.rows)
                    )
                    .offset(
                        x: -CGFloat(art.column) * geometry.size.width,
                        y: -CGFloat(art.row) * geometry.size.height
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .clipped()
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
    private final class Bitmap {
        let width: Int
        let height: Int
        let alpha: [UInt8]

        init(width: Int, height: Int, alpha: [UInt8]) {
            self.width = width
            self.height = height
            self.alpha = alpha
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
        cache.totalCostLimit = 16 * 1_024 * 1_024
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

    private static func bitmap(for art: DotPuzzleReferenceArt) -> Bitmap? {
        let key = "\(art.assetName):\(art.column):\(art.row):\(art.columns):\(art.rows)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        guard art.columns > 0, art.rows > 0,
              art.column >= 0, art.column < art.columns,
              art.row >= 0, art.row < art.rows,
              let image = UIImage(named: art.assetName)?.cgImage else { return nil }

        let tileWidth = image.width / art.columns
        let tileHeight = image.height / art.rows
        guard tileWidth > 0, tileHeight > 0,
              let tile = image.cropping(
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
        let result = Bitmap(width: tileWidth, height: tileHeight, alpha: alpha)
        cache.setObject(result, forKey: key, cost: alpha.count)
        return result
    }
}
