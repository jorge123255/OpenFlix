import Foundation
import SwiftUI

@MainActor
class MediaDetailViewModel: ObservableObject {
    private let mediaRepository = MediaRepository()
    private let watchlistRepository = WatchlistRepository()

    @Published var mediaItem: MediaItem?
    @Published var seasons: [MediaItem] = []
    @Published var episodes: [MediaItem] = []
    @Published var selectedSeason: MediaItem?
    @Published var relatedItems: [MediaItem] = []
    @Published var isInWatchlist = false
    @Published var isLoading = false
    @Published var error: String?

    // TMDB-enhanced metadata (for movies without server metadata)
    @Published var tmdbInfo: TMDBMovieInfo?
    @Published var isLoadingTMDB = false

    private var mediaId: Int = 0

    // MARK: - Load

    func loadMedia(id: Int) async {
        self.mediaId = id
        isLoading = true
        error = nil

        NSLog("MediaDetailViewModel: Loading media with id \(id)")

        do {
            // Load media details
            let item = try await mediaRepository.getMediaDetails(id: id)
            NSLog("MediaDetailViewModel: Loaded media '\(item.title)' type=\(item.type.rawValue)")
            NSLog("MediaDetailViewModel: summary=\(item.summary?.prefix(50) ?? "nil"), thumb=\(item.thumb ?? "nil"), art=\(item.art ?? "nil")")
            NSLog("MediaDetailViewModel: genres=\(item.genres), roles count=\(item.roles.count)")
            NSLog("MediaDetailViewModel: mediaVersions count=\(item.mediaVersions.count)")
            if let version = item.mediaVersions.first, let part = version.parts.first {
                NSLog("MediaDetailViewModel: First part key=\(part.key), file=\(part.file ?? "nil")")
            }
            mediaItem = item

            // Check watchlist status
            try? await watchlistRepository.loadWatchlist()
            isInWatchlist = watchlistRepository.isInWatchlist(mediaId: id)

            // Load children if it's a TV show
            if item.type == .show {
                NSLog("MediaDetailViewModel: Loading seasons for show")
                await loadSeasons(showId: id)
            }

            // If movie is missing metadata, fetch from TMDB
            if item.type == .movie && needsTMDBMetadata(item) {
                NSLog("MediaDetailViewModel: Movie missing metadata, fetching from TMDB...")
                await loadTMDBMetadata(for: item)
            }

        } catch let networkError as NetworkError {
            NSLog("MediaDetailViewModel: Network error - \(networkError.errorDescription ?? "unknown")")
            error = networkError.errorDescription
        } catch {
            NSLog("MediaDetailViewModel: Error - \(error.localizedDescription)")
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadSeasons(showId: Int) async {
        do {
            seasons = try await mediaRepository.getMediaChildren(id: showId)
            seasons.sort { ($0.index ?? 0) < ($1.index ?? 0) }

            // Select first season by default
            if let firstSeason = seasons.first {
                await selectSeason(firstSeason)
            }
        } catch {
            // Silently fail
        }
    }

    func selectSeason(_ season: MediaItem) async {
        selectedSeason = season

        do {
            episodes = try await mediaRepository.getMediaChildren(id: season.id)
            episodes.sort { ($0.index ?? 0) < ($1.index ?? 0) }
        } catch {
            episodes = []
        }
    }

    // MARK: - Actions

    func toggleWatchlist() async {
        do {
            try await watchlistRepository.toggleWatchlist(mediaId: mediaId)
            isInWatchlist = watchlistRepository.isInWatchlist(mediaId: mediaId)
        } catch {
            // Silently fail
        }
    }

    func markAsWatched() async {
        do {
            try await mediaRepository.markAsWatched(mediaId: mediaId)
            // Reload to get updated state
            await loadMedia(id: mediaId)
        } catch {
            // Silently fail
        }
    }

    func markAsUnwatched() async {
        do {
            try await mediaRepository.markAsUnwatched(mediaId: mediaId)
            await loadMedia(id: mediaId)
        } catch {
            // Silently fail
        }
    }

    // MARK: - Computed

    var canPlay: Bool {
        guard let item = mediaItem else { return false }
        return item.type == .movie || item.type == .episode
    }

    var hasSeasons: Bool {
        !seasons.isEmpty
    }

    var hasEpisodes: Bool {
        !episodes.isEmpty
    }

    var playButtonTitle: String {
        guard let item = mediaItem else { return "Play" }

        if item.isInProgress {
            return "Resume"
        }
        return "Play"
    }

    var nextUpEpisode: MediaItem? {
        // Find first unwatched episode
        episodes.first { !$0.isWatched }
    }

    // MARK: - TMDB Metadata

    /// Check if movie is missing metadata that TMDB can provide
    private func needsTMDBMetadata(_ item: MediaItem) -> Bool {
        // If missing summary OR cast, we should fetch from TMDB
        let missingSummary = item.summary == nil || item.summary?.isEmpty == true
        let missingCast = item.roles.isEmpty
        let missingGenres = item.genres.isEmpty
        return missingSummary || missingCast || missingGenres
    }

    /// Fetch metadata from TMDB for movies without server metadata
    private func loadTMDBMetadata(for item: MediaItem) async {
        isLoadingTMDB = true
        defer { isLoadingTMDB = false }

        let info = await TMDBService.shared.getMovieDetails(title: item.title, year: item.year)
        if let info = info {
            tmdbInfo = info
            NSLog("MediaDetailViewModel: Loaded TMDB metadata - summary: \(info.overview?.prefix(50) ?? "nil"), cast: \(info.cast.count), genres: \(info.genres)")
        } else {
            NSLog("MediaDetailViewModel: No TMDB metadata found for '\(item.title)'")
        }
    }

    // MARK: - Combined Metadata Accessors

    /// Get summary - prefer server data, fallback to TMDB
    var effectiveSummary: String? {
        if let summary = mediaItem?.summary, !summary.isEmpty {
            return summary
        }
        return tmdbInfo?.overview
    }

    /// Get genres - prefer server data, fallback to TMDB
    var effectiveGenres: [String] {
        if let genres = mediaItem?.genres, !genres.isEmpty {
            return genres
        }
        return tmdbInfo?.genres ?? []
    }

    /// Get cast - prefer server data, fallback to TMDB
    var effectiveCast: [CastMember] {
        if let roles = mediaItem?.roles, !roles.isEmpty {
            return roles
        }
        // Generate unique IDs for TMDB cast members using enumeration
        return tmdbInfo?.cast.enumerated().map { index, castMember in
            CastMember(
                id: 10000 + index,  // Use offset to avoid conflicts with server IDs
                name: castMember.name,
                role: castMember.character,
                thumb: castMember.profileURL?.absoluteString
            )
        } ?? []
    }

    /// Get directors - prefer server data, fallback to TMDB
    var effectiveDirectors: [String] {
        if let directors = mediaItem?.directors, !directors.isEmpty {
            return directors
        }
        return tmdbInfo?.directors ?? []
    }

    /// Get backdrop URL - prefer TMDB high quality
    var effectiveBackdropURL: URL? {
        tmdbInfo?.backdropURL
    }

    /// Get audience rating - prefer server data, fallback to TMDB
    var effectiveRating: Double? {
        if let rating = mediaItem?.audienceRating, rating > 0 {
            return rating
        }
        return tmdbInfo?.voteAverage
    }
}
