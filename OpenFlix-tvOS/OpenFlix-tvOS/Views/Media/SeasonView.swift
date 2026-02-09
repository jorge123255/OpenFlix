import SwiftUI

// MARK: - Season View
// Episode picker for TV shows

struct SeasonView: View {
    let show: MediaItem
    let seasons: [MediaItem]
    @State private var selectedSeason: MediaItem?
    @State private var episodes: [MediaItem] = []
    @State private var selectedEpisode: MediaItem?
    @State private var showPlayer = false
    @State private var isLoading = false

    @FocusState private var focusedEpisodeId: Int?

    private let mediaRepository = MediaRepository()

    var body: some View {
        HStack(spacing: 0) {
            // Season list (left side)
            seasonList
                .frame(width: 300)
                .background(OpenFlixColors.surface)

            // Episode list (right side)
            episodeList
        }
        .background(OpenFlixColors.background)
        .task {
            if let first = seasons.first {
                await selectSeason(first)
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let episode = selectedEpisode {
                VideoPlayerView(
                    mediaItem: episode,
                    liveChannelURL: nil,
                    recordingURL: nil,
                    startPosition: episode.viewOffset
                )
            }
        }
    }

    // MARK: - Season List

    private var seasonList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Seasons")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

            Divider()
                .background(OpenFlixColors.textTertiary)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(seasons) { season in
                        SeasonRow(
                            season: season,
                            isSelected: selectedSeason?.id == season.id
                        ) {
                            Task { await selectSeason(season) }
                        }
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Episode List

    private var episodeList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            if let season = selectedSeason {
                VStack(alignment: .leading, spacing: 8) {
                    Text(season.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(episodes.count) Episodes")
                        .font(.system(size: 18))
                        .foregroundColor(OpenFlixColors.textSecondary)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
            }

            Divider()
                .background(OpenFlixColors.textTertiary)

            // Episodes
            if isLoading {
                Spacer()
                ProgressView()
                    .tint(OpenFlixColors.primary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(episodes) { episode in
                            EpisodeRow(episode: episode) {
                                selectedEpisode = episode
                                showPlayer = true
                            }
                            .focused($focusedEpisodeId, equals: episode.id)
                        }
                    }
                    .padding(24)
                }
            }
        }
    }

    // MARK: - Helpers

    private func selectSeason(_ season: MediaItem) async {
        selectedSeason = season
        isLoading = true

        do {
            episodes = try await mediaRepository.getMediaChildren(id: season.id)
            if let first = episodes.first {
                focusedEpisodeId = first.id
            }
        } catch {
            episodes = []
        }

        isLoading = false
    }
}

// MARK: - Season Row

struct SeasonRow: View {
    let season: MediaItem
    let isSelected: Bool
    let onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Thumbnail
                if let thumb = season.thumb {
                    AuthenticatedImage(path: thumb, systemPlaceholder: "tv")
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 50)
                        .cornerRadius(6)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(season.title)
                        .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                        .foregroundColor(.white)

                    if let count = season.childCount {
                        Text("\(count) episodes")
                            .font(.system(size: 14))
                            .foregroundColor(OpenFlixColors.textSecondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(OpenFlixColors.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? OpenFlixColors.primary.opacity(0.2) : (isFocused ? OpenFlixColors.surfaceVariant : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? OpenFlixColors.primary : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.card)
        .focused($isFocused)
        .padding(.horizontal, 12)
    }
}

// MARK: - Episode Row

struct EpisodeRow: View {
    let episode: MediaItem
    let onSelect: () -> Void

    @FocusState private var isFocused: Bool

    private var progress: Double {
        guard let duration = episode.duration, duration > 0,
              let offset = episode.viewOffset else { return 0 }
        return Double(offset) / Double(duration)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 20) {
                // Thumbnail with overlay
                ZStack(alignment: .bottomLeading) {
                    AuthenticatedImage(
                        path: episode.thumb,
                        systemPlaceholder: "play.rectangle"
                    )
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 200, height: 112)
                    .clipped()
                    .cornerRadius(8)

                    // Progress bar
                    if progress > 0 {
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                    Rectangle()
                                        .fill(OpenFlixColors.primary)
                                        .frame(width: geo.size.width * progress)
                                }
                                .frame(height: 4)
                            }
                        }
                        .frame(width: 200, height: 112)
                    }

                    // Duration badge
                    if !episode.durationFormatted.isEmpty {
                        Text(episode.durationFormatted)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                            .padding(8)
                    }
                }

                // Episode info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let episodeNum = episode.index {
                            Text("E\(episodeNum)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(OpenFlixColors.primary)
                        }

                        Text(episode.title)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    if let summary = episode.summary {
                        Text(summary)
                            .font(.system(size: 16))
                            .foregroundColor(OpenFlixColors.textSecondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 12) {
                        if let date = episode.originallyAvailableAt {
                            Text(date)
                                .font(.system(size: 14))
                                .foregroundColor(OpenFlixColors.textTertiary)
                        }

                        if let rating = episode.contentRating {
                            Text(rating)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(OpenFlixColors.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(OpenFlixColors.surfaceVariant)
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                // Play button hint
                if isFocused {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(OpenFlixColors.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? OpenFlixColors.surfaceVariant : OpenFlixColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? OpenFlixColors.primary : .clear, lineWidth: 3)
            )
            .scaleEffect(isFocused ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

#Preview {
    SeasonView(
        show: MediaItem(
            id: 1,
            key: "/library/metadata/1",
            guid: nil,
            type: .show,
            title: "Breaking Bad",
            originalTitle: nil,
            tagline: nil,
            summary: "A high school chemistry teacher turned meth manufacturer.",
            thumb: nil,
            art: nil,
            banner: nil,
            year: 2008,
            duration: nil,
            viewOffset: nil,
            viewCount: nil,
            contentRating: "TV-MA",
            audienceRating: 9.5,
            rating: nil,
            studio: nil,
            addedAt: nil,
            originallyAvailableAt: nil,
            leafCount: 62,
            viewedLeafCount: 0,
            childCount: 5,
            index: nil,
            parentIndex: nil,
            parentRatingKey: nil,
            parentTitle: nil,
            grandparentRatingKey: nil,
            grandparentTitle: nil,
            grandparentThumb: nil,
            genres: [],
            roles: [],
            directors: [],
            writers: [],
            countries: [],
            mediaVersions: []
        ),
        seasons: []
    )
}
