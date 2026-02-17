import SwiftUI

struct AuthenticatedImage: View {
    let path: String?
    var placeholder: AnyView = AnyView(Color.gray.opacity(0.3))

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ProgressView()
            } else {
                placeholder
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let path = path, !path.isEmpty else { return }
        guard let serverURL = UserDefaults.standard.serverURL else { return }

        isLoading = true
        defer { isLoading = false }

        // Build full URL
        let fullURL: URL
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            guard let url = URL(string: path) else { return }
            fullURL = url
        } else {
            fullURL = serverURL.appendingPathComponent(path)
        }

        // Create request with auth
        var request = URLRequest(url: fullURL)
        if let token = KeychainHelper.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            if let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.image = uiImage
                }
            }
        } catch {
            // Silently fail - show placeholder
        }
    }
}

// Convenience initializer with system image placeholder
extension AuthenticatedImage {
    init(path: String?, systemPlaceholder: String) {
        self.path = path
        self.placeholder = AnyView(
            Image(systemName: systemPlaceholder)
                .font(.largeTitle)
                .foregroundColor(.gray)
        )
    }
}
