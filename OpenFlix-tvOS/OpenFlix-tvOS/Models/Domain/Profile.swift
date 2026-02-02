import Foundation

// MARK: - Profile

struct Profile: Identifiable, Hashable {
    let id: Int
    let uuid: String
    let name: String
    let avatar: String?
    let isKid: Bool
    let isProtected: Bool
    let isAdmin: Bool
    let isGuest: Bool
    let isRestricted: Bool

    // MARK: - Computed Properties

    var displayName: String {
        name
    }

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

// MARK: - DTO Mapping

extension ProfileDTO {
    func toDomain() -> Profile {
        Profile(
            id: id,
            uuid: uuid,
            name: name,
            avatar: avatar ?? thumb,
            isKid: isKid ?? false,
            isProtected: protected ?? hasPassword ?? false,
            isAdmin: admin ?? false,
            isGuest: guest ?? false,
            isRestricted: restricted ?? false
        )
    }
}

extension HomeUserDTO {
    func toDomain() -> Profile {
        Profile(
            id: 0, // Home users don't have numeric ID
            uuid: uuid,
            name: title,
            avatar: thumb,
            isKid: false,
            isProtected: protected ?? false,
            isAdmin: admin ?? false,
            isGuest: guest ?? false,
            isRestricted: restricted ?? false
        )
    }
}

// MARK: - User

struct User: Identifiable {
    let id: Int
    let uuid: String?
    let username: String
    let email: String?
    let displayName: String?
    let avatar: String?
    let isAdmin: Bool

    var name: String {
        displayName ?? username
    }
}

extension UserDTO {
    func toDomain() -> User {
        User(
            id: id,
            uuid: uuid,
            username: username,
            email: email,
            displayName: title,
            avatar: thumb,
            isAdmin: admin ?? false
        )
    }
}
