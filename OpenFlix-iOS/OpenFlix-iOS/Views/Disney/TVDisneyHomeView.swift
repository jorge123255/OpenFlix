#if os(tvOS)
import SwiftUI

// MARK: - TVDisneyHomeView
//
// Apple TV Disney+ destination. Drives globalNav → deeplink → page →
// containers; renders containers via TVDisneyPageRenderer. No polling
// (Disney browse is user-driven).

struct TVDisneyHomeView: View {
    @StateObject private var repo = DisneyExploreRepository()
    @State private var tabs: [DisneyTab] = []
    @State private var selectedTab: DisneyTab?
    @State private var page: DXPage?
    @State private var isLoadingPage = false
    @State private var loadError: String?

    @State private var pushedDetail: TVDisneyPushedDetail?
    @State private var pushedPage: TVDisneyPushedPage?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color(red: 8/255, green: 12/255, blue: 28/255),
                             Color(red: 16/255, green: 24/255, blue: 48/255)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        tabStrip
                            .padding(.top, 30)

                        if let page {
                            TVDisneyPageRenderer(
                                page: page,
                                repo: repo,
                                onOpenDetail: { item, container in
                                    pushedDetail = TVDisneyPushedDetail(item: item, container: container)
                                },
                                onPlayEvent: { item, container in
                                    pushedDetail = TVDisneyPushedDetail(item: item, container: container)
                                },
                                onOpenPage: { target, label in
                                    pushedPage = TVDisneyPushedPage(target: target, label: label)
                                }
                            )
                        } else if isLoadingPage {
                            ProgressView().tint(.white).padding(.top, 80)
                        } else if let loadError {
                            errorView(loadError)
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
            .task {
                await repo.loadGlobalNav()
                buildTabs()
                await loadInitialTab()
            }
            .navigationDestination(item: $pushedPage) { p in
                TVDisneySubPageView(target: p.target, title: p.label, repo: repo)
            }
            .navigationDestination(item: $pushedDetail) { d in
                TVDisneyDetailView(item: d.item, container: d.container, repo: repo)
            }
        }
    }

    // MARK: Tab strip

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(tabs) { tab in
                    Button {
                        selectedTab = tab
                        Task { await loadTab(tab) }
                    } label: {
                        Text(tab.title)
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 22).padding(.vertical, 12)
                            .foregroundStyle(selectedTab?.id == tab.id ? .white : .white.opacity(0.7))
                            .background(
                                Capsule()
                                    .fill(selectedTab?.id == tab.id ? Color.white.opacity(0.2) : Color.white.opacity(0.07))
                            )
                    }
                    .buttonStyle(OFFocusableButtonStyle(cornerRadius: 999))
                }
            }
            .padding(.horizontal, 56)
        }
        .focusSection()
    }

    // MARK: Tab loading

    private func buildTabs() {
        guard let navChildren = repo.nav?.children else { return }
        var collected: [DisneyTab] = []
        for child in navChildren {
            if let leaves = child.children {
                for leaf in leaves {
                    let title = leaf.visuals?.displayText ?? leaf.action?.visuals?.displayText
                    let deeplinkId = leaf.action?.slug ?? leaf.browse?.deeplinkId
                    let pageId = leaf.browse?.pageId
                    guard let title, !title.isEmpty else { continue }
                    guard deeplinkId != nil || pageId != nil else { continue }
                    collected.append(DisneyTab(title: title, deeplinkId: deeplinkId, pageId: pageId))
                }
            }
        }
        tabs = collected
    }

    private func loadInitialTab() async {
        guard let first = tabs.first else { return }
        selectedTab = first
        await loadTab(first)
    }

    private func loadTab(_ tab: DisneyTab) async {
        isLoadingPage = true
        defer { isLoadingPage = false }
        loadError = nil
        do {
            if let pageId = tab.pageId, !pageId.isEmpty {
                page = try await repo.loadPage(pageId: pageId, force: true)
                return
            }
            if let deeplinkId = tab.deeplinkId, !deeplinkId.isEmpty {
                let action = try await repo.resolveDeeplink(refId: deeplinkId, refIdType: "deeplinkId")
                if let pageId = action?.pageId, !pageId.isEmpty {
                    page = try await repo.loadPage(pageId: pageId, force: true)
                }
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40)).foregroundStyle(.orange)
            Text("Disney+ unavailable").font(.system(size: 22, weight: .heavy)).foregroundStyle(.white)
            Text(msg)
                .font(.system(size: 14)).foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center).padding(.horizontal, 60)
        }
        .frame(maxWidth: .infinity).padding(.top, 80)
    }
}

// MARK: - Push wrappers (tvOS-only to avoid colliding with iPhone wrappers)

struct TVDisneyPushedDetail: Hashable, Identifiable {
    let item: DXItem
    let container: DXContainer?
    var id: String { item.id + ":" + (container?.id ?? "?") }
    static func == (lhs: TVDisneyPushedDetail, rhs: TVDisneyPushedDetail) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct TVDisneyPushedPage: Hashable, Identifiable {
    let target: DXTarget
    let label: String?
    var id: String { (target.pageId ?? target.setId ?? "?") + (label ?? "") }
    static func == (lhs: TVDisneyPushedPage, rhs: TVDisneyPushedPage) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Sub-page (used for See-all / browseTarget pushes)

struct TVDisneySubPageView: View {
    let target: DXTarget
    let title: String?
    @ObservedObject var repo: DisneyExploreRepository

    @State private var page: DXPage?
    @State private var loadError: String?
    @State private var pushedDetail: TVDisneyPushedDetail?
    @State private var pushedPage: TVDisneyPushedPage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if let title {
                    Text(title)
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 30).padding(.horizontal, 56)
                }

                if let page {
                    TVDisneyPageRenderer(
                        page: page, repo: repo,
                        onOpenDetail: { i, c in pushedDetail = TVDisneyPushedDetail(item: i, container: c) },
                        onPlayEvent: { i, c in pushedDetail = TVDisneyPushedDetail(item: i, container: c) },
                        onOpenPage: { t, l in pushedPage = TVDisneyPushedPage(target: t, label: l) }
                    )
                } else if loadError == nil {
                    ProgressView().tint(.white).padding(.top, 60)
                }
                if let loadError {
                    Text(loadError).foregroundStyle(.red).padding()
                }
            }
            .padding(.bottom, 80)
        }
        .background(Color(red: 6/255, green: 4/255, blue: 16/255).ignoresSafeArea())
        .task { await load() }
        .navigationDestination(item: $pushedPage) { p in
            TVDisneySubPageView(target: p.target, title: p.label, repo: repo)
        }
        .navigationDestination(item: $pushedDetail) { d in
            TVDisneyDetailView(item: d.item, container: d.container, repo: repo)
        }
    }

    private func load() async {
        do {
            if let pageId = target.pageId, !pageId.isEmpty {
                page = try await repo.loadPage(pageId: pageId, target: target)
            } else if let setId = target.setId, !setId.isEmpty {
                if let container = try await repo.loadSetFromTarget(target) {
                    page = DXPage(id: setId, pageId: setId, title: title, style: nil, pageStyle: nil,
                                  containers: [container], visuals: nil)
                }
            } else if let refId = target.refId {
                let action = try await repo.resolveDeeplink(refId: refId, refIdType: target.refIdType ?? "deeplinkId")
                if let pageId = action?.pageId, !pageId.isEmpty {
                    page = try await repo.loadPage(pageId: pageId)
                }
            }
        } catch {
            loadError = error.localizedDescription
        }
    }
}
#endif
