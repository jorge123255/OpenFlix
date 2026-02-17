import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    @State private var showSources = false
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            List {
                // Server Section
                Section("Server") {
                    if let info = settingsViewModel.serverInfo {
                        HStack {
                            Text("Server Name")
                            Spacer()
                            Text(info.name)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Version")
                            Spacer()
                            Text(info.version)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let url = UserDefaults.standard.serverURL {
                        HStack {
                            Text("Server URL")
                            Spacer()
                            Text(url.host ?? url.absoluteString)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Profile Section
                Section("Profile") {
                    if let profile = authViewModel.currentProfile {
                        HStack {
                            Text("Current Profile")
                            Spacer()
                            Text(profile.name)
                                .foregroundColor(.secondary)
                        }

                        Button("Switch Profile") {
                            authViewModel.clearProfile()
                        }
                    }
                }

                // Library Section
                Section("Library") {
                    NavigationLink(destination: WatchlistView()) {
                        HStack {
                            Image(systemName: "bookmark.fill")
                            Text("Watchlist")
                        }
                    }

                    NavigationLink(destination: PlaylistsView()) {
                        HStack {
                            Image(systemName: "music.note.list")
                            Text("Playlists")
                        }
                    }
                    
                    NavigationLink(destination: WatchStatsView()) {
                        HStack {
                            Image(systemName: "chart.bar.xaxis")
                            Text("Watch Stats")
                        }
                    }
                }

                // Sources Section
                Section("Sources") {
                    NavigationLink(destination: SourcesView()) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("Manage Sources")
                            Spacer()
                            Text("\(settingsViewModel.totalChannelCount) channels")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Playback Section
                Section("Playback") {
                    Toggle("Auto-Play Next Episode", isOn: $settingsViewModel.autoPlayNext)

                    Toggle("Skip Intros", isOn: $settingsViewModel.skipIntros)

                    Toggle("Skip Credits", isOn: $settingsViewModel.skipCredits)

                    Toggle("Show Subtitles", isOn: $settingsViewModel.showSubtitles)
                }

                // DVR Section
                if settingsViewModel.hasDVR {
                    Section("DVR") {
                        Toggle("Commercial Skip", isOn: $settingsViewModel.commercialSkipEnabled)
                    }
                }

                // Live TV Section
                if settingsViewModel.hasLiveTV {
                    Section("Live TV") {
                        Toggle("Channel Surfing", isOn: $settingsViewModel.channelSurfingEnabled)

                        Picker("EPG Days to Load", selection: $settingsViewModel.epgDaysToLoad) {
                            Text("1 Day").tag(1)
                            Text("3 Days").tag(3)
                            Text("7 Days").tag(7)
                            Text("14 Days").tag(14)
                        }
                    }
                }

                // Display Section
                Section("Display") {
                    Toggle("Screensaver", isOn: $settingsViewModel.screensaverEnabled)

                    if settingsViewModel.screensaverEnabled {
                        Picker("Screensaver Delay", selection: $settingsViewModel.screensaverDelay) {
                            Text("2 Minutes").tag(120)
                            Text("5 Minutes").tag(300)
                            Text("10 Minutes").tag(600)
                            Text("15 Minutes").tag(900)
                        }
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("\(settingsViewModel.appVersion) (\(settingsViewModel.buildNumber))")
                            .foregroundColor(.secondary)
                    }

                    if let caps = settingsViewModel.capabilities {
                        HStack {
                            Text("Capabilities")
                            Spacer()
                            HStack(spacing: 8) {
                                if caps.liveTV {
                                    capabilityBadge("Live TV")
                                }
                                if caps.dvr {
                                    capabilityBadge("DVR")
                                }
                                if caps.transcoding {
                                    capabilityBadge("Transcode")
                                }
                            }
                        }
                    }
                }

                // Account Section
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .task {
            await settingsViewModel.loadServerInfo()
            await settingsViewModel.loadSources()
        }
        .confirmationDialog("Sign Out", isPresented: $showLogoutConfirm) {
            Button("Sign Out", role: .destructive) {
                Task { await authViewModel.logout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private func capabilityBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(4)
    }
}

struct SourcesView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    @State private var showAddM3U = false
    @State private var showAddXtream = false
    @State private var selectedTab = SourceTab.m3u

    enum SourceTab: String, CaseIterable {
        case m3u = "M3U"
        case xtream = "Xtream"
        case epg = "EPG"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Source Type", selection: $selectedTab) {
                ForEach(SourceTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            switch selectedTab {
            case .m3u:
                m3uSourcesList
            case .xtream:
                xtreamSourcesList
            case .epg:
                epgSourcesList
            }
        }
        .navigationTitle("Sources")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showAddM3U = true }) {
                        Label("Add M3U Source", systemImage: "list.bullet")
                    }
                    Button(action: { showAddXtream = true }) {
                        Label("Add Xtream Source", systemImage: "server.rack")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddM3U) {
            AddM3USourceView()
        }
        .sheet(isPresented: $showAddXtream) {
            AddXtreamSourceView()
        }
    }

    private var m3uSourcesList: some View {
        List {
            ForEach(settingsViewModel.m3uSources) { source in
                M3USourceRow(source: source) {
                    Task { try? await settingsViewModel.refreshM3USource(source) }
                } onDelete: {
                    Task { try? await settingsViewModel.deleteM3USource(source) }
                }
            }
        }
    }

    private var xtreamSourcesList: some View {
        List {
            ForEach(settingsViewModel.xtreamSources) { source in
                XtreamSourceRow(source: source) {
                    Task { try? await settingsViewModel.refreshXtreamSource(source) }
                } onTest: {
                    Task { _ = await settingsViewModel.testXtreamSource(source) }
                } onDelete: {
                    Task { try? await settingsViewModel.deleteXtreamSource(source) }
                }
            }
        }
    }

    private var epgSourcesList: some View {
        List {
            ForEach(settingsViewModel.epgSources) { source in
                EPGSourceRow(source: source) {
                    Task { try? await settingsViewModel.refreshEPGSource(source) }
                } onDelete: {
                    Task { try? await settingsViewModel.deleteEPGSource(source) }
                }
            }
        }
    }
}

struct M3USourceRow: View {
    let source: M3USource
    var onRefresh: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.headline)

                Text("\(source.channelCount) channels")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let lastFetched = source.lastFetched {
                    Text("Updated \(lastFetched, formatter: relativeDateFormatter)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if !source.enabled {
                Text("Disabled")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
        }
        .contextMenu {
            Button(action: onRefresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct XtreamSourceRow: View {
    let source: XtreamSource
    var onRefresh: () -> Void
    var onTest: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.headline)

                Text("\(source.channelCount) channels")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let expiration = source.expirationDate {
                    if source.isExpired {
                        Text("Expired")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if let days = source.expiresInDays, days <= 30 {
                        Text("Expires in \(days) days")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            if !source.enabled {
                Text("Disabled")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
        }
        .contextMenu {
            Button(action: onTest) {
                Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
            }
            Button(action: onRefresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct EPGSourceRow: View {
    let source: EPGSource
    var onRefresh: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.headline)

                HStack {
                    Text(source.type.displayName)
                    Text("\(source.channelCount) channels")
                    Text("\(source.programCount) programs")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            if !source.enabled {
                Text("Disabled")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
        }
        .contextMenu {
            Button(action: onRefresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct AddM3USourceView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var url = ""
    @State private var epgUrl = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("M3U URL", text: $url)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                TextField("EPG URL (optional)", text: $epgUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)

                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Add M3U Source")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addSource()
                    }
                    .disabled(name.isEmpty || url.isEmpty || isLoading)
                }
            }
        }
    }

    private func addSource() {
        isLoading = true
        Task {
            do {
                try await settingsViewModel.addM3USource(
                    name: name,
                    url: url,
                    epgUrl: epgUrl.isEmpty ? nil : epgUrl
                )
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct AddXtreamSourceView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var serverUrl = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Server URL", text: $serverUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                SecureField("Password", text: $password)

                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Add Xtream Source")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addSource()
                    }
                    .disabled(name.isEmpty || serverUrl.isEmpty || username.isEmpty || password.isEmpty || isLoading)
                }
            }
        }
    }

    private func addSource() {
        isLoading = true
        Task {
            do {
                try await settingsViewModel.addXtreamSource(
                    name: name,
                    serverUrl: serverUrl,
                    username: username,
                    password: password
                )
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter
}()

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
        .environmentObject(SettingsViewModel())
}
