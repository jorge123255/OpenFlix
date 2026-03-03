import SwiftUI

// MARK: - DVR Passes List View

struct DVRPassesView: View {
    @ObservedObject var viewModel: DVRViewModel
    @State private var showCreateSheet = false
    @State private var editingPass: DVRPass? = nil
    @State private var searchText = ""

    private var filteredPasses: [DVRPass] {
        if searchText.isEmpty { return viewModel.dvrPasses }
        let q = searchText.lowercased()
        return viewModel.dvrPasses.filter {
            $0.name.lowercased().contains(q) ||
            ($0.league?.lowercased().contains(q) ?? false) ||
            ($0.teamName?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        Group {
            if viewModel.dvrPasses.isEmpty {
                ContentUnavailableView {
                    Label("No Recording Passes", systemImage: "tv.badge.wifi")
                } description: {
                    Text("Create a series rule to record shows automatically.")
                } actions: {
                    Button("Create Pass") { showCreateSheet = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(filteredPasses) { pass in
                        DVRPassRow(pass: pass, onToggle: {
                            Task { await viewModel.toggleDVRPass(pass) }
                        })
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                editingPass = pass
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.indigo)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteDVRPass(pass) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                Task { await viewModel.toggleDVRPass(pass) }
                            } label: {
                                Label(pass.paused ? "Resume" : "Pause",
                                      systemImage: pass.paused ? "play.fill" : "pause.fill")
                            }
                            .tint(pass.paused ? .green : .orange)
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search passes")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showCreateSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateDVRPassSheet(viewModel: viewModel)
        }
        .sheet(item: $editingPass) { pass in
            EditDVRPassSheet(pass: pass, viewModel: viewModel)
        }
        .task {
            await viewModel.loadDVRPasses()
        }
        .refreshable {
            await viewModel.loadDVRPasses()
        }
    }
}

// MARK: - Pass Row

struct DVRPassRow: View {
    let pass: DVRPass
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Group {
                if let imageURL = pass.image, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        passIcon
                    }
                } else {
                    passIcon
                }
            }
            .frame(width: 48, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .background(Color(.systemFill).clipShape(RoundedRectangle(cornerRadius: 6)))

            VStack(alignment: .leading, spacing: 4) {
                Text(pass.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(pass.typeLabel)
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(pass.type == "team" ? Color.orange.opacity(0.2) : Color.indigo.opacity(0.2))
                        .foregroundStyle(pass.type == "team" ? .orange : .indigo)
                        .clipShape(Capsule())

                    if pass.paused {
                        Text("Paused")
                            .font(.caption)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(.systemFill))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }

                    if let league = pass.league {
                        Text(league)
                            .font(.caption)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 10) {
                    Label("\(pass.numJobs) recording\(pass.numJobs == 1 ? "" : "s")", systemImage: "video")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(pass.keepLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if pass.rerecord {
                        Text("Re-record")
                            .font(.caption)
                            .foregroundStyle(.indigo)
                    }
                }

                // Tracker badge — "Season N premieres [date]"
                if let tracker = pass.tracker,
                   let season = tracker.nextSeasonNumber, season > 0,
                   let airDateStr = tracker.nextEpisodeAirDate, !airDateStr.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 10))
                        Text(trackerBadgeLabel(season: season, airDate: airDateStr))
                            .font(.caption2)
                    }
                    .foregroundStyle(.blue)
                }
            }

            Spacer()

            Button(action: onToggle) {
                Image(systemName: pass.paused ? "play.fill" : "pause.fill")
                    .foregroundStyle(pass.paused ? .green : .orange)
            }
            .buttonStyle(.plain)
        }
        .opacity(pass.paused ? 0.6 : 1)
        .padding(.vertical, 4)
    }

    private var passIcon: some View {
        Image(systemName: pass.type == "team" ? "trophy.fill" : "tv")
            .foregroundStyle(.secondary)
            .frame(width: 48, height: 64)
            .background(Color(.systemFill))
    }

    private func trackerBadgeLabel(season: Int, airDate: String) -> String {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = df.date(from: airDate) ?? ISO8601DateFormatter().date(from: airDate)
        if let date = date {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            return "Season \(season) · \(fmt.string(from: date))"
        }
        return "Season \(season) coming soon"
    }
}

// MARK: - Create Pass Sheet (TMDB-First Search)

struct CreateDVRPassSheet: View {
    @ObservedObject var viewModel: DVRViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var mediaType = "tv"
    @State private var results: [ShowSearchResult] = []
    @State private var isLoading = false
    @State private var isCreating = false
    @State private var debounceTask: Task<Void, Never>? = nil
    @State private var confirmingResult: ShowSearchResult? = nil
    @State private var newEpisodesOnly = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search shows & movies...", text: $searchText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: searchText) { _, newValue in
                            scheduleSearch(query: newValue)
                        }
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // TV / Movie toggle
                HStack(spacing: 8) {
                    ForEach(["tv", "movie"], id: \.self) { type in
                        Button {
                            mediaType = type
                            scheduleSearch(query: searchText)
                        } label: {
                            Label(type == "tv" ? "TV Shows" : "Movies",
                                  systemImage: type == "tv" ? "tv" : "film")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(mediaType == type ? Color.indigo : Color(.secondarySystemBackground))
                                .foregroundStyle(mediaType == type ? .white : .secondary)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                Divider()

                // Results grid
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if results.isEmpty && searchText.count >= 2 {
                    Spacer()
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("No \(mediaType == "tv" ? "shows" : "movies") match \"\(searchText)\"")
                    )
                    Spacer()
                } else if results.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "Search for a Show",
                        systemImage: "tv",
                        description: Text("Type a title to find something to record")
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 12)],
                            spacing: 16
                        ) {
                            ForEach(results) { result in
                                ShowPosterCard(result: result, isCreating: isCreating) {
                                    confirmingResult = result
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("New Recording Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $confirmingResult) { result in
                confirmSheet(result: result)
            }
        }
    }

    @ViewBuilder
    private func confirmSheet(result: ShowSearchResult) -> some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        if let url = result.posterUrl.flatMap(URL.init) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                } else {
                                    Color(.secondarySystemBackground)
                                }
                            }
                            .frame(width: 48, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title).font(.headline)
                            if let year = result.year { Text(String(year)).font(.caption).foregroundStyle(.secondary) }
                            if let airing = result.nextAiring {
                                Text(formatAiringShort(airing)).font(.caption).foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("New Episodes Only", isOn: $newEpisodesOnly)
                } footer: {
                    Text("Records only episodes marked as new by the guide. Turn off to record all episodes.")
                }
            }
            .navigationTitle("Record \(result.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { confirmingResult = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isCreating {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Button("Add Pass") {
                            createRule(for: result)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func formatAiringShort(_ airing: ShowNextAiring) -> String {
        guard let date = ISO8601DateFormatter().date(from: airing.start) else { return airing.channelName ?? "" }
        let df = DateFormatter(); df.dateFormat = "EEE MMM d"
        let day = df.string(from: date)
        return airing.channelName.map { "\(day) · \($0)" } ?? day
    }

    private func scheduleSearch(query: String) {
        debounceTask?.cancel()
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { results = []; return }
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query: q)
        }
    }

    @MainActor
    private func performSearch(query: String) async {
        isLoading = true
        do {
            results = try await OpenFlixAPI.shared.searchShowForPass(query: query, type: mediaType)
        } catch {
            results = []
        }
        isLoading = false
    }

    private func createRule(for result: ShowSearchResult) {
        guard !isCreating else { return }
        isCreating = true
        Task {
            var params: [String: Any] = [
                "Name": result.title,
                "KeepOnly": "",
                "KeepNum": 0,
                "PaddingStart": 0,
                "PaddingEnd": 0,
                "Rerecord": false
            ]
            if newEpisodesOnly { params["EQ"] = ["isNew": "true"] }
            if let poster = result.posterUrl { params["Image"] = poster }
            if let tmdbId = result.tmdbId { params["TmdbId"] = tmdbId }
            if let mt = result.mediaType { params["MediaType"] = mt }
            await viewModel.createDVRPassWithParams(params)
            isCreating = false
            confirmingResult = nil
            dismiss()
        }
    }
}

// MARK: - Show Poster Card

struct ShowPosterCard: View {
    let result: ShowSearchResult
    let isCreating: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Portrait poster
                ZStack {
                    if let posterUrl = result.posterUrl, let url = URL(string: posterUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            default:
                                posterPlaceholder
                            }
                        }
                    } else {
                        posterPlaceholder
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )

                // Title + year
                Text(result.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let year = result.year {
                    Text(String(year))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Next airing badge
                if let airing = result.nextAiring {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text(formatAiringLabel(airing))
                            .font(.system(size: 10))
                            .lineLimit(2)
                    }
                    .foregroundStyle(.blue)
                } else {
                    Text("Not in guide yet")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isCreating)
        .opacity(isCreating ? 0.5 : 1)
    }

    private var posterPlaceholder: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [Color.indigo.opacity(0.5), Color.purple.opacity(0.3)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .overlay(
                Image(systemName: result.mediaType == "movie" ? "film" : "tv")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.4))
            )
    }

    private func formatAiringLabel(_ airing: ShowNextAiring) -> String {
        guard let date = ISO8601DateFormatter().date(from: airing.start) else {
            return airing.channelName ?? ""
        }
        let df = DateFormatter()
        df.dateFormat = "EEE MMM d"
        let dayStr = df.string(from: date)
        if let ch = airing.channelName {
            return "\(dayStr) · \(ch)"
        }
        return dayStr
    }
}

// MARK: - Edit DVR Pass Sheet

struct EditDVRPassSheet: View {
    let pass: DVRPass
    @ObservedObject var viewModel: DVRViewModel
    @Environment(\.dismiss) private var dismiss

    // Simple tab state
    @State private var name: String
    @State private var newOnly: Bool       // EQ.Tags = "New"
    @State private var channelNumber: String
    @State private var paddingBefore: String  // minutes
    @State private var paddingAfter: String   // minutes
    @State private var keepOnly: String       // "" | "last" | "unwatched"
    @State private var keepNum: Int

    // Advanced tab state
    @State private var limit: Int
    @State private var rerecord: Bool
    @State private var conditions: [EditConditionRow]

    @State private var selectedTab = 0
    @State private var isSaving = false

    init(pass: DVRPass, viewModel: DVRViewModel) {
        self.pass = pass
        self.viewModel = viewModel
        _name = State(initialValue: pass.name)
        _newOnly = State(initialValue: false)   // resolved from EQ below via onAppear
        _channelNumber = State(initialValue: "")
        _paddingBefore = State(initialValue: String(pass.paddingStart / 60))
        _paddingAfter = State(initialValue: String(pass.paddingEnd / 60))
        _keepOnly = State(initialValue: pass.keepOnly)
        _keepNum = State(initialValue: max(pass.keepNum, 1))
        _limit = State(initialValue: pass.limit > 0 ? pass.limit : 0)
        _rerecord = State(initialValue: pass.rerecord)
        _conditions = State(initialValue: [])
    }

    private let keepOptions: [(label: String, value: String)] = [
        ("Keep All", ""),
        ("Last N Episodes", "last"),
        ("Unwatched Only", "unwatched")
    ]

    private let limitOptions = [0, 3, 5, 10, 20, 50, 100]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("", selection: $selectedTab) {
                    Text("Simple").tag(0)
                    Text("Advanced").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider()

                if selectedTab == 0 {
                    simpleTab
                } else {
                    advancedTab
                }
            }
            .navigationTitle(pass.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadFromPass() }
        }
    }

    // MARK: Simple Tab

    private var simpleTab: some View {
        Form {
            Section("Recording") {
                Toggle("New Episodes Only", isOn: $newOnly)

                HStack {
                    Text("Channel")
                    Spacer()
                    TextField("Any", text: $channelNumber)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }

            Section("Padding") {
                HStack {
                    Text("Before")
                    Spacer()
                    TextField("0", text: $paddingBefore)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("min").foregroundStyle(.secondary)
                }
                HStack {
                    Text("After")
                    Spacer()
                    TextField("0", text: $paddingAfter)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("min").foregroundStyle(.secondary)
                }
            }

            Section("Keep") {
                Picker("Keep", selection: $keepOnly) {
                    ForEach(keepOptions, id: \.value) { opt in
                        Text(opt.label).tag(opt.value)
                    }
                }
                .pickerStyle(.menu)

                if keepOnly == "last" || keepOnly == "unwatched" {
                    Stepper("Count: \(keepNum)", value: $keepNum, in: 1...100)
                }
            }
        }
    }

    // MARK: Advanced Tab

    private var advancedTab: some View {
        Form {
            Section("Name") {
                TextField("Rule name", text: $name)
            }

            Section("Limits") {
                Picker("Max Recordings", selection: $limit) {
                    Text("No limit").tag(0)
                    ForEach([3, 5, 10, 20, 50, 100], id: \.self) { n in
                        Text("\(n) max").tag(n)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Re-record Deleted Episodes", isOn: $rerecord)
            }

            Section {
                ForEach(conditions.indices, id: \.self) { i in
                    ConditionRowView(row: $conditions[i])
                }
                .onDelete { conditions.remove(atOffsets: $0) }

                Button {
                    conditions.append(EditConditionRow(key: "Title", type: "EQ", value: ""))
                } label: {
                    Label("Add Condition", systemImage: "plus.circle")
                }
            } header: {
                Text("Conditions")
            } footer: {
                Text("Conditions are ANDed together. Use Title EQ for exact match.")
                    .font(.caption)
            }
        }
    }

    // MARK: Helpers

    private func loadFromPass() {
        // Resolve "New Episodes Only" from EQ.Tags == "New"
        newOnly = pass.eq?["Tags"] == "New"

        // Resolve channel from IN.Channel
        channelNumber = pass.inMap?["Channel"] ?? ""

        // Flatten remaining conditions into EditConditionRow array
        var rows: [EditConditionRow] = []
        let maps: [(String, [String: String]?)] = [
            ("EQ", pass.eq), ("NE", pass.ne), ("IN", pass.inMap),
            ("NI", pass.ni), ("GT", pass.gt), ("LT", pass.lt)
        ]
        for (opType, map) in maps {
            guard let map = map else { continue }
            for (key, value) in map {
                // Skip entries already surfaced in Simple tab
                if opType == "EQ" && key == "Tags" && value == "New" { continue }
                if opType == "IN" && key == "Channel" { continue }
                rows.append(EditConditionRow(key: key, type: opType, value: value))
            }
        }
        conditions = rows
    }

    private func save() {
        isSaving = true
        var params: [String: Any] = [
            "Name": name.trimmingCharacters(in: .whitespaces),
            "PaddingStart": (Int(paddingBefore) ?? 0) * 60,
            "PaddingEnd": (Int(paddingAfter) ?? 0) * 60,
            "KeepOnly": keepOnly,
            "KeepNum": keepNum,
            "Limit": limit,
            "Rerecord": rerecord
        ]

        // Build EQ/NE/IN/NI condition maps from advanced conditions
        var eqMap: [String: Any] = [:]
        var neMap: [String: Any] = [:]
        var inMap: [String: Any] = [:]
        var niMap: [String: Any] = [:]
        var ltMap: [String: Any] = [:]
        var gtMap: [String: Any] = [:]

        if newOnly { eqMap["Tags"] = "New" }
        if !channelNumber.trimmingCharacters(in: .whitespaces).isEmpty {
            inMap["Channel"] = channelNumber.trimmingCharacters(in: .whitespaces)
        }

        for c in conditions where !c.value.trimmingCharacters(in: .whitespaces).isEmpty {
            let v = c.value.trimmingCharacters(in: .whitespaces)
            switch c.type {
            case "EQ": eqMap[c.key] = v
            case "NE": neMap[c.key] = v
            case "IN": inMap[c.key] = v
            case "NI": niMap[c.key] = v
            case "LT": ltMap[c.key] = v
            case "GT": gtMap[c.key] = v
            default: break
            }
        }

        if !eqMap.isEmpty { params["EQ"] = eqMap }
        if !neMap.isEmpty { params["NE"] = neMap }
        if !inMap.isEmpty { params["IN"] = inMap }
        if !niMap.isEmpty { params["NI"] = niMap }
        if !ltMap.isEmpty { params["LT"] = ltMap }
        if !gtMap.isEmpty { params["GT"] = gtMap }

        Task {
            await viewModel.updateDVRPassWithParams(pass, params: params)
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Condition Row

struct EditConditionRow: Identifiable {
    let id = UUID()
    var key: String
    var type: String
    var value: String
}

private struct ConditionRowView: View {
    @Binding var row: EditConditionRow

    private let keys = ["Title", "Channel", "EpisodeTitle", "EventTitle", "Tags",
                        "Categories", "Genres", "Duration", "SeasonNumber",
                        "EpisodeNumber", "Directors", "Cast", "Summary"]
    private let types = ["EQ", "NE", "IN", "NI", "LT", "GT"]
    private let typeLabels = ["==", "!=", "contains", "excludes", "<", ">"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Picker("Field", selection: $row.key) {
                    ForEach(keys, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Picker("Type", selection: $row.type) {
                    ForEach(Array(zip(types, typeLabels)), id: \.0) { t, label in
                        Text(label).tag(t)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 90)
            }
            TextField("Value", text: $row.value)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
        }
        .padding(.vertical, 2)
    }
}
