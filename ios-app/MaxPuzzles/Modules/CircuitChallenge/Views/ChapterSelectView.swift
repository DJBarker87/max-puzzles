import SwiftUI

/// Chapter selection screen with 3D carousel of large alien cards
struct ChapterSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    private var progress: StoryProgress { appState.storyProgress }

    @State private var selectedChapter: ChapterAlien?
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var viewId: UUID = UUID()  // Force view refresh on appear

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let isLandscape = screenWidth > screenHeight

            ZStack {
                SplashBackground(overlayOpacity: 0.35)

                VStack(spacing: 0) {
                    // Title with total stars - more compact in landscape
                    HStack(spacing: 12) {
                        Text("Story Mode")
                            .font(.system(size: isLandscape ? 22 : 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: AppTheme.connectorGlow.opacity(0.8), radius: 8)
                            .shadow(color: AppTheme.accentPrimary.opacity(0.5), radius: 4)

                        if isLandscape {
                            // Inline stars badge in landscape
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                Text("\(progress.totalStars)/210")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(AppTheme.accentTertiary)
                        }
                    }

                    if !isLandscape {
                        // Portrait: subtitle below
                        HStack(spacing: 12) {
                            Text("Help the aliens!")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))

                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                Text("\(progress.totalStars)")
                                    .font(.system(size: 13, weight: .bold))
                                Text("/210")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .foregroundColor(AppTheme.accentTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.backgroundDark.opacity(0.5))
                            .cornerRadius(10)
                        }
                        .padding(.top, 4)
                    }

                    // 3D Carousel
                    Spacer()

                    // Carousel with navigation arrows
                    ZStack {
                        carouselContent(screenWidth: screenWidth, screenHeight: screenHeight)

                        // Navigation arrows on the sides
                        HStack {
                            // Left arrow (previous chapter)
                            if currentIndex > 0 {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        currentIndex = max(currentIndex - 1, 0)
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(12)
                                        .background(Circle().fill(Color.black.opacity(0.3)))
                                }
                            } else {
                                Spacer().frame(width: 52)
                            }

                            Spacer()

                            // Right arrow (next chapter)
                            if currentIndex < ChapterAlien.all.count - 1 {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        currentIndex = min(currentIndex + 1, ChapterAlien.all.count - 1)
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(12)
                                        .background(Circle().fill(Color.black.opacity(0.3)))
                                }
                            } else {
                                Spacer().frame(width: 52)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .frame(height: screenHeight * 0.55)

                    Spacer()

                    // Progress indicator
                    progressIndicator
                        .padding(.bottom, 16)
                }
            }
        }
        .id(viewId)  // Force view refresh when viewId changes
        .onAppear {
            OrientationManager.shared.unlockAll()
        }
        .navigationTitle("Story Mode")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Force view refresh when returning from game
            viewId = UUID()

            // Check for pending chapter navigation (from level 6 completion after advancing chapters)
            if let pendingChapter = appState.pendingChapterNavigation {
                // Clear the pending navigation first
                appState.pendingChapterNavigation = nil
                // Navigate to the chapter's level select after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    selectedChapter = ChapterAlien.forChapter(pendingChapter)
                    // Also update the carousel to show the correct chapter
                    currentIndex = pendingChapter - 1
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedChapter != nil },
            set: { if !$0 { selectedChapter = nil } }
        )) {
            if let alien = selectedChapter {
                LevelSelectView(
                    chapter: alien.chapter,
                    alien: alien
                )
            }
        }
    }

    // MARK: - Carousel View

    private func carouselContent(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        // Adjust card size based on orientation
        let isLandscape = screenWidth > screenHeight
        let isSmallPhone = screenWidth < 400

        // In landscape: cards are taller relative to screen, narrower width
        // In portrait: cards are wider
        let cardWidthPercent: CGFloat = isLandscape ? 0.35 : (isSmallPhone ? 0.60 : 0.68)
        let cardWidth = screenWidth * cardWidthPercent
        let cardHeight = isLandscape ? screenHeight * 0.75 : screenHeight * 0.52
        let spacing: CGFloat = isLandscape ? 30 : 20

        return ZStack {
            ForEach(0..<ChapterAlien.all.count, id: \.self) { index in
                let alien = ChapterAlien.all[index]
                let offset = CGFloat(index - currentIndex) + (dragOffset / (cardWidth + spacing))
                let absOffset = abs(offset)

                // 3D transforms for sphere effect
                let angle = offset * 30 // degrees of rotation
                let scale = max(0.7, 1 - absOffset * 0.12)
                let zIndex = 10 - absOffset
                let xOffset = offset * cardWidth * 0.58 // show edges of adjacent cards

                // Opacity based on distance
                let opacity = max(0.4, 1 - absOffset * 0.25)

                LargeChapterCard(
                    alien: alien,
                    isUnlocked: progress.isChapterUnlocked(alien.chapter),
                    isCompleted: progress.isChapterCompleted(alien.chapter),
                    isCurrent: index == currentIndex,
                    levelsCompleted: countCompletedLevels(alien.chapter),
                    chapterStars: progress.starsInChapter(alien.chapter),
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    isLandscape: isLandscape,
                    onTap: {
                        if index == currentIndex && progress.isChapterUnlocked(alien.chapter) {
                            selectedChapter = alien
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentIndex = index
                            }
                        }
                    }
                )
                .scaleEffect(scale)
                .rotation3DEffect(
                    .degrees(angle),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .offset(x: xOffset)
                .opacity(opacity)
                .zIndex(zIndex)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold = cardWidth * 0.3
                    let velocity = value.predictedEndLocation.x - value.location.x

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if dragOffset < -threshold || velocity < -200 {
                            currentIndex = min(currentIndex + 1, ChapterAlien.all.count - 1)
                        } else if dragOffset > threshold || velocity > 200 {
                            currentIndex = max(currentIndex - 1, 0)
                        }
                        dragOffset = 0
                    }
                }
        )
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: 8) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(1...10, id: \.self) { chapter in
                    Circle()
                        .fill(progressDotColor(for: chapter))
                        .frame(width: currentIndex == chapter - 1 ? 14 : 10,
                               height: currentIndex == chapter - 1 ? 14 : 10)
                        .overlay(
                            Circle()
                                .stroke(progressDotBorder(for: chapter), lineWidth: 2)
                        )
                        .animation(.spring(response: 0.3), value: currentIndex)
                }
            }

            Text("\(progress.completedChaptersCount) of 10 chapters completed")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func progressDotColor(for chapter: Int) -> Color {
        if progress.isChapterCompleted(chapter) {
            return AppTheme.accentPrimary
        } else if progress.isChapterUnlocked(chapter) {
            return AppTheme.backgroundMid
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    private func progressDotBorder(for chapter: Int) -> Color {
        if progress.isChapterCompleted(chapter) {
            return AppTheme.accentPrimary
        } else if progress.isChapterUnlocked(chapter) {
            return AppTheme.accentPrimary.opacity(0.5)
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    private func countCompletedLevels(_ chapter: Int) -> Int {
        (1...7).filter { progress.isLevelCompleted(chapter: chapter, level: $0) }.count
    }
}

// MARK: - Large Chapter Card

struct LargeChapterCard: View {
    let alien: ChapterAlien
    let isUnlocked: Bool
    let isCompleted: Bool
    let isCurrent: Bool
    let levelsCompleted: Int
    let chapterStars: Int
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let isLandscape: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    /// Scale factor for border widths based on device type
    private var borderScale: CGFloat {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 1.5 : 1.0
        #else
        return 1.5
        #endif
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: isLandscape ? 6 : 16) {
                // Top spacer - equal on both sides for landscape to center content
                Spacer()

                // Alien image - large and prominent
                ZStack {
                    // Calculate sizes once
                    let imageSize = isLandscape ? cardHeight * 0.35 : cardHeight * 0.45
                    let glowSize = imageSize * 1.3

                    // Glow effect for unlocked
                    if isUnlocked {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppTheme.accentPrimary.opacity(0.3),
                                        AppTheme.accentPrimary.opacity(0)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: glowSize * 0.5
                                )
                            )
                            .frame(width: glowSize, height: glowSize)
                    }

                    // Alien image with idle animation when unlocked and current
                    Image(alien.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: cardWidth * 0.85, height: imageSize)
                        .grayscale(isUnlocked ? 0 : 1)
                        .opacity(isUnlocked ? 1 : 0.5)
                        .alienIdleAnimation(style: .float, intensity: isCurrent && isUnlocked ? 1.0 : 0)

                    // Lock overlay
                    if !isUnlocked {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: cardWidth * 0.6, height: cardWidth * 0.6)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Completion checkmark
                    if isCompleted {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accentPrimary)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: AppTheme.accentPrimary.opacity(0.5), radius: 8)

                                    Image(systemName: "checkmark")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: -20, y: 20)
                            }
                            Spacer()
                        }
                        .frame(width: cardWidth * 0.7, height: cardWidth * 0.7)
                    }
                }

                // Only add spacer between alien and text in portrait (wide cards)
                if !isLandscape {
                    Spacer()
                }

                // Chapter info
                VStack(spacing: isLandscape ? 4 : 8) {
                    Text("Chapter \(alien.chapter)")
                        .font(.system(size: isLandscape ? 12 : 14, weight: .medium))
                        .foregroundColor(isUnlocked ? AppTheme.textSecondary : .gray)

                    Text(alien.name)
                        .font(.system(size: isLandscape ? 24 : 32, weight: .heavy, design: .rounded))
                        .foregroundColor(isUnlocked ? .white : .gray)

                    if isUnlocked {
                        Text(alien.words.joined(separator: " • "))
                            .font(.system(size: isLandscape ? 10 : 13))
                            .foregroundColor(AppTheme.accentPrimary.opacity(0.9))
                            .multilineTextAlignment(.center)

                        // Progress bar - hide in landscape to keep card compact
                        if !isLandscape {
                            VStack(spacing: 6) {
                                // 7 level progress bars
                                HStack(spacing: 3) {
                                    ForEach(1...7, id: \.self) { level in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(level <= levelsCompleted
                                                ? AppTheme.accentPrimary
                                                : Color.gray.opacity(0.3))
                                            .frame(height: 6)
                                    }
                                }
                                .padding(.horizontal, 16)

                                // Stats row
                                HStack {
                                    Text("\(levelsCompleted)/7 levels")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textSecondary)

                                    Spacer()

                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                        Text("\(chapterStars)/21")
                                            .font(.system(size: 11))
                                    }
                                    .foregroundColor(AppTheme.accentTertiary)
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                // Bottom: use Spacer for landscape (to match top), padding for portrait
                if isLandscape {
                    Spacer()
                } else {
                    Spacer().frame(height: 32)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.backgroundMid.opacity(isUnlocked ? 0.9 : 0.5),
                                AppTheme.backgroundDark.opacity(isUnlocked ? 0.95 : 0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        isUnlocked
                            ? (isCurrent
                                ? AppTheme.accentPrimary
                                : AppTheme.accentPrimary.opacity(0.4))
                            : Color.gray.opacity(0.2),
                        lineWidth: (isCurrent ? 3 : 1.5) * borderScale
                    )
            )
            .shadow(
                color: isCurrent && isUnlocked
                    ? AppTheme.accentPrimary.opacity(0.3)
                    : Color.black.opacity(0.3),
                radius: isCurrent ? 20 : 10,
                y: 8
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Chapter Intro View (Placeholder)

struct ChapterIntroView: View {
    let alien: ChapterAlien
    @ObservedObject var progress: StoryProgress
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Colorful splash background
            Image("splash_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                Text(alien.name)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: AppTheme.connectorGlow.opacity(0.8), radius: 8)

                SpeechBubble {
                    Text("Let's try Chapter \(alien.chapter)!")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.backgroundDark)
                }

                Spacer()

                Button(action: {}) {
                    Text("Start Chapter")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accentPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Chapter \(alien.chapter)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Speech Bubble

struct SpeechBubble<Content: View>: View {
    let pointsUp: Bool
    @ViewBuilder let content: Content

    init(pointsUp: Bool = false, @ViewBuilder content: () -> Content) {
        self.pointsUp = pointsUp
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            if pointsUp {
                // Triangle pointing up (above bubble, pointing to alien above)
                BubbleTriangle(pointsUp: true)
                    .fill(Color.white)
                    .frame(width: 20, height: 12)
                    .offset(y: 1)
            }

            content
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(16)

            if !pointsUp {
                // Triangle pointing down (below bubble)
                BubbleTriangle(pointsUp: false)
                    .fill(Color.white)
                    .frame(width: 20, height: 12)
                    .offset(y: -1)
            }
        }
    }
}

private struct BubbleTriangle: Shape {
    let pointsUp: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsUp {
            // Triangle pointing up to alien above
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            // Triangle pointing down
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - ChapterAlien Hashable

extension ChapterAlien: Hashable {
    static func == (lhs: ChapterAlien, rhs: ChapterAlien) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview

#Preview("Chapter Select") {
    NavigationStack {
        ChapterSelectView()
            .environmentObject(AppState())
    }
}
