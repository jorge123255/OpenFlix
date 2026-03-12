import SwiftUI

struct AwayFromHomeSheet: View {
    @Binding var code: String
    var isLoading: Bool
    var error: String?
    var onConnect: () -> Void
    var onCancel: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack {
            OpenFlixColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Cancel button row
                HStack {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.body)
                            .foregroundColor(OpenFlixColors.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(OpenFlixColors.surface)
                            .cornerRadius(20)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 32)

                // Globe icon
                ZStack {
                    Circle()
                        .fill(OpenFlixColors.accent.opacity(0.2))
                        .frame(width: 90, height: 90)
                    Image(systemName: "globe")
                        .font(.system(size: 42))
                        .foregroundColor(OpenFlixColors.accent)
                }
                .padding(.bottom, 24)

                // Title
                Text("Away from Home")
                    .font(.title2.bold())
                    .foregroundColor(OpenFlixColors.textPrimary)
                    .padding(.bottom, 8)

                // Subtitle
                Text("Enter the 4-character pairing code shown in your server's Settings → Remote Access")
                    .font(.subheadline)
                    .foregroundColor(OpenFlixColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)

                // 4-box code entry
                FourCharCodeEntry(code: $code, isFocused: $isFieldFocused)
                    .padding(.bottom, 12)

                Text("Tap to enter code")
                    .font(.caption)
                    .foregroundColor(OpenFlixColors.textTertiary)
                    .padding(.bottom, 40)

                // Error
                if let error = error {
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
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }

                // Connect button
                Button(action: onConnect) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(OpenFlixColors.background)
                        } else {
                            Text("Connect")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(OpenFlixColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(code.count >= 4 ? OpenFlixColors.accent : OpenFlixColors.accent.opacity(0.4))
                    .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(code.count < 4 || isLoading)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFieldFocused = true
            }
        }
    }
}

// MARK: - 4-Character Code Entry

struct FourCharCodeEntry: View {
    @Binding var code: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        ZStack {
            // Hidden real text field
            TextField("", text: $code)
                .keyboardType(.asciiCapable)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .focused(isFocused)
                .onChange(of: code) { newValue in
                    code = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(4))
                }
                .frame(width: 1, height: 1)
                .opacity(0.01)

            // Visual boxes
            HStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { index in
                    CharBox(
                        character: index < code.count ? String(code[code.index(code.startIndex, offsetBy: index)]) : "",
                        isActive: isFocused.wrappedValue && index == min(code.count, 3)
                    )
                    .onTapGesture {
                        isFocused.wrappedValue = true
                    }
                }
            }
        }
    }
}

struct CharBox: View {
    let character: String
    let isActive: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(OpenFlixColors.surface)
                .frame(width: 68, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isActive ? OpenFlixColors.accent : OpenFlixColors.surfaceElevated, lineWidth: isActive ? 2 : 1)
                )

            Text(character)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(OpenFlixColors.textPrimary)
        }
    }
}
