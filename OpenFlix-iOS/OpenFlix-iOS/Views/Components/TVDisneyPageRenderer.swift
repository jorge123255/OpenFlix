#if os(tvOS)
import SwiftUI

// MARK: - TV Disney Page Renderer
//
// 10-foot focus-aware version of the iPhone DisneyPageRenderer.
// Same shape detection (hero_*/brand_*/immersive container = hero;
// rest = horizontal rails; lazy-load with full ctx forwarding via
// /disney/explore/set/:setId), but laid out for the focus engine:
//   - Each rail is its own .focusSection() so left/right stays in
//     the rail and up/down jumps between rails.
//   - Tile ids are stable across hub refresh, so the focus engine
//     keeps focus on the same tile when the 45s poll re-renders the
//     hub (a re-fetched item with the same id keeps focus).
//   - Pretiouos/next focus across hero → first rail handled by
//     normal default focus rules.

struct TVDisneyPageRenderer: View {
    let page: DXPage
    @ObservedObject var repo: DisneyExploreRepository
    let onOpenDetail: (DXItem, DXContainer?) -> Void
    let onPlayEvent: (DXItem, DXContainer?) -> Void
    let onOpenPage: (DXTarget, String?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            if page.isDetailPage {
                TVDisneyDetailPageHero(page: page).padding(.horizontal, 56)
            } else if let hero = heroContainer {
                TVDisneyHeroBanner(container: hero, repo: repo) { item in
                    handleTap(item: item, container: hero)
                }
                .padding(.horizontal, 56)
            }
            ForEach(rowContainers) { container in
                TVDisneyRailView(
                    container: container,
                    repo: repo,
                    onSelect: { item in handleTap(item: item, container: container) },
                    onOpenAll: { target, label in onOpenPage(target, label) }
                )
            }
        }
    }

    private var heroContainer: DXContainer? {
        page.containers?.first(where: { isHeroStyle($0.style) })
    }

    private var rowContainers: [DXContainer] {
        guard let containers = page.containers else { return [] }
        guard let hero = heroContainer else { return containers }
        return containers.filter { $0.id != hero.id }
    }

    private func isHeroStyle(_ style: String?) -> Bool {
        guard let s = style?.lowercased() else { return false }
        return s.hasPrefix("hero_") || s.hasPrefix("brand_") || s == "immersive"
    }

    private func handleTap(item: DXItem, container: DXContainer?) {
        if item.isPlayable {
            onPlayEvent(item, container)
            return
        }
        if let bt = item.browseTarget, hasNav(bt) {
            onOpenPage(bt, item.displayTitle)
            return
        }
        if let t = item.target, hasNav(t) {
            onOpenPage(t, item.displayTitle)
            return
        }
        onOpenDetail(item, container)
    }

    private func hasNav(_ target: DXTarget) -> Bool {
        (target.pageId?.isEmpty == false) ||
        (target.setId?.isEmpty == false) ||
        (target.entityId?.isEmpty == false)
    }
}

// MARK: - Hero banner

struct TVDisneyHeroBanner: View {
    let container: DXContainer
    @ObservedObject var repo: DisneyExploreRepository
    let onSelect: (DXItem) -> Void

    @State private var loadStarted = false
    @State private var heroIndex = 0

    private var items: [DXItem] {
        if let xs = container.items, !xs.isEmpty { return xs }
        return repo.setById[container.id]?.items ?? []
    }

    var body: some View {
        Group {
            if let item = items[safe: heroIndex] ?? items.first {
                Button { onSelect(item) } label: {
                    heroLabel(for: item)
                }
                .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 22))
            } else {
                placeholder
            }
        }
        .task {
            guard !loadStarted else { return }
            loadStarted = true
            if (container.items?.isEmpty ?? true) && repo.setById[container.id] == nil {
                await repo.loadSet(container)
            }
        }
        .task(id: container.id) {
            // 7s rotation matches the web's HERO_ROTATE_MS. Skip when
            // there's only one item so we don't churn focus.
            heroIndex = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 7_000_000_000)
                if Task.isCancelled { return }
                let count = items.count
                guard count > 1 else { continue }
                heroIndex = (heroIndex + 1) % count
            }
        }
    }

    private func heroLabel(for item: DXItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let urlString = item.bestImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.black.opacity(0.4)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 480)
                .clipped()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.08, blue: 0.30),
                             Color(red: 0.10, green: 0.15, blue: 0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 480)
            }

            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 480)

            VStack(alignment: .leading, spacing: 10) {
                if let badge = item.badges?.first {
                    Text(badge.uppercased())
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(2)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.white.opacity(0.18), in: Capsule())
                }
                Text(item.displayTitle ?? container.displayTitle ?? "Featured")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let sub = item.displaySubtitle ?? item.visuals?.description?.brief {
                    Text(sub)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(3)
                }
            }
            .padding(34)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(Color.white.opacity(0.04))
            .frame(height: 480)
    }
}

// MARK: - Detail page hero (uses page-level artwork, no rotation)

private struct TVDisneyDetailPageHero: View {
    let page: DXPage

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let urlString = page.pageHeroArtworkURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.black.opacity(0.4)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 480)
                .clipped()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.08, blue: 0.30),
                             Color(red: 0.10, green: 0.15, blue: 0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 480)
            }
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 480)
            VStack(alignment: .leading, spacing: 10) {
                Text("DETAIL")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(2.5)
                Text(page.title ?? page.visuals?.title ?? page.visuals?.displayText ?? "Detail")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let desc = page.visuals?.description?.medium ?? page.visuals?.description?.brief {
                    Text(desc)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(3)
                }
            }
            .padding(34)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// `subscript(safe:)` is provided by the project-wide Array extension
// in ViewModels/PlayerViewModel.swift.

// MARK: - Rail (focus section per row)

struct TVDisneyRailView: View {
    let container: DXContainer
    @ObservedObject var repo: DisneyExploreRepository
    let onSelect: (DXItem) -> Void
    let onOpenAll: (DXTarget, String?) -> Void

    @State private var didRequestLoad = false

    private var items: [DXItem] {
        if let xs = container.items, !xs.isEmpty { return xs }
        return repo.setById[container.id]?.items ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(container.displayTitle ?? "")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if let target = container.browseTarget ?? container.target {
                    Button {
                        onOpenAll(target, container.displayTitle)
                    } label: {
                        Text("See all")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 14).padding(.vertical, 6)
                    }
                    .buttonStyle(OFFocusableButtonStyle(cornerRadius: 999))
                }
            }
            .padding(.horizontal, 56)

            if items.isEmpty && repo.loadingSets.contains(container.id) {
                HStack { ProgressView().tint(.white); Spacer() }
                    .padding(.horizontal, 56)
            } else if items.isEmpty, let err = repo.setErrors[container.id] {
                Text(err)
                    .font(.system(size: 16))
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.horizontal, 56)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 18) {
                        ForEach(items) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                TVDisneyTile(item: item, style: container.style)
                            }
                            .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: tileCornerRadius))
                        }
                    }
                    .padding(.horizontal, 56)
                    .padding(.vertical, 12)
                }
            }
        }
        .focusSection()
        .task {
            guard !didRequestLoad else { return }
            didRequestLoad = true
            if (container.items?.isEmpty ?? true) && repo.setById[container.id] == nil {
                await repo.loadSet(container)
            }
        }
    }

    private var tileCornerRadius: CGFloat {
        let style = container.style?.lowercased() ?? ""
        if style.contains("logo") { return 999 }
        return 12
    }
}

// MARK: - Tile

struct TVDisneyTile: View {
    let item: DXItem
    let style: String?
    @Environment(\.isFocused) private var isFocused

    private var aspect: CGFloat {
        if let s = style?.lowercased() {
            if s.contains("poster") || s.contains("portrait") { return 2.0 / 3.0 }
            if s.contains("logo") { return 1.0 }
        }
        return 16.0 / 9.0
    }

    private var width: CGFloat { aspect < 1 ? 220 : 320 }
    private var height: CGFloat { width / aspect }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let urlString = item.bestImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.white.opacity(0.06)
                    }
                    .frame(width: width, height: height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: tileRadius, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: tileRadius, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: width, height: height)
                        .overlay(
                            Text(item.displayTitle ?? "")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(8)
                        )
                }
                if item.isLive {
                    badge("LIVE", color: .red)
                } else if item.isUpcoming {
                    badge("UPCOMING", color: Color.white.opacity(0.18))
                }
            }
            if let title = item.displayTitle {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isFocused ? .white : .white.opacity(0.85))
                    .lineLimit(2)
                    .frame(width: width, alignment: .leading)
            }
        }
    }

    private var tileRadius: CGFloat {
        let s = style?.lowercased() ?? ""
        return s.contains("logo") ? 999 : 12
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(color, in: Capsule())
            .padding(8)
    }
}
#endif
