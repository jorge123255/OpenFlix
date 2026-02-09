import SwiftUI

struct MediaCard: View {
    let item: MediaItem
    var showProgress: Bool = true
    var onSelect: (() -> Void)?

    @FocusState private var isFocused: Bool

    private let cardWidth: CGFloat = 200
    private let cardHeight: CGFloat = 300

    var body: some View {
        Button(action: { onSelect?() }) {
            VStack(alignment: .leading, spacing: 8) {
                // Poster Image
                ZStack(alignment: .bottomLeading) {
                    AuthenticatedImage(
                        path: item.bestThumb,
                        systemPlaceholder: item.type == .movie ? "film" : "tv"
                    )
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                    .cornerRadius(OpenFlixColors.cornerRadiusMedium)

                    // Progress bar
                    if showProgress && item.isInProgress {
                        VStack {
                            Spacer()
                            ProgressBar(progress: item.progressPercent)
                                .frame(height: 4)
                                .padding(.horizontal, 4)
                                .padding(.bottom, 4)
                        }
                    }

                    // Watched badge
                    if item.isWatched {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(OpenFlixColors.success)
                            .font(.title3)
                            .padding(8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }

                    // NEW badge (top-right corner)
                    if item.isRecentlyAdded && !item.isWatched {
                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(OpenFlixColors.accent)
                            .cornerRadius(4)
                            .padding(8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusMedium)
                        .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 4)
                )

                // Title
                Text(item.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(isFocused ? OpenFlixColors.accent : OpenFlixColors.textPrimary)

                // Year
                if let year = item.year {
                    Text(String(year))
                        .font(.caption2)
                        .foregroundColor(OpenFlixColors.textSecondary)
                }
            }
            .frame(width: cardWidth)
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .shadow(color: isFocused ? OpenFlixColors.accentGlow : .clear, radius: 15)
            .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Wide Media Card
// Landscape card variant for Continue Watching and featured content

struct WideMediaCard: View {
    let item: MediaItem
    var showProgress: Bool = true
    var onSelect: (() -> Void)?

    @FocusState private var isFocused: Bool

    private let cardWidth: CGFloat = 320
    private let cardHeight: CGFloat = 180

    var body: some View {
        Button(action: { onSelect?() }) {
            ZStack(alignment: .bottom) {
                // Landscape thumbnail (backdrop or art)
                AuthenticatedImage(
                    path: item.art ?? item.bestThumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
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
                .frame(height: cardHeight * 0.6)

                // Content overlay
                VStack(alignment: .leading, spacing: 6) {
                    Spacer()

                    // Title
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    // Metadata row
                    HStack(spacing: 8) {
                        if let year = item.year {
                            Text(String(year))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        if showProgress && item.isInProgress {
                            Text("·")
                                .foregroundColor(.white.opacity(0.5))
                            Text(remainingTime)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            let duration = item.durationFormatted
                            if !duration.isEmpty {
                                Text("·")
                                    .foregroundColor(.white.opacity(0.5))
                                Text(duration)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }

                    // Progress bar
                    if showProgress && item.isInProgress {
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
                }
                .padding(12)

                // Play button overlay (centered)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(isFocused ? 1.0 : 0.7))
                    .shadow(color: .black.opacity(0.5), radius: 6)

                // NEW badge (top-right)
                if item.isRecentlyAdded && !item.isWatched && !item.isInProgress {
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(OpenFlixColors.accent)
                        .cornerRadius(3)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
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

    private var remainingTime: String {
        guard let duration = item.duration,
              let offset = item.viewOffset else {
            return item.durationFormatted
        }
        let remaining = duration - offset
        return String.formatDuration(milliseconds: remaining) + " left"
    }
}

struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(OpenFlixColors.progressBackground)

                Rectangle()
                    .fill(OpenFlixColors.progressFill)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
            }
        }
        .cornerRadius(2)
    }
}

#Preview {
    MediaCard(
        item: MediaItem(
            id: 1,
            key: "1",
            guid: nil,
            type: .movie,
            title: "Sample Movie",
            originalTitle: nil,
            tagline: nil,
            summary: nil,
            thumb: nil,
            art: nil,
            banner: nil,
            year: 2024,
            duration: 7200000,
            viewOffset: 3600000,
            viewCount: nil,
            contentRating: "PG-13",
            audienceRating: 8.5,
            rating: nil,
            studio: nil,
            addedAt: nil,
            originallyAvailableAt: nil,
            leafCount: nil,
            viewedLeafCount: nil,
            childCount: nil,
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
        )
    )
}
