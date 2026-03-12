import Foundation

@MainActor
class SourceRepository: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published var m3uSources: [M3USource] = []
    @Published var xtreamSources: [XtreamSource] = []
    @Published var epgSources: [EPGSource] = []

    // MARK: - M3U Sources

    func loadM3USources() async throws {
        let response = try await api.getM3USources()
        m3uSources = response.sources.map { $0.toDomain() }
    }

    func addM3USource(name: String, url: String, epgUrl: String?) async throws {
        let dto = try await api.addM3USource(name: name, url: url, epgUrl: epgUrl)
        m3uSources.append(dto.toDomain())
    }

    func deleteM3USource(id: Int) async throws {
        try await api.deleteM3USource(id: String(id))
        m3uSources.removeAll { $0.id == id }
    }

    func refreshM3USource(id: Int) async throws {
        try await api.refreshM3USource(id: String(id))
        try await loadM3USources()
    }

    // MARK: - Xtream Sources

    func loadXtreamSources() async throws {
        let response = try await api.getXtreamSources()
        xtreamSources = response.sources.map { $0.toDomain() }
    }

    func addXtreamSource(name: String, serverUrl: String, username: String, password: String) async throws {
        let dto = try await api.addXtreamSource(
            name: name,
            serverUrl: serverUrl,
            username: username,
            password: password
        )
        xtreamSources.append(dto.toDomain())
    }

    func deleteXtreamSource(id: Int) async throws {
        try await api.deleteXtreamSource(id: String(id))
        xtreamSources.removeAll { $0.id == id }
    }

    func testXtreamSource(id: Int) async throws -> Bool {
        do {
            try await api.requestVoid(.testXtreamSource(id: String(id)))
            return true
        } catch {
            return false
        }
    }

    func refreshXtreamSource(id: Int) async throws {
        try await api.requestVoid(.refreshXtreamSource(id: String(id)))
        try await loadXtreamSources()
    }

    // MARK: - EPG Sources

    func loadEPGSources() async throws {
        let response: EPGSourcesResponse = try await api.request(.getEPGSources)
        epgSources = response.sources.map { $0.toDomain() }
    }

    func addEPGSource(name: String, url: String?, type: String, tvguideProviderId: String? = nil, tvguideZipCode: String? = nil, tvguideDays: Int? = nil) async throws {
        let _: EPGSourceDTO = try await api.request(.addEPGSource(name: name, url: url, type: type, tvguideProviderId: tvguideProviderId, tvguideZipCode: tvguideZipCode, tvguideDays: tvguideDays))
        try await loadEPGSources()
    }

    func discoverTVGuideProviders(zip: String) async throws -> TVGuideProvidersResponse {
        return try await api.request(.discoverTVGuideProviders(zip: zip))
    }

    func deleteEPGSource(id: Int) async throws {
        try await api.requestVoid(.deleteEPGSource(id: String(id)))
        epgSources.removeAll { $0.id == id }
    }

    func refreshEPGSource(id: Int) async throws {
        try await api.requestVoid(.refreshEPGSource(id: String(id)))
        try await loadEPGSources()
    }

    // MARK: - Load All

    func loadAllSources() async throws {
        async let m3u: () = loadM3USources()
        async let xtream: () = loadXtreamSources()
        async let epg: () = loadEPGSources()

        _ = try await (m3u, xtream, epg)
    }

    // MARK: - Computed

    var totalChannelCount: Int {
        m3uSources.reduce(0) { $0 + $1.channelCount } +
        xtreamSources.reduce(0) { $0 + $1.channelCount }
    }

    var enabledM3USources: [M3USource] {
        m3uSources.filter { $0.enabled }
    }

    var enabledXtreamSources: [XtreamSource] {
        xtreamSources.filter { $0.enabled }
    }

    var enabledEPGSources: [EPGSource] {
        epgSources.filter { $0.enabled }
    }
}
