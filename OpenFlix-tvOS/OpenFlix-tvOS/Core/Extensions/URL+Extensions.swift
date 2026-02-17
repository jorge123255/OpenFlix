import Foundation

extension URL {
    /// Creates a thumbnail URL by appending the server base URL
    func withServer(_ serverURL: URL?) -> URL? {
        guard let serverURL = serverURL else { return self }

        // If already absolute, return as is
        if self.scheme != nil {
            return self
        }

        // Append to server URL
        return serverURL.appendingPathComponent(self.path)
    }

    /// Creates an image URL with optional size parameters
    func withImageSize(width: Int? = nil, height: Int? = nil) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        var queryItems = components?.queryItems ?? []

        if let width = width {
            queryItems.append(URLQueryItem(name: "width", value: "\(width)"))
        }
        if let height = height {
            queryItems.append(URLQueryItem(name: "height", value: "\(height)"))
        }

        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        return components?.url ?? self
    }

    /// Checks if URL is an HLS stream
    var isHLSStream: Bool {
        pathExtension.lowercased() == "m3u8"
    }

    /// Appends auth token as query parameter
    func withToken(_ token: String?) -> URL {
        guard let token = token else { return self }

        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: "X-Plex-Token", value: token))
        components?.queryItems = queryItems
        return components?.url ?? self
    }
}
