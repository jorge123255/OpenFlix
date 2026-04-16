import SwiftUI

// MARK: - Xfinity Stream Style Home View

struct XfinityHomeView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @StateObject private var liveTVViewModel = LiveTVViewModel()
    @StateObject private var dvrViewModel = DVRViewModel()
    @State private var selectedItem: MediaItem?
    @State private var selectedChannel: Channel?
    @State private var showMediaDetail = false
    @State private var showPlayer = false
    @State private var selectedRecordingId: Int?
    @State private var showRecordingPlayer = false
    @State private var resolvedRecordingURL: URL?
    @State private var showChannelPlayer = false
    @State private var selectedSeriesTitle: String?
    @State private var showSeriesEpisodes = false
    @State private var liveFilterCategory: String?
    #if os(tvOS)
    @FocusState private var focusedHomeTarget: TVHomeFocusTarget?
    @State private var tvHeroIndex = 0
    @State private var heroTimer: Timer?
    #endif
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.recentlyAdded.isEmpty {
                #if os(tvOS)
                tvLoadingView
                #else
                LoadingView(message: "Loading...")
                #endif
            } else if let error = viewModel.error, viewModel.recentlyAdded.isEmpty, viewModel.hubs.isEmpty, viewModel.onDeck.isEmpty {
                #if os(tvOS)
                tvErrorView(message: error)
                #else
                ErrorView(message: error)
                #endif
            } else {
                #if os(tvOS)
                tvContentView
                #else
                contentView
                #endif
            }
        }
        .background(XfinityColors.background.ignoresSafeArea())
        #if os(tvOS)
        .onAppear {
            requestHomeFocus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tvHomeRequestFocus)) { _ in
            requestHomeFocus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tvContentRequestFocus)) { _ in
            requestHomeFocus()
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            if !isLoading {
                requestHomeFocus()
            }
        }
        #endif
        .task {
            async let homeContent: Void = viewModel.loadHomeContent()
            async let liveChannels: Void = liveTVViewModel.loadChannels()
            async let dvrLoad: Void = dvrViewModel.loadRecordings()
            _ = await (homeContent, liveChannels, dvrLoad)
            await dvrViewModel.loadDownloadJobs()
            await liveTVViewModel.refreshNowPlaying()
        }
        .refreshable {
            async let homeContent: Void = viewModel.loadHomeContent()
            async let liveChannels: Void = liveTVViewModel.loadChannels()
            async let dvrLoad: Void = dvrViewModel.loadRecordings()
            _ = await (homeContent, liveChannels, dvrLoad)
            await dvrViewModel.loadDownloadJobs()
            await liveTVViewModel.refreshNowPlaying()
        }
        .navigationDestination(isPresented: $showMediaDetail) {
            if let item = selectedItem {
                MediaDetailView(mediaId: item.id)
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let item = selectedItem {
                #if os(tvOS)
                VideoPlayerView(mediaItem: item, startPosition: item.viewOffset)
                    .id(item.id)  // stable identity prevents SwiftUI recreating VLC
                #else
                VideoPlayerView(mediaItem: item, startPosition: item.viewOffset)
                #endif
            }
        }
        .fullScreenCover(isPresented: $showRecordingPlayer) {
            if let recordingId = selectedRecordingId,
               let recording = dvrViewModel.recordings.first(where: { $0.id == recordingId }) {
                #if os(tvOS)
                VideoPlayerView(
                    mediaItem: nil,
                    recordingURL: resolvedRecordingURL,
                    startPosition: recording.viewOffset,
                    commercials: recording.commercials,
                    recordingDurationMs: recording.duration,
                    recording: recording
                )
                .id(recording.id)  // stable identity prevents SwiftUI recreating VLC
                #else
                DVRPlayerView(recording: recording)
                #endif
            }
        }
        .fullScreenCover(isPresented: $showChannelPlayer) {
            if let channel = selectedChannel {
                #if os(tvOS)
                TVLiveChannelPlayerView(
                    initialChannel: channel,
                    initialStreamURL: channel.preferredPlaybackURL,
                    viewModel: liveTVViewModel
                )
                .id(channel.id)  // stable identity prevents SwiftUI recreating VLC on re-render
                .environmentObject(dvrViewModel)
                #else
                if let streamURL = channel.preferredPlaybackURL {
                    FullScreenPlayerView(
                        channel: channel,
                        program: channel.nowPlaying,
                        streamURL: streamURL,
                        onMinimize: { showChannelPlayer = false },
                        onClose: { showChannelPlayer = false }
                    )
                }
                #endif
            }
        }
        .fullScreenCover(isPresented: $showSeriesEpisodes) {
            if let seriesTitle = selectedSeriesTitle,
               let series = dvrViewModel.recordingsBySeries.first(where: { $0.title == seriesTitle }) {
                TVSeriesEpisodesView(
                    title: series.title,
                    recordings: series.recordings,
                    onPlayRecording: { recording in
                        selectedRecordingId = recording.id
                        showSeriesEpisodes = false
                        resolveAndPlayRecording(recording)
                    },
                    onDismiss: { showSeriesEpisodes = false }
                )
            }
        }
        .onChange(of: liveTVViewModel.liveRefreshTick) { _, _ in
            Task {
                await liveTVViewModel.refreshNowPlaying()
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

    #if os(tvOS)
    private var tvContentView: some View {
        ZStack {
            // Ambient backdrop: the focused hero item's artwork blurred and
            // tinted, behind everything. Updates as the hero auto-rotates.
            tvAmbientBackdrop
                .ignoresSafeArea()
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.8), value: tvHeroIndex)

            ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                tvCompactHeroSection
                tvHeroPageIndicator
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                if allTVRailsEmpty {
                    VStack(spacing: 18) {
                        Image(systemName: "tray")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.white.opacity(0.38))
                        Text("Nothing to show yet")
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Your server returned no content. Pull down to refresh or check your server.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.46))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 520)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 80)
                }

                VStack(alignment: .leading, spacing: 36) {
                    // 1. Continue Watching
                    if !tvContinueWatchingItems.isEmpty {
                        tvHomeRow(title: "Continue Watching", showViewAll: false) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(tvContinueWatchingItems) { item in
                                        TVCompactWideCard(item: item) {
                                            selectedItem = item
                                            showPlayer = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }

                    // 2. On Now (Live TV)
                    if !tvLiveNowChannels.isEmpty {
                        tvHomeRow(
                            title: liveFilterCategory == nil ? "On Now" : "On Now — \(liveFilterCategory!)",
                            showViewAll: true, onViewAll: {
                            SidecarMenuState.shared.selectedTab = OpenFlixTVTabView.Tab.liveTV
                        }) {
                            VStack(alignment: .leading, spacing: 10) {
                                // Category filter chips
                                tvLiveFilterChips

                                if tvFilteredLiveChannels.isEmpty && liveFilterCategory != nil {
                                    Text("No channels matching \(liveFilterCategory!)")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.4))
                                        .padding(.horizontal, 28)
                                        .padding(.vertical, 12)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 18) {
                                            ForEach(tvFilteredLiveChannels) { channel in
                                                TVLiveNowCard(channel: channel) {
                                                    selectedChannel = channel
                                                    showChannelPlayer = true
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 28)
                                        .padding(.vertical, 8)
                                        .focusSection()
                                    }
                                }
                            }
                        }
                    }

                    // 3. Recently Recorded (DVR) — grouped by series
                    if !tvRecentlyRecorded.isEmpty {
                        tvHomeRow(title: "Recently Recorded", showViewAll: false) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(tvRecentlyRecorded, id: \.title) { series in
                                        TVSeriesRecordedCard(
                                            title: series.title,
                                            recordings: series.recordings
                                        ) {
                                            selectedSeriesTitle = series.title
                                            showSeriesEpisodes = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }

                    // 4. Recently Added
                    if !tvRecentlyAddedItems.isEmpty {
                        tvHomeRow(title: "Recently Added") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 18) {
                                    ForEach(tvRecentlyAddedItems) { item in
                                        TVCompactPosterCard(item: item) {
                                            selectedItem = item
                                            showMediaDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }

                    // Tonight
                    if !viewModel.onLaterTonight.isEmpty {
                        tvHomeRow(title: "Tonight", showViewAll: false) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.onLaterTonight.prefix(15)) { entry in
                                        TVOnLaterProgramCard(entry: entry) {
                                            tuneToOnLaterChannel(entry)
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }

                    // Live Sports
                    if !viewModel.onLaterSports.isEmpty {
                        tvHomeRow(title: "Live Sports", showViewAll: false) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.onLaterSports.prefix(15)) { entry in
                                        TVOnLaterProgramCard(entry: entry) {
                                            tuneToOnLaterChannel(entry)
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }

                    // News
                    if !viewModel.onLaterNews.isEmpty {
                        tvHomeRow(title: "News", showViewAll: false) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.onLaterNews.prefix(15)) { entry in
                                        TVOnLaterProgramCard(entry: entry) {
                                            tuneToOnLaterChannel(entry)
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }

                    // Kids
                    if !viewModel.onLaterKids.isEmpty {
                        tvHomeRow(title: "Kids", showViewAll: false) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.onLaterKids.prefix(15)) { entry in
                                        TVOnLaterProgramCard(entry: entry) {
                                            tuneToOnLaterChannel(entry)
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }

                    // 5. Top Picks
                    if !tvTopPicksItems.isEmpty {
                        tvHomeRow(title: "Top Picks") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(tvTopPicksItems.enumerated()), id: \.element.id) { idx, item in
                                        TVCompactRankedCard(item: item, rank: idx + 1) {
                                            selectedItem = item
                                            showMediaDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }

                    // 6. Recommended
                    if !tvRecommendedItems.isEmpty {
                        tvHomeRow(title: "Recommended For You") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 18) {
                                    ForEach(tvRecommendedItems) { item in
                                        TVCompactPosterCard(item: item) {
                                            selectedItem = item
                                            showMediaDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }

                    // 7. Movies
                    if !tvMovieItems.isEmpty {
                        tvHomeRow(title: "Movies") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 18) {
                                    ForEach(tvMovieItems) { item in
                                        TVCompactPosterCard(item: item) {
                                            selectedItem = item
                                            showMediaDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }

                    // 8. TV Shows
                    if !tvShowItems.isEmpty {
                        tvHomeRow(title: "TV Shows") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 18) {
                                    ForEach(tvShowItems) { item in
                                        TVCompactPosterCard(item: item) {
                                            selectedItem = item
                                            showMediaDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }

                    // 9. Hubs
                    ForEach(tvCuratedHubs.prefix(4)) { hub in
                        tvHomeRow(title: hub.title) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 18) {
                                    ForEach(hub.items) { item in
                                        TVCompactPosterCard(item: item) {
                                            selectedItem = item
                                            showMediaDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .focusSection()
                            }
                        }
                    }
                }
                .padding(.top, 28)
            }
            .padding(.top, 18)
            .padding(.bottom, 80)
        }
        }
    }

    // MARK: - Hero Polish

    private var tvHeroPageIndicator: some View {
        let count = tvHeroItems.count
        return HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { idx in
                Capsule()
                    .fill(idx == tvHeroIndex ? Color.white : Color.white.opacity(0.32))
                    .frame(width: idx == tvHeroIndex ? 24 : 8, height: 5)
                    .animation(.easeInOut(duration: 0.25), value: tvHeroIndex)
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(count > 1 ? 1 : 0)
    }

    private var tvAmbientBackdrop: some View {
        let items = tvHeroItems
        let safeIndex = min(tvHeroIndex, max(items.count - 1, 0))
        let item = items.isEmpty ? nil : items[safeIndex]
        return ZStack {
            XfinityColors.background
            if let item {
                AuthenticatedImage(
                    paths: heroArtworkCandidates(for: item),
                    systemPlaceholder: "sparkles.tv"
                )
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: 60)
                .opacity(0.42)
                .id(item.id) // force the AuthenticatedImage to reload when hero changes
            }
            // Heavy bottom-to-top scrim so backdrop never overpowers content.
            LinearGradient(
                colors: [
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipped()
    }

    private var tvCompactHeroSection: some View {
        let items = tvHeroItems
        let safeIndex = min(tvHeroIndex, max(items.count - 1, 0))
        let heroItem = items.isEmpty ? nil : items[safeIndex]

        return VStack(spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                // Background: swipeable artwork pages
                TabView(selection: $tvHeroIndex) {
                    ForEach(0..<items.count, id: \.self) { index in
                        AuthenticatedImage(
                            paths: heroArtworkCandidates(for: items[index]),
                            systemPlaceholder: "sparkles.tv"
                        )
                        .aspectRatio(16 / 9, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 420)
                        .overlay(Color.black.opacity(0.35))
                        .clipped()
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 420)

                // Content overlay
                HStack(alignment: .bottom, spacing: 0) {
                    // Poster
                    AuthenticatedImage(
                        paths: [heroItem?.thumb, heroItem?.art, heroItem?.banner],
                        systemPlaceholder: heroItem?.type == .show ? "tv" : "film"
                    )
                    .aspectRatio(2/3, contentMode: .fill)
                    .frame(width: 220, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
                    .padding(.leading, 40)
                    .padding(.bottom, 30)

                    // Title + metadata + buttons
                    VStack(alignment: .leading, spacing: 10) {
                        Text(heroItem?.type.displayName.uppercased() ?? "FEATURED")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color(red: 97/255, green: 56/255, blue: 245/255), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                        Text(heroItem?.title ?? "OpenFlix")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .shadow(radius: 4)

                        HStack(spacing: 12) {
                            if let year = heroItem?.year {
                                Text(String(year))
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            if let rating = heroItem?.contentRating {
                                Text(rating)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.18), in: Capsule())
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            if let duration = heroItem?.durationFormatted {
                                Text(duration)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }

                        if let summary = heroItem?.summary, !summary.isEmpty {
                            Text(summary)
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(2)
                                .frame(maxWidth: 500, alignment: .leading)
                        }

                        // Action buttons
                        HStack(spacing: 14) {
                            Button {
                                if let heroItem {
                                    selectedItem = heroItem
                                    showPlayer = true
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                    Text("Play")
                                }
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 10)
                                .background(Color(red: 97/255, green: 56/255, blue: 245/255), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Button {
                                if let heroItem {
                                    selectedItem = heroItem
                                    showMediaDetail = true
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                    Text("More Info")
                                }
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.leading, 28)

                    Spacer()
                }

                // Recording indicator
                if let recording = dvrViewModel.currentlyRecording.first {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .fill(Color.red.opacity(0.4))
                                    .scaleEffect(1.6)
                            )
                        Text("REC: \(recording.title)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: 420, alignment: .topTrailing)
                    .padding(20)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(focusedHomeTarget == .heroCard ? Color.white.opacity(0.72) : Color.white.opacity(0.06), lineWidth: focusedHomeTarget == .heroCard ? 3 : 1)
            )
            .focused($focusedHomeTarget, equals: .heroCard)
            .defaultFocus($focusedHomeTarget, .heroCard)
            .padding(.horizontal, 28)

            // Page indicators
            if items.count > 1 {
                HStack(spacing: 10) {
                    ForEach(0..<min(items.count, 5), id: \.self) { index in
                        Capsule()
                            .fill(index == safeIndex
                                  ? Color(red: 97/255, green: 56/255, blue: 245/255)
                                  : Color.white.opacity(0.28))
                            .frame(width: index == safeIndex ? 28 : 10, height: 6)
                            .animation(.easeInOut(duration: 0.25), value: safeIndex)
                    }
                }
            }
        }
        .onAppear { startHeroTimer() }
        .onDisappear { stopHeroTimer() }
    }

    private func startHeroTimer() {
        stopHeroTimer()
        heroTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
            Task { @MainActor in
                let count = tvHeroItems.count
                guard count > 1 else { return }
                withAnimation(.easeInOut(duration: 0.6)) {
                    tvHeroIndex = (tvHeroIndex + 1) % count
                }
            }
        }
    }

    private func stopHeroTimer() {
        heroTimer?.invalidate()
        heroTimer = nil
    }

    private var featuredHeroItem: MediaItem? {
        curatedDiscoveryItems(viewModel.featured, limit: 1).first
        ?? tvContinueWatchingItems.first
        ?? tvNewPopularItems.first
        ?? tvCuratedHubs.first?.items.first
    }

    private var tvHeroItems: [MediaItem] {
        let items = curatedDiscoveryItems(viewModel.featured + viewModel.recommended + viewModel.recentlyAdded, limit: 5)
        return items.isEmpty ? featuredHeroItem.map { [$0] } ?? [] : items
    }

    private var tvRecentlyAddedItems: [MediaItem] {
        curatedDiscoveryItems(viewModel.recentlyAdded, limit: 15)
    }

    private var tvTopPicksItems: [MediaItem] {
        curatedDiscoveryItems(viewModel.topTen, limit: 10)
    }

    private var tvRecentChannels: [Channel] {
        Array(liveTVViewModel.channels.prefix(8))
    }

    /// Channels sorted: prefer server /livetv/on-now list; fall back to local sort
    private var tvLiveNowChannels: [Channel] {
        // Prefer /livetv/on-now. If the server already put the currently-airing
        // program on channel.nowPlaying (ChannelDTO.toDomain() does), use the
        // channel as-is; otherwise fall back to the local-filter synthesis.
        let serverList = viewModel.liveNow.map { $0.channel }
        if !serverList.isEmpty {
            return Array(serverList.prefix(12))
        }
        let sorted = liveTVViewModel.channels.sorted { a, b in
            if a.isFavorite != b.isFavorite { return a.isFavorite }
            let aHas = a.nowPlaying != nil
            let bHas = b.nowPlaying != nil
            if aHas != bHas { return aHas }
            return (a.number ?? Int.max) < (b.number ?? Int.max)
        }
        return Array(sorted.prefix(20))
    }

    /// Channels filtered by the selected category chip
    /// When a filter is active, searches ALL channels (not just the capped 20)
    private var tvFilteredLiveChannels: [Channel] {
        guard let filter = liveFilterCategory else { return tvLiveNowChannels }
        // Search the full channel list when filtering by category
        let pool = liveTVViewModel.channels.sorted { a, b in
            (a.number ?? Int.max) < (b.number ?? Int.max)
        }
        let filtered = pool.filter { channel in
            let chName = channel.name.lowercased()
            if let program = channel.nowPlaying {
                let title = program.title.lowercased()
                let cat = program.category?.lowercased() ?? ""
                switch filter {
                case "Sports":
                    return program.isSports
                        || cat.contains("sport")
                        || title.contains("football") || title.contains("basketball")
                        || title.contains("baseball") || title.contains("hockey")
                        || title.contains("soccer") || title.contains("tennis")
                        || title.contains("golf") || title.contains("nfl") || title.contains("nba")
                        || title.contains("mlb") || title.contains("nhl") || title.contains("mls")
                        || chName.contains("espn") || chName.contains("sport")
                        || chName.contains("nfl") || chName.contains("nba") || chName.contains("mlb")
                        || chName.contains("fs1") || chName.contains("nhl")
                case "News":
                    return program.isNews
                        || cat.contains("news")
                        || title.contains("news") || title.contains("tonight")
                        || title.contains("evening") || title.contains("report")
                        || title.contains("daily") || title.contains("update")
                        || chName.contains("news") || chName.contains("cnn")
                        || chName.contains("msnbc") || chName.contains("cnbc")
                        || chName.contains("bbc") || chName.contains("cheddar")
                case "Movies":
                    return program.isMovie
                        || cat.contains("movie") || cat.contains("film")
                        || title.contains("movie") || title.contains("film")
                        || chName.contains("movie") || chName.contains("cinema")
                        || chName.contains("hbo") || chName.contains("showtime")
                        || chName.contains("starz") || chName.contains("cinemax")
                case "Entertainment":
                    return cat.contains("entertain") || cat.contains("comedy") || cat.contains("series")
                        || title.contains("show") || title.contains("comedy")
                        || title.contains("episode") || title.contains("season")
                        || chName.contains("amc") || chName.contains("bravo")
                        || chName.contains("fx") || chName.contains("tbs")
                        || chName.contains("tnt") || chName.contains("usa")
                        || chName.contains("comedy") || chName.contains("e!")
                case "Kids":
                    return program.isKids
                        || cat.contains("kid") || cat.contains("child") || cat.contains("cartoon")
                        || title.contains("cartoon") || title.contains("kids") || title.contains("disney")
                        || title.contains("nick") || title.contains("pbs kids")
                        || chName.contains("disney") || chName.contains("nick")
                        || chName.contains("cartoon") || chName.contains("pbs kids")
                        || chName.contains("baby") || chName.contains("junior")
                default: return true
                }
            } else {
                // No now-playing data — filter by channel name only
                switch filter {
                case "Sports":
                    return chName.contains("espn") || chName.contains("sport")
                        || chName.contains("nfl") || chName.contains("nba") || chName.contains("mlb")
                        || chName.contains("fs1") || chName.contains("nhl") || chName.contains("mls")
                        || chName.contains("golf") || chName.contains("tennis")
                case "News":
                    return chName.contains("news") || chName.contains("cnn")
                        || chName.contains("msnbc") || chName.contains("cnbc")
                        || chName.contains("bbc") || chName.contains("cheddar")
                        || chName.contains("nhk")
                case "Movies":
                    return chName.contains("movie") || chName.contains("cinema")
                        || chName.contains("hbo") || chName.contains("showtime")
                        || chName.contains("starz") || chName.contains("cinemax")
                        || chName.contains("film")
                case "Entertainment":
                    return chName.contains("amc") || chName.contains("bravo")
                        || chName.contains("fx") || chName.contains("tbs")
                        || chName.contains("tnt") || chName.contains("usa")
                        || chName.contains("comedy") || chName.contains("e!")
                        || chName.contains("a&e") || chName.contains("lifetime")
                case "Kids":
                    return chName.contains("disney") || chName.contains("nick")
                        || chName.contains("cartoon") || chName.contains("pbs kids")
                        || chName.contains("baby") || chName.contains("junior")
                default: return true
                }
            }
        }
        return Array(filtered.prefix(20))
    }

    /// Category filter chips for the On Now rail
    private var tvLiveFilterChips: some View {
        let categories: [(label: String, icon: String, color: Color)] = [
            ("All", "tv", Color(red: 97/255, green: 56/255, blue: 245/255)),
            ("Sports", "sportscourt", Color(red: 56/255, green: 189/255, blue: 148/255)),
            ("News", "newspaper", Color(red: 96/255, green: 165/255, blue: 250/255)),
            ("Movies", "film", Color(red: 168/255, green: 85/255, blue: 247/255)),
            ("Entertainment", "theatermasks", Color(red: 97/255, green: 56/255, blue: 245/255)),
            ("Kids", "sparkles", Color(red: 251/255, green: 191/255, blue: 36/255))
        ]

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.label) { cat in
                    let isSelected = (liveFilterCategory == nil && cat.label == "All") || liveFilterCategory == cat.label
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            liveFilterCategory = cat.label == "All" ? nil : cat.label
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 14))
                            Text(cat.label)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(isSelected ? cat.color.opacity(0.35) : Color.white.opacity(0.08))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? cat.color.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    #if os(tvOS)
                    .buttonStyle(.card)
                    #endif
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 4)
        }
        .focusSection()
    }

    private func resolveAndPlayRecording(_ recording: Recording) {
        Task {
            do {
                resolvedRecordingURL = try await dvrViewModel.getRecordingStream(recording)
                showRecordingPlayer = true
            } catch {
                resolvedRecordingURL = nil
                showRecordingPlayer = true
            }
        }
    }

    /// Recently completed recordings for the home rail
    private var tvRecentlyRecorded: [(title: String, recordings: [Recording])] {
        Array(dvrViewModel.recordingsBySeries.prefix(10))
    }

    private var tvRecommendedItems: [MediaItem] {
        curatedDiscoveryItems(viewModel.recommended, limit: 15)
    }

    private var tvLoadingView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 11/255, green: 11/255, blue: 28/255),
                    Color(red: 20/255, green: 18/255, blue: 43/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ProgressView()
                    .scaleEffect(1.6)
                    .tint(.white)

                Text("Loading Home")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
    }

    private func tvErrorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 54))
                .foregroundStyle(.white.opacity(0.72))

            Text("Home Couldn’t Load")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(message)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 760)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private func heroEyebrow(for item: MediaItem?) -> String {
        guard let item else { return "Featured Tonight" }

        var parts: [String] = [item.type.displayName.uppercased()]
        if let year = item.year {
            parts.append(String(year))
        }
        if let rating = item.contentRating, !rating.isEmpty {
            parts.append(rating)
        }
        if let resolution = item.resolution, !resolution.isEmpty {
            parts.append(resolution)
        }
        return parts.joined(separator: "  •  ")
    }

    private func heroSummary(for item: MediaItem?) -> String? {
        if let tagline = item?.tagline, !tagline.isEmpty {
            return tagline
        }
        if let summary = item?.summary, !summary.isEmpty {
            return summary
        }
        return "A cinematic, focus-first home screen built for Apple TV."
    }

    private func heroArtworkCandidates(for item: MediaItem?) -> [String?] {
        guard let item else { return [] }
        return [item.thumb, item.art, item.banner, item.grandparentThumb]
    }

    private var tvContinueWatchingItems: [MediaItem] {
        deduplicatedItems(viewModel.onDeck.filter(\.isInProgress), limit: 10, preferDiscoveryTypes: false)
    }

    private var tvRecentlyWatchedItems: [MediaItem] {
        deduplicatedItems(viewModel.onDeck, limit: 10, preferDiscoveryTypes: false)
    }

    private var tvNewPopularItems: [MediaItem] {
        let fallbackHubItems = viewModel.hubs
            .filter {
                let title = $0.title.lowercased()
                return title.contains("popular")
                    || title.contains("recent")
                    || title.contains("released")
                    || title.contains("trending")
                    || title.contains("unwatched")
                    || title.contains("top")
            }
            .flatMap(\.items)

        let compositeItems =
            viewModel.recentlyAdded
            + viewModel.featured
            + viewModel.topTen
            + viewModel.recommended
            + fallbackHubItems
            + viewModel.hubs.flatMap(\.items)

        return curatedDiscoveryItems(compositeItems, limit: 12)
    }

    private var tvCuratedHubs: [TVHomeHub] {
        viewModel.hubs.prefix(4).compactMap { hub in
            let curatedItems = curatedDiscoveryItems(hub.items, limit: 12)
            guard !curatedItems.isEmpty else { return nil }
            return TVHomeHub(id: hub.id, title: hub.title, items: curatedItems)
        }
    }

    private var tvMovieItems: [MediaItem] {
        let direct = curatedDiscoveryItems(
            viewModel.recentlyAdded.filter { $0.type == .movie }
            + viewModel.featured.filter { $0.type == .movie }
            + viewModel.recommended.filter { $0.type == .movie }
            + viewModel.hubs.flatMap(\.items).filter { $0.type == .movie },
            limit: 12
        )
        return direct
    }

    private var tvShowItems: [MediaItem] {
        curatedDiscoveryItems(
            viewModel.recentlyAdded.filter { $0.type == .show || $0.type == .episode }
            + viewModel.featured.filter { $0.type == .show || $0.type == .episode }
            + viewModel.recommended.filter { $0.type == .show || $0.type == .episode }
            + viewModel.hubs.flatMap(\.items).filter { $0.type == .show || $0.type == .episode },
            limit: 12
        )
    }

    private var allTVRailsEmpty: Bool {
        tvContinueWatchingItems.isEmpty
            && tvLiveNowChannels.isEmpty
            && tvRecentlyRecorded.isEmpty
            && tvRecentlyAddedItems.isEmpty
            && tvTopPicksItems.isEmpty
            && tvRecommendedItems.isEmpty
            && tvMovieItems.isEmpty
            && tvShowItems.isEmpty
            && tvCuratedHubs.isEmpty
            && viewModel.onLaterTonight.isEmpty
            && viewModel.onLaterSports.isEmpty
            && viewModel.onLaterKids.isEmpty
            && viewModel.onLaterNews.isEmpty
    }

    private func curatedDiscoveryItems(_ items: [MediaItem], limit: Int) -> [MediaItem] {
        deduplicatedItems(items, limit: limit, preferDiscoveryTypes: true)
    }

    private func deduplicatedItems(_ items: [MediaItem], limit: Int, preferDiscoveryTypes: Bool) -> [MediaItem] {
        let sourceItems: [MediaItem]
        if preferDiscoveryTypes {
            let primary = items.filter { $0.type == .movie || $0.type == .show }
            sourceItems = primary.isEmpty ? items.filter { $0.type != .season && $0.type != .episode } : primary
        } else {
            sourceItems = items
        }

        let artworkReadyItems = sourceItems.filter(hasUsableArtwork)

        var seen = Set<String>()
        var seenFranchises = Set<String>()
        var curated: [MediaItem] = []

        for item in artworkReadyItems {
            let key = presentationFamilyKey(for: item)
            guard !seen.contains(key) else { continue }

            if preferDiscoveryTypes {
                let franchiseKey = presentationFranchiseKey(for: item)
                guard !seenFranchises.contains(franchiseKey) else { continue }
                seenFranchises.insert(franchiseKey)
            }

            seen.insert(key)
            curated.append(item)
            if curated.count == limit {
                break
            }
        }

        return curated
    }

    private func hasUsableArtwork(_ item: MediaItem) -> Bool {
        let candidates: [String?] = [item.thumb, item.art, item.banner, item.grandparentThumb]
        return candidates
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains { !$0.isEmpty }
    }

    private func presentationFamilyKey(for item: MediaItem) -> String {
        switch item.type {
        case .episode:
            if let showId = item.grandparentRatingKey {
                return "show-\(showId)"
            }
            if let showTitle = item.grandparentTitle, !showTitle.isEmpty {
                return "show-\(showTitle.lowercased())"
            }
            return "episode-\(item.id)"
        case .season:
            if let showTitle = item.parentTitle, !showTitle.isEmpty {
                return "show-\(showTitle.lowercased())"
            }
            return "season-\(item.id)"
        case .show:
            if let guid = item.guid, !guid.isEmpty {
                return "show-\(guid)"
            }
            return "show-\(item.id)"
        case .movie:
            if let guid = item.guid, !guid.isEmpty {
                return "movie-\(guid)"
            }
            return "movie-\(item.id)"
        default:
            if let guid = item.guid, !guid.isEmpty {
                return "\(item.type.rawValue)-\(guid)"
            }
            return "\(item.type.rawValue)-\(item.id)"
        }
    }

    private func presentationFranchiseKey(for item: MediaItem) -> String {
        let rawTitle: String
        switch item.type {
        case .show:
            rawTitle = item.title
        case .movie:
            rawTitle = item.title
        case .episode:
            rawTitle = item.grandparentTitle ?? item.title
        case .season:
            rawTitle = item.parentTitle ?? item.title
        default:
            rawTitle = item.title
        }

        let normalized = normalizedFranchiseTitle(rawTitle)
        return "\(item.type == .show ? "show" : "franchise")-\(normalized)"
    }

    private func normalizedFranchiseTitle(_ title: String) -> String {
        let lowercased = title.lowercased()
        let trimmed = lowercased
            .components(separatedBy: ":")
            .first?
            .components(separatedBy: " - ")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? lowercased

        let collapsed = trimmed.replacingOccurrences(
            of: #"[^a-z0-9]+"#,
            with: " ",
            options: .regularExpression
        )
        let tokens = collapsed
            .split(separator: " ")
            .map(String.init)
            .filter { !["a", "an", "the"].contains($0) }

        if tokens.count >= 2 {
            return tokens.prefix(2).joined(separator: " ")
        }
        return tokens.joined(separator: " ")
    }

    private func tuneToOnLaterChannel(_ entry: OnLaterProgram) {
        // Try to resolve the OnLater entry's channel against the loaded
        // LiveTV channel list. If we find it, tune in via the existing
        // channel-player presenter.
        if let channel = liveTVViewModel.channels.first(where: { $0.id == entry.channelId }) {
            selectedChannel = channel
            showChannelPlayer = true
        }
        // If not found, silently do nothing — the program may be on a channel
        // we don't have. A future iteration could surface a "Set Reminder"
        // sheet here.
    }

    private func requestHomeFocus() {
        // Retry multiple times — tvOS focus system needs the view to be
        // fully laid out before programmatic focus assignment takes effect.
        let delays: [Double] = [0.05, 0.2, 0.4, 0.7, 1.0]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                focusedHomeTarget = .heroCard
            }
        }
    }
    #endif
}

#if os(tvOS)
private enum TVHomeFocusTarget: Hashable {
    case heroCard
}

private struct TVHomeHub: Identifiable {
    let id: String
    let title: String
    let items: [MediaItem]
}

private enum TVHomeCardStyle {
    case landscape
    case poster
}

private struct TVFocusableCard<Content: View>: View {
    let content: Content
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused

    init(@ViewBuilder content: () -> Content, action: @escaping () -> Void) {
        self.content = content()
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(isFocused ? Color.white.opacity(0.8) : Color.clear, lineWidth: 4)
                )
                .shadow(color: isFocused ? Color.white.opacity(0.18) : .clear, radius: 18, y: 8)
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .buttonStyle(CardButtonStyle())
    }
}

/// Press-state style with an explicit hit region. The focus visuals live on
/// the parent TVFocusableCard — inside a ButtonStyle `@Environment(\.isFocused)`
/// is not reliably updated, and returning just `configuration.label` with no
/// contentShape leaves the tvOS focus engine without a hit-test region, so
/// center-button presses never fire the action.
private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

private struct TVHomeRail: View {
    let title: String
    let subtitle: String
    let items: [MediaItem]
    let cardStyle: TVHomeCardStyle
    let onSelect: (MediaItem) -> Void

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.58))
                }
                .padding(.horizontal, 42)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 26) {
                        ForEach(items) { item in
                            TVMediaCard(item: item, style: cardStyle) {
                                onSelect(item)
                            }
                        }
                    }
                    .padding(.horizontal, 42)
                    .padding(.vertical, 8)
                    .focusSection()
                }
            }
        }
    }
}

private struct TVCompactPosterRail: View {
    let title: String
    let items: [MediaItem]
    let onSelect: (MediaItem) -> Void

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("View All")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.58))
                }
                .padding(.horizontal, 28)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 18) {
                        ForEach(items) { item in
                            TVCompactPosterCard(item: item) {
                                onSelect(item)
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 6)
                    .focusSection()
                }
            }
        }
    }
}

private struct TVCompactWideCard: View {
    let item: MediaItem
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused

    private var progress: Double {
        guard let duration = item.duration, duration > 0,
              let offset = item.viewOffset else { return 0 }
        return min(Double(offset) / Double(duration), 1.0)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .bottomLeading) {
                    AuthenticatedImage(
                        path: item.art ?? item.thumb,
                        systemPlaceholder: "play.rectangle"
                    )
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 340, height: 192)
                    .clipped()

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    if progress > 0 {
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(height: 5)

                                    Capsule()
                                        .fill(Color(red: 97/255, green: 56/255, blue: 245/255))
                                        .frame(width: geo.size.width * progress, height: 5)
                                }
                            }
                        }
                        .frame(width: 340, height: 192)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isFocused ? Color.white.opacity(0.78) : Color.white.opacity(0.06), lineWidth: isFocused ? 3 : 1)
                )

                Text(item.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: 340, alignment: .leading)
            }
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .shadow(color: isFocused ? Color.white.opacity(0.10) : .clear, radius: 8, y: 4)
            .animation(.easeInOut(duration: 0.18), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

private struct TVCompactPosterCard: View {
    let item: MediaItem
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                AuthenticatedImage(
                    path: item.thumb ?? item.art,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .aspectRatio(2 / 3, contentMode: .fill)
                .frame(width: 200, height: 300)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isFocused ? Color.white.opacity(0.78) : Color.white.opacity(0.05), lineWidth: isFocused ? 3 : 1)
                )

                Text(item.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(width: 200, alignment: .leading)
            }
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .shadow(color: isFocused ? Color.white.opacity(0.10) : .clear, radius: 8, y: 4)
            .animation(.easeInOut(duration: 0.18), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

private struct TVOnLaterProgramCard: View {
    let entry: OnLaterProgram
    let onTap: () -> Void

    @Environment(\.isFocused) private var isFocused

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE h:mm a"
        return f
    }()

    var body: some View {
        TVFocusableCard(
            content: { card },
            action: onTap
        )
        .frame(width: 240, height: 200)
    }

    @ViewBuilder
    private var card: some View {
        ZStack(alignment: .bottomLeading) {
            artworkLayer
            scrim
            content
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var artworkLayer: some View {
        if let path = entry.program.art ?? entry.program.icon {
            AuthenticatedImage(path: path, systemPlaceholder: placeholderIcon)
                .aspectRatio(contentMode: .fill)
        } else if let logo = entry.channelLogo {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.16, green: 0.13, blue: 0.30),
                             Color(red: 0.09, green: 0.08, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                AuthenticatedImage(path: logo, systemPlaceholder: placeholderIcon)
                    .aspectRatio(contentMode: .fit)
                    .padding(36)
            }
        } else {
            LinearGradient(
                colors: [Color(red: 0.16, green: 0.13, blue: 0.30),
                         Color(red: 0.09, green: 0.08, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: placeholderIcon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.white.opacity(0.32))
            }
        }
    }

    private var scrim: some View {
        LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.86)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            badgeRow
            Text(entry.program.title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
            HStack(spacing: 6) {
                Text(channelLabel)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                Text("·")
                    .foregroundStyle(.white.opacity(0.4))
                Text(Self.timeFormatter.string(from: entry.program.startTime))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private var badgeRow: some View {
        HStack(spacing: 4) {
            if entry.program.isLive {
                badge("LIVE", tint: .red)
            }
            if entry.program.isNew {
                badge("NEW", tint: .blue)
            }
            if entry.program.isPremiere {
                badge("PREMIERE", tint: .purple)
            }
        }
    }

    private func badge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.85), in: Capsule())
    }

    private var channelLabel: String {
        if let n = entry.channelNumber {
            return "\(n) · \(entry.channelName)"
        }
        return entry.channelName
    }

    private var placeholderIcon: String {
        if entry.program.isSports { return "sportscourt" }
        if entry.program.isKids { return "balloon.2" }
        if entry.program.isNews { return "newspaper" }
        return "tv"
    }
}

private struct TVCompactRankedCard: View {
    let item: MediaItem
    let rank: Int
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                Text("\(rank)")
                    .font(.system(size: 120, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.12))
                    .frame(width: 88)
                    .offset(x: 6, y: 8)

                AuthenticatedImage(
                    path: item.thumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .aspectRatio(2/3, contentMode: .fill)
                .frame(width: 180, height: 270)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isFocused ? Color.white.opacity(0.78) : Color.white.opacity(0.05), lineWidth: isFocused ? 3 : 1)
                )
                .offset(x: 58)
            }
            .frame(width: 250, height: 270)
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .shadow(color: isFocused ? Color.white.opacity(0.10) : .clear, radius: 8, y: 4)
            .animation(.easeInOut(duration: 0.18), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

private struct TVRecentChannelCard: View {
    let channel: Channel
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 33/255, green: 25/255, blue: 55/255),
                                    Color(red: 20/255, green: 18/255, blue: 34/255)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 230, height: 132)

                    AuthenticatedImage(
                        path: channel.logo,
                        systemPlaceholder: "tv"
                    )
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 110, height: 64)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isFocused ? Color.white.opacity(0.78) : Color.white.opacity(0.05), lineWidth: isFocused ? 3 : 1)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let number = channel.number {
                        Text(String(number))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }
                .frame(width: 230, alignment: .leading)
            }
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .shadow(color: isFocused ? Color.white.opacity(0.10) : .clear, radius: 8, y: 4)
            .animation(.easeInOut(duration: 0.18), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

private extension XfinityHomeView {
    @ViewBuilder
    func tvHomeRow<Content: View>(
        title: String,
        showViewAll: Bool = false,
        onViewAll: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if showViewAll {
                    if let onViewAll {
                        Button(action: onViewAll) {
                            HStack(spacing: 4) {
                                Text("View All")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(Color(red: 97/255, green: 56/255, blue: 245/255))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("View All")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }
            }
            .padding(.horizontal, 28)

            content()
        }
    }
}

private struct TVMediaCard: View {
    let item: MediaItem
    let style: TVHomeCardStyle
    let action: () -> Void

    private var imagePath: String? {
        switch style {
        case .landscape:
            return item.art ?? item.thumb ?? item.banner
        case .poster:
            return item.thumb ?? item.art
        }
    }

    var body: some View {
        TVFocusableCard {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 32/255, green: 30/255, blue: 48/255),
                                    Color(red: 19/255, green: 18/255, blue: 29/255)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: cardSize.width, height: cardSize.height)

                    AuthenticatedImage(
                        path: imagePath,
                        systemPlaceholder: style == .landscape ? "play.rectangle.fill" : "photo"
                    )
                    .aspectRatio(cardAspectRatio, contentMode: .fill)
                    .frame(width: cardSize.width, height: cardSize.height)
                    .clipped()

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    if item.isInProgress {
                        VStack(spacing: 10) {
                            Spacer()

                            if style == .landscape {
                                Text(item.title)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                    Capsule()
                                        .fill(Color.white)
                                        .frame(width: proxy.size.width * item.progressPercent)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(18)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: style == .landscape ? 28 : 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(cardSubtitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }
                .frame(width: cardSize.width, alignment: .leading)
            }
        } action: {
            action()
        }
    }

    private var cardSize: CGSize {
        switch style {
        case .landscape:
            return CGSize(width: 420, height: 236)
        case .poster:
            return CGSize(width: 230, height: 336)
        }
    }

    private var cardAspectRatio: CGFloat {
        switch style {
        case .landscape:
            return 16 / 9
        case .poster:
            return 2 / 3
        }
    }

    private var cardSubtitle: String {
        if let episodeLabel = item.episodeLabel {
            return episodeLabel
        }
        if let grandparentTitle = item.grandparentTitle, !grandparentTitle.isEmpty {
            return grandparentTitle
        }
        if let year = item.year {
            return "\(item.type.displayName) • \(year)"
        }
        return item.type.displayName
    }
}

private struct TVFeaturedDestinationsRow: View {
    private let cards: [TVFeaturedDestination] = [
        TVFeaturedDestination(
            title: "Drama Picks",
            subtitle: "Serialized, cinematic, premium",
            colors: [Color(red: 123/255, green: 84/255, blue: 255/255), Color(red: 59/255, green: 126/255, blue: 246/255)],
            symbol: "sparkles.tv"
        ),
        TVFeaturedDestination(
            title: "Movie Night",
            subtitle: "Blockbusters and comfort rewatches",
            colors: [Color(red: 252/255, green: 113/255, blue: 77/255), Color(red: 252/255, green: 64/255, blue: 129/255)],
            symbol: "film.stack.fill"
        ),
        TVFeaturedDestination(
            title: "What To Watch",
            subtitle: "Fast-start picks for tonight",
            colors: [Color(red: 109/255, green: 93/255, blue: 252/255), Color(red: 194/255, green: 83/255, blue: 245/255)],
            symbol: "star.bubble.fill"
        ),
        TVFeaturedDestination(
            title: "Live Sports",
            subtitle: "Game-day energy on the main screen",
            colors: [Color(red: 29/255, green: 201/255, blue: 142/255), Color(red: 20/255, green: 164/255, blue: 230/255)],
            symbol: "sportscourt.fill"
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Explore")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Fast lanes into the biggest categories")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .padding(.horizontal, 42)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(cards) { card in
                        TVFeaturedDestinationCard(card: card)
                    }
                }
                .padding(.horizontal, 42)
                .padding(.vertical, 8)
                .focusSection()
            }
        }
    }
}

private struct TVFeaturedDestination: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let colors: [Color]
    let symbol: String
}

private struct TVFeaturedDestinationCard: View {
    let card: TVFeaturedDestination
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: {
            // Featured destination action - could navigate to specific category
        }) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: card.colors, startPoint: .topLeading, endPoint: .bottomTrailing)

                Circle()
                    .fill(.white.opacity(isFocused ? 0.2 : 0.14))
                    .frame(width: 180, height: 180)
                    .offset(x: 100, y: 10)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(isFocused ? Color.white.opacity(0.92) : Color.white.opacity(0.08), lineWidth: isFocused ? 3 : 1)

                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: card.symbol)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(isFocused ? .white : .white.opacity(0.85))

                    Spacer()

                    Text(card.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(card.subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isFocused ? .white.opacity(0.92) : .white.opacity(0.8))
                        .lineLimit(2)
                }
                .padding(24)
            }
            .frame(width: 320, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: isFocused ? Color.white.opacity(0.16) : .clear, radius: 10, y: 4)
            .scaleEffect(isFocused ? 1.035 : 1.0)
            .opacity(isFocused ? 1.0 : 0.92)
            .animation(.easeInOut(duration: 0.18), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

private enum TVHeroButtonStyle {
    case primary, secondary
}

private struct TVHeroButton: View {
    let title: String
    let systemImage: String
    let style: TVHeroButtonStyle
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(backgroundFill, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(borderColor, lineWidth: isActive ? 3 : (style == .secondary ? 1 : 0))
                }
                .shadow(color: isActive ? Color.white.opacity(0.18) : .clear, radius: 10, y: 3)
                .overlay {
                    Capsule()
                        .fill(Color.white.opacity(isActive ? 0.06 : 0))
                        .padding(-4)
                        .blur(radius: 5)
                }
                .scaleEffect(isActive ? 1.04 : 1.0)
                .animation(.easeInOut(duration: 0.18), value: isActive)
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .black
        case .secondary:
            return isActive ? .black : .white
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return isActive ? .white : .clear
        case .secondary:
            return isActive ? .white : Color.white.opacity(0.2)
        }
    }

    private var backgroundFill: LinearGradient {
        switch style {
        case .primary:
            return LinearGradient(
                colors: isActive
                    ? [Color.white, Color(red: 232/255, green: 225/255, blue: 255/255)]
                    : [Color.white.opacity(0.95), Color.white.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            return LinearGradient(
                colors: isActive
                    ? [Color.white, Color(red: 226/255, green: 220/255, blue: 255/255)]
                    : [Color.white.opacity(0.16), Color.white.opacity(0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

#endif

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

// MARK: - Live Now Card (Category-Colored)

private struct TVLiveNowCard: View {
    let channel: Channel
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused

    private var nowPlaying: Program? { channel.nowPlaying }
    private var progress: Double { nowPlaying?.progress ?? 0 }

    private var catColor: Color {
        let teal = Color(red: 56/255, green: 189/255, blue: 148/255)
        let violet = Color(red: 168/255, green: 85/255, blue: 247/255)
        let blue = Color(red: 96/255, green: 165/255, blue: 250/255)
        let amber = Color(red: 251/255, green: 191/255, blue: 36/255)
        let brandPurple = Color(red: 97/255, green: 56/255, blue: 245/255)

        // Check program data first
        if let program = nowPlaying {
            if program.isSports { return teal }
            if program.isMovie { return violet }
            if program.isNews { return blue }
            if program.isKids { return amber }
            if let cat = program.category?.lowercased() {
                if cat.contains("sport") { return teal }
                if cat.contains("movie") || cat.contains("film") { return violet }
                if cat.contains("news") { return blue }
                if cat.contains("kid") || cat.contains("child") { return amber }
            }
        }

        // Fallback: infer category from channel name
        let name = channel.name.lowercased()
        if name.contains("espn") || name.contains("sport") || name.contains("nfl")
            || name.contains("nba") || name.contains("mlb") || name.contains("nhl")
            || name.contains("fs1") || name.contains("golf") || name.contains("tennis")
            || name.contains("mls") || name.contains("redzone") { return teal }
        if name.contains("movie") || name.contains("cinema") || name.contains("hbo")
            || name.contains("showtime") || name.contains("starz") || name.contains("cinemax")
            || name.contains("film") || name.contains("flix") { return violet }
        if name.contains("news") || name.contains("cnn") || name.contains("msnbc")
            || name.contains("cnbc") || name.contains("bbc") || name.contains("cheddar")
            || name.contains("nhk") || name.contains("newsy") { return blue }
        if name.contains("disney") || name.contains("nick") || name.contains("cartoon")
            || name.contains("pbs kids") || name.contains("baby") || name.contains("junior")
            || name.contains("sprout") { return amber }

        return brandPurple
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Category stripe
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [catColor, catColor.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: isFocused ? 6 : 4)
                    .padding(.vertical, 8)
                    .shadow(color: isFocused ? catColor : .clear, radius: 4)

                // Card content
                ZStack(alignment: .topLeading) {
                    // Background: program artwork or category-colored gradient
                    if let programImage = nowPlaying?.art ?? nowPlaying?.icon {
                        AuthenticatedImage(
                            path: programImage,
                            systemPlaceholder: "tv"
                        )
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(width: 334, height: 220)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [.clear, Color.black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        catColor.opacity(0.25),
                                        Color(red: 13/255, green: 15/255, blue: 28/255)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 334, height: 220)
                    }

                    // Top row: channel number + name | LIVE badge
                    HStack {
                        Text(channel.displayName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(catColor)
                            .lineLimit(1)

                        if channel.isHD {
                            Text("HD")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(catColor.opacity(0.3), in: Capsule())
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        Spacer()

                        if nowPlaying != nil {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 7, height: 7)
                                Text("LIVE")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.82), in: Capsule())
                            .foregroundStyle(.white)
                        }

                        if channel.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.red.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)

                    // Center: channel logo + program info
                    VStack(spacing: 8) {
                        Spacer(minLength: 30)

                        if let logoPath = channel.logo {
                            AuthenticatedImage(
                                path: logoPath,
                                systemPlaceholder: "tv"
                            )
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 56)
                        }

                        if let program = nowPlaying {
                            Text(program.title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .shadow(radius: 2)

                            if let subtitle = program.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.65))
                                    .lineLimit(1)
                            }
                        } else {
                            Text(channel.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)

                    // Bottom: time + progress
                    VStack(alignment: .leading, spacing: 6) {
                        Spacer()

                        if let program = nowPlaying {
                            HStack(spacing: 8) {
                                Text(program.timeRangeFormatted)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.55))

                                if program.remainingMinutes > 0 {
                                    Text("\(program.remainingMinutes) min left")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.45))
                                }

                                // Program badges
                                ForEach(program.badges, id: \.self) { badge in
                                    Text(badge)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(catColor.opacity(0.35), in: Capsule())
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                            }
                        }

                        // Progress bar
                        if nowPlaying != nil && progress > 0 {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(height: 4)
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [catColor, catColor.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * CGFloat(progress), height: 4)

                                    // Glowing dot at progress point
                                    if isFocused {
                                        Circle()
                                            .fill(catColor)
                                            .frame(width: 8, height: 8)
                                            .shadow(color: catColor, radius: 4)
                                            .offset(x: geo.size.width * CGFloat(progress) - 4)
                                    }
                                }
                            }
                            .frame(height: isFocused ? 6 : 4)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isFocused ? catColor.opacity(0.6) : Color.white.opacity(0.06),
                        lineWidth: isFocused ? 3 : 1
                    )
            )
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .shadow(color: isFocused ? catColor.opacity(0.25) : .clear, radius: 10, y: 4)
            .animation(.easeInOut(duration: 0.18), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Series Recorded Card (grouped by show)

private struct TVSeriesRecordedCard: View {
    let title: String
    let recordings: [Recording]
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused

    private var latestRecording: Recording? { recordings.first }
    private var episodeCount: Int { recordings.count }
    private var isAnyRecording: Bool { recordings.contains { $0.isCurrentlyRecording } }
    private var hasNewEpisode: Bool {
        guard let latest = latestRecording else { return false }
        return !latest.isWatched && latest.endTime > Date().addingTimeInterval(-86400)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    // Artwork from the most recent recording
                    AuthenticatedImage(
                        path: latestRecording?.art ?? latestRecording?.thumb,
                        systemPlaceholder: "tv"
                    )
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 340, height: 192)
                    .clipped()

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Badges
                    HStack(spacing: 6) {
                        if isAnyRecording {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 7, height: 7)
                                Text("REC")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.85), in: Capsule())
                            .foregroundStyle(.white)
                        }

                        if hasNewEpisode {
                            Text("New Episode")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 97/255, green: 56/255, blue: 245/255), in: Capsule())
                            .foregroundStyle(.white)
                        }

                        if !isAnyRecording && !hasNewEpisode {
                            Text("\(episodeCount) Episodes")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.18), in: Capsule())
                            .foregroundStyle(.white)
                        }
                    }
                    .padding(10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isFocused ? Color.white.opacity(0.78) : Color.white.opacity(0.06), lineWidth: isFocused ? 3 : 1)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let channelName = latestRecording?.channelName {
                        Text(channelName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.48))
                            .lineLimit(1)
                    }
                }
                .frame(width: 340, alignment: .leading)
            }
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .shadow(color: isFocused ? Color.white.opacity(0.10) : .clear, radius: 8, y: 4)
            .animation(.easeInOut(duration: 0.18), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Series Episodes View (fullScreenCover)

private struct TVSeriesEpisodesView: View {
    let title: String
    let recordings: [Recording]
    let onPlayRecording: (Recording) -> Void
    let onDismiss: () -> Void

    @Environment(\.isFocused) private var isFocused
    @FocusState private var focusedEpisodeId: Int?
    @State private var selectedEpisode: Recording?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header with artwork + title
                    headerSection

                    // Episode list
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(recordings) { recording in
                            episodeRow(recording)
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 80)
                }
            }
        }
        .focusSection()
    }

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Background artwork
            AuthenticatedImage(
                path: recordings.first?.art ?? recordings.first?.thumb,
                systemPlaceholder: "tv"
            )
            .aspectRatio(contentMode: .fill)
            .frame(height: 360)
            .clipped()
            .blur(radius: 10)
            .overlay(Color.black.opacity(0.55))

            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    Text("\(recordings.count) episodes")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))

                    if let channel = recordings.first?.channelName {
                        Text(channel)
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    if recordings.contains(where: { $0.isCurrentlyRecording }) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Recording")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                    }
                }

                // Close button
                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Close")
                    }
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(60)
        }
    }

    private func episodeRow(_ recording: Recording) -> some View {
        Button {
            onPlayRecording(recording)
        } label: {
            HStack(spacing: 20) {
                // Thumbnail
                AuthenticatedImage(
                    path: recording.thumb ?? recording.art,
                    systemPlaceholder: "play.rectangle"
                )
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: 200, height: 112)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isFocused && focusedEpisodeId == recording.id ? Color.white.opacity(0.78) : Color.white.opacity(0.06), lineWidth: isFocused && focusedEpisodeId == recording.id ? 3 : 1)
                )

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if recording.isCurrentlyRecording {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 7, height: 7)
                                Text("REC")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                        } else if !recording.isWatched && recording.endTime > Date().addingTimeInterval(-86400) {
                            Text("NEW")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(red: 97/255, green: 56/255, blue: 245/255), in: Capsule())
                            .foregroundStyle(.white)
                        }

                        if let label = recording.episodeLabel {
                            Text(label)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                    }

                    if let subtitle = recording.subtitle {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.62))
                            .lineLimit(2)
                    }

                    if let desc = recording.description {
                        Text(desc)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(2)
                    }

                    HStack(spacing: 10) {
                        if let channelName = recording.channelName {
                            Text(channelName)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.38))
                        }

                        Text(recording.durationFormatted)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.38))

                        Text(recording.endTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.38))
                    }
                }

                Spacer()

                // Play icon
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .focused($focusedEpisodeId, equals: recording.id)
    }
}

#Preview {
    NavigationStack {
        XfinityHomeView()
    }
}
