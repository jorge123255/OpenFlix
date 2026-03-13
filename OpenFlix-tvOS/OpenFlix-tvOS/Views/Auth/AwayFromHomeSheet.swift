import SwiftUI

// MARK: - Away From Home (tvOS)
// Lets users connect remotely using a 4-char pairing code (owner) or
// 8-char invite code (family). Uses an on-screen D-pad keyboard since
// tvOS has no hardware keyboard for text fields by default.

struct AwayFromHomeSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isPresented: Bool

    @State private var code = ""
    @State private var errorMessage: String?
    @State private var isConnecting = false

    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let bg = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            HStack(spacing: 80) {
                // Left panel — instructions
                leftPanel

                // Right panel — code entry + keyboard
                rightPanel
            }
            .padding(60)
        }
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                Image(systemName: "globe")
                    .font(.system(size: 48))
                    .foregroundColor(accentColor)
            }

            Text("Away from Home")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                instructionRow(number: "1", text: "On your server, go to Settings → Remote Access")
                instructionRow(number: "2", text: "Copy the 4-character pairing code shown there")
                instructionRow(number: "3", text: "Enter it here to connect remotely")
            }

            Divider().background(Color.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 8) {
                Text("Have an invite code?")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Enter your 8-character invite code to create a new account on a friend's server.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .frame(maxWidth: 500)
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor)
                    .frame(width: 32, height: 32)
                Text(number)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(spacing: 32) {
            // Code display boxes
            codeDisplayBoxes

            // Code type hint
            Group {
                if code.count == 4 {
                    Text("Pairing code — connecting as owner")
                        .foregroundColor(.green)
                } else if code.count == 8 {
                    Text("Invite code — will create a new account")
                        .foregroundColor(.orange)
                } else if code.isEmpty {
                    Text("Enter your pairing or invite code")
                        .foregroundColor(.gray)
                } else {
                    Text("\(code.count) of 4 or 8 characters")
                        .foregroundColor(.gray)
                }
            }
            .font(.subheadline)

            // Error
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.subheadline)
                .foregroundColor(.red)
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            // TV Keypad
            TVCodeKeypad(code: $code, maxLength: 8)

            // Action buttons
            HStack(spacing: 24) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(TVSecondaryButtonStyle())

                Button(action: connect) {
                    Group {
                        if isConnecting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Connect")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .buttonStyle(TVPrimaryButtonStyle(accentColor: accentColor))
                .disabled(code.count < 4 || isConnecting)
                .opacity(code.count < 4 ? 0.5 : 1)
            }
        }
        .frame(maxWidth: 500)
    }

    // MARK: - Code Boxes

    private var codeDisplayBoxes: some View {
        HStack(spacing: 12) {
            ForEach(0..<8, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cardBg)
                        .frame(width: 56, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    index < code.count ? accentColor : Color.white.opacity(0.15),
                                    lineWidth: index < code.count ? 2 : 1
                                )
                        )

                    if index < code.count {
                        let charIndex = code.index(code.startIndex, offsetBy: index)
                        Text(String(code[charIndex]))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                // Separator between 4 and 8 chars
                .padding(.trailing, index == 3 ? 8 : 0)
            }
        }
    }

    // MARK: - Connect

    private func connect() {
        guard code.count >= 4 else { return }
        isConnecting = true
        errorMessage = nil

        Task {
            do {
                if code.count == 8 {
                    try await authViewModel.resolveInvite(code: code)
                } else {
                    try await authViewModel.resolvePairingCode(code: code)
                }
                isPresented = false
            } catch {
                errorMessage = error.localizedDescription
                isConnecting = false
            }
        }
    }
}

// MARK: - TV Code Keypad

struct TVCodeKeypad: View {
    @Binding var code: String
    var maxLength: Int

    private let rows: [[String]] = [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["A","B","C","D","E","F","G","H","I","J"],
        ["K","L","M","N","O","P","Q","R","S","T"],
        ["U","V","W","X","Y","Z","⌫","","",""]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Spacer().frame(width: 52, height: 52)
                        } else {
                            KeypadButton(key: key) {
                                handleKey(key)
                            }
                        }
                    }
                }
            }
        }
    }

    private func handleKey(_ key: String) {
        if key == "⌫" {
            if !code.isEmpty { code.removeLast() }
        } else if code.count < maxLength {
            code.append(key)
        }
    }
}

private struct KeypadButton: View {
    let key: String
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            Text(key)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isFocused ? .black : .white)
                .frame(width: 52, height: 52)
                .background(isFocused ? Color.white : Color.white.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

// MARK: - Button Styles

struct TVPrimaryButtonStyle: ButtonStyle {
    let accentColor: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(accentColor)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

struct TVSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}
