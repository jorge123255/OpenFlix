import Foundation

@MainActor
class WatchlistRepository: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published var items: [WatchlistItem] = []
    @Published var mediaIds: Set<Int> = []

    // MARK: - Load

    func loadWatchlist() async throws {
        let response = try await api.getWatchlist()
        items = response.allItems.map { $0.toDomain() }
        mediaIds = Set(items.map { $0.mediaId })
    }

    // MARK: - Add/Remove

    func addToWatchlist(mediaId: Int) async throws {
        try await api.addToWatchlist(mediaId: mediaId)
        mediaIds.insert(mediaId)

        // Reload to get full item details
        try await loadWatchlist()
    }

    func removeFromWatchlist(mediaId: Int) async throws {
        try await api.removeFromWatchlist(mediaId: mediaId)
        mediaIds.remove(mediaId)
        items.removeAll { $0.mediaId == mediaId }
    }

    func toggleWatchlist(mediaId: Int) async throws {
        if isInWatchlist(mediaId: mediaId) {
            try await removeFromWatchlist(mediaId: mediaId)
        } else {
            try await addToWatchlist(mediaId: mediaId)
        }
    }

    // MARK: - Check

    func isInWatchlist(mediaId: Int) -> Bool {
        mediaIds.contains(mediaId)
    }
}
