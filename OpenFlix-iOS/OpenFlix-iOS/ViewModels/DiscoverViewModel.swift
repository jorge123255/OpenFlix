import Foundation
import SwiftUI

@MainActor
class DiscoverViewModel: ObservableObject {
    private let mediaRepository = MediaRepository()
    private let watchlistRepository = WatchlistRepository()

    @Published var sections: [LibrarySection] = []
    @Published var onDeck: [MediaItem] = []
    @Published var recentlyAdded: [MediaItem] = []
    @Published var featured: [MediaItem] = []
    @Published var topTen: [MediaItem] = []
    @Published var hubs: [Hub] = []
    @Published var streamingServices: [StreamingService] = []
    @Published var recommended: [MediaItem] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: String?
    @Published var lastRefreshTime: Date?

    // Auto-refresh timer
    private var refreshTask: Task<Void, Never>?
    private let autoRefreshInterval: TimeInterval = 60 // Refresh every 60 seconds

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        stopAutoRefresh()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(autoRefreshInterval * 1_000_000_000))
                if !Task.isCancelled {
                    await refresh()
                }
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() async {
        guard !isLoading else { return }
        isRefreshing = true
        await loadHomeContent(isRefresh: true)
        isRefreshing = false
        lastRefreshTime = Date()
    }

    // MARK: - Load

    func loadHomeContent(isRefresh: Bool = false) async {
        if !isRefresh {
            isLoading = true
        }
        error = nil
        defer {
            if !isRefresh {
                isLoading = false
            }
        }

        // Load each section independently so partial failures don't block everything
        var errors: [String] = []

        // Load library sections
        do {
            sections = try await mediaRepository.getLibrarySections()
            print("Loaded \(sections.count) library sections")
        } catch {
            print("Failed to load library sections: \(error)")
            errors.append("Library sections: \(error.localizedDescription)")
        }

        // Load continue watching (on deck)
        do {
            onDeck = try await mediaRepository.getOnDeck()
            print("Loaded \(onDeck.count) on deck items")
        } catch {
            print("Failed to load on deck: \(error)")
            // On deck failing is not critical
        }

        // Load recently added
        do {
            recentlyAdded = try await mediaRepository.getRecentlyAdded()
            print("Loaded \(recentlyAdded.count) recently added items")

            // Use recently added for featured if we have enough
            if recentlyAdded.count >= 3 {
                featured = Array(recentlyAdded.prefix(5))
            }
        } catch {
            print("Failed to load recently added: \(error)")
            // Recently added failing is not critical
        }

        // Load hubs for first section
        if let firstSection = sections.first {
            do {
                hubs = try await mediaRepository.getHubs(sectionId: firstSection.id)
                print("Loaded \(hubs.count) hubs")

                // Generate streaming services from hub items
                generateStreamingServices()

                // Generate recommendations from hubs
                generateRecommendations()

                // Generate top 10 from rated items
                generateTopTen()
            } catch {
                print("Failed to load hubs: \(error)")
                // Hubs failing is not critical
            }
        }

        // If no featured items yet, try to get them from hubs
        if featured.isEmpty && !hubs.isEmpty {
            // Look for a "featured" or "recommended" hub
            if let featuredHub = hubs.first(where: {
                $0.title.lowercased().contains("featured") ||
                $0.title.lowercased().contains("recommended") ||
                $0.title.lowercased().contains("popular")
            }) {
                featured = Array(featuredHub.items.prefix(5))
            } else if let firstHub = hubs.first {
                // Fall back to first hub
                featured = Array(firstHub.items.prefix(5))
            }
        }

        // Only show error if nothing loaded
        if sections.isEmpty && onDeck.isEmpty && recentlyAdded.isEmpty && hubs.isEmpty {
            if !errors.isEmpty {
                error = errors.first
            } else {
                error = "Failed to load content"
            }
        }
    }

    func loadHubs(for sectionId: Int) async {
        do {
            hubs = try await mediaRepository.getHubs(sectionId: sectionId)
            generateStreamingServices()
            generateRecommendations()
            generateTopTen()
        } catch {
            // Silently fail for hub loading
        }
    }

    // MARK: - Generate Streaming Services

    private func generateStreamingServices() {
        // Collect all items from hubs
        var allItems: [MediaItem] = []
        for hub in hubs {
            allItems.append(contentsOf: hub.items)
        }

        // Add recently added items
        allItems.append(contentsOf: recentlyAdded)

        // Group by studio/service
        var serviceMap: [String: [MediaItem]] = [:]
        for item in allItems {
            guard let studio = item.studio, !studio.isEmpty else { continue }
            serviceMap[studio, default: []].append(item)
        }

        // Create streaming service objects for services with enough content
        streamingServices = serviceMap
            .filter { $0.value.count >= 3 }
            .map { (name, items) in
                StreamingService(
                    id: name.lowercased().replacingOccurrences(of: " ", with: "-"),
                    name: name,
                    icon: nil,
                    items: Array(items.prefix(20))
                )
            }
            .sorted { $0.items.count > $1.items.count }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Generate Top 10

    private func generateTopTen() {
        // Collect all items from hubs and recently added
        var allItems: [MediaItem] = []
        for hub in hubs {
            allItems.append(contentsOf: hub.items)
        }
        allItems.append(contentsOf: recentlyAdded)

        // Remove duplicates
        var seen = Set<Int>()
        let uniqueItems = allItems.filter { item in
            guard !seen.contains(item.id) else { return false }
            seen.insert(item.id)
            return true
        }

        // Sort by rating (audience rating or regular rating) and take top 10
        topTen = uniqueItems
            .filter { $0.type == .movie || $0.type == .show }
            .sorted { (lhs, rhs) in
                let lhsRating = lhs.audienceRating ?? lhs.rating ?? 0
                let rhsRating = rhs.audienceRating ?? rhs.rating ?? 0
                return lhsRating > rhsRating
            }
            .prefix(10)
            .map { $0 }
    }

    // MARK: - Generate Recommendations

    private func generateRecommendations() {
        // Find a "recommended" or "similar" hub
        if let recHub = hubs.first(where: {
            let title = $0.title.lowercased()
            return title.contains("recommend") ||
                   title.contains("similar") ||
                   title.contains("you might like")
        }) {
            recommended = recHub.items
        } else {
            // Build recommendations from various sources
            var items: [MediaItem] = []

            // Add some from each hub
            for hub in hubs.prefix(3) {
                items.append(contentsOf: hub.items.prefix(3))
            }

            // Remove duplicates
            var seen = Set<Int>()
            recommended = items.filter { item in
                guard !seen.contains(item.id) else { return false }
                seen.insert(item.id)
                return true
            }
        }
    }

    // MARK: - Computed

    var movieSections: [LibrarySection] {
        sections.filter { $0.type == .movie }
    }

    var tvShowSections: [LibrarySection] {
        sections.filter { $0.type == .show }
    }

    var hasContinueWatching: Bool {
        !onDeck.isEmpty
    }

    var hasRecentlyAdded: Bool {
        !recentlyAdded.isEmpty
    }

    var hasFeatured: Bool {
        !featured.isEmpty
    }

    var hasStreamingServices: Bool {
        !streamingServices.isEmpty
    }

    var hasRecommended: Bool {
        !recommended.isEmpty
    }

    var hasTopTen: Bool {
        !topTen.isEmpty
    }

    // MARK: - Watchlist

    func toggleWatchlist(for item: MediaItem) async {
        do {
            try await watchlistRepository.toggleWatchlist(mediaId: item.id)
        } catch {
            print("Failed to toggle watchlist for \(item.title): \(error)")
        }
    }

    func isInWatchlist(mediaId: Int) -> Bool {
        watchlistRepository.isInWatchlist(mediaId: mediaId)
    }
}
