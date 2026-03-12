import SwiftUI

// MARK: - Pass Management View (Series Passes Only)
// Team Passes are managed separately in the Sports/Team Pass tab

struct PassManagementView: View {
    @StateObject private var viewModel = PassManagementViewModel()
    @State private var showCreateSheet = false
    @State private var ruleToDelete: SeriesPassItem?
    @State private var showDeleteConfirm = false

    private let backgroundColor = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            if viewModel.isLoading && viewModel.rules.isEmpty {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            } else if viewModel.rules.isEmpty {
                emptyState
            } else {
                rulesList
            }
        }
        .navigationTitle("Passes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(accentColor)
                        .font(.system(size: 20))
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateSeriesPassSheet(onCreated: {
                Task { await viewModel.loadRules() }
            })
        }
        .alert("Delete Pass?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let rule = ruleToDelete {
                    Task { await viewModel.deleteRule(rule) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let rule = ruleToDelete {
                Text("Remove \"\(rule.title)\"? Future episodes won't be recorded.")
            }
        }
        .refreshable {
            await viewModel.loadRules()
        }
        .task {
            await viewModel.loadRules()
        }
    }

    // MARK: - Rules List

    private var rulesList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                // Stats header
                HStack(spacing: 16) {
                    statBadge(label: "Active", value: "\(viewModel.rules.filter(\.enabled).count)", color: .green)
                    statBadge(label: "Paused", value: "\(viewModel.rules.filter { !$0.enabled }.count)", color: .orange)
                    statBadge(label: "Recorded", value: "\(viewModel.rules.map(\.recordingCount).reduce(0, +))", color: accentColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                ForEach(viewModel.rules) { rule in
                    ruleRow(rule)
                }
            }
            .padding(.bottom, 100)
        }
    }

    private func statBadge(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }

    private func ruleRow(_ rule: SeriesPassItem) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.15))

                Image(systemName: "tv.fill")
                    .font(.system(size: 18))
                    .foregroundColor(accentColor)
            }
            .frame(width: 44, height: 44)
            .opacity(rule.enabled ? 1.0 : 0.4)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(rule.enabled ? .white : .gray)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if rule.recordingCount > 0 {
                        Label("\(rule.recordingCount) recorded", systemImage: "checkmark.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    if rule.channelName != nil {
                        Label(rule.channelName!, systemImage: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }

                Text("Pre: \(rule.prePadding)m • Post: \(rule.postPadding)m" +
                     (rule.keepCount > 0 ? " • Keep \(rule.keepCount)" : " • Keep all"))
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.6))
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { _ in
                    Task { await viewModel.toggleRule(rule) }
                }
            ))
            .labelsHidden()
            .tint(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
        .contextMenu {
            Button(role: .destructive) {
                ruleToDelete = rule
                showDeleteConfirm = true
            } label: {
                Label("Delete Pass", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                ruleToDelete = rule
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(.gray.opacity(0.4))

            Text("No Series Passes")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            Text("Create a pass to automatically record\nnew episodes of your favorite shows")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button {
                showCreateSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Pass")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(accentColor)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Series Pass Item

struct SeriesPassItem: Identifiable {
    let id: String
    let title: String
    let enabled: Bool
    let prePadding: Int
    let postPadding: Int
    let keepCount: Int
    let recordingCount: Int
    let channelName: String?

    static func fromDTO(_ dto: SeriesRuleDTO) -> SeriesPassItem {
        SeriesPassItem(
            id: "\(dto.safeId)",
            title: dto.safeTitle,
            enabled: dto.enabled ?? true,
            prePadding: dto.prePadding ?? 0,
            postPadding: dto.postPadding ?? 0,
            keepCount: dto.keepCount ?? 0,
            recordingCount: dto.recordingCount ?? 0,
            channelName: nil
        )
    }
}

// MARK: - Pass Management ViewModel

@MainActor
class PassManagementViewModel: ObservableObject {
    @Published var rules: [SeriesPassItem] = []
    @Published var isLoading = false
    @Published var error: String?

    private let api = OpenFlixAPI.shared

    func loadRules() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await api.getSeriesRules()
            rules = response.rules
                .filter { $0.type == nil || $0.type == "series" }
                .map { SeriesPassItem.fromDTO($0) }
        } catch {
            // Silent - server might not have rules
        }
    }

    func toggleRule(_ rule: SeriesPassItem) async {
        // Optimistic toggle
        if let idx = rules.firstIndex(where: { $0.id == rule.id }) {
            let toggled = SeriesPassItem(
                id: rule.id, title: rule.title,
                enabled: !rule.enabled,
                prePadding: rule.prePadding, postPadding: rule.postPadding,
                keepCount: rule.keepCount, recordingCount: rule.recordingCount,
                channelName: rule.channelName
            )
            rules[idx] = toggled
        }
        // Reload from server to confirm
        await loadRules()
    }

    func deleteRule(_ rule: SeriesPassItem) async {
        do {
            try await api.deleteSeriesRule(id: rule.id)
            rules.removeAll { $0.id == rule.id }
        } catch {
            self.error = error.localizedDescription
            await loadRules()
        }
    }
}

// MARK: - Create Series Pass Sheet
// Phase 1: Search for a show via EPG guide data + TMDB
// Phase 2: Configure pass options and create

struct ShowSearchResult: Identifiable {
    enum Source { case epg, tmdb }
    let id: String
    let title: String
    let posterPath: String?       // TMDB poster path
    let network: String?
    let firstAirDate: String?
    let source: Source
    let tmdbId: Int?
}

@MainActor
class ShowSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [ShowSearchResult] = []
    @Published var isSearching = false

    private var searchTask: Task<Void, Never>?
    private let liveTVRepo = LiveTVRepository()

    func search(epgGuide: [ChannelWithPrograms]) {
        searchTask?.cancel()
        guard query.count >= 2 else {
            results = []
            return
        }
        isSearching = true
        let q = query
        searchTask = Task {
            // Run EPG + TMDB search concurrently
            async let tmdbResults = TMDBService.shared.searchTVShows(title: q)
            let epgResults = epgSearch(query: q, guide: epgGuide)

            let tmdb = await tmdbResults
            guard !Task.isCancelled else { return }

            var combined: [ShowSearchResult] = []

            // TMDB results first (richer metadata)
            for show in tmdb.prefix(8) {
                combined.append(ShowSearchResult(
                    id: "tmdb-\(show.id)",
                    title: show.name,
                    posterPath: show.posterPath,
                    network: nil,
                    firstAirDate: show.firstAirDate,
                    source: .tmdb,
                    tmdbId: show.id
                ))
            }

            // EPG results (deduplicated by title)
            let existingTitles = Set(combined.map { $0.title.lowercased() })
            for item in epgResults where !existingTitles.contains(item.title.lowercased()) {
                combined.append(item)
            }

            results = combined
            isSearching = false
        }
    }

    private func epgSearch(query: String, guide: [ChannelWithPrograms]) -> [ShowSearchResult] {
        let q = query.lowercased()
        var seen = Set<String>()
        var out: [ShowSearchResult] = []

        for cwp in guide {
            for program in cwp.programs {
                let titleLower = program.title.lowercased()
                guard titleLower.contains(q), !seen.contains(titleLower) else { continue }
                seen.insert(titleLower)
                out.append(ShowSearchResult(
                    id: "epg-\(program.id)",
                    title: program.title,
                    posterPath: nil,
                    network: cwp.channel.name,
                    firstAirDate: nil,
                    source: .epg,
                    tmdbId: nil
                ))
                if out.count >= 12 { break }
            }
            if out.count >= 12 { break }
        }
        return out
    }
}

struct CreateSeriesPassSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCreated: () -> Void

    @StateObject private var searchVM = ShowSearchViewModel()
    @State private var selectedShow: ShowSearchResult?
    @State private var phase: Phase = .search

    // Pass options
    @State private var prePadding = 0
    @State private var postPadding = 0
    @State private var keepCount = 0
    @State private var newEpisodesOnly = true
    @State private var isCreating = false
    @State private var errorMessage: String?

    // EPG guide data for search
    @State private var epgGuide: [ChannelWithPrograms] = []

    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let bg = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)

    enum Phase { case search, configure }

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                switch phase {
                case .search: searchPhase
                case .configure: configurePhase
                }
            }
            .navigationTitle(phase == .search ? "New Pass" : "Configure Pass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(phase == .search ? "Cancel" : "Back") {
                        if phase == .configure {
                            withAnimation { phase = .search }
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.white)
                }
                if phase == .configure {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") { createPass() }
                            .disabled(isCreating)
                            .bold()
                            .foregroundColor(accentColor)
                    }
                }
            }
            .task {
                // Load guide data for EPG search
                let repo = LiveTVRepository()
                if let cwps = try? await repo.getGuide() {
                    epgGuide = cwps
                }
            }
        }
    }

    // MARK: - Search Phase

    private var searchPhase: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search for a TV show...", text: $searchVM.query)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .onChange(of: searchVM.query) { _, _ in
                        searchVM.search(epgGuide: epgGuide)
                    }
                if !searchVM.query.isEmpty {
                    Button { searchVM.query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(cardBg)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if searchVM.isSearching {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchVM.results.isEmpty && searchVM.query.count >= 2 {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No shows found")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchVM.query.count < 2 {
                VStack(spacing: 12) {
                    Image(systemName: "tv")
                        .font(.system(size: 36))
                        .foregroundColor(accentColor.opacity(0.5))
                    Text("Type to search for a TV show")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                    Text("Searches your guide and TMDB")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(searchVM.results) { result in
                            ShowSearchRow(result: result)
                                .onTapGesture {
                                    selectedShow = result
                                    withAnimation { phase = .configure }
                                }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Configure Phase

    private var configurePhase: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Selected show header
                if let show = selectedShow {
                    HStack(spacing: 14) {
                        if let posterPath = show.posterPath {
                            TMDBPosterImage(path: posterPath)
                                .frame(width: 56, height: 80)
                                .cornerRadius(8)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 56, height: 80)
                                .overlay(Image(systemName: "tv.fill").foregroundColor(accentColor))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(show.title)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            if let network = show.network {
                                Label(network, systemImage: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            if let date = show.firstAirDate {
                                Text("First aired: \(date)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(cardBg)
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }

                // Options card
                VStack(spacing: 0) {
                    OptionRow(label: "New episodes only") {
                        Toggle("", isOn: $newEpisodesOnly)
                            .tint(accentColor)
                            .labelsHidden()
                    }
                    Divider().background(Color.white.opacity(0.08))

                    OptionRow(label: "Start \(prePadding) min early") {
                        Stepper("", value: $prePadding, in: 0...30, step: 1)
                            .labelsHidden()
                    }
                    Divider().background(Color.white.opacity(0.08))

                    OptionRow(label: "End \(postPadding) min late") {
                        Stepper("", value: $postPadding, in: 0...120, step: 5)
                            .labelsHidden()
                    }
                    Divider().background(Color.white.opacity(0.08))

                    OptionRow(label: keepLabel) {
                        Picker("", selection: $keepCount) {
                            Text("All").tag(0)
                            Text("Last 3").tag(3)
                            Text("Last 5").tag(5)
                            Text("Last 10").tag(10)
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(accentColor)
                    }
                }
                .background(cardBg)
                .cornerRadius(14)
                .padding(.horizontal, 16)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                }

                // Create button
                Button(action: createPass) {
                    HStack {
                        if isCreating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Pass")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isCreating ? accentColor.opacity(0.5) : accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(isCreating)
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }

    private var keepLabel: String {
        keepCount == 0 ? "Keep: All episodes" : "Keep: Last \(keepCount)"
    }

    private func createPass() {
        guard let show = selectedShow else { return }
        isCreating = true
        errorMessage = nil

        Task {
            do {
                _ = try await OpenFlixAPI.shared.createSeriesRule(
                    title: show.title,
                    prePadding: prePadding,
                    postPadding: postPadding,
                    keepCount: keepCount
                )
                onCreated()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isCreating = false
            }
        }
    }
}

// MARK: - Supporting Components

private struct ShowSearchRow: View {
    let result: ShowSearchResult
    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)

    var body: some View {
        HStack(spacing: 12) {
            // Poster or icon
            if let posterPath = result.posterPath {
                TMDBPosterImage(path: posterPath)
                    .frame(width: 44, height: 64)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 64)
                    .overlay(Image(systemName: "tv.fill").foregroundColor(accentColor))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if let network = result.network {
                    Label(network, systemImage: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                if let date = result.firstAirDate, !date.isEmpty {
                    Text(date.prefix(4))
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                }

                Text(result.source == .tmdb ? "TMDB" : "On Guide")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(result.source == .tmdb ? .blue : .green)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background((result.source == .tmdb ? Color.blue : Color.green).opacity(0.15))
                    .cornerRadius(4)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
                .font(.system(size: 14))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(cardBg)
        .contentShape(Rectangle())
    }
}

private struct OptionRow<Content: View>: View {
    let label: String
    @ViewBuilder let trailing: Content

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white)
            Spacer()
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// Loads a TMDB poster thumbnail by path
private struct TMDBPosterImage: View {
    let path: String

    var body: some View {
        AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w92\(path)")) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFill()
            case .failure, .empty:
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .overlay(Image(systemName: "tv").foregroundColor(.gray))
            @unknown default:
                Rectangle().fill(Color.white.opacity(0.06))
            }
        }
        .clipped()
    }
}
