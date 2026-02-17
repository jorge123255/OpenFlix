import Foundation

@MainActor
class PlaylistRepository: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published var playlists: [Playlist] = []

    // MARK: - Load

    func loadPlaylists() async throws {
        let response = try await api.getPlaylists()
        playlists = response.allPlaylists.map { $0.toDomain() }
    }

    func getPlaylistItems(id: Int) async throws -> [PlaylistItem] {
        let response = try await api.getPlaylistItems(id: id)
        return (response.items ?? []).map { $0.toDomain() }
    }

    // MARK: - Create/Delete

    func createPlaylist(name: String) async throws -> Playlist {
        let dto = try await api.createPlaylist(name: name)
        let playlist = dto.toDomain()
        playlists.append(playlist)
        return playlist
    }

    func deletePlaylist(id: Int) async throws {
        try await api.deletePlaylist(id: id)
        playlists.removeAll { $0.id == id }
    }

    // MARK: - Add/Remove Items

    func addToPlaylist(playlistId: Int, mediaIds: [Int]) async throws {
        try await api.addToPlaylist(id: playlistId, mediaIds: mediaIds)
        // Reload to get updated item count
        try await loadPlaylists()
    }

    func removeFromPlaylist(playlistId: Int, itemId: Int) async throws {
        try await api.requestVoid(.removeFromPlaylist(id: playlistId, itemId: itemId))
        try await loadPlaylists()
    }
}
