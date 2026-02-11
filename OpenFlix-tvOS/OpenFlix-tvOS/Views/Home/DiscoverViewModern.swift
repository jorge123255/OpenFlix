import SwiftUI

// MARK: - Modern Discover View
// Premium Apple TV+ inspired home screen with parallax, glass effects, and smooth animations

struct DiscoverViewModern: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var showPlayer = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.onDeck.isEmpty && viewModel.featured.isEmpty {
                    ModernLoadingView()
                } else if let error = viewModel.error {
                    ModernErrorView(message: error) {
                        Task { await viewModel.loadHomeContent() }
                    }
                } else {
                    contentView
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showDetail) {
                if let item = selectedItem {
                    MediaDetailViewModern(item: item)
                }
            }
        }
        .task {
            await viewModel.loadHomeContent()
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let item = selectedItem {
                VideoPlayerView(mediaItem: item, startPosition: item.viewOffset)
            }
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Hero Banner with Parallax
                if viewModel.hasFeatured {
                    ModernHeroBanner(
                        items: viewModel.featured,
                        scrollOffset: scrollOffset,
                        onPlay: { item in
                            selectedItem = item
                            showPlayer = true
                        },
                        onDetails: { item in
                            selectedItem = item
                            showDetail = true
                        },
                        onWatchlist: { item in
                            Task {
                                await viewModel.toggleWatchlist(for: item)
                            }
                        }
                    )
                    .focusSection()
                }
                
                // Content sections with staggered animation
                VStack(alignment: .leading, spacing: 48) {
                    // Continue Watching
                    if viewModel.hasContinueWatching {
                        ModernContentRow(
                            title: "Continue Watching",
                            subtitle: "Pick up where you left off",
                            icon: "play.circle.fill",
                            accentColor: .blue,
                            items: viewModel.onDeck,
                            style: .continueWatching
                        ) { item in
                            selectedItem = item
                            showPlayer = true
                        }
                        .focusSection()
                    }
                    
                    // Top 10
                    if viewModel.hasTopTen {
                        ModernTop10Row(items: viewModel.topTen) { item in
                            selectedItem = item
                            showDetail = true
                        }
                        .focusSection()
                    }
                    
                    // Recently Added
                    if viewModel.hasRecentlyAdded {
                        ModernContentRow(
                            title: "Recently Added",
                            subtitle: "Fresh content in your library",
                            icon: "sparkles",
                            accentColor: OpenFlixColors.accent,
                            items: viewModel.recentlyAdded,
                            style: .poster
                        ) { item in
                            selectedItem = item
                            showDetail = true
                        }
                        .focusSection()
                    }
                    
                    // Streaming Service Hubs
                    ForEach(viewModel.streamingServices) { service in
                        ModernServiceHub(service: service) { item in
                            selectedItem = item
                            showDetail = true
                        }
                        .focusSection()
                    }
                    
                    // Hubs from server
                    ForEach(viewModel.hubs) { hub in
                        ModernContentRow(
                            title: hub.title,
                            subtitle: nil,
                            icon: hubIcon(for: hub.title),
                            accentColor: hubColor(for: hub.title),
                            items: hub.items,
                            style: .poster
                        ) { item in
                            selectedItem = item
                            showDetail = true
                        }
                        .focusSection()
                    }
                    
                    // Recommended
                    if viewModel.hasRecommended {
                        ModernContentRow(
                            title: "Recommended For You",
                            subtitle: "Based on your viewing history",
                            icon: "wand.and.stars",
                            accentColor: .purple,
                            items: viewModel.recommended,
                            style: .wide
                        ) { item in
                            selectedItem = item
                            showDetail = true
                        }
                        .focusSection()
                    }
                }
                .padding(.top, 40)
                
                // Bottom spacing
                Spacer().frame(height: 80)
            }
        }
        .background(
            // Ambient background that shifts with content
            AmbientBackground(items: viewModel.featured)
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Helpers
    
    private func hubIcon(for title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("action") { return "flame.fill" }
        if lower.contains("comedy") { return "face.smiling.fill" }
        if lower.contains("drama") { return "theatermasks.fill" }
        if lower.contains("horror") { return "moon.fill" }
        if lower.contains("sci") { return "sparkles.tv.fill" }
        if lower.contains("documentary") { return "doc.text.fill" }
        if lower.contains("family") { return "figure.2.and.child.holdinghands" }
        return "film.fill"
    }
    
    private func hubColor(for title: String) -> Color {
        let lower = title.lowercased()
        if lower.contains("action") { return .red }
        if lower.contains("comedy") { return .yellow }
        if lower.contains("drama") { return .purple }
        if lower.contains("horror") { return .gray }
        if lower.contains("sci") { return .cyan }
        if lower.contains("family") { return .green }
        return OpenFlixColors.accent
    }
}

// MARK: - Modern Hero Banner with Parallax

struct ModernHeroBanner: View {
    let items: [MediaItem]
    let scrollOffset: CGFloat
    var onPlay: ((MediaItem) -> Void)?
    var onDetails: ((MediaItem) -> Void)?
    var onWatchlist: ((MediaItem) -> Void)?
    
    @State private var currentIndex = 0
    @State private var autoAdvanceTimer: Timer?
    @FocusState private var isFocused: Bool
    
    private let autoAdvanceInterval: TimeInterval = 10.0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Pager
            TabView(selection: $currentIndex) {
                ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, item in
                    ModernHeroItem(
                        item: item,
                        parallaxOffset: scrollOffset * 0.3,
                        onPlay: { onPlay?(item) },
                        onDetails: { onDetails?(item) },
                        onWatchlist: { onWatchlist?(item) }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 750)
            
            // Page indicator with blur background
            if items.count > 1 {
                HStack(spacing: 12) {
                    ForEach(0..<min(items.count, 5), id: \.self) { index in
                        Capsule()
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: index == currentIndex ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentIndex)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 30)
            }
        }
        .focused($isFocused)
        .onAppear { startAutoAdvance() }
        .onDisappear { stopAutoAdvance() }
        .onChange(of: isFocused) { _, focused in
            if focused { stopAutoAdvance() } else { startAutoAdvance() }
        }
    }
    
    private func startAutoAdvance() {
        guard items.count > 1 else { return }
        stopAutoAdvance()
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: autoAdvanceInterval, repeats: true) { _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentIndex = (currentIndex + 1) % min(items.count, 5)
            }
        }
    }
    
    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }
}

// MARK: - Modern Hero Item

struct ModernHeroItem: View {
    let item: MediaItem
    let parallaxOffset: CGFloat
    var onPlay: () -> Void
    var onDetails: () -> Void
    var onWatchlist: (() -> Void)?
    
    @FocusState private var focusedButton: HeroButton?
    
    enum HeroButton: Hashable {
        case play, watchlist, info
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background art with parallax
                AuthenticatedImage(
                    path: item.art ?? item.thumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height + 100)
                .offset(y: parallaxOffset)
                .clipped()
                
                // Multi-layer gradient overlay
                ZStack {
                    // Bottom fade
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.5), .black.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Left fade for text readability
                    LinearGradient(
                        colors: [.black.opacity(0.7), .black.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    // Vignette
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.3)],
                        center: .center,
                        startRadius: geometry.size.width * 0.3,
                        endRadius: geometry.size.width * 0.8
                    )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    // Logo or Title
                    Text(item.title)
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                        .lineLimit(2)
                    
                    Spacer().frame(height: 16)
                    
                    // Tagline
                    if let tagline = item.tagline {
                        Text(tagline)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                    
                    Spacer().frame(height: 20)
                    
                    // Metadata row
                    HStack(spacing: 16) {
                        // Type badge
                        HStack(spacing: 6) {
                            Image(systemName: item.type == .movie ? "film" : "tv")
                            Text(item.type.displayName)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.15))
                        .cornerRadius(6)
                        
                        // Genres
                        if !item.genres.isEmpty {
                            Text(item.genres.prefix(2).joined(separator: " · "))
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Rating badge
                        if let rating = item.contentRating {
                            Text(rating)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(4)
                        }
                        
                        // Year
                        if let year = item.year {
                            Text(String(year))
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Duration
                        let duration = item.durationFormatted
                        if !duration.isEmpty {
                            Text(duration)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Star rating
                        if let audienceRating = item.audienceRating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", audienceRating))
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        }
                    }
                    
                    Spacer().frame(height: 32)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        // Play button - Large white pill
                        Button(action: onPlay) {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 22))
                                Text(item.isInProgress ? "Resume" : "Play")
                                    .font(.system(size: 20, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 18)
                            .background(
                                Capsule()
                                    .fill(.white)
                                    .shadow(color: .white.opacity(focusedButton == .play ? 0.5 : 0), radius: 20)
                            )
                        }
                        .buttonStyle(.plain)
                        .focused($focusedButton, equals: .play)
                        .scaleEffect(focusedButton == .play ? 1.08 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedButton)
                        
                        // Watchlist button
                        if let onWatchlist = onWatchlist {
                            Button(action: onWatchlist) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Circle()
                                                    .stroke(.white.opacity(focusedButton == .watchlist ? 1 : 0.3), lineWidth: 2)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .focused($focusedButton, equals: .watchlist)
                            .scaleEffect(focusedButton == .watchlist ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedButton)
                        }
                        
                        // Info button
                        Button(action: onDetails) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(focusedButton == .info ? 1 : 0.3), lineWidth: 2)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .focused($focusedButton, equals: .info)
                        .scaleEffect(focusedButton == .info ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedButton)
                    }
                    
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 80)
            }
        }
    }
}

// MARK: - Modern Content Row

struct ModernContentRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let accentColor: Color
    let items: [MediaItem]
    let style: CardStyle
    let onSelect: (MediaItem) -> Void
    
    enum CardStyle {
        case poster       // Standard portrait poster
        case wide         // 16:9 landscape
        case continueWatching  // With progress bar
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // See All
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("See All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 48)
            
            // Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(items) { item in
                        switch style {
                        case .poster:
                            ModernPosterCard(item: item, onSelect: { onSelect(item) })
                        case .wide:
                            ModernWideCard(item: item, onSelect: { onSelect(item) })
                        case .continueWatching:
                            ModernContinueCard(item: item, onSelect: { onSelect(item) })
                        }
                    }
                }
                .padding(.horizontal, 48)
            }
        }
    }
}

// MARK: - Modern Poster Card

struct ModernPosterCard: View {
    let item: MediaItem
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Poster
                ZStack(alignment: .bottomLeading) {
                    AuthenticatedImage(
                        path: item.thumb,
                        systemPlaceholder: item.type == .movie ? "film" : "tv"
                    )
                    .aspectRatio(2/3, contentMode: .fill)
                    .frame(width: 180, height: 270)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Gradient overlay on focus
                    if isFocused {
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.7)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Quick info on focus
                    if isFocused {
                        VStack(alignment: .leading, spacing: 4) {
                            if let rating = item.audienceRating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", rating))
                                        .fontWeight(.bold)
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            }
                        }
                        .padding(12)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? OpenFlixColors.accent : .clear,
                            lineWidth: 4
                        )
                )
                .shadow(
                    color: isFocused ? OpenFlixColors.accent.opacity(0.4) : .black.opacity(0.3),
                    radius: isFocused ? 20 : 8,
                    y: isFocused ? 10 : 4
                )
                
                // Title
                Text(item.title)
                    .font(.system(size: 16, weight: isFocused ? .semibold : .regular))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(width: 180, alignment: .leading)
            }
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

// MARK: - Modern Wide Card

struct ModernWideCard: View {
    let item: MediaItem
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottomLeading) {
                AuthenticatedImage(
                    path: item.art ?? item.thumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: 400, height: 225)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Gradient
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let year = item.year {
                            Text(String(year))
                        }
                        if let rating = item.contentRating {
                            Text(rating)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(16)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 4)
            )
            .shadow(
                color: isFocused ? OpenFlixColors.accent.opacity(0.4) : .black.opacity(0.3),
                radius: isFocused ? 20 : 8
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

// MARK: - Modern Continue Watching Card

struct ModernContinueCard: View {
    let item: MediaItem
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomLeading) {
                    // Thumbnail
                    AuthenticatedImage(
                        path: item.art ?? item.thumb,
                        systemPlaceholder: item.type == .movie ? "film" : "tv"
                    )
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 320, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Dark overlay
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.3))
                    
                    // Play icon on focus
                    if isFocused {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Progress bar
                    VStack {
                        Spacer()
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 4)
                                
                                Rectangle()
                                    .fill(OpenFlixColors.accent)
                                    .frame(width: geo.size.width * (item.progress ?? 0), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 3)
                )
                .shadow(
                    color: isFocused ? OpenFlixColors.accent.opacity(0.4) : .black.opacity(0.3),
                    radius: isFocused ? 16 : 8
                )
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let remaining = item.remainingDuration {
                        Text("\(remaining) left")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(width: 320, alignment: .leading)
            }
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

// MARK: - Modern Top 10 Row

struct ModernTop10Row: View {
    let items: [MediaItem]
    let onSelect: (MediaItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Text("TOP")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.red)
                
                Text("10")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("in Your Library")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 48)
            
            // Cards with numbers
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(Array(items.prefix(10).enumerated()), id: \.element.id) { index, item in
                        ModernTop10Card(
                            item: item,
                            rank: index + 1,
                            onSelect: { onSelect(item) }
                        )
                    }
                }
                .padding(.horizontal, 48)
            }
        }
    }
}

// MARK: - Modern Top 10 Card

struct ModernTop10Card: View {
    let item: MediaItem
    let rank: Int
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .bottom, spacing: -30) {
                // Rank number
                Text("\(rank)")
                    .font(.system(size: 140, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black, radius: 4)
                    .offset(y: 20)
                    .zIndex(0)
                
                // Poster
                AuthenticatedImage(
                    path: item.thumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .aspectRatio(2/3, contentMode: .fill)
                .frame(width: 140, height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 3)
                )
                .shadow(
                    color: isFocused ? OpenFlixColors.accent.opacity(0.5) : .black.opacity(0.4),
                    radius: isFocused ? 16 : 8
                )
                .zIndex(1)
            }
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

// MARK: - Modern Service Hub

struct ModernServiceHub: View {
    let service: StreamingService
    let onSelect: (MediaItem) -> Void
    
    var body: some View {
        ModernContentRow(
            title: service.name,
            subtitle: "From \(service.name)",
            icon: "play.rectangle.fill",
            accentColor: serviceColor(for: service.name),
            items: service.items,
            style: .poster,
            onSelect: onSelect
        )
    }
    
    private func serviceColor(for name: String) -> Color {
        let lower = name.lowercased()
        if lower.contains("netflix") { return .red }
        if lower.contains("disney") { return .blue }
        if lower.contains("hbo") || lower.contains("max") { return .purple }
        if lower.contains("amazon") || lower.contains("prime") { return .cyan }
        if lower.contains("apple") { return .gray }
        if lower.contains("hulu") { return .green }
        if lower.contains("paramount") { return .blue }
        if lower.contains("peacock") { return .yellow }
        return OpenFlixColors.accent
    }
}

// MARK: - Ambient Background

struct AmbientBackground: View {
    let items: [MediaItem]
    
    var body: some View {
        ZStack {
            Color.black
            
            if let firstItem = items.first {
                AuthenticatedImage(
                    path: firstItem.art ?? firstItem.thumb,
                    systemPlaceholder: "rectangle"
                )
                .aspectRatio(contentMode: .fill)
                .blur(radius: 100)
                .opacity(0.3)
                .scaleEffect(1.2)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Modern Loading View

struct ModernLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated logo
            Image(systemName: "play.tv.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [OpenFlixColors.accent, OpenFlixColors.accentLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("Loading your library...")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(OpenFlixColors.accent)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Modern Error View

struct ModernErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Modern Detail View Placeholder

struct MediaDetailViewModern: View {
    let item: MediaItem
    
    var body: some View {
        MediaDetailView(mediaId: item.id)
    }
}

#Preview {
    DiscoverViewModern()
}
