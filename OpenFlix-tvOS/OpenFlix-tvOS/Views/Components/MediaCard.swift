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
