import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    @State private var showSources = false
    @State private var showLogoutConfirm = false
    @State private var showClaimTokenCopied = false

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

                // Invite Section
                Section {
                    if let link = settingsViewModel.inviteDeepLink, let token = settingsViewModel.inviteToken {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Invite Code")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack {
                                Text(token)
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .tracking(4)
                                Spacer()
                                ShareLink(item: link) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.blue)
                                }
                                Button {
                                    UIPasteboard.general.string = link
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                }
                            }
                            if let exp = settingsViewModel.inviteExpiresAt {
                                Text("Expires \(exp.formatted(.relative(presentation: .named)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        Task { await settingsViewModel.generateInvite() }
                    } label: {
                        HStack {
                            if settingsViewModel.isGeneratingInvite {
                                ProgressView().scaleEffect(0.8)
                                Text("Creating invite...")
                            } else {
                                Image(systemName: "person.badge.plus")
                                Text(settingsViewModel.inviteToken == nil ? "Invite Family or Friend" : "New Invite Link")
                            }
                        }
                    }
                    .disabled(settingsViewModel.isGeneratingInvite)
                } header: {
                    Text("Share with Family & Friends")
                } footer: {
                    Text("Send an invite link to someone. They'll create their own account on your server and can stream from anywhere.")
                }

                // Away from Home Section
                Section {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Away from Home")
                                .font(.headline)
                            Text("Connect to your server from anywhere")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)

                    if settingsViewModel.claimTokenActive, let token = settingsViewModel.claimToken {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("New Device Code")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack {
                                Text(token)
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .tracking(8)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = token
                                    showClaimTokenCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showClaimTokenCopied = false
                                    }
                                } label: {
                                    Image(systemName: showClaimTokenCopied ? "checkmark" : "doc.on.doc")
                                        .foregroundColor(showClaimTokenCopied ? .green : .blue)
                                }
                            }
                            if let expiresIn = settingsViewModel.claimTokenExpiresIn {
                                Text("Expires in \(Int(expiresIn / 60)) min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("Enter this code in the OpenFlix app on your new device")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        Task { await settingsViewModel.generateNewClaimToken() }
                    } label: {
                        HStack {
                            if settingsViewModel.isGeneratingToken {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Generating...")
                            } else {
                                Image(systemName: "plus.circle")
                                Text(settingsViewModel.claimTokenActive ? "Generate New Code" : "Generate Access Code")
                            }
                        }
                    }
                    .disabled(settingsViewModel.isGeneratingToken)
                } header: {
                    Text("Remote Access")
                } footer: {
                    Text("Generate a one-time code to add a new device. Codes expire after 10 minutes.")
                }
                .task {
                    await settingsViewModel.loadClaimToken()
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

                        // ONNX AI Detection
                        Toggle(isOn: $settingsViewModel.onnxDetectionEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Label("ONNX AI Detection", systemImage: "cpu")
                                Text("Neural network for more accurate commercial detection")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // AcoustID Intro Detection
                        Toggle(isOn: $settingsViewModel.acoustidEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Label("Audio Fingerprint Intro Detection", systemImage: "waveform")
                                Text("Find episode intros by comparing audio across episodes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Live TV Section
                if settingsViewModel.hasLiveTV {
                    Section("Live TV") {
                        NavigationLink(destination: ChannelEditorView()) {
                            HStack {
                                Image(systemName: "pencil.and.list.clipboard")
                                Text("Channel Editor")
                            }
                        }

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

// MARK: - Sources View

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
        .task {
            await settingsViewModel.loadLibraries()
        }
    }

    private var m3uSourcesList: some View {
        List {
            ForEach(settingsViewModel.m3uSources) { source in
                M3USourceRow(
                    source: source,
                    libraries: settingsViewModel.libraries,
                    onRefresh: {
                        Task { try? await settingsViewModel.refreshM3USource(source) }
                    },
                    onDelete: {
                        Task { try? await settingsViewModel.deleteM3USource(source) }
                    },
                    onImportVOD: { libraryId in
                        Task { try? await settingsViewModel.importM3UVOD(sourceId: source.id, libraryId: libraryId) }
                    },
                    onImportSeries: { libraryId in
                        Task { try? await settingsViewModel.importM3USeries(sourceId: source.id, libraryId: libraryId) }
                    },
                    onToggleEnabled: { enabled in
                        Task { try? await settingsViewModel.updateM3USource(id: source.id, name: nil, url: nil, epgUrl: nil, enabled: enabled) }
                    },
                    onEdit: { name, url, epgUrl in
                        Task { try? await settingsViewModel.updateM3USource(id: source.id, name: name, url: url, epgUrl: epgUrl, enabled: nil) }
                    }
                )
            }
        }
    }

    private var xtreamSourcesList: some View {
        List {
            ForEach(settingsViewModel.xtreamSources) { source in
                XtreamSourceRow(
                    source: source,
                    libraries: settingsViewModel.libraries,
                    onRefresh: {
                        Task { try? await settingsViewModel.refreshXtreamSource(source) }
                    },
                    onTest: {
                        Task { _ = await settingsViewModel.testXtreamSource(source) }
                    },
                    onDelete: {
                        Task { try? await settingsViewModel.deleteXtreamSource(source) }
                    },
                    onImportVOD: {
                        Task { try? await settingsViewModel.importXtreamVOD(sourceId: source.id) }
                    },
                    onImportSeries: {
                        Task { try? await settingsViewModel.importXtreamSeries(sourceId: source.id) }
                    },
                    onToggleEnabled: { enabled in
                        Task { try? await settingsViewModel.updateXtreamSource(id: source.id, name: nil, enabled: enabled, importLive: nil, importVod: nil, importSeries: nil) }
                    },
                    onEdit: { name, enabled, importLive, importVod, importSeries in
                        Task { try? await settingsViewModel.updateXtreamSource(id: source.id, name: name, enabled: enabled, importLive: importLive, importVod: importVod, importSeries: importSeries) }
                    }
                )
            }
        }
    }

    @State private var showAddEPG = false

    private var epgSourcesList: some View {
        List {
            ForEach(settingsViewModel.epgSources) { source in
                EPGSourceRow(source: source) {
                    Task { try? await settingsViewModel.refreshEPGSource(source) }
                } onDelete: {
                    Task { try? await settingsViewModel.deleteEPGSource(source) }
                }
            }

            Button {
                showAddEPG = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.purple)
                    Text("Add EPG Source")
                        .foregroundColor(.purple)
                }
            }
        }
        .sheet(isPresented: $showAddEPG) {
            AddEPGSourceView()
                .environmentObject(settingsViewModel)
        }
    }
}

// MARK: - M3U Source Row (Enhanced)

struct M3USourceRow: View {
    let source: M3USource
    let libraries: [SettingsViewModel.LibraryPickerItem]
    var onRefresh: () -> Void
    var onDelete: () -> Void
    var onImportVOD: (String) -> Void
    var onImportSeries: (String) -> Void
    var onToggleEnabled: (Bool) -> Void
    var onEdit: (String?, String?, String?) -> Void

    @State private var showEdit = false
    @State private var showImportVOD = false
    @State private var showImportSeries = false
    @State private var selectedLibrary: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(source.name)
                            .font(.headline)
                        if !source.enabled {
                            Text("OFF")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(3)
                        }
                    }

                    HStack(spacing: 8) {
                        Label("\(source.channelCount)", systemImage: "tv")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let lastFetched = source.lastFetched {
                        Text("Updated \(lastFetched, formatter: relativeDateFormatter)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }

            // Import buttons
            HStack(spacing: 8) {
                Button {
                    if let first = libraries.first {
                        selectedLibrary = first.id
                    }
                    showImportVOD = true
                } label: {
                    Label("Import VOD", systemImage: "film")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Button {
                    if let first = libraries.first {
                        selectedLibrary = first.id
                    }
                    showImportSeries = true
                } label: {
                    Label("Import Series", systemImage: "tv")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
        .contextMenu {
            Button(action: { showEdit = true }) {
                Label("Edit", systemImage: "pencil")
            }
            Toggle("Enabled", isOn: Binding(
                get: { source.enabled },
                set: { onToggleEnabled($0) }
            ))
            Button(action: onRefresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showEdit) {
            EditM3USourceView(source: source, onSave: onEdit)
        }
        .alert("Import VOD", isPresented: $showImportVOD) {
            ForEach(libraries, id: \.id) { lib in
                Button(lib.name) {
                    onImportVOD(lib.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select a library for VOD import")
        }
        .alert("Import Series", isPresented: $showImportSeries) {
            ForEach(libraries, id: \.id) { lib in
                Button(lib.name) {
                    onImportSeries(lib.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select a library for Series import")
        }
    }
}

// MARK: - Xtream Source Row (Enhanced)

struct XtreamSourceRow: View {
    let source: XtreamSource
    let libraries: [SettingsViewModel.LibraryPickerItem]
    var onRefresh: () -> Void
    var onTest: () -> Void
    var onDelete: () -> Void
    var onImportVOD: () -> Void
    var onImportSeries: () -> Void
    var onToggleEnabled: (Bool) -> Void
    var onEdit: (String?, Bool?, Bool?, Bool?, Bool?) -> Void

    @State private var showEdit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(source.name)
                            .font(.headline)
                        if !source.enabled {
                            Text("OFF")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(3)
                        }
                    }

                    HStack(spacing: 8) {
                        Label("\(source.channelCount)", systemImage: "tv")
                        if source.vodCount > 0 {
                            Label("\(source.vodCount)", systemImage: "film")
                        }
                        if source.seriesCount > 0 {
                            Label("\(source.seriesCount)", systemImage: "tv.and.mediabox")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if source.expirationDate != nil {
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

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }

            // Action buttons
            HStack(spacing: 8) {
                Button(action: onTest) {
                    Label("Test", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Button(action: onImportVOD) {
                    Label("Import VOD", systemImage: "film")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Button(action: onImportSeries) {
                    Label("Import Series", systemImage: "tv")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
        .contextMenu {
            Button(action: { showEdit = true }) {
                Label("Edit", systemImage: "pencil")
            }
            Toggle("Enabled", isOn: Binding(
                get: { source.enabled },
                set: { onToggleEnabled($0) }
            ))
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
        .sheet(isPresented: $showEdit) {
            EditXtreamSourceView(source: source, onSave: onEdit)
        }
    }
}

// MARK: - EPG Source Row

struct EPGSourceRow: View {
    let source: EPGSource
    var onRefresh: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(source.name)
                            .font(.headline)
                        Text(source.type.displayName)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(source.type == .tvguide ? .purple : .blue)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background((source.type == .tvguide ? Color.purple : Color.blue).opacity(0.15))
                            .cornerRadius(3)
                    }

                    HStack(spacing: 12) {
                        Label("\(source.channelCount)", systemImage: "tv")
                        Label("\(source.programCount)", systemImage: "doc.text")
                    }
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
                    Text("OFF")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(3)
                }

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }

            // Action bar
            HStack(spacing: 8) {
                if source.type == .tvguide, let zip = source.tvguideZipCode {
                    Text("📍 \(zip)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if let days = source.tvguideDays, source.type == .tvguide {
                    Text("\(days) days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onRefresh) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
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

// MARK: - Edit M3U Source View

struct EditM3USourceView: View {
    let source: M3USource
    var onSave: (String?, String?, String?) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var url: String
    @State private var epgUrl: String

    init(source: M3USource, onSave: @escaping (String?, String?, String?) -> Void) {
        self.source = source
        self.onSave = onSave
        _name = State(initialValue: source.name)
        _url = State(initialValue: source.url)
        _epgUrl = State(initialValue: source.epgUrl ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Source Details") {
                    TextField("Name", text: $name)
                    TextField("M3U URL", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("EPG URL (optional)", text: $epgUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit M3U Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            name != source.name ? name : nil,
                            url != source.url ? url : nil,
                            epgUrl != (source.epgUrl ?? "") ? (epgUrl.isEmpty ? nil : epgUrl) : nil
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty || url.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Xtream Source View

struct EditXtreamSourceView: View {
    let source: XtreamSource
    var onSave: (String?, Bool?, Bool?, Bool?, Bool?) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var enabled: Bool
    @State private var importLive: Bool
    @State private var importVod: Bool
    @State private var importSeries: Bool

    init(source: XtreamSource, onSave: @escaping (String?, Bool?, Bool?, Bool?, Bool?) -> Void) {
        self.source = source
        self.onSave = onSave
        _name = State(initialValue: source.name)
        _enabled = State(initialValue: source.enabled)
        _importLive = State(initialValue: source.importLive)
        _importVod = State(initialValue: source.importVod)
        _importSeries = State(initialValue: source.importSeries)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Source Details") {
                    TextField("Name", text: $name)
                    Toggle("Enabled", isOn: $enabled)
                }

                Section("Import Settings") {
                    Toggle("Import Live Channels", isOn: $importLive)
                    Toggle("Import VOD", isOn: $importVod)
                    Toggle("Import Series", isOn: $importSeries)
                }

                Section {
                    HStack {
                        Text("Server")
                        Spacer()
                        Text(source.serverUrl)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(source.username)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Xtream Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            name != source.name ? name : nil,
                            enabled != source.enabled ? enabled : nil,
                            importLive != source.importLive ? importLive : nil,
                            importVod != source.importVod ? importVod : nil,
                            importSeries != source.importSeries ? importSeries : nil
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add M3U Source View (Enhanced)

struct AddM3USourceView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var url = ""
    @State private var epgUrl = ""
    @State private var importVod = false
    @State private var importSeries = false
    @State private var selectedVodLibrary = ""
    @State private var selectedSeriesLibrary = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Source") {
                    TextField("Name", text: $name)
                    TextField("M3U URL", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("EPG URL (optional)", text: $epgUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("Import Options") {
                    Toggle("Import VOD", isOn: $importVod)
                    if importVod && !settingsViewModel.libraries.isEmpty {
                        Picker("VOD Library", selection: $selectedVodLibrary) {
                            Text("Select Library").tag("")
                            ForEach(settingsViewModel.libraries) { lib in
                                Text(lib.name).tag(lib.id)
                            }
                        }
                    }

                    Toggle("Import Series", isOn: $importSeries)
                    if importSeries && !settingsViewModel.libraries.isEmpty {
                        Picker("Series Library", selection: $selectedSeriesLibrary) {
                            Text("Select Library").tag("")
                            ForEach(settingsViewModel.libraries) { lib in
                                Text(lib.name).tag(lib.id)
                            }
                        }
                    }
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
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
                // Trigger imports if requested
                if let source = settingsViewModel.m3uSources.last {
                    if importVod && !selectedVodLibrary.isEmpty {
                        try? await settingsViewModel.importM3UVOD(sourceId: source.id, libraryId: selectedVodLibrary)
                    }
                    if importSeries && !selectedSeriesLibrary.isEmpty {
                        try? await settingsViewModel.importM3USeries(sourceId: source.id, libraryId: selectedSeriesLibrary)
                    }
                }
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Add Xtream Source View (Enhanced)

struct AddXtreamSourceView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var serverUrl = ""
    @State private var username = ""
    @State private var password = ""
    @State private var importLive = true
    @State private var importVod = false
    @State private var importSeries = false
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    TextField("Name", text: $name)
                    TextField("Server URL", text: $serverUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                }

                Section("Import Options") {
                    Toggle("Import Live Channels", isOn: $importLive)
                    Toggle("Import VOD", isOn: $importVod)
                    Toggle("Import Series", isOn: $importSeries)
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
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
                // Trigger imports if requested
                if let source = settingsViewModel.xtreamSources.last {
                    if importVod {
                        try? await settingsViewModel.importXtreamVOD(sourceId: source.id)
                    }
                    if importSeries {
                        try? await settingsViewModel.importXtreamSeries(sourceId: source.id)
                    }
                }
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

// MARK: - Add EPG Source View

struct AddEPGSourceView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var selectedType: EPGSourceType = .tvguide
    @State private var xmltvUrl = ""

    // TVGuide fields
    @State private var zipCode = ""
    @State private var tvguideDays = 13
    @State private var providers: [TVGuideProviderDTO] = []
    @State private var selectedProvider: TVGuideProviderDTO?
    @State private var isSearching = false
    @State private var hasSearched = false

    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                // Provider type picker
                Section("Provider") {
                    HStack(spacing: 12) {
                        providerButton(.tvguide, label: "TV Guide", icon: "tv", color: .purple)
                        providerButton(.xmltv, label: "XMLTV", icon: "doc.text", color: .blue)
                        providerButton(.gracenote, label: "Gracenote", icon: "antenna.radiowaves.left.and.right", color: .green)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 4)
                }

                Section("Name") {
                    TextField("e.g. YouTube TV - Chicago", text: $name)
                }

                // Type-specific fields
                switch selectedType {
                case .tvguide:
                    tvguideFields
                case .xmltv:
                    Section("XMLTV URL") {
                        TextField("http://example.com/guide.xml", text: $xmltvUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                case .gracenote:
                    Section("XMLTV URL") {
                        TextField("http://example.com/guide.xml", text: $xmltvUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add EPG Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addSource()
                    }
                    .disabled(!canAdd || isLoading)
                    .fontWeight(.bold)
                }
            }
        }
    }

    private var canAdd: Bool {
        guard !name.isEmpty else { return false }
        switch selectedType {
        case .tvguide:
            return selectedProvider != nil && !zipCode.isEmpty
        case .xmltv, .gracenote:
            return !xmltvUrl.isEmpty
        }
    }

    @ViewBuilder
    private var tvguideFields: some View {
        Section("Location") {
            HStack {
                TextField("Zip Code", text: $zipCode)
                    .keyboardType(.numberPad)

                Button {
                    searchProviders()
                } label: {
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Search")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(zipCode.count < 5 || isSearching)
            }
        }

        if hasSearched {
            Section("Provider (\(providers.count) found)") {
                if providers.isEmpty {
                    Text("No providers found for this zip code")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(providers) { provider in
                        Button {
                            selectedProvider = provider
                            if name.isEmpty {
                                name = provider.name
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.name)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    HStack(spacing: 6) {
                                        Text(provider.type.capitalized)
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.purple.opacity(0.15))
                                            .cornerRadius(3)
                                        if let city = provider.city, let state = provider.state {
                                            Text("\(city), \(state)")
                                                .font(.caption2)
                                        }
                                    }
                                    .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedProvider?.id == provider.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.purple)
                                        .font(.title3)
                                }
                            }
                        }
                    }
                }
            }
        }

        if selectedProvider != nil {
            Section("Settings") {
                Picker("Days to Fetch", selection: $tvguideDays) {
                    Text("3 days").tag(3)
                    Text("7 days").tag(7)
                    Text("13 days (max)").tag(13)
                }
            }
        }
    }

    private func providerButton(_ type: EPGSourceType, label: String, icon: String, color: Color) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedType = type
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selectedType == type ? color : Color(.systemGray5))
            .foregroundColor(selectedType == type ? .white : .primary)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func searchProviders() {
        isSearching = true
        error = nil
        Task {
            do {
                let response = try await settingsViewModel.discoverTVGuideProviders(zip: zipCode)
                providers = response.providers
                hasSearched = true
                selectedProvider = nil
            } catch {
                self.error = "Failed to search: \(error.localizedDescription)"
            }
            isSearching = false
        }
    }

    private func addSource() {
        isLoading = true
        error = nil
        Task {
            do {
                switch selectedType {
                case .tvguide:
                    guard let provider = selectedProvider else { return }
                    try await settingsViewModel.addEPGSource(
                        name: name,
                        url: nil,
                        type: "tvguide",
                        tvguideProviderId: String(provider.id),
                        tvguideZipCode: zipCode,
                        tvguideDays: tvguideDays
                    )
                case .xmltv:
                    try await settingsViewModel.addEPGSource(name: name, url: xmltvUrl, type: "xmltv")
                case .gracenote:
                    try await settingsViewModel.addEPGSource(name: name, url: xmltvUrl, type: "gracenote")
                }
                // Auto-refresh after adding
                if let newSource = settingsViewModel.epgSources.last {
                    try? await settingsViewModel.refreshEPGSource(newSource)
                }
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
        .environmentObject(SettingsViewModel())
}
