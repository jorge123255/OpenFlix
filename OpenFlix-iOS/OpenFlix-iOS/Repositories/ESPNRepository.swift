import Foundation

/// ESPN section repository.
///
/// Backs the Sports tab's ESPN screen. Contract:
///   - hub fetch is a single call to `/api/tuner-backends/active/espn/hub`
///     which returns linear channels + an optional Disney-shaped hub
///     page; this client never hits Disney browse endpoints to derive
///     ESPN content.
///   - linear playback uses `/api/tuner-backends/active/stream/:channelId`.
///   - event playback (Disney-shaped items inside hub.disneyHub) uses
///     `/api/tuner-backends/active/espn/play/stream` with full
///     browse-derived context as query items — see `eventStreamURL(...)`.
///   - polling: 45s while ESPN is on screen; pauses while the player
///     is active (refcounted so multi-view + a presented detail can
///     both claim playback).
@MainActor
final class ESPNRepository: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published private(set) var hub: ESPNHubResponse?
    @Published private(set) var isLoadingHub = false
    @Published var error: String?

    private var pollingTask: Task<Void, Never>?

    /// Refcount of active playback views (player or multi-view). When > 0,
    /// the 45s poll skips its tick — playback takes priority over hub
    /// refresh per the contract.
    private var playbackActiveCount: Int = 0
    var isPlaybackActive: Bool { playbackActiveCount > 0 }

    // MARK: - Hub

    func loadHub(force: Bool = false) async {
        if !force && hub != nil { return }
        isLoadingHub = true
        defer { isLoadingHub = false }
        do {
            hub = try await api.espnHub()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func refreshHub() async {
        do {
            hub = try await api.espnHub()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Polling

    func startPolling() {
        if pollingTask != nil { return }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 45_000_000_000)
                if Task.isCancelled { return }
                guard let self else { return }
                if self.isPlaybackActive { continue }
                await self.refreshHub()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func beginPlayback() { playbackActiveCount += 1 }
    func endPlayback() { playbackActiveCount = max(0, playbackActiveCount - 1) }

    // MARK: - Playback URLs

    /// `/api/tuner-backends/active/stream/:channelId` for an ESPN linear
    /// channel from `hub.linearChannels`.
    func linearStreamURL(for channel: ESPNLinearChannel) async -> URL? {
        await api.tunerActiveStreamURL(channelId: channel.id)
    }

    /// `/api/tuner-backends/active/espn/play/stream` for a Disney-shaped
    /// playable event item inside `hub.disneyHub`. Forwards every piece
    /// of browse context the server may need to resolve playback. Pass
    /// `mode="startover"` for from-the-beginning playback.
    func eventStreamURL(
        for item: DXItem,
        in container: DXContainer? = nil,
        mode: String? = nil
    ) async -> URL? {
        guard let resourceId = item.playback?.resourceId, !resourceId.isEmpty else { return nil }

        var params: [URLQueryItem] = [URLQueryItem(name: "resourceId", value: resourceId)]
        func add(_ name: String, _ value: String?) {
            if let value, !value.isEmpty { params.append(URLQueryItem(name: name, value: value)) }
        }

        add("itemId", item.deeplinkId?.replacingOccurrences(of: "entity-", with: "") ?? item.rawId)
        add("deeplinkId", item.deeplinkId ?? item.playback?.deeplinkId)
        add("availId", item.playback?.availId)

        let req = container?.request
        add("setId", item.setId ?? container?.setId ?? container?.id)
        add("pageId", item.pageId ?? container?.pageId ?? req?.pageId)
        add("layoutId", container?.layoutId ?? req?.layoutId)
        add("pageResolutionId", container?.pageResolutionId ?? req?.pageResolutionId)
        add("setResolutionId", container?.setResolutionId ?? req?.setResolutionId)
        add("pageStyle", container?.pageStyle ?? req?.pageStyle)
        add("setStyle", container?.setStyle ?? req?.setStyle)
        add("entityId", container?.entityId ?? req?.entityId)
        add("entityType", container?.entityType ?? req?.entityType)

        if let mode, !mode.isEmpty {
            params.append(URLQueryItem(name: "mode", value: mode))
        }

        return await api.espnPlayStreamURL(params: params)
    }
}
