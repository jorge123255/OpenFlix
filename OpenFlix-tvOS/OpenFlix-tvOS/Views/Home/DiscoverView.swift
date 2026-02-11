import SwiftUI

// MARK: - Discover View
// Apple TV-inspired home screen with hero banner, Top 10, and content rows

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var showPlayer = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.onDeck.isEmpty && viewModel.featured.isEmpty {
                    LoadingView(message: "Loading your library...")
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.loadHomeContent() }
                    }
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
            await viewModel.loadHomeContent()
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let item = selectedItem {
                VideoPlayerView(mediaItem: item, startPosition: item.viewOffset)
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 40) {
                // Hero Banner
                if viewModel.hasFeatured {
                    HeroBannerView(
                        items: viewModel.featured,
                        onPlay: { item in
                            selectedItem = item
                            showPlayer = true
                        },
                        onDetails: { item in
                            selectedItem = item
                            showDetail = true
                        },
                        onWatchlist: { item in
                            Task {
                                await viewModel.toggleWatchlist(for: item)
                            }
                        }
                    )
                    .focusSection()
                }

                // Continue Watching
                if viewModel.hasContinueWatching {
                    ContinueWatchingSection(items: viewModel.onDeck) { item in
                        selectedItem = item
                        showPlayer = true
                    }
                    .focusSection()
                }

                // Top 10 in Your Library
                if viewModel.hasTopTen {
                    TopTenSection(items: viewModel.topTen) { item in
                        selectedItem = item
                        showDetail = true
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

                // Streaming Service Hubs (by studio)
                ForEach(viewModel.streamingServices) { service in
                    StreamingHubRow(
                        serviceName: service.name,
                        serviceIcon: service.icon,
                        items: service.items
                    ) { item in
                        selectedItem = item
                        showDetail = true
                    }
                    .focusSection()
                }

                // Hubs from server
                ForEach(viewModel.hubs) { hub in
                    HubSection(hub: hub) { item in
                        selectedItem = item
                        showDetail = true
                    }
                    .focusSection()
                }

                // Recommended For You
                if viewModel.hasRecommended {
                    FeaturedRow(title: "Recommended For You", items: viewModel.recommended) { item in
                        selectedItem = item
                        showDetail = true
                    }
                    .focusSection()
                }

                // Library sections (fallback when nothing else to show)
                if !viewModel.sections.isEmpty && viewModel.onDeck.isEmpty && viewModel.recentlyAdded.isEmpty && viewModel.hubs.isEmpty {
                    librarySectionsView
                        .focusSection()
                }

                // Empty state
                if viewModel.sections.isEmpty && viewModel.onDeck.isEmpty && viewModel.recentlyAdded.isEmpty && viewModel.hubs.isEmpty {
                    emptyStateView
                }

                // Bottom spacing
                Spacer().frame(height: 60)
            }
        }
        .background(OpenFlixColors.background)
    }

    // MARK: - Library Sections

    private var librarySectionsView: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Your Libraries", showChevron: false)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(viewModel.sections) { section in
                        LibrarySectionCard(section: section)
                    }
                }
                .padding(.horizontal, 48)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tv")
                .font(.system(size: 60))
                .foregroundColor(OpenFlixColors.textTertiary)

            Text("Welcome to OpenFlix")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(OpenFlixColors.textPrimary)

            Text("Your library is empty. Use the tabs above to browse Movies, TV Shows, or Live TV.")
                .font(.body)
                .foregroundColor(OpenFlixColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Library Section Card

struct LibrarySectionCard: View {
    let section: LibrarySection
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationLink(destination: destinationView) {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusLarge)
                        .fill(isFocused ? OpenFlixColors.accent.opacity(0.3) : OpenFlixColors.surfaceVariant)
                        .frame(width: 200, height: 120)

                    Image(systemName: section.type.icon)
                        .font(.system(size: 40))
                        .foregroundColor(isFocused ? OpenFlixColors.accent : OpenFlixColors.textSecondary)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusLarge)
                        .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 3)
                )

                Text(section.title)
                    .font(.headline)
                    .foregroundColor(isFocused ? OpenFlixColors.accent : OpenFlixColors.textPrimary)
            }
        }
        .buttonStyle(.card)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
    }

    @ViewBuilder
    private var destinationView: some View {
        switch section.type {
        case .movie:
            MoviesView()
        case .show:
            TVShowsHubView()
        default:
            MoviesView()
        }
    }
}

// MARK: - Legacy Featured Hero View (kept for compatibility)

struct FeaturedHeroView: View {
    let item: MediaItem
    var onPlay: () -> Void
    var onDetails: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            AsyncImage(url: artURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    Rectangle()
                        .fill(OpenFlixColors.surface)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 600)
            .clipped()

            // Gradient overlay
            OpenFlixColors.heroBottomGradient

            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text(item.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if let tagline = item.tagline {
                    Text(tagline)
                        .font(.headline)
                        .foregroundColor(OpenFlixColors.textSecondary)
                }

                HStack(spacing: 8) {
                    if let year = item.year {
                        Text(String(year))
                    }
                    if let rating = item.contentRating {
                        ContentRatingBadge(rating: rating, size: .small)
                    }
                    let duration = item.durationFormatted
                    if !duration.isEmpty {
                        Text(duration)
                    }
                }
                .font(.subheadline)
                .foregroundColor(OpenFlixColors.textSecondary)

                ActionButtonGroup(
                    playTitle: "Play",
                    onPlay: onPlay,
                    onMore: onDetails
                )
            }
            .padding(48)
        }
    }

    private var artURL: URL? {
        guard let art = item.art ?? item.thumb,
              let serverURL = UserDefaults.standard.serverURL else { return nil }
        return serverURL.appendingPathComponent(art)
    }
}

#Preview {
    DiscoverView()
}
