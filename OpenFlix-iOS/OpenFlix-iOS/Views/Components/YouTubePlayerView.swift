import SwiftUI
import AVKit

// MARK: - Hero Trailer Background
// On tvOS, WebKit is not available, so we use a YouTube thumbnail as background
// with an optional play button that could launch the YouTube app
// In a production app, you might use YouTube's iframe player via TVML or
// extract the direct video URL for AVPlayer playback

struct HeroTrailerBackground: View {
    let item: MediaItem
    let trailer: TrailerInfo?

    @State private var imageLoaded = false

    var body: some View {
        ZStack {
            // Static backdrop image (base layer - from local server)
            AuthenticatedImage(
                path: item.art ?? item.thumb,
                systemPlaceholder: "film"
            )
            .aspectRatio(contentMode: .fill)

            // High quality TMDB backdrop (if available from trailer lookup)
            if let trailer = trailer {
                // Priority 1: TMDB backdrop (highest quality movie poster art)
                if let tmdbBackdropURL = trailer.tmdbBackdropURLMedium {
                    AsyncImage(url: tmdbBackdropURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .transition(.opacity.animation(.easeIn(duration: 0.5)))
                                .onAppear { imageLoaded = true }
                        case .failure:
                            // Fallback to YouTube thumbnail if TMDB fails
                            youTubeThumbnail(trailer: trailer)
                        default:
                            EmptyView()
                        }
                    }
                } else {
                    // No TMDB backdrop, use YouTube thumbnail
                    youTubeThumbnail(trailer: trailer)
                }
            }
        }
    }

    @ViewBuilder
    private func youTubeThumbnail(trailer: TrailerInfo) -> some View {
        AsyncImage(url: trailer.thumbnailURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity.animation(.easeIn(duration: 0.5)))
            case .failure:
                // Try medium quality thumbnail as fallback
                AsyncImage(url: trailer.thumbnailURLMedium) { fallbackPhase in
                    if case .success(let fallbackImage) = fallbackPhase {
                        fallbackImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - YouTube Trailer Player
// AVPlayer-based trailer player for tvOS
// Note: This would require extracting the actual video stream URL from YouTube,
// which is against YouTube's ToS. For a production app, consider:
// 1. Using official YouTube TV app deep linking
// 2. Using TVML with YouTube's iframe embed
// 3. Only showing thumbnails (current implementation)

struct YouTubeTrailerPlayer: View {
    let trailer: TrailerInfo
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            // Background thumbnail
            AsyncImage(url: trailer.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.black
            }

            // Play indicator (since we can't actually play YouTube on tvOS without workarounds)
            VStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.8))

                Text("Trailer Available")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Trailer Badge
// Small indicator that a trailer is available

struct TrailerBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "play.rectangle.fill")
                .font(.caption2)
            Text("TRAILER")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red)
        .cornerRadius(4)
    }
}

#Preview {
    VStack {
        TrailerBadge()

        YouTubeTrailerPlayer(trailer: TrailerInfo(
            youtubeKey: "dQw4w9WgXcQ",
            name: "Sample Trailer"
        ))
        .frame(width: 400, height: 225)
    }
}
