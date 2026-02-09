import Foundation

// MARK: - Trailer Info
// Represents a movie trailer from TMDB/YouTube

struct TrailerInfo: Identifiable, Hashable {
    let id: String
    let youtubeKey: String
    let name: String
    let backdropPath: String?  // TMDB backdrop path for high quality image

    init(youtubeKey: String, name: String, backdropPath: String? = nil) {
        self.id = youtubeKey
        self.youtubeKey = youtubeKey
        self.name = name
        self.backdropPath = backdropPath
    }

    /// TMDB backdrop URL (original quality - usually 1920x1080 or higher)
    var tmdbBackdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(path)")
    }

    /// TMDB backdrop URL (1280x720 for faster loading)
    var tmdbBackdropURLMedium: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(path)")
    }

    /// YouTube embed URL with autoplay, muted, no controls, and looping
    /// Configured for background playback on tvOS
    var embedURL: URL {
        // Parameters:
        // - autoplay=1: Start playing automatically
        // - mute=1: Mute the video (required for autoplay)
        // - controls=0: Hide video controls
        // - showinfo=0: Hide video title
        // - rel=0: Don't show related videos at end
        // - modestbranding=1: Minimal YouTube branding
        // - playsinline=1: Play inline (not fullscreen)
        // - loop=1: Loop the video
        // - playlist=KEY: Required for loop to work
        let urlString = "https://www.youtube.com/embed/\(youtubeKey)?autoplay=1&mute=1&controls=0&showinfo=0&rel=0&modestbranding=1&playsinline=1&loop=1&playlist=\(youtubeKey)&enablejsapi=1"
        return URL(string: urlString)!
    }

    /// Standard YouTube watch URL (for opening in YouTube app)
    var watchURL: URL {
        URL(string: "https://www.youtube.com/watch?v=\(youtubeKey)")!
    }

    /// YouTube thumbnail URL (high quality)
    var thumbnailURL: URL {
        URL(string: "https://img.youtube.com/vi/\(youtubeKey)/maxresdefault.jpg")!
    }

    /// YouTube thumbnail URL (medium quality fallback)
    var thumbnailURLMedium: URL {
        URL(string: "https://img.youtube.com/vi/\(youtubeKey)/hqdefault.jpg")!
    }
}
