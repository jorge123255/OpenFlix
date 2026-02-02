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
        try await dvrRepository.getRecordingStream(id: recording.id)
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
