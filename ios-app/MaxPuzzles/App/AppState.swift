import SwiftUI
import Combine

/// Global application state managing user session and app lifecycle
@MainActor
class AppState: ObservableObject {
    // MARK: - Published State

    @Published var isLoading = true
    @Published var needsFirstRun = false
    @Published var currentUser: User?
    @Published var isGuest = true
    @Published var isInGame = false
    @Published var shouldPauseTimer = false

    /// Story mode progress tracker
    @Published var storyProgress = StoryProgress()

    // MARK: - Private

    private var backgroundDate: Date?
    private let sessionTimeoutSeconds: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    init() {
        // Initialize with guest mode
        isGuest = true
        loadUserState()
    }

    // MARK: - Loading

    /// Called when splash screen completes
    func completeLoading() {
        isLoading = false
        // Check if first run setup is needed
        if StorageService.shared.needsFirstRunSetup {
            needsFirstRun = true
        }
    }

    /// Called when first run setup is completed
    func completeFirstRun() {
        needsFirstRun = false
    }

    // MARK: - User State

    private func loadUserState() {
        let storage = StorageService.shared

        // Check if we have a guest session
        if storage.hasGuestSession {
            currentUser = User.guest()
            isGuest = true
        } else {
            // First launch - guest session will be created by SplashView
            currentUser = User.guest()
            isGuest = true
        }
    }

    /// Update guest coin total after game
    func updateGuestCoins(_ amount: Int) {
        guard isGuest else { return }
        StorageService.shared.addCoins(amount)
    }

    /// Record a completed puzzle
    func recordPuzzleCompleted() {
        StorageService.shared.incrementPuzzlesCompleted()
        StorageService.shared.incrementGamesPlayed()
    }

    // MARK: - Game State

    /// Called when entering a game
    func enterGame() {
        isInGame = true
        shouldPauseTimer = false
    }

    /// Called when exiting a game
    func exitGame() {
        isInGame = false
        shouldPauseTimer = false
    }

    // MARK: - App Lifecycle

    /// Resume session when app becomes active
    func resumeSession() {
        guard isInGame else { return }

        // Check if session has timed out
        if let backgroundDate = backgroundDate {
            let elapsed = Date().timeIntervalSince(backgroundDate)
            if elapsed > sessionTimeoutSeconds {
                // Session timed out - would trigger session end
                // For now, just log it
                print("Session timeout after \(Int(elapsed)) seconds")
            }
        }

        // Resume timer
        shouldPauseTimer = false
        backgroundDate = nil
    }

    /// Pause session when app becomes inactive
    func pauseSession() {
        guard isInGame else { return }

        // Pause timer
        shouldPauseTimer = true
    }

    /// Save state when app goes to background
    func saveState() {
        // Record when we went to background
        backgroundDate = Date()

        // Pause timer
        if isInGame {
            shouldPauseTimer = true
        }

        // Save any pending data
        // (In future phases, this would trigger sync queue processing)
    }

    // MARK: - Account Prompt

    /// Check if we should show the account creation prompt
    var shouldShowAccountPrompt: Bool {
        isGuest && StorageService.shared.shouldShowAccountPrompt
    }

    /// Mark account prompt as shown
    func markAccountPromptShown() {
        StorageService.shared.markAccountPromptShown()
    }
}
