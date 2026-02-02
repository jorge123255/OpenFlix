import SwiftUI

// MARK: - Search View
// Apple TV-style search with genre grid landing

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @FocusState private var focusedSection: SearchSection?

    enum SearchSection: Hashable {
        case genres
        case searchField
        case results
    }

    // Common genres for browse
    private let browseGenres = [
        "Action", "Comedy", "Drama", "Sci-Fi",
        "Horror", "Romance", "Thriller", "Animation",
        "Documentary", "Kids", "Music", "Sports"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field at top
                searchField
                    .focused($focusedSection, equals: .searchField)
                    .padding(.top, 24)

                // Results or genre grid
                if viewModel.hasResults {
                    resultsContent
                        .focusSection()
                        .focused($focusedSection, equals: .results)
                } else if !viewModel.query.isEmpty && !viewModel.isSearching {
                    noResultsView
                } else {
                    // Genre browse grid when idle
                    genreGridView
                        .focusSection()
                        .focused($focusedSection, equals: .genres)
                }
            }
            .navigationTitle("Search")
            .navigationDestination(isPresented: $showDetail) {
                if let item = selectedItem {
                    MediaDetailView(mediaId: item.id)
                }
            }
            .background(OpenFlixColors.background)
        }
        .onChange(of: viewModel.query) { _ in
            Task { await viewModel.search() }
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.title3)
                .foregroundColor(OpenFlixColors.textTertiary)

            TextField("Search Movies, Shows, and More", text: $viewModel.query)
                .textFieldStyle(.plain)
                .font(.title3)
                .foregroundColor(OpenFlixColors.textPrimary)
                .onSubmit {
                    Task { await viewModel.search() }
                }

            if !viewModel.query.isEmpty {
                Button(action: { viewModel.clearSearch() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(OpenFlixColors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            if viewModel.isSearching {
                ProgressView()
                    .tint(OpenFlixColors.accent)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(OpenFlixColors.surface)
        .cornerRadius(OpenFlixColors.cornerRadiusMedium)
        .padding(.horizontal, 48)
    }

    // MARK: - Genre Grid View

    private var genreGridView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Title
                Text("Browse by Genre")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(OpenFlixColors.textPrimary)
                    .padding(.horizontal, 48)

                // Genre grid
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 180, maximum: 200), spacing: 16)
                ], spacing: 16) {
                    ForEach(browseGenres, id: \.self) { genre in
                        GenreTile(genre: genre) {
                            viewModel.query = genre
                        }
                    }
                }
                .padding(.horizontal, 48)

                Spacer().frame(height: 48)
            }
            .padding(.top, 32)
        }
    }

    // MARK: - Results Content

    private var resultsContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 32) {
                ForEach(viewModel.results) { hub in
                    if !hub.items.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: hub.title, showChevron: false)

                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 24) {
                                    ForEach(hub.items) { item in
                                        MediaCard(item: item, showProgress: false) {
                                            selectedItem = item
                                            showDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 48)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(OpenFlixColors.textTertiary)

            Text("No Results Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(OpenFlixColors.textPrimary)

            Text("Try a different search term or browse by genre")
                .font(.body)
                .foregroundColor(OpenFlixColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 100)
    }
}

#Preview {
    SearchView()
}
