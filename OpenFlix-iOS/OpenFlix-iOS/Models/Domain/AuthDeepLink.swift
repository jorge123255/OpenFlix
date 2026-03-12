import Foundation

/// Deep link types for authentication flows
enum AuthDeepLink: Equatable {
    case invite(machineId: String, token: String)
    case connect(url: String)
}
