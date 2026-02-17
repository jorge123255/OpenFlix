import SwiftUI

@main
struct OpenFlixApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()

    init() {
        // Configure API on launch if we have stored credentials
        if let serverURL = UserDefaults.standard.serverURL,
           let token = KeychainHelper.shared.getToken() {
            Task {
                await OpenFlixAPI.shared.configure(serverURL: serverURL, token: token)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(settingsViewModel)
        }
    }
}
