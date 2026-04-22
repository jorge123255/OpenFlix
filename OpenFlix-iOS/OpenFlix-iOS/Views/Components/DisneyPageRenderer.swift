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
        // LazyVStack so SwiftUI only materializes rows as they scroll
        // into view. With 30+ Disney rails, an eager VStack would
        // instantiate every AsyncImage at mount time and the iPhone
        // process gets killed for memory pressure.
        LazyVStack(alignment: .leading, spacing: 24) {
            if page.isDetailPage {
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
                if isEpisodicStyle(container.styleName), let seasons = container.seasons, !seasons.isEmpty {
                    DisneySeasonsView(container: container, seasons: seasons)
                } else {
                    DisneyRowView(
                        container: container,
                        repo: repo,
                        onSelect: { item in handleTap(item: item, container: container) },
                        onOpenAll: { target, label in onOpenPage(target, label) }
                    )
                }
            }
        }
    }

    private func isEpisodicStyle(_ name: String) -> Bool {
        name.lowercased().contains("episodic")
    }

    private var heroContainer: DXContainer? {
        page.containers?.first(where: { isHeroStyle($0.styleName) })
    }

    private var rowContainers: [DXContainer] {
        guard let containers = page.containers else { return [] }
        guard let hero = heroContainer else { return containers }
        return containers.filter { $0.id != hero.id }
    }

    private func isHeroStyle(_ name: String) -> Bool {
        let s = name.lowercased()
        return s.hasPrefix("hero_") || s.hasPrefix("brand_") || s == "immersive"
    }

    private func handleTap(item: DXItem, container: DXContainer?) {
        if item.isPlayable {
            onPlayEvent(item, container)
            return
        }
        if let bt = item.browseTarget, hasPageOrSetId(bt) {
            onOpenPage(bt, item.displayTitle); return
        }
        if let t = item.target, hasPageOrSetId(t) {
            onOpenPage(t, item.displayTitle); return
        }
        if let action = item.primaryAction, let target = targetFromAction(action, label: item.displayTitle) {
            onOpenPage(target, item.displayTitle); return
        }
        onOpenDetail(item, container)
    }

    private func hasPageOrSetId(_ target: DXTarget) -> Bool {
        (target.pageId?.isEmpty == false) ||
        (target.setId?.isEmpty == false) ||
        (target.entityId?.isEmpty == false)
    }

    private func targetFromAction(_ action: DXItemAction, label: String?) -> DXTarget? {
        let pageId = action.pageId
        let setId = action.setId
        let entityId = action.entityId
        let deeplinkId = action.deeplinkId
        guard pageId != nil || setId != nil || entityId != nil || deeplinkId != nil else { return nil }
        return DXTarget(
            type: action.type, scope: nil, id: nil,
            setId: setId, pageId: pageId,
            entityId: entityId, entityType: action.entityType,
            layoutId: nil, pageResolutionId: nil, setResolutionId: nil,
            pageStyle: nil, setStyle: nil,
            skipEligibilityCheck: nil, limit: nil, offset: nil,
            label: label,
            refId: deeplinkId,
            refIdType: deeplinkId == nil ? nil : "deeplinkId"
        )
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
                    if let badge = item.firstBadge {
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
                    LazyHStack(spacing: 10) {
                        ForEach(items) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                DisneyTile(item: item, style: container.styleName)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear {
            // Use onAppear (not .task) so the load survives the row
            // being re-virtualized by LazyVStack during scroll. The
            // unstructured Task is owned by `repo`, which lives as a
            // @StateObject on the parent view.
            guard !didRequestLoad else { return }
            didRequestLoad = true
            if (container.items?.isEmpty ?? true) && repo.setById[container.id] == nil {
                Task { await repo.loadSet(container) }
            }
        }
    }
}

// MARK: - Tile

struct DisneyTile: View {
    let item: DXItem
    let style: String

    private var aspect: CGFloat {
        let s = style.lowercased()
        if s.contains("poster") || s.contains("portrait") { return 2.0 / 3.0 }
        if s.contains("logo") { return 1.0 }
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

// MARK: - Seasons (detail-page episodes container)
//
// Render-only for now: season picker + episode cards. Tap on an
// episode shows a "Disney VOD playback isn't wired yet" sheet — we
// don't have a server-side /disney/play/stream endpoint.

struct DisneySeasonsView: View {
    let container: DXContainer
    let seasons: [DXSeason]
    @State private var selectedSeasonId: String?
    @State private var unsupportedTitle: String?

    private var selectedSeason: DXSeason? {
        if let id = selectedSeasonId, let s = seasons.first(where: { $0.id == id }) { return s }
        return seasons.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(container.displayTitle ?? "Episodes")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if let count = selectedSeason?.episodeCountLabel {
                    Text(count)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)

            if seasons.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(seasons) { s in
                            Button {
                                selectedSeasonId = s.id
                            } label: {
                                Text(s.displayTitle)
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .foregroundStyle((selectedSeason?.id == s.id) ? .white : .white.opacity(0.7))
                                    .background(
                                        Capsule()
                                            .fill((selectedSeason?.id == s.id) ? Color.white.opacity(0.16) : Color.white.opacity(0.06))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            if let season = selectedSeason {
                LazyVStack(spacing: 14) {
                    ForEach(season.items ?? []) { episode in
                        Button {
                            unsupportedTitle = episode.visuals?.fullEpisodeTitle ?? episode.visuals?.title ?? "Episode"
                        } label: {
                            DisneyEpisodeCard(episode: episode)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .alert("Playback not yet supported", isPresented: Binding(
            get: { unsupportedTitle != nil },
            set: { if !$0 { unsupportedTitle = nil } }
        )) {
            Button("OK") { unsupportedTitle = nil }
        } message: {
            Text("Disney VOD playback (\(unsupportedTitle ?? "")) needs a server-side `/disney/play/stream` endpoint. Linear ESPN and ESPN events still work.")
        }
    }
}

private struct DisneyEpisodeCard: View {
    let episode: DXItem

    private var episodeImageURL: URL? {
        guard let s = episode.bestImageURL else { return nil }
        return URL(string: s)
    }

    private var runtimeLabel: String? {
        guard let ms = episode.visuals?.durationMs?.value, ms > 0 else { return nil }
        let minutes = (ms + 30_000) / 60_000
        return "\(minutes) min"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                if let url = episodeImageURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.white.opacity(0.08)
                    }
                    .frame(width: 140, height: 80)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 140, height: 80)
                }
                if let n = episode.visuals?.episodeNumber?.value {
                    Text("EP \(n)")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.black.opacity(0.65), in: Capsule())
                        .padding(6)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.visuals?.episodeTitle ?? episode.visuals?.fullEpisodeTitle ?? episode.displayTitle ?? "Episode")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let runtimeLabel {
                    Text(runtimeLabel)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                if let desc = episode.visuals?.description?.brief {
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(3)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
}
