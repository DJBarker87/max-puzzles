import SwiftUI

/// First run welcome screen where an alien rises up and asks for the player's name
struct FirstRunView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService

    @State private var playerName: String = ""
    @State private var alienOffset: CGFloat = 400  // Start below screen
    @State private var alienScale: CGFloat = 1.0
    @State private var bubbleOpacity: Double = 0
    @State private var inputOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var isExiting = false

    // Pick a random welcome alien
    private let welcomeAlien = ChapterAlien.all.randomElement() ?? ChapterAlien.all[0]

    private var storage: StorageService { StorageService.shared }

    var body: some View {
        ZStack {
            // Colorful splash background
            Image("splash_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Dark overlay for readability
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Name input field (appears above alien)
                VStack(spacing: 16) {
                    TextField("Your name", text: $playerName)
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(AppTheme.backgroundMid)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.accentPrimary.opacity(0.5), lineWidth: 2)
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)

                    // Continue button
                    Button(action: completeFirstRun) {
                        HStack {
                            Text(playerName.isEmpty ? "Skip" : "Let's Play!")
                                .font(.system(size: 18, weight: .bold, design: .rounded))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            playerName.isEmpty
                                ? AppTheme.backgroundMid
                                : AppTheme.accentPrimary
                        )
                        .cornerRadius(14)
                        .shadow(color: playerName.isEmpty ? .clear : AppTheme.accentPrimary.opacity(0.4), radius: 12)
                    }
                }
                .frame(maxWidth: 400)
                .padding(.horizontal, 24)
                .opacity(inputOpacity)

                // Speech bubble (appears above alien)
                SpeechBubble(pointsUp: false) {
                    VStack(spacing: 6) {
                        Text("Hi there! I'm \(welcomeAlien.name)!")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppTheme.backgroundDark)

                        Text("What's your name?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.backgroundDark.opacity(0.8))
                    }
                }
                .padding(.horizontal, 50)
                .opacity(bubbleOpacity)

                // Alien image rising from bottom
                Image(welcomeAlien.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .alienIdleAnimation(style: .bounce, intensity: alienOffset == 0 ? 1.0 : 0)
                    .scaleEffect(alienScale)
                    .offset(y: alienOffset)
            }
            .padding(.bottom, -40) // Let alien overlap bottom edge slightly
        }
        .opacity(isExiting ? 0 : 1)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Alien rises up from bottom with spring animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            alienOffset = 0
        }

        // Speech bubble fades in after alien arrives
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.4)) {
                bubbleOpacity = 1.0
            }
        }

        // Input field fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                inputOpacity = 1.0
            }
        }

        // Button is part of input opacity, so no separate animation needed
    }

    private func completeFirstRun() {
        // Save the player name (even if empty)
        let nameToSave = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        storage.setPlayerName(nameToSave)
        storage.completeFirstRun()

        // Haptic feedback
        FeedbackManager.shared.haptic(.success)

        // Exit animation - alien drops back down
        withAnimation(.easeIn(duration: 0.3)) {
            alienOffset = 400
            bubbleOpacity = 0
            inputOpacity = 0
        }

        // Fade out whole view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                isExiting = true
            }
        }

        // Transition to main hub
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            appState.completeFirstRun()
        }
    }
}

#Preview {
    FirstRunView()
        .environmentObject(AppState())
        .environmentObject(MusicService.shared)
}
