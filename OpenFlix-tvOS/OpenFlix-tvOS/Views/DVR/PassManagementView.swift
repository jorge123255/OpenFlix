import SwiftUI

// MARK: - Pass Management View (tvOS)
// Lists series rules (passes). Tapping a pass shows detail / edit options.

struct TVPassManagementView: View {
    @StateObject private var viewModel = TVPassManagementViewModel()
    @State private var showCreatePass = false
    @State private var selectedRule: SeriesRule?
    @State private var ruleToDelete: SeriesRule?

    private let bg = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            if viewModel.isLoading && viewModel.rules.isEmpty {
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Loading passes...").foregroundColor(.gray)
                }
            } else if viewModel.rules.isEmpty {
                emptyState
            } else {
                rulesContent
            }
        }
        .task { await viewModel.loadRules() }
        .fullScreenCover(isPresented: $showCreatePass) {
            TVCreatePassView(onCreated: {
                showCreatePass = false
                Task { await viewModel.loadRules() }
            }, onDismiss: {
                showCreatePass = false
            })
        }
        .alert("Delete Pass?", isPresented: .constant(ruleToDelete != nil)) {
            Button("Delete", role: .destructive) {
                if let rule = ruleToDelete {
                    Task {
                        await viewModel.deleteRule(rule)
                        ruleToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) { ruleToDelete = nil }
        } message: {
            if let rule = ruleToDelete {
                Text("Remove \"\(rule.title)\"? Future episodes won't be recorded.")
            }
        }
    }

    // MARK: - Rules Content

    private var rulesContent: some View {
        HStack(spacing: 0) {
            // Sidebar: stats + add
            VStack(alignment: .leading, spacing: 24) {
                Text("Series Passes")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)

                // Stats
                VStack(spacing: 12) {
                    statRow("Active", value: viewModel.rules.filter(\.enabled).count, color: .green)
                    statRow("Paused", value: viewModel.rules.filter { !$0.enabled }.count, color: .orange)
                    statRow("Total recordings", value: viewModel.rules.map(\.recordingCount).reduce(0, +), color: accentColor)
                }

                Divider().background(Color.white.opacity(0.1))

                Button {
                    showCreatePass = true
                } label: {
                    Label("Create Pass", systemImage: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accentColor)
                        .cornerRadius(12)
                }
                .buttonStyle(.card)

                Spacer()
            }
            .padding(.horizontal, 40)
            .frame(width: 380)

            Divider().background(Color.white.opacity(0.1))

            // Pass list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.rules) { rule in
                        TVPassRow(
                            rule: rule,
                            accentColor: accentColor,
                            cardBg: cardBg,
                            onToggle: { Task { await viewModel.toggleRule(rule) } },
                            onDelete: { ruleToDelete = rule }
                        )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
            }
        }
    }

    private func statRow(_ label: String, value: Int, color: Color) -> some View {
        HStack {
            Text(label).font(.system(size: 18)).foregroundColor(.gray)
            Spacer()
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(cardBg)
        .cornerRadius(10)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Series Passes")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)

            Text("Create a pass to automatically record every new episode of a series.")
                .font(.system(size: 20))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)

            Button {
                showCreatePass = true
            } label: {
                Label("Create First Pass", systemImage: "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 20)
                    .background(accentColor)
                    .cornerRadius(14)
            }
            .buttonStyle(.card)
        }
    }
}

// MARK: - Pass Row

private struct TVPassRow: View {
    let rule: SeriesRule
    let accentColor: Color
    let cardBg: Color
    let onToggle: () -> Void
    let onDelete: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 20) {
            // Status indicator
            Circle()
                .fill(rule.enabled ? Color.green : Color.orange)
                .frame(width: 12, height: 12)

            // Icon
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 32))
                .foregroundColor(rule.enabled ? accentColor : .gray)
                .frame(width: 48)

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(rule.title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 16) {
                    if !rule.enabled {
                        Text("PAUSED")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(4)
                    }

                    Text("\(rule.recordingCount) recordings")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)

                    if rule.keepCount > 0 {
                        Text("Keep \(rule.keepCount)")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: rule.enabled ? "pause.circle" : "play.circle")
                        .font(.system(size: 28))
                        .foregroundColor(rule.enabled ? .orange : .green)
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(isFocused ? Color.white.opacity(0.12) : cardBg)
        .cornerRadius(14)
        .focused($isFocused)
    }
}

// MARK: - Create Pass View

struct TVCreatePassView: View {
    let onCreated: () -> Void
    let onDismiss: () -> Void

    @StateObject private var searchVM = TVPassShowSearchViewModel()
    @State private var showTitle = ""
    @State private var options = SeriesPassOptions()
    @State private var phase: CreatePhase = .search

    private let bg = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)

    enum CreatePhase { case search, configure }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            switch phase {
            case .search:
                searchPhase
            case .configure:
                configurePhase
            }
        }
    }

    // MARK: - Search Phase

    private var searchPhase: some View {
        HStack(spacing: 80) {
            // Left
            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    Circle().fill(accentColor.opacity(0.2)).frame(width: 100, height: 100)
                    Image(systemName: "magnifyingglass").font(.system(size: 48)).foregroundColor(accentColor)
                }

                Text("New Series Pass")
                    .font(.system(size: 48, weight: .bold)).foregroundColor(.white)

                Text("Search for a show or movie to automatically record new episodes.")
                    .font(.system(size: 18)).foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
                Button("Cancel", action: onDismiss).buttonStyle(TVSecondaryButtonStyle())
            }
            .frame(maxWidth: 480)

            // Right: search
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search shows...", text: $searchVM.query)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }
                .padding(16)
                .background(cardBg)
                .cornerRadius(12)

                if searchVM.isLoading {
                    ProgressView().tint(.white)
                } else if !searchVM.results.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(searchVM.results, id: \.self) { title in
                                Button {
                                    showTitle = title
                                    phase = .configure
                                } label: {
                                    HStack {
                                        Text(title)
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                    .background(cardBg)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.card)
                            }
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(80)
        .onChange(of: searchVM.query) { _ in
            searchVM.search()
        }
    }

    // MARK: - Configure Phase

    private var configurePhase: some View {
        HStack(spacing: 80) {
            // Left
            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    Circle().fill(accentColor.opacity(0.2)).frame(width: 100, height: 100)
                    Image(systemName: "calendar.badge.plus").font(.system(size: 48)).foregroundColor(accentColor)
                }

                Text("Configure Pass")
                    .font(.system(size: 48, weight: .bold)).foregroundColor(.white)

                Text(showTitle)
                    .font(.system(size: 28)).foregroundColor(accentColor)

                Spacer()

                HStack(spacing: 16) {
                    Button("Back") { phase = .search }
                        .buttonStyle(TVSecondaryButtonStyle())
                    Button("Cancel", action: onDismiss)
                        .buttonStyle(TVSecondaryButtonStyle())
                }
            }
            .frame(maxWidth: 480)

            // Right: options
            VStack(spacing: 16) {
                optRow("Record") {
                    Picker("Record", selection: $options.recordMode) {
                        ForEach(SeriesPassOptions.RecordMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.menu).tint(accentColor)
                }
                optRow("Keep") {
                    Picker("Keep", selection: $options.keepMode) {
                        ForEach(SeriesPassOptions.KeepMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.menu).tint(accentColor)
                }
                optRow("Start Recording") {
                    Picker("Start", selection: $options.startRecording) {
                        ForEach(SeriesPassOptions.PaddingOption.startOptions, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.menu).tint(accentColor)
                }
                optRow("End Recording") {
                    Picker("End", selection: $options.endRecording) {
                        ForEach(SeriesPassOptions.PaddingOption.endOptions, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.menu).tint(accentColor)
                }

                Spacer()

                Button {
                    Task { await createPass() }
                } label: {
                    Label("Create Pass", systemImage: "calendar.badge.plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(accentColor)
                        .cornerRadius(14)
                }
                .buttonStyle(.card)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(80)
    }

    @ViewBuilder
    private func optRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label).font(.system(size: 20, weight: .medium)).foregroundColor(.white)
            Spacer()
            content()
        }
        .padding(.horizontal, 20).padding(.vertical, 16)
        .background(cardBg).cornerRadius(10)
    }

    private func createPass() async {
        let api = OpenFlixAPI.shared
        struct PassBody: Encodable {
            let Name: String
            let EQ: [String: String]?
        }

        let eq: [String: String] = options.recordMode == .newEpisodes ? ["Tags": "New"] : [:]
        let body = PassBody(Name: showTitle, EQ: eq.isEmpty ? nil : eq)

        do {
            let _: EmptyResponse = try await api.request(.createPass(body: body))
            onCreated()
        } catch {
            // Silently log — user can retry
        }
    }
}

private struct EmptyResponse: Decodable {}

// MARK: - Show Search ViewModel

@MainActor
class TVPassShowSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [String] = []
    @Published var isLoading = false

    private var searchTask: Task<Void, Never>?

    func search() {
        searchTask?.cancel()
        guard query.count >= 2 else {
            results = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            isLoading = true

            // Search from EPG programs
            let liveTVRepo = LiveTVRepository()
            do {
                try await liveTVRepo.loadChannels()
                let guide = try await liveTVRepo.getGuide()
                let q = query.lowercased()
                var found = Set<String>()
                for cwp in guide {
                    for program in cwp.programs {
                        if program.title.lowercased().contains(q) {
                            found.insert(program.title)
                        }
                        if found.count >= 30 { break }
                    }
                    if found.count >= 30 { break }
                }
                results = Array(found).sorted()
            } catch {
                results = []
            }

            isLoading = false
        }
    }
}

// MARK: - Pass Management ViewModel

@MainActor
class TVPassManagementViewModel: ObservableObject {
    @Published var rules: [SeriesRule] = []
    @Published var isLoading = false
    @Published var error: String?

    private let api = OpenFlixAPI.shared

    func loadRules() async {
        isLoading = true
        defer { isLoading = false }

        struct PassesResponse: Decodable {
            let rules: [SeriesRuleDTO]?
            let passes: [SeriesRuleDTO]?

            var allRules: [SeriesRuleDTO] { rules ?? passes ?? [] }
        }

        do {
            let response: PassesResponse = try await api.request(.getPasses)
            rules = response.allRules.map { $0.toDomain() }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleRule(_ rule: SeriesRule) async {
        let endpoint: APIEndpoint = rule.enabled
            ? .pausePass(id: rule.id)
            : .resumePass(id: rule.id)
        do {
            let _: EmptyResponse = try await api.request(endpoint)
            await loadRules()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteRule(_ rule: SeriesRule) async {
        do {
            let _: EmptyResponse = try await api.request(.deletePass(id: rule.id))
            rules.removeAll { $0.id == rule.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
