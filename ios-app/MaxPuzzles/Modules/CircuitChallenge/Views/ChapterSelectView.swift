import SwiftUI

/// Chapter selection screen with horizontal scrolling aliens
struct ChapterSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var progress = StoryProgress()

    @State private var selectedChapter: ChapterAlien?

    var body: some View {
        ZStack {
            StarryBackground(useHubImage: true)

            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Story Mode")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Help the aliens by solving puzzles!")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.top, 20)

                // Horizontal chapter scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(ChapterAlien.all) { alien in
                            ChapterCard(
                                alien: alien,
                                isUnlocked: progress.isChapterUnlocked(alien.chapter),
                                isCompleted: progress.isChapterCompleted(alien.chapter),
                                onTap: {
                                    if progress.isChapterUnlocked(alien.chapter) {
                                        selectedChapter = alien
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }

                // Progress indicator
                progressIndicator

                Spacer()
            }
        }
        .navigationTitle("Story Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
        .navigationDestination(item: $selectedChapter) { alien in
            // Navigate to level select for this chapter
            LevelSelectView(
                chapter: alien.chapter,
                alien: alien,
                progress: progress
            )
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: 8) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(1...10, id: \.self) { chapter in
                    Circle()
                        .fill(progressDotColor(for: chapter))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(progressDotBorder(for: chapter), lineWidth: 2)
                        )
                }
            }

            Text("\(progress.completedChapters.count) of 10 chapters completed")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.bottom, 20)
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

// MARK: - Chapter Card

struct ChapterCard: View {
    let alien: ChapterAlien
    let isUnlocked: Bool
    let isCompleted: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Alien image
                ZStack {
                    // Background circle
                    Circle()
                        .fill(
                            isUnlocked
                                ? LinearGradient(
                                    colors: [AppTheme.backgroundMid, AppTheme.backgroundDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 120, height: 120)

                    // Alien image
                    Image(alien.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .grayscale(isUnlocked ? 0 : 1)
                        .opacity(isUnlocked ? 1 : 0.5)

                    // Lock overlay for locked chapters
                    if !isUnlocked {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 120, height: 120)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 32))
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
                                        .frame(width: 28, height: 28)

                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            Spacer()
                        }
                        .frame(width: 120, height: 120)
                    }
                }

                // Chapter number
                Text("Chapter \(alien.chapter)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isUnlocked ? AppTheme.textSecondary : .gray)

                // Alien name
                Text(alien.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isUnlocked ? .white : .gray)

                // Fun words
                if isUnlocked {
                    Text(alien.words.joined(separator: " • "))
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.accentPrimary.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .frame(width: 140)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.backgroundMid.opacity(isUnlocked ? 0.6 : 0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isUnlocked
                            ? (isCompleted ? AppTheme.accentPrimary : AppTheme.accentPrimary.opacity(0.3))
                            : Color.gray.opacity(0.2),
                        lineWidth: isCompleted ? 2 : 1
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
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

                // Alien image
                Image(alien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                // Alien name
                Text(alien.name)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                // Speech bubble
                SpeechBubble {
                    Text("Let's try Chapter \(alien.chapter)!")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.backgroundDark)
                }

                Spacer()

                // Start button
                Button(action: {
                    // TODO: Navigate to level select
                }) {
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

            // Tail
            Triangle()
                .fill(Color.white)
                .frame(width: 20, height: 12)
                .offset(y: -1)
        }
    }
}

struct Triangle: Shape {
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

#Preview("Chapter Card - Unlocked") {
    ZStack {
        Color(hex: "0f0f23")
        ChapterCard(
            alien: ChapterAlien.all[0],
            isUnlocked: true,
            isCompleted: false,
            onTap: {}
        )
    }
}

#Preview("Chapter Card - Locked") {
    ZStack {
        Color(hex: "0f0f23")
        ChapterCard(
            alien: ChapterAlien.all[4],
            isUnlocked: false,
            isCompleted: false,
            onTap: {}
        )
    }
}

#Preview("Chapter Card - Completed") {
    ZStack {
        Color(hex: "0f0f23")
        ChapterCard(
            alien: ChapterAlien.all[0],
            isUnlocked: true,
            isCompleted: true,
            onTap: {}
        )
    }
}
