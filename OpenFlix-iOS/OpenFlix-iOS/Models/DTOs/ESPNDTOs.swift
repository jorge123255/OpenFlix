import Foundation

// MARK: - ESPN Hub
//
// `GET /api/tuner-backends/active/espn/hub` returns:
//   - linearChannels   always-present list of linear ESPN channels
//   - linearCount      count of the above
//   - disneyHub        DXPage or null (Disney-shaped page)
//   - hasDisneyHub     bool
//   - generated        ISO timestamp
//
// Linear channels play via `/api/tuner-backends/active/stream/:channelId`
// (raw MPEG-TS — hand the URL to VLC). Disney-shaped items inside the
// embedded disneyHub page (when hasDisneyHub == true) play via
// `/api/tuner-backends/active/espn/play/stream` with browse-derived
// context as query params.
//
// There is no flattened "rails / featuredItem" shape on the client.
// Render linearChannels directly; pass disneyHub through the shared
// DisneyPageRenderer.

struct ESPNHubResponse: Codable {
    let linearChannels: [ESPNLinearChannel]?
    let linearCount: Int?
    let disneyHub: DXPage?
    let hasDisneyHub: Bool?
    let generated: String?
}

struct ESPNLinearChannel: Codable, Identifiable {
    /// Stable slug from the tuner (e.g. "ESPN-LINEAR-ESPN"). Use this
    /// as the SwiftUI Identifiable id; it's what shows up in
    /// /api/tuner-backends/active/stream/:channelId.
    let id: String
    /// Disney's UUID for the channel — kept for cross-referencing
    /// browse items but NOT used for playback URL construction.
    let channelId: String?
    let key: String?
    let name: String
    let number: Int?
    let isLinear: Bool?
}
