import SwiftUI

// MARK: - Xfinity Stream Style Home View

struct XfinityHomeView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var selectedItem: MediaItem?
    @State private var selectedChannel: Channel?
    @State private var showMediaDetail = false
    @State private var showPlayer = false
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.recentlyAdded.isEmpty {
                LoadingView(message: "Loading...")
            } else {
                contentView
            }
        }
        .background(XfinityColors.background.ignoresSafeArea())
        .task {
            await viewModel.loadHomeContent()
        }
        .refreshable {
            await viewModel.loadHomeContent()
        }
        .navigationDestination(isPresented: $showMediaDetail) {
            if let item = selectedItem {
                MediaDetailView(mediaId: item.id)
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let item = selectedItem {
                VideoPlayerView(mediaItem: item, startPosition: item.viewOffset)
            }
        }
    }
    
    // MARK: - Content
    
    private var contentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 32) {
                
                // MARK: Continue Watching (Hero Row)
                if !viewModel.onDeck.isEmpty {
                    XfinityContinueWatchingSection(
                        items: viewModel.onDeck.filter { $0.isInProgress }
                    ) { item in
                        selectedItem = item
                        showPlayer = true
                    }
                }
                
                // MARK: New & Popular
                if !viewModel.recentlyAdded.isEmpty {
                    XfinityPosterSection(
                        title: "New & popular",
                        items: Array(viewModel.recentlyAdded.prefix(15))
                    ) { item in
                        selectedItem = item
                        showMediaDetail = true
                    }
                }
                
                // MARK: Featured Categories
                XfinityFeaturedSection()
                
                // MARK: Hubs from server
                ForEach(viewModel.hubs.prefix(4)) { hub in
                    XfinityPosterSection(
                        title: hub.title,
                        items: Array(hub.items.prefix(12))
                    ) { item in
                        selectedItem = item
                        showMediaDetail = true
                    }
                }
                
                // MARK: Recently Watched
                if !viewModel.onDeck.isEmpty {
                    XfinityRecentlyWatchedSection(
                        items: viewModel.onDeck
                    ) { item in
                        selectedItem = item
                        showMediaDetail = true
                    }
                }
                
                Spacer().frame(height: 100)
            }
            .padding(.top, 16)
        }
    }
}

// MARK: - Section Header

struct XfinitySectionHeader: View {
    let title: String
    var showViewAll: Bool = true
    var onViewAll: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            if showViewAll {
                Button(action: { onViewAll?() }) {
                    Text("View all")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(20)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Continue Watching Section (Hero)

struct XfinityContinueWatchingSection: View {
    let items: [MediaItem]
    let onTap: (MediaItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items) { item in
                        XfinityContinueCard(item: item, onTap: { onTap(item) })
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct XfinityContinueCard: View {
    let item: MediaItem
    let onTap: () -> Void
    
    private var progress: Double {
        guard let duration = item.duration, duration > 0,
              let offset = item.viewOffset else { return 0 }
        return min(Double(offset) / Double(duration), 1.0)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Wide thumbnail
                ZStack(alignment: .bottomLeading) {
                    AuthenticatedImage(
                        path: item.art ?? item.thumb,
                        systemPlaceholder: "play.rectangle"
                    )
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 280, height: 158)
                    .clipped()
                    .cornerRadius(8)
                    
                    // Progress bar at bottom
                    if progress > 0 {
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(XfinityColors.progressBackground)
                                        .frame(height: 4)
                                    
                                    Rectangle()
                                        .fill(XfinityColors.progressBar)
                                        .frame(width: geo.size.width * progress, height: 4)
                                }
                            }
                        }
                        .frame(width: 280, height: 158)
                        .cornerRadius(8)
                    }
                }
                
                // Title
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(width: 280, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Poster Section (New & Popular, etc.)

struct XfinityPosterSection: View {
    let title: String
    let items: [MediaItem]
    let onTap: (MediaItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            XfinitySectionHeader(title: title)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items) { item in
                        XfinityPosterCard(item: item, onTap: { onTap(item) })
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct XfinityPosterCard: View {
    let item: MediaItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AuthenticatedImage(
                path: item.thumb ?? item.art,
                systemPlaceholder: "photo"
            )
            .aspectRatio(2/3, contentMode: .fill)
            .frame(width: 140, height: 210)
            .clipped()
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Featured Categories Section

struct XfinityFeaturedSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            XfinitySectionHeader(title: "Featured", showViewAll: false)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    XfinityFeaturedCard(
                        title: "New & popular\nTV dramas",
                        gradientColors: [.purple, .blue],
                        imageName: "tv"
                    )
                    
                    XfinityFeaturedCard(
                        title: "New & popular\nmovies",
                        gradientColors: [.orange, .pink],
                        imageName: "film"
                    )
                    
                    XfinityFeaturedCard(
                        title: "What to\nWatch",
                        subtitle: "This week's best",
                        gradientColors: [.indigo, .purple],
                        imageName: "star"
                    )
                    
                    XfinityFeaturedCard(
                        title: "Live\nSports",
                        gradientColors: [.green, .teal],
                        imageName: "sportscourt"
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct XfinityFeaturedCard: View {
    let title: String
    var subtitle: String? = nil
    let gradientColors: [Color]
    let imageName: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Gradient background
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(16)
            
            // Icon on right
            HStack {
                Spacer()
                Image(systemName: imageName)
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.trailing, 16)
            }
        }
        .frame(width: 200, height: 120)
        .cornerRadius(12)
    }
}

// MARK: - Recently Watched Section

struct XfinityRecentlyWatchedSection: View {
    let items: [MediaItem]
    let onTap: (MediaItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            XfinitySectionHeader(title: "Recently watched")
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(items.prefix(10)) { item in
                        XfinityRecentCard(item: item, onTap: { onTap(item) })
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct XfinityRecentCard: View {
    let item: MediaItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                AuthenticatedImage(
                    path: item.thumb ?? item.art,
                    systemPlaceholder: "photo"
                )
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: 180, height: 100)
                .clipped()
                .cornerRadius(8)
                
                // Title
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Episode info
                if let grandparentTitle = item.grandparentTitle {
                    Text(grandparentTitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(width: 180)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Live TV Card (for future Live TV section)

struct XfinityLiveTVCard: View {
    let channelLogo: String?
    let channelName: String
    let thumbnail: String?
    let showTitle: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Channel logo
                HStack {
                    if let logo = channelLogo {
                        AsyncImage(url: URL(string: logo)) { phase in
                            if case .success(let image) = phase {
                                image.resizable().aspectRatio(contentMode: .fit)
                            } else {
                                Text(channelName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 24)
                    } else {
                        Text(channelName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                
                // Thumbnail
                AsyncImage(url: URL(string: thumbnail ?? "")) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(XfinityColors.cardBackground)
                    }
                }
                .frame(width: 200, height: 112)
                .clipped()
            }
            .frame(width: 200)
            .background(XfinityColors.cardBackground)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sports Card (for Sports on now section)

struct XfinitySportsCard: View {
    let channelLogo: String?
    let channelName: String
    let thumbnail: String?
    let sportTitle: String
    let eventTitle: String
    var progress: Double = 0
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Channel logo
                HStack {
                    if let logo = channelLogo {
                        AsyncImage(url: URL(string: logo)) { phase in
                            if case .success(let image) = phase {
                                image.resizable().aspectRatio(contentMode: .fit)
                            } else {
                                Text(channelName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 20)
                    } else {
                        Text(channelName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                Spacer()
                
                // Sport title overlay
                VStack(alignment: .leading, spacing: 4) {
                    Text(sportTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Progress bar
                    if progress > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 3)
                                
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: geo.size.width * progress, height: 3)
                            }
                        }
                        .frame(height: 3)
                        .padding(.top, 4)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(width: 200, height: 140)
            .background(
                AsyncImage(url: URL(string: thumbnail ?? "")) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Color.blue.opacity(0.3))
                    }
                }
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        XfinityHomeView()
    }
}
