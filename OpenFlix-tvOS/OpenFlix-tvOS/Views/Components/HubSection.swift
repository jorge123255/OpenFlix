import SwiftUI

// MARK: - Hub Section
// Generic section for displaying media hubs from server

struct HubSection: View {
    let hub: Hub
    var onItemSelected: ((MediaItem) -> Void)?
    var onSeeAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with chevron
            SectionHeader(
                title: hub.title,
                showChevron: hub.more,
                onSeeAll: onSeeAll
            )

            // Content - Horizontal scroll with cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(hub.items) { item in
                        MediaCard(item: item) {
                            onItemSelected?(item)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 10) // Give room for focus scale
            }
        }
    }
}

// MARK: - Continue Watching Section
// Apple TV-style wide cards with overlay info

struct ContinueWatchingSection: View {
    let items: [MediaItem]
    var onItemSelected: ((MediaItem) -> Void)?
    var onSeeAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(
                title: "Continue Watching",
                showChevron: true,
                onSeeAll: onSeeAll
            )

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

// MARK: - Continue Watching Card
// Wide landscape card with progress bar and overlay info

struct ContinueWatchingCard: View {
    let item: MediaItem
    var onSelect: (() -> Void)?

    @FocusState private var isFocused: Bool

    private let cardWidth: CGFloat = 450
    private let cardHeight: CGFloat = 253  // 16:9 aspect ratio

    var body: some View {
        Button(action: { onSelect?() }) {
            ZStack(alignment: .bottom) {
                // Thumbnail
                AuthenticatedImage(
                    path: item.bestThumb ?? item.art,
                    systemPlaceholder: "play.rectangle"
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: cardWidth, height: cardHeight)
                .clipped()

                // Gradient overlay at bottom
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: cardHeight * 0.5)

                // Content overlay
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()

                    // Episode info or title
                    if item.type == .episode {
                        Text(item.grandparentTitle ?? item.parentTitle ?? "")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)

                        Text(item.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        // Season/Episode info with remaining time
                        HStack {
                            if let seasonNum = item.parentIndex, let episodeNum = item.index {
                                Text("S\(seasonNum), E\(episodeNum)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Text("·")
                                .foregroundColor(.white.opacity(0.5))

                            Text(remainingTime)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    } else {
                        // Movie
                        Text(item.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(remainingTime)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    // Progress bar at very bottom
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

                // Play button overlay (centered)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(isFocused ? 1.0 : 0.8))
                    .shadow(color: .black.opacity(0.5), radius: 8)
                    .offset(y: -30)  // Offset up from center
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

    private var remainingTime: String {
        guard let duration = item.duration,
              let offset = item.viewOffset else {
            return item.durationFormatted
        }
        let remaining = duration - offset
        return String.formatDuration(milliseconds: remaining) + " remaining"
    }
}

// MARK: - Recently Added Section

struct RecentlyAddedSection: View {
    let items: [MediaItem]
    var onItemSelected: ((MediaItem) -> Void)?
    var onSeeAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(
                title: "Recently Added",
                showChevron: true,
                onSeeAll: onSeeAll
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(items) { item in
                        MediaCard(item: item, showProgress: false) {
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

// MARK: - Top 10 Section
// Numbered ranking cards

struct TopTenSection: View {
    let items: [MediaItem]
    var onItemSelected: ((MediaItem) -> Void)?
    var onSeeAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(
                title: "Top 10 in Your Library",
                showChevron: true,
                onSeeAll: onSeeAll
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(items.prefix(10).enumerated()), id: \.element.id) { index, item in
                        VStack(alignment: .leading, spacing: 8) {
                            TopTenCard(
                                item: item,
                                rank: index + 1,
                                onSelect: { onItemSelected?(item) }
                            )

                            // Genre label below
                            if let genre = item.genres.first {
                                Text(genre)
                                    .font(.caption)
                                    .foregroundColor(OpenFlixColors.textSecondary)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 10)
            }
        }
    }
}

// MARK: - Genre Browse Section
// Horizontal row of genre tiles

struct GenreBrowseSection: View {
    let genres: [String]
    var onGenreSelected: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(
                title: "Browse by Genre",
                showChevron: true
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(genres, id: \.self) { genre in
                        GenreTile(genre: genre) {
                            onGenreSelected?(genre)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 10)
            }
        }
    }
}

// MARK: - Movie Hero Section
// Full-width hero section for Movies hub page

struct MovieHeroSection: View {
    let item: MediaItem
    var onPlay: () -> Void
    var onMoreInfo: () -> Void

    @FocusState private var focusedButton: HeroButton?

    enum HeroButton: Hashable {
        case play, info
    }

    private let heroHeight: CGFloat = 480

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Full-width backdrop image
            AuthenticatedImage(
                path: item.art ?? item.thumb,
                systemPlaceholder: "film"
            )
            .aspectRatio(contentMode: .fill)
            .frame(height: heroHeight)
            .clipped()

            // Horizontal gradient (left side)
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

            // Vertical gradient (bottom)
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

                // MOVIES badge
                HStack(spacing: 8) {
                    Image(systemName: "film.fill")
                        .font(.caption)
                    Text("MOVIES")
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
                Text(item.title)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
                    .lineLimit(2)

                Spacer().frame(height: 12)

                // Metadata row
                HStack(spacing: 12) {
                    if let year = item.year {
                        Text(String(year))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    if let rating = item.contentRating {
                        ContentRatingBadge(rating: rating, size: .medium)
                    }

                    let duration = item.durationFormatted
                    if !duration.isEmpty {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))
                        Text(duration)
                            .font(.subheadline)
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

                Spacer().frame(height: 16)

                // Summary (2 lines max)
                if let summary = item.summary {
                    Text(summary)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .frame(maxWidth: 600, alignment: .leading)
                }

                Spacer().frame(height: 24)

                // Action buttons
                HStack(spacing: 16) {
                    // Play button
                    Button(action: onPlay) {
                        Label(item.isInProgress ? "Resume" : "Play", systemImage: "play.fill")
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

                    // More Info button
                    Button(action: onMoreInfo) {
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

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 80)
        }
        .frame(height: heroHeight)
    }
}

// MARK: - Browse All Button
// Prominent button to navigate to full grid browse

struct BrowseAllButton: View {
    let mediaType: String  // "Movies" or "TV Shows"
    var onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: mediaType == "Movies" ? "film" : "tv")
                    .font(.title2)
                    .foregroundColor(OpenFlixColors.accent)
                    .frame(width: 50, height: 50)
                    .background(OpenFlixColors.accent.opacity(0.2))
                    .cornerRadius(10)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Browse All")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(OpenFlixColors.textPrimary)

                    Text(mediaType)
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(isFocused ? OpenFlixColors.accent : OpenFlixColors.textTertiary)
            }
            .padding(20)
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
        .padding(.horizontal, 50)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        ContinueWatchingSection(items: [])
        RecentlyAddedSection(items: [])
        BrowseAllButton(mediaType: "Movies") {}
    }
    .background(Color.black)
}
