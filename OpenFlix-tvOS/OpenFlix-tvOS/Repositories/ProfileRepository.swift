import Foundation

@MainActor
class ProfileRepository: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published var profiles: [Profile] = []
    @Published var currentProfile: Profile?

    // MARK: - Load

    func loadProfiles() async throws {
        let response = try await api.getHomeUsers()
        profiles = response.users.map { $0.toDomain() }

        // Restore current profile
        if let savedUUID = UserDefaults.standard.currentProfileUUID,
           let profile = profiles.first(where: { $0.uuid == savedUUID }) {
            currentProfile = profile
        }
    }

    // MARK: - Switch Profile

    func switchProfile(_ profile: Profile, pin: String? = nil) async throws {
        let response = try await api.switchProfile(uuid: profile.uuid, pin: pin)

        // Update token if provided
        if let newToken = response.token {
            KeychainHelper.shared.saveToken(newToken)
            await api.setToken(newToken)
        }

        currentProfile = profile
        UserDefaults.standard.currentProfileUUID = profile.uuid
    }

    // MARK: - Profile Management

    func createProfile(name: String, isKid: Bool, pin: String?) async throws {
        let _: ProfileDTO = try await api.request(.createProfile(name: name, isKid: isKid, pin: pin))
        try await loadProfiles()
    }

    func updateProfile(id: Int, name: String?, isKid: Bool?, pin: String?) async throws {
        try await api.requestVoid(.updateProfile(id: id, name: name, isKid: isKid, pin: pin))
        try await loadProfiles()
    }

    func deleteProfile(id: Int) async throws {
        try await api.requestVoid(.deleteProfile(id: id))
        profiles.removeAll { $0.id == id }

        // If deleted current profile, clear it
        if currentProfile?.id == id {
            currentProfile = nil
            UserDefaults.standard.currentProfileUUID = nil
        }
    }

    // MARK: - Computed

    func profile(for uuid: String) -> Profile? {
        profiles.first { $0.uuid == uuid }
    }

    var kidProfiles: [Profile] {
        profiles.filter { $0.isKid }
    }

    var protectedProfiles: [Profile] {
        profiles.filter { $0.isProtected }
    }
}
