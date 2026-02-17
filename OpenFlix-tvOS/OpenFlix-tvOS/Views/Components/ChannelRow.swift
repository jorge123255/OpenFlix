import SwiftUI

struct ChannelRow: View {
    let channel: Channel
    var isPlaying: Bool = false
    var onSelect: (() -> Void)?

    var body: some View {
        Button(action: { onSelect?() }) {
            HStack(spacing: 16) {
                // Channel Logo
                AsyncImage(url: logoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure, .empty:
                        Image(systemName: "tv")
                            .font(.title2)
                            .foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "tv")
                    }
                }
                .frame(width: 80, height: 50)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)

                // Channel Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let number = channel.number {
                            Text("\(number)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }

                        Text(channel.name)
                            .font(.headline)
                            .lineLimit(1)

                        if channel.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }

                        if channel.isHD {
                            Text("HD")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                    }

                    // Now Playing
                    if let program = channel.nowPlaying {
                        Text(program.title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        // Progress
                        ProgressBar(progress: program.progress)
                            .frame(height: 3)
                            .frame(maxWidth: 200)
                    }
                }

                Spacer()

                // Playing indicator
                if isPlaying {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }

                // Next Program
                if let nextProgram = channel.nextProgram {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Up Next")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(nextProgram.title)
                            .font(.caption)
                            .lineLimit(1)
                        Text(nextProgram.startTimeFormatted)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 150)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isPlaying ? Color.red.opacity(0.2) : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(.card)
    }

    private var logoURL: URL? {
        guard let logo = channel.logo,
              let serverURL = UserDefaults.standard.serverURL else { return nil }
        if logo.hasPrefix("http") {
            return URL(string: logo)
        }
        return serverURL.appendingPathComponent(logo)
    }
}

#Preview {
    ChannelRow(
        channel: Channel(
            id: "1",
            number: 5,
            name: "NBC HD",
            logo: nil,
            sourceId: nil,
            sourceName: nil,
            streamUrl: nil,
            enabled: true,
            isFavorite: true,
            group: nil,
            archiveEnabled: false,
            archiveDays: 0,
            nowPlaying: Program(
                id: "1",
                title: "The Office",
                subtitle: "Dinner Party",
                description: nil,
                startTime: Date().addingTimeInterval(-1800),
                endTime: Date().addingTimeInterval(1800),
                duration: 60,
                icon: nil,
                art: nil,
                rating: nil,
                category: nil,
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
            ),
            nextProgram: nil
        )
    )
}
