import SwiftUI

// MARK: - Modern Movies View
// Premium streaming service inspired movie hub with theater mode elements

struct MoviesViewModern: View {
    @StateObject private var viewModel = MoviesViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var showPlayer = false
    @State private var showGridBrowse = false
    @State private var selectedGenre: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && !viewModel.hasFeatured {
                    ModernMoviesLoadingView()
                } else if let error = viewModel.error {
                    ModernErrorView(message: error) {
                        Task { await viewModel.loadMoviesHub() }
                    }
                } else if !viewModel.hasFeatured && viewModel.allMovies.isEmpty {
                    ModernEmptyStateView(
                        icon: "film.stack",
                        title: "No Movies Yet",
                        message: "Your movie library is empty.\nAdd movies to start your collection."
                    )
                } else {
                    hubContentView
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showDetail) {
                if let item = selectedItem {
                    MovieDetailViewModern(item: item)
                }
            }
            .navigationDestination(isPresented: $showGridBrowse) {
                MoviesGridBrowseView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadMoviesHub()
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
                // Hero Carousel with Theater Mode
                if viewModel.hasFeaturedCarousel {
                    TheaterModeHero(
                        movies: viewModel.featuredMovies,
                        trailers: viewModel.trailers,
                        onPlay: { movie in
                            selectedItem = movie
                            showPlayer = true
                        },
                        onMoreInfo: { movie in
                            selectedItem = movie
                            showDetail = true
                        }
                    )
                    .focusSection()
                }
                
                // Content sections
                VStack(alignment: .leading, spacing: 48) {
                    // Genre Filter Bar
                    GenreFilterBar(
                        genres: viewModel.availableGenres,
                        selectedGenre: $selectedGenre,
                        onBrowseAll: { showGridBrowse = true }
                    )
                    .focusSection()
                    
                    // Continue Watching
                    if viewModel.hasContinueWatching {
                        ModernMovieRow(
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
                    if !viewModel.recentlyAdded.isEmpty {
                        ModernMovieRow(
                            title: "Recently Added",
                            subtitle: "Fresh in your library",
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
                    
                    // Genres
                    ForEach(viewModel.genreCollections.prefix(5), id: \.genre) { collection in
                        if selectedGenre == nil || selectedGenre == collection.genre {
                            ModernMovieRow(
                                title: collection.genre,
                                subtitle: nil,
                                icon: genreIcon(for: collection.genre),
                                accentColor: genreColor(for: collection.genre),
                                items: collection.items,
                                style: .poster
                            ) { item in
                                selectedItem = item
                                showDetail = true
                            }
                            .focusSection()
                        }
                    }
                    
                    // Collections (if available)
                    if !viewModel.collections.isEmpty {
                        CollectionsRow(
                            collections: viewModel.collections,
                            onSelect: { collection in
                                // Navigate to collection
                            }
                        )
                        .focusSection()
                    }
                    
                    // Studios/Services
                    if !viewModel.studioCollections.isEmpty {
                        ForEach(viewModel.studioCollections.prefix(3), id: \.studio) { collection in
                            ModernMovieRow(
                                title: "From \(collection.studio)",
                                subtitle: nil,
                                icon: "building.2",
                                accentColor: studioColor(for: collection.studio),
                                items: collection.items,
                                style: .poster
                            ) { item in
                                selectedItem = item
                                showDetail = true
                            }
                            .focusSection()
                        }
                    }
                }
                .padding(.top, 40)
                
                Spacer().frame(height: 80)
            }
        }
        .background(
            TheaterModeBackground(item: viewModel.featuredItem)
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Helpers
    
    private func genreIcon(for genre: String) -> String {
        let lower = genre.lowercased()
        if lower.contains("action") { return "flame.fill" }
        if lower.contains("comedy") { return "face.smiling.fill" }
        if lower.contains("drama") { return "theatermasks.fill" }
        if lower.contains("horror") { return "moon.fill" }
        if lower.contains("sci") { return "sparkles.tv.fill" }
        if lower.contains("thriller") { return "bolt.fill" }
        if lower.contains("romance") { return "heart.fill" }
        if lower.contains("animation") { return "figure.play" }
        if lower.contains("documentary") { return "doc.text.fill" }
        if lower.contains("family") { return "figure.2.and.child.holdinghands" }
        return "film.fill"
    }
    
    private func genreColor(for genre: String) -> Color {
        let lower = genre.lowercased()
        if lower.contains("action") { return .red }
        if lower.contains("comedy") { return .yellow }
        if lower.contains("drama") { return .purple }
        if lower.contains("horror") { return .gray }
        if lower.contains("sci") { return .cyan }
        if lower.contains("thriller") { return .orange }
        if lower.contains("romance") { return .pink }
        if lower.contains("family") { return .green }
        return OpenFlixColors.accent
    }
    
    private func studioColor(for studio: String) -> Color {
        let lower = studio.lowercased()
        if lower.contains("disney") { return .blue }
        if lower.contains("warner") { return .purple }
        if lower.contains("universal") { return .red }
        if lower.contains("paramount") { return .blue }
        if lower.contains("sony") { return .cyan }
        if lower.contains("marvel") { return .red }
        if lower.contains("a24") { return .green }
        return OpenFlixColors.accent
    }
}

// MARK: - Theater Mode Hero

struct TheaterModeHero: View {
    let movies: [MediaItem]
    let trailers: [String: String]
    var onPlay: ((MediaItem) -> Void)?
    var onMoreInfo: ((MediaItem) -> Void)?
    
    @State private var currentIndex = 0
    @State private var isPlayingTrailer = false
    @State private var autoAdvanceTimer: Timer?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // Background with ambient blur
            if let movie = movies[safe: currentIndex] {
                AuthenticatedImage(
                    path: movie.art ?? movie.thumb,
                    systemPlaceholder: "film"
                )
                .aspectRatio(contentMode: .fill)
                .frame(height: 800)
                .blur(radius: 50)
                .opacity(0.4)
                .scaleEffect(1.2)
            }
            
            // Main hero content
            TabView(selection: $currentIndex) {
                ForEach(Array(movies.prefix(6).enumerated()), id: \.element.id) { index, movie in
                    TheaterModeHeroItem(
                        movie: movie,
                        hasTrailer: trailers[String(movie.id)] != nil,
                        isPlayingTrailer: $isPlayingTrailer,
                        onPlay: { onPlay?(movie) },
                        onMoreInfo: { onMoreInfo?(movie) },
                        onPlayTrailer: {
                            // Play trailer
                            isPlayingTrailer = true
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 800)
            
            // Page indicator
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    ForEach(0..<min(movies.count, 6), id: \.self) { index in
                        Capsule()
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: index == currentIndex ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentIndex)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 40)
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
        guard movies.count > 1, !isPlayingTrailer else { return }
        stopAutoAdvance()
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: 12.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentIndex = (currentIndex + 1) % min(movies.count, 6)
            }
        }
    }
    
    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }
}

// MARK: - Theater Mode Hero Item

struct TheaterModeHeroItem: View {
    let movie: MediaItem
    let hasTrailer: Bool
    @Binding var isPlayingTrailer: Bool
    var onPlay: () -> Void
    var onMoreInfo: () -> Void
    var onPlayTrailer: () -> Void
    
    @FocusState private var focusedButton: HeroButton?
    
    enum HeroButton: Hashable {
        case play, trailer, info, watchlist
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Movie art
                AuthenticatedImage(
                    path: movie.art ?? movie.thumb,
                    systemPlaceholder: "film"
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height + 100)
                .clipped()
                
                // Multi-layer gradient
                ZStack {
                    // Bottom gradient
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.6), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Left gradient for text
                    LinearGradient(
                        colors: [.black.opacity(0.8), .black.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    // Vignette
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.4)],
                        center: .center,
                        startRadius: geometry.size.width * 0.25,
                        endRadius: geometry.size.width * 0.75
                    )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    // Movie logo or title
                    Text(movie.title)
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 4)
                        .lineLimit(2)
                    
                    Spacer().frame(height: 16)
                    
                    // Tagline
                    if let tagline = movie.tagline {
                        Text(tagline)
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .italic()
                            .lineLimit(2)
                    }
                    
                    Spacer().frame(height: 24)
                    
                    // Metadata
                    HStack(spacing: 16) {
                        // Rating with star
                        if let rating = movie.audienceRating {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .fontWeight(.bold)
                            }
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        }
                        
                        // Year
                        if let year = movie.year {
                            Text(String(year))
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Content rating badge
                        if let contentRating = movie.contentRating {
                            Text(contentRating)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(4)
                        }
                        
                        // Duration
                        let duration = movie.durationFormatted
                        if !duration.isEmpty {
                            Text(duration)
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Genres
                        if !movie.genres.isEmpty {
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            Text(movie.genres.prefix(2).joined(separator: " · "))
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer().frame(height: 32)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        // Play button
                        Button(action: onPlay) {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 24))
                                Text(movie.isInProgress ? "Resume" : "Play")
                                    .font(.system(size: 22, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 44)
                            .padding(.vertical, 20)
                            .background(
                                Capsule()
                                    .fill(.white)
                                    .shadow(color: .white.opacity(focusedButton == .play ? 0.5 : 0), radius: 20)
                            )
                        }
                        .buttonStyle(.plain)
                        .focused($focusedButton, equals: .play)
                        .scaleEffect(focusedButton == .play ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedButton)
                        
                        // Trailer button (if available)
                        if hasTrailer {
                            Button(action: onPlayTrailer) {
                                HStack(spacing: 8) {
                                    Image(systemName: "film")
                                        .font(.system(size: 20))
                                    Text("Trailer")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 18)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Capsule()
                                                .stroke(.white.opacity(focusedButton == .trailer ? 1 : 0.3), lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .focused($focusedButton, equals: .trailer)
                            .scaleEffect(focusedButton == .trailer ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedButton)
                        }
                        
                        // Watchlist button
                        Button(action: {}) {
                            Image(systemName: "plus")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
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
                        
                        // More Info button
                        Button(action: onMoreInfo) {
                            Image(systemName: "info")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
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
                    
                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, 80)
            }
        }
    }
}

// MARK: - Genre Filter Bar

struct GenreFilterBar: View {
    let genres: [String]
    @Binding var selectedGenre: String?
    var onBrowseAll: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Browse All
                GenreChip(
                    label: "Browse All",
                    icon: "square.grid.2x2",
                    isSelected: false,
                    accentColor: OpenFlixColors.accent
                ) {
                    onBrowseAll()
                }
                
                // All Genres
                GenreChip(
                    label: "All Genres",
                    icon: nil,
                    isSelected: selectedGenre == nil,
                    accentColor: OpenFlixColors.accent
                ) {
                    selectedGenre = nil
                }
                
                ForEach(genres.prefix(10), id: \.self) { genre in
                    GenreChip(
                        label: genre,
                        icon: nil,
                        isSelected: selectedGenre == genre,
                        accentColor: OpenFlixColors.accent
                    ) {
                        selectedGenre = selectedGenre == genre ? nil : genre
                    }
                }
            }
            .padding(.horizontal, 48)
        }
    }
}

struct GenreChip: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let accentColor: Color
    var action: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor : (isFocused ? accentColor.opacity(0.3) : Color.white.opacity(0.1)))
            )
            .overlay(
                Capsule()
                    .stroke(isFocused && !isSelected ? accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isFocused)
    }
}

// MARK: - Modern Movie Row

struct ModernMovieRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let accentColor: Color
    let items: [MediaItem]
    let style: MovieCardStyle
    let onSelect: (MediaItem) -> Void
    
    enum MovieCardStyle {
        case poster
        case wide
        case continueWatching
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
            }
            .padding(.horizontal, 48)
            
            // Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(items) { item in
                        switch style {
                        case .poster:
                            ModernMoviePosterCard(item: item, onSelect: { onSelect(item) })
                        case .wide:
                            ModernMovieWideCard(item: item, onSelect: { onSelect(item) })
                        case .continueWatching:
                            ModernMovieContinueCard(item: item, onSelect: { onSelect(item) })
                        }
                    }
                }
                .padding(.horizontal, 48)
            }
        }
    }
}

// MARK: - Modern Movie Poster Card

struct ModernMoviePosterCard: View {
    let item: MediaItem
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .bottomLeading) {
                    // Poster
                    AuthenticatedImage(
                        path: item.thumb,
                        systemPlaceholder: "film"
                    )
                    .aspectRatio(2/3, contentMode: .fill)
                    .frame(width: 200, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Hover info
                    if isFocused {
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let rating = item.audienceRating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 12))
                                    Text(String(format: "%.1f", rating))
                                        .fontWeight(.bold)
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            }
                            
                            if let year = item.year {
                                Text(String(year))
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(12)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 4)
                )
                .shadow(
                    color: isFocused ? OpenFlixColors.accent.opacity(0.4) : .black.opacity(0.3),
                    radius: isFocused ? 24 : 8,
                    y: isFocused ? 12 : 4
                )
                
                // Title
                Text(item.title)
                    .font(.system(size: 16, weight: isFocused ? .semibold : .regular))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(width: 200, alignment: .leading)
            }
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

// MARK: - Modern Movie Wide Card

struct ModernMovieWideCard: View {
    let item: MediaItem
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottomLeading) {
                AuthenticatedImage(
                    path: item.art ?? item.thumb,
                    systemPlaceholder: "film"
                )
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: 440, height: 248)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Gradient
                LinearGradient(
                    colors: [.clear, .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        if let rating = item.audienceRating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if let year = item.year {
                            Text(String(year))
                        }
                        
                        if let contentRating = item.contentRating {
                            Text(contentRating)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(20)
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

// MARK: - Modern Movie Continue Card

struct ModernMovieContinueCard: View {
    let item: MediaItem
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    // Thumbnail
                    AuthenticatedImage(
                        path: item.art ?? item.thumb,
                        systemPlaceholder: "film"
                    )
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 360, height: 202)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Overlay
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.3))
                    
                    // Play icon on focus
                    if isFocused {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Progress
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
                .frame(width: 360, alignment: .leading)
            }
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

// MARK: - Collections Row

struct CollectionsRow: View {
    let collections: [MovieCollection]
    let onSelect: (MovieCollection) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.purple)
                
                Text("Collections")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 48)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(collections) { collection in
                        CollectionCard(collection: collection) {
                            onSelect(collection)
                        }
                    }
                }
                .padding(.horizontal, 48)
            }
        }
    }
}

struct CollectionCard: View {
    let collection: MovieCollection
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottomLeading) {
                // Stack of posters
                ZStack {
                    ForEach(Array(collection.items.prefix(3).enumerated().reversed()), id: \.offset) { index, item in
                        AuthenticatedImage(
                            path: item.thumb,
                            systemPlaceholder: "film"
                        )
                        .aspectRatio(2/3, contentMode: .fill)
                        .frame(width: 140, height: 210)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .offset(x: CGFloat(index) * 20, y: CGFloat(index) * -10)
                        .shadow(radius: 8)
                    }
                }
                .frame(width: 180, height: 220)
                
                // Collection name
                VStack(alignment: .leading) {
                    Text(collection.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(collection.items.count) movies")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(12)
                .frame(width: 180, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 3)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

// MARK: - Theater Mode Background

struct TheaterModeBackground: View {
    let item: MediaItem?
    
    var body: some View {
        ZStack {
            Color.black
            
            if let item = item {
                AuthenticatedImage(
                    path: item.art ?? item.thumb,
                    systemPlaceholder: "rectangle"
                )
                .aspectRatio(contentMode: .fill)
                .blur(radius: 80)
                .opacity(0.25)
                .scaleEffect(1.3)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Modern Movies Loading View

struct ModernMoviesLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "film.stack")
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
            
            Text("Loading movies...")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Modern Empty State

struct ModernEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [OpenFlixColors.accent.opacity(0.7), OpenFlixColors.accent.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Movie Detail View Modern Placeholder

struct MovieDetailViewModern: View {
    let item: MediaItem
    
    var body: some View {
        MediaDetailView(mediaId: item.id)
    }
}

// MARK: - Placeholder Types

struct MovieCollection: Identifiable {
    let id: String
    let name: String
    let items: [MediaItem]
}

// MARK: - Safe Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    MoviesViewModern()
}
