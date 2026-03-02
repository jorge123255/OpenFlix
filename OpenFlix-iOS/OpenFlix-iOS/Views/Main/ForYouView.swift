import SwiftUI

// MARK: - For You View (Xfinity-style home screen)
struct ForYouView: View {
    @StateObject private var viewModel = ForYouViewModel()
    @StateObject private var liveTVViewModel = LiveTVViewModel()
    @State private var selectedHeroIndex = 0

    // Xfinity colors
    private let bgColor = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let accentPurple = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let liveRed = Color(red: 208/255, green: 2/255, blue: 27/255)
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 24) {
                // Hero Banner Carousel
                if !viewModel.heroItems.isEmpty {
                    HeroBannerCarousel(
                        items: viewModel.heroItems,
                        selectedIndex: $selectedHeroIndex,
                        accentColor: accentPurple
                    )
                }
                
                // Continue Watching
                if !viewModel.continueWatching.isEmpty {
                    ForYouGallerySection(title: "Continue Watching") {
                        ContinueWatchingGalleryRow(items: viewModel.continueWatching)
                    }
                }

                // Movies
                if !viewModel.movies.isEmpty {
                    ForYouGallerySection(title: "Movies", showViewAll: true) {
                        MediaGalleryRow(items: viewModel.movies, style: .poster)
                    }
                }

                // TV Shows
                if !viewModel.tvShows.isEmpty {
                    ForYouGallerySection(title: "TV Shows", showViewAll: true) {
                        MediaGalleryRow(items: viewModel.tvShows, style: .poster)
                    }
                }

                // On Now - Live TV
                if !viewModel.onNowChannels.isEmpty {
                    ForYouGallerySection(
                        title: "On Now",
                        badge: "LIVE",
                        badgeColor: liveRed
                    ) {
                        OnNowGalleryRow(channels: viewModel.onNowChannels, liveTVViewModel: liveTVViewModel)
                    }
                }

                // Recent Recordings
                if !viewModel.recentRecordings.isEmpty {
                    ForYouGallerySection(title: "New in Your Library") {
                        RecordingsGalleryRow(recordings: viewModel.recentRecordings)
                    }
                }

                // Recent Channels
                if !viewModel.recentChannels.isEmpty {
                    ForYouGallerySection(title: "Recent Channels") {
                        RecentChannelsGalleryRow(channels: viewModel.recentChannels, liveTVViewModel: liveTVViewModel)
                    }
                }

                // Sports (if available)
                if !viewModel.sports.isEmpty {
                    ForYouGallerySection(title: "Sports", badge: "LIVE", badgeColor: liveRed) {
                        OnNowGalleryRow(channels: viewModel.sports, liveTVViewModel: liveTVViewModel)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
        .background(bgColor)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            async let forYou: () = viewModel.load()
            async let liveTVChannels: () = liveTVViewModel.loadChannels()
            async let liveTVGuide: () = liveTVViewModel.loadGuide()
            _ = await (forYou, liveTVChannels, liveTVGuide)
        }
    }
}

// MARK: - Hero Banner Carousel
struct HeroBannerCarousel: View {
    let items: [ForYouHeroItem]
    @Binding var selectedIndex: Int
    let accentColor: Color
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 12) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HeroBannerCard(item: item, accentColor: accentColor)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 380)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<items.count, id: \.self) { index in
                    Circle()
                        .fill(index == selectedIndex ? accentColor : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: selectedIndex)
                }
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                selectedIndex = (selectedIndex + 1) % max(items.count, 1)
            }
        }
    }
}

// MARK: - Hero Banner Card
struct HeroBannerCard: View {
    let item: ForYouHeroItem
    let accentColor: Color

    var body: some View {
        Button {
            if let mediaId = item.mediaId {
                presentMediaDetail(mediaId: mediaId)
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Blurred poster as full-bleed background
                AuthenticatedImage(path: item.imagePath, systemPlaceholder: "play.rectangle")
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 380)
                    .clipped()
                    .blur(radius: 20)
                    .scaleEffect(1.1) // prevent blur edges showing

                // Sharp poster centered
                AuthenticatedImage(path: item.imagePath, systemPlaceholder: "play.rectangle")
                    .aspectRatio(2/3, contentMode: .fit)
                    .frame(height: 280)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                    .frame(maxWidth: .infinity)
                    .offset(y: -30)

                // Gradient overlay for text legibility
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Content at bottom
                VStack(alignment: .leading, spacing: 6) {
                    if let badge = item.badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentColor)
                            .cornerRadius(4)
                    }

                    Text(item.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .padding(16)
            }
            .frame(height: 380)
            .clipped()
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gallery Section Container
struct ForYouGallerySection<Content: View>: View {
    let title: String
    var badge: String? = nil
    var badgeColor: Color = .red
    var showViewAll: Bool = false
    var onViewAll: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(badgeColor)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                if showViewAll {
                    Button {
                        onViewAll?()
                    } label: {
                        Text("View All")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Content
            content()
        }
    }
}

// MARK: - On Now Row (Live TV channels)
struct OnNowGalleryRow: View {
    let channels: [Channel]
    @ObservedObject var liveTVViewModel: LiveTVViewModel
    @State private var selectedChannel: Channel?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(channels) { channel in
                    OnNowGalleryTile(channel: channel) {
                        selectedChannel = channel
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .fullScreenCover(item: $selectedChannel) { channel in
            LiveChannelPlayerView(
                channel: channel,
                viewModel: liveTVViewModel,
                channels: liveTVViewModel.channels.isEmpty ? channels : liveTVViewModel.channels
            ) {
                selectedChannel = nil
            }
        }
    }
}

// MARK: - On Now Tile
struct OnNowGalleryTile: View {
    let channel: Channel
    let onTap: () -> Void
    
    private let liveRed = Color(red: 208/255, green: 2/255, blue: 27/255)
    
    /// Resolve EPG image value to a full URL (handles Gracenote TMS IDs)
    private static func resolveImageURL(_ val: String?) -> String? {
        guard let val = val, !val.isEmpty else { return nil }
        if val.hasPrefix("http://") || val.hasPrefix("https://") { return val }
        if val.hasPrefix("//") { return "https:" + val }
        // Gracenote/TMS asset IDs (e.g., "p200944_b_v13_az")
        if (val.hasPrefix("p") || val.hasPrefix("GN")) && !val.contains("/") {
            return "https://www.tmsimg.com/assets/" + val + ".jpg"
        }
        return nil
    }

    /// Program artwork (icon or art) if available, resolved to full URL
    private var programArtwork: String? {
        Self.resolveImageURL(channel.nowPlaying?.icon) ?? Self.resolveImageURL(channel.nowPlaying?.art)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if let artwork = programArtwork {
                        // Program artwork as background
                        AuthenticatedImage(path: artwork, systemPlaceholder: "tv")
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 90)
                            .clipped()
                    } else {
                        // Fallback: channel logo on dark card
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 160, height: 90)

                        AuthenticatedImage(
                            path: channel.logo,
                            systemPlaceholder: "tv"
                        )
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 50)
                        .frame(width: 160, height: 90)
                    }

                    // Live badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(liveRed)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .padding(8)
                }
                .frame(width: 160, height: 90)
                .cornerRadius(8)

                // Channel info
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let program = channel.nowPlaying {
                        Text(program.title)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Continue Watching Row
struct ContinueWatchingGalleryRow: View {
    let items: [ForYouContinueItem]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items) { item in
                    ContinueWatchingGalleryTile(item: item) {
                        guard let windowScene = UIApplication.shared.connectedScenes
                                .compactMap({ $0 as? UIWindowScene })
                                .first(where: { $0.activationState == .foregroundActive })
                        else { return }
                        if let url = item.recordingURL {
                            PlayerWindowManager.shared.present(
                                playerView: VideoPlayerView(
                                    mediaItem: item.mediaItem,
                                    recordingURL: url,
                                    startPosition: item.progress
                                ),
                                in: windowScene
                            )
                        } else if let mediaItem = item.mediaItem {
                            PlayerWindowManager.shared.present(mediaItem: mediaItem, in: windowScene)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Continue Watching Tile
struct ContinueWatchingGalleryTile: View {
    let item: ForYouContinueItem
    let onTap: () -> Void
    
    private let accentPurple = Color(red: 97/255, green: 56/255, blue: 245/255)
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottom) {
                    // Thumbnail
                    AuthenticatedImage(
                        path: item.thumbnailPath,
                        systemPlaceholder: "play.rectangle"
                    )
                    .aspectRatio(contentMode: .fill)

                    // Progress bar
                    GeometryReader { geo in
                        VStack {
                            Spacer()
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 3)

                                Rectangle()
                                    .fill(accentPurple)
                                    .frame(width: geo.size.width * item.progressPercent, height: 3)
                            }
                        }
                    }
                }
                .frame(width: 160, height: 90)
                .clipped()
                .cornerRadius(8)
                
                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(item.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recordings Row
struct RecordingsGalleryRow: View {
    let recordings: [Recording]
    @State private var playbackItem: PlaybackItem?

    private let dvrRepo = DVRRepository()

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(recordings) { recording in
                    RecordingGalleryTile(recording: recording) {
                        Task {
                            if let url = try? await dvrRepo.getRecordingStream(id: recording.id) {
                                playbackItem = PlaybackItem(recording: recording, url: url, startPosition: recording.viewOffset)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .fullScreenCover(item: $playbackItem) { item in
            VideoPlayerView(
                mediaItem: nil,
                recordingURL: item.url,
                startPosition: item.startPosition,
                commercials: item.recording.commercials,
                recordingDurationMs: item.recording.duration
            )
        }
    }
}

// MARK: - Recording Tile
struct RecordingGalleryTile: View {
    let recording: Recording
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                AuthenticatedImage(
                    path: recording.thumb ?? recording.art,
                    systemPlaceholder: "play.rectangle"
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: 160, height: 90)
                .clipped()
                .cornerRadius(8)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(recording.fullTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let channelName = recording.channelName {
                        Text(channelName)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Channels Row
struct RecentChannelsGalleryRow: View {
    let channels: [Channel]
    @ObservedObject var liveTVViewModel: LiveTVViewModel
    @State private var selectedChannel: Channel?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(channels) { channel in
                    RecentChannelGalleryTile(channel: channel) {
                        selectedChannel = channel
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .fullScreenCover(item: $selectedChannel) { channel in
            LiveChannelPlayerView(
                channel: channel,
                viewModel: liveTVViewModel,
                channels: liveTVViewModel.channels.isEmpty ? channels : liveTVViewModel.channels
            ) {
                selectedChannel = nil
            }
        }
    }
}

// MARK: - Recent Channel Tile
struct RecentChannelGalleryTile: View {
    let channel: Channel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Channel logo
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 70, height: 70)

                    AuthenticatedImage(path: channel.logo, systemPlaceholder: "tv")
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                }

                // Channel number
                Text(channel.displayNumber)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Media Row (Movies/TV Shows) - Multi-Source Aware
struct MediaGalleryRow: View {
    let items: [MultiSourceItem]
    let style: MediaGalleryTileStyle
    @State private var selectedItem: MultiSourceItem?
    @State private var showSourcePicker = false

    enum MediaGalleryTileStyle {
        case poster   // 2:3 ratio
        case landscape // 16:9 ratio
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items) { item in
                    MediaGalleryTile(item: item, style: style) {
                        if item.hasMultipleSources {
                            selectedItem = item
                            showSourcePicker = true
                        } else {
                            presentMediaDetail(mediaId: item.primaryItem.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showSourcePicker) {
            if let item = selectedItem {
                SourcePickerSheet(item: item) { mediaId in
                    showSourcePicker = false
                    presentMediaDetail(mediaId: mediaId)
                }
            }
        }
    }
}

// MARK: - Legacy MediaGalleryRow for plain MediaItem arrays
struct MediaGalleryRowLegacy: View {
    let items: [MediaItem]
    let style: MediaGalleryRow.MediaGalleryTileStyle
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items) { item in
                    MediaGalleryTileLegacy(item: item, style: style) {
                        selectedItem = item
                        showDetail = true
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .fullScreenCover(isPresented: $showDetail) {
            if let item = selectedItem {
                NavigationStack {
                    MediaDetailView(mediaId: item.id)
                }
            }
        }
    }
}

// MARK: - Source Picker Sheet
struct SourcePickerSheet: View {
    let item: MultiSourceItem
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 17/255, green: 12/255, blue: 33/255)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Movie poster + title
                        HStack(spacing: 16) {
                            AuthenticatedImage(
                                path: item.thumb,
                                systemPlaceholder: item.type == .movie ? "film" : "tv"
                            )
                            .aspectRatio(2/3, contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .clipped()
                            .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title)
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.white)

                                if let year = item.year {
                                    Text(String(year))
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.6))
                                }

                                Text("\(item.sources.count) sources available")
                                    .font(.caption)
                                    .foregroundColor(OpenFlixColors.accent)
                            }

                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Divider().overlay(Color.white.opacity(0.1))

                        // Source list
                        VStack(spacing: 12) {
                            ForEach(Array(item.sources.enumerated()), id: \.offset) { index, source in
                                Button {
                                    onSelect(source.item.id)
                                } label: {
                                    HStack(spacing: 14) {
                                        // Source icon
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(OpenFlixColors.accent)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(source.sectionName)
                                                .font(.headline)
                                                .foregroundColor(.white)

                                            HStack(spacing: 8) {
                                                if let resolution = source.item.resolution {
                                                    Text(resolution)
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.7))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.white.opacity(0.15))
                                                        .cornerRadius(4)
                                                }

                                                if let version = source.item.mediaVersions.first {
                                                    if let codec = version.videoCodec {
                                                        Text(codec.uppercased())
                                                            .font(.caption)
                                                            .foregroundColor(.white.opacity(0.7))
                                                    }

                                                    if let size = version.parts.first?.size {
                                                        Text(formatFileSize(size))
                                                            .font(.caption)
                                                            .foregroundColor(.white.opacity(0.5))
                                                    }
                                                }
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Choose Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(OpenFlixColors.accent)
                }
            }
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        }
        let mb = Double(bytes) / 1_048_576
        return String(format: "%.0f MB", mb)
    }
}

// MARK: - Media Tile (Multi-Source)
struct MediaGalleryTile: View {
    let item: MultiSourceItem
    let style: MediaGalleryRow.MediaGalleryTileStyle
    let onTap: () -> Void

    private var displayThumb: String? {
        let primary = item.primaryItem
        if primary.type == .episode {
            return primary.grandparentThumb ?? primary.thumb
        }
        return item.thumb ?? primary.thumb
    }

    private var displayTitle: String {
        let primary = item.primaryItem
        if primary.type == .episode {
            return primary.grandparentTitle ?? item.title
        }
        return item.title
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    AuthenticatedImage(
                        path: displayThumb,
                        systemPlaceholder: item.type == .movie ? "film" : "tv"
                    )
                    .aspectRatio(style == .poster ? 2/3 : 16/9, contentMode: .fill)
                    .frame(width: style == .poster ? 120 : 160)
                    .clipped()
                    .cornerRadius(8)

                    // Multi-source badge
                    if item.hasMultipleSources {
                        Text("\(item.sources.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(OpenFlixColors.accent)
                            .clipShape(Circle())
                            .padding(4)
                    }
                }

                Text(displayTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(width: style == .poster ? 110 : 160, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legacy Media Tile (for plain MediaItem)
struct MediaGalleryTileLegacy: View {
    let item: MediaItem
    let style: MediaGalleryRow.MediaGalleryTileStyle
    let onTap: () -> Void

    private var displayThumb: String? {
        if item.type == .episode {
            return item.grandparentThumb ?? item.thumb
        }
        return item.thumb
    }

    private var displayTitle: String {
        if item.type == .episode {
            return item.grandparentTitle ?? item.title
        }
        return item.title
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                AuthenticatedImage(
                    path: displayThumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .aspectRatio(style == .poster ? 2/3 : 16/9, contentMode: .fill)
                .frame(width: style == .poster ? 120 : 160)
                .clipped()
                .cornerRadius(8)

                Text(displayTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(width: style == .poster ? 110 : 160, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View Model
@MainActor
class ForYouViewModel: ObservableObject {
    @Published var heroItems: [ForYouHeroItem] = []
    @Published var onNowChannels: [Channel] = []
    @Published var continueWatching: [ForYouContinueItem] = []
    @Published var recentRecordings: [Recording] = []
    @Published var recentChannels: [Channel] = []
    @Published var movies: [MultiSourceItem] = []
    @Published var tvShows: [MultiSourceItem] = []
    @Published var sports: [Channel] = []
    @Published var isLoading = false

    private let liveTVRepo = LiveTVRepository()
    private let dvrRepo = DVRRepository()
    private let mediaRepo = MediaRepository()

    func load() async {
        guard !isLoading else { return }
        isLoading = true

        await loadChannels()
        await loadRecordings()
        await loadMedia()

        isLoading = false
    }

    func refresh() async {
        isLoading = false
        await load()
    }

    private func loadChannels() async {
        do {
            try await liveTVRepo.loadChannels()
            let channels = liveTVRepo.channels

            // On Now - first 10 channels with current programs
            onNowChannels = Array(channels.filter { $0.nowPlaying != nil }.prefix(10))

            // Recent channels (could be from UserDefaults, for now just sample)
            recentChannels = Array(channels.prefix(8))

            // Sports channels
            sports = channels.filter { channel in
                channel.name.lowercased().contains("espn") ||
                channel.name.lowercased().contains("sport") ||
                channel.name.lowercased().contains("fox sports")
            }.prefix(10).map { $0 }

            // Create hero items from featured channels/programs
            heroItems = channels.prefix(5).compactMap { channel -> ForYouHeroItem? in
                guard let program = channel.nowPlaying else { return nil }
                return ForYouHeroItem(
                    id: "\(channel.id)-\(program.id)",
                    title: program.title,
                    subtitle: "On \(channel.name)",
                    imagePath: program.icon ?? program.art ?? channel.logo,
                    badge: "LIVE",
                    mediaId: nil,
                    channelId: channel.id
                )
            }
        } catch {
            print("Failed to load channels: \(error)")
        }
    }

    private func loadRecordings() async {
        do {
            try await dvrRepo.loadRecordings()
            let recordings = dvrRepo.recordings

            // Recent recordings (newest first by start time)
            recentRecordings = Array(recordings.sorted(by: { $0.startTime > $1.startTime }).prefix(10))

            // Continue watching - in-progress recordings
            continueWatching = recordings
                .filter { $0.isInProgress }
                .prefix(10)
                .map { recording in
                    ForYouContinueItem(
                        id: String(recording.id),
                        title: recording.fullTitle,
                        subtitle: recording.channelName ?? "",
                        thumbnailPath: recording.thumb ?? recording.art,
                        progressPercent: recording.progressPercent,
                        mediaItem: nil,
                        recordingURL: nil,
                        progress: recording.viewOffset
                    )
                }
        } catch {
            print("Failed to load recordings: \(error)")
        }
    }

    private func loadMedia() async {
        do {
            let sections = try await mediaRepo.getLibrarySections()

            // Load from ALL movie sections
            let movieSections = sections.filter { $0.type == .movie }
            var allMovieSources: [(sectionName: String, items: [MediaItem])] = []

            for section in movieSections {
                let items = (try? await mediaRepo.getSectionRecentlyAdded(sectionId: section.id, limit: 30)) ?? []
                allMovieSources.append((sectionName: section.title, items: items))
            }

            movies = MultiSourceItem.merge(from: allMovieSources, type: .movie, limit: 15)

            // Load from ALL TV show sections
            let tvSections = sections.filter { $0.type == .show }
            var allTVSources: [(sectionName: String, items: [MediaItem])] = []

            for section in tvSections {
                let items = (try? await mediaRepo.getSectionRecentlyAdded(sectionId: section.id, limit: 30)) ?? []
                allTVSources.append((sectionName: section.title, items: items))
            }

            tvShows = MultiSourceItem.merge(from: allTVSources, type: .show, limit: 15)

            // Movie heroes first (reliable poster art), then live heroes after
            let movieHeroes = movies.prefix(3).compactMap { multi -> ForYouHeroItem? in
                guard let thumb = multi.thumb else { return nil }
                let movie = multi.primaryItem
                return ForYouHeroItem(
                    id: "movie-\(movie.id)",
                    title: multi.title,
                    subtitle: multi.year.map { String($0) },
                    imagePath: thumb,
                    badge: "MOVIE",
                    mediaId: movie.id,
                    channelId: nil
                )
            }
            heroItems = movieHeroes + heroItems.filter { $0.imagePath != nil }
        } catch {
            print("Failed to load media: \(error)")
        }
    }
}

// MARK: - Models
struct ForYouHeroItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let imagePath: String?
    let badge: String?
    let mediaId: Int?
    let channelId: String?
}

struct ForYouContinueItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let thumbnailPath: String?
    let progressPercent: CGFloat
    let mediaItem: MediaItem?
    let recordingURL: URL?
    let progress: Int?
}

// MARK: - Multi-Source Item

struct MultiSourceItem: Identifiable {
    let id: String                    // normalized merge key
    let title: String
    let year: Int?
    let thumb: String?
    let art: String?
    let type: MediaType
    let sources: [(sectionName: String, item: MediaItem)]

    var primaryItem: MediaItem { sources[0].item }
    var hasMultipleSources: Bool { sources.count > 1 }
    var hasSources: Bool { !sources.isEmpty }

    /// Normalize a show name for deduplication: strip year patterns, punctuation, extra spaces
    private static func normalizeShowName(_ name: String) -> String {
        var s = name.lowercased()
        // Remove year patterns: "(2018)", "2018", "(2018) -", trailing " -"
        s = s.replacingOccurrences(of: #"\s*\(\d{4}\)\s*-?\s*$"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s+\d{4}\s*$"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s*-\s*$"#, with: "", options: .regularExpression)
        // Remove punctuation (keep alphanumeric and spaces)
        s = s.replacingOccurrences(of: #"[^\w\s]"#, with: "", options: .regularExpression)
        // Collapse whitespace
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// Merge items from multiple sections, deduplicating by normalized title+year (movies) or show name (TV)
    static func merge(
        from sectionData: [(sectionName: String, items: [MediaItem])],
        type: MediaType,
        limit: Int
    ) -> [MultiSourceItem] {
        // key -> (title, year, thumb, art, type, sources keyed by sectionName)
        var merged: [String: (title: String, year: Int?, thumb: String?, art: String?, type: MediaType, sourceBySectionName: [String: MediaItem])] = [:]
        var insertionOrder: [String] = []

        for (sectionName, items) in sectionData {
            for item in items {
                let key: String
                let displayTitle: String

                if type == .show {
                    // For TV, group by normalized show name
                    let showName = item.grandparentTitle ?? item.parentTitle ?? item.title
                    key = normalizeShowName(showName)
                    displayTitle = showName
                } else {
                    // For movies, group by normalized title + year
                    displayTitle = item.title
                    key = normalizeShowName(item.title) + "-" + String(item.year ?? 0)
                }

                if var existing = merged[key] {
                    // Only add one entry per section (for TV, avoid duplicate episodes from same section)
                    if existing.sourceBySectionName[sectionName] == nil {
                        existing.sourceBySectionName[sectionName] = item
                    }
                    // Prefer better artwork
                    if existing.art == nil && item.art != nil { existing.art = item.art }
                    if existing.thumb == nil && item.thumb != nil {
                        existing.thumb = type == .show ? (item.grandparentThumb ?? item.thumb) : item.thumb
                    }
                    merged[key] = existing
                } else {
                    let thumb = type == .show ? (item.grandparentThumb ?? item.thumb) : item.thumb
                    merged[key] = (
                        title: displayTitle,
                        year: item.year,
                        thumb: thumb,
                        art: item.art,
                        type: item.type,
                        sourceBySectionName: [sectionName: item]
                    )
                    insertionOrder.append(key)
                }
            }
        }

        let result = insertionOrder.prefix(limit).compactMap { key -> MultiSourceItem? in
            guard let data = merged[key], !data.sourceBySectionName.isEmpty else { return nil }
            let sources = data.sourceBySectionName.map { (sectionName: $0.key, item: $0.value) }
            return MultiSourceItem(
                id: key,
                title: data.title,
                year: data.year,
                thumb: data.thumb,
                art: data.art,
                type: data.type,
                sources: sources
            )
        }
        return result
    }
}

// MARK: - UIKit Presentation Helpers

/// Present MediaDetailView via UIKit — avoids fullScreenCover unreliability inside LazyVStack
func presentMediaDetail(mediaId: Int) {
    guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
          let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    else { return }
    var topVC = rootVC
    while let presented = topVC.presentedViewController {
        topVC = presented
    }
    let hosting = UIHostingController(rootView: MediaDetailView(mediaId: mediaId))
    hosting.modalPresentationStyle = .fullScreen
    topVC.present(hosting, animated: true)
}

#Preview {
    ForYouView()
}
