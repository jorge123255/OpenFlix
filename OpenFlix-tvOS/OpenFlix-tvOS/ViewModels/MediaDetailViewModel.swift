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
}
