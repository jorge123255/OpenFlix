import Foundation
import AVKit
import Combine

/// Commercial break data
struct CommercialBreak: Codable {
    let startTime: Double
    let endTime: Double
    let duration: Double
    let confidence: Double
    let skipped: Bool
    let userMarked: Bool

    enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case endTime = "end_time"
        case duration, confidence, skipped
        case userMarked = "user_marked"
    }
}

/// Commercial detection data for a recording
struct CommercialData: Codable {
    let recordingId: String
    let duration: Double
    let commercials: [CommercialBreak]
    let detectedAt: Date?
    let method: String
    let confidence: Double
    let userCorrected: Bool

    enum CodingKeys: String, CodingKey {
        case recordingId = "recording_id"
        case duration, commercials
        case detectedAt = "detected_at"
        case method, confidence
        case userCorrected = "user_corrected"
    }
}

/// Skip check response
struct SkipCheckResponse: Codable {
    let success: Bool
    let shouldSkip: Bool
    let skipTo: Double
    let position: Double

    enum CodingKeys: String, CodingKey {
        case success
        case shouldSkip = "should_skip"
        case skipTo = "skip_to"
        case position
    }
}

/// Commercial Skip state
enum CommercialSkipState {
    case idle
    case inCommercial(skipTo: Double)
    case countingDown(secondsRemaining: Int, skipTo: Double)
    case skipping
}

@MainActor
class CommercialSkipManager: ObservableObject {
    @Published var state: CommercialSkipState = .idle
    @Published var commercialData: CommercialData?
    @Published var autoSkipEnabled = true
    @Published var skipDelay: Double = 3.0 // Seconds before auto-skip

    private var recordingId: String?
    private var player: AVPlayer?
    private var checkTimer: Timer?
    private var countdownTimer: Timer?
    private var lastCheckedPosition: Double = 0

    // Check position every second
    private let checkInterval: TimeInterval = 1.0

    // MARK: - Public API

    func startMonitoring(recordingId: String, player: AVPlayer) {
        self.recordingId = recordingId
        self.player = player
        self.state = .idle

        // Fetch commercial data for this recording
        Task {
            await fetchCommercialData()
        }

        // Start position monitoring
        checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPosition()
            }
        }
    }

    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        state = .idle
        recordingId = nil
        player = nil
    }

    func skipNow() {
        guard case .inCommercial(let skipTo) = state,
              let player = player else { return }

        state = .skipping
        let time = CMTime(seconds: skipTo, preferredTimescale: 600)
        player.seek(to: time) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.state = .idle
            }
        }
    }

    func cancelSkip() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        state = .idle
    }

    func markAsCommercial(start: Double, end: Double) {
        guard let recordingId = recordingId else { return }

        Task {
            await sendMarkRequest(recordingId: recordingId, start: start, end: end, isCommercial: true)
        }
    }

    func markAsContent(start: Double, end: Double) {
        guard let recordingId = recordingId else { return }

        Task {
            await sendMarkRequest(recordingId: recordingId, start: start, end: end, isCommercial: false)
        }
    }

    // MARK: - Position Checking

    private func checkPosition() {
        guard let player = player,
              let recordingId = recordingId else { return }

        let currentTime = player.currentTime()
        let position = CMTimeGetSeconds(currentTime)

        // Avoid checking same position repeatedly
        if abs(position - lastCheckedPosition) < 0.5 {
            return
        }
        lastCheckedPosition = position

        // Check if we're in a commercial
        Task {
            await checkIfShouldSkip(recordingId: recordingId, position: position)
        }
    }

    private func checkIfShouldSkip(recordingId: String, position: Double) async {
        // First check local data
        if let data = commercialData {
            for commercial in data.commercials {
                if position >= commercial.startTime && position < commercial.endTime {
                    if commercial.confidence >= 0.8 {
                        handleCommercialDetected(skipTo: commercial.endTime)
                        return
                    }
                }
            }
        }

        // If no local data or not in known commercial, check server
        do {
            let response = try await checkPositionOnServer(recordingId: recordingId, position: position)
            if response.shouldSkip {
                handleCommercialDetected(skipTo: response.skipTo)
            } else if case .inCommercial = state {
                // We were in a commercial but now we're not
                state = .idle
            }
        } catch {
            // Server check failed, continue without skip
        }
    }

    private func handleCommercialDetected(skipTo: Double) {
        guard autoSkipEnabled else {
            // Just show indicator, don't auto-skip
            state = .inCommercial(skipTo: skipTo)
            return
        }

        // Start countdown if not already counting
        if case .countingDown = state { return }

        state = .countingDown(secondsRemaining: Int(skipDelay), skipTo: skipTo)

        var remaining = Int(skipDelay)
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                remaining -= 1
                if remaining <= 0 {
                    timer.invalidate()
                    self?.skipNow()
                } else {
                    self?.state = .countingDown(secondsRemaining: remaining, skipTo: skipTo)
                }
            }
        }
    }

    // MARK: - API Calls

    private func fetchCommercialData() async {
        guard let recordingId = recordingId,
              let serverURL = UserDefaults.standard.string(forKey: "serverURL"),
              let url = URL(string: "\(serverURL)/api/commercial/get?recording_id=\(recordingId)") else {
            return
        }

        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            struct Response: Codable {
                let success: Bool
                let detected: Bool
                let data: CommercialData?
            }

            let response = try JSONDecoder().decode(Response.self, from: data)
            if response.detected, let commercialData = response.data {
                self.commercialData = commercialData
            }
        } catch {
            // Silently fail - commercial skip is optional
        }
    }

    private func checkPositionOnServer(recordingId: String, position: Double) async throws -> SkipCheckResponse {
        guard let serverURL = UserDefaults.standard.string(forKey: "serverURL"),
              let url = URL(string: "\(serverURL)/api/commercial/check?recording_id=\(recordingId)&position=\(position)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(SkipCheckResponse.self, from: data)
    }

    private func sendMarkRequest(recordingId: String, start: Double, end: Double, isCommercial: Bool) async {
        let endpoint = isCommercial ? "mark" : "unmark"
        guard let serverURL = UserDefaults.standard.string(forKey: "serverURL"),
              let url = URL(string: "\(serverURL)/api/commercial/\(endpoint)") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "recording_id": recordingId,
            "start_time": start,
            "end_time": end
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        _ = try? await URLSession.shared.data(for: request)

        // Refresh commercial data
        await fetchCommercialData()
    }
}
