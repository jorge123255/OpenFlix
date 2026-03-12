import SwiftUI

// MARK: - Home View (Redesigned)

struct HomeView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showMediaDetail = false
    @State private var showPlayer = false

    private let bg   = Color(red: 17/255,  green: 12/255, blue: 33/255)
    private let card = Color(red: 26/255,  green: 20/255, blue: 46/255)
    private let accent = Color(red: 97/255, green: 56/255, blue: 245/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            if viewModel.isLoading && viewModel.recentlyAdded.isEmpty && viewModel.onDeck.isEmpty {
                VStack(spacing: 12) {
                    ProgressView().tint(accent).scaleEffect(1.3)
                    Text("Loading…")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
            } else {
                contentScroll
            }
        }
        .task { await viewModel.loadHomeContent() }
        .refreshable { await viewModel.loadHomeContent() }
        .navigationDestination(isPresented: $showMediaDetail) {
            if let item = selectedItem { MediaDetailView(mediaId: item.id) }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let item = selectedItem {
                VideoPlayerView(mediaItem: item, startPosition: item.viewOffset)
            }
        }
    }

    // MARK: - Main Scroll

    private var contentScroll: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Hero Banner ──────────────────────────────────────────
                if !viewModel.featured.isEmpty {
                    HeroBannerView(
                        items: Array(viewModel.featured.prefix(5)),
                        onPlay: { item in
                            selectedItem = item
                            showPlayer = true
                        },
                        onDetails: { item in
                            selectedItem = item
                            showMediaDetail = true
                        }
                    )
                    // Extend art behind the nav bar
                    .ignoresSafeArea(edges: .top)
                }

                VStack(alignment: .leading, spacing: 36) {

                    // ── Continue Watching ────────────────────────────────
                    let inProgress = viewModel.onDeck.filter { $0.isInProgress }
                    if !inProgress.isEmpty {
                        homeRow(
                            title: "Continue Watching",
                            icon: "play.circle.fill",
                            iconColor: accent
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(inProgress) { item in
                                        HomeWideCard(item: item, accent: accent) {
                                            selectedItem = item
                                            showPlayer = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // ── Recently Added ───────────────────────────────────
                    if !viewModel.recentlyAdded.isEmpty {
                        homeRow(
                            title: "Recently Added",
                            icon: "sparkles",
                            iconColor: .yellow
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.recentlyAdded.prefix(20)) { item in
                                        HomePosterCard(item: item) {
                                            selectedItem = item
                                            showMediaDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // ── Top Picks ────────────────────────────────────────
                    if !viewModel.topTen.isEmpty {
                        homeRow(
                            title: "Top Picks",
                            icon: "star.fill",
                            iconColor: .orange
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 4) {
                                    ForEach(Array(viewModel.topTen.prefix(10).enumerated()), id: \.element.id) { idx, item in
                                        HomeRankedCard(item: item, rank: idx + 1) {
                                            selectedItem = item
                                            showMediaDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // ── Recommended ──────────────────────────────────────
                    if !viewModel.recommended.isEmpty {
                        homeRow(
                            title: "Recommended For You",
                            icon: "hand.thumbsup.fill",
                            iconColor: .green
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.recommended.prefix(15)) { item in
                                        HomePosterCard(item: item) {
                                            selectedItem = item
                                            showMediaDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // ── Server Hubs ──────────────────────────────────────
                    ForEach(viewModel.hubs.prefix(6)) { hub in
                        homeRow(
                            title: hub.title,
                            icon: "square.grid.2x2.fill",
                            iconColor: accent
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(hub.items.prefix(15)) { item in
                                        HomePosterCard(item: item) {
                                            selectedItem = item
                                            showMediaDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // ── Streaming Services ───────────────────────────────
                    ForEach(viewModel.streamingServices.prefix(4)) { service in
                        homeRow(
                            title: service.name,
                            icon: "play.rectangle.fill",
                            iconColor: .cyan
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(service.items.prefix(15)) { item in
                                        HomePosterCard(item: item) {
                                            selectedItem = item
                                            showMediaDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, 28)
            }
        }
        .background(bg)
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func homeRow<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)

            content()
        }
    }
}

// MARK: - Wide "Continue Watching" Card  (240 × 140)

struct HomeWideCard: View {
    let item: MediaItem
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                // Art
                AuthenticatedImage(
                    path: item.art ?? item.thumb,
                    systemPlaceholder: "play.rectangle.fill"
                )
                .scaledToFill()
                .frame(width: 240, height: 140)
                .clipped()

                // Dark gradient from centre down
                LinearGradient(
                    colors: [.clear, .black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Info overlay
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.granularTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            if let remaining = item.remainingMinutes {
                                Text("\(remaining) min left")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .frame(height: 3)
                            Capsule()
                                .fill(accent)
                                .frame(width: geo.size.width * CGFloat(item.progressPercent), height: 3)
                        }
                    }
                    .frame(height: 3)
                }
                .padding(10)
            }
            .frame(width: 240, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Poster Card  (110 × 165)

struct HomePosterCard: View {
    let item: MediaItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                AuthenticatedImage(
                    path: item.thumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .scaledToFill()
                .frame(width: 110, height: 165)
                .clipped()

                // Fade at bottom for legibility
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                Text(item.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 7)
                    .padding(.bottom, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 110, height: 165)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ranked Card  (rank number + 100 × 150 poster)

struct HomeRankedCard: View {
    let item: MediaItem
    let rank: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Big rank number behind poster
                Text("\(rank)")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.12))
                    .frame(width: 60)
                    .offset(x: 2, y: 8)

                // Poster offset right
                ZStack(alignment: .bottom) {
                    AuthenticatedImage(
                        path: item.thumb,
                        systemPlaceholder: item.type == .movie ? "film" : "tv"
                    )
                    .scaledToFill()
                    .frame(width: 100, height: 150)
                    .clipped()

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
                .frame(width: 100, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .offset(x: 42)
            }
            .frame(width: 148, height: 150)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MediaItem helpers

private extension MediaItem {
    /// Best short title for "continue watching" overlay
    var granularTitle: String {
        if let parent = grandparentTitle ?? parentTitle { return parent }
        return title
    }

    var remainingMinutes: Int? {
        guard let d = duration, let o = viewOffset, d > o else { return nil }
        let mins = (d - o) / 60000
        return mins > 0 ? mins : nil
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
    }
}
