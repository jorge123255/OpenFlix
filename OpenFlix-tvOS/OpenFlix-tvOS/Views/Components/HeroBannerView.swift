import SwiftUI

// MARK: - Hero Banner View
// Apple TV-inspired full-width featured content carousel

struct HeroBannerView: View {
    let items: [MediaItem]
    var onPlay: ((MediaItem) -> Void)?
    var onDetails: ((MediaItem) -> Void)?
    var onWatchlist: ((MediaItem) -> Void)?

    @State private var currentIndex = 0
    @State private var autoAdvanceTimer: Timer?
    @FocusState private var isFocused: Bool

    private let autoAdvanceInterval: TimeInterval = 8.0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background images with tab view
            TabView(selection: $currentIndex) {
                ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, item in
                    HeroBannerItem(
                        item: item,
                        onPlay: { onPlay?(item) },
                        onDetails: { onDetails?(item) },
                        onWatchlist: { onWatchlist?(item) }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 700)

            // Page indicator dots - INSIDE the hero at bottom center
            if items.count > 1 {
                HStack(spacing: 10) {
                    ForEach(0..<min(items.count, 5), id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: index == currentIndex ? 10 : 8, height: index == currentIndex ? 10 : 8)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.3))
                .cornerRadius(20)
                .padding(.bottom, 24)
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
                stopAutoAdvance()
            } else {
                startAutoAdvance()
            }
        }
    }

    private func startAutoAdvance() {
        guard items.count > 1 else { return }
        stopAutoAdvance()
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: autoAdvanceInterval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % min(items.count, 5)
            }
        }
    }

    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }
}

// MARK: - Hero Banner Item

struct HeroBannerItem: View {
    let item: MediaItem
    var onPlay: () -> Void
    var onDetails: () -> Void
    var onWatchlist: (() -> Void)?

    @FocusState private var focusedButton: BannerButton?

    enum BannerButton: Hashable {
        case play, watchlist, info
    }

    var body: some View {
        ZStack {
            // Full-bleed background art
            AuthenticatedImage(
                path: item.art ?? item.thumb,
                systemPlaceholder: item.type == .movie ? "film" : "tv"
            )
            .aspectRatio(contentMode: .fill)
            .frame(height: 700)
            .clipped()

            // Side gradient overlay (left-aligned content style)
            OpenFlixColors.heroGradient

            // Bottom gradient for content area
            OpenFlixColors.heroBottomGradient

            // Content - Left aligned
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Large title/logo
                Text(item.title)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    .lineLimit(2)

                Spacer().frame(height: 16)

                // Metadata row with dots
                HStack(spacing: 12) {
                    // Media type icon
                    HStack(spacing: 6) {
                        Image(systemName: item.type == .movie ? "film" : "tv")
                            .font(.subheadline)
                        Text(item.type.displayName)
                            .font(.subheadline)
                    }
                    .foregroundColor(.white.opacity(0.9))

                    // Genres (first 2)
                    if !item.genres.isEmpty {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))

                        Text(item.genres.prefix(2).joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // Content rating badge
                    if let rating = item.contentRating {
                        ContentRatingBadge(rating: rating, size: .medium)
                    }

                    // Year
                    if let year = item.year {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))
                        Text(String(year))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Duration
                    let duration = item.durationFormatted
                    if !duration.isEmpty {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))
                        Text(duration)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Rating
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

                // Action buttons - Apple TV style
                HStack(spacing: 16) {
                    // Play button - White pill
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

                    // Watchlist button - Circular
                    if let onWatchlist = onWatchlist {
                        Button(action: onWatchlist) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 54, height: 54)
                                .background(Color.white.opacity(0.25))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.card)
                        .focused($focusedButton, equals: .watchlist)
                        .scaleEffect(focusedButton == .watchlist ? 1.1 : 1.0)
                        .overlay(
                            Circle()
                                .stroke(focusedButton == .watchlist ? Color.white : .clear, lineWidth: 2)
                        )
                        .animation(.easeInOut(duration: 0.15), value: focusedButton)
                    }

                    // Info button - Circular
                    Button(action: onDetails) {
                        Image(systemName: "info")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 54, height: 54)
                            .background(Color.white.opacity(0.25))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.card)
                    .focused($focusedButton, equals: .info)
                    .scaleEffect(focusedButton == .info ? 1.1 : 1.0)
                    .overlay(
                        Circle()
                            .stroke(focusedButton == .info ? Color.white : .clear, lineWidth: 2)
                    )
                    .animation(.easeInOut(duration: 0.15), value: focusedButton)
                }

                Spacer().frame(height: 80)
            }
            .padding(.horizontal, 80)
        }
    }
}

// MARK: - Preview

#Preview {
    HeroBannerView(items: [
        MediaItem(
            id: 1,
            key: "/library/metadata/1",
            guid: "tmdb://157336",
            type: .movie,
            title: "Interstellar",
            originalTitle: nil,
            tagline: "Mankind was born on Earth. It was never meant to die here.",
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
            genres: ["Sci-Fi", "Drama", "Adventure"],
            roles: [],
            directors: [],
            writers: [],
            countries: [],
            mediaVersions: []
        )
    ])
}
