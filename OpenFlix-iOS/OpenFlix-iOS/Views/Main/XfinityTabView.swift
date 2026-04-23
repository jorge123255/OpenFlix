import SwiftUI

#if os(iOS)

extension Notification.Name {
    static let switchTab = Notification.Name("switchTab")
}

// MARK: - Xfinity-Style Tab View (hamburger drawer nav)
struct XfinityTabView: View {
    @State private var selectedTab: XfinityTab = .forYou
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var miniPlayerManager = MiniPlayerManager.shared
    @State private var showFullPlayer = false
    @State private var showSettings = false
    @State private var showProfilePicker = false
    @State private var showDrawer = false
    @State private var isLandscape = UIDevice.current.orientation.isLandscape
    
    enum XfinityTab: String, CaseIterable {
        case forYou = "Home"
        case guide = "Live TV"
        case teamPass = "Team Pass"
        case saved = "My library"
        case passes = "Passes"
        case browse = "Browse"
        case search = "Search"
        
        var icon: String {
            switch self {
            case .forYou: return "house.fill"
            case .guide: return "tv.fill"
            case .teamPass: return "sportscourt.fill"
            case .saved: return "arrow.down.circle.fill"
            case .passes: return "calendar.badge.clock"
            case .browse: return "square.grid.2x2.fill"
            case .search: return "magnifyingglass"
            }
        }
        
        var iconUnselected: String {
            switch self {
            case .forYou: return "house"
            case .guide: return "tv"
            case .teamPass: return "sportscourt"
            case .saved: return "arrow.down.circle"
            case .passes: return "calendar.badge.clock"
            case .browse: return "square.grid.2x2"
            case .search: return "magnifyingglass"
            }
        }
    }
    
    private var hideInLandscape: Bool {
        isLandscape && selectedTab == .guide
    }

    // Xfinity dark purple background
    private let backgroundColor = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let tabBarBackground = Color(red: 26/255, green: 20/255, blue: 46/255)
    
    var body: some View {
        ZStack {
            // Background
            backgroundColor.ignoresSafeArea()

            // Main content
            NavigationStack {
                Group {
                    switch selectedTab {
                    case .forYou:
                        ForYouView()
                    case .guide:
                        XfinityLiveTVView()
                    case .teamPass:
                        SportsTeamsView()
                    case .saved:
                        XfinityLibraryWrapper()
                    case .passes:
                        PassManagementView()
                    case .browse:
                        XfinityBrowseWrapper()
                    case .search:
                        SearchView()
                    }
                }
                .toolbar(hideInLandscape ? .hidden : .visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showDrawer.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        Text("OpenFlix")
                            .font(.title2.bold())
                            .foregroundColor(accentColor)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 12) {
                            Button { showProfilePicker = true } label: {
                                XfinityProfileButton(profile: authViewModel.currentProfile)
                            }
                            Button { showSettings = true } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }

            // Mini Player floating at bottom
            if miniPlayerManager.isShowing, let channel = miniPlayerManager.currentChannel {
                VStack {
                    Spacer()
                    MiniPlayerView(
                        channel: channel,
                        program: miniPlayerManager.currentProgram,
                        isPlaying: miniPlayerManager.isPlaying,
                        onTap: { showFullPlayer = true },
                        onClose: { miniPlayerManager.hide() },
                        onPlayPause: { miniPlayerManager.togglePlayPause() },
                        onChannelUp: {},
                        onChannelDown: {}
                    )
                    .padding(.bottom, 8)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Dim overlay when drawer open
            if showDrawer {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                    }
                    .zIndex(1)

                HStack(spacing: 0) {
                    SideDrawerView(
                        selectedTab: $selectedTab,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                        },
                        onSettings: {
                            withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                            showSettings = true
                        }
                    )
                    .frame(width: 280)
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .zIndex(2)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let orientation = UIDevice.current.orientation
            if orientation.isLandscape || orientation.isPortrait {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isLandscape = orientation.isLandscape
                }
            }
        }
        .ignoresSafeArea(hideInLandscape ? .all : [])
        .onReceive(NotificationCenter.default.publisher(for: .switchTab)) { notification in
            if let tabName = notification.object as? String,
               let tab = XfinityTab(rawValue: ["forYou": "Home", "guide": "Live TV", "teamPass": "Team Pass", "saved": "My library", "browse": "Browse", "search": "Search"][tabName] ?? "") {
                selectedTab = tab
            }
        }
        .environmentObject(miniPlayerManager)
        .environmentObject(settingsViewModel)
        .fullScreenCover(isPresented: $showFullPlayer) {
            if let channel = miniPlayerManager.currentChannel,
               let url = miniPlayerManager.streamURL {
                FullScreenPlayerView(
                    channel: channel,
                    program: miniPlayerManager.currentProgram,
                    streamURL: url,
                    onMinimize: { showFullPlayer = false },
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
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showSettings = false }
                                .foregroundColor(Color(red: 97/255, green: 56/255, blue: 245/255))
                        }
                    }
            }
            .environmentObject(authViewModel)
            .environmentObject(settingsViewModel)
        }
        .sheet(isPresented: $showProfilePicker) {
            XfinityProfilePickerSheet()
        }
        // When profile is cleared from Settings, show profile picker
        .onChange(of: authViewModel.currentProfile?.id) { profileId in
            if profileId == nil {
                showProfilePicker = true
            }
        }
    }
}

// MARK: - Side Drawer
struct SideDrawerView: View {
    @Binding var selectedTab: XfinityTabView.XfinityTab
    let onSelect: () -> Void
    let onSettings: () -> Void

    private let bg = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let accent = Color(red: 97/255, green: 56/255, blue: 245/255)

    struct DrawerItem {
        let tab: XfinityTabView.XfinityTab
        let icon: String
        let label: String
    }

    private let items: [DrawerItem] = [
        DrawerItem(tab: .forYou,  icon: "house.fill",           label: "Home"),
        DrawerItem(tab: .guide,   icon: "play.fill",            label: "Live TV"),
        DrawerItem(tab: .teamPass, icon: "sportscourt.fill",    label: "Team Pass"),
        DrawerItem(tab: .passes,  icon: "calendar.badge.clock", label: "Passes"),
        DrawerItem(tab: .saved,   icon: "list.bullet",          label: "Library"),
        DrawerItem(tab: .browse,  icon: "text.justify",         label: "Browse"),
        DrawerItem(tab: .search,  icon: "magnifyingglass",      label: "Search"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo
            Text("OpenFlix")
                .font(.title2.bold())
                .foregroundColor(accent)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 32)

            // Nav items
            ForEach(items, id: \.label) { item in
                Button {
                    selectedTab = item.tab
                    onSelect()
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18))
                            .frame(width: 24)
                            .foregroundColor(selectedTab == item.tab ? accent : .white)
                        Text(item.label)
                            .font(.system(size: 17, weight: selectedTab == item.tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == item.tab ? accent : .white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        selectedTab == item.tab
                            ? accent.opacity(0.15)
                            : Color.clear
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Divider + Settings
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            Button {
                onSettings()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .frame(width: 24)
                        .foregroundColor(.white)
                    Text("Settings")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 40)
        }
        .frame(maxHeight: .infinity)
        .background(bg.ignoresSafeArea())
    }
}

// MARK: - Custom Tab Bar
struct XfinityCustomTabBar: View {
    @Binding var selectedTab: XfinityTabView.XfinityTab
    let accentColor: Color
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(XfinityTabView.XfinityTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab ? tab.icon : tab.iconUnselected)
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == tab ? accentColor : .gray)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == tab ? accentColor : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 20) // Safe area
        // Liquid Glass tab bar on iOS 26 (translucent over content);
        // falls back to the legacy opaque purple chrome on iOS 17–18.
        .openFlixGlassRegular(
            in: Rectangle(),
            tint: backgroundColor.opacity(0.55)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: -4)
    }
}

// MARK: - Profile Button
struct XfinityProfileButton: View {
    let profile: Profile?
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.3))
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
                        .foregroundColor(.purple)
                }
            } else {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.purple)
            }
        }
    }
}

// MARK: - Profile Picker Sheet
struct XfinityProfilePickerSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 17/255, green: 12/255, blue: 33/255).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Who's Watching?")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    if authViewModel.profiles.isEmpty {
                        ProgressView()
                            .tint(.white)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(authViewModel.profiles) { profile in
                                XfinityProfileCard(profile: profile) {
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
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.purple)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Profile Card
struct XfinityProfileCard: View {
    let profile: Profile
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 80, height: 80)
                    
                    if let avatarPath = profile.avatar {
                        AuthenticatedImage(path: avatarPath, systemPlaceholder: "person.crop.circle")
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Text(String(profile.name.prefix(1)).uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.purple)
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
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Library Wrapper (Saved Tab)
struct XfinityLibraryWrapper: View {
    @State private var selectedSection: LibrarySection = .recordings
    
    enum LibrarySection: String, CaseIterable {
        case recordings = "Recordings"
        case scheduled = "Scheduled"
        case downloads = "Downloads"
        case watchlist = "Watchlist"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Section picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LibrarySection.allCases, id: \.self) { section in
                        XfinityChip(
                            title: section.rawValue,
                            isSelected: selectedSection == section
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
            
            Divider().background(Color.white.opacity(0.1))
            
            // Content
            Group {
                switch selectedSection {
                case .recordings:
                    DVRRecordingsContent()
                case .scheduled:
                    DVRScheduledContent()
                case .downloads:
                    DownloadsPlaceholder()
                case .watchlist:
                    WatchlistContent()
                }
            }
        }
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Browse Wrapper (Xfinity-Style Category Grid)
struct XfinityBrowseWrapper: View {
    @State private var searchText = ""
    @State private var selectedCategory: XfinityBrowseCategory? = nil
    
    enum XfinityBrowseCategory: String, CaseIterable, Identifiable {
        case disneyPlus = "Disney+"
        case max = "Max"
        case movies = "Movies"
        case tvShows = "TV"
        case news = "News"
        case kids = "Kids & family"
        case networks = "Networks"

        var id: String { rawValue }

        // Purple gradient colors for each category (Xfinity style)
        var gradientColors: [Color] {
            switch self {
            case .disneyPlus:
                return [Color(hex: "1B3A8C"), Color(hex: "0E1F4F")]
            case .max:
                return [Color(hex: "3A0E5C"), Color(hex: "1B0832")]
            case .movies:
                return [Color(hex: "7B4FE8"), Color(hex: "5B3DC4")]
            case .tvShows:
                return [Color(hex: "6B3FD8"), Color(hex: "4B2DB4")]
            case .news:
                return [Color(hex: "7B4FE8"), Color(hex: "5B3DC4")]
            case .kids:
                return [Color(hex: "6B3FD8"), Color(hex: "4B2DB4")]
            case .networks:
                return [Color(hex: "8B5FF8"), Color(hex: "6B4DD4")]
            }
        }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "110c21").ignoresSafeArea()
            
            // Main browse view with category grid
            mainBrowseView
        }
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedCategory) { category in
            // Category detail view - presented as full screen cover
            CategoryDetailFullScreen(category: category) {
                selectedCategory = nil
            }
        }
    }
    
    // MARK: - Main Browse View
    
    private var mainBrowseView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Search bar
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // Browse by category
                VStack(alignment: .leading, spacing: 16) {
                    Text("Browse by category")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                    
                    // Category grid (2 columns)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(XfinityBrowseCategory.allCases) { category in
                            XfinityBrowseCategoryCard(category: category) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 100) // Space for tab bar
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            
            TextField("Search movies, TV shows, or keywords", text: $searchText)
                .foregroundColor(.black)
                .font(.system(size: 16))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(8)
    }
    
}

// MARK: - Category Detail Full Screen
struct CategoryDetailFullScreen: View {
    let category: XfinityBrowseWrapper.XfinityBrowseCategory
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category content fills the screen
                switch category {
                case .disneyPlus:
                    DisneyHomeView()
                case .max:
                    MaxHomeView()
                case .movies:
                    BrowseMoviesView()
                case .tvShows:
                    BrowseTVShowsView()
                case .news:
                    BrowseNewsView()
                case .kids:
                    BrowseKidsView()
                case .networks:
                    BrowseNetworksView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "110c21"))
            .navigationTitle(category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Browse")
                        }
                        .foregroundColor(Color(hex: "6138f5"))
                    }
                }
            }
            .toolbarBackground(Color(hex: "110c21"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Browse Category Card (Purple Gradient)
struct XfinityBrowseCategoryCard: View {
    let category: XfinityBrowseWrapper.XfinityBrowseCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // Gradient background
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: category.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Category name
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.leading, 16)
                    .padding(.bottom, 16)
            }
            .frame(height: 100)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Browse Networks View
struct BrowseNetworksView: View {
    @StateObject private var liveTVRepo = LiveTVRepository()
    @State private var networks: [String: [Channel]] = [:]
    @State private var selectedChannel: Channel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if networks.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ForEach(Array(networks.keys.sorted()), id: \.self) { network in
                        if let channels = networks[network] {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(network)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(channels) { channel in
                                            BrowseNetworkCard(channel: channel) {
                                                selectedChannel = channel
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .task {
            await loadNetworks()
        }
        .fullScreenCover(item: $selectedChannel) { channel in
            if let url = OpenFlixAPI.shared.channelStreamURL(id: channel.id) {
                VideoPlayerView(
                    mediaItem: nil,
                    recordingURL: url,
                    startPosition: nil
                )
            }
        }
    }
    
    private func loadNetworks() async {
        do {
            try await liveTVRepo.loadChannels()
        } catch {
            print("Failed to load channels: \(error)")
        }
        
        // Group by network
        var grouped: [String: [Channel]] = [:]
        for channel in liveTVRepo.channels {
            let network = deriveNetwork(from: channel.name)
            if grouped[network] == nil {
                grouped[network] = []
            }
            grouped[network]?.append(channel)
        }
        networks = grouped
    }
    
    private func deriveNetwork(from name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("espn") { return "ESPN" }
        if lower.contains("fox") { return "FOX" }
        if lower.contains("nbc") { return "NBC" }
        if lower.contains("cbs") { return "CBS" }
        if lower.contains("abc") { return "ABC" }
        if lower.contains("hbo") { return "HBO" }
        if lower.contains("showtime") { return "Showtime" }
        if lower.contains("discovery") { return "Discovery" }
        if lower.contains("hgtv") { return "HGTV" }
        if lower.contains("tnt") || lower.contains("tbs") { return "Turner" }
        if lower.contains("usa") { return "USA Network" }
        return "Other"
    }
}

// MARK: - Browse Network Card
struct BrowseNetworkCard: View {
    let channel: Channel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let logoUrl = channel.logo, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 80, height: 50)
                    .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 50)
                        .overlay(
                            Image(systemName: "tv.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                Text(channel.name)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(width: 90)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Browse Overview (fallback)
struct BrowseOverviewView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Featured Movies
            BrowseCategoryRow(title: "Popular Movies", type: .movies)
            
            // Featured Shows
            BrowseCategoryRow(title: "Trending TV Shows", type: .tvShows)
            
            // Sports
            BrowseCategoryRow(title: "Sports", type: .sports)
            
            // News
            BrowseCategoryRow(title: "News", type: .news)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Browse Movies View
struct BrowseMoviesView: View {
    @StateObject private var viewModel = MoviesViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var showAllGrid = false
    @State private var showGenreGrid: (genre: String, items: [MediaItem])? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.isLoading && viewModel.allMovies.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if viewModel.allMovies.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "film")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No movies available")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    // Recently Added row
                    if !viewModel.recentlyAdded.isEmpty {
                        BrowseMediaRow(
                            title: "Recently Added",
                            items: viewModel.recentlyAdded
                        ) { item in
                            selectedItem = item
                            showDetail = true
                        }
                    }

                    // Genre rows
                    ForEach(viewModel.genreHubs, id: \.genre) { hub in
                        BrowseMediaRow(
                            title: hub.genre,
                            items: hub.items,
                            onViewAll: {
                                showGenreGrid = (genre: hub.genre, items: hub.items)
                            }
                        ) { item in
                            selectedItem = item
                            showDetail = true
                        }
                    }

                    // View All button
                    Button {
                        showAllGrid = true
                    } label: {
                        HStack {
                            Text("View All Movies")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Text("\(viewModel.allMovies.count)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.loadMoviesHub()
        }
        .navigationDestination(isPresented: $showDetail) {
            if let item = selectedItem {
                MediaDetailView(mediaId: item.id)
            }
        }
        .navigationDestination(isPresented: $showAllGrid) {
            BrowseAllGridView(title: "All Movies", items: viewModel.allMovies)
        }
        .navigationDestination(isPresented: Binding(
            get: { showGenreGrid != nil },
            set: { if !$0 { showGenreGrid = nil } }
        )) {
            if let genreData = showGenreGrid {
                BrowseAllGridView(title: genreData.genre, items: genreData.items)
            }
        }
    }
}

// MARK: - Browse TV Shows View
struct BrowseTVShowsView: View {
    @StateObject private var viewModel = TVShowsViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var showAllGrid = false
    @State private var showGenreGrid: (genre: String, items: [MediaItem])? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.isLoading && viewModel.allShows.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if viewModel.allShows.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tv")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No TV shows available")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    // Recently Added row
                    if !viewModel.recentlyAdded.isEmpty {
                        BrowseMediaRow(
                            title: "Recently Added",
                            items: viewModel.recentlyAdded
                        ) { item in
                            selectedItem = item
                            showDetail = true
                        }
                    }

                    // Genre rows
                    ForEach(viewModel.genreHubs, id: \.genre) { hub in
                        BrowseMediaRow(
                            title: hub.genre,
                            items: hub.items,
                            onViewAll: {
                                showGenreGrid = (genre: hub.genre, items: hub.items)
                            }
                        ) { item in
                            selectedItem = item
                            showDetail = true
                        }
                    }

                    // View All button
                    Button {
                        showAllGrid = true
                    } label: {
                        HStack {
                            Text("View All TV Shows")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Text("\(viewModel.allShows.count)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.loadTVShowsHub()
        }
        .navigationDestination(isPresented: $showDetail) {
            if let item = selectedItem {
                MediaDetailView(mediaId: item.id)
            }
        }
        .navigationDestination(isPresented: $showAllGrid) {
            BrowseAllGridView(title: "All TV Shows", items: viewModel.allShows)
        }
        .navigationDestination(isPresented: Binding(
            get: { showGenreGrid != nil },
            set: { if !$0 { showGenreGrid = nil } }
        )) {
            if let genreData = showGenreGrid {
                BrowseAllGridView(title: genreData.genre, items: genreData.items)
            }
        }
    }
}

// MARK: - Browse Media Row (horizontal genre row)

struct BrowseMediaRow: View {
    let title: String
    let items: [MediaItem]
    var onViewAll: (() -> Void)? = nil
    let onSelect: (MediaItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                if let onViewAll = onViewAll {
                    Button(action: onViewAll) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 97/255, green: 56/255, blue: 245/255))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            // Horizontal scroll of poster cards
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items.prefix(20)) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                AuthenticatedImage(
                                    path: item.thumb,
                                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                                )
                                .aspectRatio(2/3, contentMode: .fill)
                                .frame(width: 120, height: 180)
                                .cornerRadius(8)

                                Text(item.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .frame(width: 120, alignment: .leading)

                                if let year = item.year {
                                    Text(String(year))
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Browse All Grid View (full grid for View All)

struct BrowseAllGridView: View {
    let title: String
    let items: [MediaItem]
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var sortOption: BrowseSortOption = .alphabetical
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 130), spacing: 12)]

    private var sortedItems: [MediaItem] {
        switch sortOption {
        case .recentlyAdded:
            return items.sorted { ($0.addedAt ?? .distantPast) > ($1.addedAt ?? .distantPast) }
        case .alphabetical:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .rating:
            return items.sorted { ($0.audienceRating ?? 0) > ($1.audienceRating ?? 0) }
        case .year:
            return items.sorted { ($0.year ?? 0) > ($1.year ?? 0) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Sort bar
                BrowseSortBar(sortOption: $sortOption, itemCount: items.count)
                    .padding(.horizontal, 16)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(sortedItems) { item in
                        XfinityMediaCard(item: item) {
                            selectedItem = item
                            showDetail = true
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 12)
            .padding(.bottom, 80)
        }
        .background(Color(red: 17/255, green: 12/255, blue: 33/255))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showDetail) {
            if let item = selectedItem {
                MediaDetailView(mediaId: item.id)
            }
        }
    }
}

// MARK: - Browse Sort & Filter Components

enum BrowseSortOption: String, CaseIterable {
    case recentlyAdded = "Recently Added"
    case alphabetical = "A-Z"
    case rating = "Top Rated"
    case year = "Year"

    var icon: String {
        switch self {
        case .recentlyAdded: return "clock.fill"
        case .alphabetical: return "textformat.abc"
        case .rating: return "star.fill"
        case .year: return "calendar"
        }
    }
}

struct BrowseSortBar: View {
    @Binding var sortOption: BrowseSortOption
    let itemCount: Int

    var body: some View {
        HStack {
            Text("\(itemCount) titles")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))

            Spacer()

            Menu {
                ForEach(BrowseSortOption.allCases, id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            sortOption = option
                        }
                    } label: {
                        Label(option.rawValue, systemImage: option.icon)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: sortOption.icon)
                        .font(.system(size: 12))
                    Text(sortOption.rawValue)
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.12))
                .cornerRadius(20)
            }
        }
    }
}

// MARK: - Browse News View
struct BrowseNewsView: View {
    @StateObject private var liveTVRepo = LiveTVRepository()
    @State private var newsChannels: [Channel] = []
    @State private var selectedChannel: Channel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("News Channels")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            if newsChannels.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Loading news channels...")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(newsChannels) { channel in
                        NewsChannelRow(channel: channel) {
                            selectedChannel = channel
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .task {
            await loadNewsChannels()
        }
        .fullScreenCover(item: $selectedChannel) { channel in
            if let url = OpenFlixAPI.shared.channelStreamURL(id: channel.id) {
                VideoPlayerView(
                    mediaItem: nil,
                    recordingURL: url,
                    startPosition: nil
                )
            }
        }
    }
    
    private func loadNewsChannels() async {
        do {
            try await liveTVRepo.loadChannels()
        } catch {
            print("Failed to load channels: \(error)")
        }
        // Filter for news channels
        newsChannels = liveTVRepo.channels.filter { channel in
            let name = channel.name.lowercased()
            return name.contains("news") || name.contains("cnn") || name.contains("fox") || 
                   name.contains("msnbc") || name.contains("cnbc") || name.contains("bbc") ||
                   name.contains("cbs") || name.contains("abc") || name.contains("nbc")
        }
    }
}

// MARK: - News Channel Row
struct NewsChannelRow: View {
    let channel: Channel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Channel logo
                if let logoUrl = channel.logo, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 40)
                    .cornerRadius(6)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 40)
                        .cornerRadius(6)
                        .overlay(
                            Image(systemName: "tv.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let program = channel.nowPlaying {
                        Text(program.title)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Browse Kids View
struct BrowseKidsView: View {
    @StateObject private var moviesVM = MoviesViewModel()
    @StateObject private var showsVM = TVShowsViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    
    var kidsContent: [MediaItem] {
        let allContent = moviesVM.allMovies + showsVM.allShows
        return allContent.filter { item in
            let genres = item.genres ?? []
            return genres.contains { genre in
                let lower = genre.lowercased()
                return lower.contains("animation") || 
                       lower.contains("family") ||
                       lower.contains("kids") ||
                       lower.contains("children")
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("👶 Kids & Family")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            if moviesVM.isLoading || showsVM.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: 200)
            } else if kidsContent.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No kids content available")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(kidsContent) { item in
                        XfinityMediaCard(item: item) {
                            selectedItem = item
                            showDetail = true
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .task {
            await moviesVM.loadMoviesHub()
            await showsVM.loadTVShowsHub()
        }
        .navigationDestination(isPresented: $showDetail) {
            if let item = selectedItem {
                MediaDetailView(mediaId: item.id)
            }
        }
    }
}

// MARK: - Browse Category Row
struct BrowseCategoryRow: View {
    let title: String
    let type: BrowseType
    
    enum BrowseType {
        case movies, tvShows, sports, news
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<6) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 140, height: 80)
                            .overlay(
                                Image(systemName: iconForType)
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    var iconForType: String {
        switch type {
        case .movies: return "film.fill"
        case .tvShows: return "tv.fill"
        case .sports: return "sportscourt.fill"
        case .news: return "newspaper.fill"
        }
    }
}

// MARK: - Sports Teams View (ESPN Powered)
struct SportsTeamsView: View {
    @State private var teamsByLeague: [String: [ESPNTeam]] = [:]
    @State private var teamIdToLeague: [String: ESPNService.League] = [:]  // Quick lookup
    @State private var liveGames: [String: [ESPNGame]] = [:]
    @State private var favoriteTeamNextGames: [String: ESPNGame] = [:]
    @State private var selectedTeam: ESPNTeam?
    @State private var selectedTeamLeague: ESPNService.League = .nba
    @State private var selectedLeague: ESPNService.League? = nil
    @State private var isLoading = true
    @State private var showTeamDetail = false
    @State private var showManageFavorites = false
        @State private var selectedChannel: Channel?
    @StateObject private var broadcastService = BroadcastChannelService.shared
    @AppStorage("favoriteTeamKeys") private var favoriteTeamKeysData: Data = Data()
    
    private var favoriteTeamKeys: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: favoriteTeamKeysData)) ?? []
    }
    
    private func teamKey(league: ESPNService.League, teamId: String) -> String {
        "\(league.rawValue):\(teamId)"
    }
    
    private func isFavorite(league: ESPNService.League, teamId: String) -> Bool {
        favoriteTeamKeys.contains(teamKey(league: league, teamId: teamId))
    }
    
    // Returns (team, league) pairs for favorites — iterates teamsByLeague directly to avoid ID collisions
    private var favoriteTeamsWithLeague: [(team: ESPNTeam, league: ESPNService.League)] {
        var seen = Set<String>()
        var result: [(team: ESPNTeam, league: ESPNService.League)] = []
        for league in leagues {
            guard let teams = teamsByLeague[league.displayName] else { continue }
            for team in teams {
                let key = teamKey(league: league, teamId: team.id)
                if favoriteTeamKeys.contains(key) && seen.insert(key).inserted {
                    result.append((team: team, league: league))
                }
            }
        }
        return result
    }
    
    let leagues: [ESPNService.League] = [.nfl, .nba, .mlb, .nhl, .mls]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ESPN dedicated hub — DVR-Tuner-owned browse, not the
                // generic guide. Shown at the top of Sports/Team Pass.
                NavigationLink {
                    ESPNHubView()
                } label: {
                    ESPNTileLabel(logoSize: CGSize(width: 78, height: 46))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)

                // League filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        XfinityChip(title: "All", isSelected: selectedLeague == nil) {
                            withAnimation { selectedLeague = nil }
                        }
                        ForEach(leagues, id: \.rawValue) { league in
                            XfinityChip(title: "\(league.emoji) \(league.displayName)", isSelected: selectedLeague == league) {
                                withAnimation { selectedLeague = league }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading teams from ESPN...")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 40)
                } else {
                    // Live Games Section
                    if !liveGames.isEmpty && selectedLeague == nil {
                        LiveGamesSection(games: liveGames)
                    }
                    
                    // Favorite Teams Section
                    let favs = favoriteTeamsWithLeague
                    if !favs.isEmpty && selectedLeague == nil {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("⭐ My Teams")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: { showManageFavorites = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: 12))
                                        Text("Manage")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(favs.enumerated()), id: \.offset) { _, item in
                                    FavoriteTeamDashboardCard(
                                        team: item.team,
                                        league: item.league,
                                        nextGame: favoriteTeamNextGames[teamKey(league: item.league, teamId: item.team.id)],
                                        liveGame: liveGame(for: item.team.id),
                                        broadcastService: broadcastService,
                                        onTap: {
                                            selectedTeam = item.team
                                            selectedTeamLeague = item.league
                                            showTeamDetail = true
                                        },
                                        onWatch: { channel in
                                            selectedChannel = channel
                                        },
                                        onRemove: { toggleFavorite(item.team, league: item.league) }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    // Teams by League
                    let leaguesToShow = selectedLeague != nil ? [selectedLeague!] : leagues
                    
                    ForEach(leaguesToShow, id: \.rawValue) { league in
                        if let teams = teamsByLeague[league.displayName], !teams.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("\(league.emoji) \(league.displayName)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("(\(teams.count) teams)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    // Live game indicator for this league
                                    if let liveCount = liveGames[league.displayName]?.filter({ $0.isLive }).count, liveCount > 0 {
                                        HStack(spacing: 4) {
                                            Circle().fill(Color.red).frame(width: 6, height: 6)
                                            Text("\(liveCount) LIVE")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(teams) { team in
                                            ESPNTeamCard(
                                                team: team,
                                                isFavorite: isFavorite(league: league, teamId: team.id),
                                                onTap: {
                                                    selectedTeam = team
                                                    selectedTeamLeague = league
                                                    showTeamDetail = true
                                                },
                                                onFavorite: { toggleFavorite(team, league: league) }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .task {
            await loadAllData()
        }
        .refreshable {
            await loadAllData()
        }
        .navigationDestination(isPresented: $showTeamDetail) {
            if let team = selectedTeam {
                ESPNTeamDetailView(team: team, league: selectedTeamLeague)
            }
        }
        .fullScreenCover(item: $selectedChannel) { channel in
            if let url = OpenFlixAPI.shared.channelStreamURL(id: channel.id) {
                VideoPlayerView(
                    mediaItem: nil,
                    recordingURL: url,
                    startPosition: nil
                )
            }
        }
        .sheet(isPresented: $showManageFavorites) {
            ManageFavoritesSheet(
                favoriteTeams: favoriteTeamsWithLeague,
                onRemove: { team, league in toggleFavorite(team, league: league) }
            )
        }
    }
    
    private func loadAllData() async {
        isLoading = true
        
        // Load teams and scores in parallel
        await withTaskGroup(of: Void.self) { group in
            // Load teams for each league
            for league in leagues {
                group.addTask {
                    if let teams = try? await ESPNService.shared.fetchTeams(league: league) {
                        await MainActor.run {
                            teamsByLeague[league.displayName] = teams.sorted { $0.displayName < $1.displayName }
                            // Build teamId -> league lookup
                            for team in teams {
                                teamIdToLeague[team.id] = league
                            }
                        }
                    }
                }
            }
            
            // Load live scores
            group.addTask {
                let scores = await ESPNService.shared.fetchAllLiveScores()
                await MainActor.run {
                    liveGames = scores
                }
            }
        }
        
        // Load favorite team schedules (keyed by "league:teamId")
        let favsList = await MainActor.run { self.favoriteTeamsWithLeague }
        if favsList.isEmpty {
            await MainActor.run { favoriteTeamNextGames = [:] }
        } else {
            let now = Date()
            var nextGames: [String: ESPNGame] = [:]
            await withTaskGroup(of: (String, ESPNGame?).self) { group in
                for item in favsList {
                    let key = teamKey(league: item.league, teamId: item.team.id)
                    group.addTask {
                        let schedule = try? await ESPNService.shared.fetchTeamSchedule(league: item.league, teamId: item.team.id)
                        let nextGame = schedule?
                            .filter { game in
                                guard let date = game.gameDate else { return false }
                                return date >= now && !game.isCompleted
                            }
                            .sorted { ($0.gameDate ?? .distantFuture) < ($1.gameDate ?? .distantFuture) }
                            .first
                        return (key, nextGame)
                    }
                }
                
                for await (key, game) in group {
                    if let game {
                        nextGames[key] = game
                    }
                }
            }
            await MainActor.run { favoriteTeamNextGames = nextGames }
        }
        
        if !broadcastService.isLoaded {
            await broadcastService.loadChannels()
        }
        
        isLoading = false
    }
    
    private func toggleFavorite(_ team: ESPNTeam, league: ESPNService.League) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let key = teamKey(league: league, teamId: team.id)
        var keys = favoriteTeamKeys
        let isRemoving = keys.contains(key)
        if keys.contains(key) {
            keys.remove(key)
        } else {
            keys.insert(key)
        }
        if let encoded = try? JSONEncoder().encode(keys) {
            favoriteTeamKeysData = encoded
        }
        
        Task {
            let api = OpenFlixAPI.shared
            if isRemoving {
                if let passesResponse = try? await api.getTeamPasses(),
                   let matchingPass = passesResponse.teamPasses.first(where: {
                       $0.teamName.localizedCaseInsensitiveCompare(team.displayName) == .orderedSame
                   }) {
                    try? await api.deleteTeamPass(id: String(matchingPass.id))
                }
            } else {
                _ = try? await api.createTeamPass(teamName: team.displayName, league: league.rawValue)
            }
            await MainActor.run {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    private func leagueForTeam(_ team: ESPNTeam) -> ESPNService.League {
        for league in leagues {
            if teamsByLeague[league.displayName]?.contains(where: { $0.id == team.id }) == true {
                return league
            }
        }
        return .nfl
    }
    
    private func liveGame(for teamId: String) -> ESPNGame? {
        for games in liveGames.values {
            if let match = games.first(where: { game in
                guard game.isLive else { return false }
                return game.homeTeam?.team.id == teamId || game.awayTeam?.team.id == teamId
            }) {
                return match
            }
        }
        return nil
    }
}

// MARK: - Favorite Team Dashboard Card
struct FavoriteTeamDashboardCard: View {
    let team: ESPNTeam
    let league: ESPNService.League
    let nextGame: ESPNGame?
    let liveGame: ESPNGame?
    let broadcastService: BroadcastChannelService
    let onTap: () -> Void
    let onWatch: (Channel) -> Void
    var onRemove: (() -> Void)? = nil
    
    @State private var pulse = false
    
    private var teamColor: Color {
        Color(hex: team.primaryColor)
    }
    
    private var displayGame: ESPNGame? {
        liveGame ?? nextGame
    }
    
    private var opponent: ESPNCompetitor? {
        guard let game = displayGame else { return nil }
        let isHome = game.homeTeam?.team.id == team.id
        return isHome ? game.awayTeam : game.homeTeam
    }
    
    private var watchChannel: Channel? {
        guard let game = displayGame, let broadcast = game.broadcast else { return nil }
        return broadcastService.findChannel(forBroadcast: broadcast)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [teamColor, teamColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 54, height: 54)
                    
                    if let logoUrl = team.logoURL, let url = URL(string: logoUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Text(team.abbreviation)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 30, height: 30)
                    } else {
                        Text(team.abbreviation)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(league.emoji)
                    .font(.system(size: 18))
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            
            if let live = liveGame {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                            .scaleEffect(pulse ? 1.2 : 0.7)
                            .opacity(pulse ? 1 : 0.5)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    pulse.toggle()
                                }
                            }
                        Text("LIVE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                        if let status = live.statusDetail {
                            Text(status)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Text(live.awayTeam?.team.abbreviation ?? "AWY")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text(live.awayTeam?.scoreDisplay ?? "-")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        HStack(spacing: 6) {
                            Text(live.homeTeam?.team.abbreviation ?? "HOM")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text(live.homeTeam?.scoreDisplay ?? "-")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        
                        if let channel = watchChannel {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onWatch(channel)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("Watch")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else if let game = nextGame {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Next Game")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(game.homeTeam?.team.id == team.id ? "vs" : "@") \(opponent?.team.displayName ?? "TBD")")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        if let date = game.gameDate {
                            Text(date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        if let broadcast = game.broadcast {
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            Text(broadcast)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(watchChannel != nil ? Color(hex: "6138f5") : .white.opacity(0.7))
                        }
                    }
                }
            } else {
                Text("No upcoming games")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [teamColor.opacity(0.25), Color.black.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(teamColor.opacity(0.4), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Manage Favorites Sheet
struct ManageFavoritesSheet: View {
    let favoriteTeams: [(team: ESPNTeam, league: ESPNService.League)]
    let onRemove: (ESPNTeam, ESPNService.League) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if favoriteTeams.isEmpty {
                    Text("No favorite teams yet.\nStar teams from the list below to add them here.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(favoriteTeams, id: \.team.id) { item in
                        HStack(spacing: 12) {
                            if let logoUrl = item.team.logoURL, let url = URL(string: logoUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 36, height: 36)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.team.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("\(item.league.emoji) \(item.league.displayName)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button {
                                withAnimation { onRemove(item.team, item.league) }
                            } label: {
                                Image(systemName: "star.slash.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Manage My Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Live Games Section
struct LiveGamesSection: View {
    let games: [String: [ESPNGame]]
    
    var liveGamesFlat: [(league: String, game: ESPNGame)] {
        games.flatMap { league, games in
            games.filter { $0.isLive }.map { (league, $0) }
        }
    }
    
    var body: some View {
        if !liveGamesFlat.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("LIVE NOW")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(liveGamesFlat, id: \.game.id) { item in
                            LiveGameCard(game: item.game, league: item.league)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Live Game Card
struct LiveGameCard: View {
    let game: ESPNGame
    let league: String
    
    var body: some View {
        VStack(spacing: 8) {
            // Teams and scores
            HStack(spacing: 16) {
                // Away team
                VStack(spacing: 4) {
                    if let logo = game.awayTeam?.team.logo, let url = URL(string: logo) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 32, height: 32)
                    }
                    Text(game.awayTeam?.team.abbreviation ?? "")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                    Text(game.awayTeam?.scoreDisplay ?? "0")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("@")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                // Home team
                VStack(spacing: 4) {
                    if let logo = game.homeTeam?.team.logo, let url = URL(string: logo) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 32, height: 32)
                    }
                    Text(game.homeTeam?.team.abbreviation ?? "")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                    Text(game.homeTeam?.scoreDisplay ?? "0")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Game status
            HStack(spacing: 4) {
                Circle().fill(Color.red).frame(width: 6, height: 6)
                Text(game.statusDetail ?? "LIVE")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.red)
            }
            
            // Broadcast
            if let broadcast = game.broadcast {
                Text(broadcast)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .frame(width: 140)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - ESPN Team Card
struct ESPNTeamCard: View {
    let team: ESPNTeam
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    
    var teamColor: Color {
        Color(hex: team.primaryColor)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    // Team logo
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [teamColor, teamColor.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                        
                        if let logoUrl = team.logoURL, let url = URL(string: logoUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Text(team.abbreviation)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 36, height: 36)
                        } else {
                            Text(team.abbreviation)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Favorite button
                    Button(action: onFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(isFavorite ? .yellow : .gray)
                            .padding(4)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .offset(x: 4, y: -4)
                }
                
                Text(team.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 75)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ESPN Team Detail View
struct ESPNTeamDetailView: View {
    let team: ESPNTeam
    let league: ESPNService.League
    
    @StateObject private var broadcastService = BroadcastChannelService.shared
    @State private var schedule: [ESPNGame] = []
    @State private var teamDetails: ESPNTeamDetails?
    @State private var isLoading = true
    @State private var selectedChannel: Channel?
    @AppStorage("favoriteTeamKeys") private var favoriteTeamKeysData: Data = Data()
    
    private var teamKey: String {
        "\(league.rawValue):\(team.id)"
    }
    
    private var isFavorite: Bool {
        let keys = (try? JSONDecoder().decode(Set<String>.self, from: favoriteTeamKeysData)) ?? []
        return keys.contains(teamKey)
    }
    
    var teamColor: Color {
        Color(hex: team.primaryColor)
    }
    
    // Find currently live game
    private var liveGame: ESPNGame? {
        schedule.first { $0.isLive }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [teamColor, teamColor.opacity(0.3), Color(hex: "110c21")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    
                    VStack(spacing: 12) {
                        if let logoUrl = team.logoURL, let url = URL(string: logoUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Circle().fill(Color.white.opacity(0.2))
                            }
                            .frame(width: 80, height: 80)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Text(team.displayName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text(league.displayName)
                            if let record = teamDetails?.recordSummary {
                                Text("•")
                                Text(record)
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 20)
                }
                
                // Live game banner (if live now)
                if let live = liveGame, let channel = broadcastService.findChannel(forBroadcast: live.broadcast) {
                    liveGameBanner(game: live, channel: channel)
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: toggleFavorite) {
                        HStack {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                            Text(isFavorite ? "Following" : "Follow")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isFavorite ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isFavorite ? Color.yellow : Color.white.opacity(0.15))
                        .cornerRadius(8)
                    }
                    
                    // Next game button (if we have the channel)
                    if let nextGame = schedule.first(where: { $0.isScheduled }),
                       let channel = broadcastService.findChannel(forBroadcast: nextGame.broadcast) {
                        Button {
                            selectedChannel = channel
                        } label: {
                            HStack {
                                Image(systemName: "tv")
                                Text(channel.name)
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "6138f5"))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                // Team Info Section
                if let details = teamDetails {
                    teamInfoSection(details: details)
                }
                
                // Schedule
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Schedule")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        if !schedule.isEmpty {
                            Text("\(schedule.count) games")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else if schedule.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                            Text("No upcoming games")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        // Recent results section
                        let recentGames = schedule.filter { $0.isCompleted }
                        let upcomingGames = schedule.filter { !$0.isCompleted }
                        
                        if !recentGames.isEmpty {
                            Text("Recent Results")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            
                            ForEach(recentGames) { game in
                                ScheduleGameRow(
                                    game: game,
                                    teamId: team.id,
                                    broadcastService: broadcastService,
                                    onWatchTapped: { _ in }
                                )
                            }
                        }
                        
                        if !upcomingGames.isEmpty {
                            Text("Upcoming")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, recentGames.isEmpty ? 8 : 16)
                            
                            ForEach(upcomingGames) { game in
                                ScheduleGameRow(
                                    game: game,
                                    teamId: team.id,
                                    broadcastService: broadcastService,
                                    onWatchTapped: { channel in
                                        selectedChannel = channel
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .background(Color(hex: "110c21"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .white)
                }
            }
        }
        .task {
            await loadSchedule()
            if !broadcastService.isLoaded {
                await broadcastService.loadChannels()
            }
        }
        .fullScreenCover(item: $selectedChannel) { channel in
            if let url = OpenFlixAPI.shared.channelStreamURL(id: channel.id) {
                VideoPlayerView(
                    mediaItem: nil,
                    recordingURL: url,
                    startPosition: nil
                )
            }
        }
    }

    @ViewBuilder
    private func teamInfoSection(details: ESPNTeamDetails) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Team Info")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 10) {
                if let venue = details.venueName {
                    TeamInfoRow(label: "Venue", value: venue)
                }
                if let location = details.venueCity {
                    TeamInfoRow(label: "Location", value: location)
                }
                if let standing = details.standingSummary {
                    TeamInfoRow(label: "Standing", value: standing)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private func liveGameBanner(game: ESPNGame, channel: Channel) -> some View {
        Button {
            selectedChannel = channel
        } label: {
            HStack(spacing: 12) {
                // Live indicator
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }
                
                // Game info
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.shortName ?? game.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("on \(channel.name)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Watch button
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                    Text("Watch")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(6)
            }
            .padding(12)
            .background(Color.red.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private func loadSchedule() async {
        isLoading = true
        
        // Fetch team details and schedule in parallel
        async let detailsTask = ESPNService.shared.fetchTeamDetails(league: league, teamId: team.id)
        async let scheduleTask = ESPNService.shared.fetchTeamSchedule(league: league, teamId: team.id)
        
        // Get team details
        teamDetails = try? await detailsTask
        
        // Get schedule
        if let games = try? await scheduleTask {
            let now = Date()
            let thirtyDaysAgo = now.addingTimeInterval(-30 * 24 * 3600)
            
            // Split into past and future games
            let recentPast = games
                .filter { game in
                    guard let gameDate = game.gameDate else { return false }
                    return gameDate < now && gameDate > thirtyDaysAgo
                }
                .sorted { ($0.gameDate ?? .distantPast) > ($1.gameDate ?? .distantPast) } // Most recent first
                .prefix(5) // Last 5 games
            
            let upcoming = games
                .filter { game in
                    guard let gameDate = game.gameDate else { return false }
                    return gameDate >= now || game.isLive
                }
                .sorted { ($0.gameDate ?? .distantPast) < ($1.gameDate ?? .distantPast) }
                .prefix(10) // Next 10 games
            
            // Combine: recent past (reversed to chronological) + upcoming
            schedule = Array(recentPast.reversed()) + Array(upcoming)
        }
        isLoading = false
    }
    
    private func toggleFavorite() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        var keys = (try? JSONDecoder().decode(Set<String>.self, from: favoriteTeamKeysData)) ?? []
        if keys.contains(teamKey) {
            keys.remove(teamKey)
        } else {
            keys.insert(teamKey)
        }
        if let encoded = try? JSONEncoder().encode(keys) {
            favoriteTeamKeysData = encoded
        }
    }
}

// MARK: - Schedule Game Row
struct ScheduleGameRow: View {
    let game: ESPNGame
    let teamId: String
    let broadcastService: BroadcastChannelService
    let onWatchTapped: (Channel) -> Void
    
    var isHome: Bool {
        game.homeTeam?.team.id == teamId
    }
    
    var opponent: ESPNCompetitor? {
        isHome ? game.awayTeam : game.homeTeam
    }
    
    var matchingChannel: Channel? {
        broadcastService.findChannel(forBroadcast: game.broadcast)
    }
    
    var body: some View {
        Button {
            if let channel = matchingChannel {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onWatchTapped(channel)
            }
        } label: {
            HStack(spacing: 12) {
                // Date
                if let date = game.gameDate {
                    VStack(spacing: 2) {
                        Text(date.formatted(.dateTime.month(.abbreviated)))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 45)
                }
                
                // Opponent logo
                if let logo = opponent?.team.logo, let url = URL(string: logo) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 36, height: 36)
                }
                
                // Game info
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(isHome ? "vs" : "@") \(opponent?.team.displayName ?? "TBD")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        if let date = game.gameDate {
                            Text(date.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        if let broadcast = game.broadcast {
                            Text("•")
                                .foregroundColor(.gray)
                            HStack(spacing: 4) {
                                Text(broadcast)
                                    .font(.system(size: 12, weight: .medium))
                                // Show checkmark if we have this channel
                                if matchingChannel != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                }
                            }
                            .foregroundColor(matchingChannel != nil ? Color(hex: "6138f5") : .gray)
                        }
                    }
                }
                
                Spacer()
                
                // Status / Action
                if game.isLive {
                    if matchingChannel != nil {
                        // Watch live button
                        HStack(spacing: 4) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text("WATCH")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(6)
                    } else {
                        HStack(spacing: 4) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                } else if game.isCompleted {
                    // Show final score
                    if let home = game.homeTeam?.scoreDisplay, let away = game.awayTeam?.scoreDisplay {
                        VStack(spacing: 0) {
                            Text("FINAL")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.gray)
                            Text(isHome ? "\(home)-\(away)" : "\(away)-\(home)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                } else if matchingChannel != nil {
                    // Upcoming with channel
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "6138f5"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(game.isLive && matchingChannel != nil ? Color.red.opacity(0.1) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(game.isLive && matchingChannel != nil ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(matchingChannel == nil && !game.isCompleted)
        .padding(.horizontal, 16)
    }
}

// MARK: - Team Info Row
struct TeamInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Chip Component
struct XfinityChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.purple : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DVR Recordings Content (TV-style)
struct DVRRecordingsContent: View {
    @StateObject private var viewModel = DVRViewModel()
    @State private var selectedRecording: Recording?  // drives the detail sheet
    @State private var playbackItem: PlaybackItem?
    @State private var recordingToDelete: Recording?
    @State private var showDeleteConfirmation = false

    // Storage calculations
    private var storageUsedGB: Double {
        let totalBytes = viewModel.recordings.reduce(0) { $0 + ($1.fileSize ?? 0) }
        return Double(totalBytes) / 1_073_741_824
    }

    private var storageTotalGB: Double {
        100.0 // TODO: Get from server API
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.recordings.isEmpty {
                ProgressView("Loading recordings...")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasRecordings {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Storage meter at top
                        DVRStorageMeter(
                            usedGB: storageUsedGB,
                            totalGB: storageTotalGB,
                            recordingCount: viewModel.recordings.count
                        )
                        .padding(.bottom, 8)

                        // Currently Recording
                        if !viewModel.currentlyRecording.isEmpty {
                            sectionHeader("Recording Now", icon: "record.circle", iconColor: .red)
                            ForEach(viewModel.currentlyRecording) { recording in
                                recordingRowButton(recording)
                            }
                        }

                        // Continue Watching
                        if !viewModel.inProgressRecordings.isEmpty {
                            sectionHeader("Continue Watching", icon: "play.circle", iconColor: .purple)
                            ForEach(viewModel.inProgressRecordings) { recording in
                                recordingRowButton(recording)
                            }
                        }

                        // Grouped by Date
                        ForEach(viewModel.recordingsByDate, id: \.date) { group in
                            sectionHeader(relativeDate(group.date))
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
                VStack(spacing: 12) {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No Recordings")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Your completed recordings will appear here.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await viewModel.loadRecordings()
        }
        .fullScreenCover(item: $playbackItem) { item in
            VideoPlayerView(
                mediaItem: nil,
                recordingURL: item.url,
                startPosition: item.startPosition,
                commercials: item.recording.commercials,
                recordingDurationMs: item.recording.duration
            )
        }
        .sheet(item: $selectedRecording) { recording in
            RecordingDetailSheet(
                viewModel: viewModel,
                recording: recording,
                onWatch: { playRecording(recording) },
                onDelete: {
                    selectedRecording = nil
                    Task { await viewModel.deleteRecording(recording) }
                },
                onToggleWatched: {
                    Task { await viewModel.toggleRecordingWatched(recording) }
                },
                onToggleFavorite: {
                    Task { await viewModel.toggleRecordingFavorite(recording) }
                },
                onToggleKeep: {
                    Task { await viewModel.toggleRecordingKeep(recording) }
                },
                onStopRecording: recording.isCurrentlyRecording ? {
                    Task { await viewModel.stopRecording(recording) }
                    selectedRecording = nil
                } : nil
            )
            .presentationDetents([.medium, .large])
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

    @ViewBuilder
    private func recordingRowButton(_ recording: Recording) -> some View {
        Button {
            selectedRecording = recording
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
            if let state = viewModel.recordingActionStates[recording.id], state.canDownload {
                Button {
                    Task { _ = try? await viewModel.startDownload(for: recording) }
                } label: {
                    Label(state.downloadTitle, systemImage: "arrow.down.circle")
                }
            }
            Button(role: .destructive) {
                recordingToDelete = recording
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String? = nil, iconColor: Color = .white) -> some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.top, 8)
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        if daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func playRecording(_ recording: Recording) {
        selectedRecording = nil  // dismiss detail sheet
        Task {
            do {
                let url = try await viewModel.getRecordingStream(recording)
                playbackItem = PlaybackItem(recording: recording, url: url, startPosition: recording.viewOffset)
            } catch {
                viewModel.error = error.localizedDescription
            }
        }
    }
}

// MARK: - DVR Scheduled Content
struct DVRScheduledContent: View {
    @StateObject private var viewModel = DVRViewModel()
    
    var body: some View {
        Group {
            if viewModel.hasScheduled {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.upcomingRecordings) { recording in
                            XfinityScheduledRow(recording: recording) {
                                Task { await viewModel.deleteRecording(recording) }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No Scheduled Recordings")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Schedule recordings from the Guide.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await viewModel.loadRecordings()
        }
    }
}

// MARK: - Downloads Placeholder
struct DownloadsPlaceholder: View {
    @StateObject private var viewModel = DVRViewModel()

    var body: some View {
        Group {
            if viewModel.directvDownloadJobs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No Downloads")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("DirecTV cloud downloads in progress will appear here.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(viewModel.directvDownloadJobs.values).sorted { ($0.title ?? "") < ($1.title ?? "") }, id: \.id) { job in
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(job.title ?? "Download")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(job.status ?? "Preparing")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    ProgressView(value: max(0, min(job.progress ?? 0, 1)))
                                        .tint(.purple)
                                }
                                Spacer()
                                if let progress = job.progress {
                                    Text("\(Int(progress * 100))%")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.white.opacity(0.75))
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await viewModel.loadRecordings()
        }
    }
}

// MARK: - Watchlist Content
struct WatchlistContent: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView("Loading watchlist...")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Watchlist Empty")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Add movies and shows to watch later.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.items) { watchlistItem in
                            if let media = watchlistItem.media {
                                XfinityMediaCard(item: media) {
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

// MARK: - Recording Row
struct XfinityRecordingRow: View {
    let recording: Recording

    var body: some View {
        HStack(spacing: 12) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            // Thumbnail with progress overlay
            ZStack(alignment: .bottom) {
                AuthenticatedImage(path: recording.thumb, systemPlaceholder: "play.rectangle")
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 80)
                    .clipped()
                    .cornerRadius(6)

                if recording.isInProgress {
                    GeometryReader { geo in
                        VStack {
                            Spacer()
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(height: 3)
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: geo.size.width * min(max(recording.progressPercent, 0), 1), height: 3)
                            }
                        }
                    }
                    .frame(width: 140, height: 80)
                    .cornerRadius(6)
                }
            }
            .frame(width: 140, height: 80)

            // Text info
            VStack(alignment: .leading, spacing: 3) {
                Text(recording.title)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(.white)

                if let label = recording.episodeLabel {
                    HStack(spacing: 0) {
                        Text(label)
                        if let subtitle = recording.subtitle {
                            Text(" \u{00B7} \(subtitle)")
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                }

                HStack(spacing: 4) {
                    if let channelName = recording.channelName {
                        Text(channelName)
                    }
                    Text("\u{00B7}")
                    Text(recording.durationFormatted)
                    if let size = recording.fileSizeFormatted {
                        Text("\u{00B7} \(size)")
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(.gray)

                if let sourceOwnershipLabel = recording.sourceOwnershipLabel {
                    Text(sourceOwnershipLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }

                // Badge pills
                HStack(spacing: 4) {
                    if recording.isMovie {
                        XfinityBadgePill("MOVIE", color: .blue)
                    }
                    if let rating = recording.contentRating, !rating.isEmpty {
                        XfinityBadgePill(rating, color: .gray)
                    }
                    if recording.isCurrentlyRecording {
                        XfinityBadgePill("REC", color: .red)
                    }
                    if let year = recording.year, year > 0 {
                        XfinityBadgePill(String(year), color: .gray)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch recording.status {
        case .completed: return .green
        case .recording: return .red
        case .failed: return .gray
        default:
            return recording.isInProgress ? .orange : .green
        }
    }
}

struct XfinityBadgePill: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.7))
            .cornerRadius(4)
    }
}

struct RecordingDetailSheet: View {
    @ObservedObject var viewModel: DVRViewModel
    let recording: Recording
    let onWatch: () -> Void
    let onDelete: () -> Void
    var onToggleWatched: (() -> Void)?
    var onToggleFavorite: (() -> Void)?
    var onToggleKeep: (() -> Void)?
    var onStopRecording: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showExtended = false
    @State private var actionState: RecordingDVRActionState = .fallback()
    @State private var isStartingDownload = false

    private let darkBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    private let accentPurple = Color(red: 97/255, green: 56/255, blue: 245/255)

    var body: some View {
        ZStack {
            darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Top: Thumbnail + Info side by side
                        HStack(alignment: .top, spacing: 14) {
                            // Thumbnail with progress bar
                            ZStack(alignment: .bottom) {
                                AuthenticatedImage(
                                    path: recording.thumb ?? recording.art,
                                    systemPlaceholder: "play.rectangle"
                                )
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 90)
                                .clipped()
                                .cornerRadius(8)

                                if recording.isInProgress {
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(height: 4)
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(
                                                width: 160 * min(max(recording.progressPercent, 0), 1),
                                                height: 4
                                            )
                                    }
                                }
                            }
                            .frame(width: 160, height: 90)

                            // Title / subtitle / episode info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recording.title)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)

                                if let subtitle = recording.subtitle, !subtitle.isEmpty {
                                    Text(subtitle)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.85))
                                        .lineLimit(1)
                                }

                                // Episode + date
                                HStack(spacing: 0) {
                                    if let season = recording.seasonNumber, let episode = recording.episodeNumber {
                                        Text("Season \(season), Episode \(episode)")
                                    }
                                    if recording.seasonNumber != nil {
                                        Text(" \u{00B7} ")
                                    }
                                    Text(shortDate(recording.startTime))
                                }
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            }

                            Spacer()
                        }

                        // Duration + date line
                        HStack(spacing: 6) {
                            Text(recording.durationFormatted)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text(shortDate(recording.startTime))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }

                        if let sourceOwnershipLabel = recording.sourceOwnershipLabel {
                            Text(sourceOwnershipLabel)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }

                        HStack(spacing: 8) {
                            XfinityBadgePill(actionState.routeLabel, color: accentPurple.opacity(0.85))
                            XfinityBadgePill(actionState.statusLabel, color: Color.white.opacity(0.15))
                        }

                        // Badge pills row
                        HStack(spacing: 6) {
                            if isNew {
                                XfinityBadgePill("New", color: accentPurple)
                            }
                            if recording.isMovie {
                                XfinityBadgePill("Movie", color: .blue)
                            }
                            if let rating = recording.contentRating, !rating.isEmpty {
                                XfinityBadgePill(rating, color: Color.white.opacity(0.15))
                            }
                            if let year = recording.year, year > 0 {
                                XfinityBadgePill(String(year), color: Color.white.opacity(0.15))
                            }
                            if recording.status == .failed {
                                XfinityBadgePill("Failed", color: .red)
                            }
                            if recording.isCurrentlyRecording {
                                XfinityBadgePill("REC", color: .red)
                            }
                        }

                        // Description
                        if let desc = recording.description, !desc.isEmpty {
                            Text(desc)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(showExtended ? nil : 3)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Progress
                        if recording.isInProgress {
                            VStack(alignment: .leading, spacing: 4) {
                                let remainingMin = max(1, Int((1.0 - recording.progressPercent) * Double(recording.duration) / 60000))
                                Text("\(remainingMin) min remaining")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                ProgressView(value: recording.progressPercent)
                                    .tint(accentPurple)
                            }
                        }

                        // Extended details section
                        if showExtended {
                            VStack(alignment: .leading, spacing: 12) {
                                Divider().background(Color.white.opacity(0.15))

                                // Recording info grid
                                detailRow("Channel", value: recording.channelName)
                                detailRow("Aired", value: recording.timeRangeFormatted)
                                detailRow("Date", value: recording.dateFormatted)
                                detailRow("Duration", value: recording.durationFormatted)
                                detailRow("File Size", value: recording.fileSizeFormatted)
                                detailRow("Status", value: recording.status.displayName)

                                if let season = recording.seasonNumber, let episode = recording.episodeNumber {
                                    detailRow("Episode", value: "S\(season) E\(episode)")
                                }

                                if let rating = recording.contentRating, !rating.isEmpty {
                                    detailRow("Rating", value: rating)
                                }

                                if let year = recording.year, year > 0 {
                                    detailRow("Year", value: String(year))
                                }

                                if !recording.genres.isEmpty {
                                    detailRow("Genres", value: recording.genres.joined(separator: ", "))
                                }

                                if !recording.commercials.isEmpty {
                                    detailRow("Commercials", value: "\(recording.commercials.count) detected")
                                }

                                if recording.seriesRecord {
                                    detailRow("Series Rule", value: "Active")
                                }

                                if let job = actionState.downloadJob {
                                    detailRow("Download", value: downloadLabel(job))
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(20)
                }

                // Quick action icons row
                if onToggleWatched != nil || onToggleFavorite != nil || onToggleKeep != nil {
                    HStack(spacing: 24) {
                        if let onToggleWatched {
                            Button(action: onToggleWatched) {
                                VStack(spacing: 4) {
                                    Image(systemName: recording.isWatched ? "eye.fill" : "eye")
                                        .font(.system(size: 18))
                                    Text(recording.isWatched ? "Watched" : "Unwatched")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(recording.isWatched ? accentPurple : .gray)
                            }
                        }
                        if let onToggleFavorite {
                            Button(action: onToggleFavorite) {
                                VStack(spacing: 4) {
                                    Image(systemName: recording.isFavorite ? "heart.fill" : "heart")
                                        .font(.system(size: 18))
                                    Text("Favorite")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(recording.isFavorite ? .red : .gray)
                            }
                        }
                        if let onToggleKeep {
                            Button(action: onToggleKeep) {
                                VStack(spacing: 4) {
                                    Image(systemName: recording.isProtected ? "lock.fill" : "lock.open")
                                        .font(.system(size: 18))
                                    Text(recording.isProtected ? "Kept" : "Keep")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(recording.isProtected ? .yellow : .gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                // Bottom action buttons
                HStack(spacing: 12) {
                    Button(action: onWatch) {
                        Label("Watch", systemImage: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showExtended.toggle()
                        }
                    } label: {
                        Label(showExtended ? "Less" : "Details", systemImage: showExtended ? "chevron.up" : "info.circle")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .background(showExtended ? accentPurple.opacity(0.3) : Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    if actionState.canDownload {
                        Button {
                            Task {
                                isStartingDownload = true
                                _ = try? await viewModel.startDownload(for: recording)
                                actionState = await viewModel.recordingActionState(for: recording)
                                isStartingDownload = false
                            }
                        } label: {
                            Label(isStartingDownload ? "Starting…" : actionState.downloadTitle, systemImage: "arrow.down.circle")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .background(Color.blue.opacity(0.18))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    if let onStopRecording, recording.isCurrentlyRecording {
                        Button(action: onStopRecording) {
                            Label("Stop", systemImage: "stop.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(10)
                    }

                    if actionState.canDelete {
                        Button(role: .destructive, action: onDelete) {
                            Label(deleteButtonTitle, systemImage: deleteButtonIcon)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(darkBg)
            }
        }
        .task {
            actionState = await viewModel.recordingActionState(for: recording)
        }
    }

    @ViewBuilder
    private func detailRow(_ label: String, value: String?) -> some View {
        if let value = value, !value.isEmpty {
            HStack(alignment: .top) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(width: 100, alignment: .leading)
                Text(value)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
        }
    }

    private var isNew: Bool {
        let daysSinceRecorded = Calendar.current.dateComponents([.day], from: recording.startTime, to: Date()).day ?? 0
        return daysSinceRecorded <= 7 && recording.status == .completed
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func downloadLabel(_ job: ExternalDownloadJob) -> String {
        if let progress = job.progress {
            return "\(job.status ?? "Downloading") • \(Int(progress * 100))%"
        }
        return job.status ?? "Downloading"
    }

    private var deleteButtonTitle: String {
        if recording.providerId?.lowercased() == "directv",
           recording.accountId != nil,
           (recording.status == .scheduled || recording.status == .recording) {
            return "Cancel"
        }
        return "Delete"
    }

    private var deleteButtonIcon: String {
        deleteButtonTitle == "Cancel" ? "xmark.circle" : "trash"
    }
}

// MARK: - Scheduled Row
struct XfinityScheduledRow: View {
    let recording: Recording
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recording.status == .recording ? "record.circle" : "clock")
                .font(.title3)
                .foregroundColor(recording.status == .recording ? .red : .gray)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recording.fullTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                HStack {
                    if let channelName = recording.channelName {
                        Text(channelName)
                    }
                    Text("•")
                    Text(recording.timeRangeFormatted)
                }
                .font(.system(size: 12))
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Media Card
struct XfinityMediaCard: View {
    let item: MediaItem
    let onSelect: () -> Void

    private var displayTitle: String {
        if item.type == .episode {
            return item.grandparentTitle ?? item.title
        }
        return item.title
    }

    private var displayThumb: String? {
        if item.type == .episode {
            return item.grandparentThumb ?? item.thumb
        }
        return item.thumb
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                AuthenticatedImage(
                    path: displayThumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .aspectRatio(2/3, contentMode: .fill)
                .cornerRadius(8)

                Text(displayTitle)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LiveTV Grid Tab
// Wrapper that owns the LiveTVViewModel and bridges EPGGridViewModern into the tab system

struct LiveTVGridTab: View {
    @StateObject private var viewModel = LiveTVViewModel()
    @State private var playerChannel: Channel?
    @State private var playerProgram: Program?
    @State private var showPlayer = false
    @State private var showProgramDetail = false
    @State private var detailProgram: Program?
    @State private var detailChannel: Channel?

    var body: some View {
        EPGGridViewModern(
            viewModel: viewModel,
            onChannelSelect: { channel in
                playerChannel = channel
                playerProgram = channel.nowPlaying
                showPlayer = true
            },
            onProgramSelect: { program, channel in
                detailProgram = program
                detailChannel = channel
                showProgramDetail = true
            }
        )
        .task {
            async let channels: () = viewModel.loadChannels()
            async let guide: () = viewModel.loadGuide()
            _ = await (channels, guide)
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let channel = playerChannel {
                VideoPlayerView(
                    mediaItem: nil,
                    liveChannelURL: OpenFlixAPI.shared.channelStreamURL(id: channel.id)
                )
            }
        }
        .sheet(isPresented: $showProgramDetail) {
            if let program = detailProgram, let channel = detailChannel {
                ProgramDetailSheet(program: program, channel: channel) {
                    // Play action
                    detailProgram = nil
                    showProgramDetail = false
                    playerChannel = channel
                    playerProgram = program
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPlayer = true
                    }
                }
            }
        }
    }
}

// MARK: - Program Detail Sheet (inline, shown from EPG tap)

struct ProgramDetailSheet: View {
    let program: Program
    let channel: Channel
    let onPlay: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let bg = Color(red: 17/255, green: 12/255, blue: 33/255)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Artwork
                        if let artPath = program.art ?? program.icon {
                            AuthenticatedImage(
                                path: artPath,
                                systemPlaceholder: "tv"
                            )
                            .aspectRatio(16/9, contentMode: .fill)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(program.title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)

                            if let subtitle = program.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }

                            HStack(spacing: 12) {
                                Label(channel.name, systemImage: "antenna.radiowaves.left.and.right")
                                if let rating = program.rating {
                                    Text(rating)
                                        .font(.system(size: 11, weight: .semibold))
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                if program.isNew {
                                    Text("NEW")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color.green.opacity(0.15))
                                        .cornerRadius(4)
                                }
                            }
                            .font(.system(size: 13))
                            .foregroundColor(.gray)

                            if let desc = program.description {
                                Text(desc)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal)

                        // Watch button
                        Button(action: onPlay) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Watch Live")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    XfinityTabView()
        .environmentObject(AuthViewModel())
}
#endif
