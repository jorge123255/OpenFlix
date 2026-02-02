import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.currentProfile == nil {
                    ProfileSelectionView()
                } else {
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
        .task {
            // Try to auto-discover server on local network first
            await authViewModel.initialize()
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            MoviesView()
                .tabItem {
                    Label("Movies", systemImage: "film")
                }
                .tag(1)

            TVShowsView()
                .tabItem {
                    Label("TV Shows", systemImage: "tv")
                }
                .tag(2)

            LiveTVView()
                .tabItem {
                    Label("Live TV", systemImage: "play.tv")
                }
                .tag(3)

            DVRView()
                .tabItem {
                    Label("DVR", systemImage: "record.circle")
                }
                .tag(4)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(5)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(6)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(SettingsViewModel())
}
