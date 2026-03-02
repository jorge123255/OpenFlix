import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.currentProfile != nil {
                    // New Xfinity-style 5-tab navigation
                    XfinityTabView()
                } else {
                    ProfileSelectionView()
                }
            } else {
                LoginView()
            }
        }
        .environmentObject(authViewModel)
    }
}

// MARK: - Main Tab View (YouTube TV Style - 4 Tabs)

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @StateObject private var miniPlayerManager = MiniPlayerManager.shared
    @State private var showFullPlayer = false
    @State private var showSettings = false
    @State private var showProfilePicker = false
    
    init() {
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Navigation bar appearance  
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                TabView(selection: $selectedTab) {
                    // Tab 1: Home
                    HomeTabView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    // Tab 2: Live
                    AdaptiveLiveTVView()
                        .tabItem {
                            Label("Live", systemImage: "antenna.radiowaves.left.and.right")
                        }
                        .tag(1)
                    
                    // Tab 3: Library (DVR + Recordings + On Later)
                    LibraryView()
                        .tabItem {
                            Label("Library", systemImage: "rectangle.stack.fill")
                        }
                        .tag(2)
                    
                    // Tab 4: Search
                    SearchView()
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(3)
                }
                .tint(.red)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("OpenFlix")
                            .font(.title2.bold())
                            .foregroundColor(.red)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            // Settings
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gear")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                            }
                            
                            // Profile switcher
                            Button {
                                showProfilePicker = true
                            } label: {
                                ProfileAvatarButton(profile: authViewModel.currentProfile)
                            }
                        }
                    }
                }
            }
            
            // Mini Player overlay
            if miniPlayerManager.isShowing, let channel = miniPlayerManager.currentChannel {
                VStack {
                    Spacer()
                    MiniPlayerView(
                        channel: channel,
                        program: miniPlayerManager.currentProgram,
                        isPlaying: miniPlayerManager.isPlaying,
                        onTap: {
                            showFullPlayer = true
                        },
                        onClose: {
                            miniPlayerManager.hide()
                        },
                        onPlayPause: {
                            miniPlayerManager.togglePlayPause()
                        },
                        onChannelUp: {
                            // TODO: Channel up logic
                        },
                        onChannelDown: {
                            // TODO: Channel down logic
                        }
                    )
                    .padding(.bottom, 49) // Above tab bar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.4), value: miniPlayerManager.isShowing)
            }
        }
        .environmentObject(miniPlayerManager)
        .fullScreenCover(isPresented: $showFullPlayer) {
            if let channel = miniPlayerManager.currentChannel,
               let url = miniPlayerManager.streamURL {
                FullScreenPlayerView(
                    channel: channel,
                    program: miniPlayerManager.currentProgram,
                    streamURL: url,
                    onMinimize: {
                        showFullPlayer = false
                    },
                    onClose: {
                        showFullPlayer = false
                        miniPlayerManager.hide()
                    }
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showSettings = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showProfilePicker) {
            ProfilePickerSheet()
        }
    }
}

// MARK: - Home Tab View (Wraps DiscoverViewModern with Movies/TV rows)

struct HomeTabView: View {
    var body: some View {
        DiscoverViewModern()
    }
}

// MARK: - Library View (Combines DVR, On Later, Watchlist)

struct LibraryView: View {
    @State private var selectedSection: LibrarySection = .recordings
    
    enum LibrarySection: String, CaseIterable {
        case recordings = "Recordings"
        case scheduled = "Scheduled"
        case onLater = "On Later"
        case watchlist = "Watchlist"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Section picker (horizontal scroll chips)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LibrarySection.allCases, id: \.self) { section in
                        LibrarySectionChip(
                            title: section.rawValue,
                            isSelected: selectedSection == section,
                            icon: iconFor(section)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedSection = section
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            
            Divider()
            
            // Content
            switch selectedSection {
            case .recordings:
                DVRRecordingsView()
            case .scheduled:
                DVRScheduledView()
            case .onLater:
                OnLaterView()
            case .watchlist:
                WatchlistViewEmbedded()
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func iconFor(_ section: LibrarySection) -> String {
        switch section {
        case .recordings: return "play.rectangle.fill"
        case .scheduled: return "clock.fill"
        case .onLater: return "calendar"
        case .watchlist: return "bookmark.fill"
        }
    }
}

// MARK: - Library Section Chip

struct LibrarySectionChip: View {
    let title: String
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.red : Color(.systemGray5))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DVR Recordings View (embedded, TV-style)

struct DVRRecordingsView: View {
    @StateObject private var viewModel = DVRViewModel()
    @State private var selectedRecording: Recording?
    @State private var showPlayer = false
    @State private var showDetailSheet = false
    @State private var streamURL: URL?
    @State private var recordingToDelete: Recording?
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.recordings.isEmpty {
                LoadingView(message: "Loading recordings...")
            } else if viewModel.hasRecordings {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Currently Recording
                        if !viewModel.currentlyRecording.isEmpty {
                            LibrarySectionHeader(title: "Currently Recording", icon: "record.circle", iconColor: .red)
                            ForEach(viewModel.currentlyRecording) { recording in
                                recordingRowButton(recording)
                            }
                        }

                        // Continue Watching
                        if !viewModel.inProgressRecordings.isEmpty {
                            LibrarySectionHeader(title: "Continue Watching", icon: "play.circle", iconColor: .blue)
                            ForEach(viewModel.inProgressRecordings) { recording in
                                recordingRowButton(recording)
                            }
                        }

                        // Grouped by Date
                        ForEach(viewModel.recordingsByDate, id: \.date) { group in
                            LibrarySectionHeader(title: relativeDate(group.date))
                            ForEach(group.recordings) { recording in
                                recordingRowButton(recording)
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.loadRecordings()
                }
            } else {
                EmptyStateView(
                    icon: "play.rectangle",
                    title: "No Recordings",
                    message: "Your completed recordings will appear here."
                )
            }
        }
        .task {
            await viewModel.loadRecordings()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let url = streamURL, let recording = selectedRecording {
                VideoPlayerView(
                    mediaItem: nil,
                    recordingURL: url,
                    startPosition: recording.viewOffset
                )
            }
        }
        .sheet(isPresented: $showDetailSheet) {
            if let recording = selectedRecording {
                RecordingDetailSheet(
                    recording: recording,
                    onWatch: { playRecording(recording) },
                    onDelete: {
                        showDetailSheet = false
                        Task { await viewModel.deleteRecording(recording) }
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .alert("Delete Recording", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let recording = recordingToDelete {
                    Task { await viewModel.deleteRecording(recording) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let recording = recordingToDelete {
                Text("Are you sure you want to delete \"\(recording.title)\"? This cannot be undone.")
            }
        }
    }

    private func recordingRowButton(_ recording: Recording) -> some View {
        Button {
            selectedRecording = recording
            showDetailSheet = true
        } label: {
            XfinityRecordingRow(recording: recording)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                playRecording(recording)
            } label: {
                Label("Watch", systemImage: "play.fill")
            }
            Button(role: .destructive) {
                recordingToDelete = recording
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func playRecording(_ recording: Recording) {
        showDetailSheet = false
        Task {
            do {
                let url = try await viewModel.getRecordingStream(recording)
                selectedRecording = recording
                streamURL = url
                showPlayer = true
            } catch {
                viewModel.error = error.localizedDescription
            }
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day, daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - DVR Scheduled View (embedded)

struct DVRScheduledView: View {
    @StateObject private var viewModel = DVRViewModel()
    
    var body: some View {
        Group {
            if viewModel.hasScheduled {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Currently Recording
                        if !viewModel.currentlyRecording.isEmpty {
                            LibrarySectionHeader(title: "Recording Now", icon: "record.circle", iconColor: .red)
                            ForEach(viewModel.currentlyRecording) { recording in
                                CompactScheduledRow(recording: recording) {
                                    Task { await viewModel.deleteRecording(recording) }
                                }
                            }
                        }
                        
                        // Upcoming
                        if !viewModel.upcomingRecordings.isEmpty {
                            LibrarySectionHeader(title: "Upcoming", icon: "clock")
                            ForEach(viewModel.upcomingRecordings) { recording in
                                CompactScheduledRow(recording: recording) {
                                    Task { await viewModel.deleteRecording(recording) }
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    icon: "clock",
                    title: "No Scheduled Recordings",
                    message: "Schedule recordings from the TV Guide."
                )
            }
        }
        .task {
            await viewModel.loadRecordings()
        }
    }
}

// MARK: - Watchlist View (embedded)

struct WatchlistViewEmbedded: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                LoadingView(message: "Loading watchlist...")
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    icon: "bookmark",
                    title: "Watchlist Empty",
                    message: "Add movies and shows to watch later."
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.items) { watchlistItem in
                            if let media = watchlistItem.media {
                                CompactMediaCard(item: media) {
                                    selectedItem = media
                                    showDetail = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await viewModel.loadWatchlist()
        }
        .navigationDestination(isPresented: $showDetail) {
            if let item = selectedItem {
                MediaDetailView(mediaId: item.id)
            }
        }
    }
}

// MARK: - Compact Scheduled Row

struct CompactScheduledRow: View {
    let recording: Recording
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: recording.status == .recording ? "record.circle" : "clock")
                .font(.title3)
                .foregroundColor(recording.status == .recording ? .red : .secondary)
                .frame(width: 32)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(recording.fullTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                
                HStack {
                    if let channelName = recording.channelName {
                        Text(channelName)
                    }
                    Text("•")
                    Text(recording.timeRangeFormatted)
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Compact Media Card

struct CompactMediaCard: View {
    let item: MediaItem
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                AuthenticatedImage(
                    path: item.thumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .aspectRatio(2/3, contentMode: .fill)
                .cornerRadius(8)
                
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Library Section Header

struct LibrarySectionHeader: View {
    let title: String
    var icon: String? = nil
    var iconColor: Color = .secondary
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Profile Avatar Button

struct ProfileAvatarButton: View {
    let profile: Profile?
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 32, height: 32)
            
            if let profile = profile {
                if let avatarPath = profile.avatar {
                    AuthenticatedImage(path: avatarPath, systemPlaceholder: "person.crop.circle")
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Text(String(profile.name.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                }
            } else {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Profile Picker Sheet

struct ProfilePickerSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Who's Watching?")
                    .font(.title2.bold())
                    .padding(.top, 20)
                
                if authViewModel.profiles.isEmpty {
                    ProgressView()
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(authViewModel.profiles) { profile in
                            ProfilePickerCard(profile: profile) {
                                Task {
                                    await authViewModel.selectProfile(profile, pin: nil)
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                Button("Sign Out") {
                    Task {
                        await authViewModel.logout()
                        dismiss()
                    }
                }
                .foregroundColor(.red)
                .padding(.bottom, 20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Profile Picker Card

struct ProfilePickerCard: View {
    let profile: Profile
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    if let avatarPath = profile.avatar {
                        AuthenticatedImage(path: avatarPath, systemPlaceholder: "person.crop.circle")
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Text(String(profile.name.prefix(1)).uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.red)
                    }
                    
                    if profile.isProtected {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .offset(x: 28, y: 28)
                    }
                }
                
                Text(profile.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
