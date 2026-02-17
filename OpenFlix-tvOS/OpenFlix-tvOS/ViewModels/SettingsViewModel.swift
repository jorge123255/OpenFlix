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

    // MARK: - EPG Sources

    func addEPGSource(name: String, url: String, type: String) async throws {
        try await sourceRepository.addEPGSource(name: name, url: url, type: type)
        epgSources = sourceRepository.epgSources
    }

    func deleteEPGSource(_ source: EPGSource) async throws {
        try await sourceRepository.deleteEPGSource(id: source.id)
        epgSources = sourceRepository.epgSources
    }

    func refreshEPGSource(_ source: EPGSource) async throws {
        try await sourceRepository.refreshEPGSource(id: source.id)
        epgSources = sourceRepository.epgSources
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
}
