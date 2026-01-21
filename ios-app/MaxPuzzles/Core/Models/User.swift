import Foundation

/// Represents a user in the Maxi's Mighty Mindgames system
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var displayName: String
    var role: UserRole
    var coins: Int
    var isGuest: Bool
    var avatarConfig: AvatarConfig?

    init(
        id: UUID = UUID(),
        displayName: String,
        role: UserRole = .child,
        coins: Int = 0,
        isGuest: Bool = true,
        avatarConfig: AvatarConfig? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.role = role
        self.coins = coins
        self.isGuest = isGuest
        self.avatarConfig = avatarConfig
    }

    /// Create a guest user
    static func guest() -> User {
        User(
            displayName: "Guest",
            role: .child,
            coins: 0,
            isGuest: true
        )
    }
}

/// User role in the family
enum UserRole: String, Codable {
    case parent
    case child
}

/// Avatar configuration (V3 stub)
struct AvatarConfig: Codable, Equatable {
    var skinColor: String?
    var hairStyle: String?
    var hairColor: String?
    var accessories: [String]

    init(
        skinColor: String? = nil,
        hairStyle: String? = nil,
        hairColor: String? = nil,
        accessories: [String] = []
    ) {
        self.skinColor = skinColor
        self.hairStyle = hairStyle
        self.hairColor = hairColor
        self.accessories = accessories
    }
}
