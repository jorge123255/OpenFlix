import SwiftUI

// Bundle all playback info into one Identifiable item
struct PlaybackItem: Identifiable {
    let id = UUID()
    let recording: Recording
    let url: URL
    let startPosition: Int?
}

struct DVRView: View {
    @StateObject private var viewModel = DVRViewModel()
    @State private var playbackItem: PlaybackItem?  // non-nil triggers fullScreenCover
    @State private var showManageSheet = false
    @State private var showRecordingActions = false
    @State private var tappedRecording: Recording?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.recordings.isEmpty {
                    LoadingView(message: "Loading recordings...")
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.loadRecordings() }
                    }
                } else if !viewModel.hasRecordings && !viewModel.hasScheduled && viewModel.currentlyRecording.isEmpty {
                    emptyLibraryView
                } else {
                    libraryContent
                }
            }
            .navigationTitle("My library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showManageSheet = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .task {
            await viewModel.loadRecordings()
            await viewModel.loadSeriesRules()
        }
        .onAppear {
            Task { await viewModel.loadRecordings() }
        }
        .fullScreenCover(item: $playbackItem) { item in
            VideoPlayerView(
                mediaItem: nil,
                recordingURL: item.url,
                startPosition: item.startPosition,
                commercials: item.recording.commercials,
                recordingDurationMs: item.recording.duration
            )
        }
        .sheet(isPresented: $showManageSheet) {
            ManageRecordingsSheet(viewModel: viewModel)
        }
        .confirmationDialog(
            tappedRecording?.title ?? "Recording",
            isPresented: $showRecordingActions,
            titleVisibility: .visible
        ) {
            if let recording = tappedRecording {
                Button("Watch from Start") {
                    playRecording(recording, startPosition: 0)
                }
                Button("Watch Live") {
                    // -1 sentinel means "seek to live edge"
                    playRecording(recording, startPosition: -1)
                }
                Button("Stop Recording", role: .destructive) {
                    Task { await viewModel.stopRecording(recording) }
                }
                Button("Cancel", role: .cancel) {}
            }
        } message: {
            if let recording = tappedRecording {
                Text("Recording \(recording.channelName ?? "")  \(recording.timeRangeFormatted)")
            }
        }
    }
    
    // MARK: - Library Content (Xfinity Style)
    
    private var libraryContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 32) {
                // Currently Recording
                if !viewModel.currentlyRecording.isEmpty {
                    DVRSectionRow(title: "Recording now", showBadge: true) {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.currentlyRecording) { recording in
                                LibraryCard(recording: recording, isRecording: true) {
                                    tappedRecording = recording
                                    showRecordingActions = true
                                }
                            }
                        }
                    }
                }
                
                // Recently Watched (In Progress)
                if !viewModel.inProgressRecordings.isEmpty {
                    DVRSectionRow(title: "Recently watched") {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.inProgressRecordings) { recording in
                                LibraryCard(recording: recording, showProgress: true) {
                                    playRecording(recording)
                                }
                            }
                        }
                    }
                }
                
                // Just Recorded (Recent completions)
                if !viewModel.justRecorded.isEmpty {
                    DVRSectionRow(title: "Just recorded") {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.justRecorded) { recording in
                                LibraryCard(recording: recording) {
                                    playRecording(recording)
                                }
                            }
                        }
                    }
                }
                
                // All Recordings by Channel
                if !viewModel.recordingsByChannel.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("All recordings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)

                        VStack(spacing: 2) {
                            ForEach(viewModel.recordingsByChannel, id: \.channelId) { group in
                                if group.recordings.count == 1, let recording = group.recordings.first {
                                    // Single recording — show inline card
                                    ChannelRecordingRow(recording: recording) {
                                        playRecording(recording)
                                    }
                                    .padding(.horizontal, 20)
                                } else {
                                    // Multiple recordings — expandable section
                                    ChannelRecordingsSection(
                                        channelName: group.channelName,
                                        channelLogo: group.channelLogo,
                                        recordings: group.recordings,
                                        onPlay: { recording in playRecording(recording) }
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
                
                // Upcoming Scheduled
                if !viewModel.upcomingRecordings.isEmpty {
                    DVRSectionRow(title: "Scheduled") {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.upcomingRecordings) { recording in
                                ScheduledCard(recording: recording) {
                                    Task { await viewModel.deleteRecording(recording) }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 24)
        }
        .background(Color.black)
        .refreshable {
            await viewModel.loadRecordings()
        }
    }
    
    private var emptyLibraryView: some View {
        EmptyStateView(
            icon: "play.rectangle.on.rectangle",
            title: "Your library is empty",
            message: "Recordings you make from the TV Guide will appear here."
        )
    }
    
    private func playRecording(_ recording: Recording, startPosition: Int? = nil) {
        Task {
            do {
                let url = try await viewModel.getRecordingStream(recording)
                let position: Int?
                if let sp = startPosition {
                    position = sp  // -1 = live edge, 0 = from start
                } else {
                    position = recording.viewOffset
                }
                // Setting playbackItem triggers the fullScreenCover
                playbackItem = PlaybackItem(recording: recording, url: url, startPosition: position)
            } catch {
                viewModel.error = error.localizedDescription
            }
        }
    }
}

// MARK: - DVR Section Row

struct DVRSectionRow<Content: View>: View {
    let title: String
    var showBadge: Bool = false
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if showBadge {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                content
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Library Card (Xfinity Style)

struct LibraryCard: View {
    let recording: Recording
    var showProgress: Bool = false
    var isRecording: Bool = false
    var onTap: () -> Void
    
    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 158  // 16:9 aspect
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Card with thumbnail
                ZStack(alignment: .bottomLeading) {
                    // Thumbnail
                    AsyncImage(url: thumbURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "play.rectangle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.3))
                                )
                        }
                    }
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                    
                    // Progress bar overlay
                    if showProgress {
                        VStack {
                            Spacer()
                            GeometryReader { geo in
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: geo.size.width * recording.progressPercent, height: 4)
                            }
                            .frame(height: 4)
                        }
                    }
                    
                    // Recording indicator
                    if isRecording {
                        HStack {
                            Spacer()
                            VStack {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    Text("REC")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                                .padding(8)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .cornerRadius(8)
                
                // Title
                Text(recording.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Episode info
                Text(episodeInfo)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(width: cardWidth)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isRecording {
                Button {
                    onTap()
                } label: {
                    Label("Watch Options", systemImage: "play.fill")
                }
            } else {
                Button {
                    onTap()
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
            }
        }
    }
    
    private var thumbURL: URL? {
        guard let thumb = recording.thumb ?? recording.art,
              let serverURL = UserDefaults.standard.serverURL else { return nil }
        return serverURL.appendingPathComponent(thumb)
    }
    
    private var episodeInfo: String {
        var parts: [String] = []
        
        if let season = recording.seasonNumber, let episode = recording.episodeNumber {
            parts.append("S\(season) Ep\(episode)")
        }
        
        if let subtitle = recording.subtitle {
            parts.append(subtitle)
        } else {
            // Fallback to airdate
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            parts.append("Airdate: \(formatter.string(from: recording.startTime))")
        }
        
        return parts.joined(separator: " - ")
    }
}

// MARK: - Channel Recordings Section (Expandable)

struct ChannelRecordingsSection: View {
    let channelName: String
    let channelLogo: String?
    let recordings: [Recording]
    let onPlay: (Recording) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Channel header
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Channel logo
                    AuthenticatedImage(path: channelLogo, systemPlaceholder: "tv")
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(channelName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(recordings.count) recording\(recordings.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Expanded recordings list
            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(recordings) { recording in
                        ChannelRecordingRow(recording: recording) {
                            onPlay(recording)
                        }
                        .padding(.leading, 52) // indent past the logo
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Channel Recording Row

struct ChannelRecordingRow: View {
    let recording: Recording
    let onTap: () -> Void

    private let thumbWidth: CGFloat = 120
    private let thumbHeight: CGFloat = 68

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack(alignment: .bottom) {
                    AuthenticatedImage(
                        path: recording.thumb ?? recording.art,
                        systemPlaceholder: "play.rectangle.fill"
                    )
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbWidth, height: thumbHeight)
                    .clipped()
                    .cornerRadius(6)

                    // Progress bar
                    if recording.isInProgress {
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: geo.size.width * recording.progressPercent, height: 3)
                            }
                        }
                        .frame(width: thumbWidth, height: thumbHeight)
                    }
                }
                .frame(width: thumbWidth, height: thumbHeight)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let label = recording.episodeLabel {
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Text(recording.dateFormatted)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Series Card

struct SeriesCard: View {
    let title: String
    let recordings: [Recording]
    let latestRecording: Recording?
    var onTap: () -> Void
    
    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 158
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    // Thumbnail from latest recording
                    AsyncImage(url: thumbURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Text(title.prefix(1))
                                        .font(.system(size: 60, weight: .bold))
                                        .foregroundColor(.white.opacity(0.3))
                                )
                        }
                    }
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                    
                    // Episode count badge
                    Text("\(recordings.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(8)
                }
                .cornerRadius(8)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(recordings.count) episode\(recordings.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: cardWidth)
        }
        .buttonStyle(.plain)
    }
    
    private var thumbURL: URL? {
        guard let recording = latestRecording,
              let thumb = recording.thumb ?? recording.art,
              let serverURL = UserDefaults.standard.serverURL else { return nil }
        return serverURL.appendingPathComponent(thumb)
    }
}

// MARK: - Scheduled Card

struct ScheduledCard: View {
    let recording: Recording
    var onCancel: () -> Void
    
    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 158
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Thumbnail or placeholder
                AsyncImage(url: thumbURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipped()
                .overlay(Color.black.opacity(0.3))
                
                // Cancel button
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                }
            }
            .cornerRadius(8)
            
            Text(recording.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(scheduledInfo)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(width: cardWidth)
    }
    
    private var thumbURL: URL? {
        guard let thumb = recording.thumb ?? recording.art,
              let serverURL = UserDefaults.standard.serverURL else { return nil }
        return serverURL.appendingPathComponent(thumb)
    }
    
    private var scheduledInfo: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d 'at' h:mm a"
        return formatter.string(from: recording.startTime)
    }
}

// MARK: - Manage Recordings Sheet

struct ManageRecordingsSheet: View {
    @ObservedObject var viewModel: DVRViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    Text("Recordings").tag(0)
                    Text("Series Rules").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    recordingsList
                } else {
                    seriesRulesList
                }
            }
            .navigationTitle("Manage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var recordingsList: some View {
        List {
            ForEach(viewModel.recordings) { recording in
                HStack {
                    VStack(alignment: .leading) {
                        Text(recording.title)
                            .font(.headline)
                        if let subtitle = recording.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(recording.dateFormatted)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let size = recording.fileSizeFormatted {
                        Text(size)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let recording = viewModel.recordings[index]
                    Task { await viewModel.deleteRecording(recording) }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var seriesRulesList: some View {
        Group {
            if viewModel.seriesRules.isEmpty {
                ContentUnavailableView(
                    "No Series Rules",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Create series recordings from the TV Guide.")
                )
            } else {
                List {
                    ForEach(viewModel.seriesRules) { rule in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(rule.title)
                                    .font(.headline)
                                Text("\(rule.recordingCount) recordings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Circle()
                                .fill(rule.enabled ? Color.green : Color.gray)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let rule = viewModel.seriesRules[index]
                            Task { await viewModel.deleteSeriesRule(rule) }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

#Preview {
    DVRView()
}
