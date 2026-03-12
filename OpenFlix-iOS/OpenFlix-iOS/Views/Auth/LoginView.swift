import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var serverURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var rememberMe = true
    @State private var showRegister = false
    @State private var isServerConnected = false
    @State private var claimCode = ""
    @State private var inviteCode = ""
    @State private var isSearchingByCode = false
    @State private var isResolvingInvite = false
    @State private var inviteStatus: InviteStatus?
    @State private var showOtherWays = false
    @State private var selectedOtherWay: OtherConnectOption?
    @State private var showAwayFromHomeSheet = false
    @State private var awayCode = ""
    @State private var awayIsLoading = false
    @State private var awayError: String?

    // Animation states
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var cardOffset: CGFloat = 50
    @State private var cardOpacity: Double = 0

    @FocusState private var focusedField: Field?

    enum Field {
        case serverURL, username, password
    }

    enum InviteStatus: Equatable {
        case success(String)
        case failure(String)
    }

    enum OtherConnectOption: String, CaseIterable, Identifiable {
        case code
        case manual

        var id: String { rawValue }

        var title: String {
            switch self {
            case .code: return "Away from Home"
            case .manual: return "Enter server address manually"
            }
        }

        var subtitle: String? {
            switch self {
            case .code: return "Enter your 4-character pairing code"
            case .manual: return nil
            }
        }

        var icon: String {
            switch self {
            case .code: return "globe"
            case .manual: return "link"
            }
        }
    }

    var body: some View {
        ZStack {
            OpenFlixColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    // Animated Logo
                    VStack(spacing: 12) {
                        Text("OpenFlix")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(OpenFlixColors.primary)
                            .shadow(color: OpenFlixColors.primary.opacity(0.5), radius: 20, x: 0, y: 0)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)

                        Text("Your Personal\nStreaming Experience")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(OpenFlixColors.textSecondary)
                            .opacity(logoOpacity)
                    }

                    Spacer().frame(height: 40)

                    VStack(spacing: 0) {
                        authContent
                    }
                    .padding(28)
                    .background(OpenFlixColors.surface.opacity(0.95))
                    .cornerRadius(24)
                    .frame(maxWidth: 500)
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            startAnimations()
            loadSavedCredentials()
            Task {
                await authViewModel.initialize()
            }
        }
        .onChange(of: authViewModel.pendingDeepLink) { _, newValue in
            guard let newValue else { return }
            handleDeepLink(newValue)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            cardOffset = 0
            cardOpacity = 1.0
        }
    }

    // MARK: - Auth Content Router

    @ViewBuilder
    private var authContent: some View {
        if isServerConnected {
            loginFormView
        } else {
            connectionFlowView
        }
    }

    // MARK: - Unified Connection Flow

    private var connectionFlowView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Looking for your server...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(OpenFlixColors.textPrimary)

                Text("We will automatically find it on your network.")
                    .font(.subheadline)
                    .foregroundColor(OpenFlixColors.textSecondary)
            }

            RadarScanView(
                statusText: authViewModel.discoveryProgress ?? "Searching your network...",
                isScanning: authViewModel.isDiscovering
            )

            if !authViewModel.discoveredServers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(OpenFlixColors.success)
                        Text("Servers Found")
                            .font(.subheadline)
                            .foregroundColor(OpenFlixColors.textSecondary)
                    }

                    ForEach(authViewModel.discoveredServers) { server in
                        DiscoveredServerRow(server: server) {
                            Task {
                                await authViewModel.selectServer(server)
                            }
                        }
                    }
                }
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            }

            if !authViewModel.isDiscovering && authViewModel.discoveredServers.isEmpty && authViewModel.error != nil {
                VStack(spacing: 12) {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 40))
                        .foregroundColor(OpenFlixColors.textTertiary)

                    Text("No servers found")
                        .font(.headline)
                        .foregroundColor(OpenFlixColors.textSecondary)

                    Text("Make sure your OpenFlix server is running")
                        .font(.caption)
                        .foregroundColor(OpenFlixColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }

            if !authViewModel.isDiscovering {
                Button(action: {
                    Task {
                        await authViewModel.discoverServers()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Scan Again")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(OpenFlixColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(OpenFlixColors.primary.opacity(0.15))
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
            }

            otherWaysSection

            if let error = authViewModel.error, !authViewModel.isDiscovering {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(OpenFlixColors.error)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(OpenFlixColors.error)
                }
                .padding(12)
                .background(OpenFlixColors.error.opacity(0.1))
                .cornerRadius(8)
            }

            // Debug log (tap to expand)
            if !authViewModel.discoveryLog.isEmpty {
                DisclosureGroup("Discovery Log") {
                    ScrollView {
                        Text(authViewModel.discoveryLog.joined(separator: "\n"))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(OpenFlixColors.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                }
                .font(.caption)
                .foregroundColor(OpenFlixColors.textTertiary)
                .padding(8)
                .background(OpenFlixColors.surfaceVariant.opacity(0.5))
                .cornerRadius(8)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: authViewModel.discoveredServers.isEmpty)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: authViewModel.isDiscovering)
    }

    private var otherWaysSection: some View {
        VStack(spacing: 12) {
            // Away from Home — opens sheet
            Button(action: { showAwayFromHomeSheet = true }) {
                HStack(spacing: 12) {
                    Image(systemName: OtherConnectOption.code.icon)
                        .foregroundColor(OpenFlixColors.primary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(OtherConnectOption.code.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(OpenFlixColors.textPrimary)

                        if let subtitle = OtherConnectOption.code.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(OpenFlixColors.textSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(OpenFlixColors.textTertiary)
                }
                .padding(12)
                .background(OpenFlixColors.surfaceVariant)
                .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
            .sheet(isPresented: $showAwayFromHomeSheet) {
                AwayFromHomeSheet(
                    code: $awayCode,
                    isLoading: awayIsLoading,
                    error: awayError,
                    onConnect: {
                        awayIsLoading = true
                        awayError = nil
                        Task {
                            if let server = await authViewModel.discoverViaCloud(claimToken: awayCode) {
                                showAwayFromHomeSheet = false
                                await authViewModel.selectServer(server, isRemote: true)
                            } else {
                                awayError = "Server not found. Check your code."
                            }
                            awayIsLoading = false
                        }
                    },
                    onCancel: { showAwayFromHomeSheet = false }
                )
                .environmentObject(authViewModel)
            }

            // Manual entry
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    selectedOtherWay = selectedOtherWay == .manual ? nil : .manual
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: OtherConnectOption.manual.icon)
                        .foregroundColor(OpenFlixColors.primary)
                        .frame(width: 24)

                    Text(OtherConnectOption.manual.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(OpenFlixColors.textPrimary)

                    Spacer()

                    Image(systemName: selectedOtherWay == .manual ? "chevron.up" : "chevron.right")
                        .foregroundColor(OpenFlixColors.textTertiary)
                }
                .padding(12)
                .background(OpenFlixColors.surfaceVariant)
                .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())

            if selectedOtherWay == .manual {
                manualEntryView
            }
        }
    }

    private var unifiedCodeEntryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connection Code")
                .font(.subheadline)
                .foregroundColor(OpenFlixColors.textSecondary)

            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(OpenFlixColors.textTertiary)
                    TextField("Enter code", text: $claimCode)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .onChange(of: claimCode) { newValue in
                            claimCode = String(newValue.uppercased().prefix(8))
                        }
                        .onSubmit { submitUnifiedCode() }
                }
                .padding(14)
                .background(OpenFlixColors.surfaceVariant)
                .cornerRadius(12)

                Button(action: submitUnifiedCode) {
                    Group {
                        if isSearchingByCode || isResolvingInvite {
                            ProgressView()
                                .tint(OpenFlixColors.background)
                                .scaleEffect(0.8)
                        } else {
                            Text("Connect")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .foregroundColor(OpenFlixColors.background)
                    .frame(width: 90)
                    .padding(.vertical, 14)
                    .background(claimCode.count >= 4 ? OpenFlixColors.primary : OpenFlixColors.primary.opacity(0.5))
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(claimCode.count < 4 || isSearchingByCode || isResolvingInvite)
            }

            Text("Enter the code from your server admin or setup screen")
                .font(.caption2)
                .foregroundColor(OpenFlixColors.textTertiary)

            if let inviteStatus {
                HStack(spacing: 8) {
                    Image(systemName: inviteStatusIcon)
                        .foregroundColor(inviteStatusColor)
                    Text(inviteStatusText)
                        .font(.caption)
                        .foregroundColor(inviteStatusColor)
                }
                .padding(10)
                .background(inviteStatusColor.opacity(0.12))
                .cornerRadius(8)
            }
        }
    }

    private var manualEntryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Server URL")
                .font(.subheadline)
                .foregroundColor(OpenFlixColors.textSecondary)

            HStack {
                Image(systemName: "link")
                    .foregroundColor(OpenFlixColors.textTertiary)
                TextField("https://your-server.example.com:32400", text: $serverURL)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .focused($focusedField, equals: .serverURL)
                    .onSubmit { connectToServer() }
            }
            .padding(14)
            .background(OpenFlixColors.surfaceVariant)
            .cornerRadius(12)

            Button(action: connectToServer) {
                HStack(spacing: 8) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(OpenFlixColors.background)
                            .scaleEffect(0.8)
                    }
                    Text("Connect")
                        .font(.headline)
                }
                .foregroundColor(OpenFlixColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(serverURL.isEmpty ? OpenFlixColors.primary.opacity(0.5) : OpenFlixColors.primary)
                .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(serverURL.isEmpty || authViewModel.isLoading)
        }
    }

    private var inviteStatusText: String {
        switch inviteStatus {
        case .success(let text): return text
        case .failure(let text): return text
        case .none: return ""
        }
    }

    private var inviteStatusColor: Color {
        switch inviteStatus {
        case .success: return OpenFlixColors.success
        case .failure: return OpenFlixColors.error
        case .none: return OpenFlixColors.textTertiary
        }
    }

    private var inviteStatusIcon: String {
        switch inviteStatus {
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        case .none: return "info.circle"
        }
    }

    // MARK: - Login Form View

    private var loginFormView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Sign In")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(OpenFlixColors.textPrimary)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(OpenFlixColors.success)
                    Text(serverURL)
                        .font(.caption)
                        .foregroundColor(OpenFlixColors.textTertiary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(OpenFlixColors.surfaceVariant)
                .cornerRadius(20)
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)

                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(OpenFlixColors.textTertiary)
                        TextField("Enter username", text: $username)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .username)
                    }
                    .padding(14)
                    .background(OpenFlixColors.surfaceVariant)
                    .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)

                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(OpenFlixColors.textTertiary)
                        SecureField("Enter password", text: $password)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .focused($focusedField, equals: .password)
                            .onSubmit { login() }
                    }
                    .padding(14)
                    .background(OpenFlixColors.surfaceVariant)
                    .cornerRadius(12)
                }

                Toggle(isOn: $rememberMe) {
                    Text("Remember Me")
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)
                }
                .tint(OpenFlixColors.primary)
            }

            if let error = authViewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(OpenFlixColors.error)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(OpenFlixColors.error.opacity(0.1))
                    .cornerRadius(8)
            }

            VStack(spacing: 12) {
                Button(action: login) {
                    Group {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(OpenFlixColors.background)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(OpenFlixColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isFormValid ? OpenFlixColors.primary : OpenFlixColors.primary.opacity(0.5))
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!isFormValid || authViewModel.isLoading)

                Button(action: { showRegister = true }) {
                    Text("New user? Create Account")
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(OpenFlixColors.surfaceVariant)
                        .cornerRadius(8)
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: resetServerSelection) {
                    Text("Change Server")
                        .font(.caption)
                        .foregroundColor(OpenFlixColors.textTertiary)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        !username.isEmpty && !password.isEmpty
    }

    private func handleDeepLink(_ deepLink: AuthDeepLink) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showOtherWays = true
        }

        switch deepLink {
        case .invite(let machineId, let token):
            selectedOtherWay = .code
            claimCode = token
            inviteCode = token
            acceptInviteFromDeepLink(machineId: machineId, token: token)
        case .connect(let url):
            selectedOtherWay = .manual
            serverURL = url
            connectToServer()
        }

        authViewModel.pendingDeepLink = nil
    }

    private func resetServerSelection() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isServerConnected = false
        }
        authViewModel.error = nil
        Task {
            await authViewModel.discoverServers()
        }
    }

    private func acceptInviteFromDeepLink(machineId: String, token: String) {
        inviteStatus = nil
        isResolvingInvite = true
        authViewModel.error = nil

        Task {
            defer { isResolvingInvite = false }
            guard let resolved = await authViewModel.resolveInvite(machineId: machineId, token: token) else {
                inviteStatus = .failure("Invite link is invalid or expired.")
                return
            }

            serverURL = resolved.server.url.absoluteString
            let success = await authViewModel.connectToServerURL(serverURL)
            if success {
                inviteStatus = .success("Invite accepted. Please sign in.")
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isServerConnected = true
                }
                focusedField = .username
            } else {
                inviteStatus = .failure("Could not connect to invited server.")
            }
        }
    }

    private func acceptInviteCode() {
        guard inviteCode.count == 8 else { return }

        inviteStatus = nil
        isResolvingInvite = true
        authViewModel.error = nil

        Task {
            defer { isResolvingInvite = false }

            guard let resolved = await authViewModel.acceptInvite(code: inviteCode) else {
                inviteStatus = .failure("Invite code not found or expired. Ask the server owner to generate a new one.")
                return
            }

            serverURL = resolved.url.absoluteString
            let success = await authViewModel.connectToServerURL(serverURL)
            if success {
                inviteStatus = .success("Invite accepted. Please sign in.")
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isServerConnected = true
                }
                focusedField = .username
            } else {
                inviteStatus = .failure("Could not connect to invited server.")
            }
        }
    }

    private func loadSavedCredentials() {
        if let savedURL = UserDefaults.standard.serverURL {
            serverURL = savedURL.absoluteString
        }
        if UserDefaults.standard.rememberMe {
            username = UserDefaults.standard.lastUsername ?? ""
        }
    }

    /// Smart code handler: 4-char = claim code (find server), 5-8 char = invite code (join server)
    private func submitUnifiedCode() {
        let code = claimCode.trimmingCharacters(in: .whitespaces)
        if code.count <= 4 {
            findServerByCode()
        } else {
            inviteCode = code
            acceptInviteCode()
        }
    }

    private func findServerByCode() {
        guard claimCode.count == 4 else { return }

        isSearchingByCode = true
        authViewModel.error = nil

        Task {
            defer { isSearchingByCode = false }

            if let server = await authViewModel.discoverViaCloud(claimToken: claimCode) {
                serverURL = server.url.absoluteString
                UserDefaults.standard.serverURL = server.url
                await OpenFlixAPI.shared.configure(serverURL: server.url, token: nil)

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isServerConnected = true
                }
                focusedField = .username
            } else {
                authViewModel.error = "No server found with code \"\(claimCode)\". Make sure the code is correct and your server is online."
            }
        }
    }

    private func connectToServer() {
        guard !serverURL.isEmpty else { return }

        Task {
            let success = await authViewModel.connectToServerURL(serverURL)
            if success {
                if let url = UserDefaults.standard.serverURL {
                    serverURL = url.absoluteString
                }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isServerConnected = true
                }
                focusedField = .username
            }
        }
    }

    private func login() {
        guard let url = URL(string: serverURL) else {
            authViewModel.error = "Invalid server URL"
            return
        }

        Task {
            await authViewModel.login(
                serverURL: url,
                username: username,
                password: password,
                rememberMe: rememberMe
            )
        }
    }
}

// MARK: - Discovered Server Row

struct DiscoveredServerRow: View {
    let server: DiscoveredServer
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(OpenFlixColors.primary.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "tv")
                        .font(.title2)
                        .foregroundColor(OpenFlixColors.primary)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(server.name)
                        .font(.headline)
                        .foregroundColor(OpenFlixColors.textPrimary)

                    Text("\(server.host):\(server.port)")
                        .font(.caption)
                        .foregroundColor(OpenFlixColors.textSecondary)
                }

                Spacer()

                // Version badge
                if server.version != "unknown" {
                    Text("v\(server.version)")
                        .font(.caption2)
                        .foregroundColor(OpenFlixColors.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(OpenFlixColors.surfaceElevated)
                        .cornerRadius(6)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(OpenFlixColors.textTertiary)
            }
            .padding(14)
            .background(OpenFlixColors.surfaceVariant)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(OpenFlixColors.surfaceElevated, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Register View

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var serverURL = ""
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        NavigationStack {
            ZStack {
                OpenFlixColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Server URL")
                                .font(.subheadline)
                                .foregroundColor(OpenFlixColors.textSecondary)

                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(OpenFlixColors.textTertiary)
                                TextField("http://your-server:32400", text: $serverURL)
                                    .textFieldStyle(.plain)
                                    .autocapitalization(.none)
                            }
                            .padding(14)
                            .background(OpenFlixColors.surfaceVariant)
                            .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.subheadline)
                                .foregroundColor(OpenFlixColors.textSecondary)

                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(OpenFlixColors.textTertiary)
                                TextField("Your name", text: $name)
                                    .textFieldStyle(.plain)
                            }
                            .padding(14)
                            .background(OpenFlixColors.surfaceVariant)
                            .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email (optional)")
                                .font(.subheadline)
                                .foregroundColor(OpenFlixColors.textSecondary)

                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(OpenFlixColors.textTertiary)
                                TextField("email@example.com", text: $email)
                                    .textFieldStyle(.plain)
                                    .keyboardType(.emailAddress)
                            }
                            .padding(14)
                            .background(OpenFlixColors.surfaceVariant)
                            .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(OpenFlixColors.textSecondary)

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(OpenFlixColors.textTertiary)
                                SecureField("Create password", text: $password)
                                    .textFieldStyle(.plain)
                            }
                            .padding(14)
                            .background(OpenFlixColors.surfaceVariant)
                            .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundColor(OpenFlixColors.textSecondary)

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(OpenFlixColors.textTertiary)
                                SecureField("Confirm password", text: $confirmPassword)
                                    .textFieldStyle(.plain)
                            }
                            .padding(14)
                            .background(OpenFlixColors.surfaceVariant)
                            .cornerRadius(12)
                        }

                        if let error = authViewModel.error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(OpenFlixColors.error)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(OpenFlixColors.error.opacity(0.1))
                                .cornerRadius(8)
                        }

                        Button(action: register) {
                            Group {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(OpenFlixColors.background)
                                } else {
                                    Text("Create Account")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(OpenFlixColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isFormValid ? OpenFlixColors.primary : OpenFlixColors.primary.opacity(0.5))
                            .cornerRadius(12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(!isFormValid || authViewModel.isLoading)

                        Text("First user registered becomes the admin.")
                            .font(.caption2)
                            .foregroundColor(OpenFlixColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                }
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let url = UserDefaults.standard.serverURL {
                serverURL = url.absoluteString
            }
        }
    }

    private var isFormValid: Bool {
        !serverURL.isEmpty && !name.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 6
    }

    private func register() {
        guard let url = URL(string: serverURL) else {
            authViewModel.error = "Invalid server URL"
            return
        }

        Task {
            await authViewModel.register(
                serverURL: url,
                name: name,
                email: email,
                password: password
            )
            if authViewModel.isAuthenticated {
                dismiss()
            }
        }
    }
}

// MARK: - Invite Register Sheet

struct InviteRegisterSheet: View {
    let serverName: String
    @Binding var username: String
    @Binding var email: String
    @Binding var password: String
    let isLoading: Bool
    let error: String?
    let onAccept: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("You've been invited to \(serverName)")
                            .font(.subheadline)
                    }
                }

                Section("Create Your Account") {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button(action: onAccept) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Join Server")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(username.isEmpty || email.isEmpty || password.count < 6 || isLoading)
                }
            }
            .navigationTitle("Join \(serverName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}
