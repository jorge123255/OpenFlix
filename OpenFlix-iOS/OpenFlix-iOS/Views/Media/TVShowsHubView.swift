import SwiftUI

// MARK: - TV Shows Hub View
// Netflix/Apple TV+ style hub view with hero, carousels, and browse option

struct TVShowsHubView: View {
    @StateObject private var viewModel = TVShowsViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var showPlayer = false
    @State private var showGridBrowse = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.featuredShows.isEmpty && viewModel.allShows.isEmpty {
                    LoadingView(message: "Loading TV shows...")
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.loadTVShowsHub() }
                    }
                } else if viewModel.featuredShows.isEmpty && viewModel.allShows.isEmpty {
                    EmptyStateView(
                        icon: "tv",
                        title: "No TV Shows",
                        message: "Your TV show library is empty. Add some shows to get started."
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
                TVShowsGridBrowseView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadTVShowsHub()
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
                // Hero Section
                if viewModel.hasFeaturedCarousel {
                    TVShowHeroSection(
                        shows: viewModel.featuredShows,
                        currentIndex: $viewModel.currentFeaturedIndex,
                        onPlay: { show in
                            selectedItem = show
                            showDetail = true  // Go to detail for TV shows to pick episode
                        },
                        onMoreInfo: { show in
                            selectedItem = show
                            showDetail = true
                        }
                    )
                    .focusSection()
                }

                // Browse All Button
                BrowseAllButton(mediaType: "TV Shows") {
                    showGridBrowse = true
                }
                .focusSection()

                // Continue Watching
                if viewModel.hasContinueWatching {
                    TVContinueWatchingSection(items: viewModel.continueWatching) { item in
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

// MARK: - TV Show Hero Section

struct TVShowHeroSection: View {
    let shows: [MediaItem]
    @Binding var currentIndex: Int
    var onPlay: (MediaItem) -> Void
    var onMoreInfo: (MediaItem) -> Void

    @FocusState private var focusedButton: HeroButton?

    enum HeroButton: Hashable {
        case play, info
    }

    private let heroHeight: CGFloat = 500

    private var currentShow: MediaItem? {
        guard currentIndex < shows.count else { return nil }
        return shows[currentIndex]
    }

    var body: some View {
        if let show = currentShow {
            ZStack(alignment: .bottomLeading) {
                // Backdrop image
                AuthenticatedImage(
                    path: show.art ?? show.thumb,
                    systemPlaceholder: "tv"
                )
                .aspectRatio(contentMode: .fill)
                .frame(height: heroHeight)
                .clipped()

                // Gradients
                LinearGradient(
                    colors: [
                        OpenFlixColors.background,
                        OpenFlixColors.background.opacity(0.8),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 800)

                LinearGradient(
                    colors: [.clear, OpenFlixColors.background.opacity(0.9), OpenFlixColors.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: heroHeight * 0.5)
                .offset(y: heroHeight * 0.5)

                // Content overlay
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    // TV SHOWS badge
                    HStack(spacing: 8) {
                        Image(systemName: "tv.fill")
                            .font(.caption)
                        Text("TV SHOWS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(2)
                    }
                    .foregroundColor(OpenFlixColors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(OpenFlixColors.accent.opacity(0.2))
                    .cornerRadius(4)

                    Spacer().frame(height: 16)

                    // Title
                    Text(show.title)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                        .lineLimit(2)

                    Spacer().frame(height: 12)

                    // Metadata
                    HStack(spacing: 12) {
                        if let year = show.year {
                            Text(String(year))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        if let rating = show.contentRating {
                            ContentRatingBadge(rating: rating, size: .medium)
                        }

                        if let seasons = show.childCount, seasons > 0 {
                            Text("·")
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(seasons) Season\(seasons > 1 ? "s" : "")")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        if let audienceRating = show.audienceRating {
                            Text("·")
                                .foregroundColor(.white.opacity(0.6))
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", audienceRating))
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                        }
                    }

                    Spacer().frame(height: 16)

                    // Summary
                    if let summary = show.summary {
                        Text(summary)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                            .frame(maxWidth: 600, alignment: .leading)
                    }

                    Spacer().frame(height: 24)

                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: { onPlay(show) }) {
                            Label("Watch Now", systemImage: "play.fill")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 36)
                                .padding(.vertical, 18)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.card)
                        .focused($focusedButton, equals: .play)
                        .scaleEffect(focusedButton == .play ? 1.05 : 1.0)
                        .shadow(color: focusedButton == .play ? .white.opacity(0.3) : .clear, radius: 10)
                        .animation(.easeInOut(duration: 0.15), value: focusedButton)

                        Button(action: { onMoreInfo(show) }) {
                            Label("More Info", systemImage: "info.circle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 18)
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.card)
                        .focused($focusedButton, equals: .info)
                        .scaleEffect(focusedButton == .info ? 1.05 : 1.0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedButton == .info ? Color.white : .clear, lineWidth: 2)
                        )
                        .animation(.easeInOut(duration: 0.15), value: focusedButton)
                    }

                    // Page indicators
                    if shows.count > 1 {
                        Spacer().frame(height: 20)
                        HStack(spacing: 8) {
                            ForEach(0..<shows.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 80)
            }
            .frame(height: heroHeight)
        }
    }
}

// MARK: - TV Continue Watching Section

struct TVContinueWatchingSection: View {
    let items: [MediaItem]
    var onItemSelected: ((MediaItem) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                        TVEpisodeCard(item: item) {
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

// MARK: - TV Episode Card (for continue watching)

struct TVEpisodeCard: View {
    let item: MediaItem
    var onSelect: (() -> Void)?

    @FocusState private var isFocused: Bool

    private let cardWidth: CGFloat = 400
    private let cardHeight: CGFloat = 225

    var body: some View {
        Button(action: { onSelect?() }) {
            ZStack(alignment: .bottom) {
                // Thumbnail
                AuthenticatedImage(
                    path: item.thumb ?? item.grandparentThumb,
                    systemPlaceholder: "tv"
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: cardWidth, height: cardHeight)
                .clipped()

                // Gradient
                LinearGradient(
                    colors: [.clear, .black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: cardHeight * 0.6)

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Spacer()

                    // Show title
                    Text(item.grandparentTitle ?? item.parentTitle ?? "")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)

                    // Episode title
                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    // Episode info
                    HStack {
                        if let seasonNum = item.parentIndex, let episodeNum = item.index {
                            Text("S\(seasonNum) E\(episodeNum)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        if let duration = item.duration, let offset = item.viewOffset {
                            Text("·")
                                .foregroundColor(.white.opacity(0.5))
                            let remaining = duration - offset
                            Text(String.formatDuration(milliseconds: remaining) + " left")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(OpenFlixColors.progressBackground)
                            Rectangle()
                                .fill(OpenFlixColors.progressFill)
                                .frame(width: geometry.size.width * item.progressPercent)
                        }
                    }
                    .frame(height: 4)
                    .cornerRadius(2)
                }
                .padding(16)

                // Play icon
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(isFocused ? 1.0 : 0.8))
                    .shadow(color: .black.opacity(0.5), radius: 8)
                    .offset(y: -40)
            }
            .frame(width: cardWidth, height: cardHeight)
            .cornerRadius(OpenFlixColors.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusMedium)
                    .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 4)
            )
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .shadow(color: isFocused ? OpenFlixColors.accentGlow : .clear, radius: 12)
            .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - TV Shows Grid Browse View

struct TVShowsGridBrowseView: View {
    @ObservedObject var viewModel: TVShowsViewModel
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var showSortPicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 32) {
                    // Header
                    gridHeader

                    // Filter bar
                    MovieFilterBar(
                        genres: viewModel.availableGenres,
                        selectedGenre: $viewModel.selectedGenre,
                        showSortPicker: $showSortPicker,
                        currentSort: viewModel.currentSort
                    )

                    // Genre browse tiles
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

            Text("All TV Shows")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 50)
        .padding(.top, 40)
    }

    private func selectedGenreHeader(_ genre: String) -> some View {
        HStack {
            Button(action: { viewModel.selectedGenre = nil }) {
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
        }
        .padding(.horizontal, 50)
    }

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

#Preview {
    TVShowsHubView()
}
