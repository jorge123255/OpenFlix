import SwiftUI

// MARK: - Content Rating Badge
// Displays content ratings like TV-MA, PG-13, R, etc.

struct ContentRatingBadge: View {
    let rating: String
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 12
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .small: return 1
            case .medium: return 1.5
            case .large: return 2
            }
        }
    }

    var body: some View {
        Text(rating)
            .font(size.font)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(OpenFlixColors.ratingBadgeBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(OpenFlixColors.ratingBadgeBorder, lineWidth: size.borderWidth)
            )
            .cornerRadius(4)
    }
}

// MARK: - Section Header
// Title + chevron for "See All" navigation

struct SectionHeader: View {
    let title: String
    var showChevron: Bool = true
    var onSeeAll: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(OpenFlixColors.textPrimary)

            if showChevron {
                Button(action: { onSeeAll?() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isFocused ? OpenFlixColors.accent : OpenFlixColors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .focused($isFocused)
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
            }

            Spacer()
        }
        .padding(.horizontal, 50)
    }
}

// MARK: - Action Button Group
// Play/+/More buttons in Apple TV style

struct ActionButtonGroup: View {
    var playTitle: String = "Play"
    var isInWatchlist: Bool = false
    var onPlay: () -> Void
    var onWatchlist: (() -> Void)?
    var onMore: (() -> Void)?

    @FocusState private var focusedButton: ActionButton?

    enum ActionButton {
        case play, watchlist, more
    }

    var body: some View {
        HStack(spacing: 16) {
            // Play button - White pill
            Button(action: onPlay) {
                Label(playTitle, systemImage: "play.fill")
                    .font(.headline)
                    .foregroundColor(OpenFlixColors.buttonPrimaryText)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(OpenFlixColors.buttonPrimary)
                    .cornerRadius(OpenFlixColors.cornerRadiusSmall)
            }
            .buttonStyle(.card)
            .focused($focusedButton, equals: .play)
            .scaleEffect(focusedButton == .play ? 1.05 : 1.0)
            .shadow(color: focusedButton == .play ? .white.opacity(0.3) : .clear, radius: 8)
            .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: focusedButton)

            // Watchlist button - Circular
            if let onWatchlist = onWatchlist {
                Button(action: onWatchlist) {
                    Image(systemName: isInWatchlist ? "checkmark" : "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(OpenFlixColors.buttonSecondaryText)
                        .frame(width: 50, height: 50)
                        .background(OpenFlixColors.buttonSecondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.card)
                .focused($focusedButton, equals: .watchlist)
                .scaleEffect(focusedButton == .watchlist ? 1.1 : 1.0)
                .overlay(
                    Circle()
                        .stroke(focusedButton == .watchlist ? Color.white : .clear, lineWidth: 2)
                )
                .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: focusedButton)
            }

            // More options button - Circular
            if let onMore = onMore {
                Button(action: onMore) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(OpenFlixColors.buttonSecondaryText)
                        .frame(width: 50, height: 50)
                        .background(OpenFlixColors.buttonSecondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.card)
                .focused($focusedButton, equals: .more)
                .scaleEffect(focusedButton == .more ? 1.1 : 1.0)
                .overlay(
                    Circle()
                        .stroke(focusedButton == .more ? Color.white : .clear, lineWidth: 2)
                )
                .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: focusedButton)
            }
        }
    }
}

// MARK: - Top Ten Card
// Numbered ranking card for Top 10 section

struct TopTenCard: View {
    let item: MediaItem
    let rank: Int
    var onSelect: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: { onSelect?() }) {
            ZStack(alignment: .topLeading) {
                // Poster Image
                AuthenticatedImage(
                    path: item.bestThumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: 180, height: 270)
                .clipped()
                .cornerRadius(OpenFlixColors.cornerRadiusMedium)

                // Rank badge in corner
                Text("\(rank)")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(OpenFlixColors.accent)
                            .frame(width: 50, height: 50)
                    )
                    .offset(x: -8, y: -8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusMedium)
                    .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 4)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: isFocused ? OpenFlixColors.accentGlow : .clear, radius: 12)
            .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Genre Tile
// Square tile for genre browsing

struct GenreTile: View {
    let genre: String
    var backgroundImage: String?
    var onSelect: (() -> Void)?

    @FocusState private var isFocused: Bool

    // Genre-specific colors
    private var genreColor: Color {
        switch genre.lowercased() {
        case "action": return Color(hex: "FF5252")
        case "comedy": return Color(hex: "FFD740")
        case "drama": return Color(hex: "7C4DFF")
        case "sci-fi", "science fiction": return Color(hex: "00B0FF")
        case "horror": return Color(hex: "212121")
        case "romance": return Color(hex: "FF4081")
        case "thriller": return Color(hex: "455A64")
        case "animation", "animated": return Color(hex: "FF6E40")
        case "documentary": return Color(hex: "00BFA5")
        case "kids", "family", "children": return Color(hex: "FFC107")
        case "sports": return Color(hex: "00E676")
        case "music", "musical": return Color(hex: "E040FB")
        case "news": return Color(hex: "448AFF")
        case "western": return Color(hex: "8D6E63")
        default: return OpenFlixColors.surfaceElevated
        }
    }

    var body: some View {
        Button(action: { onSelect?() }) {
            ZStack {
                // Background
                if let imagePath = backgroundImage {
                    AuthenticatedImage(path: imagePath, systemPlaceholder: "rectangle.stack")
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 180)
                        .clipped()

                    // Dark overlay for text readability
                    Color.black.opacity(0.5)
                } else {
                    genreColor
                }

                // Genre name
                VStack {
                    Spacer()
                    Text(genre)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .padding(.bottom, 16)
                }
            }
            .frame(width: 180, height: 180)
            .cornerRadius(OpenFlixColors.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusMedium)
                    .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 4)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: isFocused ? OpenFlixColors.accentGlow : .clear, radius: 12)
            .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Episode Card (Apple TV Style)
// Episode row card with thumbnail, progress, and metadata

struct EpisodeCard: View {
    let episode: MediaItem
    var onPlay: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: { onPlay?() }) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail with progress
                ZStack(alignment: .bottom) {
                    AuthenticatedImage(
                        path: episode.thumb,
                        systemPlaceholder: "play.rectangle"
                    )
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 320, height: 180)
                    .clipped()

                    // Progress bar at bottom
                    if episode.isInProgress {
                        VStack {
                            Spacer()
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(OpenFlixColors.progressBackground)
                                    Rectangle()
                                        .fill(OpenFlixColors.progressFill)
                                        .frame(width: geometry.size.width * episode.progressPercent)
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                }
                .cornerRadius(OpenFlixColors.cornerRadiusSmall, corners: [.topLeft, .topRight])

                // Info section
                VStack(alignment: .leading, spacing: 8) {
                    // Episode number
                    if let index = episode.index {
                        Text("EPISODE \(index)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(OpenFlixColors.textTertiary)
                    }

                    // Title
                    Text(episode.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(OpenFlixColors.textPrimary)
                        .lineLimit(1)

                    // Description
                    if let summary = episode.summary {
                        Text(summary)
                            .font(.caption)
                            .foregroundColor(OpenFlixColors.textSecondary)
                            .lineLimit(2)
                    }

                    // Duration and watched indicator
                    HStack(spacing: 12) {
                        // Play icon and duration
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption2)
                            Text(episode.durationFormatted)
                                .font(.caption)
                        }
                        .foregroundColor(OpenFlixColors.textTertiary)

                        Spacer()

                        // Watched indicator
                        if episode.isWatched {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(OpenFlixColors.success)
                                .font(.caption)
                        }
                    }
                }
                .padding(12)
                .background(OpenFlixColors.surface)
            }
            .frame(width: 320)
            .cornerRadius(OpenFlixColors.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusMedium)
                    .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 3)
            )
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .shadow(color: isFocused ? OpenFlixColors.accentGlow : .clear, radius: 8)
            .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Season Picker
// Diamond icon with season dropdown

struct SeasonPicker: View {
    let seasons: [MediaItem]
    @Binding var selectedSeason: MediaItem?
    var onSeasonChange: ((MediaItem) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Diamond icon
            Image(systemName: "diamond.fill")
                .font(.caption)
                .foregroundColor(OpenFlixColors.accent)

            Text("Season")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(OpenFlixColors.textPrimary)

            Picker("", selection: Binding(
                get: { selectedSeason },
                set: { newSeason in
                    selectedSeason = newSeason
                    if let season = newSeason {
                        onSeasonChange?(season)
                    }
                }
            )) {
                ForEach(seasons) { season in
                    Text("Season \(season.index ?? 0)")
                        .tag(season as MediaItem?)
                }
            }
            .pickerStyle(.menu)
            .tint(OpenFlixColors.accent)

            Spacer()
        }
    }
}

// MARK: - Metadata Row
// Dot-separated metadata (type, genres, rating)

struct MetadataRow: View {
    var mediaType: MediaType?
    var genres: [String] = []
    var contentRating: String?
    var year: Int?
    var duration: String?

    var body: some View {
        HStack(spacing: 8) {
            // Media type icon
            if let type = mediaType {
                HStack(spacing: 4) {
                    Image(systemName: type == .movie ? "film" : "tv")
                        .font(.caption)
                    Text(type.displayName)
                        .font(.caption)
                }
                .foregroundColor(OpenFlixColors.textSecondary)

                dotSeparator
            }

            // Genres (first 2)
            ForEach(genres.prefix(2), id: \.self) { genre in
                Text(genre)
                    .font(.caption)
                    .foregroundColor(OpenFlixColors.textSecondary)

                if genre != genres.prefix(2).last {
                    dotSeparator
                }
            }

            // Content rating badge
            if let rating = contentRating {
                ContentRatingBadge(rating: rating, size: .small)
            }
        }
    }

    private var dotSeparator: some View {
        Text("·")
            .font(.caption)
            .foregroundColor(OpenFlixColors.textTertiary)
    }
}

// MARK: - Helper: Rounded Corner Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Previews

#Preview("Content Rating Badge") {
    HStack(spacing: 16) {
        ContentRatingBadge(rating: "TV-MA", size: .small)
        ContentRatingBadge(rating: "PG-13", size: .medium)
        ContentRatingBadge(rating: "R", size: .large)
    }
    .padding()
    .background(Color.black)
}

#Preview("Section Header") {
    VStack(spacing: 24) {
        SectionHeader(title: "Continue Watching")
        SectionHeader(title: "Top 10 in Your Library", showChevron: true)
        SectionHeader(title: "Recently Added", showChevron: false)
    }
    .background(Color.black)
}

#Preview("Action Button Group") {
    VStack(spacing: 24) {
        ActionButtonGroup(
            playTitle: "Play",
            isInWatchlist: false,
            onPlay: {},
            onWatchlist: {},
            onMore: {}
        )
        ActionButtonGroup(
            playTitle: "Resume",
            isInWatchlist: true,
            onPlay: {},
            onWatchlist: {},
            onMore: {}
        )
    }
    .padding()
    .background(Color.black)
}

#Preview("Genre Tiles") {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
        GenreTile(genre: "Action")
        GenreTile(genre: "Comedy")
        GenreTile(genre: "Drama")
        GenreTile(genre: "Sci-Fi")
        GenreTile(genre: "Horror")
        GenreTile(genre: "Romance")
    }
    .padding()
    .background(Color.black)
}
