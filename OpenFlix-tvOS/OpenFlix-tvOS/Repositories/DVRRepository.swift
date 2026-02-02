import Foundation

@MainActor
class DVRRepository: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published var recordings: [Recording] = []
    @Published var scheduledRecordings: [Recording] = []
    @Published var seriesRules: [SeriesRule] = []

    // MARK: - Recordings

    func loadRecordings() async throws {
        let response = try await api.getRecordings(status: nil)
        let allRecordings = response.allRecordings.map { $0.toDomain() }

        recordings = allRecordings.filter { $0.status == .completed }
        scheduledRecordings = allRecordings.filter { $0.status == .scheduled || $0.status == .recording }
    }

    func loadCompletedRecordings() async throws {
        let response = try await api.getRecordings(status: "completed")
        recordings = response.allRecordings.map { $0.toDomain() }
    }

    func loadScheduledRecordings() async throws {
        let response = try await api.getRecordings(status: "scheduled")
        scheduledRecordings = response.allRecordings.map { $0.toDomain() }
    }

    func getRecording(id: Int) async throws -> Recording {
        let dto = try await api.getRecording(id: id)
        return dto.toDomain()
    }

    func getRecordingStream(id: Int) async throws -> URL {
        let response = try await api.getRecordingStream(id: id)
        guard let url = URL(string: response.url) else {
            throw NetworkError.invalidURL
        }
        return url
    }

    // MARK: - Schedule Recording

    func scheduleRecording(channelId: String, startTime: Date, endTime: Date, title: String) async throws -> Recording {
        let dto = try await api.scheduleRecording(
            channelId: channelId,
            startTime: startTime,
            endTime: endTime,
            title: title
        )
        let recording = dto.toDomain()

        // Add to scheduled list
        scheduledRecordings.append(recording)
        scheduledRecordings.sort { $0.startTime < $1.startTime }

        return recording
    }

    func recordProgram(channelId: String, programId: String) async throws -> Recording {
        let dto = try await api.recordFromProgram(channelId: channelId, programId: programId)
        let recording = dto.toDomain()

        scheduledRecordings.append(recording)
        scheduledRecordings.sort { $0.startTime < $1.startTime }

        return recording
    }

    func deleteRecording(id: Int) async throws {
        try await api.deleteRecording(id: id)

        // Remove from local lists
        recordings.removeAll { $0.id == id }
        scheduledRecordings.removeAll { $0.id == id }
    }

    // MARK: - Progress

    func updateProgress(recordingId: Int, timeMs: Int) async throws {
        try await api.request(.updateRecordingProgress(id: recordingId, time: timeMs)) as EmptyResponse
    }

    // MARK: - Series Rules

    func loadSeriesRules() async throws {
        let response: SeriesRulesResponse = try await api.request(.getSeriesRules)
        seriesRules = response.rules.map { $0.toDomain() }
    }

    func createSeriesRule(title: String, channelId: String?, prePadding: Int, postPadding: Int, keepCount: Int) async throws {
        let _: SeriesRuleDTO = try await api.request(.createSeriesRule(
            title: title,
            channelId: channelId,
            prePadding: prePadding,
            postPadding: postPadding,
            keepCount: keepCount
        ))
        try await loadSeriesRules()
    }

    func deleteSeriesRule(id: Int) async throws {
        try await api.requestVoid(.deleteSeriesRule(id: id))
        seriesRules.removeAll { $0.id == id }
    }

    // MARK: - Conflicts

    func getConflicts() async throws -> [ConflictDTO] {
        let response: ConflictsResponse = try await api.request(.getConflicts)
        return response.conflicts
    }

    // MARK: - Computed Properties

    var recordingsGroupedByDate: [Date: [Recording]] {
        let calendar = Calendar.current
        var grouped: [Date: [Recording]] = [:]

        for recording in recordings {
            let startOfDay = calendar.startOfDay(for: recording.startTime)
            if grouped[startOfDay] == nil {
                grouped[startOfDay] = []
            }
            grouped[startOfDay]?.append(recording)
        }

        return grouped
    }

    var upcomingRecordings: [Recording] {
        let now = Date()
        return scheduledRecordings.filter { $0.startTime > now }
    }

    var currentlyRecording: [Recording] {
        scheduledRecordings.filter { $0.status == .recording }
    }
}

// Empty response for void endpoints
struct EmptyResponse: Codable {}
