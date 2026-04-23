import Foundation

// MARK: - Provider playback / detail (cross-provider)
//
// Mirrors the OpenFlix web's ProviderPlayResponse + the uniform
// /<provider>/detail/:id contract. Used for Disney VOD, Max VOD,
// and ESPN events. The client never builds streams from raw
// browse data — it always asks the server for a play session and
// hands the resulting `streamUrl` to VLC.

struct ProviderPlayResponse: Codable {
    let success: Bool?
    let provider: String?
    let title: String?
    let contentId: String?
    let itemId: String?
    let deeplinkId: String?
    let resourceId: String?
    let editId: String?
    let mediaId: String?
    let duration: Double?
    let quality: String?
    let hasPlayReady4k: Bool?
    let streamUrl: String?
    let infoEndpoint: String?
    let playback: ProviderPlayback?
    let error: String?
}

struct ProviderPlayback: Codable {
    let manifestUrl: String?
    let streamType: String?
    let drmType: String?
    let keyCount: Int?
    let contentName: String?
    let startoverUrl: String?
}

// MARK: - Uniform detail response
//
// `GET /api/tuner-backends/active/<provider>/detail/:id` returns
// this normalized shape across Disney / Max / ESPN. Renderer reads
// the same fields regardless of provider.

struct ProviderDetailResponse: Codable {
    let success: Bool?
    let provider: String?
    let id: String?
    let title: String?
    let shortDesc: String?
    let longDesc: String?
    let year: Int?
    let runtimeMinutes: Int?
    let genres: [String]?
    let rating: String?
    let advisories: [String]?
    let flags: [String]?
    let artwork: ProviderDetailArtwork?
    let cast: [ProviderDetailPerson]?
    let directors: [ProviderDetailPerson]?
    let trailers: [ProviderDetailTrailer]?
    let seasons: [ProviderDetailSeason]?
    let relatedIds: [String]?
    let streamUrl: String?
    let infoEndpoint: String?
    let error: String?
}

struct ProviderDetailArtwork: Codable {
    let hero: String?
    let background: String?
    let tile: String?
    let poster: String?
    let logo: String?
    let titleTreatment: String?

    var bestHeroURL: String? {
        [hero, background, tile, poster].compactMap { $0 }.first { !$0.isEmpty }
    }
}

struct ProviderDetailPerson: Codable, Identifiable {
    let id: String?
    let name: String?
    let role: String?
    let imageUrl: String?

    var renderId: String { id ?? name ?? UUID().uuidString }
}

struct ProviderDetailTrailer: Codable, Identifiable {
    let id: String?
    let title: String?
    let url: String?
    let durationMs: Int?

    var renderId: String { id ?? url ?? UUID().uuidString }
}

struct ProviderDetailSeason: Codable, Identifiable {
    let id: String?
    let title: String?
    let seasonNumber: Int?
    let episodeCount: Int?
    let episodes: [ProviderDetailEpisode]?

    var renderId: String { id ?? title ?? "season:\(seasonNumber ?? 0)" }
}

struct ProviderDetailEpisode: Codable, Identifiable {
    let id: String?
    let title: String?
    let episodeNumber: Int?
    let seasonNumber: Int?
    let runtimeMinutes: Int?
    let shortDesc: String?
    let imageUrl: String?

    var renderId: String { id ?? "ep:\(seasonNumber ?? 0):\(episodeNumber ?? 0)" }
}
