import SwiftUI

struct ProgramCell: View {
    let program: Program
    var width: CGFloat = 200
    var onSelect: (() -> Void)?
    var onRecord: (() -> Void)?

    var body: some View {
        Button(action: { onSelect?() }) {
            VStack(alignment: .leading, spacing: 6) {
                // Time
                Text(program.timeRangeFormatted)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Title
                Text(program.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                // Subtitle
                if let subtitle = program.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Badges
                if !program.badges.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(program.badges, id: \.self) { badge in
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badgeColor(for: badge))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }

                // Progress (if currently airing)
                if program.isCurrentlyAiring {
                    ProgressBar(progress: program.progress)
                        .frame(height: 3)
                }

                Spacer()

                // Duration
                Text("\(program.duration) min")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(width: width, alignment: .leading)
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(.card)
        .contextMenu {
            if !program.hasRecording {
                Button(action: { onRecord?() }) {
                    Label("Record", systemImage: "record.circle")
                }
            }
        }
    }

    private var backgroundColor: Color {
        if program.isCurrentlyAiring {
            return Color.blue.opacity(0.3)
        } else if program.hasEnded {
            return Color.gray.opacity(0.2)
        }
        return Color.gray.opacity(0.1)
    }

    private func badgeColor(for badge: String) -> Color {
        switch badge {
        case "LIVE": return .red
        case "NEW": return .green
        case "PREMIERE": return .purple
        case "FINALE": return .orange
        case "REC": return .red
        default: return .gray
        }
    }
}

struct ProgramDetailView: View {
    let program: Program
    var channelName: String?
    var onRecord: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(program.fullTitle)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let channelName = channelName {
                        Text(channelName)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let rating = program.rating {
                    Text(rating)
                        .font(.caption)
                        .padding(6)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(4)
                }
            }

            // Time
            HStack {
                Image(systemName: "clock")
                Text(program.timeRangeFormatted)
                Text("(\(program.duration) min)")
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)

            // Badges
            if !program.badges.isEmpty {
                HStack(spacing: 8) {
                    ForEach(program.badges, id: \.self) { badge in
                        Text(badge)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
            }

            // Description
            if let description = program.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            // Sports info
            if program.isSports {
                if let teams = program.teams {
                    HStack {
                        Image(systemName: "sportscourt")
                        Text(teams)
                    }
                    .font(.subheadline)
                }

                if let league = program.league {
                    Text(league)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 16) {
                if !program.hasRecording && !program.hasEnded {
                    Button(action: { onRecord?() }) {
                        Label("Record", systemImage: "record.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Close", action: { onDismiss?() })
                    .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(maxWidth: 600)
    }
}

#Preview {
    ProgramCell(
        program: Program(
            id: "1",
            title: "The Office",
            subtitle: "Dinner Party",
            description: "Michael and Jan host a dinner party.",
            startTime: Date().addingTimeInterval(-1800),
            endTime: Date().addingTimeInterval(1800),
            duration: 60,
            icon: nil,
            art: nil,
            rating: "TV-14",
            category: "Comedy",
            isNew: true,
            isLive: false,
            isPremiere: false,
            isFinale: false,
            isSports: false,
            isKids: false,
            teams: nil,
            league: nil,
            hasRecording: false,
            recordingId: nil
        )
    )
}
