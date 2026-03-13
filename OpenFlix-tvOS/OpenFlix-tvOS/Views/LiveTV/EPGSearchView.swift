import SwiftUI

// MARK: - EPG Guide Search (tvOS)
// Two-panel: on-screen search entry left, results right

struct EPGSearchView: View {
    @ObservedObject var viewModel: LiveTVViewModel
    @Binding var isPresented: Bool
    let onChannelSelect: (Channel) -> Void
    let onProgramSelect: (Program, Channel) -> Void

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private let bg = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)

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

    private func normalizeForSearch(_ s: String) -> String {
        s.lowercased()
         .replacingOccurrences(of: ".", with: "")
         .replacingOccurrences(of: "'", with: "")
         .replacingOccurrences(of: "-", with: " ")
         .trimmingCharacters(in: .whitespaces)
    }

    private var programResults: [(program: Program, channel: Channel)] {
        guard searchText.count >= 2 else { return [] }
        let query = normalizeForSearch(searchText)
        var results: [(Program, Channel)] = []

        for cwp in viewModel.guide {
            var channelHits = 0
            for program in cwp.programs {
                let matchTitle    = normalizeForSearch(program.title).contains(query)
                let matchSubtitle = program.subtitle.map { normalizeForSearch($0).contains(query) } ?? false
                let matchDesc     = program.description.map { normalizeForSearch($0).contains(query) } ?? false
                let matchTeams    = program.teams.map { normalizeForSearch($0).contains(query) } ?? false
                if matchTitle || matchSubtitle || matchDesc || matchTeams {
                    results.append((program, cwp.channel))
                    channelHits += 1
                    if channelHits >= 5 { break }
                }
            }
            if results.count >= 80 { break }
        }
        return results.sorted { $0.0.startTime < $1.0.startTime }
    }

    private var hasResults: Bool {
        !channelResults.isEmpty || !programResults.isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            HStack(spacing: 0) {
                // Left: search entry + keyboard
                searchPanel
                    .frame(width: 480)

                Divider()
                    .background(Color.white.opacity(0.1))

                // Right: results
                resultsPanel
            }
        }
    }

    // MARK: - Search Panel

    private var searchPanel: some View {
        VStack(spacing: 24) {
            // Title
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundColor(accentColor)
                Text("Guide Search")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)

            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search channels, shows, teams...", text: $searchText)
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 24))
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(cardBg)
            .cornerRadius(12)
            .padding(.horizontal, 40)

            // Stats
            if !searchText.isEmpty {
                HStack {
                    if !channelResults.isEmpty {
                        statBadge("\(channelResults.count)", label: "channels", color: accentColor)
                    }
                    if !programResults.isEmpty {
                        statBadge("\(programResults.count)", label: "programs", color: .green)
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            // Close button
            Button("Close") { isPresented = false }
                .buttonStyle(TVSecondaryButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
        }
    }

    private func statBadge(_ value: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .padding(.trailing, 16)
    }

    // MARK: - Results Panel

    private var resultsPanel: some View {
        Group {
            if searchText.isEmpty {
                emptySearchPrompt
            } else if !hasResults {
                noResultsView
            } else {
                resultsList
            }
        }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !channelResults.isEmpty {
                    sectionHeader("Channels (\(channelResults.count))")
                    ForEach(channelResults) { channel in
                        channelResultRow(channel)
                    }
                }
                if !programResults.isEmpty {
                    sectionHeader("Programs (\(programResults.count))")
                    ForEach(programResults, id: \.program.id) { result in
                        programResultRow(result.program, channel: result.channel)
                    }
                }
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Row Views

    private func channelResultRow(_ channel: Channel) -> some View {
        Button {
            onChannelSelect(channel)
            isPresented = false
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                    if let logo = channel.logo {
                        AuthenticatedImage(path: logo, systemPlaceholder: "tv")
                            .aspectRatio(contentMode: .fit)
                            .padding(6)
                    } else {
                        Text(channel.name.prefix(4).uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 64, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let nowPlaying = channel.nowPlaying {
                        Text("Now: \(nowPlaying.title)")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(accentColor)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 14)
        }
        .buttonStyle(.card)
    }

    private func programResultRow(_ program: Program, channel: Channel) -> some View {
        Button {
            onProgramSelect(program, channel)
            isPresented = false
        } label: {
            HStack(spacing: 16) {
                programThumbnail(program)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(program.title)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        ForEach(program.badges.prefix(2), id: \.self) { badge in
                            Text(badge)
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(badgeColor(badge))
                                .cornerRadius(3)
                        }
                    }

                    if let subtitle = program.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }

                    Text("\(channel.name) • \(program.timeRangeFormatted)")
                        .font(.system(size: 15))
                        .foregroundColor(accentColor)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
        }
        .buttonStyle(.card)
    }

    @ViewBuilder
    private func programThumbnail(_ program: Program) -> some View {
        let catColor: Color = {
            if program.isSports { return Color(red: 0.2, green: 0.6, blue: 1.0) }
            if program.category?.lowercased().contains("movie") == true { return Color(red: 0.9, green: 0.5, blue: 0.1) }
            if program.category?.lowercased().contains("news") == true { return Color(red: 0.9, green: 0.2, blue: 0.2) }
            return accentColor
        }()

        ZStack(alignment: .bottomLeading) {
            if let art = program.art {
                AuthenticatedImage(path: art, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 64)
                    .clipped()
                    .overlay(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
            } else {
                RoundedRectangle(cornerRadius: 0)
                    .fill(catColor.opacity(0.15))
                    .frame(width: 100, height: 64)
                    .overlay(Image(systemName: "tv").foregroundColor(catColor.opacity(0.4)).font(.system(size: 26)))
            }

            VStack(spacing: 0) { Spacer(); catColor.frame(height: 3) }

            if program.isCurrentlyAiring {
                VStack {
                    HStack {
                        Spacer()
                        Text("NOW")
                            .font(.system(size: 9, weight: .heavy)).foregroundColor(.white)
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(Color.green).cornerRadius(3)
                    }.padding(4)
                    Spacer()
                }
            }
        }
        .frame(width: 100, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(catColor.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .heavy))
            .foregroundColor(.gray)
            .textCase(.uppercase)
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private var emptySearchPrompt: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.4))
            Text("Search the Guide")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white)
            Text("Find channels by name or number,\nand shows by title, description, or team")
                .font(.system(size: 20))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var noResultsView: some View {
        let totalPrograms = viewModel.guide.reduce(0) { $0 + $1.programs.count }
        return VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48)).foregroundColor(.gray.opacity(0.4))
            Text("No results for \"\(searchText)\"")
                .font(.system(size: 24, weight: .medium)).foregroundColor(.white)
            Text("Searched \(totalPrograms) programs across \(viewModel.guide.count) channels")
                .font(.system(size: 16)).foregroundColor(.gray)
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
