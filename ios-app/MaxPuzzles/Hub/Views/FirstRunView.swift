import SwiftUI

/// First run welcome screen where an alien rises up and asks for the player's name
struct FirstRunView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var playerName: String = ""
    @State private var alienOffset: CGFloat = 400  // Start below screen
    @State private var alienScale: CGFloat = 1.0
    @State private var bubbleOpacity: Double = 0
    @State private var isExiting = false
    @State private var alienArrived = false  // Separate state for animation
    @State private var entranceTask: Task<Void, Never>?
    @State private var exitTask: Task<Void, Never>?
    @FocusState private var isTextFieldFocused: Bool

    // Pick a random welcome alien (computed once) - use first alien or a safe default
    @State private var welcomeAlien: ChapterAlien = ChapterAlien.all.first ?? ChapterAlien.defaultAlien

    var body: some View {
        ZStack {
            // Solid fallback background
            AppTheme.backgroundDark
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }

            StarryBackground(
                starCount: 32,
                enableShootingStars: false,
                animateStars: true
            )
                .allowsHitTesting(false)

            VStack(spacing: 20) {
                Spacer()

                SpeechBubble(pointsUp: false) {
                    Text("What’s your name?")
                        .font(AppTypography.bodyLarge.weight(.bold))
                        .foregroundColor(AppTheme.backgroundDark)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .opacity(bubbleOpacity)

                // Name input field (appears above alien)
                VStack(spacing: 16) {
                    TextField("Your name", text: $playerName)
                        .font(AppTypography.titleSmall.weight(.medium))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(AppTheme.backgroundMid)
                        .foregroundColor(.white)
                        .tint(.white)  // Make cursor visible
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isTextFieldFocused ? AppTheme.accentPrimary : AppTheme.accentPrimary.opacity(0.5), lineWidth: isTextFieldFocused ? 3 : 2)
                        )
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isTextFieldFocused = false
                        }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .onChange(of: playerName) { newValue in
                            if newValue.count > 24 {
                                playerName = String(newValue.prefix(24))
                            }
                        }

                    // Continue button
                    Button(action: completeFirstRun) {
                        HStack {
                            Text("Let's Play!")
                                .font(AppTypography.buttonLarge)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(minHeight: 48)
                        .padding(.horizontal, 32)
                        .background(canContinue ? AppTheme.accentPrimary : AppTheme.backgroundMid)
                        .cornerRadius(14)
                        .shadow(color: canContinue ? AppTheme.accentPrimary.opacity(0.4) : .clear, radius: 12)
                    }
                    .disabled(!canContinue)
                    .accessibilityLabel("Let's Play!")
                    .accessibilityHint(canContinue ? "Starts the games" : "Enter your name first")
                }
                .frame(maxWidth: 400)
                .padding(.horizontal, 24)

                // Alien image rising from bottom
                Image(welcomeAlien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .alienIdleAnimation(style: .bounce, intensity: alienArrived ? 1.0 : 0)
                    .scaleEffect(alienScale)
                    .offset(y: alienOffset)
            }
            .padding(.bottom, -40) // Let alien overlap bottom edge slightly
        }
        .opacity(isExiting ? 0 : 1)
        .onAppear {
            // Pick a random alien on appear (avoids init-time randomization issues)
            welcomeAlien = ChapterAlien.all.randomElement() ?? ChapterAlien.defaultAlien
            if reduceMotion {
                alienOffset = 0
                alienArrived = true
                bubbleOpacity = 1
            } else {
                startAnimations()
            }

            Task { @MainActor in
                await Task.yield()
                isTextFieldFocused = true
            }

            // Ensure music is playing (in case it wasn't started in splash)
            if !musicService.isPlaying {
                musicService.play(track: .hub)
            }
        }
        .onDisappear {
            entranceTask?.cancel()
            exitTask?.cancel()
        }
    }

    private var canContinue: Bool {
        !playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func startAnimations() {
        // Alien rises up from bottom with spring animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            alienOffset = 0
        }

        entranceTask?.cancel()
        entranceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.35)) {
                bubbleOpacity = 1
            }

            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            alienArrived = true
        }
    }

    private func completeFirstRun() {
        let nameToSave = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard appState.commitFirstRun(playerName: nameToSave) else { return }

        // Haptic feedback
        FeedbackManager.shared.haptic(.success)

        if reduceMotion {
            appState.finishFirstRunTransition()
            return
        }

        // Exit animation - alien drops back down
        withAnimation(.easeIn(duration: 0.3)) {
            alienOffset = 400
            bubbleOpacity = 0
        }

        exitTask?.cancel()
        exitTask = Task { @MainActor in
            // Fade out whole view
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                isExiting = true
            }

            // Transition to main hub
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s more (0.5s total)
            guard !Task.isCancelled else { return }
            appState.finishFirstRunTransition()
        }
    }
}

#Preview {
    FirstRunView()
        .environmentObject(AppState())
        .environmentObject(MusicService.shared)
}
