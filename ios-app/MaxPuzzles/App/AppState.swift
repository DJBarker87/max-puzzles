import SwiftUI
import Combine

/// Global application state managing user session and app lifecycle
@MainActor
class AppState: ObservableObject {
    // MARK: - Published State

    @Published var isLoading = true
    @Published var needsFirstRun = false
    @Published var needsProfileSelection = false
    @Published var currentUser: User?
    @Published var isGuest = true
    @Published var isInGame = false
    @Published var shouldPauseTimer = false

    /// Story mode progress tracker
    @Published var storyProgress: StoryProgress

    /// Pending navigation to a chapter's level select (for showing unlock animation)
    /// Set by GameScreenView when completing level 6 after advancing chapters
    @Published var pendingChapterNavigation: Int?

    // MARK: - Private

    private var backgroundDate: Date?
    private let sessionTimeoutSeconds: TimeInterval = 300 // 5 minutes
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        let profileStore = CometLearningStore.shared
        StorageService.shared.activateProfile(profileStore.activeProfileID)
        let activeName = profileStore.activeProfile.name == "Explorer"
            ? ""
            : profileStore.activeProfile.name
        StorageService.shared.setPlayerName(activeName)
        storyProgress = StoryProgress(profileID: profileStore.activeProfileID)

        // Initialize with guest mode
        isGuest = true
        loadUserState()

        profileStore.$activeProfileID
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] profileID in
                StorageService.shared.activateProfile(profileID)
                self?.storyProgress = StoryProgress(profileID: profileID)
            }
            .store(in: &cancellables)
    }

    // MARK: - Loading

    /// Called when splash screen completes
    func completeLoading() {
        // IMPORTANT: Check first run BEFORE setting isLoading to false
        // This prevents a race condition where ContentView shows MainHubView briefly
        if StorageService.shared.needsFirstRunSetup {
            needsFirstRun = true
        } else {
            needsProfileSelection = StorageService.shared.shouldOfferAdditionalProfileAfterFirstRun
                || CometLearningStore.shared.profiles.count > 1
        }
        // Now safe to set isLoading false - needsFirstRun is already set if needed
        isLoading = false
    }

    /// Persists first-run identity before recording onboarding as complete.
    ///
    /// The completion flag must remain the final durable write. If the process is interrupted
    /// before that point, onboarding is safely shown again instead of launching with an
    /// unconfigured "Explorer" profile.
    @discardableResult
    func commitFirstRun(playerName rawPlayerName: String) -> Bool {
        let playerName = rawPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !playerName.isEmpty else { return false }

        let profileStore = CometLearningStore.shared
        if profileStore.profiles.count == 1 {
            profileStore.renameActiveProfile(playerName)
        } else {
            StorageService.shared.setPlayerName(playerName)
        }

        StorageService.shared.completeFirstRun(offerAdditionalProfile: true)
        return true
    }

    /// Removes the first-run screen after its optional exit animation has completed.
    ///
    /// Every family is shown the profile picker once, even when only one child has been entered.
    /// That makes the sibling path explicit during onboarding instead of hiding “Add a child”
    /// behind an unexplained avatar on the hub.
    func finishFirstRunTransition() {
        needsFirstRun = false
        needsProfileSelection = true
    }

    // MARK: - Player Profiles

    func requestProfileSelection() {
        guard !isInGame else { return }
        needsProfileSelection = true
    }

    func selectProfile(_ profileID: UUID) {
        CometLearningStore.shared.setActiveProfile(profileID)
        StorageService.shared.markAdditionalProfileOfferHandled()
        needsProfileSelection = false
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
