import Foundation
import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    private let mediaRepository = MediaRepository()

    @Published var query = ""
    @Published var results: [Hub] = []
    @Published var isSearching = false
    @Published var error: String?

    private var searchTask: Task<Void, Never>?

    // MARK: - Search

    func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }

        // Cancel previous search
        searchTask?.cancel()

        isSearching = true
        error = nil

        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

            guard !Task.isCancelled else { return }

            do {
                let searchResults = try await mediaRepository.search(query: query)
                if !Task.isCancelled {
                    results = searchResults
                }
            } catch let networkError as NetworkError {
                if !Task.isCancelled {
                    error = networkError.errorDescription
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                }
            }

            if !Task.isCancelled {
                isSearching = false
            }
        }
    }

    func clearSearch() {
        query = ""
        results = []
        searchTask?.cancel()
    }

    // MARK: - Computed

    var hasResults: Bool {
        !results.isEmpty
    }

    var movieResults: [MediaItem] {
        results.first { $0.type == "movie" }?.items ?? []
    }

    var showResults: [MediaItem] {
        results.first { $0.type == "show" }?.items ?? []
    }

    var episodeResults: [MediaItem] {
        results.first { $0.type == "episode" }?.items ?? []
    }

    var totalResultCount: Int {
        results.reduce(0) { $0 + $1.items.count }
    }
}
