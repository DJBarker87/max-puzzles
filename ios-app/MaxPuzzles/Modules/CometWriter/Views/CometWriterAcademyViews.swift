import SwiftUI

private struct FlightShape: Identifiable, Hashable {
    let id: String
    let title: String
    let instruction: String
    let symbol: String
    let stroke: LetterStroke

    static let all: [FlightShape] = [
        FlightShape(
            id: "launch",
            title: "Rocket launch",
            instruction: "Start at the top and fly straight down.",
            symbol: "↕",
            stroke: LetterStroke(points: [
                LetterPoint(x: 0.50, y: 0.12),
                LetterPoint(x: 0.50, y: 0.82)
            ], style: .angular)
        ),
        FlightShape(
            id: "horizon",
            title: "Space horizon",
            instruction: "Start on the left and travel straight across.",
            symbol: "—",
            stroke: LetterStroke(points: [
                LetterPoint(x: 0.16, y: 0.50),
                LetterPoint(x: 0.84, y: 0.50)
            ], style: .angular)
        ),
        FlightShape(
            id: "mountains",
            title: "Moon mountains",
            instruction: "Follow the sharp slants without lifting.",
            symbol: "M",
            stroke: LetterStroke(points: [
                LetterPoint(x: 0.16, y: 0.78),
                LetterPoint(x: 0.34, y: 0.26),
                LetterPoint(x: 0.52, y: 0.78),
                LetterPoint(x: 0.70, y: 0.26),
                LetterPoint(x: 0.84, y: 0.78)
            ], style: .angular)
        ),
        FlightShape(
            id: "orbit",
            title: "Planet orbit",
            instruction: "Start at the top and travel anti-clockwise around.",
            symbol: "○",
            stroke: LetterStroke(points: stride(from: 0, through: 48, by: 1).map { step in
                let angle = -.pi / 2 - CGFloat(step) / 48 * 2 * .pi
                return LetterPoint(
                    x: 0.50 + 0.27 * cos(angle),
                    y: 0.49 + 0.27 * sin(angle)
                )
            }, style: .circular)
        ),
        FlightShape(
            id: "waves",
            title: "Solar waves",
            instruction: "Keep the waves smooth and even.",
            symbol: "≈",
            stroke: LetterStroke(points: [
                LetterPoint(x: 0.13, y: 0.50),
                LetterPoint(x: 0.24, y: 0.32),
                LetterPoint(x: 0.35, y: 0.50),
                LetterPoint(x: 0.46, y: 0.68),
                LetterPoint(x: 0.57, y: 0.50),
                LetterPoint(x: 0.68, y: 0.32),
                LetterPoint(x: 0.79, y: 0.50),
                LetterPoint(x: 0.87, y: 0.64)
            ])
        ),
        FlightShape(
            id: "loops",
            title: "Infinity loop",
            instruction: "Cross the middle and make two smooth loops.",
            symbol: "∞",
            stroke: LetterStroke(points: stride(from: 0, through: 48, by: 1).map { step in
                let angle = CGFloat(step) / 48 * 2 * .pi
                return LetterPoint(
                    x: 0.50 + 0.31 * sin(angle),
                    y: 0.50 + 0.18 * sin(2 * angle)
                )
            })
        )
    ]
}

@MainActor
private final class FlightSchoolViewModel: ObservableObject {
    @Published private(set) var shapeIndex = 0
    @Published private(set) var activeTrace: [LetterPoint] = []
    @Published private(set) var completedTrace: [LetterPoint] = []
    @Published private(set) var progress: CGFloat = 0
    @Published private(set) var mistakes = 0
    @Published private(set) var correctionCounts: [String: Int] = [:]
    @Published private(set) var feedback = "Begin on the green launch star."
    @Published private(set) var isShapeComplete = false
    @Published private(set) var isSessionComplete = false

    private var validator: LetterPathValidator?
    private var warnedDuringGesture = false

    var shape: FlightShape { FlightShape.all[shapeIndex] }

    func begin(at point: LetterPoint) -> Bool {
        guard !isShapeComplete else { return false }
        warnedDuringGesture = false
        var next = LetterPathValidator(stroke: shape.stroke)
        guard next.begin(at: point) == .ready else {
            mistake("start", "Begin on the green launch star.")
            warnedDuringGesture = true
            return false
        }
        validator = next
        activeTrace = [point]
        feedback = "Great start — follow the flight path."
        return true
    }

    func move(to point: LetterPoint) -> Bool {
        guard var next = validator else { return false }
        let result = next.add(point)
        validator = next
        switch result {
        case let .advanced(value):
            progress = value
            if activeTrace.last?.distance(to: point) ?? 1 > 0.003 { activeTrace.append(point) }
            feedback = value > 0.65 ? "Keep going to the finish star." : "Stay on the glowing route."
            return true
        case .wrongDirection:
            return warnOnce("direction", "Turn around and follow the arrow.")
        case .offTrack:
            return warnOnce("track", "Come back to the glowing route.")
        case .belowBaseline:
            return warnOnce("baseline", "Keep your flight above the line.")
        default:
            return false
        }
    }

    func end(at point: LetterPoint) -> Bool {
        guard var next = validator else { return false }
        let result = next.end(at: point)
        validator = nil
        guard result == .complete else {
            activeTrace = []
            progress = 0
            if !warnedDuringGesture { mistake("finish", "Fly all the way to the finish star.") }
            return false
        }

        if activeTrace.last?.distance(to: point) ?? 1 > 0.003 { activeTrace.append(point) }
        completedTrace = activeTrace
        activeTrace = []
        progress = 1
        feedback = "Route complete!"
        isShapeComplete = true
        return true
    }

    func cancel() {
        validator = nil
        activeTrace = []
        progress = 0
        feedback = "Start again on the green star."
    }

    func retry() {
        validator = nil
        activeTrace = []
        completedTrace = []
        progress = 0
        mistakes = 0
        correctionCounts = [:]
        feedback = "Begin on the green launch star."
        isShapeComplete = false
    }

    func advance() {
        guard isShapeComplete else { return }
        if shapeIndex == FlightShape.all.count - 1 {
            isSessionComplete = true
            return
        }
        shapeIndex += 1
        retry()
    }

    private func warnOnce(_ kind: String, _ message: String) -> Bool {
        guard !warnedDuringGesture else { return false }
        warnedDuringGesture = true
        mistake(kind, message)
        return false
    }

    private func mistake(_ kind: String, _ message: String) {
        mistakes += 1
        correctionCounts[kind, default: 0] += 1
        feedback = message
    }
}

struct CometFlightSchoolView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel = FlightSchoolViewModel()
    @ObservedObject private var store = CometLearningStore.shared
    @AppStorage("maxpuzzles.cometWriter.pencilOnly") private var pencilOnly = false
    @AppStorage("maxpuzzles.cometWriter.cometPoints") private var cometPoints = 0

    @State private var latestReward: CometReward?
    @State private var sessionRewards: [CometReward] = []
    @State private var correctionShake: CGFloat = 0

    var body: some View {
        ZStack {
            AppTheme.backgroundDark.ignoresSafeArea()
            StarryBackground(starCount: 24, animateStars: false)

            VStack(spacing: 12) {
                header
                prompt
                flightPad
                feedbackPill
                actions
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)

            if viewModel.isShapeComplete { completionOverlay }
            if viewModel.isSessionComplete { sessionOverlay }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if UIDevice.current.userInterfaceIdiom != .pad { pencilOnly = false }
        }
        .onChange(of: viewModel.isShapeComplete) { completed in
            if completed { awardShape() }
        }
        .accessibilityIdentifier("comet-flight-school")
    }

    private var header: some View {
        HStack(spacing: 12) {
            PremiumIconButton(
                icon: "chevron.left",
                action: { dismiss() },
                size: 48,
                accessibilityLabelText: "Back to Comet Writer"
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("Flight School")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Route \(viewModel.shapeIndex + 1) of \(FlightShape.all.count) · pre-writing control")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.cometCyan)
            }
            Spacer()
            Label("\(displayedCometPoints)", systemImage: "sparkles")
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.cometGold)
                .padding(.horizontal, 10)
                .frame(minHeight: 40)
                .background(Capsule().fill(AppTheme.cometPaperTop))
        }
    }

    private var prompt: some View {
        HStack(spacing: 14) {
            Text(viewModel.shape.symbol)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.cometCyan)
                .frame(width: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.shape.title)
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.textPrimary)
                Text(viewModel.shape.instruction)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .cometChildPanel()
    }

    private var flightPad: some View {
        GeometryReader { geometry in
            ZStack {
                Canvas { context, size in
                    drawPad(context: &context, size: size)
                }
                TraceTouchCapture(pencilOnly: pencilOnly) { phase, location in
                    let point = LetterCanvasGeometry(size: geometry.size, contentInset: 24).unrender(location)
                    let clamped = LetterPoint(
                        x: min(max(point.x, 0), 1),
                        y: min(max(point.y, 0), LetterWritingMetrics.canvasHeight)
                    )
                    let mistakeCountBeforeTouch = viewModel.mistakes
                    switch phase {
                    case .began: _ = viewModel.begin(at: clamped)
                    case .moved: _ = viewModel.move(to: clamped)
                    case .ended: _ = viewModel.end(at: clamped)
                    case .cancelled:
                        viewModel.cancel()
                    }
                    if viewModel.mistakes > mistakeCountBeforeTouch { correctionFeedback() }
                }
                .contentShape(Rectangle())
                .allowsHitTesting(!viewModel.isShapeComplete)
            }
        }
        .frame(minHeight: 330)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(
                    colors: [AppTheme.cometPaperTop, AppTheme.cometPaperBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(AppTheme.cometCyan.opacity(0.38), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .transaction { $0.animation = nil }
        .modifier(ShakeEffect(amount: 4, shakesPerUnit: 2.5, animatableData: reduceMotion ? 0 : correctionShake))
        .accessibilityLabel("Flight School tracing surface for \(viewModel.shape.title)")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }

    private var feedbackPill: some View {
        Text(viewModel.feedback)
            .font(AppTypography.buttonSmall)
            .foregroundColor(AppTheme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(Capsule().fill(AppTheme.cometPaperTop))
            .accessibilityLabel("Flight feedback: \(viewModel.feedback)")
    }

    private var actions: some View {
        HStack {
            Button { viewModel.retry() } label: {
                Label("Start again", systemImage: "arrow.counterclockwise")
                    .font(AppTypography.buttonSmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            Spacer()
            if UIDevice.current.userInterfaceIdiom == .pad {
                Label(pencilOnly ? "Pencil only" : "Finger or Pencil", systemImage: pencilOnly ? "pencil.tip.crop.circle.badge.checkmark" : "hand.draw")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    private var completionOverlay: some View {
        Color.black.opacity(0.60).ignoresSafeArea()
            .overlay {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "paperplane.circle.fill")
                        .font(.system(size: 58))
                        .foregroundColor(AppTheme.accentPrimary)
                    Text("Route complete!")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppTheme.textPrimary)
                    if let reward = latestReward {
                        Text("\(reward.score) / 100")
                            .font(AppTypography.displayMedium)
                            .foregroundColor(AppTheme.cometCyan)
                        Label("+\(reward.points) Comet Points", systemImage: "sparkles")
                            .font(AppTypography.buttonLarge)
                            .foregroundColor(AppTheme.cometGold)
                    }
                    PrimaryButton(
                        viewModel.shapeIndex == FlightShape.all.count - 1 ? "Finish school" : "Next route",
                        icon: "arrow.right",
                        size: .large
                    ) {
                        latestReward = nil
                        viewModel.advance()
                    }
                }
                .padding(AppSpacing.xl)
                .frame(maxWidth: 390)
                .background(RoundedRectangle(cornerRadius: 28).fill(AppTheme.backgroundMid))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(AppTheme.cometCyan.opacity(0.44), lineWidth: 1))
                .padding(AppSpacing.lg)
            }
    }

    private var sessionOverlay: some View {
        Color.black.opacity(0.72).ignoresSafeArea()
            .overlay {
                VStack(spacing: AppSpacing.md) {
                    Text("🚀")
                        .font(.system(size: 54))
                        .accessibilityHidden(true)
                    Text("Flight School complete")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Average \(sessionAverage) out of 100 · +\(sessionRewards.reduce(0) { $0 + $1.points }) points")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppTheme.cometGold)
                        .multilineTextAlignment(.center)
                    PrimaryButton("Back to missions", icon: "checkmark", size: .large) { dismiss() }
                }
                .padding(AppSpacing.xl)
                .frame(maxWidth: 420)
                .background(RoundedRectangle(cornerRadius: 28).fill(AppTheme.backgroundMid))
                .padding(AppSpacing.lg)
            }
    }

    private var sessionAverage: Int {
        guard !sessionRewards.isEmpty else { return 0 }
        return sessionRewards.reduce(0) { $0 + $1.score } / sessionRewards.count
    }

    private var displayedCometPoints: Int {
        store.profiles.count == 1 ? cometPoints : store.activePoints
    }

    private func awardShape() {
        let reward = CometRewardCalculator.reward(mistakes: viewModel.mistakes)
        let metrics = CometPerformanceMetrics(
            averagePathDeviation: 0.025,
            pathDeviationSpread: 0.012,
            averageLengthRatio: 1,
            correctionCounts: viewModel.correctionCounts,
            assistance: .followTheGlow,
            usedHint: false
        )
        cometPoints += reward.points
        CometLearningStore.shared.recordAttempt(
            character: viewModel.shape.symbol,
            mode: .flightSchool,
            reward: reward,
            metrics: metrics,
            traces: [viewModel.completedTrace]
        )
        latestReward = reward
        sessionRewards.append(reward)
        FeedbackManager.shared.haptic(.success)
        SoundEffectsService.shared.play(.starReveal)
    }

    private func correctionFeedback() {
        if !reduceMotion {
            withAnimation(.linear(duration: 0.22)) { correctionShake += 1 }
        }
        FeedbackManager.shared.haptic(.soft)
        SoundEffectsService.shared.play(.wrongMove)
    }

    private func drawPad(context: inout GraphicsContext, size: CGSize) {
        let geometry = LetterCanvasGeometry(size: size, contentInset: 24)
        let stroke = viewModel.shape.stroke
        let guide = path(stroke.points.map(geometry.render))
        context.stroke(guide, with: .color(AppTheme.cometCyan.opacity(0.12)), style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round))
        context.stroke(guide, with: .color(AppTheme.cometGuide.opacity(0.68)), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [8, 7]))

        let arrowFrom = geometry.render(stroke.point(at: 0.10))
        let arrowTo = geometry.render(stroke.point(at: 0.18))
        drawArrow(from: arrowFrom, to: arrowTo, context: &context)

        drawMarker(number: "1", point: geometry.render(stroke.start), color: AppTheme.accentPrimary, context: &context)
        let finish = geometry.render(stroke.end)
        context.stroke(Path(ellipseIn: CGRect(x: finish.x - 9, y: finish.y - 9, width: 18, height: 18)), with: .color(AppTheme.cometGold), lineWidth: 3)

        for trace in [viewModel.completedTrace, viewModel.activeTrace] where !trace.isEmpty {
            let rendered = trace.map(geometry.render)
            context.stroke(path(rendered), with: .color(AppTheme.cometCyan.opacity(0.25)), style: StrokeStyle(lineWidth: 22, lineCap: .round, lineJoin: .round))
            context.stroke(path(rendered), with: .color(.white), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
        }
    }

    private func drawArrow(from: CGPoint, to: CGPoint, context: inout GraphicsContext) {
        let angle = atan2(to.y - from.y, to.x - from.x)
        var arrow = Path()
        arrow.move(to: from)
        arrow.addLine(to: to)
        for offset in [-CGFloat.pi / 6, CGFloat.pi / 6] {
            arrow.move(to: to)
            arrow.addLine(to: CGPoint(x: to.x - 10 * cos(angle + offset), y: to.y - 10 * sin(angle + offset)))
        }
        context.stroke(arrow, with: .color(AppTheme.cometGold), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }

    private func drawMarker(number: String, point: CGPoint, color: Color, context: inout GraphicsContext) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - 12, y: point.y - 12, width: 24, height: 24)), with: .color(color))
        context.draw(Text(number).font(.system(size: 12, weight: .bold)).foregroundColor(AppTheme.backgroundDark), at: point)
    }

    private func path(_ points: [CGPoint]) -> Path {
        var result = Path()
        guard let first = points.first else { return result }
        result.move(to: first)
        for point in points.dropFirst() { result.addLine(to: point) }
        return result
    }
}

struct CometPaperTransferView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CometLearningStore.shared
    @AppStorage("maxpuzzles.cometWriter.cometPoints") private var cometPoints = 0

    @State private var characters: [String]
    @State private var index = 0
    @State private var showsExample = true
    @State private var rewards: [CometReward] = []
    @State private var isComplete = false

    init() {
        let recommended = CometLearningStore.shared.recommendedCharacters(
            from: LetterLibrary.practiceOrder,
            count: 3
        )
        _characters = State(initialValue: recommended.isEmpty ? ["c", "a", "m"] : recommended)
    }

    private var glyph: LetterGlyph { LetterLibrary.glyph(for: characters[index])! }

    var body: some View {
        ZStack {
            AppTheme.backgroundDark.ignoresSafeArea()
            StarryBackground(starCount: 22, animateStars: false)

            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    header
                    instructionCard
                    paperPreview
                    postureCard
                    selfCheck
                }
                .frame(maxWidth: 720)
                .padding(AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .scrollIndicators(.hidden)

            if isComplete { completionOverlay }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear { LetterSpeechService.shared.speak(glyph) }
        .onDisappear { LetterSpeechService.shared.stop() }
        .accessibilityIdentifier("comet-paper-transfer")
    }

    private var header: some View {
        HStack(spacing: 12) {
            PremiumIconButton(icon: "chevron.left", action: { dismiss() }, size: 48, accessibilityLabelText: "Back to Comet Writer")
            VStack(alignment: .leading, spacing: 2) {
                Text("Paper Mission")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Symbol \(index + 1) of \(characters.count) · screen to real paper")
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.cometCyan)
            }
            Spacer()
            Label("\(displayedCometPoints)", systemImage: "sparkles")
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.cometGold)
        }
    }

    private var instructionCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 28))
                .foregroundColor(AppTheme.cometGold)
            VStack(alignment: .leading, spacing: 4) {
                Text("Write \(glyph.formationName) three times on paper")
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.textPrimary)
                Text(glyph.formationCue)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
            PremiumIconButton(icon: "speaker.wave.2.fill", action: { LetterSpeechService.shared.speak(glyph) }, size: 44, iconColor: AppTheme.cometCyan, accessibilityLabelText: "Hear the formation")
        }
        .padding(AppSpacing.md)
        .cometChildPanel()
    }

    private var paperPreview: some View {
        VStack(spacing: 10) {
            if showsExample {
                PaperGlyphPreview(glyph: glyph)
                    .frame(height: 250)
                    .transition(.opacity)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 38))
                        .foregroundColor(AppTheme.cometPurple)
                    Text("Example hidden — write from memory")
                        .font(AppTypography.buttonMedium)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, minHeight: 250)
                .background(RoundedRectangle(cornerRadius: 24).fill(AppTheme.cometPaperTop))
            }

            Button {
                showsExample.toggle()
            } label: {
                Label(showsExample ? "Hide example" : "Show example", systemImage: showsExample ? "eye.slash" : "eye")
                    .font(AppTypography.buttonSmall)
                    .foregroundColor(AppTheme.cometCyan)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private var postureCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: store.activeWritingHand == .left ? "hand.raised.fill" : "hand.raised")
                .font(.system(size: 23))
                .foregroundColor(AppTheme.cometCyan)
            Text(
                store.activeWritingHand == .left
                    ? "Left-handed: tilt the top of the paper slightly right and keep your hand below the writing line."
                    : "Right-handed: tilt the top of the paper slightly left and keep your helping hand steady on the page."
            )
            .font(AppTypography.bodySmall)
            .foregroundColor(AppTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .cometChildPanel()
    }

    private var selfCheck: some View {
        VStack(spacing: 12) {
            Text("How did your best one look?")
                .font(AppTypography.titleSmall)
                .foregroundColor(AppTheme.textPrimary)
            Text("Choose honestly — every answer earns points for practising.")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
            HStack(spacing: 10) {
                assessmentButton("Try again", icon: "arrow.counterclockwise", score: 60, color: AppTheme.cometPurple)
                assessmentButton("Nearly", icon: "hand.thumbsup.fill", score: 78, color: AppTheme.cometCyan)
                assessmentButton("Nailed it", icon: "star.fill", score: 92, color: AppTheme.accentPrimary)
            }
        }
        .padding(AppSpacing.md)
        .cometChildPanel()
    }

    private func assessmentButton(_ title: String, icon: String, score: Int, color: Color) -> some View {
        Button { assess(score: score) } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 22, weight: .bold))
                Text(title).font(AppTypography.buttonSmall)
            }
            .foregroundColor(score >= 90 ? AppTheme.backgroundDark : AppTheme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(RoundedRectangle(cornerRadius: 14).fill(color.opacity(score >= 90 ? 1 : 0.34)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), self-check")
    }

    private var completionOverlay: some View {
        Color.black.opacity(0.70).ignoresSafeArea()
            .overlay {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "doc.badge.checkmark.fill")
                        .font(.system(size: 58))
                        .foregroundColor(AppTheme.accentPrimary)
                    Text("Paper Mission complete")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppTheme.textPrimary)
                    Text("You transferred \(characters.count) formations off screen and earned \(rewards.reduce(0) { $0 + $1.points }) Comet Points.")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    PrimaryButton("Back to missions", icon: "checkmark", size: .large) { dismiss() }
                }
                .padding(AppSpacing.xl)
                .frame(maxWidth: 430)
                .background(RoundedRectangle(cornerRadius: 28).fill(AppTheme.backgroundMid))
                .padding(AppSpacing.lg)
            }
    }

    private var displayedCometPoints: Int {
        store.profiles.count == 1 ? cometPoints : store.activePoints
    }

    private func assess(score: Int) {
        let reward = CometReward(
            score: score,
            characterPoints: CometRewardCalculator.characterPoints(for: score),
            wordBonusPoints: 0
        )
        let metrics = CometPerformanceMetrics(
            averagePathDeviation: 0,
            pathDeviationSpread: 0,
            averageLengthRatio: 1,
            correctionCounts: [:],
            assistance: .connectTheStars,
            usedHint: showsExample
        )
        cometPoints += reward.points
        store.recordAttempt(
            character: glyph.character,
            mode: .paperTransfer,
            reward: reward,
            metrics: metrics,
            traces: []
        )
        rewards.append(reward)
        FeedbackManager.shared.haptic(.success)
        SoundEffectsService.shared.play(.correctMove)

        if index == characters.count - 1 {
            isComplete = true
        } else {
            index += 1
            showsExample = true
            LetterSpeechService.shared.speak(glyph)
        }
    }
}

private struct PaperGlyphPreview: View {
    let glyph: LetterGlyph

    var body: some View {
        Canvas { context, size in
            let geometry = LetterCanvasGeometry(size: size, contentInset: 20)
            for (line, opacity, dash) in [
                (LetterWritingMetrics.topLineY, 0.13, [CGFloat(5), 7]),
                (LetterWritingMetrics.xHeightLineY, 0.19, [CGFloat(5), 7]),
                (LetterWritingMetrics.baselineY, 0.34, [CGFloat]()),
                (LetterWritingMetrics.descenderLineY, 0.13, [CGFloat(5), 7])
            ] {
                let y = geometry.render(LetterPoint(x: 0.5, y: line)).y
                var linePath = Path()
                linePath.move(to: CGPoint(x: 18, y: y))
                linePath.addLine(to: CGPoint(x: size.width - 18, y: y))
                context.stroke(linePath, with: .color(AppTheme.cometGuide.opacity(opacity)), style: StrokeStyle(lineWidth: 1.5, dash: dash))
            }

            for (index, stroke) in glyph.strokes.enumerated() {
                let rendered = stroke.points.map(geometry.render)
                var path = Path()
                if let first = rendered.first {
                    path.move(to: first)
                    for point in rendered.dropFirst() { path.addLine(to: point) }
                }
                context.stroke(path, with: .color(AppTheme.cometCyan), style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                let start = geometry.render(stroke.start)
                context.fill(Path(ellipseIn: CGRect(x: start.x - 10, y: start.y - 10, width: 20, height: 20)), with: .color(AppTheme.accentPrimary))
                context.draw(Text("\(index + 1)").font(.system(size: 10, weight: .bold)).foregroundColor(AppTheme.backgroundDark), at: start)
            }
        }
        .background(RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [AppTheme.cometPaperTop, AppTheme.cometPaperBottom], startPoint: .top, endPoint: .bottom)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.cometCyan.opacity(0.34), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityLabel("Formation example for \(glyph.formationName)")
    }
}

struct CometConstellationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CometLearningStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedGlyph: LetterGlyph?
    @State private var practiceGlyph: LetterGlyph?

    private let columns = [GridItem(.adaptive(minimum: 54), spacing: 12)]

    var body: some View {
        ZStack {
            AppTheme.backgroundDark.ignoresSafeArea()
            StarryBackground(starCount: 42, animateStars: !reduceMotion)

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header
                    progressCard
                    constellationGrid
                    if let selectedGlyph { selectedCard(selectedGlyph) }
                    badgeCard
                }
                .frame(maxWidth: 820)
                .padding(AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(
            isPresented: Binding(
                get: { practiceGlyph != nil },
                set: { if !$0 { practiceGlyph = nil } }
            )
        ) {
            if let practiceGlyph { CometWriterGameView(startingGlyph: practiceGlyph) }
        }
        .accessibilityIdentifier("comet-constellation")
    }

    private var header: some View {
        HStack(spacing: AppSpacing.md) {
            PremiumIconButton(icon: "chevron.left", action: { dismiss() }, size: 48, accessibilityLabelText: "Back to Comet Writer")
            VStack(alignment: .leading, spacing: 2) {
                Text("My Constellation")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Every secure formation lights a brighter star")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(litCount) of \(LetterLibrary.all.count) stars lit")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(Int(Double(litCount) / Double(LetterLibrary.all.count) * 100))%")
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.cometGold)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.cometPaperTop)
                    Capsule().fill(LinearGradient(colors: [AppTheme.cometPurple, AppTheme.cometCyan, AppTheme.cometGold], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * CGFloat(litCount) / CGFloat(LetterLibrary.all.count))
                }
            }
            .frame(height: 12)
            Text("Tap any star to see its score or launch another practice flight.")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(AppSpacing.md)
        .cometChildPanel()
    }

    private var constellationGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(LetterLibrary.all) { glyph in
                let mastery = store.mastery(for: glyph.character)
                Button { selectedGlyph = glyph } label: {
                    ZStack {
                        Circle()
                            .fill(starColor(mastery).opacity(mastery == .new ? 0.15 : 0.28))
                            .frame(width: 52, height: 52)
                        if mastery >= .secure {
                            Image(systemName: "star.fill")
                                .font(.system(size: mastery == .mastered ? 46 : 40))
                                .foregroundColor(starColor(mastery))
                                .shadow(color: starColor(mastery).opacity(0.45), radius: mastery == .mastered ? 10 : 5)
                        } else {
                            Image(systemName: mastery == .new ? "star" : "star.leadinghalf.filled")
                                .font(.system(size: 40))
                                .foregroundColor(starColor(mastery))
                        }
                        Text(glyph.character)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(mastery >= .secure ? AppTheme.backgroundDark : AppTheme.textPrimary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(glyph.formationName), \(mastery.title)")
            }
        }
        .padding(AppSpacing.md)
        .background(RoundedRectangle(cornerRadius: 24).fill(AppTheme.backgroundMid.opacity(0.58)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.cometPurple.opacity(0.22), lineWidth: 1))
    }

    private func selectedCard(_ glyph: LetterGlyph) -> some View {
        let mastery = store.mastery(for: glyph.character)
        return HStack(spacing: 16) {
            Text(glyph.character)
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundColor(starColor(mastery))
                .frame(width: 70)
            VStack(alignment: .leading, spacing: 4) {
                Text(glyph.formationName.capitalized)
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                Text("\(mastery.title) · best \(store.bestScore(for: glyph.character).map { "\($0)/100" } ?? "not scored")")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                Text(glyph.formationCue)
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.cometCyan)
            }
            Spacer(minLength: 0)
            Button { practiceGlyph = glyph } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(AppTheme.backgroundDark)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(AppTheme.accentPrimary))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Practise \(glyph.formationName)")
        }
        .padding(AppSpacing.md)
        .cometChildPanel()
    }

    private var badgeCard: some View {
        HStack(spacing: 12) {
            milestone(title: "First Light", threshold: 1, icon: "sparkle")
            milestone(title: "Star Cluster", threshold: 15, icon: "sparkles")
            milestone(title: "Galaxy", threshold: LetterLibrary.all.count, icon: "globe.europe.africa.fill")
        }
        .padding(AppSpacing.md)
        .cometChildPanel()
    }

    private func milestone(title: String, threshold: Int, icon: String) -> some View {
        let unlocked = litCount >= threshold
        return VStack(spacing: 6) {
            Image(systemName: unlocked ? icon : "lock.fill")
                .font(.system(size: 24))
                .foregroundColor(unlocked ? AppTheme.cometGold : AppTheme.textSecondary)
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(unlocked ? AppTheme.textPrimary : AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .accessibilityElement(children: .combine)
        .accessibilityValue(unlocked ? "Unlocked" : "Locked at \(threshold) secure stars")
    }

    private var litCount: Int {
        LetterLibrary.all.filter { store.mastery(for: $0.character) >= .secure }.count
    }

    private func starColor(_ level: CometMasteryLevel) -> Color {
        switch level {
        case .new: return AppTheme.textSecondary
        case .practising: return AppTheme.cometPurple
        case .secure: return AppTheme.cometCyan
        case .mastered: return AppTheme.cometGold
        }
    }
}

struct CometDailyMissionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CometLearningStore.shared
    @AppStorage("maxpuzzles.cometWriter.cometPoints") private var cometPoints = 0
    @AppStorage("maxpuzzles.cometWriter.dailyBonusKeys") private var dailyBonusKeys = ""

    @State private var destination: Stage?

    private enum Stage: Int, CaseIterable, Hashable {
        case warmup
        case guided
        case sound
        case word
        case paper

        var title: String {
            switch self {
            case .warmup: return "Warm up your hand"
            case .guided: return "Build one formation"
            case .sound: return "Listen and recall"
            case .word: return "Write a whole word"
            case .paper: return "Take it onto paper"
            }
        }

        var detail: String {
            switch self {
            case .warmup: return "Flight School route"
            case .guided: return "Three levels of help"
            case .sound: return "Three sound clues"
            case .word: return "Two words on one line"
            case .paper: return "Real-pencil transfer"
            }
        }

        var icon: String {
            switch self {
            case .warmup: return "paperplane.fill"
            case .guided: return "pencil.line"
            case .sound: return "ear.and.waveform"
            case .word: return "textformat.abc"
            case .paper: return "doc.text.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundDark.ignoresSafeArea()
            StarryBackground(starCount: 28, animateStars: false)

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header
                    hero
                    stageList
                    rewardCard
                }
                .frame(maxWidth: 700)
                .padding(AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(
            isPresented: Binding(
                get: { destination != nil },
                set: { if !$0 { destination = nil } }
            )
        ) {
            if let destination { destinationView(destination) }
        }
        .onAppear { awardDailyBonusIfNeeded() }
        .onChange(of: isComplete) { completed in
            if completed { awardDailyBonusIfNeeded() }
        }
        .accessibilityIdentifier("comet-daily-mission")
    }

    private var header: some View {
        HStack(spacing: AppSpacing.md) {
            PremiumIconButton(icon: "chevron.left", action: { dismiss() }, size: 48, accessibilityLabelText: "Back to Comet Writer")
            VStack(alignment: .leading, spacing: 2) {
                Text("Today’s Comet Mission")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Text("A balanced 10-minute writing journey")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
    }

    private var hero: some View {
        HStack(spacing: AppSpacing.md) {
            Image("alien_nova")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                Text(isComplete ? "Mission accomplished!" : "\(completedStages.count) of \(Stage.allCases.count) stages complete")
                    .font(AppTypography.titleSmall)
                    .foregroundColor(AppTheme.textPrimary)
                ProgressView(value: Double(completedStages.count), total: Double(Stage.allCases.count))
                    .tint(AppTheme.accentPrimary)
                Text(isComplete ? "Your 25-point mission bonus is secured." : "Next up: \(nextStage?.title ?? "Finish strong")")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(isComplete ? AppTheme.cometGold : AppTheme.cometCyan)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [AppTheme.cometPurple.opacity(0.28), AppTheme.backgroundMid], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.cometPurple.opacity(0.36), lineWidth: 1))
    }

    private var stageList: some View {
        VStack(spacing: 10) {
            ForEach(Stage.allCases, id: \.self) { stage in
                stageRow(stage)
            }
        }
    }

    private func stageRow(_ stage: Stage) -> some View {
        let completed = stageIsComplete(stage)
        let available = stage == nextStage || completed || isComplete
        return Button {
            if available { destination = stage }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(completed ? AppTheme.accentPrimary : (available ? AppTheme.cometPurple.opacity(0.34) : AppTheme.cometPaperTop))
                        .frame(width: 50, height: 50)
                    Image(systemName: completed ? "checkmark" : (available ? stage.icon : "lock.fill"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(completed ? AppTheme.backgroundDark : (available ? AppTheme.cometCyan : AppTheme.textSecondary))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(stage.title)
                        .font(AppTypography.buttonLarge)
                        .foregroundColor(available ? AppTheme.textPrimary : AppTheme.textSecondary)
                    Text(completed ? "Complete today" : stage.detail)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(completed ? AppTheme.accentPrimary : AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
                if available && !completed {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.cometCyan)
                }
            }
            .padding(AppSpacing.md)
            .cometChildPanel()
        }
        .buttonStyle(.plain)
        .disabled(!available)
        .accessibilityLabel("Stage \(stage.rawValue + 1), \(stage.title), \(completed ? "complete" : available ? "ready" : "locked")")
    }

    private var rewardCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.system(size: 25))
                .foregroundColor(AppTheme.cometGold)
            VStack(alignment: .leading, spacing: 3) {
                Text("Daily mission bonus · 25 points")
                    .font(AppTypography.buttonLarge)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Awarded once per child per day after all five stages.")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: isComplete ? "checkmark.seal.fill" : "seal")
                .font(.system(size: 28))
                .foregroundColor(isComplete ? AppTheme.accentPrimary : AppTheme.textSecondary)
        }
        .padding(AppSpacing.md)
        .cometChildPanel()
    }

    @ViewBuilder
    private func destinationView(_ stage: Stage) -> some View {
        switch stage {
        case .warmup:
            CometFlightSchoolView()
        case .guided:
            CometWriterGameView(startingGlyph: recommendedGlyph)
        case .sound:
            AdvancedWritingGameView(
                mission: .phonics,
                recallCharacters: LetterRecallCatalog.teachingOrder,
                words: store.availableWords,
                sessionLength: 3
            )
        case .word:
            AdvancedWritingGameView(
                mission: .wordWriting,
                words: store.availableWords,
                sessionLength: 2
            )
        case .paper:
            CometPaperTransferView()
        }
    }

    private var recommendedGlyph: LetterGlyph {
        let character = store.recommendedCharacters(from: LetterLibrary.practiceOrder, count: 1).first ?? "c"
        return LetterLibrary.glyph(for: character)!
    }

    private var todayAttempts: [CometAttemptRecord] {
        let start = Calendar.current.startOfDay(for: Date())
        return store.activeAttempts.filter { $0.timestamp >= start }
    }

    private var completedStages: [Stage] {
        Stage.allCases.filter(stageIsComplete)
    }

    private var nextStage: Stage? {
        Stage.allCases.first { !stageIsComplete($0) }
    }

    private var isComplete: Bool { completedStages.count == Stage.allCases.count }

    private func stageIsComplete(_ stage: Stage) -> Bool {
        switch stage {
        case .warmup:
            return todayAttempts.filter { $0.mode == .flightSchool }.count >= FlightShape.all.count
        case .guided:
            return todayAttempts.contains { $0.mode == .guided }
        case .sound:
            return todayAttempts.filter { $0.mode == .phonics }.count >= 3
        case .word:
            return todayAttempts.filter {
                ($0.mode == .word || $0.mode == .alienMail) && $0.pointsEarned >= 30
            }.count >= 2
        case .paper:
            return todayAttempts.filter { $0.mode == .paperTransfer }.count >= 3
        }
    }

    private func awardDailyBonusIfNeeded() {
        guard isComplete else { return }
        let key = "\(store.activeProfileID.uuidString)-\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
        var keys = Set(dailyBonusKeys.split(separator: ",").map(String.init))
        guard !keys.contains(key) else { return }
        keys.insert(key)
        dailyBonusKeys = keys.sorted().suffix(90).joined(separator: ",")
        cometPoints += 25
        let bonusReward = CometReward(
            score: 100,
            characterPoints: 25,
            wordBonusPoints: 0
        )
        store.recordAttempt(
            character: "★",
            mode: .dailyMission,
            reward: bonusReward,
            metrics: CometPerformanceMetrics(
                averagePathDeviation: 0,
                pathDeviationSpread: 0,
                averageLengthRatio: 1,
                correctionCounts: [:],
                assistance: .connectTheStars,
                usedHint: false
            ),
            traces: []
        )
        FeedbackManager.shared.haptic(.levelComplete)
        SoundEffectsService.shared.play(.levelComplete)
    }
}

struct CometQuickPracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CometLearningStore.shared

    @State private var group: SymbolGroup = .lowercase
    @State private var selectedGlyph: LetterGlyph?

    private enum SymbolGroup: String, CaseIterable, Identifiable {
        case lowercase = "abc"
        case capitals = "ABC"
        case numbers = "123"

        var id: String { rawValue }
    }

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 9)]

    var body: some View {
        ZStack {
            AppTheme.backgroundDark.ignoresSafeArea()
            StarryBackground(starCount: 24, animateStars: false)

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header
                    recommendedCard

                    Picker("Symbol group", selection: $group) {
                        ForEach(SymbolGroup.allCases) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("comet-quick-practice-group")

                    LazyVGrid(columns: columns, spacing: 9) {
                        ForEach(visibleGlyphs) { glyph in
                            glyphButton(glyph)
                        }
                    }
                    .padding(AppSpacing.md)
                    .cometChildPanel()
                }
                .frame(maxWidth: 760)
                .padding(AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(
            isPresented: Binding(
                get: { selectedGlyph != nil },
                set: { if !$0 { selectedGlyph = nil } }
            )
        ) {
            if let selectedGlyph { CometWriterGameView(startingGlyph: selectedGlyph) }
        }
        .accessibilityIdentifier("comet-quick-practice")
    }

    private var header: some View {
        HStack(spacing: AppSpacing.md) {
            PremiumIconButton(
                icon: "chevron.left",
                action: { dismiss() },
                size: 48,
                accessibilityLabelText: "Back to Comet Writer"
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("Quick Practice")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Pick one symbol and start straight away")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
    }

    private var recommendedCard: some View {
        let recommendations = store.recommendedCharacters(
            from: LetterLibrary.practiceOrder,
            count: 3
        ).compactMap(LetterLibrary.glyph(for:))

        return VStack(alignment: .leading, spacing: 10) {
            Label("Good ones to practise next", systemImage: "wand.and.stars")
                .font(AppTypography.buttonLarge)
                .foregroundColor(AppTheme.cometGold)
            HStack(spacing: 10) {
                ForEach(recommendations) { glyph in
                    Button { launch(glyph) } label: {
                        VStack(spacing: 2) {
                            Text(glyph.character)
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                            Text(store.mastery(for: glyph.character).title)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 66)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.cometPurple.opacity(0.28)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Practise \(glyph.formationName), recommended")
                }
            }
        }
        .padding(AppSpacing.md)
        .cometChildPanel()
    }

    private func glyphButton(_ glyph: LetterGlyph) -> some View {
        let mastery = store.mastery(for: glyph.character)
        return Button { launch(glyph) } label: {
            VStack(spacing: 1) {
                Text(glyph.character)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                if let score = store.bestScore(for: glyph.character) {
                    Text("\(score)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                }
            }
            .foregroundColor(mastery == .mastered ? AppTheme.backgroundDark : AppTheme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(symbolColor(mastery))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            store.bestScore(for: glyph.character).map {
                "Practise \(glyph.formationName), best score \($0)"
            } ?? "Practise \(glyph.formationName), not scored"
        )
    }

    private var visibleGlyphs: [LetterGlyph] {
        switch group {
        case .lowercase:
            return LetterLibrary.all.filter { !$0.isNumber && !$0.isUppercase }
        case .capitals:
            return LetterLibrary.uppercase
        case .numbers:
            return LetterLibrary.all.filter(\.isNumber)
        }
    }

    private func launch(_ glyph: LetterGlyph) {
        selectedGlyph = glyph
        FeedbackManager.shared.haptic(.light)
        SoundEffectsService.shared.play(.cardTap)
    }

    private func symbolColor(_ level: CometMasteryLevel) -> Color {
        switch level {
        case .new: return AppTheme.cometPaperTop
        case .practising: return AppTheme.cometPurple.opacity(0.40)
        case .secure: return AppTheme.cometCyan.opacity(0.42)
        case .mastered: return AppTheme.accentPrimary
        }
    }
}

private extension View {
    func cometChildPanel() -> some View {
        background(RoundedRectangle(cornerRadius: 18).fill(AppTheme.backgroundMid.opacity(0.90)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}
