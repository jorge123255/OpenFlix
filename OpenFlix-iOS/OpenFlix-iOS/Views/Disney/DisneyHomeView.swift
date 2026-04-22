import SwiftUI

// MARK: - Disney+ Home
//
// Top-level Disney+ section. Drives:
//   1. globalNav → top tab bar (entitlement-aware on the server side)
//   2. selected tab → deeplink resolver → page → containers
//   3. shared DisneyPageRenderer for hero/rows/tile rendering
// All navigation is server-driven (browseTarget → target → deeplink),
// no client-side flattening.

struct DisneyHomeView: View {
    @StateObject private var repo = DisneyExploreRepository()
    @State private var tabs: [DXNavTab] = []
    @State private var selectedTab: DXNavTab?
    @State private var page: DXPage?
    @State private var isLoading = false
    @State private var loadError: String?

    @State private var pushedDetail: DisneyHomePushedDetail?
    @State private var pushedPage: DisneyHomePushedPage?
    @State private var showSearch = false

    var body: some View {
        VStack(spacing: 0) {
            tabBar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            Divider().background(Color.white.opacity(0.08))

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let page {
                        DisneyPageRenderer(
                            page: page,
                            repo: repo,
                            onOpenDetail: { item, container in
                                pushedDetail = DisneyHomePushedDetail(item: item, container: container)
                            },
                            onPlayEvent: { item, container in
                                pushedDetail = DisneyHomePushedDetail(item: item, container: container)
                            },
                            onOpenPage: { target, label in
                                pushedPage = DisneyHomePushedPage(target: target, label: label)
                            }
                        )
                    } else if isLoading {
                        ProgressView().tint(.white).padding(.top, 80)
                    } else if let loadError {
                        errorView(loadError)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 8/255, green: 12/255, blue: 28/255),
                         Color(red: 16/255, green: 24/255, blue: 48/255)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Disney+")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white)
                }
            }
        }
        .task {
            await repo.loadGlobalNav()
            buildTabs()
            await loadInitialTab()
        }
        .navigationDestination(item: $pushedPage) { page in
            DisneySubPageView(target: page.target, title: page.label, repo: repo,
                              onPlayEvent: { _, _ in })
        }
        .navigationDestination(item: $pushedDetail) { d in
            DisneyDetailView(item: d.item, container: d.container, repo: repo,
                             onPlayEvent: { _, _, _ in })
        }
        .sheet(isPresented: $showSearch) {
            NavigationStack {
                DisneySearchView(repo: repo)
            }
        }
    }

    // MARK: Tab bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabs) { tab in
                    Button {
                        selectedTab = tab
                        Task { await loadTab(tab) }
                    } label: {
                        Text(tab.label)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .foregroundStyle(selectedTab?.id == tab.id ? .white : .white.opacity(0.7))
                            .background(
                                Capsule()
                                    .fill(selectedTab?.id == tab.id ? Color.white.opacity(0.16) : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Tab loading

    private func buildTabs() {
        // Mirror the web's recursive nav walker (DisneyExplore.tsx
        // navTabs): descend through globalNav / subNav children,
        // dedupe by label+target, skip Search/Settings.
        tabs = repo.nav?.walkTabs() ?? []
    }

    private func loadInitialTab() async {
        guard let initial = repo.nav?.preferredInitialTab() else { return }
        selectedTab = initial
        await loadTab(initial)
    }

    private func loadTab(_ tab: DXNavTab) async {
        isLoading = true
        defer { isLoading = false }
        loadError = nil
        do {
            // Mirror the web's resolveTarget(): pageId direct → page;
            // setId → wrap as a single-container page; entityId or
            // deeplinkId → deeplink resolver → page.
            if let pageId = tab.pageId, !pageId.isEmpty {
                page = try await repo.loadPage(pageId: pageId, force: true)
                return
            }
            if let setId = tab.setId, !setId.isEmpty {
                if let container = try await repo.loadSetFromTarget(tab.asTarget) {
                    page = DXPage(id: setId, pageId: setId, title: tab.label,
                                  style: nil, pageStyle: nil,
                                  containers: [container], visuals: nil, actions: nil)
                }
                return
            }
            let refId = tab.entityId ?? tab.deeplinkId
            let refIdType = tab.entityId != nil ? (tab.entityType ?? "entityId") : "deeplinkId"
            if let refId, !refId.isEmpty {
                let action = try await repo.resolveDeeplink(refId: refId, refIdType: refIdType)
                if let pageId = action?.pageId, !pageId.isEmpty {
                    page = try await repo.loadPage(pageId: pageId, force: true)
                } else if let setId = action?.setId, !setId.isEmpty {
                    let target = DXTarget(type: nil, scope: nil, id: nil,
                                          setId: setId, pageId: nil,
                                          entityId: nil, entityType: nil,
                                          layoutId: nil, pageResolutionId: nil, setResolutionId: nil,
                                          pageStyle: nil, setStyle: nil,
                                          skipEligibilityCheck: nil, limit: nil, offset: nil,
                                          label: tab.label,
                                          refId: nil, refIdType: nil)
                    if let container = try await repo.loadSetFromTarget(target) {
                        page = DXPage(id: setId, pageId: setId, title: tab.label,
                                      style: nil, pageStyle: nil,
                                      containers: [container], visuals: nil, actions: nil)
                    }
                }
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32)).foregroundStyle(.orange)
            Text("Disney+ unavailable").font(.headline).foregroundStyle(.white)
            Text(msg)
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center).padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

// MARK: - Nav wrapper types

struct DisneyHomePushedPage: Hashable, Identifiable {
    let target: DXTarget
    let label: String?
    var id: String { (target.pageId ?? target.setId ?? "?") + (label ?? "") }
    static func == (lhs: DisneyHomePushedPage, rhs: DisneyHomePushedPage) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct DisneyHomePushedDetail: Hashable, Identifiable {
    let item: DXItem
    let container: DXContainer?
    var id: String { item.id + ":" + (container?.id ?? "?") }
    static func == (lhs: DisneyHomePushedDetail, rhs: DisneyHomePushedDetail) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
