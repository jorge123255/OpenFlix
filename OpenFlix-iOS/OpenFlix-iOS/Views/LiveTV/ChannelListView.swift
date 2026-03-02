import SwiftUI

// MARK: - Portrait Channel List View
// Simple vertical list optimized for portrait mode on iPhone

struct ChannelListView: View {
    @ObservedObject var viewModel: LiveTVViewModel
    let onChannelSelect: (Channel) -> Void
    
    @State private var searchText = ""
    
    var displayedChannels: [Channel] {
        var result = viewModel.channels
        
        // Filter by group
        if let group = viewModel.selectedGroup {
            result = result.filter { $0.group == group }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                "\($0.number)".contains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search channels...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ChannelFilterPill(title: "All", isSelected: viewModel.selectedGroup == nil) {
                        viewModel.selectedGroup = nil
                    }
                    ForEach(viewModel.availableGroups, id: \.self) { group in
                        ChannelFilterPill(title: group, isSelected: viewModel.selectedGroup == group) {
                            viewModel.selectedGroup = group
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            
            // Channel count
            HStack {
                Text("\(displayedChannels.count) channels")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
            
            // Channel list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(displayedChannels) { channel in
                        ChannelListRow(
                            channel: channel,
                            nowPlaying: getNowPlaying(for: channel),
                            onTap: { onChannelSelect(channel) }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func getNowPlaying(for channel: Channel) -> Program? {
        // Try to find from guide data
        viewModel.guide.first(where: { $0.channel.id == channel.id })?.programs.first(where: { program in
            let now = Date()
            return program.startTime <= now && program.endTime > now
        })
    }
}

// MARK: - Channel List Row

struct ChannelListRow: View {
    let channel: Channel
    let nowPlaying: Program?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Channel number
                Text("\(channel.number)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .frame(width: 44, alignment: .trailing)
                
                // Channel logo or icon
                if let logo = channel.logo, let url = URL(string: logo) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "tv")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
                } else {
                    Image(systemName: "tv.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                }
                
                // Channel info
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let program = nowPlaying {
                        Text(program.title)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        // Progress bar
                        GeometryReader { geo in
                            let progress = programProgress(program)
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 3)
                                Rectangle()
                                    .fill(Color.cyan)
                                    .frame(width: geo.size.width * progress, height: 3)
                            }
                            .cornerRadius(1.5)
                        }
                        .frame(height: 3)
                    } else {
                        Text("No program info")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Favorite indicator
                if channel.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 12))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func programProgress(_ program: Program) -> Double {
        let now = Date()
        let total = program.endTime.timeIntervalSince(program.startTime)
        let elapsed = now.timeIntervalSince(program.startTime)
        return max(0, min(1, elapsed / total))
    }
}

// MARK: - Channel Filter Pill

struct ChannelFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.cyan : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChannelListView(
        viewModel: LiveTVViewModel(),
        onChannelSelect: { _ in }
    )
}
