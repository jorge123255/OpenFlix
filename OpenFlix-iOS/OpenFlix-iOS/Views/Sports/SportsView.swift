import SwiftUI

// MARK: - Sports View
// Shows live sports events grouped by sport/league

struct SportsView: View {
    @StateObject private var viewModel = LiveTVViewModel()
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
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let channel = selectedChannel, let url = streamURL {
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
        
        if let streamUrl = channel.streamUrl, let url = URL(string: streamUrl) {
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
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text(group.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            // Events
            ForEach(group.channels) { channel in
                SportEventCard(channel: channel) {
                    onChannelTap(channel)
                }
            }
        }
    }
}

// MARK: - Sport Event Card

struct SportEventCard: View {
    let channel: Channel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Channel logo
                AsyncImage(url: URL(string: channel.logo ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "sportscourt")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Event info
                VStack(alignment: .leading, spacing: 4) {
                    // Event name
                    Text(channel.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Status row
                    HStack(spacing: 8) {
                        // LIVE badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red)
                        }
                        
                        // Channel number if available
                        if !channel.displayNumber.isEmpty {
                            Text("CH \(channel.displayNumber)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Play button
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.red)
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SportsView()
}
