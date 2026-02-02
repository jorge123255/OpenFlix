import SwiftUI

// MARK: - Media Detail View
// Apple TV-inspired detail layout for movies and TV shows

struct MediaDetailView: View {
    let mediaId: Int

    @StateObject private var viewModel = MediaDetailViewModel()
    @State private var showPlayer = false
    @State private var selectedEpisode: MediaItem?
    @State private var showMoreOptions = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading details...")
            } else if let error = viewModel.error {
                ErrorView(message: error) {
                    Task { await viewModel.loadMedia(id: mediaId) }
                }
            } else if let item = viewModel.mediaItem {
                detailContent(item)
            } else {
                ErrorView(message: "Failed to load media details") {
                    Task { await viewModel.loadMedia(id: mediaId) }
                }
            }
        }
        .task {
            await viewModel.loadMedia(id: mediaId)
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let episode = selectedEpisode {
                VideoPlayerView(mediaItem: episode)
            } else if let item = viewModel.mediaItem, viewModel.canPlay {
                VideoPlayerView(mediaItem: item)
            }
        }
        .confirmationDialog("Options", isPresented: $showMoreOptions) {
            Button("Mark as Watched") {
                Task { await viewModel.markAsWatched() }
            }
            Button("Mark as Unwatched") {
                Task { await viewModel.markAsUnwatched() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ item: MediaItem) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section (70% height artwork)
                heroSection(item)

                // Content sections
                VStack(alignment: .leading, spacing: 40) {
                    // Summary
                    if let summary = item.summary {
                        Text(summary)
                            .font(.body)
                            .foregroundColor(OpenFlixColors.textSecondary)
                            .lineLimit(3)
                            .frame(maxWidth: 900, alignment: .leading)
                    }

                    // How to Watch section (for movies)
                    if item.type == .movie && viewModel.canPlay {
                        howToWatchSection(item)
                    }

                    // Seasons & Episodes (for TV shows)
                    if viewModel.hasSeasons {
                        seasonsSection
                    }

                    // Cast & Crew
                    if !item.roles.isEmpty {
                        castSection(item.roles)
                    }

                    // Related content
                    if !viewModel.relatedItems.isEmpty {
                        relatedSection
                    }

                    Spacer().frame(height: 48)
                }
                .padding(.horizontal, 80)
                .padding(.top, 32)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(OpenFlixColors.background)
    }

    // MARK: - Hero Section

    private func heroSection(_ item: MediaItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Full-screen artwork (70% height)
            AuthenticatedImage(
                path: item.art ?? item.thumb,
                systemPlaceholder: item.type == .movie ? "film" : "tv"
            )
            .aspectRatio(contentMode: .fill)
            .frame(height: 650)
            .clipped()

            // Side gradient overlay
            OpenFlixColors.sideGradient

            // Bottom gradient
            OpenFlixColors.heroBottomGradient

            // Content overlay
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Title
                Text(item.title)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
                    .lineLimit(2)

                Spacer().frame(height: 16)

                // Metadata row
                HStack(spacing: 12) {
                    // Media type icon
                    HStack(spacing: 6) {
                        Image(systemName: item.type == .movie ? "film" : "tv")
                            .font(.subheadline)
                        Text(item.type.displayName)
                            .font(.subheadline)
                    }
                    .foregroundColor(.white.opacity(0.9))

                    // Genres
                    if !item.genres.isEmpty {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))
                        Text(item.genres.prefix(2).joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // Content rating
                    if let rating = item.contentRating {
                        ContentRatingBadge(rating: rating, size: .medium)
                    }
                }

                Spacer().frame(height: 8)

                // Second metadata row
                HStack(spacing: 12) {
                    if let year = item.year {
                        Text(String(year))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    let duration = item.durationFormatted
                    if !duration.isEmpty {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))
                        Text(duration)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    if let resolution = item.resolution {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))
                        Text(resolution)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    if let audienceRating = item.audienceRating {
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

                Spacer().frame(height: 24)

                // Action buttons
                actionButtons(item)

                Spacer().frame(height: 48)
            }
            .padding(.horizontal, 80)
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(_ item: MediaItem) -> some View {
        ActionButtonGroup(
            playTitle: viewModel.playButtonTitle,
            isInWatchlist: viewModel.isInWatchlist,
            onPlay: {
                if viewModel.hasSeasons, let nextUp = viewModel.nextUpEpisode {
                    selectedEpisode = nextUp
                }
                showPlayer = true
            },
            onWatchlist: {
                Task { await viewModel.toggleWatchlist() }
            },
            onMore: {
                showMoreOptions = true
            }
        )
    }

    // MARK: - How to Watch Section

    private func howToWatchSection(_ item: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section divider with title
            HStack {
                Text("How to Watch")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(OpenFlixColors.textPrimary)

                Rectangle()
                    .fill(OpenFlixColors.textTertiary)
                    .frame(height: 1)
            }

            // Play option
            HowToWatchRow(
                icon: "play.fill",
                title: "Play Movie",
                subtitle: "In your library",
                onSelect: { showPlayer = true }
            )
        }
    }

    // MARK: - Cast Section

    private func castSection(_ roles: [CastMember]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section divider with title
            HStack {
                Text("Cast & Crew")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(OpenFlixColors.textPrimary)

                Rectangle()
                    .fill(OpenFlixColors.textTertiary)
                    .frame(height: 1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(roles.prefix(12)) { member in
                        CastMemberCard(member: member)
                    }
                }
            }
        }
    }

    // MARK: - Seasons Section

    private var seasonsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Season picker with diamond
            SeasonPicker(
                seasons: viewModel.seasons,
                selectedSeason: $viewModel.selectedSeason,
                onSeasonChange: { season in
                    Task { await viewModel.selectSeason(season) }
                }
            )

            // Episodes grid
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(viewModel.episodes) { episode in
                        EpisodeCard(episode: episode) {
                            selectedEpisode = episode
                            showPlayer = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Related Section

    private var relatedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Related", showChevron: true)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 24) {
                    ForEach(viewModel.relatedItems) { item in
                        MediaCard(item: item, showProgress: false)
                    }
                }
            }
        }
    }
}

// MARK: - Cast Member Card

struct CastMemberCard: View {
    let member: CastMember

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 12) {
                // Circular photo
                if member.thumb != nil {
                    AuthenticatedImage(path: member.thumb, systemPlaceholder: "person.circle.fill")
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(OpenFlixColors.surfaceElevated)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(member.name.prefix(1)).uppercased())
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(OpenFlixColors.textSecondary)
                        )
                }

                // Name
                Text(member.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isFocused ? OpenFlixColors.accent : OpenFlixColors.textPrimary)
                    .lineLimit(1)

                // Role
                if let role = member.role {
                    Text(role)
                        .font(.caption2)
                        .foregroundColor(OpenFlixColors.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: 120)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - How to Watch Row

struct HowToWatchRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var onSelect: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: { onSelect?() }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(OpenFlixColors.accent)
                    .frame(width: 44, height: 44)
                    .background(OpenFlixColors.surface)
                    .cornerRadius(8)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(OpenFlixColors.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(OpenFlixColors.textSecondary)
                }

                Spacer()

                // Subscribed badge
                Text("In Library")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(OpenFlixColors.textTertiary)
            }
            .padding(16)
            .background(isFocused ? OpenFlixColors.surfaceElevated : OpenFlixColors.surface)
            .cornerRadius(OpenFlixColors.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusMedium)
                    .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 3)
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Preview

#Preview {
    MediaDetailView(mediaId: 1)
}
