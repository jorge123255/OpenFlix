import Foundation
import SwiftUI

@MainActor
class DVRViewModel: ObservableObject {
    private let dvrRepository = DVRRepository()

    @Published var recordings: [Recording] = []
    @Published var scheduledRecordings: [Recording] = []
    @Published var seriesRules: [SeriesRule] = []
    @Published var selectedTab = DVRTab.recordings
    @Published var isLoading = false
    @Published var error: String?

    enum DVRTab: String, CaseIterable {
        case recordings = "Recordings"
        case scheduled = "Scheduled"
        case series = "Series"
    }

    // MARK: - Load

    func loadRecordings() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await dvrRepository.loadRecordings()
            recordings = dvrRepository.recordings
            scheduledRecordings = dvrRepository.scheduledRecordings
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadSeriesRules() async {
        do {
            try await dvrRepository.loadSeriesRules()
            seriesRules = dvrRepository.seriesRules
        } catch {
            // Silently fail
        }
    }

    // MARK: - Actions

    func deleteRecording(_ recording: Recording) async {
        do {
            try await dvrRepository.deleteRecording(id: recording.id)
            recordings = dvrRepository.recordings
            scheduledRecordings = dvrRepository.scheduledRecordings
        } catch {
            self.error = error.localizedDescription
        }
    }

    func getRecordingStream(_ recording: Recording) async throws -> URL {
        try await dvrRepository.getRecordingStream(id: recording.id, isInProgress: recording.isCurrentlyRecording)
    }

    func scheduleRecording(channelId: String, startTime: Date, endTime: Date, title: String) async throws {
        let recording = try await dvrRepository.scheduleRecording(
            channelId: channelId,
            startTime: startTime,
            endTime: endTime,
            title: title
        )
        scheduledRecordings.append(recording)
    }

    func recordProgram(channelId: String, program: Program) async throws {
        let recording = try await dvrRepository.recordProgram(
            channelId: channelId,
            programId: program.id
        )
        scheduledRecordings.append(recording)
    }

    func toggleRecordingWatched(_ recording: Recording) async {
        do {
            try await dvrRepository.toggleRecordingWatched(id: recording.id)
            await loadRecordings()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleRecordingFavorite(_ recording: Recording) async {
        do {
            try await dvrRepository.toggleRecordingFavorite(id: recording.id)
            await loadRecordings()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleRecordingKeep(_ recording: Recording) async {
        do {
            try await dvrRepository.toggleRecordingKeep(id: recording.id)
            await loadRecordings()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func stopRecording(_ recording: Recording) async {
        do {
            try await dvrRepository.stopRecording(id: recording.id)
            await loadRecordings()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteSeriesRule(_ rule: SeriesRule) async {
        do {
            try await dvrRepository.deleteSeriesRule(id: rule.id)
            seriesRules = dvrRepository.seriesRules
        } catch {
            // Silently fail
        }
    }

    // MARK: - Computed

    var recordingsByDate: [(date: Date, recordings: [Recording])] {
        let grouped = dvrRepository.recordingsGroupedByDate
        return grouped.map { ($0.key, $0.value) }
            .sorted { $0.date > $1.date }
    }

    var upcomingRecordings: [Recording] {
        dvrRepository.upcomingRecordings
    }

    var currentlyRecording: [Recording] {
        dvrRepository.currentlyRecording
    }

    var inProgressRecordings: [Recording] {
        recordings.filter { $0.isInProgress }
    }
    
    /// Recently completed recordings (last 7 days, not in progress)
    var justRecorded: [Recording] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return recordings
            .filter { $0.status == .completed && !$0.isInProgress && $0.endTime > sevenDaysAgo }
            .sorted { $0.endTime > $1.endTime }
            .prefix(20)
            .map { $0 }
    }
    
    /// Recordings grouped by series/show title
    var recordingsBySeries: [(title: String, recordings: [Recording])] {
        let grouped = Dictionary(grouping: recordings.filter { $0.status == .completed }) { $0.title }
        return grouped
            .map { (title: $0.key, recordings: $0.value.sorted { $0.endTime > $1.endTime }) }
            .sorted { $0.recordings.count > $1.recordings.count }
    }

    /// Recordings grouped by channel
    var recordingsByChannel: [(channelId: String, channelName: String, channelLogo: String?, recordings: [Recording])] {
        let completed = recordings.filter { $0.status == .completed }
        let grouped = Dictionary(grouping: completed) { $0.channelId ?? $0.channelName ?? "Unknown" }
        return grouped.map { (key, recs) in
            let sorted = recs.sorted { $0.endTime > $1.endTime }
            return (channelId: key, channelName: sorted.first?.channelName ?? "Unknown Channel",
                    channelLogo: sorted.first?.channelLogo, recordings: sorted)
        }
        .sorted { ($0.recordings.first?.endTime ?? .distantPast) > ($1.recordings.first?.endTime ?? .distantPast) }
    }

    var hasRecordings: Bool {
        !recordings.isEmpty
    }

    var hasScheduled: Bool {
        !scheduledRecordings.isEmpty
    }

    var hasSeriesRules: Bool {
        !seriesRules.isEmpty
    }
}
