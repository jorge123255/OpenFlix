import Foundation

// MARK: - Connection Info
struct ConnectionInfoDTO: Codable {
    let serverUrl: String
    let networkType: String
    let isRemote: Bool
    let suggestedQuality: String
    let tailscaleAvailable: Bool
}

// MARK: - Remote Access Status
struct RemoteAccessStatusDTO: Codable {
    let enabled: Bool
    let connected: Bool
    let method: String?
    let tailscaleIp: String?
    let tailscaleHostname: String?
    let magicDnsName: String?
    let backendState: String?
    let loginUrl: String?
    let lastSeen: Date?
    let error: String?
}

// MARK: - Remote Access Action Response
struct RemoteAccessActionResponse: Codable {
    let success: Bool
    let message: String?
    let loginUrl: String?
    let status: RemoteAccessStatusDTO?
}

// MARK: - Remote Access Health
struct RemoteAccessHealthDTO: Codable {
    let healthy: Bool
    let checks: [String: Bool]?
    let warnings: [String]?
}

// MARK: - Tailscale Install Info
struct TailscaleInstallInfoDTO: Codable {
    let isInstalled: Bool
    let currentVersion: String?
    let installCommand: String?
    let configureCommand: String?
    let docUrl: String?
}

// MARK: - Tailscale Login URL
struct TailscaleLoginUrlDTO: Codable {
    let url: String?
}

// MARK: - Network Type
enum NetworkType: String, Codable, CaseIterable {
    case wifi = "wifi"
    case cellular = "cellular"
    case vpn = "vpn"
    case ethernet = "ethernet"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .vpn: return "VPN"
        case .ethernet: return "Ethernet"
        case .unknown: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .vpn: return "lock.shield"
        case .ethernet: return "cable.connector"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Instant Switch Status
struct InstantSwitchStatusDTO: Codable {
    let enabled: Bool
    let activeChannel: String?
    let cachedStreams: Int
    let totalMemoryMB: Int
    let predictions: [String]?
}

// MARK: - Cached Streams
struct CachedStreamsDTO: Codable {
    let streams: [CachedStreamDTO]
}

struct CachedStreamDTO: Codable {
    let channelId: String
    let bufferSize: Int
    let isLive: Bool
    let lastAccess: Date?
}

// MARK: - Remote Streaming Quality
enum RemoteStreamingQuality: String, Codable, CaseIterable {
    case original = "original"
    case quality1080p = "1080p"
    case quality720p = "720p"
    case quality480p = "480p"
    case quality360p = "360p"
    case auto = "auto"

    var displayName: String {
        switch self {
        case .original: return "Original"
        case .quality1080p: return "1080p"
        case .quality720p: return "720p"
        case .quality480p: return "480p"
        case .quality360p: return "360p"
        case .auto: return "Auto"
        }
    }

    var description: String {
        switch self {
        case .original: return "Best quality, highest bandwidth"
        case .quality1080p: return "Full HD, 8+ Mbps"
        case .quality720p: return "HD, 4+ Mbps"
        case .quality480p: return "SD, 2+ Mbps"
        case .quality360p: return "Low, 1+ Mbps"
        case .auto: return "Automatically adjust"
        }
    }

    var bandwidth: Int {
        switch self {
        case .original: return 0
        case .quality1080p: return 8000
        case .quality720p: return 4000
        case .quality480p: return 2000
        case .quality360p: return 1000
        case .auto: return -1
        }
    }

    static func suggestedFor(_ networkType: NetworkType) -> RemoteStreamingQuality {
        switch networkType {
        case .wifi, .ethernet:
            return .original
        case .vpn:
            return .quality720p
        case .cellular:
            return .quality480p
        case .unknown:
            return .auto
        }
    }
}
