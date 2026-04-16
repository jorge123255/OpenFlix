import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Theme helpers (local)
private let settingsBg     = Color(red: 17/255,  green: 12/255,  blue: 33/255)
private let settingsCardBg = Color.white.opacity(0.07)
private let settingsAccent = Color(red: 97/255,  green: 56/255,  blue: 245/255)

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showLogoutConfirm    = false
    @State private var showInviteSheet      = false
    @State private var showAccessCodeSheet  = false
    @State private var showClaimTokenCopied = false
    @State private var showInviteCopied     = false

    var body: some View {
        ZStack {
            settingsBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    #if os(tvOS)
                    settingsHeroBanner
                        .padding(.horizontal, 28)
                        .padding(.top, 16)
                    #endif
                    serverSection
                    inviteSection
                    remoteAccessSection
                    profileSection
                    librarySection
                    sourcesSection
                    playbackSection
                    if settingsViewModel.hasDVR  { dvrSection }
                    if settingsViewModel.hasLiveTV { liveTVSection }
                    displaySection
                    aboutSection
                    accountSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Settings")
        #if !os(tvOS) // tvOS: large title style not supported
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            await settingsViewModel.loadServerInfo()
            await settingsViewModel.loadSources()
            await settingsViewModel.loadClaimToken()
        }
        .confirmationDialog("Sign Out", isPresented: $showLogoutConfirm) {
            Button("Sign Out", role: .destructive) {
                Task { await authViewModel.logout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        // After invite generated → show share sheet
        .sheet(isPresented: $showInviteSheet) {
            inviteModal
        }
        .sheet(isPresented: $showAccessCodeSheet) {
            accessCodeModal
        }
    }

    // MARK: - Section: Server

    private var serverSection: some View {
        settingsCard(header: "Server") {
            if let info = settingsViewModel.serverInfo {
                settingsRow(label: "Server Name", value: info.name)
                Divider().background(Color.white.opacity(0.08))
                settingsRow(label: "Version", value: info.version)
                Divider().background(Color.white.opacity(0.08))
            }
            if let url = UserDefaults.standard.serverURL {
                settingsRow(label: "Server URL", value: url.host ?? url.absoluteString)
            }
        }
    }

    // MARK: - Section: Invite

    private var inviteSection: some View {
        settingsCard(header: "Share with Family & Friends") {
            Button {
                Task {
                    await settingsViewModel.generateInvite()
                    if settingsViewModel.inviteDeepLink != nil {
                        showInviteSheet = true
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    if settingsViewModel.isGeneratingInvite {
                        ProgressView().scaleEffect(0.8).tint(.white)
                        Text("Creating invite...")
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(settingsAccent)
                            .font(.system(size: 18))
                        Text(settingsViewModel.inviteToken == nil ? "Invite Family or Friend" : "New Invite Link")
                            .foregroundColor(settingsAccent)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Spacer()
                    if !settingsViewModel.isGeneratingInvite {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .disabled(settingsViewModel.isGeneratingInvite)

            if settingsViewModel.inviteToken != nil {
                Divider().background(Color.white.opacity(0.08))
                Button {
                    showInviteSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "link")
                            .foregroundColor(.green)
                            .font(.system(size: 15))
                        Text("View Invite Link")
                            .foregroundColor(.green)
                            .font(.system(size: 15))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                    }
                }
                .buttonStyle(.plain)
            }
        } footer: {
            Text("Send an invite link to someone. They'll create their own account on your server and can stream from anywhere.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
                .padding(.top, 6)
        }
    }

    // MARK: - Section: Remote Access

    private var remoteAccessSection: some View {
        settingsCard(header: "Remote Access") {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "network")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Away from Home")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Connect to your server from anywhere")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            }
            .padding(.vertical, 4)

            Divider().background(Color.white.opacity(0.08))

            Button {
                Task {
                    await settingsViewModel.generateNewClaimToken()
                    if settingsViewModel.claimToken != nil {
                        showAccessCodeSheet = true
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    if settingsViewModel.isGeneratingToken {
                        ProgressView().scaleEffect(0.8).tint(.white)
                        Text("Generating...").foregroundColor(.gray)
                    } else {
                        Image(systemName: "plus.circle")
                            .foregroundColor(settingsAccent)
                            .font(.system(size: 18))
                        Text(settingsViewModel.claimTokenActive ? "Generate New Code" : "Generate Access Code")
                            .foregroundColor(settingsAccent)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Spacer()
                    if !settingsViewModel.isGeneratingToken {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .disabled(settingsViewModel.isGeneratingToken)

            if settingsViewModel.claimTokenActive, settingsViewModel.claimToken != nil {
                Divider().background(Color.white.opacity(0.08))
                Button {
                    showAccessCodeSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "key.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 15))
                        Text("View Access Code")
                            .foregroundColor(.green)
                            .font(.system(size: 15))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                    }
                }
                .buttonStyle(.plain)
            }
        } footer: {
            Text("Generate a one-time code to add a new device. Codes expire after 10 minutes.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
                .padding(.top, 6)
        }
    }

    // MARK: - Section: Profile

    private var profileSection: some View {
        settingsCard(header: "Profile") {
            if let profile = authViewModel.currentProfile {
                settingsRow(label: "Current Profile", value: profile.name)
                Divider().background(Color.white.opacity(0.08))
            }
            Button {
                authViewModel.clearProfile()
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(settingsAccent)
                        .font(.system(size: 16))
                    Text("Switch Profile")
                        .foregroundColor(settingsAccent)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 13))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Section: Library

    private var librarySection: some View {
        settingsCard(header: "Library") {
            NavigationLink(destination: WatchlistView()) {
                navRow(icon: "bookmark.fill", iconColor: settingsAccent, label: "Watchlist")
            }
            .buttonStyle(.plain)
            Divider().background(Color.white.opacity(0.08))
            NavigationLink(destination: PlaylistsView()) {
                navRow(icon: "music.note.list", iconColor: settingsAccent, label: "Playlists")
            }
            .buttonStyle(.plain)
            Divider().background(Color.white.opacity(0.08))
            NavigationLink(destination: WatchStatsView()) {
                navRow(icon: "chart.bar.xaxis", iconColor: settingsAccent, label: "Watch Stats")
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Section: Sources

    private var sourcesSection: some View {
        settingsCard(header: "Sources") {
            NavigationLink(destination: SourcesView().environmentObject(settingsViewModel)) {
                HStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(settingsAccent)
                        .font(.system(size: 16))
                    Text("Manage Sources")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Spacer()
                    Text("\(settingsViewModel.totalChannelCount) channels")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 13))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Section: Playback

    private var playbackSection: some View {
        settingsCard(header: "Playback") {
            settingsToggle(label: "Auto-Play Next Episode", isOn: $settingsViewModel.autoPlayNext)
            Divider().background(Color.white.opacity(0.08))
            settingsToggle(label: "Skip Intros", isOn: $settingsViewModel.skipIntros)
            Divider().background(Color.white.opacity(0.08))
            settingsToggle(label: "Skip Credits", isOn: $settingsViewModel.skipCredits)
            Divider().background(Color.white.opacity(0.08))
            settingsToggle(label: "Show Subtitles", isOn: $settingsViewModel.showSubtitles)
        }
    }

    // MARK: - Section: DVR

    private var dvrSection: some View {
        settingsCard(header: "DVR") {
            settingsToggle(label: "Commercial Skip", isOn: $settingsViewModel.commercialSkipEnabled)
            Divider().background(Color.white.opacity(0.08))
            VStack(alignment: .leading, spacing: 2) {
                settingsToggle(label: "ONNX AI Detection", isOn: $settingsViewModel.onnxDetectionEnabled)
                Text("Neural network for more accurate commercial detection")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 2)
            }
            Divider().background(Color.white.opacity(0.08))
            VStack(alignment: .leading, spacing: 2) {
                settingsToggle(label: "Audio Fingerprint Intro Detection", isOn: $settingsViewModel.acoustidEnabled)
                Text("Find episode intros by comparing audio across episodes")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 2)
            }
        }
    }

    // MARK: - Section: Live TV

    private var liveTVSection: some View {
        settingsCard(header: "Live TV") {
            NavigationLink(destination: ChannelEditorView()) {
                navRow(icon: "pencil.and.list.clipboard", iconColor: settingsAccent, label: "Channel Editor")
            }
            .buttonStyle(.plain)
            Divider().background(Color.white.opacity(0.08))
            settingsToggle(label: "Channel Surfing", isOn: $settingsViewModel.channelSurfingEnabled)
            Divider().background(Color.white.opacity(0.08))
            HStack {
                Text("EPG Days to Load")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
                Picker("", selection: $settingsViewModel.epgDaysToLoad) {
                    Text("1 Day").tag(1)
                    Text("3 Days").tag(3)
                    Text("7 Days").tag(7)
                    Text("14 Days").tag(14)
                }
                .pickerStyle(.menu)
                .tint(settingsAccent)
            }
        }
    }

    // MARK: - Section: Display

    private var displaySection: some View {
        settingsCard(header: "Display") {
            settingsToggle(label: "Screensaver", isOn: $settingsViewModel.screensaverEnabled)
            if settingsViewModel.screensaverEnabled {
                Divider().background(Color.white.opacity(0.08))
                HStack {
                    Text("Screensaver Delay")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Spacer()
                    Picker("", selection: $settingsViewModel.screensaverDelay) {
                        Text("2 Minutes").tag(120)
                        Text("5 Minutes").tag(300)
                        Text("10 Minutes").tag(600)
                        Text("15 Minutes").tag(900)
                    }
                    .pickerStyle(.menu)
                    .tint(settingsAccent)
                }
            }
        }
    }

    // MARK: - Section: About

    private var aboutSection: some View {
        settingsCard(header: "About") {
            settingsRow(label: "App Version", value: "\(settingsViewModel.appVersion) (\(settingsViewModel.buildNumber))")
            if let caps = settingsViewModel.capabilities {
                Divider().background(Color.white.opacity(0.08))
                HStack {
                    Text("Capabilities")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Spacer()
                    HStack(spacing: 6) {
                        if caps.liveTV      { capBadge("Live TV") }
                        if caps.dvr         { capBadge("DVR") }
                        if caps.transcoding { capBadge("Transcode") }
                    }
                }
            }
        }
    }

    // MARK: - Section: Account

    private var accountSection: some View {
        settingsCard(header: nil) {
            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                    Text("Sign Out")
                        .foregroundColor(.red)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - tvOS Hero Banner

    #if os(tvOS)
    private var settingsHeroBanner: some View {
        let serverName = settingsViewModel.serverInfo?.name ?? "OpenFlix server"
        return ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.24, blue: 0.28),
                    Color(red: 0.10, green: 0.11, blue: 0.14)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            Image(systemName: "gearshape.fill")
                .font(.system(size: 200, weight: .light))
                .foregroundStyle(.white.opacity(0.07))
                .offset(x: 380, y: -10)

            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(serverName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
            }
            .padding(28)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    #endif

    // MARK: - Invite Modal

    private var inviteModal: some View {
        NavigationStack {
            ZStack {
                settingsBg.ignoresSafeArea()
                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(settingsAccent.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 36))
                            .foregroundColor(settingsAccent)
                    }

                    VStack(spacing: 8) {
                        Text("Invite Link Ready")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text("Share this link so they can create an account and start streaming.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }

                    if let link = settingsViewModel.inviteDeepLink {
                        VStack(spacing: 12) {
                            Text(link)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(12)
                                .background(Color.white.opacity(0.07))
                                .cornerRadius(10)

                            Button {
                                #if !os(tvOS) // tvOS: UIPasteboard not available
                                UIPasteboard.general.string = link
                                #endif
                                showInviteCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showInviteCopied = false }
                            } label: {
                                HStack {
                                    Image(systemName: showInviteCopied ? "checkmark" : "doc.on.doc")
                                    Text(showInviteCopied ? "Copied!" : "Copy Link")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(showInviteCopied ? Color.green : settingsAccent)
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)

                            #if !os(tvOS) // tvOS: ShareLink unavailable
                            ShareLink(item: link) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(settingsAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(settingsAccent.opacity(0.12))
                                .cornerRadius(14)
                            }
                            #endif
                        }
                        .padding(.horizontal, 24)
                    }

                    if let exp = settingsViewModel.inviteExpiresAt {
                        Text("Expires \(exp.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)
            }
            .navigationTitle("Invite")
            #if !os(tvOS) // tvOS: inline title style not supported
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showInviteSheet = false }
                        .foregroundColor(settingsAccent)
                }
            }
        }
    }

    // MARK: - Access Code Modal

    private var accessCodeModal: some View {
        NavigationStack {
            ZStack {
                settingsBg.ignoresSafeArea()
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "key.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                    }

                    VStack(spacing: 8) {
                        Text("New Device Code")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text("Enter this code in the OpenFlix app on your new device.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }

                    if let token = settingsViewModel.claimToken {
                        VStack(spacing: 16) {
                            Text(token)
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .tracking(12)
                                .foregroundColor(.white)
                                .padding(.vertical, 20)
                                .padding(.horizontal, 24)
                                .background(Color.white.opacity(0.07))
                                .cornerRadius(16)

                            Button {
                                #if !os(tvOS) // tvOS: UIPasteboard not available
                                UIPasteboard.general.string = token
                                #endif
                                showClaimTokenCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showClaimTokenCopied = false }
                            } label: {
                                HStack {
                                    Image(systemName: showClaimTokenCopied ? "checkmark" : "doc.on.doc")
                                    Text(showClaimTokenCopied ? "Copied!" : "Copy Code")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(showClaimTokenCopied ? Color.green : Color.blue)
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                    }

                    if let expiresIn = settingsViewModel.claimTokenExpiresIn {
                        Text("Expires in \(max(0, Int(expiresIn / 60))) min")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    Spacer()
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)
            }
            .navigationTitle("Access Code")
            #if !os(tvOS) // tvOS: inline title style not supported
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showAccessCodeSheet = false }
                        .foregroundColor(settingsAccent)
                }
            }
        }
    }

    // MARK: - Reusable Components

    @ViewBuilder
    private func settingsCard<Content: View>(
        header: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        settingsCard(header: header, content: content, footer: { EmptyView() })
    }

    @ViewBuilder
    private func settingsCard<Content: View, Footer: View>(
        header: String?,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let header {
                Text(header.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 6)
            }
            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(settingsCardBg)
            .cornerRadius(16)
            footer()
        }
    }

    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
                .font(.system(size: 16))
            Spacer()
            Text(value)
                .foregroundColor(.gray)
                .font(.system(size: 15))
                .lineLimit(1)
        }
    }

    private func navRow(icon: String, iconColor: Color, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 16))
                .frame(width: 22)
            Text(label)
                .foregroundColor(.white)
                .font(.system(size: 16))
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 13))
        }
        .padding(.vertical, 4)
    }

    private func settingsToggle(label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .foregroundColor(.white)
                .font(.system(size: 16))
        }
        .tint(settingsAccent)
    }

    private func capBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(settingsAccent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(settingsAccent.opacity(0.15))
            .cornerRadius(6)
    }
}

// MARK: - Sources View

struct SourcesView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    @State private var selectedTab = SourceTab.m3u
    @State private var showAddM3U   = false
    @State private var showAddXtream = false
    @State private var showAddEPG   = false

    enum SourceTab: String, CaseIterable {
        case m3u    = "M3U"
        case xtream = "Xtream"
        case epg    = "EPG"
        case tuner  = "Tuner"
    }

    var body: some View {
        ZStack {
            settingsBg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Tab bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(SourceTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                            } label: {
                                VStack(spacing: 6) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 15, weight: selectedTab == tab ? .bold : .regular))
                                        .foregroundColor(selectedTab == tab ? .white : .gray)
                                        .padding(.horizontal, 20)
                                    Rectangle()
                                        .fill(selectedTab == tab ? settingsAccent : .clear)
                                        .frame(height: 2)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .background(Color(red: 26/255, green: 20/255, blue: 46/255))
                .padding(.bottom, 1)

                // Content
                switch selectedTab {
                case .m3u:    m3uContent
                case .xtream: xtreamContent
                case .epg:    epgContent
                case .tuner:  TunerDiscoveryView()
                }
            }
        }
        .navigationTitle("Sources")
        #if !os(tvOS) // tvOS: inline title style not supported
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if selectedTab != .tuner {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if selectedTab == .m3u || selectedTab == .xtream {
                            Button { showAddM3U = true } label: {
                                Label("Add M3U Source", systemImage: "list.bullet")
                            }
                            Button { showAddXtream = true } label: {
                                Label("Add Xtream Source", systemImage: "server.rack")
                            }
                        }
                        if selectedTab == .epg {
                            Button { showAddEPG = true } label: {
                                Label("Add EPG Source", systemImage: "doc.text")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(settingsAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddM3U)    { AddM3USourceView() }
        .sheet(isPresented: $showAddXtream) { AddXtreamSourceView() }
        .sheet(isPresented: $showAddEPG)    { AddEPGSourceView().environmentObject(settingsViewModel) }
        .task { await settingsViewModel.loadLibraries() }
    }

    // MARK: - M3U

    private var m3uContent: some View {
        Group {
            if settingsViewModel.m3uSources.isEmpty {
                emptySourceState(
                    icon: "list.bullet",
                    title: "No M3U Sources",
                    action: { showAddM3U = true }
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(settingsViewModel.m3uSources) { source in
                            StyledM3USourceCard(
                                source: source,
                                libraries: settingsViewModel.libraries,
                                onRefresh:       { Task { try? await settingsViewModel.refreshM3USource(source) } },
                                onDelete:        { Task { try? await settingsViewModel.deleteM3USource(source) } },
                                onImportVOD:     { lib in Task { try? await settingsViewModel.importM3UVOD(sourceId: source.id, libraryId: lib) } },
                                onImportSeries:  { lib in Task { try? await settingsViewModel.importM3USeries(sourceId: source.id, libraryId: lib) } },
                                onToggleEnabled: { en  in Task { try? await settingsViewModel.updateM3USource(id: source.id, name: nil, url: nil, epgUrl: nil, enabled: en) } },
                                onEdit:          { n, u, e in Task { try? await settingsViewModel.updateM3USource(id: source.id, name: n, url: u, epgUrl: e, enabled: nil) } }
                            )
                        }
                        addButton("Add M3U Source", icon: "list.bullet") { showAddM3U = true }
                    }
                    .padding(16)
                }
            }
        }
    }

    // MARK: - Xtream

    private var xtreamContent: some View {
        Group {
            if settingsViewModel.xtreamSources.isEmpty {
                emptySourceState(
                    icon: "server.rack",
                    title: "No Xtream Sources",
                    action: { showAddXtream = true }
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(settingsViewModel.xtreamSources) { source in
                            StyledXtreamSourceCard(
                                source: source,
                                libraries: settingsViewModel.libraries,
                                onRefresh:       { Task { try? await settingsViewModel.refreshXtreamSource(source) } },
                                onTest:          { Task { _ = await settingsViewModel.testXtreamSource(source) } },
                                onDelete:        { Task { try? await settingsViewModel.deleteXtreamSource(source) } },
                                onImportVOD:     { Task { try? await settingsViewModel.importXtreamVOD(sourceId: source.id) } },
                                onImportSeries:  { Task { try? await settingsViewModel.importXtreamSeries(sourceId: source.id) } },
                                onToggleEnabled: { en in Task { try? await settingsViewModel.updateXtreamSource(id: source.id, name: nil, enabled: en, importLive: nil, importVod: nil, importSeries: nil) } },
                                onEdit:          { n, en, il, iv, is_ in Task { try? await settingsViewModel.updateXtreamSource(id: source.id, name: n, enabled: en, importLive: il, importVod: iv, importSeries: is_) } }
                            )
                        }
                        addButton("Add Xtream Source", icon: "server.rack") { showAddXtream = true }
                    }
                    .padding(16)
                }
            }
        }
    }

    // MARK: - EPG

    private var epgContent: some View {
        Group {
            if settingsViewModel.epgSources.isEmpty {
                emptySourceState(
                    icon: "doc.text",
                    title: "No EPG Sources",
                    action: { showAddEPG = true }
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(settingsViewModel.epgSources) { source in
                            StyledEPGSourceCard(source: source) {
                                Task { try? await settingsViewModel.refreshEPGSource(source) }
                            } onDelete: {
                                Task { try? await settingsViewModel.deleteEPGSource(source) }
                            }
                        }
                        addButton("Add EPG Source", icon: "doc.text") { showAddEPG = true }
                    }
                    .padding(16)
                }
            }
        }
    }

    // MARK: - Helpers

    private func emptySourceState(icon: String, title: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.4))
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Button(action: action) {
                Text("Add Source")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(settingsAccent)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func addButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(settingsAccent)
                    .font(.system(size: 18))
                Text(title)
                    .foregroundColor(settingsAccent)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(settingsAccent.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(settingsAccent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tuner Discovery View

struct TunerDiscoveryView: View {
    @State private var existingDevices: [HDHomeRunDeviceDTO] = []
    @State private var discovered: [DiscoveredTunerDTO] = []
    @State private var isLoadingExisting = false
    @State private var isScanning = false
    @State private var importingId: String?
    @State private var importedIds: Set<String> = []
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // My Tuners section
                VStack(spacing: 8) {
                    Text("My Tuners")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isLoadingExisting {
                        HStack {
                            ProgressView().scaleEffect(0.8).tint(.white)
                            Text("Loading...").foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    } else if existingDevices.isEmpty {
                        Text("No tuners added yet.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(existingDevices, id: \.deviceId) { device in
                            existingTunerCard(device)
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                // Discover new section
                VStack(spacing: 8) {
                    Text("Add New Tuner")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        Task { await scan() }
                    } label: {
                        HStack(spacing: 10) {
                            if isScanning {
                                ProgressView().scaleEffect(0.8).tint(.white)
                                Text("Scanning...").foregroundColor(.white)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(.white)
                                Text("Scan for Devices")
                                    .foregroundColor(.white)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(settingsAccent)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isScanning)
                }

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                if !discovered.isEmpty {
                    ForEach(discovered, id: \.url) { tuner in
                        tunerCard(tuner)
                    }
                }
            }
            .padding(16)
        }
        .task { await loadExisting() }
    }

    private func loadExisting() async {
        isLoadingExisting = true
        defer { isLoadingExisting = false }
        do {
            let resp = try await OpenFlixAPI.shared.getTuners()
            existingDevices = resp.devices
            // Mark already-added device IDs so Add button shows "Added"
            for dev in resp.devices {
                if let id = dev.deviceId { importedIds.insert(id) }
            }
        } catch {
            // Silently fail — show empty state
        }
    }

    private func scan() async {
        isScanning = true
        error = nil
        defer { isScanning = false }
        do {
            let resp = try await OpenFlixAPI.shared.discoverTuners()
            // Filter out devices already in existingDevices
            let existingIds = Set(existingDevices.compactMap(\.deviceId))
            discovered = resp.discovered.filter { tuner in
                guard let id = tuner.deviceId else { return true }
                return !existingIds.contains(id)
            }
            if discovered.isEmpty {
                error = "No new tuners found on your network."
            }
        } catch {
            self.error = "Scan failed: \(error.localizedDescription)"
        }
    }

    @ViewBuilder
    private func existingTunerCard(_ device: HDHomeRunDeviceDTO) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(device.modelNumber ?? device.deviceId ?? "HDHomeRun")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let ip = device.localIp {
                        Text(ip)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    if let tuners = device.tunerCount, tuners > 0 {
                        Text("• \(tuners) tuner\(tuners == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            Text("Added")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.12))
                .cornerRadius(8)
        }
        .padding(14)
        .background(settingsCardBg)
        .cornerRadius(14)
    }

    @ViewBuilder
    private func tunerCard(_ tuner: DiscoveredTunerDTO) -> some View {
        let id = tuner.deviceId ?? tuner.url
        let isImported = importedIds.contains(id)
        let isImporting = importingId == id

        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tuner.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(tuner.model ?? tuner.url)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                guard !isImporting && !isImported else { return }
                Task {
                    importingId = id
                    do {
                        try await OpenFlixAPI.shared.addTuner(url: tuner.url, name: tuner.name)
                        if let deviceId = tuner.deviceId {
                            try? await OpenFlixAPI.shared.requestVoid(.importTunerChannels(id: deviceId))
                        }
                        importedIds.insert(id)
                    } catch {}
                    importingId = nil
                }
            } label: {
                if isImporting {
                    ProgressView().scaleEffect(0.7).tint(.white)
                } else {
                    Text(isImported ? "Added" : "Add")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isImported ? .green : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isImported ? Color.green.opacity(0.15) : settingsAccent)
                        .cornerRadius(8)
                }
            }
            .buttonStyle(.plain)
            .disabled(isImported || isImporting)
        }
        .padding(14)
        .background(settingsCardBg)
        .cornerRadius(14)
    }
}

// MARK: - Styled Source Cards (dark themed)

struct StyledM3USourceCard: View {
    let source: M3USource
    let libraries: [SettingsViewModel.LibraryPickerItem]
    var onRefresh:       () -> Void
    var onDelete:        () -> Void
    var onImportVOD:     (String) -> Void
    var onImportSeries:  (String) -> Void
    var onToggleEnabled: (Bool) -> Void
    var onEdit:          (String?, String?, String?) -> Void

    @State private var showEdit         = false
    @State private var showImportVOD    = false
    @State private var showImportSeries = false
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "list.bullet")
                        .foregroundColor(.purple)
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(source.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if !source.enabled {
                            offBadge
                        }
                    }
                    HStack(spacing: 10) {
                        Label("\(source.channelCount) ch", systemImage: "tv")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        if let lf = source.lastFetched {
                            Text(lf, formatter: relativeDateFormatter)
                                .font(.system(size: 11))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }

            // Action row
            HStack(spacing: 8) {
                chipButton("Import VOD", icon: "film") {
                    if let first = libraries.first { onImportVOD(first.id) }
                    else { showImportVOD = true }
                }
                chipButton("Import Series", icon: "tv") {
                    if let first = libraries.first { onImportSeries(first.id) }
                    else { showImportSeries = true }
                }
                Spacer()
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button { onToggleEnabled(!source.enabled) } label: {
                        Label(source.enabled ? "Disable" : "Enable", systemImage: source.enabled ? "pause" : "play")
                    }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(14)
        .background(settingsCardBg)
        .cornerRadius(14)
        .sheet(isPresented: $showEdit) { EditM3USourceView(source: source, onSave: onEdit) }
        .confirmationDialog("Delete Source?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { onDelete() }
        }
        .alert("Import VOD", isPresented: $showImportVOD) {
            ForEach(libraries, id: \.id) { lib in Button(lib.name) { onImportVOD(lib.id) } }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Import Series", isPresented: $showImportSeries) {
            ForEach(libraries, id: \.id) { lib in Button(lib.name) { onImportSeries(lib.id) } }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct StyledXtreamSourceCard: View {
    let source: XtreamSource
    let libraries: [SettingsViewModel.LibraryPickerItem]
    var onRefresh:       () -> Void
    var onTest:          () -> Void
    var onDelete:        () -> Void
    var onImportVOD:     () -> Void
    var onImportSeries:  () -> Void
    var onToggleEnabled: (Bool) -> Void
    var onEdit:          (String?, Bool?, Bool?, Bool?, Bool?) -> Void

    @State private var showEdit          = false
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "server.rack")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(source.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if !source.enabled { offBadge }
                        if source.isExpired {
                            Text("EXPIRED")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(3)
                        }
                    }
                    HStack(spacing: 10) {
                        Label("\(source.channelCount)", systemImage: "tv").font(.system(size: 12))
                        if source.vodCount > 0 { Label("\(source.vodCount)", systemImage: "film").font(.system(size: 12)) }
                        if source.seriesCount > 0 { Label("\(source.seriesCount)", systemImage: "tv.and.mediabox").font(.system(size: 12)) }
                    }
                    .foregroundColor(.gray)
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                chipButton("Test", icon: "antenna.radiowaves.left.and.right", action: onTest)
                chipButton("VOD", icon: "film", action: onImportVOD)
                chipButton("Series", icon: "tv", action: onImportSeries)
                Spacer()
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button { onToggleEnabled(!source.enabled) } label: {
                        Label(source.enabled ? "Disable" : "Enable", systemImage: source.enabled ? "pause" : "play")
                    }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(14)
        .background(settingsCardBg)
        .cornerRadius(14)
        .sheet(isPresented: $showEdit) { EditXtreamSourceView(source: source, onSave: onEdit) }
        .confirmationDialog("Delete Source?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}

struct StyledEPGSourceCard: View {
    let source: EPGSource
    var onRefresh: () -> Void
    var onDelete:  () -> Void

    @State private var showDeleteConfirm = false

    private var typeColor: Color {
        source.type == .tvguide ? settingsAccent : .blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "doc.text")
                        .foregroundColor(typeColor)
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(source.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(source.type.displayName)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(typeColor)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(typeColor.opacity(0.15))
                            .cornerRadius(3)
                        if !source.enabled { offBadge }
                    }
                    HStack(spacing: 12) {
                        Label("\(source.channelCount) ch", systemImage: "tv")
                        Label("\(source.programCount) programs", systemImage: "doc.text")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    if let lf = source.lastFetched {
                        Text(lf, formatter: relativeDateFormatter)
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }

                Spacer()

                Menu {
                    Button(action: onRefresh) { Label("Refresh", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(14)
        .background(settingsCardBg)
        .cornerRadius(14)
        .confirmationDialog("Delete EPG Source?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}

// MARK: - Shared helpers

private var offBadge: some View {
    Text("OFF")
        .font(.system(size: 8, weight: .bold))
        .foregroundColor(.orange)
        .padding(.horizontal, 5).padding(.vertical, 2)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(3)
}

private func chipButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11))
            Text(title).font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    .buttonStyle(.plain)
}

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .short
    return f
}()

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
                        #if !os(tvOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        #endif
                    TextField("EPG URL (optional)", text: $epgUrl)
                        #if !os(tvOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        #endif
                }
            }
            .navigationTitle("Edit M3U Source")
            #if !os(tvOS) // tvOS: inline title style not supported
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
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
                        Text(source.serverUrl).foregroundColor(.secondary).lineLimit(1)
                    }
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(source.username).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Xtream Source")
            #if !os(tvOS) // tvOS: inline title style not supported
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
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

// MARK: - Add M3U Source View

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
                        #if !os(tvOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        #endif
                    TextField("EPG URL (optional)", text: $epgUrl)
                        #if !os(tvOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        #endif
                }
                Section("Import Options") {
                    Toggle("Import VOD", isOn: $importVod)
                    if importVod && !settingsViewModel.libraries.isEmpty {
                        Picker("VOD Library", selection: $selectedVodLibrary) {
                            Text("Select Library").tag("")
                            ForEach(settingsViewModel.libraries) { lib in Text(lib.name).tag(lib.id) }
                        }
                    }
                    Toggle("Import Series", isOn: $importSeries)
                    if importSeries && !settingsViewModel.libraries.isEmpty {
                        Picker("Series Library", selection: $selectedSeriesLibrary) {
                            Text("Select Library").tag("")
                            ForEach(settingsViewModel.libraries) { lib in Text(lib.name).tag(lib.id) }
                        }
                    }
                }
                if let error { Section { Text(error).foregroundColor(.red) } }
            }
            .navigationTitle("Add M3U Source")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addSource() }
                        .disabled(name.isEmpty || url.isEmpty || isLoading)
                }
            }
        }
    }

    private func addSource() {
        isLoading = true
        Task {
            do {
                try await settingsViewModel.addM3USource(name: name, url: url, epgUrl: epgUrl.isEmpty ? nil : epgUrl)
                if let source = settingsViewModel.m3uSources.last {
                    if importVod && !selectedVodLibrary.isEmpty {
                        try? await settingsViewModel.importM3UVOD(sourceId: source.id, libraryId: selectedVodLibrary)
                    }
                    if importSeries && !selectedSeriesLibrary.isEmpty {
                        try? await settingsViewModel.importM3USeries(sourceId: source.id, libraryId: selectedSeriesLibrary)
                    }
                }
                dismiss()
            } catch { self.error = error.localizedDescription }
            isLoading = false
        }
    }
}

// MARK: - Add Xtream Source View

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
                        #if !os(tvOS)
                        .keyboardType(.URL).autocapitalization(.none)
                        #endif
                    TextField("Username", text: $username)
                        #if !os(tvOS)
                        .autocapitalization(.none)
                        #endif
                    SecureField("Password", text: $password)
                }
                Section("Import Options") {
                    Toggle("Import Live Channels", isOn: $importLive)
                    Toggle("Import VOD", isOn: $importVod)
                    Toggle("Import Series", isOn: $importSeries)
                }
                if let error { Section { Text(error).foregroundColor(.red) } }
            }
            .navigationTitle("Add Xtream Source")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addSource() }
                        .disabled(name.isEmpty || serverUrl.isEmpty || username.isEmpty || password.isEmpty || isLoading)
                }
            }
        }
    }

    private func addSource() {
        isLoading = true
        Task {
            do {
                try await settingsViewModel.addXtreamSource(name: name, serverUrl: serverUrl, username: username, password: password)
                if let source = settingsViewModel.xtreamSources.last {
                    if importVod  { try? await settingsViewModel.importXtreamVOD(sourceId: source.id) }
                    if importSeries { try? await settingsViewModel.importXtreamSeries(sourceId: source.id) }
                }
                dismiss()
            } catch { self.error = error.localizedDescription }
            isLoading = false
        }
    }
}

// MARK: - Add EPG Source View

struct AddEPGSourceView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var selectedType: EPGSourceType = .tvguide
    @State private var xmltvUrl = ""
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
                Section("Provider") {
                    HStack(spacing: 12) {
                        providerButton(.tvguide,   label: "TV Guide",  icon: "tv",                              color: .purple)
                        providerButton(.xmltv,     label: "XMLTV",     icon: "doc.text",                        color: .blue)
                        providerButton(.gracenote, label: "Gracenote", icon: "antenna.radiowaves.left.and.right", color: .green)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 4)
                }
                Section("Name") { TextField("e.g. YouTube TV - Chicago", text: $name) }
                switch selectedType {
                case .tvguide:  tvguideFields
                case .xmltv, .gracenote:
                    Section("XMLTV URL") {
                        TextField("http://example.com/guide.xml", text: $xmltvUrl)
                            #if !os(tvOS)
                            .keyboardType(.URL).autocapitalization(.none)
                            #endif
                    }
                }
                if let error { Section { Text(error).foregroundColor(.red).font(.caption) } }
            }
            .navigationTitle("Add EPG Source")
            #if !os(tvOS) // tvOS: inline title style not supported
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addSource() }
                        .disabled(!canAdd || isLoading)
                        .fontWeight(.bold)
                }
            }
        }
    }

    private var canAdd: Bool {
        guard !name.isEmpty else { return false }
        switch selectedType {
        case .tvguide: return selectedProvider != nil && !zipCode.isEmpty
        case .xmltv, .gracenote: return !xmltvUrl.isEmpty
        }
    }

    @ViewBuilder
    private var tvguideFields: some View {
        Section("Location") {
            HStack {
                TextField("Zip Code", text: $zipCode)
                    #if !os(tvOS)
                    .keyboardType(.numberPad)
                    #endif
                Button {
                    searchProviders()
                } label: {
                    if isSearching { ProgressView().scaleEffect(0.8) } else { Text("Search").fontWeight(.semibold) }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(zipCode.count < 5 || isSearching)
            }
        }
        if hasSearched {
            Section("Provider (\(providers.count) found)") {
                if providers.isEmpty {
                    Text("No providers found for this zip code").foregroundColor(.secondary).font(.caption)
                } else {
                    ForEach(providers) { provider in
                        Button {
                            selectedProvider = provider
                            if name.isEmpty { name = provider.name }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.name).font(.subheadline).foregroundColor(.primary)
                                    HStack(spacing: 6) {
                                        Text(provider.type.capitalized)
                                            .font(.caption2).padding(.horizontal, 4).padding(.vertical, 1)
                                            .background(Color.purple.opacity(0.15)).cornerRadius(3)
                                        if let city = provider.city, let state = provider.state {
                                            Text("\(city), \(state)").font(.caption2)
                                        }
                                    }
                                    .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedProvider?.id == provider.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.purple).font(.title3)
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
            withAnimation(.easeInOut(duration: 0.2)) { selectedType = type }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.caption).fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selectedType == type ? color : Color.gray.opacity(0.3)) // systemGray5 not on tvOS
            .foregroundColor(selectedType == type ? .white : .primary)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func searchProviders() {
        isSearching = true; error = nil
        Task {
            do {
                let response = try await settingsViewModel.discoverTVGuideProviders(zip: zipCode)
                providers = response.providers
                hasSearched = true
                selectedProvider = nil
            } catch { self.error = "Failed to search: \(error.localizedDescription)" }
            isSearching = false
        }
    }

    private func addSource() {
        isLoading = true; error = nil
        Task {
            do {
                switch selectedType {
                case .tvguide:
                    guard let provider = selectedProvider else { return }
                    try await settingsViewModel.addEPGSource(name: name, url: nil, type: "tvguide",
                        tvguideProviderId: String(provider.id), tvguideZipCode: zipCode, tvguideDays: tvguideDays)
                case .xmltv:
                    try await settingsViewModel.addEPGSource(name: name, url: xmltvUrl, type: "xmltv")
                case .gracenote:
                    try await settingsViewModel.addEPGSource(name: name, url: xmltvUrl, type: "gracenote")
                }
                if let newSource = settingsViewModel.epgSources.last {
                    try? await settingsViewModel.refreshEPGSource(newSource)
                }
                dismiss()
            } catch { self.error = error.localizedDescription }
            isLoading = false
        }
    }
}
