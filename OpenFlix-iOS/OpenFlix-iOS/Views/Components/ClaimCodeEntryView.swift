import SwiftUI

struct ClaimCodeEntryView: View {
    @Binding var claimCode: String
    var isLoading: Bool
    var onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Claim Code")
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
                            claimCode = String(newValue.uppercased().prefix(4))
                        }
                        .onSubmit { onSubmit() }
                }
                .padding(14)
                .background(OpenFlixColors.surfaceVariant)
                .cornerRadius(12)

                Button(action: onSubmit) {
                    Group {
                        if isLoading {
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
                .disabled(claimCode.count != 4 || isLoading)
            }

            Text("Enter the 4-character code from your server's settings")
                .font(.caption2)
                .foregroundColor(OpenFlixColors.textTertiary)
        }
    }
}

#Preview {
    ClaimCodeEntryView(claimCode: .constant("ABCD"), isLoading: false, onSubmit: {})
        .padding()
        .background(OpenFlixColors.background)
}
