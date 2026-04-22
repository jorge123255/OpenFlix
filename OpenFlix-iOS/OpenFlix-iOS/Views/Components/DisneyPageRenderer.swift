import SwiftUI

// MARK: - Disney Page Renderer
//
// Reusable renderer for the raw Disney page/container/item shape.
// Owned by the Disney+ section in Library, and by the ESPN tab when
// hub.disneyHub is non-null. Detection rules per the brief:
//
//   - The first container whose style starts with "hero_" / "brand_"
//     or equals "immersive" becomes the hero carousel.
//   - All other containers render as horizontal rows ("rails").
//   - When a container has no items[], the renderer lazy-fetches via
//     `/disney/explore/set/:setId` on first appearance, preserving full
//     request context (pageId/setId/layoutId/...).
//   - Tile tap routing: browseTarget → target → deeplink resolver.

struct DisneyPageRenderer: View {
    let page: DXPage
    @ObservedObject var repo: DisneyExploreRepository
    let onOpenDetail: (DXItem, DXContainer?) -> Void
    let onPlayEvent: (DXItem, DXContainer?) -> Void
    let onOpenPage: (DXTarget, String?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if page.isDetailPage {
                // Detail pages use the page's own artwork as the hero
                // (no rotating multi-item hero). Mirrors the web's
                // pageArtwork() behavior on details_* style pages.
                DisneyDetailPageHero(page: page).padding(.horizontal, 16)
            } else if let hero = heroContainer {
                DisneyRotatingHero(
                    container: hero,
                    repo: repo,
                    onSelect: { item in handleTap(item: item, container: hero) }
                )
                .padding(.horizontal, 16)
            }
            ForEach(rowContainers) { container in
                DisneyRowView(
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
        if let bt = item.browseTarget, hasPageOrSetId(bt) {
            onOpenPage(bt, item.displayTitle)
            return
        }
        if let t = item.target, hasPageOrSetId(t) {
            onOpenPage(t, item.displayTitle)
            return
        }
        onOpenDetail(item, container)
    }

    private func hasPageOrSetId(_ target: DXTarget) -> Bool {
        (target.pageId?.isEmpty == false) ||
        (target.setId?.isEmpty == false) ||
        (target.entityId?.isEmpty == false)
    }
}

// MARK: - Rotating hero (matches web's 7s carousel cadence)

private struct DisneyRotatingHero: View {
    let container: DXContainer
    @ObservedObject var repo: DisneyExploreRepository
    let onSelect: (DXItem) -> Void

    @State private var heroIndex = 0

    private var items: [DXItem] {
        if let xs = container.items, !xs.isEmpty { return xs }
        return repo.setById[container.id]?.items ?? []
    }

    var body: some View {
        Group {
            if let item = items[safe: heroIndex] ?? items.first {
                DisneyHeroBanner(item: item, container: container) { onSelect(item) }
            } else {
                EmptyView()
            }
        }
        .task(id: container.id) {
            heroIndex = 0
            guard items.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 7_000_000_000)
                if Task.isCancelled { return }
                let count = items.count
                guard count > 1 else { continue }
                heroIndex = (heroIndex + 1) % count
            }
        }
    }
}

// MARK: - Detail page hero (no rotation; uses page-level artwork)

private struct DisneyDetailPageHero: View {
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
                .frame(height: 220)
                .clipped()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.08, blue: 0.30),
                             Color(red: 0.10, green: 0.15, blue: 0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)
            }

            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.75)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 6) {
                Text("DETAIL")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .tracking(2)
                Text(page.title ?? page.visuals?.title ?? page.visuals?.displayText ?? "Detail")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let desc = page.visuals?.description?.brief ?? page.visuals?.description?.medium {
                    Text(desc)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// `subscript(safe:)` is provided by the project-wide Array extension
// in ViewModels/PlayerViewModel.swift.

// MARK: - Hero banner

struct DisneyHeroBanner: View {
    let item: DXItem
    let container: DXContainer
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                if let urlString = item.bestImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.black.opacity(0.4)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.05, green: 0.08, blue: 0.30),
                                 Color(red: 0.10, green: 0.15, blue: 0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 220)
                }

                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)

                VStack(alignment: .leading, spacing: 6) {
                    if let badge = item.badges?.first {
                        Text(badge.uppercased())
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color.white.opacity(0.18), in: Capsule())
                    }
                    Text(item.displayTitle ?? container.displayTitle ?? "Featured")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    if let sub = item.displaySubtitle ?? item.visuals?.description?.brief {
                        Text(sub)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                }
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Row (rail / shelf)

struct DisneyRowView: View {
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(container.displayTitle ?? "")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if let target = container.browseTarget ?? container.target {
                    Button {
                        onOpenAll(target, container.displayTitle)
                    } label: {
                        Text("See all")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            if items.isEmpty && repo.loadingSets.contains(container.id) {
                HStack { ProgressView().tint(.white); Spacer() }
                    .padding(.horizontal, 16)
            } else if items.isEmpty, let err = repo.setErrors[container.id] {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.horizontal, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(items) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                DisneyTile(item: item, style: container.style)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .task {
            guard !didRequestLoad else { return }
            didRequestLoad = true
            if (container.items?.isEmpty ?? true) && repo.setById[container.id] == nil {
                await repo.loadSet(container)
            }
        }
    }
}

// MARK: - Tile

struct DisneyTile: View {
    let item: DXItem
    let style: String?

    private var aspect: CGFloat {
        if let s = style?.lowercased() {
            if s.contains("poster") { return 2.0 / 3.0 }
            if s.contains("logo") { return 1.0 }
            if s.contains("portrait") { return 2.0 / 3.0 }
        }
        return 16.0 / 9.0
    }

    private var width: CGFloat { aspect < 1 ? 110 : 168 }
    private var height: CGFloat { width / aspect }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                if let urlString = item.bestImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.white.opacity(0.06)
                    }
                    .frame(width: width, height: height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: width, height: height)
                        .overlay(
                            Text(item.displayTitle ?? "")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(6)
                        )
                }
                if item.isLive {
                    Text("LIVE")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.red, in: Capsule())
                        .padding(6)
                } else if item.isUpcoming {
                    Text("UPCOMING")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.white.opacity(0.18), in: Capsule())
                        .padding(6)
                }
            }
            if let title = item.displayTitle {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(width: width, alignment: .leading)
            }
        }
    }
}
