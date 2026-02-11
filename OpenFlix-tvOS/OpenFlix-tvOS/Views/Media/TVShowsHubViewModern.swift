import SwiftUI

// MARK: - Modern TV Shows Hub View
// Channels DVR 7.0 inspired - Glass morphism, spring animations, theater mode

struct TVShowsHubViewModern: View {
    @StateObject private var viewModel = TVShowsViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var showPlayer = false
    @State private var showGridBrowse = false
    @State private var selectedGenre: String?
    @Namespace private var heroNamespace
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.featuredShows.isEmpty {
                    ModernTVLoadingView()
                } else if let error = viewModel.error {
                    ModernErrorView(message: error) {
                        Task { await viewModel.loadTVShowsHub() }
                    }
                } else if viewModel.featuredShows.isEmpty && viewModel.allShows.isEmpty {
                    ModernEmptyStateView(
                        icon: "tv.and.mediabox",
                        title: "No TV Shows",
                        message: "Your TV library is empty.\nAdd shows to get started."
                    )
                } else {
                    hubContentView
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showDetail) {
                if let item = selectedItem {
                    MediaDetailView(mediaId: item.id)
                }
            }
            .navigationDestination(isPresented: $showGridBrowse) {
                TVShowsGridBrowseViewModern(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadTVShowsHub()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let item = selectedItem {
                VideoPlayerView(mediaItem: item, startPosition: item.viewOffset)
            }
        }
    }
    
    // MARK: - Hub Content
    
    private var hubContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Theater Mode Hero
                if viewModel.hasFeaturedCarousel {
                    TVTheaterModeHero(
                        shows: viewModel.featuredShows,
                        onPlay: { show in
                            selectedItem = show
                            showDetail = true // Go to detail for episode selection
                        },
                        onMoreInfo: { show in
                            selectedItem = show
                            showDetail = true
                        }
                    )
                    .focusSection()
                }
                
                // Content sections with modern styling
                VStack(alignment: .leading, spacing: 48) {
                    // Genre Filter Bar
                    TVGenreFilterBar(
                        genres: viewModel.availableGenres,
                        selectedGenre: $selectedGenre,
                        onBrowseAll: { showGridBrowse = true }
                    )
                    .focusSection()
                    
                    // Continue Watching
                    if viewModel.hasContinueWatching {
                        ModernTVRow(
                            title: "Continue Watching",
                            subtitle: "Pick up where you left off",
                            icon: "play.circle.fill",
                            accentColor: .blue,
                            items: viewModel.continueWatching,
                            style: .continueWatching
                        ) { item in
                            selectedItem = item
                            showPlayer = true
                        }
                        .focusSection()
                    }
                    
                    // Recently Added
                    if viewModel.hasRecentlyAdded {
                        ModernTVRow(
                            title: "Recently Added",
                            subtitle: "Fresh episodes",
                            icon: "sparkles.tv",
                            accentColor: OpenFlixColors.accent,
                            items: viewModel.recentlyAdded,
                            style: .poster
                        ) { item in
                            selectedItem = item
                            showDetail = true
                        }
                        .focusSection()
                    }
                    
                    // Up Next (episodes ready to watch)
                    if viewModel.hasUpNext {
                        ModernTVRow(
                            title: "Up Next",
                            subtitle: "New episodes waiting",
                            icon: "arrow.right.circle.fill",
                            accentColor: .purple,
                            items: viewModel.upNext,
                            style: .episode
                        ) { item in
                            selectedItem = item
                            showPlayer = true
                        }
                        .focusSection()
                    }
                    
                    // Genre filtered content or genre hubs
                    if let genre = selectedGenre {
                        ModernTVRow(
                            title: genre,
                            subtitle: "Shows in this genre",
                            icon: genreIcon(for: genre),
                            accentColor: genreColor(for: genre),
                            items: viewModel.allShows.filter { $0.genres?.contains(genre) == true },
                            style: .poster
                        ) { item in
                            selectedItem = item
                            showDetail = true
                        }
                        .focusSection()
                    } else {
                        ForEach(viewModel.genreHubs.prefix(6), id: \.genre) { hub in
                            ModernTVRow(
                                title: hub.genre,
                                subtitle: "\(hub.items.count) shows",
                                icon: genreIcon(for: hub.genre),
                                accentColor: genreColor(for: hub.genre),
                                items: hub.items,
                                style: .poster
                            ) { item in
                                selectedItem = item
                                showDetail = true
                            }
                            .focusSection()
                        }
                    }
                    
                    Spacer().frame(height: 80)
                }
                .padding(.top, 40)
            }
        }
        .background(
            ZStack {
                Color.black
                // Ambient gradient from hero
                if let show = viewModel.featuredShows.first {
                    AuthenticatedImage(path: show.art ?? show.thumb, systemPlaceholder: "tv")
                        .blur(radius: 100)
                        .opacity(0.3)
                        .ignoresSafeArea()
                }
            }
        )
    }
    
    // MARK: - Genre Helpers
    
    private func genreIcon(for genre: String) -> String {
        switch genre.lowercased() {
        case "drama": return "theatermasks.fill"
        case "comedy": return "face.smiling.fill"
        case "action", "adventure": return "bolt.fill"
        case "sci-fi", "science fiction": return "sparkle"
        case "horror", "thriller": return "eye.fill"
        case "documentary": return "doc.text.fill"
        case "animation", "anime": return "paintbrush.fill"
        case "crime": return "shield.fill"
        case "mystery": return "magnifyingglass"
        case "romance": return "heart.fill"
        case "fantasy": return "wand.and.stars"
        case "family": return "figure.2.and.child.holdinghands"
        default: return "tv.fill"
        }
    }
    
    private func genreColor(for genre: String) -> Color {
        switch genre.lowercased() {
        case "drama": return .purple
        case "comedy": return .yellow
        case "action", "adventure": return .orange
        case "sci-fi", "science fiction": return .cyan
        case "horror", "thriller": return .red
        case "documentary": return .gray
        case "animation", "anime": return .pink
        case "crime": return .indigo
        case "mystery": return .teal
        case "romance": return .pink
        case "fantasy": return .purple
        default: return OpenFlixColors.accent
        }
    }
}

// MARK: - TV Theater Mode Hero

struct TVTheaterModeHero: View {
    let shows: [MediaItem]
    var onPlay: (MediaItem) -> Void
    var onMoreInfo: (MediaItem) -> Void
    
    @State private var currentIndex = 0
    @State private var isAutoPlaying = true
    @FocusState private var focusedButton: HeroButton?
    
    enum HeroButton: Hashable {
        case play, info, indicator(Int)
    }
    
    private let heroHeight: CGFloat = 720
    private let autoAdvanceInterval: TimeInterval = 8.0
    
    private var currentShow: MediaItem? {
        guard currentIndex < shows.count else { return nil }
        return shows[currentIndex]
    }
    
    var body: some View {
        ZStack {
            // Background with parallax
            TabView(selection: $currentIndex) {
                ForEach(Array(shows.enumerated()), id: \.element.id) { index, show in
                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY
                        
                        AuthenticatedImage(path: show.art ?? show.thumb, systemPlaceholder: "tv")
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: heroHeight + max(0, minY))
                            .offset(y: -minY * 0.3)
                            .clipped()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: heroHeight)
            
            // Cinematic vignette
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.4)],
                        center: .center,
                        startRadius: 400,
                        endRadius: 1000
                    )
                )
            
            // Left gradient for text
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0.95), .black.opacity(0.7), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 800)
                
                Spacer()
            }
            
            // Bottom gradient
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
            }
            
            // Content overlay
            if let show = currentShow {
                heroContent(for: show)
            }
        }
        .frame(height: heroHeight)
        .onAppear {
            startAutoAdvance()
        }
        .onChange(of: focusedButton) { _, newValue in
            isAutoPlaying = newValue == nil
        }
    }
    
    @ViewBuilder
    private func heroContent(for show: MediaItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                
                // TV SERIES badge
                HStack(spacing: 10) {
                    Image(systemName: "tv.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("TV SERIES")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(3)
                }
                .foregroundColor(OpenFlixColors.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(OpenFlixColors.accent.opacity(0.5), lineWidth: 1)
                        )
                )
                
                Spacer().frame(height: 20)
                
                // Title with glow
                Text(show.title)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
                    .shadow(color: OpenFlixColors.accent.opacity(0.3), radius: 20)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer().frame(height: 16)
                
                // Metadata row
                HStack(spacing: 16) {
                    // Year
                    if let year = show.year {
                        Text(String(year))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Seasons
                    if let seasons = show.childCount, seasons > 0 {
                        MetadataPill(
                            icon: "tv.inset.filled",
                            text: "\(seasons) Season\(seasons > 1 ? "s" : "")"
                        )
                    }
                    
                    // Rating
                    if let rating = show.contentRating {
                        MetadataPill(icon: nil, text: rating)
                    }
                    
                    // Score
                    if let score = show.audienceRating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", score))
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    }
                }
                
                Spacer().frame(height: 20)
                
                // Summary
                if let summary = show.summary {
                    Text(summary)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(3)
                        .lineSpacing(4)
                        .frame(maxWidth: 600, alignment: .leading)
                }
                
                Spacer().frame(height: 32)
                
                // Action buttons
                HStack(spacing: 20) {
                    // Watch Now button
                    Button(action: { onPlay(show) }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Watch Now")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(
                            Capsule()
                                .fill(.white)
                                .shadow(color: .white.opacity(0.3), radius: 10)
                        )
                    }
                    .buttonStyle(.card)
                    .focused($focusedButton, equals: .play)
                    .scaleEffect(focusedButton == .play ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedButton)
                    
                    // More Info button
                    Button(action: { onMoreInfo(show) }) {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 18))
                            Text("Episodes")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(focusedButton == .info ? 0.8 : 0.3), lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(.card)
                    .focused($focusedButton, equals: .info)
                    .scaleEffect(focusedButton == .info ? 1.06 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedButton)
                }
                
                // Page indicators
                if shows.count > 1 {
                    Spacer().frame(height: 28)
                    HStack(spacing: 12) {
                        ForEach(0..<min(shows.count, 10), id: \.self) { index in
                            Button(action: { currentIndex = index }) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(index == currentIndex ? OpenFlixColors.accent : .white.opacity(0.4))
                                    .frame(width: index == currentIndex ? 32 : 12, height: 6)
                            }
                            .buttonStyle(.plain)
                            .focused($focusedButton, equals: .indicator(index))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                        }
                    }
                }
                
                Spacer().frame(height: 60)
            }
            .padding(.leading, 80)
            .frame(maxWidth: 750, alignment: .leading)
            
            Spacer()
        }
    }
    
    private func startAutoAdvance() {
        Timer.scheduledTimer(withTimeInterval: autoAdvanceInterval, repeats: true) { _ in
            if isAutoPlaying && shows.count > 1 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentIndex = (currentIndex + 1) % shows.count
                }
            }
        }
    }
}

// MARK: - Metadata Pill

struct MetadataPill: View {
    let icon: String?
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
            }
            Text(text)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - TV Genre Filter Bar

struct TVGenreFilterBar: View {
    let genres: [String]
    @Binding var selectedGenre: String?
    var onBrowseAll: () -> Void
    
    @FocusState private var focusedGenre: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Browse All button
                Button(action: onBrowseAll) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("Browse All")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(OpenFlixColors.accent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(OpenFlixColors.accent.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(OpenFlixColors.accent.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.card)
                .focused($focusedGenre, equals: "browse")
                .scaleEffect(focusedGenre == "browse" ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedGenre)
                
                Divider()
                    .frame(height: 30)
                    .background(.white.opacity(0.2))
                
                // Genre pills
                ForEach(genres.prefix(12), id: \.self) { genre in
                    GenrePillButton(
                        genre: genre,
                        isSelected: selectedGenre == genre,
                        isFocused: focusedGenre == genre
                    ) {
                        selectedGenre = selectedGenre == genre ? nil : genre
                    }
                    .focused($focusedGenre, equals: genre)
                }
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 8)
        }
    }
}

struct GenrePillButton: View {
    let genre: String
    let isSelected: Bool
    let isFocused: Bool
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(genre)
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : .white.opacity(0.9))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? OpenFlixColors.accent : .white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(isFocused ? .white : .clear, lineWidth: 2)
                        )
                )
        }
        .buttonStyle(.card)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

// MARK: - Modern TV Row

struct ModernTVRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let items: [MediaItem]
    let style: TVRowStyle
    var onItemSelected: (MediaItem) -> Void
    
    enum TVRowStyle {
        case poster
        case continueWatching
        case episode
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section header
            HStack(spacing: 12) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(.horizontal, 80)
            
            // Content row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(items.prefix(15)) { item in
                        switch style {
                        case .poster:
                            ModernTVPosterCard(item: item) {
                                onItemSelected(item)
                            }
                        case .continueWatching:
                            ModernTVContinueCard(item: item) {
                                onItemSelected(item)
                            }
                        case .episode:
                            ModernTVEpisodeCard(item: item) {
                                onItemSelected(item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Modern TV Poster Card

struct ModernTVPosterCard: View {
    let item: MediaItem
    var onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isHovered = false
    
    private let cardWidth: CGFloat = 200
    private let cardHeight: CGFloat = 300
    
    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottom) {
                // Poster image
                AuthenticatedImage(path: item.thumb, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                
                // Bottom info overlay
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        if let seasons = item.childCount {
                            Text("\(seasons) Season\(seasons > 1 ? "s" : "")")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .opacity(isFocused ? 1 : 0.8)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? OpenFlixColors.accent : .clear,
                        lineWidth: 4
                    )
            )
            .shadow(
                color: isFocused ? OpenFlixColors.accent.opacity(0.5) : .clear,
                radius: 20
            )
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Modern TV Continue Card

struct ModernTVContinueCard: View {
    let item: MediaItem
    var onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    
    private let cardWidth: CGFloat = 400
    private let cardHeight: CGFloat = 240
    
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                // Background image
                AuthenticatedImage(path: item.thumb ?? item.grandparentThumb, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                
                // Glass overlay
                VStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Show title
                        Text(item.grandparentTitle ?? item.parentTitle ?? "")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                        
                        // Episode title
                        Text(item.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        // Episode info
                        HStack(spacing: 8) {
                            if let season = item.parentIndex, let episode = item.index {
                                Text("S\(season) E\(episode)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(OpenFlixColors.accent)
                            }
                            
                            if let duration = item.duration, let offset = item.viewOffset {
                                let remaining = duration - offset
                                Text("•")
                                    .foregroundColor(.white.opacity(0.5))
                                Text("\(Int(remaining / 60000))min left")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.white.opacity(0.3))
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(OpenFlixColors.accent)
                                    .frame(width: geo.size.width * item.progressPercent)
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                }
                
                // Play icon
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(isFocused ? 1.0 : 0.8))
                    .shadow(color: .black.opacity(0.5), radius: 10)
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 4)
            )
            .shadow(color: isFocused ? OpenFlixColors.accent.opacity(0.4) : .clear, radius: 16)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Modern TV Episode Card

struct ModernTVEpisodeCard: View {
    let item: MediaItem
    var onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    
    private let cardWidth: CGFloat = 350
    private let cardHeight: CGFloat = 200
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 0) {
                // Thumbnail
                AuthenticatedImage(path: item.thumb, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: cardHeight)
                    .clipped()
                
                // Info panel
                VStack(alignment: .leading, spacing: 8) {
                    // Show name
                    Text(item.grandparentTitle ?? "")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                    
                    // Episode title
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Season/Episode badge
                    if let season = item.parentIndex, let episode = item.index {
                        HStack(spacing: 4) {
                            Text("S\(season)")
                                .foregroundColor(OpenFlixColors.accent)
                            Text("E\(episode)")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                    }
                    
                    // Duration
                    if let duration = item.duration {
                        Text(String.formatDuration(milliseconds: duration))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 3)
            )
            .shadow(color: isFocused ? OpenFlixColors.accent.opacity(0.3) : .clear, radius: 12)
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Modern TV Loading View

struct ModernTVLoadingView: View {
    @State private var rotation = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(OpenFlixColors.accent.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(OpenFlixColors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                }
                
                Text("Loading TV Shows...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - TV Shows Grid Browse View Modern

struct TVShowsGridBrowseViewModern: View {
    @ObservedObject var viewModel: TVShowsViewModel
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.fixed(200), spacing: 28),
        GridItem(.fixed(200), spacing: 28),
        GridItem(.fixed(200), spacing: 28),
        GridItem(.fixed(200), spacing: 28),
        GridItem(.fixed(200), spacing: 28),
        GridItem(.fixed(200), spacing: 28),
        GridItem(.fixed(200), spacing: 28)
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 32) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(OpenFlixColors.accent)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("All TV Shows")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Text("\(viewModel.allShows.count) shows")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 80)
                .padding(.top, 40)
                
                // Grid
                LazyVGrid(columns: columns, spacing: 40) {
                    ForEach(viewModel.allShows) { item in
                        ModernTVPosterCard(item: item) {
                            selectedItem = item
                            showDetail = true
                        }
                    }
                }
                .padding(.horizontal, 80)
                
                Spacer().frame(height: 80)
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showDetail) {
            if let item = selectedItem {
                MediaDetailView(mediaId: item.id)
            }
        }
    }
}

// MARK: - ViewModel Extensions

extension TVShowsViewModel {
    var hasFeaturedCarousel: Bool {
        !featuredShows.isEmpty
    }
    
    var hasContinueWatching: Bool {
        !continueWatching.isEmpty
    }
    
    var hasRecentlyAdded: Bool {
        !recentlyAdded.isEmpty
    }
    
    var hasUpNext: Bool {
        // Check if upNext exists and has items
        false // Placeholder - implement based on actual ViewModel
    }
    
    var upNext: [MediaItem] {
        [] // Placeholder
    }
}

#Preview {
    TVShowsHubViewModern()
}
