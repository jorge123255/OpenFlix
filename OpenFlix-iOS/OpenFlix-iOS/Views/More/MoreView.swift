import SwiftUI

// MARK: - More View
// Contains DVR, Settings, and other options

struct MoreView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            List {
                // DVR Section
                Section {
                    NavigationLink(destination: DVRView()) {
                        MoreRowView(
                            icon: "recordingtape",
                            iconColor: .red,
                            title: "DVR",
                            subtitle: "Recordings & scheduled"
                        )
                    }
                    
                    NavigationLink(destination: OnLaterView()) {
                        MoreRowView(
                            icon: "clock.badge.checkmark",
                            iconColor: .blue,
                            title: "On Later",
                            subtitle: "Upcoming programs"
                        )
                    }
                    
                    NavigationLink(destination: CatchupView()) {
                        MoreRowView(
                            icon: "clock.arrow.circlepath",
                            iconColor: .purple,
                            title: "Catch Up",
                            subtitle: "Watch past programs"
                        )
                    }
                }
                
                // Library Section
                Section {
                    NavigationLink(destination: SearchView()) {
                        MoreRowView(
                            icon: "magnifyingglass",
                            iconColor: .gray,
                            title: "Search",
                            subtitle: "Find movies, shows & channels"
                        )
                    }
                }
                
                // Settings Section
                Section {
                    NavigationLink(destination: SettingsView()) {
                        MoreRowView(
                            icon: "gear",
                            iconColor: .gray,
                            title: "Settings",
                            subtitle: "Server, playback & more"
                        )
                    }
                }
                
                // Profile Section
                Section {
                    if let profile = authViewModel.currentProfile {
                        Button(action: {
                            authViewModel.clearProfile()
                        }) {
                            MoreRowView(
                                icon: "person.crop.circle",
                                iconColor: .green,
                                title: profile.name,
                                subtitle: "Switch profile"
                            )
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await authViewModel.logout()
                        }
                    }) {
                        MoreRowView(
                            icon: "rectangle.portrait.and.arrow.right",
                            iconColor: .red,
                            title: "Sign Out",
                            subtitle: nil
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - More Row View

struct MoreRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .cornerRadius(8)
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MoreView()
        .environmentObject(AuthViewModel())
}
