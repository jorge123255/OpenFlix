import SwiftUI

// MARK: - Gallery Row (Xfinity-style horizontal scrolling section)
struct GalleryRow<Content: View, Item: Identifiable>: View {
    let title: String
    let items: [Item]
    let showViewAll: Bool
    let onViewAll: (() -> Void)?
    let content: (Item) -> Content
    
    init(
        title: String,
        items: [Item],
        showViewAll: Bool = true,
        onViewAll: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.title = title
        self.items = items
        self.showViewAll = showViewAll
        self.onViewAll = onViewAll
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: XfinitySpacing.p2) {
            // Header
            HStack {
                Text(title)
                    .font(XfinityTypography.title3)
                    .foregroundColor(XfinityColors.textPrimary)
                
                Spacer()
                
                if showViewAll && !items.isEmpty {
                    Button("View All") {
                        onViewAll?()
                    }
                    .buttonStyle(XfinityOutlineButtonStyle())
                }
            }
            .padding(.horizontal, XfinitySpacing.galleryOuterPadding)
            
            // Scrolling content
            if items.isEmpty {
                // Loading state
                HStack(spacing: XfinitySpacing.galleryItemSpacing) {
                    ForEach(0..<4, id: \.self) { _ in
                        ShimmerTile()
                    }
                }
                .padding(.horizontal, XfinitySpacing.galleryOuterPadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: XfinitySpacing.galleryItemSpacing) {
                        ForEach(items) { item in
                            content(item)
                        }
                    }
                    .padding(.horizontal, XfinitySpacing.galleryOuterPadding)
                }
            }
        }
        .padding(.bottom, XfinitySpacing.sectionSpacing)
    }
}

// MARK: - Shimmer Loading Tile
struct ShimmerTile: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: XfinityDimensions.cornerRadiusMedium)
            .fill(XfinityColors.shimmer)
            .frame(width: XfinityDimensions.posterWidth, height: XfinityDimensions.posterHeight)
            .overlay(
                RoundedRectangle(cornerRadius: XfinityDimensions.cornerRadiusMedium)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Poster Tile (Movies/Shows)
struct PosterTile: View {
    let item: MediaItem
    let progress: Double?
    let onTap: () -> Void
    
    init(item: MediaItem, progress: Double? = nil, onTap: @escaping () -> Void) {
        self.item = item
        self.progress = progress
        self.onTap = onTap
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: XfinitySpacing.p2) {
                // Poster image
                ZStack(alignment: .bottom) {
                    AsyncImage(url: URL(string: item.thumb ?? item.art ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            Rectangle()
                                .fill(XfinityColors.backgroundTertiary)
                                .overlay(
                                    Image(systemName: "film")
                                        .font(.system(size: 30))
                                        .foregroundColor(XfinityColors.textTertiary)
                                )
                        case .empty:
                            Rectangle()
                                .fill(XfinityColors.shimmer)
                        @unknown default:
                            Rectangle()
                                .fill(XfinityColors.backgroundTertiary)
                        }
                    }
                    .frame(width: XfinityDimensions.posterWidth, height: XfinityDimensions.posterHeight)
                    .clipped()
                    .cornerRadius(XfinityDimensions.cornerRadiusMedium)
                    
                    // Progress bar overlay
                    if let progress = progress, progress > 0 {
                        VStack {
                            Spacer()
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(height: XfinityDimensions.progressBarHeight)
                                    
                                    Rectangle()
                                        .fill(XfinityColors.progress)
                                        .frame(width: geo.size.width * CGFloat(progress), height: XfinityDimensions.progressBarHeight)
                                }
                            }
                            .frame(height: XfinityDimensions.progressBarHeight)
                            .padding(.horizontal, XfinitySpacing.p2)
                            .padding(.bottom, XfinitySpacing.p2)
                        }
                    }
                }
                
                // Title
                Text(item.title)
                    .font(XfinityTypography.footnote)
                    .foregroundColor(XfinityColors.textPrimary)
                    .lineLimit(1)
                    .frame(width: XfinityDimensions.posterWidth, alignment: .leading)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Landscape Tile (Featured/Recommended)
struct LandscapeTile: View {
    let item: MediaItem
    let subtitle: String?
    let onTap: () -> Void
    
    init(item: MediaItem, subtitle: String? = nil, onTap: @escaping () -> Void) {
        self.item = item
        self.subtitle = subtitle
        self.onTap = onTap
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: XfinitySpacing.p2) {
                // Thumbnail
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: item.art ?? item.thumb ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            Rectangle()
                                .fill(XfinityColors.backgroundTertiary)
                                .overlay(
                                    Image(systemName: "tv")
                                        .font(.system(size: 30))
                                        .foregroundColor(XfinityColors.textTertiary)
                                )
                        case .empty:
                            Rectangle()
                                .fill(XfinityColors.shimmer)
                        @unknown default:
                            Rectangle()
                                .fill(XfinityColors.backgroundTertiary)
                        }
                    }
                    .frame(width: XfinityDimensions.landscapeWidth, height: XfinityDimensions.landscapeHeight)
                    .clipped()
                    .cornerRadius(XfinityDimensions.cornerRadiusMedium)
                    
                    // Gradient overlay
                    XfinityColors.cardGradient
                        .cornerRadius(XfinityDimensions.cornerRadiusMedium)
                }
                
                // Title
                Text(item.title)
                    .font(XfinityTypography.footnote)
                    .foregroundColor(XfinityColors.textPrimary)
                    .lineLimit(1)
                
                // Subtitle
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(XfinityTypography.caption)
                        .foregroundColor(XfinityColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(width: XfinityDimensions.landscapeWidth)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Channel Tile (Live TV)
struct ChannelTile: View {
    let channel: Channel
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: XfinitySpacing.p2) {
                // Channel logo area
                ZStack {
                    RoundedRectangle(cornerRadius: XfinityDimensions.cornerRadiusMedium)
                        .fill(XfinityColors.backgroundTertiary)
                        .frame(width: XfinityDimensions.channelTileWidth, height: XfinityDimensions.channelTileHeight)
                    
                    if let logoURL = channel.logo, let url = URL(string: logoURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 40)
                            default:
                                Text(channel.name.prefix(3).uppercased())
                                    .font(XfinityTypography.title3)
                                    .foregroundColor(XfinityColors.textPrimary)
                            }
                        }
                    } else {
                        Text(channel.name.prefix(3).uppercased())
                            .font(XfinityTypography.title3)
                            .foregroundColor(XfinityColors.textPrimary)
                    }
                }
                
                // Channel number and name
                VStack(spacing: 2) {
                    if let number = channel.number {
                        Text("\(number)")
                            .font(XfinityTypography.captionBold)
                            .foregroundColor(XfinityColors.textSecondary)
                    }
                    
                    Text(channel.name)
                        .font(XfinityTypography.footnote)
                        .foregroundColor(XfinityColors.textPrimary)
                        .lineLimit(1)
                }
                .frame(width: XfinityDimensions.channelTileWidth)
                
                // On Now label
                if let nowPlaying = channel.nowPlaying {
                    HStack(spacing: 4) {
                        Text("ON NOW")
                            .font(XfinityTypography.captionBold)
                            .foregroundColor(XfinityColors.live)
                        
                        Text(nowPlaying.title)
                            .font(XfinityTypography.caption)
                            .foregroundColor(XfinityColors.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(width: XfinityDimensions.channelTileWidth, alignment: .leading)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

