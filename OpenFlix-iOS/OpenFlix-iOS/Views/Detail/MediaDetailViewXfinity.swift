import SwiftUI
import AVKit

struct MediaDetailViewXfinity: View {
    let item: MediaItem
    @StateObject private var viewModel: XfinityMediaDetailViewModel
    @State private var selectedSeason: Int = 1
    @State private var isLoadingStream = false

    private let mediaRepository = MediaRepository()

    init(item: MediaItem) {
        self.item = item
        self._viewModel = StateObject(wrappedValue: XfinityMediaDetailViewModel(item: item))
    }

    var body: some View {
        ZStack {
            XfinityColors.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HeroSection(item: item, onPlay: playMedia)
                    ActionButtonsRow(item: item, viewModel: viewModel, onPlay: playMedia)

                    if let overview = item.summary {
                        DescriptionSection(text: overview)
                    }

                    MetadataSection(item: item)

                    if item.type == .show {
                        EpisodesSection(
                            seasons: viewModel.seasons,
                            episodes: viewModel.episodes,
                            selectedSeason: $selectedSeason,
                            onEpisodeSelect: { _ in }
                        )
                    }

                    if !viewModel.cast.isEmpty {
                        CastSection(cast: viewModel.cast)
                    }

                    if !viewModel.similar.isEmpty {
                        GalleryRow(title: "More Like This", items: viewModel.similar, showViewAll: false) { similarItem in
                            PosterTile(item: similarItem) {}
                        }
                    }

                    Spacer().frame(height: XfinitySpacing.p8)
                }
            }

            // Loading overlay while fetching stream URL
            if isLoadingStream {
                Color.black.opacity(0.6).ignoresSafeArea()
                ProgressView().tint(.white).scaleEffect(2)
            }
        }
        .onAppear { viewModel.loadDetails() }
    }

    private func playMedia() {
        Task { @MainActor in
            isLoadingStream = true
            do {
                let url = try await resolveStreamURL()
                isLoadingStream = false
                presentPlayer(url: url)
            } catch {
                isLoadingStream = false
            }
        }
    }

    private func resolveStreamURL() async throws -> URL {
        if let s = item.streamUrl, let url = URL(string: s) { return url }
        let detail = item.mediaVersions.isEmpty
            ? try await mediaRepository.getMediaDetails(id: item.id)
            : item
        if let s = detail.streamUrl, let url = URL(string: s) { return url }
        return try await mediaRepository.getPlaybackURL(mediaItem: detail, offset: nil)
    }

    private func presentPlayer(url: URL) {
        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return }

        var top = window.rootViewController
        while let presented = top?.presentedViewController { top = presented }

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)

        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        playerVC.showsPlaybackControls = true
        playerVC.modalPresentationStyle = .fullScreen

        top?.present(playerVC, animated: true) { player.play() }
    }
}

// MARK: - Hero Section
struct HeroSection: View {
    let item: MediaItem
    let onPlay: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            AsyncImage(url: URL(string: item.art ?? item.thumb ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle().fill(XfinityColors.backgroundTertiary)
                }
            }
            .frame(height: 280)
            .clipped()
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.clear,
                    XfinityColors.backgroundPrimary.opacity(0.6),
                    XfinityColors.backgroundPrimary
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Content
            HStack(alignment: .bottom, spacing: XfinitySpacing.p4) {
                // Poster
                AsyncImage(url: URL(string: item.thumb ?? item.art ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(XfinityColors.backgroundTertiary)
                    }
                }
                .frame(width: 100, height: 150)
                .cornerRadius(XfinityDimensions.cornerRadiusMedium)
                .shadow(color: .black.opacity(0.5), radius: 10)
                
                // Info
                VStack(alignment: .leading, spacing: XfinitySpacing.p2) {
                    Text(item.title)
                        .font(XfinityTypography.title1)
                        .foregroundColor(XfinityColors.textPrimary)
                        .lineLimit(2)
                    
                    // Metadata row
                    HStack(spacing: XfinitySpacing.p2) {
                        if let year = item.year {
                            Text(String(year))
                                .font(XfinityTypography.callout)
                                .foregroundColor(XfinityColors.textSecondary)
                        }
                        
                        if let rating = item.rating {
                            Text(String(format: "%.1f", rating))
                                .font(XfinityTypography.captionBold)
                                .foregroundColor(XfinityColors.textPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(XfinityColors.border)
                                .cornerRadius(4)
                        }
                        
                        if !item.durationFormatted.isEmpty {
                            Text(item.durationFormatted)
                                .font(XfinityTypography.callout)
                                .foregroundColor(XfinityColors.textSecondary)
                        }
                    }
                    
                    // Rating
                    if let score = (item.audienceRating ?? item.rating) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 14))
                            
                            Text(String(format: "%.1f", score))
                                .font(XfinityTypography.calloutBold)
                                .foregroundColor(XfinityColors.textPrimary)
                        }
                    }
                }
            }
            .padding(XfinitySpacing.p4)
        }
    }
}

// MARK: - Action Buttons
struct ActionButtonsRow: View {
    let item: MediaItem
    @ObservedObject var viewModel: XfinityMediaDetailViewModel
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: XfinitySpacing.p3) {
            // Play button
            Button {
                onPlay()
            } label: {
                Label("Play", systemImage: "play.fill")
                    .font(XfinityTypography.bodyBold)
                    .foregroundColor(XfinityColors.textInverse)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, XfinitySpacing.p3)
                    .background(XfinityColors.accentPrimary)
                    .cornerRadius(XfinityDimensions.cornerRadiusMedium)
            }
            
            // Watchlist button
            Button {
                viewModel.toggleWatchlist()
            } label: {
                Image(systemName: viewModel.isInWatchlist ? "checkmark" : "plus")
                    .font(.system(size: 20))
                    .foregroundColor(XfinityColors.textPrimary)
                    .frame(width: 48, height: 48)
                    .background(XfinityColors.backgroundTertiary)
                    .cornerRadius(XfinityDimensions.cornerRadiusMedium)
            }
            
            // Download button
            Button {
                // Download
            } label: {
                Image(systemName: "arrow.down.to.line")
                    .font(.system(size: 20))
                    .foregroundColor(XfinityColors.textPrimary)
                    .frame(width: 48, height: 48)
                    .background(XfinityColors.backgroundTertiary)
                    .cornerRadius(XfinityDimensions.cornerRadiusMedium)
            }
            
            // Share button
            Button {
                // Share
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(XfinityColors.textPrimary)
                    .frame(width: 48, height: 48)
                    .background(XfinityColors.backgroundTertiary)
                    .cornerRadius(XfinityDimensions.cornerRadiusMedium)
            }
        }
        .padding(.horizontal, XfinitySpacing.p4)
        .padding(.vertical, XfinitySpacing.p3)
    }
}

// MARK: - Description Section
struct DescriptionSection: View {
    let text: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: XfinitySpacing.p2) {
            Text(text)
                .font(XfinityTypography.body)
                .foregroundColor(XfinityColors.textSecondary)
                .lineLimit(isExpanded ? nil : 3)
            
            if text.count > 150 {
                Button(isExpanded ? "Show Less" : "Show More") {
                    withAnimation { isExpanded.toggle() }
                }
                .font(XfinityTypography.calloutBold)
                .foregroundColor(XfinityColors.accentPrimary)
            }
        }
        .padding(.horizontal, XfinitySpacing.p4)
        .padding(.vertical, XfinitySpacing.p3)
    }
}

// MARK: - Metadata Section
struct MetadataSection: View {
    let item: MediaItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: XfinitySpacing.p3) {
            if !item.genres.isEmpty {
                XfinityMetadataRow(label: "Genre", value: item.genres.joined(separator: ", "))
            }
            
            if !item.directors.isEmpty {
                XfinityMetadataRow(label: "Director", value: item.directors.joined(separator: ", "))
            }
            
            if let studio = item.studio {
                XfinityMetadataRow(label: "Studio", value: studio)
            }
        }
        .padding(.horizontal, XfinitySpacing.p4)
        .padding(.vertical, XfinitySpacing.p3)
    }
}

struct XfinityMetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(XfinityTypography.callout)
                .foregroundColor(XfinityColors.textTertiary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(XfinityTypography.callout)
                .foregroundColor(XfinityColors.textPrimary)
        }
    }
}

// MARK: - Episodes Section
struct EpisodesSection: View {
    let seasons: [Int]
    let episodes: [Episode]
    @Binding var selectedSeason: Int
    let onEpisodeSelect: (Episode) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: XfinitySpacing.p3) {
            // Season picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: XfinitySpacing.p2) {
                    ForEach(seasons, id: \.self) { season in
                        Button {
                            selectedSeason = season
                        } label: {
                            Text("Season \(season)")
                                .font(XfinityTypography.calloutBold)
                                .foregroundColor(selectedSeason == season ? XfinityColors.accentPrimary : XfinityColors.textSecondary)
                                .padding(.horizontal, XfinitySpacing.p3)
                                .padding(.vertical, XfinitySpacing.p2)
                                .background(selectedSeason == season ? XfinityColors.accentPrimary.opacity(0.15) : Color.clear)
                                .cornerRadius(XfinityDimensions.cornerRadiusLarge)
                        }
                    }
                }
                .padding(.horizontal, XfinitySpacing.p4)
            }
            
            // Episodes list
            LazyVStack(spacing: XfinitySpacing.p2) {
                ForEach(episodes.filter { $0.seasonNumber == selectedSeason }) { episode in
                    XfinityEpisodeRow(episode: episode) {
                        onEpisodeSelect(episode)
                    }
                }
            }
            .padding(.horizontal, XfinitySpacing.p4)
        }
        .padding(.vertical, XfinitySpacing.p3)
    }
}

struct XfinityEpisodeRow: View {
    let episode: Episode
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: XfinitySpacing.p3) {
                // Thumbnail
                AsyncImage(url: URL(string: episode.thumbnailURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(XfinityColors.backgroundTertiary)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(XfinityColors.textTertiary)
                            )
                    }
                }
                .frame(width: 120, height: 68)
                .cornerRadius(XfinityDimensions.cornerRadiusSmall)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("E\(episode.episodeNumber): \(episode.title)")
                        .font(XfinityTypography.bodyBold)
                        .foregroundColor(XfinityColors.textPrimary)
                        .lineLimit(2)
                    
                    if let duration = episode.duration {
                        Text(duration)
                            .font(XfinityTypography.caption)
                            .foregroundColor(XfinityColors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Download button
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 24))
                    .foregroundColor(XfinityColors.textTertiary)
            }
            .padding(XfinitySpacing.p2)
            .background(XfinityColors.backgroundTertiary)
            .cornerRadius(XfinityDimensions.cornerRadiusMedium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Cast Section
struct CastSection: View {
    let cast: [CastMember]
    
    var body: some View {
        VStack(alignment: .leading, spacing: XfinitySpacing.p3) {
            Text("Cast & Crew")
                .font(XfinityTypography.title3)
                .foregroundColor(XfinityColors.textPrimary)
                .padding(.horizontal, XfinitySpacing.p4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: XfinitySpacing.p3) {
                    ForEach(cast) { member in
                        CastCard(member: member)
                    }
                }
                .padding(.horizontal, XfinitySpacing.p4)
            }
        }
        .padding(.vertical, XfinitySpacing.p3)
    }
}

struct CastCard: View {
    let member: CastMember
    
    var body: some View {
        VStack(spacing: XfinitySpacing.p2) {
            // Photo
            AsyncImage(url: URL(string: member.thumb ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Circle().fill(XfinityColors.backgroundTertiary)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(XfinityColors.textTertiary)
                        )
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            
            // Name
            Text(member.name)
                .font(XfinityTypography.footnote)
                .foregroundColor(XfinityColors.textPrimary)
                .lineLimit(1)
            
            // Role
            Text(member.role ?? "")
                .font(XfinityTypography.caption)
                .foregroundColor(XfinityColors.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}

// MARK: - Video Player View
struct XfinityVideoPlayerView: View {
    let item: MediaItem
    @Environment(\.dismiss) var dismiss
    @State private var streamURL: URL?
    @State private var isLoading = true
    @State private var loadError: String?

    private let mediaRepository = MediaRepository()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let url = streamURL {
                XfinityAVPlayer(url: url)
                    .ignoresSafeArea()
            } else if isLoading {
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(2)
                    Text("Loading...").foregroundColor(.white.opacity(0.7)).font(.subheadline)
                }
            } else if let err = loadError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow).font(.largeTitle)
                    Text(err).foregroundColor(.white).multilineTextAlignment(.center).padding(.horizontal)
                    Button("Close") { dismiss() }
                        .foregroundColor(.white).padding(.top, 8)
                }
            }

            // Close button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 60).padding(.leading, 20)
                Spacer()
            }
        }
        .task { await loadStreamURL() }
    }

    private func loadStreamURL() async {
        isLoading = true
        do {
            // Use direct streamUrl if the item already has one
            if let direct = item.streamUrl, let url = URL(string: direct) {
                streamURL = url
                isLoading = false
                return
            }
            // Fetch full details to get streamUrl or mediaVersions
            let detail = item.mediaVersions.isEmpty
                ? try await mediaRepository.getMediaDetails(id: item.id)
                : item
            if let direct = detail.streamUrl, let url = URL(string: direct) {
                streamURL = url
            } else {
                streamURL = try await mediaRepository.getPlaybackURL(mediaItem: detail, offset: nil)
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}

struct XfinityAVPlayer: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        let player = AVPlayer(url: url)
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = true
        player.play()
        return vc
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player?.play()
    }
}

// MARK: - Supporting Models
struct Episode: Identifiable {
    let id: String
    let seasonNumber: Int
    let episodeNumber: Int
    let title: String
    let thumbnailURL: String?
    let duration: String?
}

// MARK: - Media Detail ViewModel
@MainActor
class XfinityMediaDetailViewModel: ObservableObject {
    @Published var seasons: [Int] = []
    @Published var episodes: [Episode] = []
    @Published var cast: [CastMember] = []
    @Published var similar: [MediaItem] = []
    @Published var isInWatchlist = false
    @Published var isLoading = false
    
    private let item: MediaItem
    private let mediaRepository = MediaRepository()
    
    init(item: MediaItem) {
        self.item = item
    }
    
    func loadDetails() {
        isLoading = true
        
        Task {
            // Load episodes if TV show
            if item.type == .show {
                await loadEpisodes()
            }
            
            await loadCast()
            await loadSimilar()
            await checkWatchlist()
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func loadEpisodes() async {
        // Simulated - would call API
        await MainActor.run {
            self.seasons = [1, 2, 3]
            self.episodes = [
                Episode(id: "1", seasonNumber: 1, episodeNumber: 1, title: "Pilot", thumbnailURL: nil, duration: "45 min"),
                Episode(id: "2", seasonNumber: 1, episodeNumber: 2, title: "Episode 2", thumbnailURL: nil, duration: "42 min"),
            ]
        }
    }
    
    private func loadCast() async {
        // Simulated - would call API
        await MainActor.run {
            self.cast = []
        }
    }
    
    private func loadSimilar() async {
        await MainActor.run {
            self.similar = []
        }
    }
    
    private func checkWatchlist() async {
        // Check if item is in watchlist
    }
    
    func toggleWatchlist() {
        isInWatchlist.toggle()
        // Save to watchlist
    }
}
