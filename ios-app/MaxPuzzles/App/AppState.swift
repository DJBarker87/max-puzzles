import SwiftUI

/// Global application state managing user session and app lifecycle
@MainActor
class AppState: ObservableObject {
    @Published var isLoading = true
    @Published var currentUser: User?
    @Published var isGuest = true

    init() {
        // Initialize with guest mode
        isGuest = true
    }

    /// Resume session when app becomes active
    func resumeSession() {
        // Resume timer if in game
    }

    /// Pause session when app becomes inactive
    func pauseSession() {
        // Pause timer
    }

    /// Save state when app goes to background
    func saveState() {
        // Save game state for background
    }
}
