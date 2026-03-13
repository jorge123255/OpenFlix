import SwiftUI

// MARK: - Playlists View

struct PlaylistsView: View {
    @StateObject private var viewModel = PlaylistsViewModel()
    @State private var showCreateSheet = false
    @State private var selectedPlaylist: Playlist?

    private let bg     = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let accent = Color(red: 97/255, green: 56/255, blue: 245/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            Group {
                if viewModel.isLoading && viewModel.playlists.isEmpty {
                    LoadingView(message: "Loading playlists...")
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.loadPlaylists() }
                    }
                } else if viewModel.playlists.isEmpty {
                    emptyState
                } else {
                    playlistGrid
                }
            }
        }
        .navigationTitle("Playlists")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(accent)
                }
            }
        }
        .task {
            await viewModel.loadPlaylists()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreatePlaylistSheet(viewModel: viewModel)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 52))
                .foregroundColor(.gray.opacity(0.4))
            Text("No Playlists")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            Text("Create playlists to organize your media.")
                .font(.system(size: 15))
                .foregroundColor(.gray)
            Button {
                showCreateSheet = true
            } label: {
                Text("Create Playlist")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accent)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var playlistGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
            ], spacing: 16) {
                ForEach(viewModel.playlists) { playlist in
                    PlaylistCard(playlist: playlist) {
                        selectedPlaylist = playlist
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Playlist Card

struct PlaylistCard: View {
    let playlist: Playlist
    let onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail or icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(OpenFlixColors.surfaceVariant)

                    if let thumb = playlist.thumb {
                        AuthenticatedImage(path: thumb, systemPlaceholder: "music.note.list")
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    } else {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 40))
                            .foregroundColor(OpenFlixColors.primary)
                    }
                }
                .frame(height: 140)
                .cornerRadius(12)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack {
                        Text("\(playlist.itemCount) items")
                            .font(.system(size: 16))
                            .foregroundColor(OpenFlixColors.textSecondary)

                        if let duration = playlist.durationFormatted {
                            Text("•")
                                .foregroundColor(OpenFlixColors.textTertiary)
                            Text(duration)
                                .font(.system(size: 16))
                                .foregroundColor(OpenFlixColors.textSecondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFocused ? OpenFlixColors.surfaceVariant : OpenFlixColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? OpenFlixColors.primary : .clear, lineWidth: 3)
            )
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

// MARK: - Create Playlist Sheet

struct CreatePlaylistSheet: View {
    @ObservedObject var viewModel: PlaylistsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var playlistName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Playlist Name") {
                    TextField("Enter name", text: $playlistName)
                }
            }
            .navigationTitle("New Playlist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createPlaylist(name: playlistName)
                            dismiss()
                        }
                    }
                    .disabled(playlistName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Playlists ViewModel

@MainActor
class PlaylistsViewModel: ObservableObject {
    private let repository = PlaylistRepository()

    @Published var playlists: [Playlist] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadPlaylists() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await repository.loadPlaylists()
            playlists = repository.playlists
        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createPlaylist(name: String) async {
        do {
            let playlist = try await repository.createPlaylist(name: name)
            playlists.append(playlist)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deletePlaylist(_ playlist: Playlist) async {
        do {
            try await repository.deletePlaylist(id: playlist.id)
            playlists.removeAll { $0.id == playlist.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    PlaylistsView()
}
