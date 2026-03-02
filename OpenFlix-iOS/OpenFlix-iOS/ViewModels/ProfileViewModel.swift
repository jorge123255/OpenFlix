import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    private let profileRepository = ProfileRepository()

    @Published var profiles: [Profile] = []
    @Published var currentProfile: Profile?
    @Published var isLoading = false
    @Published var error: String?
    @Published var showPinEntry = false
    @Published var pendingProfile: Profile?

    // MARK: - Load

    func loadProfiles() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await profileRepository.loadProfiles()
            profiles = profileRepository.profiles
            currentProfile = profileRepository.currentProfile
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Profile Selection

    func selectProfile(_ profile: Profile) {
        if profile.isProtected {
            pendingProfile = profile
            showPinEntry = true
        } else {
            Task {
                await switchToProfile(profile, pin: nil)
            }
        }
    }

    func submitPin(_ pin: String) async {
        guard let profile = pendingProfile else { return }
        await switchToProfile(profile, pin: pin)
        showPinEntry = false
        pendingProfile = nil
    }

    func cancelPinEntry() {
        showPinEntry = false
        pendingProfile = nil
    }

    private func switchToProfile(_ profile: Profile, pin: String?) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await profileRepository.switchProfile(profile, pin: pin)
            currentProfile = profile
        } catch let networkError as NetworkError {
            if case .unauthorized = networkError {
                error = "Incorrect PIN"
            } else {
                error = networkError.errorDescription
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Profile Management

    func createProfile(name: String, isKid: Bool, pin: String?) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await profileRepository.createProfile(name: name, isKid: isKid, pin: pin)
            profiles = profileRepository.profiles
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateProfile(_ profile: Profile, name: String?, isKid: Bool?, pin: String?) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await profileRepository.updateProfile(id: profile.id, name: name, isKid: isKid, pin: pin)
            profiles = profileRepository.profiles
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteProfile(_ profile: Profile) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await profileRepository.deleteProfile(id: profile.id)
            profiles = profileRepository.profiles

            if currentProfile?.id == profile.id {
                currentProfile = nil
            }
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Computed

    var hasMultipleProfiles: Bool {
        profiles.count > 1
    }

    var canAddProfile: Bool {
        // Limit to reasonable number of profiles
        profiles.count < 10
    }
}
