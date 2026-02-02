import SwiftUI

// MARK: - Movies View
// Apple TV-style browse view with genre tiles and content rows

struct MoviesView: View {
    @StateObject private var viewModel = MediaBrowseViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var selectedGenre: String? = nil

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.loadItems() }
                    }
                } else if viewModel.items.isEmpty {
                    EmptyStateView(
                        icon: "film",
                        title: "No Movies",
                        message: "Your movie library is empty. Add some movies to get started."
                    )
                } else {
                    contentView
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showDetail) {
                if let item = selectedItem {
                    MediaDetailView(mediaId: item.id)
                }
            }
        }
        .task {
            await viewModel.loadSections(type: .movie)
        }
    }

    private var contentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 32) {
                // Page title
                Text("Movies")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.top, 40)

                // Filter bar at top
                if !viewModel.availableGenres.isEmpty && selectedGenre == nil {
                    filterChips
                }

                // Genre browse tiles (when no filter selected)
                if selectedGenre == nil && !viewModel.availableGenres.isEmpty {
                    GenreBrowseSection(genres: viewModel.availableGenres) { genre in
                        selectedGenre = genre
                    }
                    .focusSection()
                }

                // Selected genre header with back button
                if let genre = selectedGenre {
                    selectedGenreHeader(genre)
                }

                // Content grid
                contentGrid
                    .focusSection()

                // Bottom spacing
                Spacer().frame(height: 60)
            }
        }
        .background(OpenFlixColors.background)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All button
                SimpleFilterChip(title: "All", isSelected: selectedGenre == nil) {
                    selectedGenre = nil
                }

                // Genre chips
                ForEach(viewModel.availableGenres.prefix(8), id: \.self) { genre in
                    SimpleFilterChip(title: genre, isSelected: selectedGenre == genre) {
                        selectedGenre = genre
                    }
                }
            }
            .padding(.horizontal, 50)
        }
    }

    // MARK: - Selected Genre Header

    private func selectedGenreHeader(_ genre: String) -> some View {
        HStack {
            Button(action: { selectedGenre = nil }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("All Movies")
                }
                .font(.subheadline)
                .foregroundColor(OpenFlixColors.accent)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(genre)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(OpenFlixColors.textPrimary)

            Spacer()

            // Sort menu
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.displayName) {
                        viewModel.sortBy(option)
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
                    .foregroundColor(OpenFlixColors.textSecondary)
            }
        }
        .padding(.horizontal, 50)
    }

    // MARK: - Content Grid

    private var contentGrid: some View {
        LazyVGrid(columns: [
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24)
        ], spacing: 40) {
            ForEach(filteredItems) { item in
                MediaCard(item: item) {
                    selectedItem = item
                    showDetail = true
                }
            }

            // Load more indicator
            if viewModel.hasMore && selectedGenre == nil {
                ProgressView()
                    .onAppear {
                        Task { await viewModel.loadMore() }
                    }
            }
        }
        .padding(.horizontal, 50)
    }

    private var filteredItems: [MediaItem] {
        guard let genre = selectedGenre else { return viewModel.items }
        return viewModel.items.filter { $0.genres.contains(genre) }
    }
}

// MARK: - Simple Filter Chip (for browse views)

struct SimpleFilterChip: View {
    let title: String
    let isSelected: Bool
    var onSelect: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: { onSelect?() }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? OpenFlixColors.buttonPrimaryText : OpenFlixColors.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? OpenFlixColors.accent : OpenFlixColors.surface)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isFocused ? Color.white : .clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
    }
}

// MARK: - TV Shows View

struct TVShowsView: View {
    @StateObject private var viewModel = MediaBrowseViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var selectedGenre: String? = nil

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.loadItems() }
                    }
                } else if viewModel.items.isEmpty {
                    EmptyStateView(
                        icon: "tv",
                        title: "No TV Shows",
                        message: "Your TV show library is empty."
                    )
                } else {
                    tvContentView
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showDetail) {
                if let item = selectedItem {
                    MediaDetailView(mediaId: item.id)
                }
            }
        }
        .task {
            await viewModel.loadSections(type: .show)
        }
    }

    private var tvContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 32) {
                // Page title
                Text("TV Shows")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.top, 40)

                // Filter bar at top
                if !viewModel.availableGenres.isEmpty && selectedGenre == nil {
                    tvFilterChips
                }

                // Genre browse tiles (when no filter selected)
                if selectedGenre == nil && !viewModel.availableGenres.isEmpty {
                    GenreBrowseSection(genres: viewModel.availableGenres) { genre in
                        selectedGenre = genre
                    }
                    .focusSection()
                }

                // Selected genre header with back button
                if let genre = selectedGenre {
                    tvSelectedGenreHeader(genre)
                }

                // Content grid
                tvContentGrid
                    .focusSection()

                // Bottom spacing
                Spacer().frame(height: 60)
            }
        }
        .background(OpenFlixColors.background)
    }

    // MARK: - Filter Chips

    private var tvFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                SimpleFilterChip(title: "All", isSelected: selectedGenre == nil) {
                    selectedGenre = nil
                }

                ForEach(viewModel.availableGenres.prefix(8), id: \.self) { genre in
                    SimpleFilterChip(title: genre, isSelected: selectedGenre == genre) {
                        selectedGenre = genre
                    }
                }
            }
            .padding(.horizontal, 50)
        }
    }

    // MARK: - Selected Genre Header

    private func tvSelectedGenreHeader(_ genre: String) -> some View {
        HStack {
            Button(action: { selectedGenre = nil }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("All TV Shows")
                }
                .font(.subheadline)
                .foregroundColor(OpenFlixColors.accent)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(genre)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(OpenFlixColors.textPrimary)

            Spacer()

            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.displayName) {
                        viewModel.sortBy(option)
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
                    .foregroundColor(OpenFlixColors.textSecondary)
            }
        }
        .padding(.horizontal, 50)
    }

    // MARK: - Content Grid

    private var tvContentGrid: some View {
        LazyVGrid(columns: [
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24),
            GridItem(.fixed(200), spacing: 24)
        ], spacing: 40) {
            ForEach(tvFilteredItems) { item in
                MediaCard(item: item) {
                    selectedItem = item
                    showDetail = true
                }
            }

            if viewModel.hasMore && selectedGenre == nil {
                ProgressView()
                    .onAppear {
                        Task { await viewModel.loadMore() }
                    }
            }
        }
        .padding(.horizontal, 50)
    }

    private var tvFilteredItems: [MediaItem] {
        guard let genre = selectedGenre else { return viewModel.items }
        return viewModel.items.filter { $0.genres.contains(genre) }
    }
}

// MARK: - Browse ViewModel

@MainActor
class MediaBrowseViewModel: ObservableObject {
    private let mediaRepository = MediaRepository()

    @Published var sections: [LibrarySection] = []
    @Published var items: [MediaItem] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentSort: SortOption = .titleAsc
    @Published var hasMore = false
    @Published var availableGenres: [String] = []

    private var currentSectionId: Int?
    private var currentOffset = 0
    private let pageSize = 50

    func loadSections(type: LibrarySectionType) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let allSections = try await mediaRepository.getLibrarySections()
            sections = allSections.filter { $0.type == type }

            if let firstSection = sections.first {
                currentSectionId = firstSection.id
                await loadItems()
            }
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadItems() async {
        guard let sectionId = currentSectionId else { return }

        isLoading = items.isEmpty
        currentOffset = 0

        do {
            let result = try await mediaRepository.getLibraryItems(
                sectionId: sectionId,
                start: 0,
                size: pageSize,
                sort: currentSort.sortKey
            )
            items = result.items
            hasMore = result.items.count < result.totalSize

            extractGenres()
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard let sectionId = currentSectionId, hasMore else { return }

        currentOffset += pageSize

        do {
            let result = try await mediaRepository.getLibraryItems(
                sectionId: sectionId,
                start: currentOffset,
                size: pageSize,
                sort: currentSort.sortKey
            )
            items.append(contentsOf: result.items)
            hasMore = currentOffset + result.items.count < result.totalSize

            extractGenres()
        } catch {
            // Silently fail on load more
        }
    }

    func sortBy(_ option: SortOption) {
        currentSort = option
        Task {
            await loadItems()
        }
    }

    private func extractGenres() {
        var genreSet = Set<String>()
        for item in items {
            for genre in item.genres {
                genreSet.insert(genre)
            }
        }
        availableGenres = genreSet.sorted()
    }
}

// MARK: - Sort Option

enum SortOption: String, CaseIterable {
    case titleAsc = "title:asc"
    case titleDesc = "title:desc"
    case yearAsc = "year:asc"
    case yearDesc = "year:desc"
    case addedDesc = "addedAt:desc"
    case ratingDesc = "audienceRating:desc"

    var displayName: String {
        switch self {
        case .titleAsc: return "Title (A-Z)"
        case .titleDesc: return "Title (Z-A)"
        case .yearAsc: return "Year (Old-New)"
        case .yearDesc: return "Year (New-Old)"
        case .addedDesc: return "Recently Added"
        case .ratingDesc: return "Highest Rated"
        }
    }

    var sortKey: String {
        rawValue
    }
}

#Preview {
    MoviesView()
}
