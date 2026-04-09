#if os(tvOS)
import SwiftUI
import os

extension Notification.Name {
    static let tvHomeRequestFocus = Notification.Name("tvHomeRequestFocus")
    static let tvBackPressed = Notification.Name("tvBackPressed")
    static let sidecarToggle = Notification.Name("sidecarToggle")
    static let sidecarArrowKey = Notification.Name("sidecarArrowKey")
    static let sidecarSelect = Notification.Name("sidecarSelect")
}

// MARK: - Sidecar Menu Item

enum SidecarMenuItem: String, CaseIterable, Hashable {
    case home = "Home"
    case liveTV = "Live TV"
    case teamPass = "Team Pass"
    case library = "Library"
    case search = "Search"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .liveTV: return "tv.fill"
        case .teamPass: return "sportscourt.fill"
        case .library: return "books.vertical.fill"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .home: return "Navigate to the Home screen"
        case .liveTV: return "Navigate to Live TV guide"
        case .teamPass: return "Navigate to Team Pass manager"
        case .library: return "Navigate to your Library"
        case .search: return "Navigate to Search"
        case .settings: return "Open Settings"
        }
    }

    var isTabItem: Bool {
        self != .settings
    }

    var correspondingTab: OpenFlixTVTabView.Tab? {
        switch self {
        case .home: return .home
        case .liveTV: return .liveTV
        case .teamPass: return .teamPass
        case .library: return .library
        case .search: return .search
        case .settings: return nil
        }
    }

    private static let tabItems: [SidecarMenuItem] = [.home, .liveTV, .teamPass, .library, .search]

    func nextUp() -> SidecarMenuItem? {
        guard let idx = Self.tabItems.firstIndex(of: self), idx > 0 else { return nil }
        return Self.tabItems[idx - 1]
    }

    func nextDown() -> SidecarMenuItem? {
        if self == .settings {
            return nil
        }
        guard let idx = Self.tabItems.firstIndex(of: self), idx < Self.tabItems.count - 1 else { return nil }
        return Self.tabItems[idx + 1]
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
        if item == .settings {
            close()
        } else {
            selectItem(item)
        }
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
    let onSettings: () -> Void

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
            }
        }
        .onChange(of: state.focusedItem) { _, newItem in
            if focusedMenuItem != newItem {
                focusedMenuItem = newItem
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sidecarArrowKey)) { notification in
            if let raw = notification.userInfo?["direction"] as? Int {
                state.handleArrowKey(direction: raw)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sidecarSelect)) { _ in
            if state.isOpen {
                if let item = state.focusedItem ?? focusedMenuItem {
                    if item == .settings {
                        state.close()
                        onSettings()
                    } else {
                        state.selectItem(item)
                    }
                }
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
        VStack(alignment: .leading, spacing: 10) {
            ForEach(SidecarMenuItem.allCases.filter(\.isTabItem), id: \.self) { item in
                sidecarButton(
                    item: item,
                    isSelected: item.correspondingTab == state.selectedTab
                ) {
                    state.selectItem(item)
                }
            }
        }
        .focusSection()
        .padding(.horizontal, 8)
    }

    private var settingsItem: some View {
        sidecarButton(
            item: .settings,
            isSelected: false
        ) {
            state.close()
            onSettings()
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 26)
    }

    private var separatorLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
    }

    private func sidecarButton(item: SidecarMenuItem, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 28)

                Text(item.rawValue)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
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
        case teamPass = "Team Pass"
        case library = "Library"
        case search = "Search"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .liveTV: return "tv.fill"
            case .teamPass: return "sportscourt.fill"
            case .library: return "books.vertical.fill"
            case .search: return "magnifyingglass"
            }
        }

        var accessibilityHint: String {
            switch self {
            case .home: return "Navigate to the Home screen"
            case .liveTV: return "Navigate to Live TV guide"
            case .teamPass: return "Navigate to Team Pass manager"
            case .library: return "Navigate to your Library"
            case .search: return "Navigate to Search"
            }
        }
    }

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var sidecarState = SidecarMenuState.shared
    @State private var selectedTab: Tab = .home
    @State private var showSettings = false

    private let backgroundColor = Color(red: 8 / 255, green: 10 / 255, blue: 20 / 255)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                backgroundColor.ignoresSafeArea()

                currentScreen
                    .environmentObject(authViewModel)
                    .environmentObject(settingsViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .disabled(sidecarState.isOpen)
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
                        profileName: authViewModel.currentProfile?.name,
                        onSettings: {
                            showSettings = true
                        }
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
            .onReceive(NotificationCenter.default.publisher(for: .tvBackPressed)) { _ in
                sidecarState.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .sidecarToggle)) { _ in
                sidecarState.toggle()
            }
            // NOTE: root-level onMoveCommand was blocking focus navigation in
            // child content views. Drawer is now opened via Menu/Escape button
            // or the .sidecarToggle notification only.
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
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                TVSettingsPlaceholderView()
            }
            .environmentObject(authViewModel)
            .environmentObject(settingsViewModel)
        }
        .onExitCommand {
            sidecarState.toggle()
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .home:
            XfinityHomeView()
        case .liveTV:
            LiveTVView()
        case .teamPass:
            TeamPassView()
        case .library:
            WatchlistView()
        case .search:
            SearchView()
        }
    }

    private func restoreContentFocus() {
        if selectedTab == .home {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                NotificationCenter.default.post(name: .tvHomeRequestFocus, object: nil)
            }
        }
    }
}

private struct TVSettingsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Settings")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Text("tvOS settings are not wired into this shell yet.")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(40)
        }
    }
}

#endif
