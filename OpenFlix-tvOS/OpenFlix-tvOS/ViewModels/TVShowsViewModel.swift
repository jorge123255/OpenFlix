import Foundation
import SwiftUI

@MainActor
class TVShowsViewModel: ObservableObject {
    private let mediaRepository = MediaRepository()

    // Hero carousel state
    @Published var featuredShows: [MediaItem] = []
    @Published var currentFeaturedIndex: Int = 0

    @Published var continueWatching: [MediaItem] = []
    @Published var recentlyAdded: [MediaItem] = []
    @Published var genreHubs: [(genre: String, items: [MediaItem])] = []
    @Published var allShows: [MediaItem] = []
    @Published var availableGenres: [String] = []
    @Published var isLoading = false
    @Published var error: String?

    // Grid browsing state
    @Published var selectedGenre: String? = nil
    @Published var currentSort: SortOption = .addedDesc
    @Published var hasMore = false

    private var showSectionId: Int?
    private var currentOffset = 0
    private let pageSize = 50
    private let maxFeaturedCount = 6

    // TMDB genre cache
    private var tmdbGenreCache: [Int: [String]] = [:]

    // MARK: - Load TV Shows Hub

    func loadTVShowsHub() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // Get the TV show library section
        do {
            let sections = try await mediaRepository.getLibrarySections()
            NSLog("TVShowsViewModel: Found %d library sections", sections.count)
            if let showSection = sections.first(where: { $0.type == .show }) {
                showSectionId = showSection.id
                NSLog("TVShowsViewModel: Using TV show section ID %d", showSection.id)
            } else {
                error = "No TV show library found"
                NSLog("TVShowsViewModel: No TV show library found")
                return
            }
        } catch {
            self.error = "Failed to load library: \(error.localizedDescription)"
            NSLog("TVShowsViewModel: Failed to load library: %@", error.localizedDescription)
            return
        }

        // Load all data in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadContinueWatching() }
            group.addTask { await self.loadRecentlyAdded() }
            group.addTask { await self.loadAllShowsForGenres() }
        }

        // Set featured shows for carousel
        setFeaturedShows()

        // Generate genre hubs
        generateGenreHubs()

        // Load TMDB genres in background
        Task {
            await loadTMDBGenresForShowsWithoutGenres()
        }
    }

    // MARK: - Continue Watching

    private func loadContinueWatching() async {
        guard let sectionId = showSectionId else { return }
        do {
            let onDeck = try await mediaRepository.getSectionOnDeck(sectionId: sectionId)
            continueWatching = onDeck
            NSLog("TVShowsViewModel: Loaded %d continue watching episodes", onDeck.count)
        } catch {
            NSLog("TVShowsViewModel: Failed to load continue watching: %@", error.localizedDescription)
        }
    }

    // MARK: - Recently Added

    private func loadRecentlyAdded() async {
        guard let sectionId = showSectionId else { return }
        do {
            let recent = try await mediaRepository.getSectionRecentlyAdded(sectionId: sectionId)
            recentlyAdded = recent
            NSLog("TVShowsViewModel: Loaded %d recently added shows", recent.count)
        } catch {
            NSLog("TVShowsViewModel: Failed to load recently added: %@", error.localizedDescription)
        }
    }

    // MARK: - All Shows

    private func loadAllShowsForGenres() async {
        guard let sectionId = showSectionId else { return }

        do {
            let result = try await mediaRepository.getLibraryItems(
                sectionId: sectionId,
                start: 0,
                size: 200,
                sort: "addedAt:desc"
            )
            allShows = result.items
            hasMore = result.items.count < result.totalSize
            extractGenres()
        } catch {
            NSLog("TVShowsViewModel: Failed to load shows: %@", error.localizedDescription)
        }
    }

    // MARK: - Featured Shows Selection

    private func setFeaturedShows() {
        let candidates = recentlyAdded.isEmpty ? allShows : recentlyAdded

        // Prefer shows with backdrop art
        var eligibleShows = candidates.filter { $0.art != nil }
        if eligibleShows.isEmpty {
            eligibleShows = candidates.filter { $0.thumb != nil }
        }

        // Sort by rating
        let sorted = eligibleShows.sorted { ($0.audienceRating ?? 0) > ($1.audienceRating ?? 0) }

        featuredShows = Array(sorted.prefix(maxFeaturedCount))
        currentFeaturedIndex = 0

        NSLog("TVShowsViewModel: Selected %d featured shows for carousel", featuredShows.count)
    }

    // MARK: - TMDB Genre Loading

    private func loadTMDBGenresForShowsWithoutGenres() async {
        let showsWithoutGenres = allShows.filter { $0.genres.isEmpty }.prefix(30)

        guard !showsWithoutGenres.isEmpty else {
            NSLog("TVShowsViewModel: All shows have genres")
            return
        }

        NSLog("TVShowsViewModel: Loading TMDB genres for %d shows", showsWithoutGenres.count)

        await TMDBService.shared.reloadApiKey()

        await withTaskGroup(of: (Int, [String]).self) { group in
            for show in showsWithoutGenres {
                group.addTask {
                    // Use movie endpoint as fallback (works for some content)
                    if let info = await TMDBService.shared.getMovieDetails(title: show.title, year: show.year) {
                        return (show.id, info.genres)
                    }
                    return (show.id, [])
                }
            }

            for await (showId, genres) in group {
                if !genres.isEmpty {
                    tmdbGenreCache[showId] = genres
                }
            }
        }

        NSLog("TVShowsViewModel: Loaded TMDB genres for %d shows", tmdbGenreCache.count)

        extractGenresWithTMDB()
        generateGenreHubs()
    }

    // MARK: - Genre Extraction

    private func extractGenres() {
        var genreSet = Set<String>()
        for item in allShows {
            for genre in item.genres {
                genreSet.insert(genre)
            }
        }
        availableGenres = genreSet.sorted()
    }

    private func extractGenresWithTMDB() {
        var genreSet = Set<String>()

        for item in allShows {
            if !item.genres.isEmpty {
                for genre in item.genres {
                    genreSet.insert(genre)
                }
            } else if let tmdbGenres = tmdbGenreCache[item.id] {
                for genre in tmdbGenres {
                    genreSet.insert(genre)
                }
            }
        }

        availableGenres = genreSet.sorted()
        NSLog("TVShowsViewModel: Extracted %d genres (including TMDB)", availableGenres.count)
    }

    private func getGenresForItem(_ item: MediaItem) -> [String] {
        if !item.genres.isEmpty {
            return item.genres
        }
        return tmdbGenreCache[item.id] ?? []
    }

    // MARK: - Genre Hubs

    private func generateGenreHubs() {
        var genreCounts: [String: Int] = [:]
        for item in allShows {
            let genres = getGenresForItem(item)
            for genre in genres {
                genreCounts[genre, default: 0] += 1
            }
        }

        let topGenres = genreCounts
            .sorted { $0.value > $1.value }
            .prefix(8)
            .map { $0.key }

        genreHubs = topGenres.compactMap { genre in
            let items = allShows.filter { getGenresForItem($0).contains(genre) }
            guard items.count >= 1 else { return nil }
            return (genre: genre, items: Array(items.prefix(20)))
        }
        NSLog("TVShowsViewModel: Generated %d genre hubs", genreHubs.count)
    }

    // MARK: - Grid Browse

    func loadGridItems() async {
        guard let sectionId = showSectionId else { return }

        isLoading = allShows.isEmpty
        currentOffset = 0

        do {
            let result = try await mediaRepository.getLibraryItems(
                sectionId: sectionId,
                start: 0,
                size: pageSize,
                sort: currentSort.sortKey
            )
            allShows = result.items
            hasMore = result.items.count < result.totalSize
            extractGenres()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadMoreGridItems() async {
        guard let sectionId = showSectionId, hasMore else { return }

        currentOffset += pageSize

        do {
            let result = try await mediaRepository.getLibraryItems(
                sectionId: sectionId,
                start: currentOffset,
                size: pageSize,
                sort: currentSort.sortKey
            )
            allShows.append(contentsOf: result.items)
            hasMore = currentOffset + result.items.count < result.totalSize
            extractGenres()
        } catch {
            // Silently fail
        }
    }

    func sortBy(_ option: SortOption) {
        currentSort = option
        Task {
            await loadGridItems()
        }
    }

    // MARK: - Computed Properties

    var hasFeaturedCarousel: Bool {
        !featuredShows.isEmpty
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

    var hasUpNext: Bool {
        !continueWatching.isEmpty
    }

    var upNext: [MediaItem] {
        continueWatching
    }

    var filteredItems: [MediaItem] {
        guard let genre = selectedGenre else { return allShows }
        return allShows.filter { getGenresForItem($0).contains(genre) }
    }
}
