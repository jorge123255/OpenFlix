import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var serverURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var rememberMe = true
    @State private var isDiscovering = false
    @State private var showRegister = false
    @State private var isServerConnected = false

    @FocusState private var focusedField: Field?

    enum Field {
        case serverURL, username, password
    }

    var body: some View {
        ZStack {
            // Background gradient
            OpenFlixColors.backgroundGradient
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 12) {
                    Text("OpenFlix")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(OpenFlixColors.primary)

                    Text("Your Personal Streaming Experience")
                        .font(.title3)
                        .foregroundColor(OpenFlixColors.textSecondary)
                }

                Spacer().frame(height: 60)

                // Auth Card
                VStack(spacing: 0) {
                    if !isServerConnected {
                        serverConnectionView
                    } else {
                        loginFormView
                    }
                }
                .padding(40)
                .background(OpenFlixColors.surface.opacity(0.95))
                .cornerRadius(24)
                .frame(maxWidth: 600)

                Spacer()
            }
            .padding(48)
        }
        .onAppear {
            loadSavedCredentials()
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
    }

    // MARK: - Server Connection View

    private var serverConnectionView: some View {
        VStack(spacing: 24) {
            Text("Connect to Server")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(OpenFlixColors.textPrimary)

            // Discovered servers
            if !authViewModel.discoveredServers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Servers Found on Network")
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)

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
            } else if authViewModel.isDiscovering {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(OpenFlixColors.primary)
                    Text("Searching for servers...")
                        .foregroundColor(OpenFlixColors.textSecondary)
                }
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 12) {
                    Text("No servers found automatically")
                        .foregroundColor(OpenFlixColors.textTertiary)

                    Button(action: {
                        Task {
                            await authViewModel.discoverAndAutoConnect()
                        }
                    }) {
                        Text("Scan Again")
                            .font(.subheadline)
                            .foregroundColor(OpenFlixColors.textPrimary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(OpenFlixColors.surfaceVariant)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.card)
                }
                .padding(.vertical, 8)
            }

            // Manual URL entry
            VStack(alignment: .leading, spacing: 8) {
                Text("Server URL")
                    .font(.subheadline)
                    .foregroundColor(OpenFlixColors.textSecondary)

                TextField("e.g., 192.168.1.100:32400", text: $serverURL)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(16)
                    .background(OpenFlixColors.surfaceVariant)
                    .cornerRadius(12)
                    .focused($focusedField, equals: .serverURL)
            }

            // Connect button
            Button(action: connectToServer) {
                Text("Connect")
                    .font(.headline)
                    .foregroundColor(OpenFlixColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(OpenFlixColors.primary)
                    .cornerRadius(12)
            }
            .buttonStyle(.card)
            .disabled(serverURL.isEmpty)
            .opacity(serverURL.isEmpty ? 0.5 : 1)

            // Error
            if let error = authViewModel.error {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(OpenFlixColors.error)
                    .padding(.top, 8)
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

                Text("Connected to: \(serverURL)")
                    .font(.caption)
                    .foregroundColor(OpenFlixColors.textTertiary)
            }

            VStack(spacing: 16) {
                // Username
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)

                    TextField("Enter username", text: $username)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(16)
                        .background(OpenFlixColors.surfaceVariant)
                        .cornerRadius(12)
                        .focused($focusedField, equals: .username)
                }

                // Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)

                    SecureField("Enter password", text: $password)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(16)
                        .background(OpenFlixColors.surfaceVariant)
                        .cornerRadius(12)
                        .focused($focusedField, equals: .password)
                }

                // Remember me
                Toggle(isOn: $rememberMe) {
                    Text("Remember Me")
                        .foregroundColor(OpenFlixColors.textSecondary)
                }
                .tint(OpenFlixColors.primary)
            }

            // Error
            if let error = authViewModel.error {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(OpenFlixColors.error)
                    .padding(.vertical, 8)
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
                    .background(OpenFlixColors.primary)
                    .cornerRadius(12)
                }
                .buttonStyle(.card)
                .disabled(!isFormValid || authViewModel.isLoading)
                .opacity(isFormValid ? 1 : 0.5)

                Button(action: { showRegister = true }) {
                    Text("New user? Create Account")
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(OpenFlixColors.surfaceVariant)
                        .cornerRadius(8)
                }
                .buttonStyle(.card)

                Button(action: { isServerConnected = false }) {
                    Text("Change Server")
                        .font(.caption)
                        .foregroundColor(OpenFlixColors.textTertiary)
                }
                .buttonStyle(.card)
            }
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        !username.isEmpty && !password.isEmpty
    }

    private func loadSavedCredentials() {
        if let savedURL = UserDefaults.standard.serverURL {
            serverURL = savedURL.absoluteString
        }
        if UserDefaults.standard.rememberMe {
            username = UserDefaults.standard.lastUsername ?? ""
        }
    }

    private func connectToServer() {
        guard !serverURL.isEmpty else { return }

        var urlString = serverURL
        if !urlString.hasPrefix("http") {
            urlString = "http://\(urlString)"
        }

        guard URL(string: urlString) != nil else {
            authViewModel.error = "Invalid server URL"
            return
        }

        serverURL = urlString
        isServerConnected = true
        focusedField = .username
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

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
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

                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(isFocused ? OpenFlixColors.primary : OpenFlixColors.textTertiary)
            }
            .padding(16)
            .background(isFocused ? OpenFlixColors.focusBackground : OpenFlixColors.surfaceVariant)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? OpenFlixColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.card)
        .focused($isFocused)
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
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Server URL")
                                .font(.subheadline)
                                .foregroundColor(OpenFlixColors.textSecondary)

                            TextField("http://your-server:32400", text: $serverURL)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(OpenFlixColors.surfaceVariant)
                                .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.subheadline)
                                .foregroundColor(OpenFlixColors.textSecondary)

                            TextField("Your name", text: $name)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(OpenFlixColors.surfaceVariant)
                                .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email (optional)")
                                .font(.subheadline)
                                .foregroundColor(OpenFlixColors.textSecondary)

                            TextField("email@example.com", text: $email)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(OpenFlixColors.surfaceVariant)
                                .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(OpenFlixColors.textSecondary)

                            SecureField("Create password", text: $password)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(OpenFlixColors.surfaceVariant)
                                .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundColor(OpenFlixColors.textSecondary)

                            SecureField("Confirm password", text: $confirmPassword)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(OpenFlixColors.surfaceVariant)
                                .cornerRadius(12)
                        }

                        if let error = authViewModel.error {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(OpenFlixColors.error)
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
                            .background(OpenFlixColors.primary)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.card)
                        .disabled(!isFormValid || authViewModel.isLoading)
                        .opacity(isFormValid ? 1 : 0.5)
                    }
                    .padding(40)
                }
            }
            .navigationTitle("Create Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !serverURL.isEmpty && !name.isEmpty && !password.isEmpty && password == confirmPassword
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
