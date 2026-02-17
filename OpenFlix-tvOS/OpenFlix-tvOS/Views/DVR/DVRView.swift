import SwiftUI

struct DVRView: View {
    @StateObject private var viewModel = DVRViewModel()
    @State private var selectedRecording: Recording?
    @State private var showPlayer = false
    @State private var streamURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.recordings.isEmpty {
                    LoadingView(message: "Loading recordings...")
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.loadRecordings() }
                    }
                } else {
                    tabContent
                }
            }
            .navigationTitle("DVR")
        }
        .task {
            await viewModel.loadRecordings()
            await viewModel.loadSeriesRules()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let url = streamURL, let recording = selectedRecording {
                VideoPlayerView(
                    mediaItem: nil,
                    recordingURL: url,
                    startPosition: recording.viewOffset
                )
            }
        }
    }

    private var tabContent: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Tab", selection: $viewModel.selectedTab) {
                ForEach(DVRViewModel.DVRTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            switch viewModel.selectedTab {
            case .recordings:
                recordingsContent
            case .scheduled:
                scheduledContent
            case .series:
                seriesRulesContent
            }
        }
    }

    private var recordingsContent: some View {
        Group {
            if viewModel.hasRecordings {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // In Progress
                        if !viewModel.inProgressRecordings.isEmpty {
                            Section {
                                ForEach(viewModel.inProgressRecordings) { recording in
                                    RecordingRow(recording: recording) {
                                        playRecording(recording)
                                    } onDelete: {
                                        Task { await viewModel.deleteRecording(recording) }
                                    }
                                }
                            } header: {
                                sectionHeader("Continue Watching")
                            }
                        }

                        // By Date
                        ForEach(viewModel.recordingsByDate, id: \.date) { group in
                            Section {
                                ForEach(group.recordings) { recording in
                                    RecordingRow(recording: recording) {
                                        playRecording(recording)
                                    } onDelete: {
                                        Task { await viewModel.deleteRecording(recording) }
                                    }
                                }
                            } header: {
                                sectionHeader(dateFormatter.string(from: group.date))
                            }
                        }
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    icon: "record.circle",
                    title: "No Recordings",
                    message: "Your completed recordings will appear here."
                )
            }
        }
    }

    private var scheduledContent: some View {
        Group {
            if viewModel.hasScheduled {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Currently Recording
                        if !viewModel.currentlyRecording.isEmpty {
                            Section {
                                ForEach(viewModel.currentlyRecording) { recording in
                                    ScheduledRecordingRow(recording: recording) {
                                        Task { await viewModel.deleteRecording(recording) }
                                    }
                                }
                            } header: {
                                sectionHeader("Recording Now", icon: "record.circle", iconColor: .red)
                            }
                        }

                        // Upcoming
                        Section {
                            ForEach(viewModel.upcomingRecordings) { recording in
                                ScheduledRecordingRow(recording: recording) {
                                    Task { await viewModel.deleteRecording(recording) }
                                }
                            }
                        } header: {
                            sectionHeader("Upcoming")
                        }
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    icon: "clock",
                    title: "No Scheduled Recordings",
                    message: "Schedule recordings from the TV Guide."
                )
            }
        }
    }

    private var seriesRulesContent: some View {
        Group {
            if viewModel.hasSeriesRules {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.seriesRules) { rule in
                            SeriesRuleRow(rule: rule) {
                                Task { await viewModel.deleteSeriesRule(rule) }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "No Series Rules",
                    message: "Create series recordings to automatically record new episodes."
                )
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String? = nil, iconColor: Color = .primary) -> some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.headline)
            Spacer()
        }
    }

    private func playRecording(_ recording: Recording) {
        Task {
            do {
                let url = try await viewModel.getRecordingStream(recording)
                selectedRecording = recording
                streamURL = url
                showPlayer = true
            } catch {
                viewModel.error = error.localizedDescription
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

struct RecordingRow: View {
    let recording: Recording
    var onPlay: () -> Void
    var onDelete: () -> Void

    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 16) {
                // Thumbnail
                AsyncImage(url: thumbURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "play.rectangle")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(width: 200, height: 112)
                .cornerRadius(8)

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(recording.fullTitle)
                        .font(.headline)
                        .lineLimit(1)

                    HStack {
                        if let channelName = recording.channelName {
                            Text(channelName)
                        }
                        Text(recording.dateFormatted)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    HStack {
                        Text(recording.durationFormatted)

                        if let size = recording.fileSizeFormatted {
                            Text(size)
                        }

                        if recording.status == .failed {
                            Text("FAILED")
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if recording.isInProgress {
                        ProgressBar(progress: recording.progressPercent)
                            .frame(height: 3)
                            .frame(maxWidth: 200)
                    }
                }

                Spacer()

                // Play button
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var thumbURL: URL? {
        guard let thumb = recording.thumb,
              let serverURL = UserDefaults.standard.serverURL else { return nil }
        return serverURL.appendingPathComponent(thumb)
    }
}

struct ScheduledRecordingRow: View {
    let recording: Recording
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            Image(systemName: recording.status == .recording ? "record.circle" : "clock")
                .font(.title2)
                .foregroundColor(recording.status == .recording ? .red : .secondary)
                .frame(width: 44)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.fullTitle)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    if let channelName = recording.channelName {
                        Text(channelName)
                    }
                    Text(recording.timeRangeFormatted)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                Text(recording.dateFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Cancel button
            Button(action: onCancel) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SeriesRuleRow: View {
    let rule: SeriesRule
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(rule.title)
                    .font(.headline)

                HStack {
                    if !rule.enabled {
                        Text("Disabled")
                            .foregroundColor(.orange)
                    }

                    Text("\(rule.recordingCount) recordings")

                    if rule.keepCount > 0 {
                        Text("Keep \(rule.keepCount)")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: .constant(rule.enabled))
                .labelsHidden()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    DVRView()
}
