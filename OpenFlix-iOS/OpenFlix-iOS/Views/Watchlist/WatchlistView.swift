import SwiftUI

struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.loadWatchlist() }
                    }
                } else if viewModel.hasItems {
                    contentView
                } else {
                    EmptyStateView(
                        icon: "bookmark",
                        title: "Your Watchlist is Empty",
                        message: "Add movies and shows to your watchlist to keep track of what you want to watch."
                    )
                }
            }
            .navigationTitle("Watchlist")
            .navigationDestination(isPresented: $showDetail) {
                if let item = selectedItem {
                    MediaDetailView(mediaId: item.id)
                }
            }
        }
        .task {
            await viewModel.loadWatchlist()
        }
    }

    private var contentView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 24)
            ], spacing: 32) {
                ForEach(viewModel.sortedByAddedDate) { item in
                    if let media = item.media {
                        MediaCard(item: media, showProgress: false) {
                            selectedItem = media
                            showDetail = true
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await viewModel.removeFromWatchlist(item) }
                            } label: {
                                Label("Remove from Watchlist", systemImage: "bookmark.slash")
                            }
                        }
                    }
                }
            }
            .padding(48)
        }
    }
}

#Preview {
    WatchlistView()
}
