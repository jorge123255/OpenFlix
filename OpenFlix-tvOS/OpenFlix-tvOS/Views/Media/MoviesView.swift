import SwiftUI

// MARK: - Movies View
// Netflix/Apple TV+ style hub view with hero, carousels, and browse option

struct MoviesView: View {
    @StateObject private var viewModel = MoviesViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var showPlayer = false
    @State private var showGridBrowse = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && !viewModel.hasFeatured {
                    LoadingView(message: "Loading movies...")
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.loadMoviesHub() }
                    }
                } else if !viewModel.hasFeatured && viewModel.allMovies.isEmpty {
                    EmptyStateView(
                        icon: "film",
                        title: "No Movies",
                        message: "Your movie library is empty. Add some movies to get started."
                    )
                } else {
                    hubContentView
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showDetail) {
                if let item = selectedItem {
                    MediaDetailView(mediaId: item.id)
                }
            }
            .navigationDestination(isPresented: $showGridBrowse) {
                MoviesGridBrowseView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadMoviesHub()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let item = selectedItem {
                VideoPlayerView(mediaItem: item, startPosition: item.viewOffset)
            }
        }
    }

    // MARK: - Hub Content View

    private var hubContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 40) {
                // Hero Carousel Section with trailers
                if viewModel.hasFeaturedCarousel {
                    HeroCarouselView(
                        movies: viewModel.featuredMovies,
                        trailers: viewModel.trailers,
                        currentIndex: $viewModel.currentFeaturedIndex,
                        onPlay: { movie in
                            selectedItem = movie
                            showPlayer = true
                        },
                        onMoreInfo: { movie in
                            selectedItem = movie
                            showDetail = true
                        }
                    )
                    .focusSection()
                } else if let featured = viewModel.featuredItem {
                    // Fallback to single hero if carousel not available
                    MovieHeroSection(
                        item: featured,
                        onPlay: {
                            selectedItem = featured
                            showPlayer = true
                        },
                        onMoreInfo: {
                            selectedItem = featured
                            showDetail = true
                        }
                    )
                    .focusSection()
                }

                // Browse All Button
                BrowseAllButton(mediaType: "Movies") {
                    showGridBrowse = true
                }
                .focusSection()

                // Continue Watching
                if viewModel.hasContinueWatching {
                    MoviesContinueWatchingSection(items: viewModel.continueWatching) { item in
                        selectedItem = item
                        showPlayer = true
                    }
                    .focusSection()
                }

                // Recently Added
                if viewModel.hasRecentlyAdded {
                    RecentlyAddedSection(items: viewModel.recentlyAdded) { item in
                        selectedItem = item
                        showDetail = true
                    }
                    .focusSection()
                }

                // Genre Hubs
                ForEach(viewModel.genreHubs, id: \.genre) { hub in
                    GenreHubSection(genre: hub.genre, items: hub.items) { item in
                        selectedItem = item
                        showDetail = true
                    }
                    .focusSection()
                }

                // Bottom spacing
                Spacer().frame(height: 60)
            }
        }
        .background(OpenFlixColors.background)
    }
}

// MARK: - Movies Continue Watching Section
// Uses play icon in header

struct MoviesContinueWatchingSection: View {
    let items: [MediaItem]
    var onItemSelected: ((MediaItem) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with play icon
            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundColor(OpenFlixColors.accent)

                Text("Continue Watching")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(OpenFlixColors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(items) { item in
                        ContinueWatchingCard(item: item) {
                            onItemSelected?(item)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 10)
            }
        }
    }
}

// MARK: - Genre Hub Section

struct GenreHubSection: View {
    let genre: String
    let items: [MediaItem]
    var onItemSelected: ((MediaItem) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: genre, showChevron: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(items) { item in
                        MediaCard(item: item) {
                            onItemSelected?(item)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 10)
            }
        }
    }
}

// MARK: - Movies Grid Browse View
// Full grid browse with filters and sorting

struct MoviesGridBrowseView: View {
    @ObservedObject var viewModel: MoviesViewModel
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var showSortPicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Main content
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 32) {
                    // Header with back button
                    gridHeader

                    // Filter bar with genres and sort button (always show for sorting)
                    MovieFilterBar(
                        genres: viewModel.availableGenres,
                        selectedGenre: $viewModel.selectedGenre,
                        showSortPicker: $showSortPicker,
                        currentSort: viewModel.currentSort
                    )

                    // Genre browse tiles (when no filter selected)
                    if viewModel.selectedGenre == nil && !viewModel.availableGenres.isEmpty {
                        GenreBrowseSection(genres: viewModel.availableGenres) { genre in
                            viewModel.selectedGenre = genre
                        }
                        .focusSection()
                    }

                    // Selected genre header
                    if let genre = viewModel.selectedGenre {
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

            // Sort picker overlay
            if showSortPicker {
                SortPickerSheet(
                    isPresented: $showSortPicker,
                    selectedSort: Binding(
                        get: { viewModel.currentSort },
                        set: { viewModel.sortBy($0) }
                    )
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showDetail) {
            if let item = selectedItem {
                MediaDetailView(mediaId: item.id)
            }
        }
        .animation(.easeInOut(duration: OpenFlixColors.animationNormal), value: showSortPicker)
    }

    // MARK: - Grid Header

    private var gridHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.subheadline)
                .foregroundColor(OpenFlixColors.accent)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("All Movies")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            // Placeholder to balance the header layout
            Color.clear
                .frame(width: 60)
        }
        .padding(.horizontal, 50)
        .padding(.top, 40)
    }

    // MARK: - Selected Genre Header

    private func selectedGenreHeader(_ genre: String) -> some View {
        HStack {
            Button(action: { viewModel.selectedGenre = nil }) {
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
            ForEach(viewModel.filteredItems) { item in
                MediaCard(item: item) {
                    selectedItem = item
                    showDetail = true
                }
            }

            // Load more indicator
            if viewModel.hasMore && viewModel.selectedGenre == nil {
                ProgressView()
                    .onAppear {
                        Task { await viewModel.loadMoreGridItems() }
                    }
            }
        }
        .padding(.horizontal, 50)
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
    @State private var showSortPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
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

                // Sort picker overlay
                if showSortPicker {
                    SortPickerSheet(
                        isPresented: $showSortPicker,
                        selectedSort: Binding(
                            get: { viewModel.currentSort },
                            set: { viewModel.sortBy($0) }
                        )
                    )
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showDetail) {
                if let item = selectedItem {
                    MediaDetailView(mediaId: item.id)
                }
            }
            .animation(.easeInOut(duration: OpenFlixColors.animationNormal), value: showSortPicker)
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

                // Filter bar with genres and sort button (always show for sorting)
                MovieFilterBar(
                    genres: viewModel.availableGenres,
                    selectedGenre: $selectedGenre,
                    showSortPicker: $showSortPicker,
                    currentSort: viewModel.currentSort
                )

                // Genre browse tiles (when no filter selected and genres available)
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

            // Placeholder to balance the header layout
            Color.clear
                .frame(width: 100)
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
        return viewModel.items.filter { viewModel.getGenresForItem($0).contains(genre) }
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
    @Published var currentSort: SortOption = .addedDesc
    @Published var hasMore = false
    @Published var availableGenres: [String] = []

    // TMDB genre cache for items without server genres
    private var tmdbGenreCache: [Int: [String]] = [:]
    @Published var isLoadingTMDBGenres = false

    private var currentSectionId: Int?
    private var currentOffset = 0
    private let pageSize = 50
    private var currentMediaType: LibrarySectionType = .show

    func loadSections(type: LibrarySectionType) async {
        currentMediaType = type
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

        // Load TMDB genres in background
        Task {
            await loadTMDBGenresForItemsWithoutGenres()
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

    // MARK: - TMDB Genre Loading

    private func loadTMDBGenresForItemsWithoutGenres() async {
        let itemsWithoutGenres = items.filter { $0.genres.isEmpty }.prefix(30)

        guard !itemsWithoutGenres.isEmpty else {
            NSLog("MediaBrowseViewModel: All items have genres")
            return
        }

        isLoadingTMDBGenres = true
        defer { isLoadingTMDBGenres = false }

        NSLog("MediaBrowseViewModel: Loading TMDB genres for %d items", itemsWithoutGenres.count)

        await TMDBService.shared.reloadApiKey()

        await withTaskGroup(of: (Int, [String]).self) { group in
            for item in itemsWithoutGenres {
                group.addTask {
                    let genres = await self.fetchTMDBGenres(for: item)
                    return (item.id, genres)
                }
            }

            for await (itemId, genres) in group {
                if !genres.isEmpty {
                    tmdbGenreCache[itemId] = genres
                }
            }
        }

        NSLog("MediaBrowseViewModel: Loaded TMDB genres for %d items", tmdbGenreCache.count)

        extractGenresWithTMDB()
    }

    private func fetchTMDBGenres(for item: MediaItem) async -> [String] {
        // For TV shows, we'd need a different TMDB endpoint
        // For now, try the movie endpoint (works for some content)
        guard let info = await TMDBService.shared.getMovieDetails(title: item.title, year: item.year) else {
            return []
        }
        return info.genres
    }

    // MARK: - Genre Extraction

    private func extractGenres() {
        var genreSet = Set<String>()
        for item in items {
            for genre in item.genres {
                genreSet.insert(genre)
            }
        }
        availableGenres = genreSet.sorted()
    }

    private func extractGenresWithTMDB() {
        var genreSet = Set<String>()

        for item in items {
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
        NSLog("MediaBrowseViewModel: Extracted %d genres (including TMDB)", availableGenres.count)
    }

    /// Get genres for an item (server or TMDB fallback)
    func getGenresForItem(_ item: MediaItem) -> [String] {
        if !item.genres.isEmpty {
            return item.genres
        }
        return tmdbGenreCache[item.id] ?? []
    }
}

// MARK: - Sort Option

enum SortOption: String, CaseIterable {
    case addedDesc = "addedAt:desc"
    case titleAsc = "title:asc"
    case titleDesc = "title:desc"
    case yearDesc = "year:desc"
    case yearAsc = "year:asc"
    case ratingDesc = "audienceRating:desc"
    case durationAsc = "duration:asc"
    case durationDesc = "duration:desc"

    var displayName: String {
        switch self {
        case .addedDesc: return "Recently Added"
        case .titleAsc: return "Title A-Z"
        case .titleDesc: return "Title Z-A"
        case .yearDesc: return "Newest First"
        case .yearAsc: return "Oldest First"
        case .ratingDesc: return "Top Rated"
        case .durationAsc: return "Shortest"
        case .durationDesc: return "Longest"
        }
    }

    var icon: String {
        switch self {
        case .addedDesc: return "clock.fill"
        case .titleAsc, .titleDesc: return "textformat.abc"
        case .yearDesc, .yearAsc: return "calendar"
        case .ratingDesc: return "star.fill"
        case .durationAsc, .durationDesc: return "timer"
        }
    }

    var sortKey: String {
        rawValue
    }
}

#Preview {
    MoviesView()
}
