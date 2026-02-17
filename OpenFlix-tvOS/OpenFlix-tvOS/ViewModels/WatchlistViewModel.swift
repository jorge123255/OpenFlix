import Foundation
import SwiftUI

@MainActor
class WatchlistViewModel: ObservableObject {
    private let watchlistRepository = WatchlistRepository()

    @Published var items: [WatchlistItem] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Load

    func loadWatchlist() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await watchlistRepository.loadWatchlist()
            items = watchlistRepository.items
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Actions

    func removeFromWatchlist(_ item: WatchlistItem) async {
        do {
            try await watchlistRepository.removeFromWatchlist(mediaId: item.mediaId)
            items = watchlistRepository.items
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addToWatchlist(mediaId: Int) async {
        do {
            try await watchlistRepository.addToWatchlist(mediaId: mediaId)
            items = watchlistRepository.items
        } catch {
            self.error = error.localizedDescription
        }
    }

    func isInWatchlist(mediaId: Int) -> Bool {
        watchlistRepository.isInWatchlist(mediaId: mediaId)
    }

    // MARK: - Computed

    var hasItems: Bool {
        !items.isEmpty
    }

    var movieItems: [WatchlistItem] {
        items.filter { $0.media?.type == .movie }
    }

    var showItems: [WatchlistItem] {
        items.filter { $0.media?.type == .show }
    }

    var sortedByAddedDate: [WatchlistItem] {
        items.sorted { $0.addedAt > $1.addedAt }
    }
}
