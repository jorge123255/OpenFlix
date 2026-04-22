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
        // LazyVStack so rows materialize as they scroll into view —
        // a Disney page has 30+ rails and an eager VStack instantiates
        // every shelf's items / AsyncImages at mount.
        LazyVStack(alignment: .leading, spacing: 36) {
            if page.isDetailPage {
                TVDisneyDetailPageHero(page: page).padding(.horizontal, 56)
            } else if let hero = heroContainer {
                TVDisneyHeroBanner(container: hero, repo: repo) { item in
                    handleTap(item: item, container: hero)
                }
                .padding(.horizontal, 56)
            }
            ForEach(rowContainers) { container in
                if container.styleName.lowercased().contains("episodic"),
                   let seasons = container.seasons, !seasons.isEmpty {
                    TVDisneySeasonsView(container: container, seasons: seasons)
                } else {
                    TVDisneyRailView(
                        container: container,
                        repo: repo,
                        onSelect: { item in handleTap(item: item, container: container) },
                        onOpenAll: { target, label in onOpenPage(target, label) }
                    )
                }
            }
        }
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
            onPlayEvent(item, container); return
        }
        if let bt = item.browseTarget, hasNav(bt) {
            onOpenPage(bt, item.displayTitle); return
        }
        if let t = item.target, hasNav(t) {
            onOpenPage(t, item.displayTitle); return
        }
        if let action = item.primaryAction, let target = targetFromAction(action, label: item.displayTitle) {
            onOpenPage(target, item.displayTitle); return
        }
        onOpenDetail(item, container)
    }

    private func hasNav(_ target: DXTarget) -> Bool {
        (target.pageId?.isEmpty == false) ||
        (target.setId?.isEmpty == false) ||
        (target.entityId?.isEmpty == false)
    }

    private func targetFromAction(_ action: DXItemAction, label: String?) -> DXTarget? {
        let pageId = action.pageId, setId = action.setId, entityId = action.entityId, deeplinkId = action.deeplinkId
        guard pageId != nil || setId != nil || entityId != nil || deeplinkId != nil else { return nil }
        return DXTarget(
            type: action.type, scope: nil, id: nil,
            setId: setId, pageId: pageId,
            entityId: entityId, entityType: action.entityType,
            layoutId: nil, pageResolutionId: nil, setResolutionId: nil,
            pageStyle: nil, setStyle: nil,
            skipEligibilityCheck: nil, limit: nil, offset: nil,
            label: label,
            refId: deeplinkId, refIdType: deeplinkId == nil ? nil : "deeplinkId"
        )
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
                if let badge = item.firstBadge {
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
    @State private var unsupportedAction: String?

    private var heroTitle: String {
        page.visuals?.title ?? page.title ?? page.visuals?.displayText ?? "Detail"
    }
    private var chips: [String] { page.detailMetaChips }
    private var playActions: [DXPageAction] { page.primaryPlaybackActions }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let urlString = page.pageHeroArtworkURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.black.opacity(0.4)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 540)
                .clipped()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.08, blue: 0.30),
                             Color(red: 0.10, green: 0.15, blue: 0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 540)
            }
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.92)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 540)

            VStack(alignment: .leading, spacing: 14) {
                Text(heroTitle)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let feat = page.visuals?.featuredTitle, !feat.isEmpty {
                    Text(feat)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                if !chips.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                            Text(chip)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.white.opacity(0.10), in: Capsule())
                        }
                    }
                }
                if let desc = page.bestDescription {
                    Text(desc)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(3)
                        .frame(maxWidth: 760, alignment: .leading)
                }
                if !playActions.isEmpty {
                    HStack(spacing: 16) {
                        ForEach(playActions) { action in
                            let label = action.options?.first?.displayText ?? "PLAY"
                            let isPrimary = playActions.first?.id == action.id
                            Button {
                                unsupportedAction = label
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: action.options?.first?.type == "resume" ? "play.fill" : "play.circle.fill")
                                        .font(.system(size: 22, weight: .bold))
                                    Text(label)
                                        .font(.system(size: 20, weight: .bold))
                                }
                                .foregroundStyle(isPrimary ? .black : .white)
                                .padding(.horizontal, 28).padding(.vertical, 14)
                                .background(Capsule().fill(isPrimary ? Color.white : Color.white.opacity(0.16)))
                            }
                            .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 999))
                        }
                        if let trailer = page.trailerAction {
                            Button {
                                unsupportedAction = trailer.options?.first?.displayText ?? "TRAILER"
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "film")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Trailer")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.horizontal, 22).padding(.vertical, 12)
                                .background(Capsule().strokeBorder(Color.white.opacity(0.2)))
                            }
                            .buttonStyle(OFFocusableButtonStyle(cornerRadius: 999))
                        }
                    }
                    .focusSection()
                }
            }
            .padding(40)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .alert("Playback not yet supported", isPresented: Binding(
            get: { unsupportedAction != nil },
            set: { if !$0 { unsupportedAction = nil } }
        )) {
            Button("OK") { unsupportedAction = nil }
        } message: {
            Text("Disney VOD playback (\(unsupportedAction ?? "")) needs a server-side `/disney/play/stream` endpoint. Linear ESPN and ESPN events still work.")
        }
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
                                TVDisneyTile(item: item, style: container.styleName)
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
        .onAppear {
            // onAppear (not .task) so the load survives row
            // virtualization on scroll — see DisneyRowView for the
            // same rationale.
            guard !didRequestLoad else { return }
            didRequestLoad = true
            if (container.items?.isEmpty ?? true) && repo.setById[container.id] == nil {
                Task { await repo.loadSet(container) }
            }
        }
    }

    private var tileCornerRadius: CGFloat {
        let style = container.styleName.lowercased()
        if style.contains("logo") { return 999 }
        return 12
    }
}

// MARK: - Tile

struct TVDisneyTile: View {
    let item: DXItem
    let style: String
    @Environment(\.isFocused) private var isFocused

    private var aspect: CGFloat {
        let s = style.lowercased()
        if s.contains("poster") || s.contains("portrait") { return 2.0 / 3.0 }
        if s.contains("logo") { return 1.0 }
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
        let s = style.lowercased()
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

// MARK: - Seasons (detail-page episodes container, focus-aware)

struct TVDisneySeasonsView: View {
    let container: DXContainer
    let seasons: [DXSeason]
    @State private var selectedSeasonId: String?
    @State private var unsupportedTitle: String?

    private var selectedSeason: DXSeason? {
        if let id = selectedSeasonId, let s = seasons.first(where: { $0.id == id }) { return s }
        return seasons.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text(container.displayTitle ?? "Episodes")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if let count = selectedSeason?.episodeCountLabel {
                    Text(count)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .padding(.horizontal, 56)

            if seasons.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(seasons) { s in
                            Button {
                                selectedSeasonId = s.id
                            } label: {
                                Text(s.displayTitle)
                                    .font(.system(size: 18, weight: .bold))
                                    .padding(.horizontal, 22).padding(.vertical, 12)
                                    .foregroundStyle((selectedSeason?.id == s.id) ? .white : .white.opacity(0.7))
                                    .background(
                                        Capsule()
                                            .fill((selectedSeason?.id == s.id) ? Color.white.opacity(0.2) : Color.white.opacity(0.07))
                                    )
                            }
                            .buttonStyle(OFFocusableButtonStyle(cornerRadius: 999))
                        }
                    }
                    .padding(.horizontal, 56)
                }
                .focusSection()
            }

            if let season = selectedSeason {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 18) {
                        ForEach(season.items ?? []) { ep in
                            Button {
                                unsupportedTitle = ep.visuals?.fullEpisodeTitle ?? ep.visuals?.title ?? "Episode"
                            } label: {
                                TVDisneyEpisodeCard(episode: ep)
                            }
                            .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 56)
                    .padding(.vertical, 12)
                }
                .focusSection()
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

private struct TVDisneyEpisodeCard: View {
    let episode: DXItem
    @Environment(\.isFocused) private var isFocused

    private var runtimeLabel: String? {
        guard let ms = episode.visuals?.durationMs?.value, ms > 0 else { return nil }
        let minutes = (ms + 30_000) / 60_000
        return "\(minutes) min"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                if let urlString = episode.bestImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.white.opacity(0.06)
                    }
                    .frame(width: 320, height: 180)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 320, height: 180)
                }
                if let n = episode.visuals?.episodeNumber?.value {
                    Text("EP \(n)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.black.opacity(0.65), in: Capsule())
                        .padding(10)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.visuals?.episodeTitle ?? episode.visuals?.fullEpisodeTitle ?? episode.displayTitle ?? "Episode")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isFocused ? .white : .white.opacity(0.9))
                    .lineLimit(2)
                    .frame(width: 320, alignment: .leading)
                if let runtimeLabel {
                    Text(runtimeLabel)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }
}
#endif
