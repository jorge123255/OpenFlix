import SwiftUI

// MARK: - What's On Now

struct WhatsOnNowView: View {
    @StateObject private var viewModel = LiveTVViewModel()
    @State private var selectedChannel: Channel?
    @State private var filterText = ""
    @State private var selectedFilter: NowFilter = .all

    enum NowFilter: String, CaseIterable {
        case all = "All"
        case sports = "Sports"
        case movies = "Movies"
        case news = "News"
        case kids = "Kids"

        var icon: String {
            switch self {
            case .all:    return "tv.fill"
            case .sports: return "sportscourt.fill"
            case .movies: return "film.fill"
            case .news:   return "newspaper.fill"
            case .kids:   return "figure.child"
            }
        }
    }

    private var displayChannels: [Channel] {
        let withPrograms = viewModel.channels.filter { $0.nowPlaying != nil }
        let filtered: [Channel]
        switch selectedFilter {
        case .all:
            filtered = withPrograms
        case .sports:
            filtered = withPrograms.filter {
                ($0.nowPlaying?.isSports ?? false) ||
                $0.name.lowercased().contains("espn") ||
                $0.name.lowercased().contains("sport")
            }
        case .movies:
            filtered = withPrograms.filter {
                ($0.nowPlaying?.category?.lowercased().contains("movie") ?? false) ||
                $0.name.lowercased().contains("movie") ||
                $0.name.lowercased().contains("hbo") ||
                $0.name.lowercased().contains("starz") ||
                $0.name.lowercased().contains("showtime")
            }
        case .news:
            filtered = withPrograms.filter {
                ($0.nowPlaying?.category?.lowercased().contains("news") ?? false) ||
                $0.name.lowercased().contains("news") ||
                $0.name.lowercased().contains("cnn") ||
                $0.name.lowercased().contains("msnbc") ||
                $0.name.lowercased().contains("fox news")
            }
        case .kids:
            filtered = withPrograms.filter {
                ($0.nowPlaying?.isKids ?? false) ||
                $0.name.lowercased().contains("disney") ||
                $0.name.lowercased().contains("cartoon") ||
                $0.name.lowercased().contains("nick")
            }
        }

        guard !filterText.isEmpty else { return filtered }
        let q = filterText.lowercased()
        return filtered.filter {
            $0.name.lowercased().contains(q) ||
            ($0.nowPlaying?.title.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if displayChannels.isEmpty {
                Spacer()
                ContentUnavailableView(
                    filterText.isEmpty ? "Nothing on \(selectedFilter.rawValue)" : "No results for \"\(filterText)\"",
                    systemImage: "tv.slash",
                    description: Text(filterText.isEmpty ? "No channels are currently airing." : "Try a different search.")
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(displayChannels) { channel in
                            Button {
                                selectedChannel = channel
                            } label: {
                                OnNowRow(channel: channel)
                            }
                            .buttonStyle(.plain)

                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .searchable(text: $filterText, prompt: "Search channels & programs")
        .navigationTitle("On Now")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.loadChannels() }
        .refreshable { await viewModel.loadChannels() }
        .fullScreenCover(item: $selectedChannel) { channel in
            LiveChannelPlayerView(
                channel: channel,
                viewModel: viewModel,
                channels: viewModel.channels
            ) {
                selectedChannel = nil
            }
        }
    }

    // MARK: Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NowFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Label(filter.rawValue, systemImage: filter.icon)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(selectedFilter == filter ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundStyle(selectedFilter == filter ? .white : .secondary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - On Now Row

private struct OnNowRow: View {
    let channel: Channel

    var body: some View {
        HStack(spacing: 12) {
            // Channel logo
            channelLogo

            // Program info
            VStack(alignment: .leading, spacing: 4) {
                if let program = channel.nowPlaying {
                    // Program title
                    Text(program.title)
                        .font(.headline)
                        .lineLimit(1)

                    // Episode subtitle if available
                    if let sub = program.subtitle, !sub.isEmpty {
                        Text(sub)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Time range
                    HStack(spacing: 6) {
                        Text(program.timeRangeFormatted)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        // Badges
                        if program.isNew {
                            NowBadge("NEW", color: .blue)
                        }
                        if program.isLive {
                            NowBadge("LIVE", color: .red)
                        }
                        if program.isSports {
                            NowBadge("SPORT", color: .green)
                        }
                        if program.isPremiere {
                            NowBadge("PREMIERE", color: .purple)
                        }
                        if program.hasRecording {
                            NowBadge("REC", color: .red)
                        }
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemFill))
                                .frame(height: 3)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.accentColor)
                                .frame(width: geo.size.width * program.progress, height: 3)
                        }
                    }
                    .frame(height: 3)
                    .padding(.top, 2)

                    // Remaining time
                    Text("\(program.remainingMinutes) min left")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(channel.name)
                        .font(.headline)
                    Text("No program info")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var channelLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 56, height: 40)

            if let logo = channel.logo, let url = URL(string: logo) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                            .frame(width: 44, height: 30)
                    default:
                        channelNumberFallback
                    }
                }
            } else {
                channelNumberFallback
            }
        }
        .frame(width: 56, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var channelNumberFallback: some View {
        Text(channel.number.map { "\($0)" } ?? channel.name.prefix(3).uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Badge

private struct NowBadge: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 4).padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
