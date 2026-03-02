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
    @State private var isSearchingByCode = false
    // Invite flow
    @State private var inviteCode = ""
    @State private var isResolvingInvite = false
    @State private var resolvedInviteServer: DiscoveredServer?
    @State private var resolvedInviteServerName = ""
    @State private var resolvedInviteToken = ""
    @State private var showInviteRegister = false
    @State private var inviteRegUsername = ""
    @State private var inviteRegEmail = ""
    @State private var inviteRegPassword = ""

    // Animation states
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var cardOffset: CGFloat = 50
    @State private var cardOpacity: Double = 0
    @State private var scanPulse = false

    @FocusState private var focusedField: Field?

    enum Field {
        case serverURL, username, password
    }

    var body: some View {
        ZStack {
            // Background - dark purple matching main app theme
            Color(red: 17/255, green: 12/255, blue: 33/255)
                .ignoresSafeArea()

            // Content
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

                    // Auth Card with animation
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
            switch authViewModel.connectionMode {
            case .selection:
                modeSelectionView
            case .atHome:
                discoveryView
            case .awayFromHome:
                serverFormView
            }
        }
    }

    // MARK: - Mode Selection (At Home / Away from Home)

    private var modeSelectionView: some View {
        VStack(spacing: 24) {
            Text("How are you connecting?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(OpenFlixColors.textPrimary)
                .multilineTextAlignment(.center)

            // At Home button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    authViewModel.selectAtHome()
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(OpenFlixColors.primary.opacity(0.2))
                            .frame(width: 56, height: 56)
                        Image(systemName: "house.fill")
                            .font(.system(size: 24))
                            .foregroundColor(OpenFlixColors.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("At Home")
                            .font(.headline)
                            .foregroundColor(OpenFlixColors.textPrimary)
                        Text("Auto-discover server on your network")
                            .font(.caption)
                            .foregroundColor(OpenFlixColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(OpenFlixColors.textTertiary)
                }
                .padding(16)
                .background(OpenFlixColors.surfaceVariant)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(OpenFlixColors.surfaceElevated, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // Away from Home button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    authViewModel.selectAwayFromHome()
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(OpenFlixColors.secondary.opacity(0.2))
                            .frame(width: 56, height: 56)
                        Image(systemName: "globe")
                            .font(.system(size: 24))
                            .foregroundColor(OpenFlixColors.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Away from Home")
                            .font(.headline)
                            .foregroundColor(OpenFlixColors.textPrimary)
                        Text("Enter your server URL manually")
                            .font(.caption)
                            .foregroundColor(OpenFlixColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(OpenFlixColors.textTertiary)
                }
                .padding(16)
                .background(OpenFlixColors.surfaceVariant)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(OpenFlixColors.surfaceElevated, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Discovery View (At Home)

    private var discoveryView: some View {
        VStack(spacing: 24) {
            // Header with back button
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        authViewModel.goBackToModeSelection()
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(OpenFlixColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(OpenFlixColors.surfaceVariant)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())

                Spacer()

                Text("Find Your Server")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(OpenFlixColors.textPrimary)

                Spacer()

                // Balance spacer
                Color.clear.frame(width: 36, height: 36)
            }

            // Discovery status
            if authViewModel.isDiscovering {
                // Animated scanning view
                VStack(spacing: 16) {
                    ZStack {
                        // Pulsing rings
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .stroke(OpenFlixColors.primary.opacity(0.3), lineWidth: 2)
                                .frame(width: 60 + CGFloat(i * 30), height: 60 + CGFloat(i * 30))
                                .scaleEffect(scanPulse ? 1.2 : 1.0)
                                .opacity(scanPulse ? 0 : 0.5)
                                .animation(
                                    .easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.3),
                                    value: scanPulse
                                )
                        }

                        // Center icon
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 28))
                            .foregroundColor(OpenFlixColors.primary)
                    }
                    .frame(height: 120)
                    .onAppear { scanPulse = true }

                    Text(authViewModel.discoveryProgress ?? "Scanning network...")
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }

            // Discovered servers list
            if !authViewModel.discoveredServers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(OpenFlixColors.primary)
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

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(OpenFlixColors.surfaceVariant)
                            .frame(height: 1)
                        Text("or enter manually")
                            .font(.caption)
                            .foregroundColor(OpenFlixColors.textTertiary)
                        Rectangle()
                            .fill(OpenFlixColors.surfaceVariant)
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)
                }
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            }

            // No servers found
            if !authViewModel.isDiscovering && authViewModel.discoveredServers.isEmpty && authViewModel.error != nil {
                VStack(spacing: 16) {
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
                .padding(.vertical, 16)
            }

            // Manual URL entry (always shown)
            VStack(alignment: .leading, spacing: 8) {
                Text("Server URL")
                    .font(.subheadline)
                    .foregroundColor(OpenFlixColors.textSecondary)

                HStack {
                    Image(systemName: "link")
                        .foregroundColor(OpenFlixColors.textTertiary)
                    TextField("192.168.1.100:32400", text: $serverURL)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .serverURL)
                }
                .padding(14)
                .background(OpenFlixColors.surfaceVariant)
                .cornerRadius(12)
            }

            // Action buttons — always show Connect, only show Scan Again when not searching
            HStack(spacing: 12) {
                if !authViewModel.isDiscovering {
                    // Scan Again
                    Button(action: {
                        scanPulse = false
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
                        .padding(.vertical, 14)
                        .background(OpenFlixColors.primary.opacity(0.15))
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                // Connect manually — always visible
                Button(action: connectToServer) {
                    HStack(spacing: 6) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(OpenFlixColors.background)
                                .scaleEffect(0.8)
                        }
                        Text("Connect")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(OpenFlixColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(serverURL.isEmpty ? OpenFlixColors.primary.opacity(0.5) : OpenFlixColors.primary)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(serverURL.isEmpty || authViewModel.isLoading)
            }

            // Error
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
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: authViewModel.discoveredServers.isEmpty)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: authViewModel.isDiscovering)
    }

    // MARK: - Server Form View (Away from Home)

    private var serverFormView: some View {
        VStack(spacing: 24) {
            // Header with back button
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        authViewModel.goBackToModeSelection()
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(OpenFlixColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(OpenFlixColors.surfaceVariant)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())

                Spacer()

                Text("Connect to Server")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(OpenFlixColors.textPrimary)

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }

            // Server URL field
            VStack(alignment: .leading, spacing: 8) {
                Text("Server URL")
                    .font(.subheadline)
                    .foregroundColor(OpenFlixColors.textSecondary)

                HStack {
                    Image(systemName: "globe")
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

                Text("Enter your server's public URL or IP address")
                    .font(.caption2)
                    .foregroundColor(OpenFlixColors.textTertiary)
            }

            // Connect button
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
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(serverURL.isEmpty ? OpenFlixColors.primary.opacity(0.5) : OpenFlixColors.primary)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(serverURL.isEmpty || authViewModel.isLoading)

            // Divider
            HStack {
                Rectangle()
                    .fill(OpenFlixColors.surfaceVariant)
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundColor(OpenFlixColors.textTertiary)
                Rectangle()
                    .fill(OpenFlixColors.surfaceVariant)
                    .frame(height: 1)
            }

            // Link with Code section
            VStack(alignment: .leading, spacing: 8) {
                Text("Link with Code")
                    .font(.subheadline)
                    .foregroundColor(OpenFlixColors.textSecondary)

                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(OpenFlixColors.textTertiary)
                        TextField("ABCD", text: $claimCode)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .onChange(of: claimCode) { newValue in
                                // Limit to 4 characters, uppercase only
                                claimCode = String(newValue.uppercased().prefix(4))
                            }
                    }
                    .padding(14)
                    .background(OpenFlixColors.surfaceVariant)
                    .cornerRadius(12)

                    Button(action: findServerByCode) {
                        Group {
                            if isSearchingByCode {
                                ProgressView()
                                    .tint(OpenFlixColors.background)
                                    .scaleEffect(0.8)
                            } else {
                                Text("Find")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .foregroundColor(OpenFlixColors.background)
                        .frame(width: 80)
                        .padding(.vertical, 14)
                        .background(claimCode.count == 4 ? OpenFlixColors.secondary : OpenFlixColors.secondary.opacity(0.5))
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(claimCode.count != 4 || isSearchingByCode)
                }

                Text("Enter the 4-character code from your server's settings")
                    .font(.caption2)
                    .foregroundColor(OpenFlixColors.textTertiary)
            }

            // Invite code section
            VStack(alignment: .leading, spacing: 8) {
                Text("Got an Invite?")
                    .font(.subheadline)
                    .foregroundColor(OpenFlixColors.textSecondary)

                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(OpenFlixColors.textTertiary)
                        TextField("ABCD1234", text: $inviteCode)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .onChange(of: inviteCode) { newValue in
                                inviteCode = String(newValue.uppercased().prefix(8))
                            }
                    }
                    .padding(14)
                    .background(OpenFlixColors.surfaceVariant)
                    .cornerRadius(12)

                    Button(action: redeemInviteCode) {
                        Group {
                            if isResolvingInvite {
                                ProgressView()
                                    .tint(OpenFlixColors.background)
                                    .scaleEffect(0.8)
                            } else {
                                Text("Join")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .foregroundColor(OpenFlixColors.background)
                        .frame(width: 80)
                        .padding(.vertical, 14)
                        .background(inviteCode.count == 8 ? Color.green : Color.green.opacity(0.5))
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(inviteCode.count != 8 || isResolvingInvite)
                }

                Text("Enter the 8-character invite code sent by a server owner")
                    .font(.caption2)
                    .foregroundColor(OpenFlixColors.textTertiary)
            }
            .sheet(isPresented: $showInviteRegister) {
                InviteRegisterSheet(
                    serverName: resolvedInviteServerName,
                    username: $inviteRegUsername,
                    email: $inviteRegEmail,
                    password: $inviteRegPassword,
                    isLoading: authViewModel.isLoading,
                    error: authViewModel.error,
                    onAccept: {
                        guard let server = resolvedInviteServer else { return }
                        Task {
                            await authViewModel.acceptInvite(
                                server: server,
                                token: resolvedInviteToken,
                                username: inviteRegUsername,
                                email: inviteRegEmail,
                                password: inviteRegPassword
                            )
                            if authViewModel.isAuthenticated {
                                showInviteRegister = false
                            }
                        }
                    },
                    onCancel: { showInviteRegister = false }
                )
            }

            // Error
            if let error = authViewModel.error {
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

                // Server info pill
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
                // Username
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

                // Password
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

                // Remember me
                Toggle(isOn: $rememberMe) {
                    Text("Remember Me")
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)
                }
                .tint(OpenFlixColors.primary)
            }

            // Error
            if let error = authViewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(OpenFlixColors.error)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(OpenFlixColors.error.opacity(0.1))
                    .cornerRadius(8)
            }

            // Buttons
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

                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isServerConnected = false
                        authViewModel.goBackToModeSelection()
                    }
                }) {
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

    private func redeemInviteCode() {
        guard inviteCode.count == 8 else { return }

        // Invite deep link format: openflix://invite/MACHINEID/TOKEN
        // Manual code entry: we treat the first part as machineId lookup via code
        // The invite code IS the token; machineId is retrieved from the server via the registry
        // We split the 8-char code: first we try it as a straight token against cloud registry
        isResolvingInvite = true
        authViewModel.error = nil

        Task {
            defer { isResolvingInvite = false }

            // Ask cloud registry: any server registered with this invite token?
            guard let baseURL = "https://discover.openflix.app" as String?,
                  let url = URL(string: "\(baseURL)/servers?invite=\(inviteCode)") else {
                authViewModel.error = "Could not contact discovery service"
                return
            }

            var req = URLRequest(url: url)
            req.timeoutInterval = 5
            if let (data, resp) = try? await URLSession.shared.data(for: req),
               let http = resp as? HTTPURLResponse, http.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let machineId = json["machineId"] as? String,
               let host = (json["publicIp"] as? String ?? json["host"] as? String),
               !host.isEmpty {
                let port = json["port"] as? Int ?? 32400
                let name = json["name"] as? String ?? "OpenFlix Server"
                resolvedInviteServer = DiscoveredServer(name: name, version: "unknown", machineId: machineId, host: host, port: port)
                resolvedInviteServerName = name
                resolvedInviteToken = inviteCode
                showInviteRegister = true
            } else {
                authViewModel.error = "Invite code not found or expired. Ask the server owner to generate a new one."
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

    private func findServerByCode() {
        guard claimCode.count == 4 else { return }

        isSearchingByCode = true
        authViewModel.error = nil

        Task {
            defer { isSearchingByCode = false }

            if let server = await authViewModel.discoverViaCloud(claimToken: claimCode) {
                // Found server via claim code - connect
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
                // Update serverURL to the cleaned version
                if let url = UserDefaults.standard.serverURL {
                    serverURL = url.absoluteString
                }

                // For "At Home" mode, go directly to profile selection (no login)
                if authViewModel.connectionMode == .atHome {
                    await authViewModel.selectServer(DiscoveredServer(
                        name: "OpenFlix Server",
                        version: "unknown",
                        machineId: serverURL,
                        host: URL(string: serverURL)?.host ?? serverURL,
                        port: URL(string: serverURL)?.port ?? 32400
                    ))
                } else {
                    // "Away from Home" - show login form
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isServerConnected = true
                    }
                    focusedField = .username
                }
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
