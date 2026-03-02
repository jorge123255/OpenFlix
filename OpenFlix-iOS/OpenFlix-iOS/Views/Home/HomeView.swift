import SwiftUI

// MARK: - YouTube TV Style Home View
// Live-first design: What's on now, recordings, upcoming

struct HomeView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var selectedItem: MediaItem?
    @State private var selectedChannel: Channel?
    @State private var showMediaDetail = false
    @State private var showPlayer = false
    @State private var showLivePlayer = false
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.recentlyAdded.isEmpty {
                LoadingView(message: "Loading...")
            } else if viewModel.recentlyAdded.isEmpty && viewModel.onDeck.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
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
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tv.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Content Available")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(viewModel.error ?? "No content available")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Task { await viewModel.loadHomeContent() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Content
    
    private var contentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 28) {
                
                // MARK: Keep Watching (Continue)
                if !viewModel.onDeck.isEmpty {
                    HomeSection(title: "Keep Watching", icon: "play.circle.fill", iconColor: .blue) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.onDeck.filter { $0.isInProgress }) { item in
                                    HomeContinueCard(item: item) {
                                        selectedItem = item
                                        showPlayer = true
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                
                // MARK: Recently Added
                if !viewModel.recentlyAdded.isEmpty {
                    HomeSection(title: "Recently Added", icon: "sparkles", iconColor: .red) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.recentlyAdded.prefix(15)) { item in
                                    PosterCard(item: item) {
                                        selectedItem = item
                                        showMediaDetail = true
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                
                // MARK: Hubs (from server)
                ForEach(viewModel.hubs.prefix(4)) { hub in
                    HomeSection(title: hub.title, icon: "square.grid.2x2.fill", iconColor: .orange) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(hub.items.prefix(10)) { item in
                                    PosterCard(item: item) {
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
            .padding(.top, 16)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Home Section

struct HomeSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            content
        }
    }
}

// MARK: - Live Now Card

struct LiveNowCard: View {
    let item: LiveNowItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail with live badge
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: item.thumbnail ?? "")) { phase in
                        if case .success(let image) = phase {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.gray.opacity(0.2))
                        }
                    }
                    .frame(width: 200, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // LIVE badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .padding(8)
                }
                
                // Channel logo + info
                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: item.channelLogo ?? "")) { phase in
                        if case .success(let image) = phase {
                            image.resizable().aspectRatio(contentMode: .fit)
                        } else {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Text(item.channelName)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(width: 200, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home Continue Card

struct HomeContinueCard: View {
    let item: MediaItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail with progress
                ZStack(alignment: .bottom) {
                    AuthenticatedImage(
                        path: item.art ?? item.thumb,
                        systemPlaceholder: "play.rectangle"
                    )
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 200, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Progress bar
                    GeometryReader { geo in
                        VStack {
                            Spacer()
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 3)
                                
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: geo.size.width * item.progressPercent, height: 3)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    if let duration = item.duration, let offset = item.viewOffset, duration > offset {
                        let remainingMin = (duration - offset) / 60000
                        Text("\(remainingMin) min left")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 200, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recording Card

struct RecordingCard: View {
    let recording: Recording
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: thumbURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "play.rectangle")
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .frame(width: 200, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Duration badge
                    Text(recording.durationFormatted)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(6)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(recording.fullTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    if let channelName = recording.channelName {
                        Text(channelName)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 200, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var thumbURL: URL? {
        guard let thumb = recording.thumb,
              let serverURL = UserDefaults.standard.serverURL else { return nil }
        return serverURL.appendingPathComponent(thumb)
    }
}

// MARK: - On Later Card

struct OnLaterCard: View {
    let program: Program
    let channelName: String?
    let onTap: () -> Void
    
    init(program: Program, channelName: String? = nil, onTap: @escaping () -> Void) {
        self.program = program
        self.channelName = channelName
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: program.icon ?? program.art ?? "")) { phase in
                        if case .success(let image) = phase {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: program.categoryIcon)
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .frame(width: 200, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Time badge
                    Text(program.startTimeFormatted)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(4)
                        .padding(6)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(program.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    if let channelName = channelName, !channelName.isEmpty {
                        Text(channelName)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(width: 200, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Poster Card (for Movies/TV)

struct PosterCard: View {
    let item: MediaItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                AuthenticatedImage(
                    path: item.thumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .aspectRatio(2/3, contentMode: .fill)
                .frame(width: 120, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .frame(width: 120, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Live Now Item Model

struct LiveNowItem: Identifiable {
    let id: String
    let title: String
    let channelName: String
    let channelLogo: String?
    let thumbnail: String?
    let channelId: String
}

// MARK: - On Later Item (Program with channel info)

struct OnLaterItem: Identifiable {
    let id: String
    let program: Program
    let channelName: String
    
    init(program: Program, channelName: String) {
        self.id = "\(program.id)-\(channelName)"
        self.program = program
        self.channelName = channelName
    }
}


#Preview {
    NavigationStack {
        HomeView()
    }
}
