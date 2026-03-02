import SwiftUI

// MARK: - Channel Editor View

struct ChannelEditorView: View {
    @StateObject private var viewModel = ChannelEditorViewModel()
    @State private var searchText = ""
    @State private var editingChannel: Channel?

    var filteredChannels: [Channel] {
        if searchText.isEmpty {
            return viewModel.channels
        }
        let query = searchText.lowercased()
        return viewModel.channels.filter {
            $0.name.lowercased().contains(query) ||
            $0.displayNumber.contains(query) ||
            ($0.group?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        List {
            ForEach(filteredChannels) { channel in
                ChannelEditorRow(channel: channel)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingChannel = channel
                    }
            }
        }
        .searchable(text: $searchText, prompt: "Search channels...")
        .navigationTitle("Channel Editor")
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.channels.isEmpty {
                ContentUnavailableView("No Channels", systemImage: "tv", description: Text("No channels found."))
            }
        }
        .task {
            await viewModel.loadChannels()
        }
        .sheet(item: $editingChannel) { channel in
            ChannelEditSheet(channel: channel, viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
}

// MARK: - Channel Editor Row

struct ChannelEditorRow: View {
    let channel: Channel

    var body: some View {
        HStack(spacing: 12) {
            // Logo
            if let logo = channel.logo, !logo.isEmpty {
                AuthenticatedImage(path: logo, systemPlaceholder: "tv")
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "tv")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if let number = channel.number {
                        Text("\(number)")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    Text(channel.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }

                if let group = channel.group, !group.isEmpty {
                    Text(group)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !channel.enabled {
                Text("Disabled")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(4)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Channel Edit Sheet

struct ChannelEditSheet: View {
    let channel: Channel
    @ObservedObject var viewModel: ChannelEditorViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var number: String
    @State private var group: String
    @State private var logoUrl: String
    @State private var enabled: Bool
    @State private var isSaving = false

    init(channel: Channel, viewModel: ChannelEditorViewModel) {
        self.channel = channel
        self.viewModel = viewModel
        _name = State(initialValue: channel.name)
        _number = State(initialValue: channel.displayNumber)
        _group = State(initialValue: channel.group ?? "")
        _logoUrl = State(initialValue: channel.logo ?? "")
        _enabled = State(initialValue: channel.enabled)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Logo Preview
                Section("Logo") {
                    HStack {
                        Spacer()
                        if !logoUrl.isEmpty {
                            AuthenticatedImage(path: logoUrl, systemPlaceholder: "tv")
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "tv")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                                .frame(width: 80, height: 80)
                                .background(Color.gray.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    TextField("Logo URL", text: $logoUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }

                // Channel Details
                Section("Channel Details") {
                    TextField("Channel Number", text: $number)
                        .keyboardType(.numberPad)

                    TextField("Channel Name", text: $name)

                    TextField("Group", text: $group)
                }

                // Status
                Section {
                    Toggle("Enabled", isOn: $enabled)
                }
            }
            .navigationTitle("Edit Channel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            await viewModel.updateChannel(
                id: channel.id,
                name: name != channel.name ? name : nil,
                number: number != channel.displayNumber ? number : nil,
                enabled: enabled != channel.enabled ? enabled : nil,
                group: group != (channel.group ?? "") ? group : nil,
                logo: logoUrl != (channel.logo ?? "") ? logoUrl : nil
            )
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Channel Editor ViewModel

@MainActor
class ChannelEditorViewModel: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadChannels() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: ChannelsResponse = try await OpenFlixAPI.shared.request(.getChannels)
            channels = response.allChannels.map { $0.toDomain() }.sorted { $0.sortKey < $1.sortKey }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateChannel(id: String, name: String?, number: String?, enabled: Bool?, group: String?, logo: String?) async {
        do {
            try await OpenFlixAPI.shared.requestVoid(
                .updateChannel(id: id, name: name, number: number, enabled: enabled, group: group, logo: logo)
            )
            await loadChannels()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
