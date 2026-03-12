import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    private let sourceRepository = SourceRepository()

    // Server
    @Published var serverInfo: ServerInfo?
    @Published var capabilities: ServerCapabilities?

    // Sources
    @Published var m3uSources: [M3USource] = []
    @Published var xtreamSources: [XtreamSource] = []
    @Published var epgSources: [EPGSource] = []

    // Settings (using AppStorage for persistence)
    @AppStorage("auto_play_next") var autoPlayNext = true
    @AppStorage("skip_intros") var skipIntros = false
    @AppStorage("skip_credits") var skipCredits = false
    @AppStorage("show_subtitles") var showSubtitles = false
    @AppStorage("commercial_skip_enabled") var commercialSkipEnabled = true
    @AppStorage("onnx_detection_enabled") var onnxDetectionEnabled = false
    @AppStorage("acoustid_enabled") var acoustidEnabled = false
    @AppStorage("channel_surfing_enabled") var channelSurfingEnabled = true
    @AppStorage("epg_days_to_load") var epgDaysToLoad = 3
    @AppStorage("screensaver_enabled") var screensaverEnabled = true
    @AppStorage("screensaver_delay") var screensaverDelay = 300

    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Load Server Info

    func loadServerInfo() async {
        do {
            let info: ServerInfoDTO = try await OpenFlixAPI.shared.request(.getServerInfo)
            serverInfo = info.toDomain()

            let caps: ServerCapabilitiesDTO = try await OpenFlixAPI.shared.request(.getCapabilities)
            capabilities = caps.toDomain()
        } catch {
            // Silently fail
        }
    }

    // MARK: - Load Sources

    func loadSources() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await sourceRepository.loadAllSources()
            m3uSources = sourceRepository.m3uSources
            xtreamSources = sourceRepository.xtreamSources
            epgSources = sourceRepository.epgSources
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - M3U Sources

    func addM3USource(name: String, url: String, epgUrl: String?) async throws {
        try await sourceRepository.addM3USource(name: name, url: url, epgUrl: epgUrl)
        m3uSources = sourceRepository.m3uSources
    }

    func deleteM3USource(_ source: M3USource) async throws {
        try await sourceRepository.deleteM3USource(id: source.id)
        m3uSources = sourceRepository.m3uSources
    }

    func refreshM3USource(_ source: M3USource) async throws {
        try await sourceRepository.refreshM3USource(id: source.id)
        m3uSources = sourceRepository.m3uSources
    }

    // MARK: - Xtream Sources

    func addXtreamSource(name: String, serverUrl: String, username: String, password: String) async throws {
        try await sourceRepository.addXtreamSource(
            name: name,
            serverUrl: serverUrl,
            username: username,
            password: password
        )
        xtreamSources = sourceRepository.xtreamSources
    }

    func deleteXtreamSource(_ source: XtreamSource) async throws {
        try await sourceRepository.deleteXtreamSource(id: source.id)
        xtreamSources = sourceRepository.xtreamSources
    }

    func testXtreamSource(_ source: XtreamSource) async -> Bool {
        do {
            return try await sourceRepository.testXtreamSource(id: source.id)
        } catch {
            return false
        }
    }

    func refreshXtreamSource(_ source: XtreamSource) async throws {
        try await sourceRepository.refreshXtreamSource(id: source.id)
        xtreamSources = sourceRepository.xtreamSources
    }

    // MARK: - M3U Source Updates

    func updateM3USource(id: Int, name: String?, url: String?, epgUrl: String?, enabled: Bool?) async throws {
        try await OpenFlixAPI.shared.requestVoid(
            .updateM3USource(id: String(id), name: name, url: url, epgUrl: epgUrl, enabled: enabled)
        )
        try await sourceRepository.loadM3USources()
        m3uSources = sourceRepository.m3uSources
    }

    func importM3UVOD(sourceId: Int, libraryId: String) async throws {
        try await OpenFlixAPI.shared.requestVoid(
            .importVOD(sourceId: String(sourceId), libraryId: libraryId)
        )
    }

    func importM3USeries(sourceId: Int, libraryId: String) async throws {
        try await OpenFlixAPI.shared.requestVoid(
            .importSeries(sourceId: String(sourceId), libraryId: libraryId)
        )
    }

    // MARK: - Xtream Source Updates

    func updateXtreamSource(id: Int, name: String?, enabled: Bool?, importLive: Bool?, importVod: Bool?, importSeries: Bool?) async throws {
        try await OpenFlixAPI.shared.requestVoid(
            .updateXtreamSource(id: String(id), name: name, enabled: enabled, importLive: importLive, importVod: importVod, importSeries: importSeries)
        )
        try await sourceRepository.loadXtreamSources()
        xtreamSources = sourceRepository.xtreamSources
    }

    func importXtreamVOD(sourceId: Int) async throws {
        try await OpenFlixAPI.shared.requestVoid(
            .importXtreamVOD(sourceId: String(sourceId))
        )
    }

    func importXtreamSeries(sourceId: Int) async throws {
        try await OpenFlixAPI.shared.requestVoid(
            .importXtreamSeries(sourceId: String(sourceId))
        )
    }

    // MARK: - EPG Sources

    func addEPGSource(name: String, url: String?, type: String, tvguideProviderId: String? = nil, tvguideZipCode: String? = nil, tvguideDays: Int? = nil) async throws {
        try await sourceRepository.addEPGSource(name: name, url: url, type: type, tvguideProviderId: tvguideProviderId, tvguideZipCode: tvguideZipCode, tvguideDays: tvguideDays)
        epgSources = sourceRepository.epgSources
    }

    func discoverTVGuideProviders(zip: String) async throws -> TVGuideProvidersResponse {
        return try await sourceRepository.discoverTVGuideProviders(zip: zip)
    }

    func deleteEPGSource(_ source: EPGSource) async throws {
        try await sourceRepository.deleteEPGSource(id: source.id)
        epgSources = sourceRepository.epgSources
    }

    func refreshEPGSource(_ source: EPGSource) async throws {
        try await sourceRepository.refreshEPGSource(id: source.id)
        epgSources = sourceRepository.epgSources
    }

    // MARK: - Libraries

    @Published var libraries: [LibraryPickerItem] = []

    struct LibraryPickerItem: Identifiable, Hashable {
        let id: String
        let name: String
        let type: String
    }

    func loadLibraries() async {
        do {
            let response: LibrarySectionsResponse = try await OpenFlixAPI.shared.request(.getLibrarySections)
            let sections = response.MediaContainer?.allDirectories ?? []
            libraries = sections.map {
                LibraryPickerItem(id: $0.key, name: $0.title, type: $0.type)
            }
        } catch {
            // Silently fail
        }
    }

    // MARK: - Computed

    var totalChannelCount: Int {
        sourceRepository.totalChannelCount
    }

    var hasLiveTV: Bool {
        capabilities?.liveTV ?? false
    }

    var hasDVR: Bool {
        capabilities?.dvr ?? false
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Invite

    @Published var inviteToken: String?
    @Published var inviteDeepLink: String?
    @Published var inviteExpiresAt: Date?
    @Published var isGeneratingInvite = false

    func generateInvite() async {
        isGeneratingInvite = true
        defer { isGeneratingInvite = false }

        struct InviteResponse: Decodable {
            let token: String
            let deepLink: String
            let expiresAt: Date
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let data = try await OpenFlixAPI.shared.requestData(.createInvite)
            let resp = try decoder.decode(InviteResponse.self, from: data)
            inviteToken = resp.token
            inviteDeepLink = resp.deepLink
            inviteExpiresAt = resp.expiresAt
        } catch {}
    }

    // MARK: - Away from Home / Claim Token

    @Published var claimToken: String?
    @Published var claimTokenExpiresIn: Double?
    @Published var claimTokenActive = false
    @Published var isGeneratingToken = false

    func loadClaimToken() async {
        struct ClaimResponse: Decodable {
            let token: String?
            let active: Bool
            let expiresIn: Double?
        }
        do {
            let resp: ClaimResponse = try await OpenFlixAPI.shared.request(.getClaimToken)
            claimToken = resp.active ? resp.token : nil
            claimTokenActive = resp.active
            claimTokenExpiresIn = resp.expiresIn
        } catch {
            claimToken = nil
            claimTokenActive = false
        }
    }

    func generateNewClaimToken() async {
        isGeneratingToken = true
        defer { isGeneratingToken = false }
        struct ClaimResponse: Decodable {
            let token: String
        }
        do {
            let resp: ClaimResponse = try await OpenFlixAPI.shared.request(.generateClaimToken)
            claimToken = resp.token
            claimTokenActive = true
            claimTokenExpiresIn = 600
        } catch {}
    }
}
