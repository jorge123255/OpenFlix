import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int, String?)
    case unauthorized
    case notFound
    case rateLimited
    case networkUnavailable
    case timeout
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to parse response: \(Self.describeDecodingError(error))"
        case .serverError(let code, let message):
            return message ?? "Server error (code: \(code))"
        case .unauthorized:
            return "Authentication required"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests. Please wait and try again."
        case .networkUnavailable:
            return "Network unavailable"
        case .timeout:
            return "Request timed out"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    private static func describeDecodingError(_ error: Error) -> String {
        guard let decodingError = error as? DecodingError else {
            return error.localizedDescription
        }

        switch decodingError {
        case .typeMismatch(let type, let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            return "Type mismatch for '\(path)': expected \(type)"
        case .valueNotFound(let type, let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            return "Missing value for '\(path)': expected \(type)"
        case .keyNotFound(let key, let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            return "Missing key '\(key.stringValue)' at '\(path)'"
        case .dataCorrupted(let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            return "Data corrupted at '\(path)': \(context.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }

    var isAuthError: Bool {
        if case .unauthorized = self { return true }
        return false
    }
}
