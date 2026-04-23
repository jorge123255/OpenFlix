import Foundation

/// Cross-provider playback resolver. Each method calls the
/// corresponding `/<provider>/play` endpoint and returns a
/// `ProviderPlayResponse` with `streamUrl` + playback metadata
/// (DRM type, startover URL, codec). Callers hand `streamUrl`
/// straight to VLC. The client never builds streams from raw
/// browse data.
@MainActor
final class ProviderPlaybackService {
    static let shared = ProviderPlaybackService()
    private let api = OpenFlixAPI.shared

    // MARK: - Disney VOD

    func disneyPlay(contentId: String, quality: String? = nil) async throws -> ProviderPlayResponse {
        try await api.disneyPlay(contentId: contentId, quality: quality)
    }

    // MARK: - Max VOD

    func maxPlay(contentId: String, quality: String? = "1080p") async throws -> ProviderPlayResponse {
        try await api.maxPlay(contentId: contentId, quality: quality)
    }

    // MARK: - ESPN events
    //
    // ESPN events use the rich Disney-shaped browse context to
    // resolve playback. Forward every piece the server may need:
    // resourceId, itemId, deeplinkId + container (set/page/layout
    // resolution ids, styles, entity refs).

    func espnPlay(item: DXItem,
                  container: DXContainer? = nil,
                  mode: String? = nil) async throws -> ProviderPlayResponse {
        var params: [URLQueryItem] = []
        func add(_ name: String, _ value: String?) {
            if let value, !value.isEmpty { params.append(URLQueryItem(name: name, value: value)) }
        }

        if let resourceId = item.playback?.resourceId, !resourceId.isEmpty {
            params.append(URLQueryItem(name: "resourceId", value: resourceId))
        }
        add("itemId", item.deeplinkId?.replacingOccurrences(of: "entity-", with: "") ?? item.rawId)
        add("deeplinkId", item.deeplinkId ?? item.playback?.deeplinkId)
        add("availId", item.playback?.availId)

        let req = container?.request
        add("setId", item.setId ?? container?.setId ?? container?.rawId)
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
            // Server also accepts startover=1 — send both for back-compat.
            if mode.lowercased() == "startover" {
                params.append(URLQueryItem(name: "startover", value: "1"))
            }
        }

        return try await api.espnPlay(params: params)
    }
}
