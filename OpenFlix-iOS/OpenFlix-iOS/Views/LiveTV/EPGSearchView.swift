import SwiftUI

// MARK: - EPG Guide Search
// Searches both channel names and program titles/descriptions

struct EPGSearchView: View {
    @ObservedObject var viewModel: LiveTVViewModel
    @Binding var isPresented: Bool
    let onChannelSelect: (Channel) -> Void
    let onProgramSelect: (Program, Channel) -> Void

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    // MARK: - Computed Results

    private var channelResults: [Channel] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return viewModel.channels.filter { ch in
            ch.name.lowercased().contains(query) ||
            
            (ch.number.map { "\($0)" } ?? "").contains(query)
        }
        .prefix(20).map { $0 }
    }

    private var programResults: [(program: Program, channel: Channel)] {
        guard searchText.count >= 2 else { return [] }
        let query = searchText.lowercased()
        var results: [(Program, Channel)] = []

        for cwp in viewModel.guide {
            for program in cwp.programs {
                if program.title.lowercased().contains(query) ||
                   (program.subtitle?.lowercased().contains(query) ?? false) ||
                   (program.description?.lowercased().contains(query) ?? false) ||
                   (program.teams?.lowercased().contains(query) ?? false) {
                    results.append((program, cwp.channel))
                    if results.count >= 50 { break }
                }
            }
            if results.count >= 50 { break }
        }

        return results.sorted { $0.0.startTime < $1.0.startTime }
    }

    private var hasResults: Bool {
        !channelResults.isEmpty || !programResults.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                if searchText.isEmpty {
                    emptySearchPrompt
                } else if !hasResults {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .background(Color(red: 17/255, green: 12/255, blue: 33/255))
            .navigationTitle("Guide Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
        .onAppear { isSearchFocused = true }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search channels, shows, teams...", text: $searchText)
                .focused($isSearchFocused)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Channel results
                if !channelResults.isEmpty {
                    sectionHeader("Channels (\(channelResults.count))")

                    ForEach(channelResults) { channel in
                        channelResultRow(channel)
                    }
                }

                // Program results
                if !programResults.isEmpty {
                    sectionHeader("Programs (\(programResults.count))")

                    ForEach(programResults, id: \.program.id) { result in
                        programResultRow(result.program, channel: result.channel)
                    }
                }
            }
        }
    }

    // MARK: - Row Views

    private func channelResultRow(_ channel: Channel) -> some View {
        Button {
            onChannelSelect(channel)
            isPresented = false
        } label: {
            HStack(spacing: 12) {
                // Channel logo/number
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                    if let logo = channel.logo, let url = URL(string: logo) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Text("\(channel.number ?? 0)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(4)
                    } else {
                        Text("\(channel.number ?? 0)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 48, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let nowPlaying = channel.nowPlaying {
                        Text("Now: \(nowPlaying.title)")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func programResultRow(_ program: Program, channel: Channel) -> some View {
        Button {
            onProgramSelect(program, channel)
            isPresented = false
        } label: {
            HStack(spacing: 12) {
                // Time badge
                VStack(spacing: 2) {
                    Text(program.startTimeFormatted)
                        .font(.system(size: 12, weight: .bold))
                    if program.isCurrentlyAiring {
                        Text("NOW")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.green)
                    }
                }
                .frame(width: 60)
                .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(program.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        // Badges
                        ForEach(program.badges.prefix(2), id: \.self) { badge in
                            Text(badge)
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(badgeColor(badge))
                                .cornerRadius(3)
                        }
                    }

                    if let subtitle = program.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }

                    Text("\(channel.name) • \(program.timeRangeFormatted)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 97/255, green: 56/255, blue: 245/255))
                        .lineLimit(1)
                }

                Spacer()

                // Create pass button
                if !program.hasEnded {
                    Menu {
                        Button {
                            onProgramSelect(program, channel)
                        } label: {
                            Label("Details", systemImage: "info.circle")
                        }

                        if program.isSports, let teams = program.teams, !teams.isEmpty {
                            Button {
                                // Will be handled by pass management
                            } label: {
                                Label("Create Team Pass", systemImage: "sportscourt")
                            }
                        }

                        Button {
                            // Will be handled by pass management
                        } label: {
                            Label("Create Series Pass", systemImage: "calendar.badge.plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .heavy))
            .foregroundColor(.gray)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    private var emptySearchPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            Text("Search the Guide")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            Text("Find channels by name or number,\nand shows by title, description, or team")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.gray.opacity(0.4))
            Text("No results for \"\(searchText)\"")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
            Text("Try a different search term")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
        }
    }

    private func badgeColor(_ badge: String) -> Color {
        switch badge {
        case "LIVE": return .red
        case "NEW": return .blue
        case "REC": return .red.opacity(0.8)
        case "PREMIERE", "FINALE": return .purple
        default: return .gray
        }
    }
}
