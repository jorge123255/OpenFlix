import Foundation

// MARK: - Auth Response

struct AuthResponse: Codable {
    let token: String
    let user: UserDTO
    let expiresAt: Int?
}

struct UserDTO: Codable {
    let id: Int
    let uuid: String?
    let username: String
    let email: String?
    let title: String?
    let thumb: String?
    let admin: Bool?
    let createdAt: String?
    let updatedAt: String?
}

// MARK: - Profile DTOs

struct ProfileDTO: Codable {
    let id: Int
    let uuid: String
    let name: String
    let avatar: String?
    let thumb: String?
    let isKid: Bool?
    let hasPassword: Bool?
    let restricted: Bool?
    let admin: Bool?
    let guest: Bool?
    let protected: Bool?
}

struct HomeUsersResponse: Codable {
    let id: Int?
    let name: String?
    let users: [HomeUserDTO]
}

struct HomeUserDTO: Codable {
    let id: Int?
    let uuid: String
    let title: String
    let username: String?
    let thumb: String?
    let hasPassword: Bool?
    let restricted: Bool?
    let admin: Bool?
    let guest: Bool?
    let protected: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case title
        case username
        case thumb
        case hasPassword
        case restricted
        case admin
        case guest
        case protected
    }
}

struct SwitchProfileResponse: Codable {
    let authToken: String?
    let token: String?
    let success: Bool?
    let message: String?
}

// MARK: - Server Info

struct ServerInfoDTO: Codable {
    let name: String?
    let version: String?
    let platform: String?
    let machineIdentifier: String?
    let owner: Bool?
    let transcoderActive: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case version
        case platform
        case machineIdentifier
        case owner
        case transcoderActive = "transcoder_active"
    }
}

struct ServerCapabilitiesDTO: Codable {
    let liveTV: Bool?
    let dvr: Bool?
    let transcoding: Bool?
    let offlineDownloads: Bool?
    let multiUser: Bool?
    let watchParty: Bool?
    let epgSources: [String]?

    enum CodingKeys: String, CodingKey {
        case liveTV = "live_tv"
        case dvr
        case transcoding
        case offlineDownloads = "offline_downloads"
        case multiUser = "multi_user"
        case watchParty = "watch_party"
        case epgSources = "epg_sources"
    }
}
