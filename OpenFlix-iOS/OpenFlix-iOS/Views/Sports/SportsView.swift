import SwiftUI

// MARK: - Sports View
// Shows live sports events grouped by sport/league

struct SportsView: View {
    @StateObject private var viewModel = LiveTVViewModel()
    @StateObject private var dvrViewModel = DVRViewModel()
    @State private var showPlayer = false
    @State private var selectedChannel: Channel?
    @State private var streamURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.channels.isEmpty {
                    LoadingView(message: "Loading sports...")
                } else if sportsChannels.isEmpty {
                    EmptyStateView(
                        icon: "sportscourt",
                        title: "No Live Sports",
                        message: "Check back later for live games and events."
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            // Live Now header
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("LIVE NOW")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.red)
                                Spacer()
                                Text("\(sportsChannels.count) events")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            // Group by sport/category
                            ForEach(sportGroups, id: \.name) { group in
                                SportGroupSection(
                                    group: group,
                                    onChannelTap: { channel in
                                        playChannel(channel)
                                    }
                                )
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Sports")
            #if !os(tvOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let channel = selectedChannel {
                #if os(tvOS)
                TVLiveChannelPlayerView(
                    initialChannel: channel,
                    initialStreamURL: streamURL,
                    viewModel: viewModel
                )
                .id(channel.id)  // stable identity prevents SwiftUI recreating VLC
                .environmentObject(dvrViewModel)
                #else
                if let url = streamURL {
                    AdaptiveLivePlayerView(
                        channel: channel,
                        program: channel.nowPlaying,
                        streamURL: url,
                        channels: sportsChannels,
                        onChannelChange: { newChannel in
                            playChannel(newChannel)
                        },
                        onClose: {
                            showPlayer = false
                        }
                    )
                }
                #endif
            }
        }
        .task {
            await viewModel.loadChannels()
        }
    }
    
    // MARK: - Sports Channels
    
    private var sportsChannels: [Channel] {
        viewModel.channels.filter { channel in
            let name = channel.name.lowercased()
            let group = (channel.group ?? "").lowercased()
            
            // Match sports-related channels
            return group.contains("sport") ||
                   name.contains("espn") ||
                   name.contains("fox sports") ||
                   name.contains("nfl") ||
                   name.contains("nba") ||
                   name.contains("mlb") ||
                   name.contains("nhl") ||
                   name.contains("golf") ||
                   name.contains("tennis") ||
                   name.contains("soccer") ||
                   name.contains("football") ||
                   name.contains("basketball") ||
                   name.contains("baseball") ||
                   name.contains("hockey") ||
                   name.contains(" vs ") ||
                   name.contains(" vs. ") ||
                   name.contains("game") ||
                   name.contains("match")
        }
    }
    
    // MARK: - Sport Groups
    
    private var sportGroups: [SportGroup] {
        var groups: [String: [Channel]] = [:]
        
        for channel in sportsChannels {
            let sport = detectSport(for: channel)
            if groups[sport] == nil {
                groups[sport] = []
            }
            groups[sport]?.append(channel)
        }
        
        return groups.map { SportGroup(name: $0.key, channels: $0.value) }
            .sorted { $0.channels.count > $1.channels.count }
    }
    
    private func detectSport(for channel: Channel) -> String {
        let name = channel.name.lowercased()
        let group = (channel.group ?? "").lowercased()
        
        if name.contains("nfl") || name.contains("football") && !name.contains("soccer") {
            return "🏈 Football"
        } else if name.contains("nba") || name.contains("basketball") {
            return "🏀 Basketball"
        } else if name.contains("mlb") || name.contains("baseball") {
            return "⚾ Baseball"
        } else if name.contains("nhl") || name.contains("hockey") {
            return "🏒 Hockey"
        } else if name.contains("soccer") || name.contains("futbol") || name.contains("mls") || name.contains("premier league") {
            return "⚽ Soccer"
        } else if name.contains("golf") || name.contains("pga") {
            return "⛳ Golf"
        } else if name.contains("tennis") || name.contains("atp") || name.contains("wta") {
            return "🎾 Tennis"
        } else if name.contains("lacrosse") {
            return "🥍 Lacrosse"
        } else if name.contains("ufc") || name.contains("mma") || name.contains("boxing") {
            return "🥊 Combat Sports"
        } else if name.contains("racing") || name.contains("nascar") || name.contains("f1") {
            return "🏎️ Racing"
        } else if name.contains("espn") {
            return "📺 ESPN"
        } else if group.contains("sport") {
            return "🏆 Sports"
        }
        
        return "🏆 Sports"
    }
    
    // MARK: - Play Channel
    
    private func playChannel(_ channel: Channel) {
        selectedChannel = channel
        
        if let url = channel.preferredPlaybackURL {
            streamURL = url
            showPlayer = true
            return
        }
        
        Task {
            do {
                let url = try await viewModel.getChannelStream(channel)
                streamURL = url
                showPlayer = true
            } catch {
                viewModel.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Sport Group

struct SportGroup {
    let name: String
    let channels: [Channel]
}

// MARK: - Sport Group Section

struct SportGroupSection: View {
    let group: SportGroup
    let onChannelTap: (Channel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(group.name)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("\(group.channels.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }
            .padding(.horizontal, 28)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(group.channels) { channel in
                        SportEventCard(channel: channel) {
                            onChannelTap(channel)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 6)
                #if os(tvOS)
                .focusSection()
                #endif
            }
        }
    }
}

// MARK: - Sport Event Card

struct SportEventCard: View {
    let channel: Channel
    let onTap: () -> Void

    #if os(tvOS)
    @Environment(\.isFocused) private var isFocused
    #endif

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                background
                gradient
                content
            }
            .frame(width: 280, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            #if os(tvOS)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isFocused ? Color.red.opacity(0.85) : Color.clear, lineWidth: 4)
            )
            .scaleEffect(isFocused ? 1.06 : 1)
            .shadow(color: isFocused ? Color.red.opacity(0.25) : .clear, radius: 22, y: 10)
            .animation(.easeInOut(duration: 0.18), value: isFocused)
            #endif
        }
        #if os(tvOS)
        .buttonStyle(SportEventButtonStyle())
        #else
        .buttonStyle(.plain)
        #endif
    }

    @ViewBuilder
    private var background: some View {
        if let logoPath = channel.logo, !logoPath.isEmpty, let url = URL(string: logoPath) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    ZStack {
                        Color.black
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(36)
                    }
                default:
                    placeholderBg
                }
            }
        } else {
            placeholderBg
        }
    }

    private var placeholderBg: some View {
        LinearGradient(
            colors: [Color(red: 0.16, green: 0.06, blue: 0.06),
                     Color(red: 0.06, green: 0.04, blue: 0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "sportscourt")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.32))
        }
    }

    private var gradient: some View {
        LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.85)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("LIVE")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
                if !channel.displayNumber.isEmpty {
                    Text("· CH \(channel.displayNumber)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            Text(channel.name)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(14)
    }
}

#if os(tvOS)
private struct SportEventButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}
#endif

#Preview {
    SportsView()
}
