import SwiftUI

// MARK: - EPG Channel Cell
// Left column channel display in EPG grid

struct EPGChannelCell: View {
    let channel: Channel
    let height: CGFloat
    let onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Channel number
                channelNumber

                // Channel logo
                channelLogo

                // Channel info
                channelInfo

                Spacer(minLength: 0)

                // Right indicators
                rightIndicators
            }
            .padding(.horizontal, 16)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isFocused ? EPGTheme.programCellSelected : EPGTheme.surface)
            )
            .overlay(
                // Focus accent stripe on left
                Rectangle()
                    .fill(isFocused ? EPGTheme.accent : .clear)
                    .frame(width: 4),
                alignment: .leading
            )
            .epgFocusStyle(isFocused: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }

    // MARK: - Subviews

    private var channelNumber: some View {
        Group {
            if let number = channel.number {
                Text("\(number)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(EPGTheme.accent)
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }

    private var channelLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))

            AuthenticatedImage(
                path: channel.logo,
                systemPlaceholder: "tv"
            )
            .aspectRatio(contentMode: .fit)
            .padding(4)
        }
        .frame(width: EPGTheme.Dimensions.logoSize, height: EPGTheme.Dimensions.logoSize * 0.75)
    }

    private var channelInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(channel.name)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(EPGTheme.textPrimary)
                .lineLimit(1)

            // Current program title (if available)
            if let nowPlaying = channel.nowPlaying {
                Text(nowPlaying.title)
                    .font(.system(size: 16))
                    .foregroundColor(EPGTheme.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var rightIndicators: some View {
        HStack(spacing: 8) {
            // HD Badge
            if channel.isHD {
                Text("HD")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(EPGTheme.hdBadge)
                    .cornerRadius(4)
            }

            // Favorite indicator
            if channel.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)
            }

            // Archive indicator
            if channel.archiveEnabled {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16))
                    .foregroundColor(EPGTheme.textMuted)
            }
        }
    }
}

// MARK: - Compact Channel Cell (for mini EPG)

struct CompactChannelCell: View {
    let channel: Channel
    let isSelected: Bool
    let onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Number
                if let number = channel.number {
                    Text("\(number)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(EPGTheme.accent)
                        .frame(width: 40)
                }

                // Logo
                AuthenticatedImage(path: channel.logo, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 30)

                // Name
                Text(channel.name)
                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                // Now playing
                if let program = channel.nowPlaying {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(program.title)
                            .font(.system(size: 16))
                            .foregroundColor(EPGTheme.textSecondary)
                            .lineLimit(1)

                        if program.isCurrentlyAiring {
                            EPGProgressBar(progress: program.progress)
                                .frame(width: 80)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? EPGTheme.accent.opacity(0.3) : (isFocused ? EPGTheme.surfaceElevated : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? EPGTheme.accent : (isFocused ? .white.opacity(0.5) : .clear), lineWidth: 2)
            )
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Channel List Cell (vertical list)

struct ChannelListCell: View {
    let channel: Channel
    let onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Number + Logo
                HStack(spacing: 12) {
                    if let number = channel.number {
                        Text("\(number)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(EPGTheme.accent)
                            .frame(width: 45, alignment: .trailing)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                        AuthenticatedImage(path: channel.logo, systemPlaceholder: "tv")
                            .aspectRatio(contentMode: .fit)
                            .padding(6)
                    }
                    .frame(width: 70, height: 50)
                }

                // Channel info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(channel.name)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)

                        if channel.isHD {
                            EPGBadge(text: "HD", color: EPGTheme.hdBadge)
                        }
                    }

                    if let program = channel.nowPlaying {
                        HStack(spacing: 8) {
                            Text(program.title)
                                .font(.system(size: 18))
                                .foregroundColor(EPGTheme.textSecondary)
                                .lineLimit(1)

                            if program.isLive {
                                LiveIndicator()
                            }
                        }

                        // Progress bar
                        if program.isCurrentlyAiring {
                            EPGProgressBar(progress: program.progress)
                                .frame(maxWidth: 200)
                        }
                    }
                }

                Spacer()

                // Indicators
                HStack(spacing: 12) {
                    if channel.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }

                    Image(systemName: "chevron.right")
                        .foregroundColor(EPGTheme.textMuted)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? EPGTheme.surfaceElevated : EPGTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? EPGTheme.accent : .clear, lineWidth: 3)
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

#Preview {
    let sampleChannel = Channel(
        id: "1",
        number: 101,
        name: "ESPN HD",
        logo: nil,
        sourceId: nil,
        sourceName: nil,
        streamUrl: nil,
        enabled: true,
        isFavorite: true,
        group: "Sports",
        archiveEnabled: true,
        archiveDays: 7,
        nowPlaying: Program(
            id: "p1",
            title: "NFL Football: Chiefs vs Bills",
            subtitle: nil,
            description: nil,
            startTime: Date().addingTimeInterval(-1800),
            endTime: Date().addingTimeInterval(3600),
            duration: 90,
            icon: nil,
            art: nil,
            rating: nil,
            category: "Sports",
            isNew: false,
            isLive: true,
            isPremiere: false,
            isFinale: false,
            isSports: true,
            isKids: false,
            teams: "Chiefs, Bills",
            league: "NFL",
            hasRecording: false,
            recordingId: nil
        ),
        nextProgram: nil
    )

    return VStack(spacing: 20) {
        EPGChannelCell(channel: sampleChannel, height: 80) {}

        CompactChannelCell(channel: sampleChannel, isSelected: true) {}

        ChannelListCell(channel: sampleChannel) {}
    }
    .padding()
    .background(EPGTheme.background)
}
