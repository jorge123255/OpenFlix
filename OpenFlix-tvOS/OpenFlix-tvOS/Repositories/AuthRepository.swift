import Foundation

@MainActor
class AuthRepository: ObservableObject {
    private let api = OpenFlixAPI.shared
    private let keychain = KeychainHelper.shared

    @Published var currentUser: User?
    @Published var currentProfile: Profile?
    @Published var profiles: [Profile] = []

    // MARK: - Authentication

    func login(username: String, password: String) async throws -> User {
        let response = try await api.login(username: username, password: password)

        // Save token
        keychain.saveToken(response.token)
        await api.setToken(response.token)

        let user = response.user.toDomain()
        currentUser = user
        return user
    }

    func register(name: String, email: String, password: String) async throws -> User {
        let response = try await api.register(name: name, email: email, password: password)

        // Save token
        keychain.saveToken(response.token)
        await api.setToken(response.token)

        let user = response.user.toDomain()
        currentUser = user
        return user
    }

    func logout() async {
        try? await api.logout()
        keychain.deleteToken()
        await api.setToken(nil)
        currentUser = nil
        currentProfile = nil
        profiles = []
        UserDefaults.standard.currentProfileUUID = nil
    }

    func checkAuthStatus() async -> Bool {
        guard keychain.getToken() != nil else { return false }

        do {
            let user = try await api.getUser()
            currentUser = user.toDomain()
            return true
        } catch {
            // Token invalid, clear it
            keychain.deleteToken()
            await api.setToken(nil)
            return false
        }
    }

    // MARK: - Profiles

    func loadProfiles() async throws {
        let response = try await api.getHomeUsers()
        profiles = response.users.map { $0.toDomain() }

        // Try to restore last selected profile
        if let savedUUID = UserDefaults.standard.currentProfileUUID,
           let profile = profiles.first(where: { $0.uuid == savedUUID }) {
            currentProfile = profile
        }
    }

    func switchProfile(_ profile: Profile, pin: String? = nil) async throws {
        let response = try await api.switchProfile(uuid: profile.uuid, pin: pin)

        // Update token if provided (Android uses authToken, check both)
        if let newToken = response.authToken ?? response.token {
            keychain.saveToken(newToken)
            await api.setToken(newToken)
        }

        currentProfile = profile
        UserDefaults.standard.currentProfileUUID = profile.uuid
    }

    func createProfile(name: String, isKid: Bool, pin: String?) async throws {
        // Note: This requires admin permissions
        // Implementation depends on profile creation endpoint response
    }
}
