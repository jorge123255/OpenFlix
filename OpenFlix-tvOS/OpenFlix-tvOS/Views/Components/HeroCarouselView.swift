import SwiftUI

// MARK: - Hero Carousel View
// Netflix-style auto-rotating hero carousel with optional TMDB YouTube trailers
// Shows featured movies with video backgrounds when available

struct HeroCarouselView: View {
    let movies: [MediaItem]
    let trailers: [Int: TrailerInfo]  // mediaId -> trailer
    @Binding var currentIndex: Int

    var onPlay: ((MediaItem) -> Void)?
    var onMoreInfo: ((MediaItem) -> Void)?

    @State private var autoAdvanceTimer: Timer?
    @FocusState private var isFocused: Bool

    private let autoAdvanceInterval: TimeInterval = 10.0
    private let heroHeight: CGFloat = 600

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background with trailer or image
            TabView(selection: $currentIndex) {
                ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                    HeroCarouselItem(
                        item: movie,
                        trailer: trailers[movie.id],
                        isActive: index == currentIndex,
                        onPlay: { onPlay?(movie) },
                        onMoreInfo: { onMoreInfo?(movie) }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: heroHeight)

            // Page indicator dots
            if movies.count > 1 {
                PageIndicatorDots(
                    count: movies.count,
                    currentIndex: currentIndex
                )
                .padding(.bottom, 30)
            }
        }
        .focusSection()
        .focused($isFocused)
        .onAppear {
            startAutoAdvance()
        }
        .onDisappear {
            stopAutoAdvance()
        }
        .onChange(of: isFocused) { _, focused in
            if focused {
                // Pause auto-advance when user is interacting
                stopAutoAdvance()
            } else {
                startAutoAdvance()
            }
        }
        .onChange(of: currentIndex) { _, _ in
            // Reset timer when user manually changes slide
            if isFocused {
                stopAutoAdvance()
            }
        }
    }

    private func startAutoAdvance() {
        guard movies.count > 1 else { return }
        stopAutoAdvance()

        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: autoAdvanceInterval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % movies.count
            }
        }
    }

    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }
}

// MARK: - Hero Carousel Item
// Single item in the carousel with trailer background

struct HeroCarouselItem: View {
    let item: MediaItem
    let trailer: TrailerInfo?
    let isActive: Bool
    var onPlay: () -> Void
    var onMoreInfo: () -> Void

    @FocusState private var focusedButton: HeroButton?

    enum HeroButton: Hashable {
        case play, info
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Background: YouTube trailer or static image
                Group {
                    if let trailer = trailer, isActive {
                        // Show trailer video when this item is active
                        HeroTrailerBackground(item: item, trailer: trailer)
                    } else {
                        // Static backdrop image
                        AuthenticatedImage(
                            path: item.art ?? item.thumb,
                            systemPlaceholder: "film"
                        )
                        .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()

                // Gradient overlays
                OpenFlixColors.heroGradient
                OpenFlixColors.heroBottomGradient

                // Content overlay
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                // FEATURED badge (when trailer is playing)
                if trailer != nil && isActive {
                    HStack(spacing: 6) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.caption2)
                        Text("FEATURED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(1.5)
                    }
                    .foregroundColor(OpenFlixColors.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(OpenFlixColors.accent.opacity(0.2))
                    .cornerRadius(4)

                    Spacer().frame(height: 12)
                }

                // Title
                Text(item.title)
                    .font(.system(size: 54, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 4)
                    .lineLimit(2)

                Spacer().frame(height: 12)

                // Metadata row
                HStack(spacing: 10) {
                    // Genres
                    if !item.genres.isEmpty {
                        Text(item.genres.prefix(2).joined(separator: " \u{2022} "))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }

                    // Content rating
                    if let rating = item.contentRating {
                        ContentRatingBadge(rating: rating, size: .medium)
                    }

                    // Year
                    if let year = item.year {
                        Text("\u{2022}")
                            .foregroundColor(.white.opacity(0.5))
                        Text(String(year))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Duration
                    let duration = item.durationFormatted
                    if !duration.isEmpty {
                        Text("\u{2022}")
                            .foregroundColor(.white.opacity(0.5))
                        Text(duration)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Rating
                    if let audienceRating = item.audienceRating, audienceRating > 0 {
                        Text("\u{2022}")
                            .foregroundColor(.white.opacity(0.5))
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

                // Summary (2 lines)
                if let summary = item.summary {
                    Text(summary)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .frame(maxWidth: 650, alignment: .leading)
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
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.card)
                    .focused($focusedButton, equals: .play)
                    .scaleEffect(focusedButton == .play ? 1.05 : 1.0)
                    .shadow(color: focusedButton == .play ? .white.opacity(0.4) : .clear, radius: 10)
                    .animation(.easeInOut(duration: 0.15), value: focusedButton)

                    // More Info button
                    Button(action: onMoreInfo) {
                        Label("More Info", systemImage: "info.circle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
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

                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 80)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
            }
        }
    }
}

// MARK: - Page Indicator Dots

struct PageIndicatorDots: View {
    let count: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                    .frame(
                        width: index == currentIndex ? 12 : 8,
                        height: index == currentIndex ? 12 : 8
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .background(Color.black.opacity(0.3))
        .cornerRadius(20)
    }
}

// MARK: - Preview

#Preview {
    HeroCarouselView(
        movies: [
            MediaItem(
                id: 1,
                key: "/library/metadata/1",
                guid: "tmdb://157336",
                type: .movie,
                title: "Interstellar",
                originalTitle: nil,
                tagline: nil,
                summary: "In Earth's future, a global crop blight and second Dust Bowl are slowly rendering the planet uninhabitable.",
                thumb: nil,
                art: nil,
                banner: nil,
                year: 2014,
                duration: 10140000,
                viewOffset: nil,
                viewCount: nil,
                contentRating: "PG-13",
                audienceRating: 8.7,
                rating: nil,
                studio: "Paramount",
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
                genres: ["Sci-Fi", "Drama"],
                roles: [],
                directors: [],
                writers: [],
                countries: [],
                mediaVersions: []
            )
        ],
        trailers: [:],
        currentIndex: .constant(0)
    )
    .background(Color.black)
}
