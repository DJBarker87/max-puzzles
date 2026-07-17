import SwiftUI
import UIKit

// MARK: - Orientation Manager

/// Manages device orientation locking for different screens
/// Game screens lock to landscape, hub/menus allow all orientations
@MainActor
final class OrientationManager: NSObject, ObservableObject {
    static let shared = OrientationManager()

    /// Current allowed orientations - default to all for menus
    @Published var allowedOrientations: UIInterfaceOrientationMask = .all
    private var requestedOrientations: UIInterfaceOrientationMask = .all

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(temporarilyAllowAllOrientations),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(restoreRequestedOrientations),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    /// Lock to landscape only (for game screens)
    func lockLandscape() {
        apply(.landscape)

        // Force rotation to landscape if currently in portrait
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let currentOrientation = windowScene.interfaceOrientation
            if currentOrientation.isPortrait {
                // Request geometry update to landscape
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
                    print("Orientation update error: \(error)")
                }
            }
        }

    }

    /// Lock to portrait only (for hub screens)
    func lockPortrait() {
        apply(.portrait)

        // Force rotation to portrait if currently in landscape
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            let currentOrientation = windowScene.interfaceOrientation
            if currentOrientation.isLandscape {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { _ in }
            }
        }
    }

    /// Allow all orientations
    func unlockAll() {
        apply(.all)
    }

    private func apply(_ orientations: UIInterfaceOrientationMask) {
        requestedOrientations = orientations
        allowedOrientations = orientations
        setNeedsOrientationUpdate()
    }

    /// Avoid retaining a forced geometry while the app is backgrounded. If the game is still
    /// visible when the app becomes active, its requested orientation is restored.
    @objc private func temporarilyAllowAllOrientations() {
        allowedOrientations = .all
        setNeedsOrientationUpdate()
    }

    @objc private func restoreRequestedOrientations() {
        allowedOrientations = requestedOrientations
        setNeedsOrientationUpdate()
    }

    private func setNeedsOrientationUpdate() {
        // Notify the system that orientation preferences have changed
        if #available(iOS 16.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}

// MARK: - App Delegate for Orientation Control

/// App delegate that controls orientation based on OrientationManager
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return OrientationManager.shared.allowedOrientations
    }
}

// MARK: - View Modifier for Landscape Lock

/// View modifier that locks the screen to landscape orientation
struct LandscapeLockModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                OrientationManager.shared.lockLandscape()
            }
            .onDisappear {
                OrientationManager.shared.unlockAll()
            }
    }
}

/// View modifier that locks the screen to portrait orientation
struct PortraitLockModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                OrientationManager.shared.lockPortrait()
            }
            .onDisappear {
                OrientationManager.shared.unlockAll()
            }
    }
}

/// View modifier that locks portrait on iPhone only (iPad stays unrestricted)
struct PortraitOnPhoneModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Only lock portrait on iPhones, let iPads use any orientation
                if UIDevice.current.userInterfaceIdiom == .phone {
                    OrientationManager.shared.lockPortrait()
                }
            }
            .onDisappear {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    OrientationManager.shared.unlockAll()
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Lock this view to landscape orientation only
    func landscapeOnly() -> some View {
        modifier(LandscapeLockModifier())
    }

    /// Lock this view to portrait orientation only
    func portraitOnly() -> some View {
        modifier(PortraitLockModifier())
    }

    /// Lock portrait on iPhone only (iPad can use any orientation)
    func portraitOnPhone() -> some View {
        modifier(PortraitOnPhoneModifier())
    }
}
