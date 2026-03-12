import Foundation

struct SavedServer: Codable, Identifiable, Equatable {
    let machineId: String
    var name: String
    var localURLs: [String]
    var remoteURL: String?
    var tailscaleURL: String?
    var lastConnectedURL: String?
    var connectionType: ConnectionType

    var id: String { machineId }
}

@MainActor
final class ServerConnectionManager: ObservableObject {
    static let shared = ServerConnectionManager()

    @Published private(set) var currentServer: SavedServer?

    private let userDefaults: UserDefaults
    private let savedServersKey = "saved_servers"
    private var savedServers: [SavedServer]

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.savedServers = ServerConnectionManager.loadSavedServers(from: userDefaults)
        if let machineId = userDefaults.lastMachineId ?? KeychainHelper.shared.getMachineId() {
            self.currentServer = savedServers.first { $0.machineId == machineId }
        }
    }

    // MARK: - Public API

    func server(for machineId: String) -> SavedServer? {
        savedServers.first { $0.machineId == machineId }
    }

    func saveServer(_ server: SavedServer, setCurrent: Bool = true) {
        let merged = upsertServer(server)
        if setCurrent {
            currentServer = merged
        }
    }

    func saveDiscoveredServer(_ server: DiscoveredServer, isRemote: Bool) {
        let urlString = server.url.absoluteString
        let saved = SavedServer(
            machineId: server.machineId,
            name: server.name,
            localURLs: isRemote ? [] : [urlString],
            remoteURL: isRemote ? urlString : nil,
            tailscaleURL: nil,
            lastConnectedURL: nil,
            connectionType: .unknown
        )
        saveServer(saved)
    }

    func connect(to server: SavedServer) async -> URL? {
        if let localURL = await firstReachableURL(from: server.localURLs, timeout: 2) {
            return await finalizeConnection(for: server, url: localURL, type: .local)
        }

        if let tailscale = server.tailscaleURL,
           let tailscaleURL = normalizedURL(from: tailscale, defaultPort: serverURLPort(from: server)) {
            if await canConnect(to: tailscaleURL, timeout: 5) {
                return await finalizeConnection(for: server, url: tailscaleURL, type: .remote)
            }
        }

        if let remote = server.remoteURL,
           let remoteURL = normalizedURL(from: remote, defaultPort: serverURLPort(from: server)) {
            if await canConnect(to: remoteURL, timeout: 5) {
                return await finalizeConnection(for: server, url: remoteURL, type: .remote)
            }
        }

        return nil
    }

    func refreshConnectionInfo(baseURL: URL) async {
        do {
            await OpenFlixAPI.shared.configure(serverURL: baseURL, token: KeychainHelper.shared.getToken())
            let info = try await OpenFlixAPI.shared.getConnectionInfo()
            let machineId = currentServer?.machineId
                ?? userDefaults.lastMachineId
                ?? KeychainHelper.shared.getMachineId()

            guard let machineId else { return }

            var updated = currentServer ?? SavedServer(
                machineId: machineId,
                name: "OpenFlix Server",
                localURLs: [],
                remoteURL: nil,
                tailscaleURL: nil,
                lastConnectedURL: nil,
                connectionType: .unknown
            )

            if let localUrl = info.localUrl,
               let normalizedLocal = normalizedURL(from: localUrl, defaultPort: baseURL.port ?? 32400)?.absoluteString {
                updated.localURLs = mergeUniqueURLs(existing: updated.localURLs, incoming: [normalizedLocal])
            }

            if let remoteUrl = info.remoteUrl,
               let normalizedRemote = normalizedURL(from: remoteUrl, defaultPort: baseURL.port ?? 32400)?.absoluteString {
                updated.remoteURL = normalizedRemote
            }

            if let tailscaleIp = info.tailscaleIp,
               let normalizedTailscale = normalizedURL(from: tailscaleIp, defaultPort: baseURL.port ?? 32400)?.absoluteString {
                updated.tailscaleURL = normalizedTailscale
            }

            if let isRemote = info.isRemote {
                updated.connectionType = isRemote ? .remote : .local
            }

            saveServer(updated)
        } catch {
            print("CONNECTION: Failed to refresh connection info: \(error)")
        }
    }

    func autoReconnect() async -> URL? {
        if currentServer == nil {
            if let machineId = userDefaults.lastMachineId ?? KeychainHelper.shared.getMachineId() {
                currentServer = savedServers.first { $0.machineId == machineId }
            }
        }

        guard let server = currentServer else { return nil }
        return await connect(to: server)
    }

    // MARK: - Helpers

    private func upsertServer(_ server: SavedServer) -> SavedServer {
        if let index = savedServers.firstIndex(where: { $0.machineId == server.machineId }) {
            let merged = mergeServers(existing: savedServers[index], incoming: server)
            savedServers[index] = merged
            persistSavedServers()
            return merged
        } else {
            savedServers.append(server)
            persistSavedServers()
            return server
        }
    }

    private func mergeServers(existing: SavedServer, incoming: SavedServer) -> SavedServer {
        let mergedLocal = mergeUniqueURLs(existing: existing.localURLs, incoming: incoming.localURLs)
        let mergedName = incoming.name.isEmpty ? existing.name : incoming.name
        let mergedRemote = incoming.remoteURL ?? existing.remoteURL
        let mergedTailscale = incoming.tailscaleURL ?? existing.tailscaleURL
        let mergedLast = incoming.lastConnectedURL ?? existing.lastConnectedURL
        let mergedType: ConnectionType = incoming.connectionType == .unknown ? existing.connectionType : incoming.connectionType

        return SavedServer(
            machineId: existing.machineId,
            name: mergedName,
            localURLs: mergedLocal,
            remoteURL: mergedRemote,
            tailscaleURL: mergedTailscale,
            lastConnectedURL: mergedLast,
            connectionType: mergedType
        )
    }

    private func persistSavedServers() {
        do {
            let data = try JSONEncoder().encode(savedServers)
            userDefaults.set(data, forKey: savedServersKey)
        } catch {
            print("CONNECTION: Failed to persist saved servers: \(error)")
        }
    }

    private static func loadSavedServers(from userDefaults: UserDefaults) -> [SavedServer] {
        guard let data = userDefaults.data(forKey: "saved_servers") else { return [] }
        return (try? JSONDecoder().decode([SavedServer].self, from: data)) ?? []
    }

    private func firstReachableURL(from urlStrings: [String], timeout: TimeInterval) async -> URL? {
        let urls = urlStrings.compactMap { normalizedURL(from: $0, defaultPort: nil) }
        guard !urls.isEmpty else { return nil }

        return await withTaskGroup(of: URL?.self) { group in
            for url in urls {
                group.addTask { [timeout] in
                    let ok = await canConnect(to: url, timeout: timeout)
                    return ok ? url : nil
                }
            }

            for await result in group {
                if let url = result {
                    group.cancelAll()
                    return url
                }
            }

            return nil
        }
    }

    private func finalizeConnection(for server: SavedServer, url: URL, type: ConnectionType) async -> URL? {
        var updated = server
        updated.lastConnectedURL = url.absoluteString
        updated.connectionType = type
        saveServer(updated)
        return url
    }

    private func serverURLPort(from server: SavedServer) -> Int {
        if let last = server.lastConnectedURL, let url = URL(string: last), let port = url.port {
            return port
        }
        if let local = server.localURLs.first, let url = URL(string: local), let port = url.port {
            return port
        }
        if let remote = server.remoteURL, let url = URL(string: remote), let port = url.port {
            return port
        }
        return 32400
    }
}

private func mergeUniqueURLs(existing: [String], incoming: [String]) -> [String] {
    var seen = Set<String>()
    var merged: [String] = []

    for url in existing + incoming {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !seen.contains(trimmed) else { continue }
        seen.insert(trimmed)
        merged.append(trimmed)
    }

    return merged
}

private func normalizedURL(from raw: String, defaultPort: Int?) -> URL? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if let url = URL(string: trimmed), url.scheme != nil {
        return url
    }

    var hostPort = trimmed
    if let port = defaultPort, !hostPort.contains(":") {
        hostPort = "\(hostPort):\(port)"
    }

    return URL(string: "http://\(hostPort)")
}

private func canConnect(to url: URL, timeout: TimeInterval) async -> Bool {
    var request = URLRequest(url: url.appendingPathComponent("identity"))
    request.timeoutInterval = timeout

    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let container = json["MediaContainer"] as? [String: Any] ?? json
            if let machineId = container["machineIdentifier"] as? String, !machineId.isEmpty {
                return true
            }
        }
    } catch {
        return false
    }

    var statusRequest = URLRequest(url: url.appendingPathComponent("api/status"))
    statusRequest.timeoutInterval = timeout

    do {
        let (data, response) = try await URLSession.shared.data(for: statusRequest)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let server = json["server"] as? [String: Any],
           let machineId = server["machineIdentifier"] as? String, !machineId.isEmpty {
            return true
        }
    } catch {
        return false
    }

    return false
}
