import Security
import SwiftUI
import UIKit

protocol ParentPasscodeStoring: AnyObject {
    func loadPasscode() -> ParentPasscodeLoadResult
    @discardableResult func savePasscode(_ passcode: String) -> Bool
    func removePasscode()
}

enum ParentPasscodeLoadResult: Equatable {
    case found(String)
    case missing
    /// A transient Keychain failure must never be interpreted as permission to replace a PIN.
    case unavailable(OSStatus)
}

enum ParentPasscodeAvailability: Equatable {
    case loading
    case present
    case absent
    case unavailable
}

private final class ParentPasscodeStoreReference: @unchecked Sendable {
    let value: ParentPasscodeStoring

    init(_ value: ParentPasscodeStoring) {
        self.value = value
    }
}

final class KeychainParentPasscodeStore: ParentPasscodeStoring {
    private let service: String
    private let account = "parent-play-timer"

    init(service: String = Bundle.main.bundleIdentifier ?? "com.maxpuzzles.app") {
        self.service = service
    }

    func loadPasscode() -> ParentPasscodeLoadResult {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return .missing }
        guard status == errSecSuccess,
              let data = item as? Data,
              let passcode = String(data: data, encoding: .utf8),
              ParentPlayTimer.isValidPasscode(passcode) else {
            return .unavailable(status)
        }
        return .found(passcode)
    }

    @discardableResult
    func savePasscode(_ passcode: String) -> Bool {
        guard ParentPlayTimer.isValidPasscode(passcode),
              let data = passcode.data(using: .utf8) else { return false }

        let attributes = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return true }
        guard updateStatus == errSecItemNotFound else { return false }

        var newItem = baseQuery
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(newItem as CFDictionary, nil) == errSecSuccess
    }

    func removePasscode() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

/// A device-wide parent timer backed by an absolute deadline.
///
/// Using a deadline instead of an in-memory countdown means closing, backgrounding, or
/// relaunching the app cannot accidentally reset a child's play session.
@MainActor
final class ParentPlayTimer: ObservableObject {
    /// The app-wide instance defers the Keychain lookup until after the first frame. Custom
    /// instances (including tests) keep the synchronous behaviour so their initial state is
    /// deterministic.
    static let shared = ParentPlayTimer(deferPasscodeLoad: true)

    static let presetMinutes = [15, 30, 45, 60]
    static let minimumMinutes = 5
    static let maximumMinutes = 120

    nonisolated private static let defaultStorageKey = "maxpuzzles.parent.playTimerDeadline"

    @Published private(set) var deadline: Date?
    private(set) var remainingSeconds = 0
    @Published private(set) var displayedRemainingMinutes = 0
    @Published private(set) var isLocked = false
    @Published private(set) var passcodeAvailability: ParentPasscodeAvailability

    private let defaults: UserDefaults
    private let storageKey: String
    private let nowProvider: () -> Date
    private let passcodeStore: ParentPasscodeStoring
    private var ticker: Timer?
    private var monitoringActive = false
    private var passcodeLoadGeneration = 0
    private var passcodeLoadInFlight = false
    #if DEBUG
    private var uiTestingPasscode: String?
    #endif

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = ParentPlayTimer.defaultStorageKey,
        nowProvider: @escaping () -> Date = Date.init,
        passcodeStore: ParentPasscodeStoring = KeychainParentPasscodeStore(),
        deferPasscodeLoad: Bool = false
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.nowProvider = nowProvider
        self.passcodeStore = passcodeStore
        passcodeAvailability = deferPasscodeLoad
            ? .loading
            : Self.availability(for: passcodeStore.loadPasscode())
        deadline = defaults.object(forKey: storageKey) as? Date
        refresh()
    }

    var hasLimit: Bool {
        deadline != nil
    }

    var hasPasscode: Bool {
        passcodeAvailability == .present
    }

    var statusText: String {
        guard hasLimit else { return "No time limit" }
        guard !isLocked else { return "Time is up" }

        let roundedMinutes = max(1, displayedRemainingMinutes)
        if roundedMinutes < 60 {
            return "\(roundedMinutes) min remaining"
        }

        let hours = roundedMinutes / 60
        let minutes = roundedMinutes % 60
        if minutes == 0 {
            return hours == 1 ? "1 hour remaining" : "\(hours) hours remaining"
        }
        return "\(hours) hr \(minutes) min remaining"
    }

    var suggestedMinutes: Int {
        guard remainingSeconds > 0 else { return 30 }
        let rounded = Int(ceil(Double(remainingSeconds) / 300.0)) * 5
        return min(max(rounded, Self.minimumMinutes), Self.maximumMinutes)
    }

    @discardableResult
    func start(minutes: Int) -> Bool {
        guard hasPasscode else { return false }
        let safeMinutes = min(max(minutes, Self.minimumMinutes), Self.maximumMinutes)
        let nextDeadline = nowProvider().addingTimeInterval(TimeInterval(safeMinutes * 60))
        deadline = nextDeadline
        defaults.set(nextDeadline, forKey: storageKey)
        refresh()
        if monitoringActive { scheduleNextRefresh() }
        return true
    }

    func removeLimit() {
        deadline = nil
        remainingSeconds = 0
        displayedRemainingMinutes = 0
        if isLocked { isLocked = false }
        defaults.removeObject(forKey: storageKey)
        stopTicker()
    }

    @discardableResult
    func setPasscode(_ passcode: String) -> Bool {
        guard Self.isValidPasscode(passcode), passcodeStore.savePasscode(passcode) else {
            return false
        }
        passcodeLoadGeneration += 1
        passcodeLoadInFlight = false
        passcodeAvailability = .present
        return true
    }

    func verifyPasscode(_ passcode: String) -> Bool {
        #if DEBUG
        if let uiTestingPasscode {
            return uiTestingPasscode == passcode
        }
        #endif
        guard Self.isValidPasscode(passcode) else {
            return false
        }
        let result = passcodeStore.loadPasscode()
        passcodeAvailability = Self.availability(for: result)
        guard case let .found(stored) = result else { return false }
        return stored == passcode
    }

    func resetAll() {
        removeLimit()
        passcodeStore.removePasscode()
        #if DEBUG
        uiTestingPasscode = nil
        #endif
        passcodeLoadGeneration += 1
        passcodeLoadInFlight = false
        passcodeAvailability = .absent
    }

    nonisolated static func isValidPasscode(_ passcode: String) -> Bool {
        passcode.count == 4 && passcode.allSatisfy(\.isNumber)
    }

    private nonisolated static func availability(
        for result: ParentPasscodeLoadResult
    ) -> ParentPasscodeAvailability {
        switch result {
        case let .found(passcode):
            return isValidPasscode(passcode) ? .present : .unavailable
        case .missing:
            return .absent
        case .unavailable:
            return .unavailable
        }
    }

    /// Reconciles published state with the persisted real-time deadline.
    func refresh(at date: Date? = nil) {
        guard let deadline else {
            remainingSeconds = 0
            if displayedRemainingMinutes != 0 { displayedRemainingMinutes = 0 }
            if isLocked { isLocked = false }
            return
        }

        let remaining = deadline.timeIntervalSince(date ?? nowProvider())
        remainingSeconds = max(0, Int(ceil(remaining)))
        let nextLocked = remaining <= 0
        let nextDisplayedMinutes = nextLocked ? 0 : max(1, (remainingSeconds + 59) / 60)
        if displayedRemainingMinutes != nextDisplayedMinutes {
            displayedRemainingMinutes = nextDisplayedMinutes
        }
        if isLocked != nextLocked {
            isLocked = nextLocked
        }
        if nextLocked {
            stopTicker()
        }
    }

    /// Performs the app-wide Keychain read after launch instead of delaying construction of the
    /// first SwiftUI scene. Mutations made while it is loading always win over the stale result.
    func loadPasscodeAvailabilityAfterLaunch() {
        guard !passcodeLoadInFlight,
              passcodeAvailability == .loading || passcodeAvailability == .unavailable else {
            return
        }
        passcodeLoadInFlight = true
        let generation = passcodeLoadGeneration
        let store = ParentPasscodeStoreReference(passcodeStore)

        DispatchQueue.global(qos: .utility).async {
            let result = store.value.loadPasscode()
            DispatchQueue.main.async { [weak self] in
                guard let self, self.passcodeLoadGeneration == generation else { return }
                self.passcodeLoadInFlight = false
                self.passcodeAvailability = Self.availability(for: result)
            }
        }
    }

    /// Parent interaction cannot wait on the launch worker. Resolve synchronously at this explicit
    /// grown-up action, and never route an unavailable Keychain result into PIN recovery.
    func resolvePasscodeAvailabilityForParentAccess() -> ParentPasscodeAvailability {
        guard passcodeAvailability == .loading || passcodeAvailability == .unavailable else {
            return passcodeAvailability
        }
        passcodeLoadGeneration += 1
        passcodeLoadInFlight = false
        let result = passcodeStore.loadPasscode()
        passcodeAvailability = Self.availability(for: result)
        return passcodeAvailability
    }

    func setMonitoringActive(_ active: Bool) {
        monitoringActive = active
        refresh()
        if active, !isLocked, hasLimit {
            scheduleNextRefresh()
        } else if !active || isLocked {
            stopTicker()
        }
    }

    #if DEBUG
    func expireForUITesting() {
        let expiredDeadline = nowProvider().addingTimeInterval(-1)
        deadline = expiredDeadline
        defaults.set(expiredDeadline, forKey: storageKey)
        refresh()
    }

    func setPasscodeForUITesting(_ passcode: String) {
        guard Self.isValidPasscode(passcode) else { return }
        // Unsigned simulator builds do not always have Keychain entitlements. Keep the
        // production path unchanged while making the launch-state UI test deterministic.
        uiTestingPasscode = passcode
        passcodeLoadGeneration += 1
        passcodeLoadInFlight = false
        passcodeAvailability = .present
    }
    #endif

    private func scheduleNextRefresh() {
        stopTicker()
        guard monitoringActive, let deadline, !isLocked else { return }

        let remaining = deadline.timeIntervalSince(nowProvider())
        guard remaining > 0 else {
            refresh()
            return
        }

        // Wake only when the minute-rounded label can change, or at the exact lock deadline.
        // A 30-minute limit therefore uses 30 one-shot callbacks instead of 1,800 timer ticks.
        let roundedMinutes = max(1, Int(ceil(remaining / 60)))
        let nextMinuteBoundary = remaining - Double(roundedMinutes - 1) * 60
        let delay = max(0.02, min(remaining, nextMinuteBoundary))
        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.ticker = nil
                self.refresh()
                if !self.isLocked {
                    self.scheduleNextRefresh()
                }
            }
        }
        timer.tolerance = min(0.1, delay * 0.05)
        ticker = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }
}

enum ParentPlayTimerSetupAction: Equatable {
    case start(minutes: Int)
    case removeLimit
}

/// A dedicated overlay window keeps the lock above game menus, full-screen games, and their
/// nested sheets without tearing down the child's current game state.
@MainActor
final class ParentPlayTimerOverlayCoordinator {
    static let shared = ParentPlayTimerOverlayCoordinator()

    private weak var previousKeyWindow: UIWindow?
    private var overlayWindow: UIWindow?

    private init() {}

    func update(isLocked: Bool) {
        isLocked ? show() : hide()
    }

    func show() {
        guard let windowScene = preferredWindowScene() else { return }

        if let overlayWindow, overlayWindow.windowScene === windowScene {
            overlayWindow.isHidden = false
            overlayWindow.makeKey()
            return
        }

        hide()
        previousKeyWindow = windowScene.windows.first(where: \.isKeyWindow)

        let lockView = ParentPlayTimerLockView(timer: .shared)
        let hostingController = UIHostingController(rootView: lockView)
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.accessibilityViewIsModal = true

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue + 2)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        overlayWindow = window
    }

    func hide() {
        guard let overlayWindow else { return }
        overlayWindow.isHidden = true
        overlayWindow.rootViewController = nil
        self.overlayWindow = nil
        previousKeyWindow?.makeKey()
        previousKeyWindow = nil
    }

    private func preferredWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first(where: { $0.activationState == .foregroundActive })
            ?? scenes.first(where: { $0.activationState == .foregroundInactive })
    }
}

struct ParentPlayTimerLockView: View {
    @ObservedObject var timer: ParentPlayTimer

    @State private var showsParentGate = false
    @State private var showsPasscodeGate = false
    @State private var showsTimerSettings = false
    @State private var parentApproved = false
    @State private var recoverPasscodeAfterDismissal = false
    @State private var requiresNewPasscode = false
    @State private var challengeLeft = 18
    @State private var challengeRight = 27
    @State private var challengeAnswer = ""
    @State private var challengeError: String?
    @State private var pendingSetupAction: ParentPlayTimerSetupAction?
    @State private var showsPasscodeUnavailableAlert = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()

                RadialGradient(
                    colors: [AppTheme.cometPurple.opacity(0.24), Color.clear],
                    center: .top,
                    startRadius: 12,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.72
                )
                .ignoresSafeArea()
                .accessibilityHidden(true)

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        Spacer(minLength: AppSpacing.xl)

                        ZStack {
                            Circle()
                                .fill(AppTheme.backgroundMid)
                                .frame(width: 120, height: 120)
                            Circle()
                                .stroke(AppTheme.cometGold.opacity(0.7), lineWidth: 3)
                                .frame(width: 120, height: 120)
                            Image(systemName: "hourglass.bottomhalf.filled")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundColor(AppTheme.cometGold)
                        }
                        .accessibilityHidden(true)

                        VStack(spacing: AppSpacing.sm) {
                            Text("Time for a break")
                                .font(AppTypography.displayMedium)
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Great playing! Your play time is finished. Ask a grown-up when you’re ready for more time.")
                                .font(AppTypography.bodyLarge)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button {
                            beginParentAccess()
                        } label: {
                            Label("Grown-up options", systemImage: "person.crop.circle.badge.checkmark")
                                .font(AppTypography.buttonLarge)
                                .foregroundColor(AppTheme.backgroundDark)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .padding(.horizontal, AppSpacing.md)
                                .background(AppTheme.cometCyan)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: 360)
                        .accessibilityHint("Opens a grown-up check before changing the play timer")
                        .accessibilityIdentifier("play-time-grown-up-options")

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    .padding(.horizontal, AppSpacing.xl)
                }
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("play-time-lock")
        .alert("Parent passcode unavailable", isPresented: $showsPasscodeUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The saved passcode could not be checked just now. Please try again; it has not been changed.")
        }
        .sheet(isPresented: $showsPasscodeGate, onDismiss: handlePasscodeGateDismissal) {
            ParentPasscodeEntryView(
                timer: timer,
                onCancel: {
                    parentApproved = false
                    recoverPasscodeAfterDismissal = false
                    showsPasscodeGate = false
                },
                onSuccess: {
                    parentApproved = true
                    recoverPasscodeAfterDismissal = false
                    showsPasscodeGate = false
                },
                onForgotPasscode: {
                    parentApproved = false
                    recoverPasscodeAfterDismissal = true
                    showsPasscodeGate = false
                }
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showsParentGate, onDismiss: presentTimerSettingsIfApproved) {
            ParentGateView(
                left: challengeLeft,
                right: challengeRight,
                answer: $challengeAnswer,
                errorMessage: challengeError,
                message: "To reset the parent passcode, ask a grown-up to solve this check.",
                onCancel: {
                    parentApproved = false
                    showsParentGate = false
                },
                onContinue: validateParentCheck
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showsTimerSettings, onDismiss: applyPendingSetupAction) {
            ParentPlayTimerSetupView(
                timer: timer,
                requiresNewPasscode: requiresNewPasscode
            ) { action in
                pendingSetupAction = action
                showsTimerSettings = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func beginParentAccess() {
        parentApproved = false
        requiresNewPasscode = false
        switch timer.resolvePasscodeAvailabilityForParentAccess() {
        case .present:
            showsPasscodeGate = true
        case .absent:
            requiresNewPasscode = true
            beginParentCheck()
        case .loading, .unavailable:
            showsPasscodeUnavailableAlert = true
        }
    }

    private func beginParentCheck() {
        challengeLeft = Int.random(in: 14...29)
        challengeRight = Int.random(in: 17...38)
        challengeAnswer = ""
        challengeError = nil
        parentApproved = false
        showsParentGate = true
    }

    private func handlePasscodeGateDismissal() {
        if recoverPasscodeAfterDismissal {
            recoverPasscodeAfterDismissal = false
            requiresNewPasscode = true
            beginParentCheck()
            return
        }

        guard parentApproved else { return }
        parentApproved = false
        requiresNewPasscode = false
        showsTimerSettings = true
    }

    private func validateParentCheck() {
        guard Int(challengeAnswer) == challengeLeft + challengeRight else {
            challengeError = "That answer isn't right. Please try again."
            return
        }
        challengeError = nil
        parentApproved = true
        showsParentGate = false
    }

    private func presentTimerSettingsIfApproved() {
        guard parentApproved else { return }
        parentApproved = false
        showsTimerSettings = true
    }

    private func applyPendingSetupAction() {
        defer { requiresNewPasscode = false }
        guard let pendingSetupAction else { return }
        self.pendingSetupAction = nil
        switch pendingSetupAction {
        case .start(let minutes):
            timer.start(minutes: minutes)
        case .removeLimit:
            timer.removeLimit()
        }
    }
}

struct ParentPasscodeEntryView: View {
    @ObservedObject var timer: ParentPlayTimer
    let onCancel: () -> Void
    let onSuccess: () -> Void
    let onForgotPasscode: () -> Void

    @State private var passcode = ""
    @State private var errorMessage: String?
    @FocusState private var passcodeFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 46, weight: .semibold))
                            .foregroundColor(AppTheme.cometCyan)
                            .accessibilityHidden(true)

                        VStack(spacing: AppSpacing.sm) {
                            Text("Parent passcode")
                                .font(AppTypography.titleMedium)
                                .foregroundColor(AppTheme.textPrimary)

                            Text("Enter the four-digit code to add time or remove the block.")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Four-digit passcode")
                                .font(AppTypography.bodySmall.weight(.semibold))
                                .foregroundColor(AppTheme.textPrimary)

                            SecureField("••••", text: $passcode)
                                .keyboardType(.numberPad)
                                .textContentType(.password)
                                .font(AppTypography.titleMedium.monospacedDigit())
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(AppSpacing.md)
                                .frame(minHeight: 52)
                                .background(AppTheme.backgroundMid)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .focused($passcodeFocused)
                                .accessibilityIdentifier("parent-passcode-entry")
                                .onChange(of: passcode) { value in
                                    let sanitized = Self.sanitizedPasscode(value)
                                    if sanitized != value { passcode = sanitized }
                                    // Clearing the field after a failed attempt must not also
                                    // erase the explanation before the parent can read it.
                                    if !sanitized.isEmpty { errorMessage = nil }
                                }

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppTheme.error)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibilityLabel("Error: \(errorMessage)")
                            }
                        }
                        .frame(maxWidth: 360)

                        Button {
                            verifyPasscode()
                        } label: {
                            Text("Continue")
                                .font(AppTypography.buttonLarge)
                                .foregroundColor(AppTheme.backgroundDark)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(
                                    ParentPlayTimer.isValidPasscode(passcode)
                                        ? AppTheme.accentPrimary
                                        : AppTheme.backgroundMid
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .disabled(!ParentPlayTimer.isValidPasscode(passcode))
                        .frame(maxWidth: 360)
                        .accessibilityIdentifier("parent-passcode-continue")

                        Button("Forgot passcode?") {
                            onForgotPasscode()
                        }
                        .font(AppTypography.buttonSmall)
                        .foregroundColor(AppTheme.cometCyan)
                        .frame(minHeight: 44)
                        .accessibilityHint("Opens the grown-up check so a new passcode can be created")
                        .accessibilityIdentifier("parent-passcode-forgot")
                    }
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.xxl)
                    .padding(.bottom, AppSpacing.xxl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Grown-up options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
            .onAppear { passcodeFocused = true }
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("parent-passcode-sheet")
    }

    private func verifyPasscode() {
        guard timer.verifyPasscode(passcode) else {
            passcode = ""
            errorMessage = "That passcode isn't right. Please try again."
            passcodeFocused = true
            return
        }
        errorMessage = nil
        onSuccess()
    }

    fileprivate static func sanitizedPasscode(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(4))
    }
}

struct ParentPlayTimerSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var timer: ParentPlayTimer
    let onApply: (ParentPlayTimerSetupAction) -> Void

    @State private var selectedMinutes: Int
    @State private var isEditingPasscode: Bool
    @State private var newPasscode = ""
    @State private var confirmedPasscode = ""
    @State private var passcodeError: String?

    init(
        timer: ParentPlayTimer,
        requiresNewPasscode: Bool = false,
        onApply: @escaping (ParentPlayTimerSetupAction) -> Void
    ) {
        self.timer = timer
        self.onApply = onApply
        _selectedMinutes = State(initialValue: timer.suggestedMinutes)
        _isEditingPasscode = State(initialValue: requiresNewPasscode || !timer.hasPasscode)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        VStack(spacing: AppSpacing.sm) {
                            Image(systemName: "timer")
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundColor(AppTheme.cometCyan)
                                .accessibilityHidden(true)

                            Text("Set play time")
                                .font(AppTypography.titleMedium)
                                .foregroundColor(AppTheme.textPrimary)

                            Text("The clock keeps counting if the app is closed. When time runs out, play pauses until a grown-up changes the timer.")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(spacing: AppSpacing.md) {
                            Text("\(selectedMinutes)")
                                .font(AppTypography.displayLarge.monospacedDigit())
                                .foregroundColor(AppTheme.textPrimary)
                            Text("minutes")
                                .font(AppTypography.bodyLarge)
                                .foregroundColor(AppTheme.textSecondary)

                            Stepper(
                                "Play time: \(selectedMinutes) minutes",
                                value: $selectedMinutes,
                                in: ParentPlayTimer.minimumMinutes...ParentPlayTimer.maximumMinutes,
                                step: 5
                            )
                            .labelsHidden()
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("play-time-stepper")
                        }
                        .padding(AppSpacing.lg)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.backgroundMid.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        HStack(spacing: AppSpacing.sm) {
                            ForEach(ParentPlayTimer.presetMinutes, id: \.self) { minutes in
                                Button {
                                    selectedMinutes = minutes
                                } label: {
                                    Text("\(minutes)")
                                        .font(AppTypography.buttonSmall.monospacedDigit())
                                        .foregroundColor(
                                            selectedMinutes == minutes
                                                ? AppTheme.backgroundDark
                                                : AppTheme.textPrimary
                                        )
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                        .background(
                                            selectedMinutes == minutes
                                                ? AppTheme.cometCyan
                                                : AppTheme.backgroundMid
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(minutes) minutes")
                                .accessibilityAddTraits(selectedMinutes == minutes ? .isSelected : [])
                                .accessibilityIdentifier("play-time-preset-\(minutes)")
                            }
                        }

                        passcodeSection

                        VStack(spacing: AppSpacing.md) {
                            Button {
                                applyTimer()
                            } label: {
                                Text(timer.isLocked ? "Start \(selectedMinutes) minutes" : "Set \(selectedMinutes) minutes")
                                    .font(AppTypography.buttonLarge)
                                    .foregroundColor(AppTheme.backgroundDark)
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(AppTheme.accentPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("play-time-apply")

                            if timer.hasLimit {
                                Button {
                                    onApply(.removeLimit)
                                } label: {
                                    Text("Remove time limit")
                                        .font(AppTypography.buttonLarge)
                                        .foregroundColor(AppTheme.textPrimary)
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                        .background(AppTheme.backgroundMid)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Unlocks play without starting another timer")
                                .accessibilityIdentifier("play-time-remove-limit")
                            }
                        }
                    }
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Play timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("play-time-settings")
    }

    private var passcodeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(AppTheme.cometCyan)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(timer.hasPasscode ? "Parent passcode is set" : "Create a parent passcode")
                        .font(AppTypography.bodyMedium.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("You’ll need this code to add time or remove the block.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if timer.hasPasscode, !isEditingPasscode {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accentPrimary)
                        .accessibilityLabel("Passcode protected")
                }
            }

            if isEditingPasscode {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    passcodeField(
                        title: timer.hasPasscode ? "New four-digit passcode" : "Four-digit passcode",
                        text: $newPasscode,
                        identifier: "new-parent-passcode"
                    )
                    passcodeField(
                        title: "Confirm passcode",
                        text: $confirmedPasscode,
                        identifier: "confirm-parent-passcode"
                    )

                    if let passcodeError {
                        Text(passcodeError)
                            .font(AppTypography.caption)
                            .foregroundColor(AppTheme.error)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("Error: \(passcodeError)")
                    }
                }
            } else {
                Button("Change passcode") {
                    newPasscode = ""
                    confirmedPasscode = ""
                    passcodeError = nil
                    isEditingPasscode = true
                }
                .font(AppTypography.buttonSmall)
                .foregroundColor(AppTheme.cometCyan)
                .frame(minHeight: 44)
                .accessibilityIdentifier("change-parent-passcode")
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.backgroundMid.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func passcodeField(
        title: String,
        text: Binding<String>,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.bodySmall.weight(.semibold))
                .foregroundColor(AppTheme.textPrimary)

            SecureField("••••", text: text)
                .keyboardType(.numberPad)
                .font(AppTypography.titleSmall.monospacedDigit())
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.textPrimary)
                .padding(AppSpacing.md)
                .frame(minHeight: 52)
                .background(AppTheme.backgroundDark.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityIdentifier(identifier)
                .onChange(of: text.wrappedValue) { value in
                    let sanitized = ParentPasscodeEntryView.sanitizedPasscode(value)
                    if sanitized != value { text.wrappedValue = sanitized }
                    passcodeError = nil
                }
        }
    }

    private func applyTimer() {
        if isEditingPasscode {
            guard ParentPlayTimer.isValidPasscode(newPasscode) else {
                passcodeError = "Choose exactly four numbers."
                return
            }
            guard newPasscode == confirmedPasscode else {
                passcodeError = "The two passcodes don't match."
                return
            }
            guard timer.setPasscode(newPasscode) else {
                passcodeError = "The passcode couldn't be saved. Please try again."
                return
            }
        }

        passcodeError = nil
        onApply(.start(minutes: selectedMinutes))
    }
}
