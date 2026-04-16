import Foundation
import SwiftUI

// MARK: - Channel

struct Channel: Identifiable, Hashable {
    let id: String
    let channelId: String?       // EPG/guide channel ID (key in programs map)
    let number: Int?
    let name: String
    let logo: String?
    let sourceId: String?
    let sourceName: String?
    let sourceType: String?
    let providerId: String?
    let providerName: String?
    let accountId: String?
    let accountName: String?
    let accountIndex: Int?
    let streamUrl: String?
    let playUrl: String?
    let hlsUrl: String?
    let browserHlsUrl: String?
    let playable: Bool?
    let drm: Bool?
    let enabled: Bool
    let isFavorite: Bool
    let group: String?
    let archiveEnabled: Bool
    let archiveDays: Int
    var nowPlaying: Program?
    var nextProgram: Program?

    init(
        id: String,
        channelId: String?,
        number: Int?,
        name: String,
        logo: String?,
        sourceId: String?,
        sourceName: String?,
        sourceType: String?,
        providerId: String?,
        providerName: String?,
        accountId: String?,
        accountName: String?,
        accountIndex: Int?,
        streamUrl: String?,
        playUrl: String? = nil,
        hlsUrl: String? = nil,
        browserHlsUrl: String? = nil,
        playable: Bool?,
        drm: Bool?,
        enabled: Bool,
        isFavorite: Bool,
        group: String?,
        archiveEnabled: Bool,
        archiveDays: Int,
        nowPlaying: Program? = nil,
        nextProgram: Program? = nil
    ) {
        self.id = id
        self.channelId = channelId
        self.number = number
        self.name = name
        self.logo = logo
        self.sourceId = sourceId
        self.sourceName = sourceName
        self.sourceType = sourceType
        self.providerId = providerId
        self.providerName = providerName
        self.accountId = accountId
        self.accountName = accountName
        self.accountIndex = accountIndex
        self.streamUrl = streamUrl
        self.playUrl = playUrl
        self.hlsUrl = hlsUrl
        self.browserHlsUrl = browserHlsUrl
        self.playable = playable
        self.drm = drm
        self.enabled = enabled
        self.isFavorite = isFavorite
        self.group = group
        self.archiveEnabled = archiveEnabled
        self.archiveDays = archiveDays
        self.nowPlaying = nowPlaying
        self.nextProgram = nextProgram
    }

    // MARK: - Computed Properties

    var displayNumber: String {
        if let number = number {
            return "\(number)"
        }
        return ""
    }

    var displayName: String {
        if let number = number {
            return "\(number) - \(name)"
        }
        return name
    }

    var isHD: Bool {
        name.uppercased().contains("HD") ||
        name.uppercased().contains("FHD") ||
        name.uppercased().contains("4K") ||
        name.uppercased().contains("UHD")
    }

    var sortKey: Double {
        Double(number ?? Int.max)
    }

    private func resolvedURL(from value: String?) -> URL? {
        guard let value, !value.isEmpty else { return nil }
        // Absolute URLs go straight to URL(string:).
        if value.hasPrefix("http://") || value.hasPrefix("https://") {
            return URL(string: value)
        }
        // Anything else is treated as server-relative — server returns paths
        // both with leading slash ("/common,channel/...") and without
        // ("common,channel/..."). The latter previously fell through to
        // URL(string:) which fails on commas / unencoded chars.
        guard let serverURL = UserDefaults.standard.serverURL else { return nil }
        let normalizedPath = value.hasPrefix("/") ? value : "/\(value)"
        let encoded = normalizedPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? normalizedPath
        return URL(string: encoded, relativeTo: serverURL)?.absoluteURL
    }

    var resolvedPlayURL: URL? {
        resolvedURL(from: playUrl)
    }

    var resolvedHLSURL: URL? {
        resolvedURL(from: hlsUrl)
    }

    var resolvedBrowserHLSURL: URL? {
        resolvedURL(from: browserHlsUrl)
    }

    var resolvedFallbackStreamURL: URL? {
        resolvedURL(from: streamUrl)
    }

    var preferredPlaybackURL: URL? {
        resolvedPlayURL ?? resolvedHLSURL ?? resolvedFallbackStreamURL
    }

    var preferredPreviewURL: URL? {
        resolvedHLSURL ?? resolvedBrowserHLSURL ?? resolvedPlayURL ?? resolvedFallbackStreamURL
    }

    var preferredBrowserPlaybackURL: URL? {
        resolvedBrowserHLSURL ?? resolvedHLSURL ?? resolvedPlayURL ?? resolvedFallbackStreamURL
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Channel, rhs: Channel) -> Bool {
        lhs.id == rhs.id
    }
}

typealias LiveTVChannel = Channel
typealias GuideChannel = Channel

// MARK: - DTO Mapping

extension ChannelDTO {
    func toDomain() -> Channel {
        Channel(
            id: safeId,
            channelId: channelIdOrNil ?? tvgIdOrNil,
            number: number,
            name: safeName,
            logo: logo ?? thumb,
            sourceId: sourceId?.stringValue,
            sourceName: sourceName,
            sourceType: sourceType,
            providerId: providerId,
            providerName: providerName,
            accountId: accountId?.stringValue,
            accountName: accountName,
            accountIndex: accountIndex,
            streamUrl: streamUrl,
            playUrl: playUrl,
            hlsUrl: hlsUrl,
            browserHlsUrl: browserHlsUrl,
            playable: playable,
            drm: drm,
            enabled: enabled ?? true,
            isFavorite: isFavorite ?? false,
            group: group ?? category,
            archiveEnabled: archiveEnabled ?? false,
            archiveDays: archiveDays ?? 0,
            nowPlaying: nowPlaying?.toDomain(),
            nextProgram: nextProgram?.toDomain()
        )
    }
}

// MARK: - Channel Group

struct ChannelGroup: Identifiable {
    let id: Int
    let name: String
    let enabled: Bool
    let members: [ChannelGroupMember]
}

struct ChannelGroupMember: Identifiable {
    var id: String { channelId }
    let channelId: String
    let priority: Int
    let channelName: String?
}

extension ChannelGroupDTO {
    func toDomain() -> ChannelGroup {
        ChannelGroup(
            id: id,
            name: name,
            enabled: enabled ?? true,
            members: members?.map { ChannelGroupMember(channelId: $0.channelId, priority: $0.priority, channelName: $0.channelName) } ?? []
        )
    }
}

// MARK: - External Tuner Backend

struct TunerBackend: Codable, Identifiable {
    let id: String
    let name: String
    let host: String?
    let port: Int?
    let baseUrl: String?
    let version: String?
    let healthy: Bool
    let providers: [TunerBackendProvider]
}

struct TunerBackendProvider: Codable, Identifiable {
    let id: String
    let name: String
    let enabled: Bool?
    let loggedIn: Bool?
    let channelCount: Int?
    let accounts: [TunerBackendProviderAccount]?
}

enum UIMode: String, Codable {
    case backendDVR = "backend-dvr"
    case receiver = "receiver"
    case none = "none"
}

struct TunerBackendProviderAccount: Codable, Identifiable {
    var id: String { accountId }

    let accountId: String
    let accountName: String?
    let accountIndex: Int?
    let accountType: String?
    let recordingMode: String?
    let uiMode: UIMode?
    let serviceType: String?
    let cloudDvrCapable: Bool?
    let receiverDvrCapable: Bool?
    let capabilitySource: String?
    let dvrState: String?
    let cdvrEligibleReceiverID: String?
    let customerType: String?
    let serviceDomain: String?
    let profileId: String?
    let authGroups: String?
    let packageInfo: String?
    let packageIds: [String]?
    let shortPackageIds: [String]?
    let capabilities: ProviderCapabilities?

    /// Resolved uiMode: prefers the server-provided value, falls back to
    /// deriving it from the legacy `recordingMode` / `serviceType` fields.
    var resolvedUIMode: UIMode {
        if let uiMode { return uiMode }
        // Fallback: derive from legacy heuristics
        if recordingMode == "cloud", serviceType == "stream" { return .backendDVR }
        if recordingMode == "receiver" || serviceType == "satellite" { return .receiver }
        if recordingMode == "none" { return .none }
        // Default: if there's an account at all, assume local DVR is available
        return .receiver
    }
}

struct ProviderCapabilities: Codable {
    let canRecord: Bool?
    let canSeriesRecord: Bool?
    let canDownload: Bool?
    let canCancel: Bool?
    let canDelete: Bool?
    let canManageSeries: Bool?
}

struct NowPlayingItem: Identifiable, Hashable {
    var id: String { channelId }

    let channelId: String
    let channelName: String
    let channelLogo: String?
    let program: Program?
}

@MainActor
final class TunerBackendStore: ObservableObject {
    static let shared = TunerBackendStore()

    @Published private(set) var activeBackend: TunerBackend?
    @Published private(set) var isLoading = false

    private let api = OpenFlixAPI.shared
    private var lastLoadedAt: Date?

    private init() {}

    func load(force: Bool = false) async throws {
        if !force,
           let lastLoadedAt,
           Date().timeIntervalSince(lastLoadedAt) < 60,
           activeBackend != nil {
            return
        }

        isLoading = true
        defer { isLoading = false }

        activeBackend = try await api.getActiveTunerBackend()
        lastLoadedAt = Date()
    }

    func providerAccount(for channel: Channel) -> TunerBackendProviderAccount? {
        guard let backend = activeBackend else { return nil }

        return backend.providers
            .filter { provider in
                if let providerId = channel.providerId {
                    return provider.id.caseInsensitiveCompare(providerId) == .orderedSame
                }
                if let providerName = channel.providerName {
                    return provider.name.caseInsensitiveCompare(providerName) == .orderedSame
                }
                return false
            }
            .flatMap { $0.accounts ?? [] }
            .first { account in
                if let accountId = channel.accountId, account.accountId == accountId {
                    return true
                }
                if let accountIndex = channel.accountIndex, account.accountIndex == accountIndex {
                    return true
                }
                if let accountName = channel.accountName, account.accountName == accountName {
                    return true
                }
                return false
            }
    }

    func providerAccount(for recording: Recording) -> TunerBackendProviderAccount? {
        guard let backend = activeBackend else { return nil }

        return backend.providers
            .filter { provider in
                if let providerId = recording.providerId {
                    return provider.id.caseInsensitiveCompare(providerId) == .orderedSame
                }
                if let providerName = recording.providerName {
                    return provider.name.caseInsensitiveCompare(providerName) == .orderedSame
                }
                return false
            }
            .flatMap { $0.accounts ?? [] }
            .first { account in
                if let accountId = recording.accountId, account.accountId == accountId {
                    return true
                }
                if let accountIndex = recording.accountIndex, account.accountIndex == accountIndex {
                    return true
                }
                if let accountName = recording.accountName, account.accountName == accountName {
                    return true
                }
                return false
            }
    }
}

extension ChannelNowPlayingDTO {
    func toDomain() -> NowPlayingItem {
        NowPlayingItem(
            channelId: safeChannelId,
            channelName: safeChannelName,
            channelLogo: channelLogo,
            program: program?.toDomain()
        )
    }
}

enum RecordingStrategy: Equatable {
    case local
    case directvCloud(accountID: String)
    case sling(accountID: String)
    case unavailable
}

enum RecordingStrategyResolver {
    static func resolve(
        channel: Channel,
        program: Program,
        account: TunerBackendProviderAccount?
    ) -> RecordingStrategy {
        switch channel.providerId?.lowercased() {
        case "directv":
            guard let account else { return .local }
            // Prefer server-provided uiMode; fall back to legacy heuristics
            switch account.resolvedUIMode {
            case .backendDVR:
                return .directvCloud(accountID: account.accountId)
            case .receiver:
                return .local
            case .none:
                return .unavailable
            }
        case "sling":
            guard let account,
                  program.slingChannelId != nil,
                  program.slingItemId != nil else {
                return .unavailable
            }
            return .sling(accountID: account.accountId)
        default:
            return .local
        }
    }
}
