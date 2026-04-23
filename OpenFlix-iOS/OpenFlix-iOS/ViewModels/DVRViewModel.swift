import Foundation
import SwiftUI

@MainActor
class DVRViewModel: ObservableObject {
    private let dvrRepository = DVRRepository()
    private let tunerBackendStore = TunerBackendStore.shared

    @Published var recordings: [Recording] = []
    @Published var scheduledRecordings: [Recording] = []
    @Published var seriesRules: [SeriesRule] = []
    @Published var managedPassRules: [ManagedPassRule] = []
    @Published var activeTunerBackend: TunerBackend?
    @Published var providerActionStates: [String: ProgramDVRActionState] = [:]
    @Published var recordingActionStates: [Int: RecordingDVRActionState] = [:]
    @Published var directvDownloadJobs: [String: ExternalDownloadJob] = [:]
    @Published var providerUpcomingRecordings: [Recording] = []
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
            try? await tunerBackendStore.load()
            activeTunerBackend = tunerBackendStore.activeBackend
            try await dvrRepository.loadRecordings()
            recordings = dvrRepository.recordings
            scheduledRecordings = dvrRepository.scheduledRecordings
            providerUpcomingRecordings = (try? await dvrRepository.loadProviderUpcomingRecordings()) ?? []
            await loadDownloadJobs()
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadSeriesRules() async {
        do {
            managedPassRules = try await dvrRepository.loadManagedPassRules()
            seriesRules = dvrRepository.seriesRules
        } catch {
            // Silently fail
        }
    }

    func loadDownloadJobs() async {
        guard let backend = activeTunerBackend else { return }
        let hasDirectvCloud = (backend.providers ?? []).contains { provider in
            provider.id.caseInsensitiveCompare("directv") == .orderedSame &&
            (provider.accounts ?? []).contains { $0.resolvedUIMode == .backendDVR }
        }
        guard hasDirectvCloud else {
            directvDownloadJobs = [:]
            return
        }

        do {
            let jobs = try await dvrRepository.getAllDirectvDownloads()
            directvDownloadJobs = Dictionary(uniqueKeysWithValues: jobs.map { ($0.id, $0) })
        } catch {
            directvDownloadJobs = [:]
        }
    }

    // MARK: - Actions

    func deleteRecording(_ recording: Recording) async {
        do {
            try await dvrRepository.deleteRecording(recording)
            recordings = dvrRepository.recordings
            scheduledRecordings = dvrRepository.scheduledRecordings
            recordingActionStates.removeValue(forKey: recording.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func getRecordingStream(_ recording: Recording) async throws -> URL {
        try await dvrRepository.getRecordingStream(recording)
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

    func recordProgram(channel: Channel, program: Program) async throws {
        try? await tunerBackendStore.load()
        activeTunerBackend = tunerBackendStore.activeBackend
        try await dvrRepository.recordProgram(channel: channel, program: program)
    }

    func createSeriesPass(channel: Channel, program: Program, prePadding: Int = 0, postPadding: Int = 0, keepCount: Int = 0) async throws {
        try? await tunerBackendStore.load()
        activeTunerBackend = tunerBackendStore.activeBackend
        try await dvrRepository.createSeriesPass(
            channel: channel,
            program: program,
            prePadding: prePadding,
            postPadding: postPadding,
            keepCount: keepCount
        )
    }

    func programActionState(channel: Channel, program: Program) async -> ProgramDVRActionState {
        try? await tunerBackendStore.load()
        activeTunerBackend = tunerBackendStore.activeBackend
        let key = "\(channel.id)::\(program.id)"
        let state = (try? await dvrRepository.actionState(for: channel, program: program)) ?? .fallback()
        providerActionStates[key] = state
        return state
    }

    func startDownload(channel: Channel, program: Program) async throws -> ExternalDownloadJob? {
        try? await tunerBackendStore.load()
        activeTunerBackend = tunerBackendStore.activeBackend
        guard var job = try await dvrRepository.startDownload(channel: channel, program: program) else {
            return nil
        }

        directvDownloadJobs[job.id] = job

        if let jobId = job.jobId {
            for _ in 0..<5 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                job = try await dvrRepository.getDirectvDownloadJob(jobId: jobId)
                directvDownloadJobs[job.id] = job
                let status = (job.status ?? "").lowercased()
                if status.contains("complete") || status.contains("failed") || status.contains("error") {
                    break
                }
            }
        }

        return job
    }

    func recordingActionState(for recording: Recording) async -> RecordingDVRActionState {
        try? await tunerBackendStore.load()
        activeTunerBackend = tunerBackendStore.activeBackend
        let state = (try? await dvrRepository.actionState(for: recording)) ?? .fallback()
        recordingActionStates[recording.id] = state
        if let job = state.downloadJob {
            directvDownloadJobs[job.id] = job
        }
        return state
    }

    func startDownload(for recording: Recording) async throws -> ExternalDownloadJob? {
        try? await tunerBackendStore.load()
        activeTunerBackend = tunerBackendStore.activeBackend
        guard var job = try await dvrRepository.startDownload(recording) else {
            return nil
        }

        directvDownloadJobs[job.id] = job

        if let jobId = job.jobId {
            for _ in 0..<5 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                job = try await dvrRepository.getDirectvDownloadJob(jobId: jobId)
                directvDownloadJobs[job.id] = job
                let status = (job.status ?? "").lowercased()
                if status.contains("complete") || status.contains("failed") || status.contains("error") {
                    break
                }
            }
        }

        return job
    }

    func providerAccount(for channel: Channel) -> TunerBackendProviderAccount? {
        tunerBackendStore.providerAccount(for: channel)
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
            managedPassRules.removeAll { $0.id == "local-\(rule.id)" }
        } catch {
            // Silently fail
        }
    }

    func setManagedPassEnabled(_ rule: ManagedPassRule, enabled: Bool) async {
        do {
            try await dvrRepository.setManagedPassEnabled(rule, enabled: enabled)
            managedPassRules = try await dvrRepository.loadManagedPassRules()
            seriesRules = dvrRepository.seriesRules
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteManagedPass(_ rule: ManagedPassRule) async {
        do {
            try await dvrRepository.deleteManagedPass(rule)
            managedPassRules.removeAll { $0.id == rule.id }
            seriesRules = dvrRepository.seriesRules
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Computed

    var recordingsByDate: [(date: Date, recordings: [Recording])] {
        let grouped = dvrRepository.recordingsGroupedByDate
        return grouped.map { ($0.key, $0.value) }
            .sorted { $0.date > $1.date }
    }

    var upcomingRecordings: [Recording] {
        let combined = dvrRepository.upcomingRecordings + providerUpcomingRecordings
        return combined.sorted { $0.startTime < $1.startTime }
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
