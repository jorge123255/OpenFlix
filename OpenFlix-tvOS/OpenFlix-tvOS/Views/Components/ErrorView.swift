import SwiftUI

struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)

            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InlineErrorView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionTitle: String = "Get Started"

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            if let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NetworkUnavailableView: View {
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("No Connection")
                .font(.title2)
                .fontWeight(.bold)

            Text("Please check your network connection and try again.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ErrorView(message: "Failed to load content")
}
