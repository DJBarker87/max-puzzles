import SwiftUI

/// Chapter selection screen with 3D carousel of large alien cards
struct ChapterSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var progress = StoryProgress()

    @State private var selectedChapter: ChapterAlien?
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                StarryBackground(useHubImage: true)

                VStack(spacing: 0) {
                    // Title
                    VStack(spacing: 4) {
                        Text("Story Mode")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("Help the aliens by solving puzzles!")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 16)

                    // 3D Carousel
                    Spacer()

                    carousel3D(geometry: geometry)
                        .frame(height: geometry.size.height * 0.65)

                    Spacer()

                    // Progress indicator
                    progressIndicator
                        .padding(.bottom, 20)
                }
            }
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
        .navigationDestination(isPresented: Binding(
            get: { selectedChapter != nil },
            set: { if !$0 { selectedChapter = nil } }
        )) {
            if let alien = selectedChapter {
                LevelSelectView(
                    chapter: alien.chapter,
                    alien: alien,
                    progress: progress
                )
            }
        }
    }

    // MARK: - 3D Carousel

    private func carousel3D(geometry: GeometryProxy) -> some View {
        let cardWidth = geometry.size.width * 0.7
        let cardHeight = geometry.size.height * 0.6
        let spacing: CGFloat = 20

        return ZStack {
            ForEach(Array(ChapterAlien.all.enumerated()), id: \.element.id) { index, alien in
                let offset = CGFloat(index - currentIndex) + (dragOffset / (cardWidth + spacing))
                let absOffset = abs(offset)

                // 3D transforms for sphere effect
                let angle = offset * 35 // degrees of rotation
                let scale = max(0.6, 1 - absOffset * 0.15)
                let zIndex = 10 - absOffset
                let xOffset = offset * cardWidth * 0.4

                // Opacity based on distance
                let opacity = max(0.3, 1 - absOffset * 0.3)

                LargeChapterCard(
                    alien: alien,
                    isUnlocked: progress.isChapterUnlocked(alien.chapter),
                    isCompleted: progress.isChapterCompleted(alien.chapter),
                    isCurrent: index == currentIndex,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
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
}

// MARK: - Large Chapter Card

struct LargeChapterCard: View {
    let alien: ChapterAlien
    let isUnlocked: Bool
    let isCompleted: Bool
    let isCurrent: Bool
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Spacer()

                // Alien image - large and prominent
                ZStack {
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
                                    endRadius: cardWidth * 0.4
                                )
                            )
                            .frame(width: cardWidth * 0.8, height: cardWidth * 0.8)
                    }

                    // Alien image with idle animation when unlocked and current
                    Image(alien.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: cardWidth * 0.7, height: cardWidth * 0.7)
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

                Spacer()

                // Chapter info
                VStack(spacing: 8) {
                    Text("Chapter \(alien.chapter)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isUnlocked ? AppTheme.textSecondary : .gray)

                    Text(alien.name)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(isUnlocked ? .white : .gray)

                    if isUnlocked {
                        Text(alien.words.joined(separator: " • "))
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.accentPrimary.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 24)
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
                        lineWidth: isCurrent ? 3 : 1.5
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
            StarryBackground(useHubImage: true)

            VStack(spacing: 24) {
                Spacer()

                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                Text(alien.name)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

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
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(16)

            ChapterTriangle()
                .fill(Color.white)
                .frame(width: 20, height: 12)
                .offset(y: -1)
        }
    }
}

private struct ChapterTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
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
    }
}
