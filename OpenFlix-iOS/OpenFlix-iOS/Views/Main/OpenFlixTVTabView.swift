#if os(tvOS)
import SwiftUI
import os

extension Notification.Name {
    static let tvHomeRequestFocus = Notification.Name("tvHomeRequestFocus")
    static let tvContentRequestFocus = Notification.Name("tvContentRequestFocus")
    static let tvBackPressed = Notification.Name("tvBackPressed")
    static let sidecarToggle = Notification.Name("sidecarToggle")
    static let sidecarArrowKey = Notification.Name("sidecarArrowKey")
    static let sidecarSelect = Notification.Name("sidecarSelect")
}

// MARK: - Sidecar Menu Item

enum SidecarMenuItem: String, CaseIterable, Hashable {
    case home = "Home"
    case liveTV = "Live TV"
    case catchUp = "Catch Up"
    case onLater = "On Later"
    case teamPass = "Team Pass"
    case groups = "Groups"
    case library = "Library"
    case search = "Search"
    case sports = "Sports"
    case browse = "Browse"
    case stats = "Stats"
    case settings = "Settings"

    enum Section: String, CaseIterable {
        case main = "Browse"
        case liveTV = "Live TV"
        case library = "Library"
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .liveTV: return "tv.fill"
        case .catchUp: return "clock.arrow.circlepath"
        case .onLater: return "calendar.badge.clock"
        case .teamPass: return "sportscourt.fill"
        case .groups: return "square.grid.2x2.fill"
        case .library: return "books.vertical.fill"
        case .search: return "magnifyingglass"
        case .sports: return "sportscourt.fill"
        case .browse: return "square.grid.2x2.fill"
        case .stats: return "chart.bar.fill"
        case .settings: return "gearshape"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .home: return "Navigate to the Home screen"
        case .liveTV: return "Navigate to Live TV guide"
        case .catchUp: return "Navigate to Catch Up"
        case .onLater: return "Navigate to On Later"
        case .teamPass: return "Navigate to Team Pass manager"
        case .groups: return "Navigate to Channel Groups"
        case .library: return "Navigate to your Library"
        case .search: return "Navigate to Search"
        case .sports: return "Browse live and upcoming sports"
        case .browse: return "Browse Disney+, Max, and more"
        case .stats: return "View watch and recording stats"
        case .settings: return "Open Settings"
        }
    }

    var isTabItem: Bool {
        true
    }

    var section: Section? {
        switch self {
        case .home:
            return .main
        case .liveTV, .catchUp, .onLater, .teamPass, .groups, .sports, .browse:
            return .liveTV
        case .library, .search, .stats:
            return .library
        case .settings:
            return nil
        }
    }

    var correspondingTab: OpenFlixTVTabView.Tab? {
        switch self {
        case .home: return .home
        case .liveTV: return .liveTV
        case .catchUp: return .catchUp
        case .onLater: return .onLater
        case .teamPass: return .teamPass
        case .groups: return .groups
        case .library: return .library
        case .search: return .search
        case .sports: return .sports
        case .browse: return .browse
        case .stats: return .stats
        case .settings: return .settings
        }
    }

    private static let tabItems: [SidecarMenuItem] = [.home, .liveTV, .catchUp, .onLater, .teamPass, .groups, .library, .search, .sports, .browse, .stats]
    private static let fullMenuItems: [SidecarMenuItem] = [.home, .liveTV, .catchUp, .onLater, .teamPass, .groups, .library, .search, .sports, .browse, .stats]

    func nextUp() -> SidecarMenuItem? {
        guard let idx = Self.fullMenuItems.firstIndex(of: self), idx > 0 else { return nil }
        return Self.fullMenuItems[idx - 1]
    }

    func nextDown() -> SidecarMenuItem? {
        if self == .settings {
            return nil
        }
        guard let idx = Self.fullMenuItems.firstIndex(of: self), idx < Self.fullMenuItems.count - 1 else { return nil }
        return Self.fullMenuItems[idx + 1]
    }
}

// MARK: - Sidecar Menu State

@MainActor
final class SidecarMenuState: ObservableObject {
    @Published var isOpen = false
    @Published var focusedItem: SidecarMenuItem? = nil
    @Published var lastFocusedItem: SidecarMenuItem = .home
    @Published var selectedTab: OpenFlixTVTabView.Tab = .home

    private var debounceTask: Task<Void, Never>?
    private static let logger = Logger(subsystem: "com.openflix.tvos", category: "Sidecar")

    static let shared = SidecarMenuState()

    func toggle() {
        if isOpen {
            close()
        } else {
            open()
        }
    }

    func open() {
        guard !isOpen else { return }
        debounceTask?.cancel()
        debounceTask = Task {
            Self.logger.debug("Sidecar opening")
            withAnimation(.easeInOut(duration: 0.25)) {
                isOpen = true
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
            guard !Task.isCancelled else { return }
            focusedItem = lastFocusedItem
        }
    }

    func close() {
        guard isOpen else { return }
        debounceTask?.cancel()
        Self.logger.debug("Sidecar closing")
        if let item = focusedItem {
            lastFocusedItem = item
        }
        focusedItem = nil
        withAnimation(.easeInOut(duration: 0.25)) {
            isOpen = false
        }
    }

    func selectItem(_ item: SidecarMenuItem) {
        lastFocusedItem = item
        if let tab = item.correspondingTab {
            selectedTab = tab
        }
        close()
    }

    func handleArrowKey(direction: Int) {
        guard isOpen else {
            if direction == 2 {
                open()
            }
            return
        }

        let current = focusedItem ?? lastFocusedItem

        switch direction {
        case 0:
            if let prev = current.nextUp() {
                focusedItem = prev
            }
        case 1:
            if current == .search {
                focusedItem = .settings
            } else if let next = current.nextDown() {
                focusedItem = next
            }
        case 2:
            close()
        case 3:
            break
        default:
            break
        }
    }

    func handleSelect() {
        guard isOpen, let item = focusedItem else { return }
        selectItem(item)
    }

    func restoreState() {
        Self.logger.debug("Sidecar restoring state, lastFocused=\(self.lastFocusedItem.rawValue)")
        if isOpen {
            focusedItem = lastFocusedItem
        }
    }
}

// MARK: - Sidecar Menu View

struct SidecarMenuView: View {
    @ObservedObject var state: SidecarMenuState
    let profileName: String?

    @FocusState private var focusedMenuItem: SidecarMenuItem?

    private let accentColor = Color(red: 97 / 255, green: 56 / 255, blue: 245 / 255)
    private let drawerBackground = Color(red: 17 / 255, green: 12 / 255, blue: 33 / 255)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            menuItems
            Spacer()
            separatorLine
            settingsItem
        }
        .frame(maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [drawerBackground, drawerBackground.opacity(0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Navigation menu")
        .accessibilityHint("Use up and down arrows to navigate, select to choose, right arrow or back to close")
        .onChange(of: focusedMenuItem) { _, newItem in
            if let newItem {
                state.focusedItem = newItem
            } else {
                // Focus left the sidecar (e.g. user pressed right) — close it
                if state.isOpen {
                    state.close()
                }
            }
        }
        .onChange(of: state.focusedItem) { _, newItem in
            if focusedMenuItem != newItem {
                focusedMenuItem = newItem
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OpenFlix")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(accentColor)

            if let profileName {
                Text(profileName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 56)
        .padding(.bottom, 28)
    }

    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(SidecarMenuItem.Section.allCases, id: \.self) { section in
                let sectionItems = SidecarMenuItem.allCases.filter { $0.section == section }
                if !sectionItems.isEmpty {
                    VStack(alignment: .leading, spacing: section == .liveTV ? 8 : 10) {
                        Text(section.rawValue)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.38))
                            .tracking(1.2)
                            .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: section == .liveTV ? 6 : 10) {
                            ForEach(sectionItems, id: \.self) { item in
                                sidecarButton(
                                    item: item,
                                    isSelected: item.correspondingTab == state.selectedTab,
                                    compact: section == .liveTV
                                ) {
                                    state.selectItem(item)
                                }
                            }
                        }
                    }
                }
            }
        }
        .focusSection()
        .padding(.horizontal, 8)
    }

    private var settingsItem: some View {
        sidecarButton(
            item: .settings,
            isSelected: state.selectedTab == .settings,
            compact: false
        ) {
            state.selectItem(.settings)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 26)
        // Mark Settings as its own focus section so the tvOS focus engine
        // navigates to it when the user presses down past the last menu
        // item. Without this it stays trapped inside `menuItems`'
        // `.focusSection()` and Settings is unreachable.
        .focusSection()
    }

    private var separatorLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
    }

    private func sidecarButton(item: SidecarMenuItem, isSelected: Bool, compact: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: compact ? 12 : 14) {
                Image(systemName: item.icon)
                    .font(.system(size: compact ? 16 : 18, weight: .semibold))
                    .frame(width: compact ? 24 : 28)

                Text(item.rawValue)
                    .font(.system(size: compact ? 18 : 20, weight: isSelected ? .semibold : .regular))

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, compact ? 11 : 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? accentColor.opacity(0.24) : Color.clear)
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? accentColor : .clear)
                    .frame(width: 4, height: 28)
                    .padding(.leading, 6)
            }
        }
        .buttonStyle(SidecarButtonStyle(accentColor: accentColor, isSelected: isSelected))
        .focused($focusedMenuItem, equals: item)
        .accessibilityLabel(item.rawValue)
        .accessibilityHint(item.accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

}

private struct SidecarButtonStyle: ButtonStyle {
    let accentColor: Color
    let isSelected: Bool

    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(resolvedForeground)
            .background(focusedBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(borderColor, lineWidth: 2)
            )
            .shadow(color: isFocused ? Color.white.opacity(0.08) : .clear, radius: 10, y: 0)
            .scaleEffect(isFocused ? 1.015 : 1.0)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    private var resolvedForeground: Color {
        if isSelected { return accentColor }
        if isFocused { return .white }
        return .white.opacity(0.9)
    }

    private var focusedBackground: Color {
        isFocused ? Color.white.opacity(0.08) : .clear
    }

    private var borderColor: Color {
        isFocused ? Color.white.opacity(0.45) : .clear
    }
}

// MARK: - Main Tab View

struct OpenFlixTVTabView: View {
    enum Tab: String, CaseIterable, Hashable {
        case home = "Home"
        case liveTV = "Live TV"
        case catchUp = "Catch Up"
        case onLater = "On Later"
        case teamPass = "Team Pass"
        case groups = "Groups"
        case library = "Library"
        case search = "Search"
        case sports = "Sports"
        case browse = "Browse"
        case stats = "Stats"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .liveTV: return "tv.fill"
            case .catchUp: return "clock.arrow.circlepath"
            case .onLater: return "calendar.badge.clock"
            case .teamPass: return "sportscourt.fill"
            case .groups: return "square.grid.2x2.fill"
            case .library: return "books.vertical.fill"
            case .search: return "magnifyingglass"
            case .sports: return "sportscourt.fill"
            case .browse: return "square.grid.2x2.fill"
            case .stats: return "chart.bar.fill"
            case .settings: return "gearshape"
            }
        }

        var accessibilityHint: String {
            switch self {
            case .home: return "Navigate to the Home screen"
            case .liveTV: return "Navigate to Live TV guide"
            case .catchUp: return "Navigate to Catch Up"
            case .onLater: return "Navigate to On Later"
            case .teamPass: return "Navigate to Team Pass manager"
            case .groups: return "Navigate to Channel Groups"
            case .library: return "Navigate to your Library"
            case .search: return "Navigate to Search"
            case .sports: return "Browse live and upcoming sports"
            case .browse: return "Browse Disney+, Max, and more"
            case .stats: return "View watch and recording stats"
            case .settings: return "Open Settings"
            }
        }
    }

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var sidecarState = SidecarMenuState.shared
    @State private var selectedTab: Tab = .home

    private let backgroundColor = Color(red: 8 / 255, green: 10 / 255, blue: 20 / 255)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                backgroundColor.ignoresSafeArea()

                currentScreen
                    .environmentObject(authViewModel)
                    .environmentObject(settingsViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        if sidecarState.isOpen {
                            Color.black.opacity(0.42)
                                .ignoresSafeArea()
                                .transition(.opacity)
                                .onTapGesture {
                                    sidecarState.close()
                                }
                        }
                    }
                    .offset(x: sidecarState.isOpen ? 220 : 0)
                    .scaleEffect(sidecarState.isOpen ? 0.97 : 1.0, anchor: .leading)

                if sidecarState.isOpen {
                    SidecarMenuView(
                        state: sidecarState,
                        profileName: authViewModel.currentProfile?.name
                    )
                    .frame(width: 320)
                    .zIndex(2)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: sidecarState.isOpen)
            .onAppear {
                sidecarState.restoreState()
            }
            .onExitCommand {
                if sidecarState.isOpen {
                    sidecarState.close()
                } else {
                    sidecarState.open()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .sidecarToggle)) { _ in
                sidecarState.toggle()
            }
            .onChange(of: sidecarState.selectedTab) { _, newTab in
                selectedTab = newTab
            }
            .onChange(of: sidecarState.isOpen) { _, isOpen in
                if !isOpen {
                    restoreContentFocus()
                }
            }
            .onChange(of: selectedTab) { _, _ in
                if !sidecarState.isOpen {
                    restoreContentFocus()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    sidecarState.restoreState()
                } else if newPhase == .background {
                    if sidecarState.isOpen {
                        sidecarState.close()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.22), value: selectedTab)
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .home:
            NavigationStack {
                XfinityHomeView()
            }
        case .liveTV:
            LiveTVView()
        case .catchUp:
            CatchupView()
        case .onLater:
            OnLaterView()
        case .teamPass:
            TeamPassView()
        case .groups:
            ChannelGroupsView()
        case .library:
            WatchlistView()
        case .search:
            SearchView()
        case .sports:
            // SportsView provides its own NavigationStack; nesting one here
            // breaks its fullScreenCover (taps fired but no player).
            SportsView()
        case .browse:
            TVBrowseHubView()
        case .stats:
            NavigationStack {
                WatchStatsView()
            }
        case .settings:
            NavigationStack {
                SettingsView()
            }
        }
    }

    private func restoreContentFocus() {
        // Retry a few times to give the focus system a chance
        let delays: [Double] = [0.08, 0.25, 0.5]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Post both a tab-specific and a generic notification
                NotificationCenter.default.post(name: .tvContentRequestFocus, object: nil)
                if selectedTab == .home {
                    NotificationCenter.default.post(name: .tvHomeRequestFocus, object: nil)
                }
            }
        }
    }
}

#endif
