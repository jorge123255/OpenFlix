import Foundation
import SwiftUI

@MainActor
class MoviesViewModel: ObservableObject {
    private let mediaRepository = MediaRepository()

    // Single featured item (legacy - kept for compatibility)
    @Published var featuredItem: MediaItem?

    // Hero carousel state
    @Published var featuredMovies: [MediaItem] = []
    @Published var currentFeaturedIndex: Int = 0
    @Published var trailers: [Int: TrailerInfo] = [:]  // mediaId -> trailer
    @Published var isLoadingTrailers = false

    @Published var continueWatching: [MediaItem] = []
    @Published var recentlyAdded: [MediaItem] = []
    @Published var genreHubs: [(genre: String, items: [MediaItem])] = []
    @Published var allMovies: [MediaItem] = []
    @Published var availableGenres: [String] = []
    @Published var collections: [MovieCollection] = []
    @Published var studioCollections: [(studio: String, items: [MediaItem])] = []
    @Published var isLoading = false
    @Published var error: String?

    // Grid browsing state
    @Published var isShowingGridBrowse = false
    @Published var selectedGenre: String? = nil
    @Published var currentSort: SortOption = .addedDesc
    @Published var hasMore = false

    private var movieSectionId: Int?
    private var currentOffset = 0
    private let pageSize = 50
    private let maxFeaturedCount = 8  // Number of movies in hero carousel

    // TMDB genre cache for movies without server genres
    private var tmdbGenreCache: [Int: [String]] = [:]  // mediaId -> genres
    @Published var isLoadingTMDBGenres = false

    // MARK: - Load Movies Hub

    func loadMoviesHub() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // First, get the movie library section
        do {
            let sections = try await mediaRepository.getLibrarySections()
            NSLog("MoviesViewModel: Found %d library sections", sections.count)
            if let movieSection = sections.first(where: { $0.type == .movie }) {
                movieSectionId = movieSection.id
                NSLog("MoviesViewModel: Using movie section ID %d", movieSection.id)
            } else {
                error = "No movie library found"
                NSLog("MoviesViewModel: No movie library found")
                return
            }
        } catch {
            self.error = "Failed to load library: \(error.localizedDescription)"
            NSLog("MoviesViewModel: Failed to load library: %@", error.localizedDescription)
            return
        }

        // Load all data in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadContinueWatching() }
            group.addTask { await self.loadRecentlyAdded() }
            group.addTask { await self.loadAllMoviesForGenres() }
        }

        // Set featured items for carousel
        setFeaturedMovies()

        // Set single featured item (legacy compatibility)
        setFeaturedItem()

        // Generate genre hubs
        generateGenreHubs()

        // Load trailers for featured movies (in background)
        Task {
            await loadTrailersForFeaturedMovies()
        }

        // Load TMDB genres for movies without server genres (in background)
        Task {
            await loadTMDBGenresForMoviesWithoutGenres()
        }
    }

    // MARK: - Continue Watching (OnDeck filtered to movies)

    private func loadContinueWatching() async {
        guard let sectionId = movieSectionId else {
            NSLog("MoviesViewModel: No section ID for continue watching")
            return
        }
        do {
            // Use section-specific method for better filtering
            let onDeck = try await mediaRepository.getSectionOnDeck(sectionId: sectionId)
            continueWatching = onDeck
            NSLog("MoviesViewModel: Loaded %d continue watching movies", onDeck.count)
        } catch {
            // Continue watching is not critical, don't set error
            NSLog("MoviesViewModel: Failed to load continue watching: %@", error.localizedDescription)
        }
    }

    // MARK: - Recently Added

    private func loadRecentlyAdded() async {
        guard let sectionId = movieSectionId else {
            NSLog("MoviesViewModel: No section ID for recently added")
            return
        }
        do {
            // Use section-specific endpoint instead of global
            let recent = try await mediaRepository.getSectionRecentlyAdded(sectionId: sectionId)
            recentlyAdded = recent
            NSLog("MoviesViewModel: Loaded %d recently added movies", recent.count)
        } catch {
            NSLog("MoviesViewModel: Failed to load recently added: %@", error.localizedDescription)
        }
    }

    // MARK: - All Movies (for genre extraction)

    private func loadAllMoviesForGenres() async {
        guard let sectionId = movieSectionId else { return }

        do {
            let result = try await mediaRepository.getLibraryItems(
                sectionId: sectionId,
                start: 0,
                size: 200,  // Load enough for good genre variety
                sort: "addedAt:desc"
            )
            allMovies = result.items
            hasMore = result.items.count < result.totalSize

            // Extract genres
            extractGenres()
        } catch {
            print("Failed to load movies for genres: \(error)")
        }
    }

    // MARK: - Featured Movies Selection (for Carousel)

    private func setFeaturedMovies() {
        // Select top movies for the hero carousel
        // Priority: high-rated recent movies with backdrop art, fallback to thumb
        let candidates = recentlyAdded.isEmpty ? allMovies : recentlyAdded

        // Prefer movies with backdrop art, but fallback to those with at least a thumb
        var eligibleMovies = candidates.filter { $0.art != nil }
        if eligibleMovies.isEmpty {
            // Fallback: use movies with thumb (poster) instead
            eligibleMovies = candidates.filter { $0.thumb != nil }
        }

        // Sort by rating (descending) to get best movies first
        let sorted = eligibleMovies.sorted { ($0.audienceRating ?? 0) > ($1.audienceRating ?? 0) }

        // Take top N for carousel
        featuredMovies = Array(sorted.prefix(maxFeaturedCount))

        // Reset carousel index
        currentFeaturedIndex = 0

        NSLog("MoviesViewModel: Selected %d featured movies for carousel (from %d candidates)", featuredMovies.count, eligibleMovies.count)
    }

    // MARK: - Featured Item Selection (Legacy)

    private func setFeaturedItem() {
        // Priority: recent high-rated movie > random recently added > first movie
        let candidates = recentlyAdded.isEmpty ? allMovies : recentlyAdded

        // Prefer items with backdrop art and high ratings
        let withArt = candidates.filter { $0.art != nil }
        let preferred = withArt.filter { ($0.audienceRating ?? 0) >= 7.0 }

        if !preferred.isEmpty {
            featuredItem = preferred.randomElement()
        } else if !withArt.isEmpty {
            featuredItem = withArt.randomElement()
        } else {
            featuredItem = candidates.first
        }
    }

    // MARK: - TMDB Trailer Loading

    private func loadTrailersForFeaturedMovies() async {
        guard !featuredMovies.isEmpty else { return }

        isLoadingTrailers = true
        defer { isLoadingTrailers = false }

        NSLog("MoviesViewModel: Loading trailers for %d featured movies", featuredMovies.count)

        // Preload the TMDB API key before starting parallel searches
        // This ensures all parallel tasks have access to the key
        await TMDBService.shared.reloadApiKey()

        // Load trailers in parallel for all featured movies
        await withTaskGroup(of: (Int, TrailerInfo?).self) { group in
            for movie in featuredMovies {
                group.addTask {
                    let trailer = await self.loadTrailerForMovie(movie)
                    return (movie.id, trailer)
                }
            }

            for await (movieId, trailer) in group {
                if let trailer = trailer {
                    trailers[movieId] = trailer
                    NSLog("MoviesViewModel: Loaded trailer for movie %d: %@", movieId, trailer.name)
                }
            }
        }

        NSLog("MoviesViewModel: Loaded %d trailers total", trailers.count)
    }

    private func loadTrailerForMovie(_ movie: MediaItem) async -> TrailerInfo? {
        // Try to extract TMDB ID from the movie's GUID
        // Plex stores GUIDs like "plex://movie/xxx", "tmdb://12345", or
        // "com.plexapp.agents.themoviedb://12345?lang=en"

        var guidToCheck = movie.guid

        // If guid is not in the basic item, fetch full details
        if guidToCheck == nil || !guidToCheck!.contains("tmdb") && !guidToCheck!.contains("themoviedb") {
            do {
                let details = try await mediaRepository.getMediaDetails(id: movie.id)
                guidToCheck = details.guid
            } catch {
                NSLog("MoviesViewModel: Failed to get details for movie %d: %@", movie.id, error.localizedDescription)
            }
        }

        // Try to extract TMDB ID from GUID
        if let guid = guidToCheck,
           let tmdbId = await TMDBService.shared.extractTMDBId(from: guid) {
            NSLog("MoviesViewModel: Found TMDB ID %@ for movie %d (%@)", tmdbId, movie.id, movie.title)
            return await TMDBService.shared.getTrailer(tmdbId: tmdbId)
        }

        // Fallback: Search TMDB by title and year (for M3U/VOD imports without TMDB GUIDs)
        NSLog("MoviesViewModel: No TMDB GUID for movie %d (%@), searching by title...", movie.id, movie.title)
        return await TMDBService.shared.getTrailerByTitle(title: movie.title, year: movie.year)
    }

    /// Get current trailer for the carousel (if available)
    var currentTrailer: TrailerInfo? {
        guard currentFeaturedIndex < featuredMovies.count else { return nil }
        let movie = featuredMovies[currentFeaturedIndex]
        return trailers[movie.id]
    }

    /// Check if we have any featured movies for the carousel
    var hasFeaturedCarousel: Bool {
        !featuredMovies.isEmpty
    }

    // MARK: - TMDB Genre Loading

    /// Load TMDB genres for movies that don't have server genres
    private func loadTMDBGenresForMoviesWithoutGenres() async {
        // Find movies without genres (limit to first 30 to avoid too many API calls)
        let moviesWithoutGenres = allMovies.filter { $0.genres.isEmpty }.prefix(30)

        guard !moviesWithoutGenres.isEmpty else {
            NSLog("MoviesViewModel: All movies have genres, skipping TMDB genre fetch")
            return
        }

        isLoadingTMDBGenres = true
        defer { isLoadingTMDBGenres = false }

        NSLog("MoviesViewModel: Loading TMDB genres for %d movies without genres", moviesWithoutGenres.count)

        // Preload the TMDB API key
        await TMDBService.shared.reloadApiKey()

        // Load genres in parallel (batched)
        await withTaskGroup(of: (Int, [String]).self) { group in
            for movie in moviesWithoutGenres {
                group.addTask {
                    let genres = await self.fetchTMDBGenres(for: movie)
                    return (movie.id, genres)
                }
            }

            for await (movieId, genres) in group {
                if !genres.isEmpty {
                    tmdbGenreCache[movieId] = genres
                }
            }
        }

        NSLog("MoviesViewModel: Loaded TMDB genres for %d movies", tmdbGenreCache.count)

        // Re-extract genres to include TMDB data
        extractGenresWithTMDB()

        // Regenerate genre hubs with new data
        generateGenreHubs()
    }

    /// Fetch genres from TMDB for a single movie
    private func fetchTMDBGenres(for movie: MediaItem) async -> [String] {
        guard let info = await TMDBService.shared.getMovieDetails(title: movie.title, year: movie.year) else {
            return []
        }
        return info.genres
    }

    // MARK: - Genre Extraction and Hub Generation

    private func extractGenres() {
        var genreSet = Set<String>()
        for item in allMovies {
            for genre in item.genres {
                genreSet.insert(genre)
            }
        }
        availableGenres = genreSet.sorted()
    }

    /// Extract genres including TMDB cache data
    private func extractGenresWithTMDB() {
        var genreSet = Set<String>()

        for item in allMovies {
            // First try server genres
            if !item.genres.isEmpty {
                for genre in item.genres {
                    genreSet.insert(genre)
                }
            } else if let tmdbGenres = tmdbGenreCache[item.id] {
                // Fall back to TMDB genres
                for genre in tmdbGenres {
                    genreSet.insert(genre)
                }
            }
        }

        availableGenres = genreSet.sorted()
        NSLog("MoviesViewModel: Extracted %d genres (including TMDB)", availableGenres.count)
    }

    private func generateGenreHubs() {
        // Create hubs for top genres (ones with most movies)
        // Include both server genres and TMDB genres
        var genreCounts: [String: Int] = [:]
        for item in allMovies {
            let genres = getGenresForItem(item)
            for genre in genres {
                genreCounts[genre, default: 0] += 1
            }
        }

        // Sort by count and take top genres
        let topGenres = genreCounts
            .sorted { $0.value > $1.value }
            .prefix(8)
            .map { $0.key }

        // Create hub for each genre (lowered threshold to show all genres with at least 1 movie)
        genreHubs = topGenres.compactMap { genre in
            let items = allMovies.filter { getGenresForItem($0).contains(genre) }
            guard items.count >= 1 else { return nil }
            return (genre: genre, items: Array(items.prefix(20)))
        }
        NSLog("MoviesViewModel: Generated %d genre hubs from %d movies", genreHubs.count, allMovies.count)
    }

    /// Get genres for an item (server or TMDB fallback)
    private func getGenresForItem(_ item: MediaItem) -> [String] {
        if !item.genres.isEmpty {
            return item.genres
        }
        return tmdbGenreCache[item.id] ?? []
    }

    // MARK: - Grid Browse Functions

    func loadGridItems() async {
        guard let sectionId = movieSectionId else { return }

        isLoading = allMovies.isEmpty
        currentOffset = 0

        do {
            let result = try await mediaRepository.getLibraryItems(
                sectionId: sectionId,
                start: 0,
                size: pageSize,
                sort: currentSort.sortKey
            )
            allMovies = result.items
            hasMore = result.items.count < result.totalSize
            extractGenres()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadMoreGridItems() async {
        guard let sectionId = movieSectionId, hasMore else { return }

        currentOffset += pageSize

        do {
            let result = try await mediaRepository.getLibraryItems(
                sectionId: sectionId,
                start: currentOffset,
                size: pageSize,
                sort: currentSort.sortKey
            )
            allMovies.append(contentsOf: result.items)
            hasMore = currentOffset + result.items.count < result.totalSize
            extractGenres()
        } catch {
            // Silently fail on load more
        }
    }

    func sortBy(_ option: SortOption) {
        currentSort = option
        Task {
            await loadGridItems()
        }
    }

    // MARK: - Computed Properties

    var hasFeatured: Bool {
        featuredItem != nil
    }

    var hasContinueWatching: Bool {
        !continueWatching.isEmpty
    }

    var hasRecentlyAdded: Bool {
        !recentlyAdded.isEmpty
    }

    var hasGenreHubs: Bool {
        !genreHubs.isEmpty
    }

    var genreCollections: [(genre: String, items: [MediaItem])] {
        genreHubs
    }

    var filteredItems: [MediaItem] {
        guard let genre = selectedGenre else { return allMovies }
        return allMovies.filter { getGenresForItem($0).contains(genre) }
    }
}

// MARK: - Movie Collection

struct MovieCollection: Identifiable {
    let id: String
    let name: String
    let items: [MediaItem]
}
