import SwiftUI

// MARK: - EPG Program Cell
// Grid cell for program display in EPG

struct EPGProgramCell: View {
    let program: Program
    let channel: Channel
    let width: CGFloat
    let height: CGFloat
    let onSelect: () -> Void

    @FocusState private var isFocused: Bool

    private var isCurrentlyAiring: Bool {
        program.isCurrentlyAiring
    }

    private var categoryColor: Color {
        if program.isSports { return EPGTheme.sports }
        if program.category?.lowercased().contains("movie") == true { return EPGTheme.movie }
        if program.category?.lowercased().contains("news") == true { return EPGTheme.news }
        if program.isKids { return EPGTheme.kids }
        return EPGTheme.categoryColor(for: program.category)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(program.title)
                    .font(.system(size: 20, weight: isCurrentlyAiring ? .semibold : .regular))
                    .foregroundColor(EPGTheme.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: 2)

                // Badges and time
                HStack(spacing: 6) {
                    Text(program.startTimeFormatted)
                        .font(.system(size: 16))
                        .foregroundColor(EPGTheme.textMuted)

                    // Badges
                    badgesView
                }

                // Progress bar for currently airing
                if isCurrentlyAiring {
                    EPGProgressBar(
                        progress: program.progress,
                        height: 3,
                        foregroundColor: categoryColor
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: width, height: height, alignment: .topLeading)
            .background(cellBackground)
            .overlay(cellOverlay)
            .overlay(categoryStripe, alignment: .leading)
            .epgFocusStyle(isFocused: isFocused, borderColor: categoryColor)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }

    // MARK: - Subviews

    private var badgesView: some View {
        HStack(spacing: 4) {
            if program.isNew {
                EPGBadge(text: "NEW", color: EPGTheme.newBadge, textColor: .black)
            }

            if program.isLive {
                LiveIndicator()
            }

            if program.hasRecording {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(EPGTheme.recording)
            }

            if program.isPremiere {
                EPGBadge(text: "PREMIERE", color: EPGTheme.accent, textColor: .black)
            }

            if program.isFinale {
                EPGBadge(text: "FINALE", color: EPGTheme.warning, textColor: .black)
            }
        }
    }

    private var cellBackground: some View {
        RoundedRectangle(cornerRadius: EPGTheme.Dimensions.cornerRadius)
            .fill(isFocused ? EPGTheme.programCellSelected : (isCurrentlyAiring ? EPGTheme.programCellLive : EPGTheme.programCell))
    }

    private var cellOverlay: some View {
        RoundedRectangle(cornerRadius: EPGTheme.Dimensions.cornerRadius)
            .stroke(
                isFocused ? categoryColor : EPGTheme.background.opacity(0.5),
                lineWidth: isFocused ? 3 : 1
            )
    }

    private var categoryStripe: some View {
        RoundedRectangle(cornerRadius: EPGTheme.Dimensions.cornerRadius)
            .fill(categoryColor)
            .frame(width: 4)
            .padding(.vertical, 4)
    }
}

// MARK: - Program Detail Card (for focused state / info popup)

struct ProgramDetailCard: View {
    let program: Program
    let channel: Channel
    var onPlay: (() -> Void)?
    var onRecord: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    if let subtitle = program.subtitle {
                        Text(subtitle)
                            .font(.system(size: 20))
                            .foregroundColor(EPGTheme.textSecondary)
                    }

                    HStack(spacing: 8) {
                        Text(channel.name)
                            .foregroundColor(EPGTheme.accent)

                        Text("•")
                            .foregroundColor(EPGTheme.textMuted)

                        Text(program.timeRangeFormatted)
                            .foregroundColor(EPGTheme.textSecondary)

                        if let rating = program.rating {
                            Text("•")
                                .foregroundColor(EPGTheme.textMuted)
                            Text(rating)
                                .foregroundColor(EPGTheme.textSecondary)
                        }
                    }
                    .font(.system(size: 18))
                }

                Spacer()

                // Badges
                VStack(alignment: .trailing, spacing: 6) {
                    ForEach(program.badges, id: \.self) { badge in
                        EPGBadge(
                            text: badge,
                            color: badgeColor(for: badge)
                        )
                    }
                }
            }

            // Description
            if let description = program.description {
                Text(description)
                    .font(.system(size: 18))
                    .foregroundColor(EPGTheme.textSecondary)
                    .lineLimit(3)
            }

            // Progress (if airing)
            if program.isCurrentlyAiring {
                VStack(alignment: .leading, spacing: 6) {
                    EPGProgressBar(progress: program.progress, height: 6)

                    HStack {
                        Text("\(Int(program.progress * 100))% complete")
                        Spacer()
                        Text("\(program.remainingMinutes) min remaining")
                    }
                    .font(.system(size: 16))
                    .foregroundColor(EPGTheme.textMuted)
                }
            }

            // Actions
            HStack(spacing: 16) {
                if let onPlay = onPlay {
                    Button(action: onPlay) {
                        Label(program.isCurrentlyAiring ? "Watch" : "Preview", systemImage: "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(EPGTheme.accent)
                }

                if let onRecord = onRecord, !program.hasRecording && !program.hasEnded {
                    Button(action: onRecord) {
                        Label("Record", systemImage: "record.circle")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EPGTheme.surfaceElevated)
        )
    }

    private func badgeColor(for badge: String) -> Color {
        switch badge {
        case "NEW": return EPGTheme.newBadge
        case "LIVE": return EPGTheme.liveBadge
        case "REC": return EPGTheme.recBadge
        case "PREMIERE": return EPGTheme.accent
        case "FINALE": return EPGTheme.warning
        default: return EPGTheme.accent
        }
    }
}

// MARK: - Minimal Program Cell (for player mini EPG)

struct MiniProgramCell: View {
    let program: Program
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(program.title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                if program.isLive {
                    Circle()
                        .fill(EPGTheme.live)
                        .frame(width: 8, height: 8)
                }
            }

            Text(program.timeRangeFormatted)
                .font(.system(size: 14))
                .foregroundColor(EPGTheme.textMuted)

            if program.isCurrentlyAiring {
                EPGProgressBar(progress: program.progress, height: 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? EPGTheme.accent.opacity(0.3) : .clear)
        )
    }
}

#Preview {
    let sampleProgram = Program(
        id: "p1",
        title: "NFL Football: Chiefs vs Bills - AFC Championship",
        subtitle: "AFC Championship Game",
        description: "The Kansas City Chiefs face the Buffalo Bills in the AFC Championship at Arrowhead Stadium. Winner advances to Super Bowl LIX.",
        startTime: Date().addingTimeInterval(-1800),
        endTime: Date().addingTimeInterval(5400),
        duration: 120,
        icon: nil,
        art: nil,
        rating: "TV-G",
        category: "Sports",
        isNew: false,
        isLive: true,
        isPremiere: false,
        isFinale: false,
        isSports: true,
        isKids: false,
        teams: "Chiefs, Bills",
        league: "NFL",
        hasRecording: true,
        recordingId: nil
    )

    let sampleChannel = Channel(
        id: "1",
        number: 206,
        name: "ESPN",
        logo: nil,
        sourceId: nil,
        sourceName: nil,
        streamUrl: nil,
        enabled: true,
        isFavorite: true,
        group: "Sports",
        archiveEnabled: false,
        archiveDays: 0,
        nowPlaying: nil,
        nextProgram: nil
    )

    return ScrollView {
        VStack(spacing: 20) {
            EPGProgramCell(
                program: sampleProgram,
                channel: sampleChannel,
                width: 400,
                height: 100,
                onSelect: {}
            )

            ProgramDetailCard(
                program: sampleProgram,
                channel: sampleChannel,
                onPlay: {},
                onRecord: {}
            )
            .frame(maxWidth: 600)

            MiniProgramCell(program: sampleProgram, isSelected: true)
                .frame(width: 300)
        }
        .padding()
    }
    .background(EPGTheme.background)
}
