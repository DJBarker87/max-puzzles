# Phase 6: Authentication

**Objective:** Implement authentication including guest mode, parent login/signup, family management, and child PIN authentication using Supabase.

**Dependencies:** Phase 1 (Foundation), Phase 5 (Hub Screens)

---

## Subphase 6.1: Auth Types

**Goal:** Define all types for authentication and user management.

### Prompt for Claude Code:

```
Create the authentication types for Max's Puzzles iOS app.

Create file: Shared/Models/AuthTypes.swift

```swift
import Foundation

/// User role types
enum UserRole: String, Codable {
    case parent
    case child
}

/// User profile information
struct User: Identifiable, Codable {
    /// Unique user identifier
    let id: String
    /// Family this user belongs to (nil for guest users)
    let familyId: String?
    /// Email address (parents only)
    let email: String?
    /// Display name shown in the app
    let displayName: String
    /// User role (parent or child)
    let role: UserRole
    /// Current coin balance
    var coins: Int
    /// Whether the user account is active
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case email
        case displayName = "display_name"
        case role
        case coins
        case isActive = "is_active"
    }
}

/// Family group containing parents and children
struct Family: Identifiable, Codable {
    /// Unique family identifier
    let id: String
    /// Family display name
    let name: String
    /// When the family was created
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
}

/// Child user info for family selection
struct Child: Identifiable {
    let id: String
    let displayName: String
    var avatarEmoji: String = "👽"
    var coins: Int = 0
}

/// Child session for PIN-based sub-authentication
struct ChildSession: Codable {
    /// Child's user ID
    let childId: String
    /// Child's display name
    let displayName: String
    /// Family this child belongs to
    let familyId: String
}

/// Parent session with full account access
struct ParentSession: Codable {
    /// Parent's user ID
    let userId: String
    /// Parent's email
    let email: String
    /// Family ID
    let familyId: String
    /// Session token
    let token: String
}

/// Authentication state
struct AuthState {
    var user: User? = nil
    var family: Family? = nil
    var children: [Child] = []
    var isGuest: Bool = false
    var isDemoMode: Bool = false
    var isLoading: Bool = true
    var activeChildId: String? = nil
}

/// Result of authentication operations
enum AuthResult {
    case success(User)
    case failure(AuthError)
}

/// Authentication errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError
    case invalidPin
    case accountExists
    case weakPassword
    case emailRequired
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error. Please try again."
        case .invalidPin:
            return "Wrong PIN. Try again!"
        case .accountExists:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .emailRequired:
            return "Email is required"
        case .unknown(let message):
            return message
        }
    }
}
```
```

---

## Subphase 6.2: Local Storage Service

**Goal:** Implement local storage for guest mode and offline data using UserDefaults and/or Core Data.

### Prompt for Claude Code:

```
Create the LocalStorageService for Max's Puzzles iOS app.

Create file: Shared/Services/LocalStorageService.swift

This service handles local storage for guest mode and offline data:

```swift
import Foundation

/// Keys for UserDefaults storage
enum StorageKey: String {
    case guestProfile = "guest_profile"
    case guestProgress = "guest_progress"
    case appSettings = "app_settings"
    case lastSyncTimestamp = "last_sync_timestamp"
}

/// Local storage service for guest mode and offline data
class LocalStorageService {
    static let shared = LocalStorageService()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Guest Profile

    /// Initialize or retrieve guest profile
    func initGuestProfile() -> User {
        if let existingProfile = getGuestProfile() {
            return existingProfile
        }

        // Create new guest profile
        let guestProfile = User(
            id: "guest_\(UUID().uuidString)",
            familyId: nil,
            email: nil,
            displayName: "Guest",
            role: .child,
            coins: 0,
            isActive: true
        )

        saveGuestProfile(guestProfile)
        return guestProfile
    }

    /// Get existing guest profile
    func getGuestProfile() -> User? {
        guard let data = defaults.data(forKey: StorageKey.guestProfile.rawValue) else {
            return nil
        }
        return try? decoder.decode(User.self, from: data)
    }

    /// Save guest profile
    func saveGuestProfile(_ profile: User) {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: StorageKey.guestProfile.rawValue)
        }
    }

    /// Clear guest data (after account creation)
    func clearGuestData() {
        defaults.removeObject(forKey: StorageKey.guestProfile.rawValue)
        defaults.removeObject(forKey: StorageKey.guestProgress.rawValue)
    }

    // MARK: - Progress Storage

    /// Module progress data structure
    struct ModuleProgress: Codable {
        var quickPlayGames: Int = 0
        var bestStreak: Int = 0
        var totalCorrect: Int = 0
        var totalMistakes: Int = 0
        var lastPlayedAt: Date?
    }

    /// Get progress for a module
    func getModuleProgress(moduleId: String) -> ModuleProgress {
        guard let data = defaults.data(forKey: "\(StorageKey.guestProgress.rawValue)_\(moduleId)"),
              let progress = try? decoder.decode(ModuleProgress.self, from: data) else {
            return ModuleProgress()
        }
        return progress
    }

    /// Save progress for a module
    func saveModuleProgress(_ progress: ModuleProgress, moduleId: String) {
        if let data = try? encoder.encode(progress) {
            defaults.set(data, forKey: "\(StorageKey.guestProgress.rawValue)_\(moduleId)")
        }
    }

    // MARK: - App Settings

    struct AppSettings: Codable {
        var soundEnabled: Bool = true
        var musicEnabled: Bool = true
        var animationLevel: AnimationLevel = .full

        enum AnimationLevel: String, Codable {
            case full
            case reduced
        }
    }

    func getSettings() -> AppSettings {
        guard let data = defaults.data(forKey: StorageKey.appSettings.rawValue),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    func saveSettings(_ settings: AppSettings) {
        if let data = try? encoder.encode(settings) {
            defaults.set(data, forKey: StorageKey.appSettings.rawValue)
        }
    }
}
```

Unit tests:
- Test guest profile creation
- Test guest profile persistence
- Test progress save/load
- Test settings save/load
- Test clear guest data
```

---

## Subphase 6.3: Supabase Configuration

**Goal:** Set up Supabase client configuration for the iOS app.

### Prompt for Claude Code:

```
Create the Supabase configuration for Max's Puzzles iOS app.

First, add the Supabase Swift package to the project:
- Package URL: https://github.com/supabase/supabase-swift
- Version: 2.0.0 or later

Create file: Shared/Services/SupabaseConfig.swift

```swift
import Foundation
import Supabase

/// Supabase client configuration
class SupabaseConfig {
    static let shared = SupabaseConfig()

    /// The Supabase client (nil if not configured)
    private(set) var client: SupabaseClient?

    /// Whether Supabase is configured and available
    var isConfigured: Bool {
        return client != nil
    }

    private init() {
        configure()
    }

    private func configure() {
        // Load from environment or config
        // For development, these can be hardcoded
        // For production, use a configuration file or environment variables

        guard let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ??
                                Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ??
                                Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              let url = URL(string: supabaseURL) else {
            print("⚠️ Supabase not configured - running in offline mode")
            return
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
        )
    }

    /// Reconfigure with explicit values (for testing)
    func configure(url: String, key: String) {
        guard let supabaseURL = URL(string: url) else { return }
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key
        )
    }
}

// MARK: - Convenience accessor

var supabase: SupabaseClient? {
    SupabaseConfig.shared.client
}

/// Check if Supabase is available
func isSupabaseConfigured() -> Bool {
    SupabaseConfig.shared.isConfigured
}
```

Also create an Info.plist entry for Supabase credentials:
- SUPABASE_URL: Your Supabase project URL
- SUPABASE_ANON_KEY: Your Supabase anonymous key

For development, you can also add these to a Config.xcconfig file.
```

---

## Subphase 6.4: Auth Service

**Goal:** Implement the authentication service with Supabase integration.

### Prompt for Claude Code:

```
Create the AuthService for Max's Puzzles iOS app.

Create file: Shared/Services/AuthService.swift

```swift
import Foundation
import Supabase

/// Authentication service handling all auth operations
class AuthService {
    static let shared = AuthService()

    private let localStorage = LocalStorageService.shared

    private init() {}

    // MARK: - Sign Up

    /// Sign up a new parent user
    func signUp(email: String, password: String, displayName: String) async throws -> User {
        guard let client = supabase else {
            throw AuthError.networkError
        }

        // Create auth user
        let authResponse = try await client.auth.signUp(
            email: email,
            password: password
        )

        guard let authUser = authResponse.user else {
            throw AuthError.unknown("Failed to create account")
        }

        // Create family
        let familyResponse: Family = try await client
            .from("families")
            .insert(["name": "\(displayName)'s Family"])
            .select()
            .single()
            .execute()
            .value

        // Create user profile
        let userProfile: User = try await client
            .from("users")
            .insert([
                "id": authUser.id.uuidString,
                "auth_id": authUser.id.uuidString,
                "family_id": familyResponse.id,
                "email": email,
                "display_name": displayName,
                "role": "parent",
                "coins": 0,
                "is_active": true
            ])
            .select()
            .single()
            .execute()
            .value

        return userProfile
    }

    // MARK: - Sign In

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> User {
        guard let client = supabase else {
            throw AuthError.networkError
        }

        let session = try await client.auth.signIn(
            email: email,
            password: password
        )

        // Fetch user profile
        let user: User = try await client
            .from("users")
            .select()
            .eq("auth_id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value

        return user
    }

    // MARK: - Sign Out

    /// Sign out current user
    func signOut() async throws {
        guard let client = supabase else { return }
        try await client.auth.signOut()
    }

    // MARK: - Current User

    /// Get current authenticated user
    func getCurrentUser() async throws -> User? {
        guard let client = supabase else { return nil }

        guard let session = try? await client.auth.session else {
            return nil
        }

        let user: User = try await client
            .from("users")
            .select()
            .eq("auth_id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value

        return user
    }

    // MARK: - Family

    /// Fetch family by ID
    func fetchFamily(id: String) async throws -> Family? {
        guard let client = supabase else { return nil }

        let family: Family = try await client
            .from("families")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        return family
    }

    /// Fetch children in a family
    func fetchFamilyChildren(familyId: String) async throws -> [User] {
        guard let client = supabase else { return [] }

        let children: [User] = try await client
            .from("users")
            .select()
            .eq("family_id", value: familyId)
            .eq("role", value: "child")
            .eq("is_active", value: true)
            .execute()
            .value

        return children
    }

    // MARK: - Child Management

    /// Add a new child to a family
    func addChild(familyId: String, displayName: String, pin: String) async throws -> User {
        guard let client = supabase else {
            throw AuthError.networkError
        }

        // Hash the PIN (simple hash for now, use proper hashing in production)
        let pinHash = hashPin(pin)

        let child: User = try await client
            .from("users")
            .insert([
                "family_id": familyId,
                "display_name": displayName,
                "role": "child",
                "pin_hash": pinHash,
                "coins": 0,
                "is_active": true
            ])
            .select()
            .single()
            .execute()
            .value

        return child
    }

    /// Verify a child's PIN
    func verifyChildPin(childId: String, pin: String) async throws -> Bool {
        guard let client = supabase else {
            throw AuthError.networkError
        }

        // Fetch the child's PIN hash
        struct PinHashResult: Decodable {
            let pin_hash: String?
        }

        let result: PinHashResult = try await client
            .from("users")
            .select("pin_hash")
            .eq("id", value: childId)
            .single()
            .execute()
            .value

        guard let storedHash = result.pin_hash else {
            return false
        }

        return verifyPin(pin, against: storedHash)
    }

    /// Remove a child (soft delete)
    func removeChild(childId: String) async throws {
        guard let client = supabase else {
            throw AuthError.networkError
        }

        try await client
            .from("users")
            .update(["is_active": false])
            .eq("id", value: childId)
            .execute()
    }

    // MARK: - PIN Hashing

    private func hashPin(_ pin: String) -> String {
        // Simple hash for development
        // In production, use proper bcrypt or argon2 hashing
        return pin.data(using: .utf8)?.base64EncodedString() ?? ""
    }

    private func verifyPin(_ pin: String, against hash: String) -> Bool {
        return hashPin(pin) == hash
    }
}
```

Unit tests:
- Test sign up flow
- Test sign in flow
- Test sign out
- Test fetch family
- Test fetch children
- Test add child
- Test verify PIN
- Test PIN hashing
```

---

## Subphase 6.5: Auth Manager (ViewModel)

**Goal:** Create the main AuthManager as an ObservableObject for SwiftUI.

### Prompt for Claude Code:

```
Create the AuthManager for Max's Puzzles iOS app.

Create file: Shared/ViewModels/AuthManager.swift

```swift
import SwiftUI
import Combine

/// Main authentication manager for the app
@MainActor
class AuthManager: ObservableObject {
    // MARK: - Published State
    @Published private(set) var currentUser: User?
    @Published private(set) var family: Family?
    @Published private(set) var children: [Child] = []
    @Published private(set) var isGuest: Bool = false
    @Published private(set) var isDemoMode: Bool = false
    @Published private(set) var isLoading: Bool = true
    @Published private(set) var activeChildId: String?

    // MARK: - Services
    private let authService = AuthService.shared
    private let localStorage = LocalStorageService.shared

    // MARK: - Computed Properties

    /// The currently selected child (if any)
    var selectedChild: Child? {
        guard let id = activeChildId else { return nil }
        return children.first { $0.id == id }
    }

    /// Whether Supabase is configured and online
    var isOnline: Bool {
        isSupabaseConfigured()
    }

    // MARK: - Initialization

    init() {
        Task {
            await initialize()
        }
    }

    /// Initialize auth state
    private func initialize() async {
        defer { isLoading = false }

        do {
            // Check for existing session
            if let user = try await authService.getCurrentUser() {
                await loadUserData(user)
            }
        } catch {
            print("Auth initialization error: \(error)")
        }
    }

    /// Load user data including family and children
    private func loadUserData(_ user: User) async {
        guard let familyId = user.familyId else { return }

        do {
            let family = try await authService.fetchFamily(id: familyId)
            let familyChildren = try await authService.fetchFamilyChildren(familyId: familyId)

            self.currentUser = user
            self.family = family
            self.children = familyChildren.map { Child(
                id: $0.id,
                displayName: $0.displayName,
                avatarEmoji: "👽",
                coins: $0.coins
            )}
            self.isGuest = false
            self.isDemoMode = false
        } catch {
            print("Error loading user data: \(error)")
        }
    }

    // MARK: - Auth Actions

    /// Sign up a new parent account
    func signup(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let user = try await authService.signUp(
            email: email,
            password: password,
            displayName: displayName
        )

        await loadUserData(user)
    }

    /// Log in with email and password
    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let user = try await authService.signIn(email: email, password: password)
        await loadUserData(user)
    }

    /// Log out current user
    func logout() async {
        do {
            try await authService.signOut()
        } catch {
            print("Logout error: \(error)")
        }

        currentUser = nil
        family = nil
        children = []
        isGuest = false
        isDemoMode = false
        activeChildId = nil
    }

    // MARK: - Guest Mode

    /// Enter guest mode (no account)
    func setGuestMode() {
        let guestUser = localStorage.initGuestProfile()

        currentUser = guestUser
        family = nil
        children = []
        isGuest = true
        isDemoMode = false
        isLoading = false
        activeChildId = nil
    }

    // MARK: - Family Actions

    /// Select a child and verify PIN
    func selectChild(id: String, pin: String) async throws {
        let isValid = try await authService.verifyChildPin(childId: id, pin: pin)

        if !isValid {
            throw AuthError.invalidPin
        }

        guard let child = children.first(where: { $0.id == id }) else {
            throw AuthError.unknown("Child not found")
        }

        // Create a child user object for the session
        let childUser = User(
            id: child.id,
            familyId: family?.id,
            email: nil,
            displayName: child.displayName,
            role: .child,
            coins: child.coins,
            isActive: true
        )

        currentUser = childUser
        activeChildId = id
        isDemoMode = false
    }

    /// Enter parent demo mode
    func enterDemoMode() {
        guard let family = family else { return }

        let demoUser = User(
            id: "demo",
            familyId: family.id,
            email: nil,
            displayName: "Demo",
            role: .parent,
            coins: 0,
            isActive: true
        )

        currentUser = demoUser
        isDemoMode = true
        activeChildId = nil
    }

    /// Exit demo mode
    func exitDemoMode() {
        currentUser = nil
        isDemoMode = false
        activeChildId = nil
    }

    /// Add a new child to the family
    func addChild(displayName: String, pin: String) async throws {
        guard let familyId = family?.id else {
            throw AuthError.unknown("No family found")
        }

        let newChild = try await authService.addChild(
            familyId: familyId,
            displayName: displayName,
            pin: pin
        )

        children.append(Child(
            id: newChild.id,
            displayName: newChild.displayName,
            avatarEmoji: "👽",
            coins: newChild.coins
        ))
    }

    /// Remove a child from the family
    func removeChild(id: String) async throws {
        try await authService.removeChild(childId: id)
        children.removeAll { $0.id == id }
    }

    // MARK: - Preview Support

    static var preview: AuthManager {
        let manager = AuthManager()
        manager.isLoading = false
        manager.currentUser = User(
            id: "preview",
            familyId: "family1",
            email: "parent@test.com",
            displayName: "Test Parent",
            role: .parent,
            coins: 150,
            isActive: true
        )
        manager.family = Family(
            id: "family1",
            name: "Test Family",
            createdAt: Date()
        )
        manager.children = [
            Child(id: "child1", displayName: "Max", avatarEmoji: "👽", coins: 50),
            Child(id: "child2", displayName: "Emma", avatarEmoji: "👽", coins: 30)
        ]
        return manager
    }
}
```

Unit tests:
- Test initialization
- Test signup flow
- Test login flow
- Test logout
- Test guest mode
- Test child selection with PIN
- Test demo mode
- Test add/remove child
```

---

## Subphase 6.6: Login View

**Goal:** Create the login/signup screen with guest play option.

### Prompt for Claude Code:

```
Create the LoginView for Max's Puzzles iOS app.

Create file: Hub/Views/LoginView.swift

```swift
import SwiftUI

enum LoginMode {
    case choice
    case login
    case signup
}

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var mode: LoginMode = .choice
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var error: String?
    @State private var isLoading = false

    @State private var navigateToHub = false
    @State private var navigateToFamilySelect = false

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            switch mode {
            case .choice:
                choiceView
            case .login:
                loginFormView
            case .signup:
                signupFormView
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToHub) {
            MainHubView()
        }
        .navigationDestination(isPresented: $navigateToFamilySelect) {
            FamilySelectView()
        }
    }

    // MARK: - Choice View

    private var choiceView: some View {
        VStack(spacing: 24) {
            // Logo
            VStack(spacing: 16) {
                Text("👽")
                    .font(.system(size: 80))

                HStack {
                    Text("Max's")
                        .foregroundColor(.accentPrimary)
                    Text("Puzzles")
                        .foregroundColor(.white)
                }
                .font(.system(size: 36, weight: .bold, design: .rounded))
            }
            .padding(.bottom, 32)

            // Guest play button
            Button(action: handleGuestPlay) {
                Text("Play as Guest")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentPrimary)
                    .cornerRadius(12)
            }
            .frame(maxWidth: 300)

            Text("No account needed - jump right in!")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            // Divider
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
            }
            .frame(maxWidth: 300)

            // Login/Signup buttons
            HStack(spacing: 12) {
                Button(action: { resetForm(); mode = .login }) {
                    Text("Log In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.backgroundDark)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }

                Button(action: { resetForm(); mode = .signup }) {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentSecondary)
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: 300)

            // Benefits
            VStack(spacing: 8) {
                Text("With a family account you can:")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("• Save progress across devices")
                    Text("• Track multiple children")
                    Text("• View parent dashboard")
                }
                .font(.caption)
                .foregroundColor(.textSecondary)
            }
            .padding(.top, 24)
        }
        .padding()
    }

    // MARK: - Login Form

    private var loginFormView: some View {
        VStack(spacing: 24) {
            Text("Welcome Back!")
                .font(.title.bold())
                .foregroundColor(.white)

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(AuthTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(AuthTextFieldStyle())

                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.error)
                }

                Button(action: handleLogin) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Log In")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentPrimary)
                .cornerRadius(8)
                .disabled(isLoading)
            }
            .frame(maxWidth: 300)

            Button("Back") {
                resetForm()
                mode = .choice
            }
            .font(.subheadline)
            .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.9))
        .cornerRadius(16)
        .padding()
    }

    // MARK: - Signup Form

    private var signupFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Create Account")
                    .font(.title.bold())
                    .foregroundColor(.white)

                VStack(spacing: 16) {
                    TextField("Your Name", text: $displayName)
                        .textFieldStyle(AuthTextFieldStyle())

                    TextField("Email", text: $email)
                        .textFieldStyle(AuthTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(AuthTextFieldStyle())

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(AuthTextFieldStyle())

                    if let error = error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.error)
                    }

                    Button(action: handleSignup) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Account")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentPrimary)
                    .cornerRadius(8)
                    .disabled(isLoading)
                }
                .frame(maxWidth: 300)

                Button("Back") {
                    resetForm()
                    mode = .choice
                }
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            }
            .padding()
        }
        .background(Color.backgroundMid.opacity(0.9))
        .cornerRadius(16)
        .padding()
    }

    // MARK: - Actions

    private func handleGuestPlay() {
        authManager.setGuestMode()
        navigateToHub = true
    }

    private func handleLogin() {
        error = nil
        isLoading = true

        Task {
            do {
                try await authManager.login(email: email, password: password)
                navigateToFamilySelect = true
            } catch {
                self.error = "Invalid email or password"
            }
            isLoading = false
        }
    }

    private func handleSignup() {
        // Validation
        if password != confirmPassword {
            error = "Passwords do not match"
            return
        }
        if password.count < 6 {
            error = "Password must be at least 6 characters"
            return
        }

        error = nil
        isLoading = true

        Task {
            do {
                try await authManager.signup(
                    email: email,
                    password: password,
                    displayName: displayName
                )
                navigateToFamilySelect = true
            } catch {
                self.error = "Could not create account"
            }
            isLoading = false
        }
    }

    private func resetForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        error = nil
    }
}

// MARK: - Text Field Style

struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.backgroundDark)
            .cornerRadius(8)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthManager.preview)
    }
}
```
```

---

## Subphase 6.7: Family Select View

**Goal:** Create the family selection screen for logged-in families.

### Prompt for Claude Code:

```
Create the FamilySelectView for Max's Puzzles iOS app.

Create file: Hub/Views/FamilySelectView.swift

```swift
import SwiftUI

struct FamilySelectView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedChild: Child?
    @State private var showPinEntry = false
    @State private var pinError: String?

    @State private var navigateToHub = false
    @State private var navigateToDashboard = false
    @State private var navigateToAddChild = false

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Who's Playing?")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text(authManager.family?.name ?? "Your Family")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, 32)

                // Children Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(authManager.children) { child in
                            ChildCard(child: child) {
                                selectedChild = child
                                pinError = nil
                                showPinEntry = true
                            }
                        }

                        // Add Child button (if less than max)
                        if authManager.children.count < 5 {
                            AddChildCard {
                                navigateToAddChild = true
                            }
                        }
                    }
                    .padding()
                }

                Spacer()

                // Parent Options
                VStack(spacing: 12) {
                    Button(action: { navigateToDashboard = true }) {
                        Text("Parent Dashboard")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentSecondary)
                            .cornerRadius(8)
                    }

                    Button(action: handleDemoMode) {
                        Text("Play as Parent (Demo)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.backgroundDark)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }

                    NavigationLink(destination: SettingsView()) {
                        Text("Settings")
                            .font(.headline)
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .padding()
            }

            // PIN Entry Sheet
            if showPinEntry, let child = selectedChild {
                PinEntrySheet(
                    childName: child.displayName,
                    avatarEmoji: child.avatarEmoji,
                    error: pinError,
                    onSubmit: { pin in handlePinSubmit(pin) },
                    onCancel: { showPinEntry = false }
                )
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToHub) {
            MainHubView()
        }
        .navigationDestination(isPresented: $navigateToDashboard) {
            ParentDashboardView()
        }
        .navigationDestination(isPresented: $navigateToAddChild) {
            AddChildView()
        }
    }

    private func handlePinSubmit(_ pin: String) {
        guard let child = selectedChild else { return }

        Task {
            do {
                try await authManager.selectChild(id: child.id, pin: pin)
                showPinEntry = false
                navigateToHub = true
            } catch {
                pinError = "Wrong PIN. Try again!"
            }
        }
    }

    private func handleDemoMode() {
        authManager.enterDemoMode()
        navigateToHub = true
    }
}

// MARK: - Child Card

struct ChildCard: View {
    let child: Child
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(child.avatarEmoji)
                    .font(.system(size: 48))

                Text(child.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(width: 100, height: 120)
            .background(Color.backgroundMid.opacity(0.8))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Add Child Card

struct AddChildCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text("+")
                    .font(.system(size: 40))
                    .foregroundColor(.textSecondary)

                Text("Add Child")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(width: 100, height: 120)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(.white.opacity(0.3))
            )
        }
    }
}

#Preview {
    NavigationStack {
        FamilySelectView()
            .environmentObject(AuthManager.preview)
    }
}
```
```

---

## Subphase 6.8: PIN Entry Sheet

**Goal:** Create the PIN entry modal for child authentication.

### Prompt for Claude Code:

```
Create the PinEntrySheet for Max's Puzzles iOS app.

Create file: Hub/Views/Components/PinEntrySheet.swift

```swift
import SwiftUI

struct PinEntrySheet: View {
    let childName: String
    let avatarEmoji: String
    let error: String?
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var pin = ""
    @State private var isShaking = false

    private let numberPad: [PinKey] = [
        .digit(1), .digit(2), .digit(3),
        .digit(4), .digit(5), .digit(6),
        .digit(7), .digit(8), .digit(9),
        .empty, .digit(0), .back
    ]

    enum PinKey {
        case digit(Int)
        case back
        case empty
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }

            // Modal
            VStack(spacing: 24) {
                // Child info
                VStack(spacing: 8) {
                    Text(avatarEmoji)
                        .font(.system(size: 60))

                    Text(childName)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }

                // PIN dots
                HStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < pin.count ? Color.accentPrimary : Color.clear)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(
                                        index < pin.count ? Color.accentPrimary : Color.white.opacity(0.3),
                                        lineWidth: 2
                                    )
                            )
                    }
                }
                .modifier(ShakeEffect(animatableData: isShaking ? 1 : 0))

                // Error message
                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.error)
                } else {
                    Text("Enter your 4-digit PIN")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                // Number pad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(0..<numberPad.count, id: \.self) { index in
                        PinKeyButton(key: numberPad[index]) { key in
                            handleKeyPress(key)
                        }
                    }
                }
                .frame(maxWidth: 240)

                // Cancel button
                Button("Cancel") {
                    onCancel()
                }
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            }
            .padding(32)
            .background(Color.backgroundMid)
            .cornerRadius(24)
            .padding(40)
        }
        .onChange(of: error) { _, newError in
            if newError != nil {
                triggerShake()
                pin = ""
            }
        }
    }

    private func handleKeyPress(_ key: PinKey) {
        switch key {
        case .digit(let num):
            if pin.count < 4 {
                pin += String(num)
                if pin.count == 4 {
                    onSubmit(pin)
                }
            }
        case .back:
            if !pin.isEmpty {
                pin.removeLast()
            }
        case .empty:
            break
        }
    }

    private func triggerShake() {
        withAnimation(.linear(duration: 0.3)) {
            isShaking = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShaking = false
        }
    }
}

struct PinKeyButton: View {
    let key: PinEntrySheet.PinKey
    let onTap: (PinEntrySheet.PinKey) -> Void

    var body: some View {
        Button(action: { onTap(key) }) {
            Group {
                switch key {
                case .digit(let num):
                    Text("\(num)")
                        .font(.title)
                        .foregroundColor(.white)
                case .back:
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .foregroundColor(.textSecondary)
                case .empty:
                    Color.clear
                }
            }
            .frame(width: 64, height: 56)
            .background(
                key == .empty
                    ? Color.clear
                    : Color.backgroundDark
            )
            .cornerRadius(12)
        }
        .disabled(key == .empty)
    }
}

#Preview {
    PinEntrySheet(
        childName: "Max",
        avatarEmoji: "👽",
        error: nil,
        onSubmit: { _ in },
        onCancel: { }
    )
}
```
```

---

## Subphase 6.9: Add Child View

**Goal:** Create the screen for adding a new child to the family.

### Prompt for Claude Code:

```
Create the AddChildView for Max's Puzzles iOS app.

Create file: Hub/Views/AddChildView.swift

```swift
import SwiftUI

struct AddChildView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var error: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HubHeader(title: "Add Child", showBack: true)

                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar preview
                        VStack(spacing: 8) {
                            Text("👽")
                                .font(.system(size: 80))

                            Text(displayName.isEmpty ? "New Player" : displayName)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 24)

                        // Form
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Child's Name")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)

                                TextField("e.g., Max", text: $displayName)
                                    .textFieldStyle(AuthTextFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Set a PIN")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)

                                SecureField("4-digit PIN", text: $pin)
                                    .textFieldStyle(AuthTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .onChange(of: pin) { _, newValue in
                                        // Limit to 4 digits
                                        if newValue.count > 4 {
                                            pin = String(newValue.prefix(4))
                                        }
                                        // Only allow digits
                                        pin = newValue.filter { $0.isNumber }
                                    }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm PIN")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)

                                SecureField("Repeat PIN", text: $confirmPin)
                                    .textFieldStyle(AuthTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .onChange(of: confirmPin) { _, newValue in
                                        if newValue.count > 4 {
                                            confirmPin = String(newValue.prefix(4))
                                        }
                                        confirmPin = newValue.filter { $0.isNumber }
                                    }
                            }

                            if let error = error {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.error)
                            }
                        }
                        .padding()
                        .background(Color.backgroundMid.opacity(0.8))
                        .cornerRadius(12)

                        // Add button
                        Button(action: handleAddChild) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Add Child")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            isFormValid
                                ? Color.accentPrimary
                                : Color.gray.opacity(0.5)
                        )
                        .cornerRadius(12)
                        .disabled(!isFormValid || isLoading)

                        // Info text
                        Text("The PIN will be used when this child selects their profile to play.")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var isFormValid: Bool {
        !displayName.isEmpty &&
        pin.count == 4 &&
        pin == confirmPin
    }

    private func handleAddChild() {
        // Validation
        if displayName.isEmpty {
            error = "Please enter a name"
            return
        }
        if pin.count != 4 {
            error = "PIN must be 4 digits"
            return
        }
        if pin != confirmPin {
            error = "PINs do not match"
            return
        }

        error = nil
        isLoading = true

        Task {
            do {
                try await authManager.addChild(displayName: displayName, pin: pin)
                dismiss()
            } catch {
                self.error = "Could not add child. Please try again."
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        AddChildView()
            .environmentObject(AuthManager.preview)
    }
}
```
```

---

## Phase 6 Summary

After completing Phase 6, you will have:

1. **Auth Types** - User, Family, Child, Session types
2. **Local Storage** - Guest mode and offline data storage
3. **Supabase Config** - Client configuration
4. **Auth Service** - Authentication operations
5. **Auth Manager** - Main ObservableObject for auth state
6. **Login View** - Login/signup/guest choice screen
7. **Family Select** - Family member selection
8. **PIN Entry** - Child authentication modal
9. **Add Child** - Screen to add new children

**Next Phase:** Phase 7 will implement parent features (dashboard, child stats, activity history).
