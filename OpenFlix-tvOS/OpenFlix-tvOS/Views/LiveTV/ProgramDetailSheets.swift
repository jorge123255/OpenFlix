import SwiftUI

// MARK: - Program Detail Sheet (tvOS)
// Full-screen overlay (tvOS can't present sheets over video)

struct TVProgramDetailView: View {
    let program: Program
    let channel: Channel
    let onPlay: () -> Void
    let onRecord: () -> Void
    let onCreatePass: (SeriesPassOptions) -> Void
    let onDismiss: () -> Void

    @State private var showSeriesPass = false
    @State private var showRecordConfirm = false

    private let darkBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    private let accentPurple = Color(red: 97/255, green: 56/255, blue: 245/255)

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            darkBg.opacity(0.9).ignoresSafeArea()

            HStack(spacing: 80) {
                // Left: artwork + info
                leftPanel

                // Right: description + actions
                rightPanel
            }
            .padding(80)
        }
        .fullScreenCover(isPresented: $showSeriesPass) {
            TVSeriesPassView(
                program: program,
                channel: channel,
                onCreate: { options in
                    showSeriesPass = false
                    onCreatePass(options)
                },
                onDismiss: { showSeriesPass = false }
            )
        }
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Artwork
            ZStack {
                if let art = program.art {
                    AuthenticatedImage(path: art, systemPlaceholder: program.isSports ? "sportscourt" : "tv")
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: [EPGTheme.categoryColor(for: program.category), .black.opacity(0.8)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: program.isSports ? "sportscourt" : "tv")
                            .font(.system(size: 56))
                            .foregroundColor(.white.opacity(0.3))
                    )
                }
            }
            .frame(width: 480, height: 270)
            .clipped()
            .cornerRadius(16)

            // Title
            Text(program.title)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)

            if let subtitle = program.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }

            // Meta row
            HStack(spacing: 16) {
                Text("\(program.duration) min")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Text(program.startTimeFormatted)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                Text(channel.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accentPurple)
            }

            // Badges
            HStack(spacing: 8) {
                ForEach(program.badges, id: \.self) { badge in
                    Text(badge)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(accentPurple.opacity(0.7))
                        .cornerRadius(6)
                }
                if let rating = program.rating, !rating.isEmpty {
                    Text(rating)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Progress
            if program.isCurrentlyAiring {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: program.progress).tint(accentPurple)
                    HStack {
                        Text("\(Int(program.progress * 100))% complete")
                        Spacer()
                        Text("\(program.remainingMinutes) min remaining")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .frame(maxWidth: 520)
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Description
            if let desc = program.description, !desc.isEmpty {
                ScrollView {
                    Text(desc)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxHeight: 300)
            }

            // Sports metadata
            if program.isSports {
                if let teams = program.teams {
                    detailRow("Teams", value: teams)
                }
                if let league = program.league {
                    detailRow("League", value: league)
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 16) {
                // Watch
                Button(action: onPlay) {
                    Label("Watch Now", systemImage: "play.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(accentPurple)
                        .cornerRadius(14)
                }
                .buttonStyle(.card)

                HStack(spacing: 16) {
                    if !program.hasEnded {
                        Button { showRecordConfirm = true } label: {
                            Label("Record", systemImage: "record.circle")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(14)
                        }
                        .buttonStyle(.card)
                        .alert("Record", isPresented: $showRecordConfirm) {
                            Button("Record") { onRecord() }
                            Button("Cancel", role: .cancel) {}
                        }
                    }

                    Button { showSeriesPass = true } label: {
                        Label("Series Pass", systemImage: "calendar.badge.plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(14)
                    }
                    .buttonStyle(.card)
                }

                Button(action: onDismiss) {
                    Text("Close")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.card)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.gray).frame(width: 80, alignment: .leading)
            Text(value).foregroundColor(.white.opacity(0.9))
        }
        .font(.system(size: 16))
    }
}

// MARK: - Series Pass Options (shared model)

struct SeriesPassOptions {
    var recordMode: RecordMode = .newEpisodes
    var keepMode: KeepMode = .allRecordings
    var startRecording: PaddingOption = .onTime
    var endRecording: PaddingOption = .onTime
    var channelMode: ChannelMode = .anyChannel

    enum RecordMode: String, CaseIterable {
        case newEpisodes = "New Episodes"
        case allEpisodes = "All Episodes"
    }

    enum KeepMode: String, CaseIterable {
        case allRecordings = "All recordings"
        case keep1 = "1 day"
        case keep2 = "2 days"
        case keep3 = "3 days"
        case keep5 = "5 days"
        case keep7 = "7 days"
        case keep10 = "10 days"
        case afterWatch = "After I watch, delete"

        var keepCount: Int {
            switch self {
            case .allRecordings: return 0
            case .keep1: return 1; case .keep2: return 2; case .keep3: return 3
            case .keep5: return 5; case .keep7: return 7; case .keep10: return 10
            case .afterWatch: return -1
            }
        }
    }

    enum PaddingOption: String, CaseIterable {
        case onTime = "On Time"
        case early1 = "1 min early"; case early5 = "5 min early"; case early15 = "15 min early"
        case late5 = "5 min late"; case late15 = "15 min late"; case late30 = "30 min late"; case late60 = "1 hr late"

        var seconds: Int {
            switch self {
            case .onTime: return 0
            case .early1: return 60; case .early5: return 300; case .early15: return 900
            case .late5: return 300; case .late15: return 900; case .late30: return 1800; case .late60: return 3600
            }
        }
        static var startOptions: [PaddingOption] { [.onTime, .early1, .early5, .early15] }
        static var endOptions: [PaddingOption] { [.onTime, .late5, .late15, .late30, .late60] }
    }

    enum ChannelMode: String, CaseIterable {
        case anyChannel = "Any Channel"
        case thisChannel = "This Channel"
    }
}

// MARK: - Series Pass View (tvOS)

struct TVSeriesPassView: View {
    let program: Program
    let channel: Channel
    let onCreate: (SeriesPassOptions) -> Void
    let onDismiss: () -> Void

    @State private var options = SeriesPassOptions()

    private let bg = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    private let accentPurple = Color(red: 97/255, green: 56/255, blue: 245/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            HStack(spacing: 80) {
                // Left: program info
                VStack(alignment: .leading, spacing: 24) {
                    ZStack {
                        Circle().fill(accentPurple.opacity(0.2)).frame(width: 100, height: 100)
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 48)).foregroundColor(accentPurple)
                    }

                    Text("Series Pass")
                        .font(.system(size: 48, weight: .bold)).foregroundColor(.white)

                    Text(program.title)
                        .font(.system(size: 28)).foregroundColor(accentPurple)

                    Text("Automatically record every new episode of this series.")
                        .font(.system(size: 18)).foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    Button("Cancel", action: onDismiss)
                        .buttonStyle(TVSecondaryButtonStyle())
                }
                .frame(maxWidth: 480)

                // Right: options
                VStack(spacing: 24) {
                    Text("Recording Options")
                        .font(.system(size: 32, weight: .bold)).foregroundColor(.white)

                    VStack(spacing: 12) {
                        optionRow("Record") {
                            Picker("Record", selection: $options.recordMode) {
                                ForEach(SeriesPassOptions.RecordMode.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.menu).tint(accentPurple)
                        }

                        optionRow("Keep") {
                            Picker("Keep", selection: $options.keepMode) {
                                ForEach(SeriesPassOptions.KeepMode.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.menu).tint(accentPurple)
                        }

                        optionRow("Start Recording") {
                            Picker("Start", selection: $options.startRecording) {
                                ForEach(SeriesPassOptions.PaddingOption.startOptions, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.menu).tint(accentPurple)
                        }

                        optionRow("End Recording") {
                            Picker("End", selection: $options.endRecording) {
                                ForEach(SeriesPassOptions.PaddingOption.endOptions, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.menu).tint(accentPurple)
                        }

                        optionRow("Channel") {
                            Picker("Channel", selection: $options.channelMode) {
                                Text("Any Channel").tag(SeriesPassOptions.ChannelMode.anyChannel)
                                Text(channel.name).tag(SeriesPassOptions.ChannelMode.thisChannel)
                            }
                            .pickerStyle(.menu).tint(accentPurple)
                        }
                    }
                    .cornerRadius(12)

                    Spacer()

                    Button { onCreate(options) } label: {
                        Label("Create Pass", systemImage: "calendar.badge.plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(accentPurple)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.card)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(80)
        }
    }

    @ViewBuilder
    private func optionRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(cardBg)
        .cornerRadius(10)
    }
}
