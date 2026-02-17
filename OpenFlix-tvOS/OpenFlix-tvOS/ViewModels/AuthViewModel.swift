import Foundation
import SwiftUI
import Network

@MainActor
class AuthViewModel: ObservableObject {
    private let authRepository = AuthRepository()

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentUser: User?
    @Published var currentProfile: Profile?
    @Published var profiles: [Profile] = []

    // Server discovery
    @Published var discoveredServers: [DiscoveredServer] = []
    @Published var isDiscovering = false
    @Published var autoConnected = false
    @Published var isLocalAccessMode = false

    // Known addresses to probe (matching Android)
    private let probeAddresses = [
        "192.168.1.185",   // OpenFlix server (primary - Unraid)
        "192.168.1.180",   // OpenFlix server (fallback)
        "192.168.1.100",   // Common server address
        "192.168.1.1",     // Common router/server
    ]
    private let defaultPort = 32400
    private let httpTimeout: TimeInterval = 2.0

    // MARK: - Initialization

    func initialize() async {
        // Try to auto-discover and connect on startup
        await discoverAndAutoConnect()
    }

    // MARK: - Auto Discovery & Connect

    func discoverAndAutoConnect() async {
        isDiscovering = true
        defer { isDiscovering = false }

        // Discover servers on local network
        let servers = await discoverServers()
        discoveredServers = servers

        if let server = servers.first {
            // Auto-connect to first discovered server (we're on local network)
            await autoConnectToServer(server)
        }
    }

    private func autoConnectToServer(_ server: DiscoveredServer) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Configure API with discovered server
            await OpenFlixAPI.shared.configure(serverURL: server.url, token: nil)
            UserDefaults.standard.serverURL = server.url

            // Enable local access mode - no login required
            isLocalAccessMode = true
            autoConnected = true
            isAuthenticated = true

            // Load profiles directly (no login needed on local network)
            try await loadProfiles()

            print("Auto-connected to local server: \(server.name) at \(server.url)")
        } catch {
            print("Failed to auto-connect: \(error)")
            // Fall back to manual login
            isLocalAccessMode = false
            autoConnected = false
        }
    }

    // MARK: - Server Discovery

    func discoverServers() async -> [DiscoveredServer] {
        var servers: [DiscoveredServer] = []

        // Probe known addresses via HTTP
        await withTaskGroup(of: DiscoveredServer?.self) { group in
            for address in probeAddresses {
                group.addTask {
                    await self.probeServer(host: address, port: self.defaultPort)
                }
            }

            for await server in group {
                if let server = server {
                    servers.append(server)
                }
            }
        }

        return servers
    }

    private func probeServer(host: String, port: Int) async -> DiscoveredServer? {
        guard let url = URL(string: "http://\(host):\(port)/identity") else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = httpTimeout

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            // Parse identity response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let container = json["MediaContainer"] as? [String: Any] ?? json

                let name = container["friendlyName"] as? String
                    ?? container["name"] as? String
                    ?? "OpenFlix Server"
                let version = container["version"] as? String ?? "unknown"
                let machineId = container["machineIdentifier"] as? String ?? host

                return DiscoveredServer(
                    name: name,
                    version: version,
                    machineId: machineId,
                    host: host,
                    port: port
                )
            }

            // If we got 200 but couldn't parse, still return a basic server
            return DiscoveredServer(
                name: "OpenFlix Server",
                version: "unknown",
                machineId: host,
                host: host,
                port: port
            )
        } catch {
            return nil
        }
    }

    // MARK: - Auth State

    func checkAuthStatus() async {
        isLoading = true
        defer { isLoading = false }

        // If we're in local access mode, we're authenticated
        if isLocalAccessMode {
            isAuthenticated = true
            try? await loadProfiles()
            return
        }

        let hasValidToken = await authRepository.checkAuthStatus()
        isAuthenticated = hasValidToken

        if isAuthenticated {
            currentUser = authRepository.currentUser
            try? await loadProfiles()
        }
    }

    // MARK: - Login (for remote access)

    func login(serverURL: URL, username: String, password: String, rememberMe: Bool) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Configure API with server URL
            await OpenFlixAPI.shared.configure(serverURL: serverURL, token: nil)

            // Save server URL
            UserDefaults.standard.serverURL = serverURL
            if rememberMe {
                UserDefaults.standard.lastUsername = username
                UserDefaults.standard.rememberMe = true
            }

            // Perform login
            let user = try await authRepository.login(username: username, password: password)
            currentUser = user
            isAuthenticated = true
            isLocalAccessMode = false

            // Load profiles
            try await loadProfiles()

        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Register

    func register(serverURL: URL, name: String, email: String, password: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            await OpenFlixAPI.shared.configure(serverURL: serverURL, token: nil)
            UserDefaults.standard.serverURL = serverURL

            let user = try await authRepository.register(name: name, email: email, password: password)
            currentUser = user
            isAuthenticated = true

            try await loadProfiles()

        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Logout

    func logout() async {
        await authRepository.logout()
        isAuthenticated = false
        isLocalAccessMode = false
        autoConnected = false
        currentUser = nil
        currentProfile = nil
        profiles = []
    }

    // MARK: - Profiles

    func loadProfiles() async throws {
        try await authRepository.loadProfiles()
        profiles = authRepository.profiles
        currentProfile = authRepository.currentProfile
    }

    func selectProfile(_ profile: Profile, pin: String? = nil) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await authRepository.switchProfile(profile, pin: pin)
            currentProfile = profile
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearProfile() {
        currentProfile = nil
        UserDefaults.standard.currentProfileUUID = nil
    }

    // MARK: - Manual Server Selection

    func selectServer(_ server: DiscoveredServer) async {
        await autoConnectToServer(server)
    }
}

// MARK: - Discovered Server Model

struct DiscoveredServer: Identifiable {
    let name: String
    let version: String
    let machineId: String
    let host: String
    let port: Int

    var id: String { machineId }

    var url: URL {
        URL(string: "http://\(host):\(port)")!
    }
}
