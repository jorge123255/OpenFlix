import SwiftUI

// MARK: - Channel Editor View (tvOS)
// Two-panel: channel list left, detail/edit right

struct TVChannelEditorView: View {
    @StateObject private var viewModel = TVChannelEditorViewModel()
    @State private var selectedChannel: Channel?
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private let bg = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)

    private var filteredChannels: [Channel] {
        if searchText.isEmpty { return viewModel.channels }
        let q = searchText.lowercased()
        return viewModel.channels.filter {
            $0.name.lowercased().contains(q) ||
            ($0.number.map { "\($0)" } ?? "").contains(q) ||
            ($0.group?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            HStack(spacing: 0) {
                // Left: channel list
                channelListPanel

                Divider().background(Color.white.opacity(0.1))

                // Right: selected channel detail
                if let channel = selectedChannel {
                    channelDetailPanel(channel)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "tv.badge.ellipsis")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("Select a channel to edit")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task { await viewModel.loadChannels() }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error { Text(error) }
        }
    }

    // MARK: - Channel List Panel

    private var channelListPanel: some View {
        VStack(spacing: 16) {
            Text("Channel Editor")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
                .padding(.horizontal, 40)

            // Search
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("Search channels...", text: $searchText)
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }.buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(cardBg)
            .cornerRadius(12)
            .padding(.horizontal, 40)

            if viewModel.isLoading {
                ProgressView().tint(.white)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredChannels) { channel in
                            TVChannelEditorRow(
                                channel: channel,
                                isSelected: selectedChannel?.id == channel.id,
                                accentColor: accentColor
                            ) {
                                selectedChannel = channel
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(width: 520)
    }

    // MARK: - Channel Detail Panel

    private func channelDetailPanel(_ channel: Channel) -> some View {
        TVChannelEditPanel(
            channel: channel,
            viewModel: viewModel,
            accentColor: accentColor,
            cardBg: cardBg,
            onSaved: {
                Task { await viewModel.loadChannels() }
                selectedChannel = nil
            }
        )
    }
}

// MARK: - Channel Editor Row

private struct TVChannelEditorRow: View {
    let channel: Channel
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                if let number = channel.number {
                    Text("\(number)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accentColor)
                        .frame(width: 44, alignment: .trailing)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08))
                    if let logo = channel.logo, !logo.isEmpty {
                        AuthenticatedImage(path: logo, systemPlaceholder: "tv")
                            .aspectRatio(contentMode: .fit).padding(4)
                    } else {
                        Image(systemName: "tv").foregroundColor(.gray)
                    }
                }
                .frame(width: 40, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if let group = channel.group {
                        Text(group)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if !channel.enabled {
                    Text("OFF")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.red)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(isSelected ? accentColor.opacity(0.2) : (isFocused ? Color.white.opacity(0.08) : Color.clear))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

// MARK: - Channel Edit Panel

private struct TVChannelEditPanel: View {
    let channel: Channel
    @ObservedObject var viewModel: TVChannelEditorViewModel
    let accentColor: Color
    let cardBg: Color
    let onSaved: () -> Void

    @State private var enabled: Bool
    @State private var isFavorite: Bool
    @State private var name: String
    @State private var isSaving = false

    init(channel: Channel, viewModel: TVChannelEditorViewModel, accentColor: Color, cardBg: Color, onSaved: @escaping () -> Void) {
        self.channel = channel
        self.viewModel = viewModel
        self.accentColor = accentColor
        self.cardBg = cardBg
        self.onSaved = onSaved
        _enabled = State(initialValue: channel.enabled)
        _isFavorite = State(initialValue: channel.isFavorite)
        _name = State(initialValue: channel.name)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Channel identity
                HStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08))
                        if let logo = channel.logo, !logo.isEmpty {
                            AuthenticatedImage(path: logo, systemPlaceholder: "tv")
                                .aspectRatio(contentMode: .fit).padding(12)
                        } else {
                            Image(systemName: "tv").font(.system(size: 36)).foregroundColor(.gray)
                        }
                    }
                    .frame(width: 100, height: 75)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(channel.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        if let number = channel.number {
                            Text("Channel \(number)")
                                .font(.system(size: 18))
                                .foregroundColor(accentColor)
                        }
                        if let group = channel.group {
                            Text(group)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                // Toggle options
                VStack(spacing: 12) {
                    toggleRow("Enable Channel", isOn: $enabled)
                    toggleRow("Mark as Favorite", isOn: $isFavorite)
                }

                Divider().background(Color.white.opacity(0.1))

                // Name edit
                VStack(alignment: .leading, spacing: 10) {
                    Text("Display Name")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)

                    TextField("Channel name", text: $name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(cardBg)
                        .cornerRadius(12)
                }

                // Source info
                if let sourceName = channel.sourceName {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Source")
                            .font(.system(size: 16)).foregroundColor(.gray)
                        Text(sourceName)
                            .font(.system(size: 18)).foregroundColor(.white)
                    }
                }

                // Action buttons
                HStack(spacing: 16) {
                    Button {
                        Task {
                            isSaving = true
                            await viewModel.saveChannel(
                                channel,
                                enabled: enabled,
                                isFavorite: isFavorite,
                                name: name
                            )
                            isSaving = false
                            onSaved()
                        }
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Label("Save Changes", systemImage: "checkmark")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(accentColor)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.card)
                    .disabled(isSaving)
                }
            }
            .padding(40)
        }
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label).font(.system(size: 20)).foregroundColor(.white)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(accentColor)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(cardBg).cornerRadius(10)
    }
}

// MARK: - Channel Editor ViewModel

@MainActor
class TVChannelEditorViewModel: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var isLoading = false
    @Published var error: String?

    private let repository = LiveTVRepository()

    func loadChannels() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await repository.loadChannels()
            channels = repository.channels
        } catch {
            self.error = error.localizedDescription
        }
    }

    func saveChannel(_ channel: Channel, enabled: Bool, isFavorite: Bool, name: String) async {
        struct ChannelUpdate: Encodable {
            let enabled: Bool
            let isFavorite: Bool
            let name: String
        }
        do {
            let body = ChannelUpdate(enabled: enabled, isFavorite: isFavorite, name: name)
            let _: EmptyEditResponse = try await OpenFlixAPI.shared.request(.updateChannel(id: channel.id, body: body))
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct EmptyEditResponse: Decodable {}
