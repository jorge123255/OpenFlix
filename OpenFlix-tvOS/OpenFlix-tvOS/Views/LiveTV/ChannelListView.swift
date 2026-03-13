import SwiftUI

// MARK: - Channel List View (tvOS)
// Full-screen channel browser with category filter + search

struct ChannelListView: View {
    @ObservedObject var viewModel: LiveTVViewModel
    let onChannelSelect: (Channel) -> Void

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private let bg = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)

    private var displayedChannels: [Channel] {
        var result = viewModel.channels

        if let group = viewModel.selectedGroup {
            result = result.filter { $0.group == group }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.number.map { "\($0)" } ?? "").contains(searchText)
            }
        }

        return result
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            HStack(spacing: 0) {
                // Sidebar: search + category filters
                sidebar
                    .frame(width: 420)

                Divider().background(Color.white.opacity(0.1))

                // Main: channel list
                channelList
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 24) {
            // Title
            Text("Channels")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
                .padding(.horizontal, 40)

            // Search
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("Search...", text: $searchText)
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(cardBg)
            .cornerRadius(12)
            .padding(.horizontal, 40)

            // Channel count
            Text("\(displayedChannels.count) channels")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)

            // Category filters
            ScrollView {
                VStack(spacing: 4) {
                    TVFilterRow(title: "All Channels", isSelected: viewModel.selectedGroup == nil) {
                        viewModel.selectedGroup = nil
                    }

                    ForEach(viewModel.availableGroups, id: \.self) { group in
                        TVFilterRow(title: group, isSelected: viewModel.selectedGroup == group) {
                            viewModel.selectedGroup = group
                        }
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    // MARK: - Channel List

    private var channelList: some View {
        Group {
            if displayedChannels.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("No channels found")
                        .font(.system(size: 28))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(displayedChannels) { channel in
                            TVChannelListRow(
                                channel: channel,
                                nowPlaying: nowPlaying(for: channel),
                                accentColor: accentColor
                            ) {
                                onChannelSelect(channel)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                }
            }
        }
    }

    private func nowPlaying(for channel: Channel) -> Program? {
        viewModel.guide.first(where: { $0.channel.id == channel.id })?.programs.first(where: { p in
            let now = Date()
            return p.startTime <= now && p.endTime > now
        })
    }
}

// MARK: - TV Channel List Row

struct TVChannelListRow: View {
    let channel: Channel
    let nowPlaying: Program?
    let accentColor: Color
    let onTap: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Channel number
                if let number = channel.number {
                    Text("\(number)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                        .frame(width: 54, alignment: .trailing)
                }

                // Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08))
                    if let logo = channel.logo, !logo.isEmpty {
                        AuthenticatedImage(path: logo, systemPlaceholder: "tv")
                            .aspectRatio(contentMode: .fit)
                            .padding(6)
                    } else {
                        Text(channel.name.prefix(3).uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 52, height: 40)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let program = nowPlaying {
                        HStack(spacing: 8) {
                            Text(program.title)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .lineLimit(1)

                            GeometryReader { geo in
                                let progress = programProgress(program)
                                ZStack(alignment: .leading) {
                                    Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 3)
                                    Rectangle().fill(accentColor).frame(width: geo.size.width * progress, height: 3)
                                }
                                .cornerRadius(1.5)
                            }
                            .frame(width: 80, height: 3)
                        }
                    } else {
                        Text("No program info")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }

                Spacer()

                if channel.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                }

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(isFocused ? accentColor : .secondary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(isFocused ? Color.white.opacity(0.12) : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }

    private func programProgress(_ program: Program) -> Double {
        let now = Date()
        let total = program.endTime.timeIntervalSince(program.startTime)
        let elapsed = now.timeIntervalSince(program.startTime)
        return max(0, min(1, elapsed / total))
    }
}

// MARK: - TV Filter Row

struct TVFilterRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .secondary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 97/255, green: 56/255, blue: 245/255))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.white.opacity(0.12) : (isFocused ? Color.white.opacity(0.06) : Color.clear))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}
