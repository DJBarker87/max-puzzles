import SwiftUI

/// All possible navigation destinations in the app
enum AppRoute: Hashable {
    case splash
    case hub
    case familySelect
    case pinEntry(childId: UUID)
    case settings
    case parentDashboard

    // Circuit Challenge routes
    case circuitChallengeMenu
    case circuitChallengeSetup
    case circuitChallengeGame(difficulty: Int, isCustom: Bool)
    case circuitChallengeSummary
    case circuitChallengePuzzleMaker
}

/// Centralized navigation controller
class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    /// Navigate to a new route
    func navigate(to route: AppRoute) {
        path.append(route)
    }

    /// Pop the top route from the stack
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    /// Pop all routes and return to root
    func popToRoot() {
        path = NavigationPath()
    }

    /// Replace the entire navigation stack with a single route
    func replace(with route: AppRoute) {
        path = NavigationPath()
        path.append(route)
    }
}
