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

struct CreateSeriesPassSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCreated: () -> Void

    @State private var title = ""
    @State private var prePadding = 0
    @State private var postPadding = 0
    @State private var keepCount = 0
    @State private var isCreating = false
    @State private var errorMessage: String?

    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)

    var body: some View {
        NavigationStack {
            Form {
                Section("Show Title") {
                    TextField("e.g. Grey's Anatomy", text: $title)
                        .autocorrectionDisabled()
                }

                Section("Recording Padding") {
                    Stepper("Start \(prePadding) min early", value: $prePadding, in: 0...30, step: 1)
                    Stepper("End \(postPadding) min late", value: $postPadding, in: 0...120, step: 5)
                }

                Section("Keep") {
                    Picker("Keep", selection: $keepCount) {
                        Text("All episodes").tag(0)
                        Text("Last 3").tag(3)
                        Text("Last 5").tag(5)
                        Text("Last 10").tag(10)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                    }
                }
            }
            .navigationTitle("New Series Pass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPass()
                    }
                    .disabled(title.isEmpty || isCreating)
                    .bold()
                }
            }
        }
    }

    private func createPass() {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                _ = try await OpenFlixAPI.shared.createSeriesRule(
                    title: title,
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
