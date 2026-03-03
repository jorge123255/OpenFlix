import SwiftUI

// MARK: - EPG Search View
// Searches channels by name (client-side) and programs by title (server-side)

struct EPGSearchView: View {
    @Environment(\.dismiss) private var dismiss
    let channels: [Channel]
    let onChannelSelect: (Channel) -> Void
    let onProgramSelect: (EPGSearchProgram) -> Void

    @State private var query = ""
    @State private var programResults: [EPGSearchProgram] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>? = nil

    private var channelResults: [Channel] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return channels.filter { $0.name.lowercased().contains(q) }
            .sorted { ($0.number ?? 999) < ($1.number ?? 999) }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Channels, shows, movies…", text: $query)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: query) { _, new in scheduleSearch(new) }
                        if !query.isEmpty {
                            Button { query = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if query.isEmpty {
                        emptyState
                    } else if channelResults.isEmpty && programResults.isEmpty && !isSearching {
                        noResults
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Search Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Results list

    private var resultsList: some View {
        List {
            // Channels section
            if !channelResults.isEmpty {
                Section("Channels") {
                    ForEach(channelResults) { channel in
                        ChannelSearchRow(channel: channel)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismiss()
                                onChannelSelect(channel)
                            }
                            .listRowBackground(Color(.secondarySystemBackground))
                    }
                }
            }

            // Programs section
            if isSearching {
                Section("Programs") {
                    HStack {
                        Spacer()
                        ProgressView().padding(.vertical, 8)
                        Spacer()
                    }
                    .listRowBackground(Color(.secondarySystemBackground))
                }
            } else if !programResults.isEmpty {
                Section("Programs") {
                    ForEach(programResults) { program in
                        ProgramSearchRow(program: program)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismiss()
                                onProgramSelect(program)
                            }
                            .listRowBackground(Color(.secondarySystemBackground))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Empty states

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Search for channels, shows, or movies across your entire guide")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var noResults: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tv.slash")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No results for \"\(query)\"")
                .font(.headline)
            Text("Try a different title or channel name")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Search logic

    private func scheduleSearch(_ q: String) {
        searchTask?.cancel()
        programResults = []
        guard !q.trimmingCharacters(in: .whitespaces).isEmpty else {
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000) // 350ms debounce
            guard !Task.isCancelled else { return }
            do {
                let response = try await OpenFlixAPI.shared.searchGuidePrograms(query: q, limit: 40)
                await MainActor.run {
                    programResults = response.programs
                    isSearching = false
                }
            } catch {
                await MainActor.run { isSearching = false }
            }
        }
    }
}

// MARK: - Channel search row

private struct ChannelSearchRow: View {
    let channel: Channel

    var body: some View {
        HStack(spacing: 12) {
            // Logo
            ZStack {
                Color(.tertiarySystemBackground)
                if let logo = channel.logo, let url = URL(string: logo) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFit().padding(4)
                        } else {
                            Image(systemName: "tv").foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "tv").foregroundStyle(.secondary)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(channel.name)
                    .font(.headline)
                if let num = channel.number {
                    Text("Ch. \(num)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Program search row

private struct ProgramSearchRow: View {
    let program: EPGSearchProgram

    var body: some View {
        HStack(spacing: 12) {
            // Artwork thumbnail
            ZStack {
                Color(.tertiarySystemBackground)
                if let art = program.art, let url = URL(string: art) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            placeholderIcon
                        }
                    }
                } else {
                    placeholderIcon
                }
            }
            .frame(width: 80, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                // Title
                HStack(spacing: 4) {
                    Text(program.safeTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    if program.isCurrentlyAiring {
                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }

                // Episode info
                if let ep = program.episodeNum, !ep.isEmpty {
                    Text(ep)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                // Channel + time
                HStack(spacing: 6) {
                    if let logo = program.channelLogo, let url = URL(string: logo) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFit()
                            }
                        }
                        .frame(width: 18, height: 18)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    Text(program.safeChannelName)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    if let start = program.startDate {
                        Text("•")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 10))
                        Text(start, format: .dateTime.weekday(.abbreviated).hour().minute())
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private var placeholderIcon: some View {
        Image(systemName: program.isMovie == true ? "film" : "tv")
            .font(.system(size: 20))
            .foregroundStyle(.tertiary)
    }
}
