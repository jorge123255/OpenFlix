#if os(tvOS)
import SwiftUI

// MARK: - TVDisneyDetailView
//
// Apple TV detail screen for Disney items. Resolves the navigation
// target (browseTarget → target → deeplink) into either a sub-page
// (rendered through TVDisneyPageRenderer) or a leaf detail with a
// hero, capability chips (from playerExperience), and Watch / Start
// Over actions if the item is a playable event.

struct TVDisneyDetailView: View {
    let item: DXItem
    let container: DXContainer?
    @ObservedObject var repo: DisneyExploreRepository

    @State private var page: DXPage?
    @State private var experience: DXPlayerExperience?
    @State private var loadError: String?
    @State private var pushedSubPage: TVDisneyPushedPage?
    @State private var pushedDetail: TVDisneyPushedDetail?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hero
                if let experience { capabilityChips(experience) }
                actionRow
                if let page {
                    TVDisneyPageRenderer(
                        page: page, repo: repo,
                        onOpenDetail: { i, c in pushedDetail = TVDisneyPushedDetail(item: i, container: c) },
                        onPlayEvent: { i, c in pushedDetail = TVDisneyPushedDetail(item: i, container: c) },
                        onOpenPage: { t, l in pushedSubPage = TVDisneyPushedPage(target: t, label: l) }
                    )
                } else if loadError == nil {
                    ProgressView().tint(.white).frame(maxWidth: .infinity).padding(.top, 24)
                }
                if let loadError {
                    Text(loadError).foregroundStyle(.red.opacity(0.8)).padding(.horizontal, 56)
                }
            }
            .padding(.bottom, 80)
        }
        .background(Color(red: 8/255, green: 12/255, blue: 28/255).ignoresSafeArea())
        .task { await load() }
        .navigationDestination(item: $pushedSubPage) { p in
            TVDisneySubPageView(target: p.target, title: p.label, repo: repo)
        }
        .navigationDestination(item: $pushedDetail) { d in
            TVDisneyDetailView(item: d.item, container: d.container, repo: repo)
        }
    }

    // MARK: Sections

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            if let urlString = item.bestImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.white.opacity(0.05)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 480)
                .clipped()
            } else {
                LinearGradient(
                    colors: [Color.black.opacity(0.5), Color.black],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 480)
            }
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 480)

            VStack(alignment: .leading, spacing: 10) {
                Text(item.displayTitle ?? "")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                if let sub = item.displaySubtitle {
                    Text(sub)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                if let desc = item.visuals?.description?.medium ?? item.visuals?.description?.brief ?? item.description {
                    Text(desc)
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(3)
                }
            }
            .padding(40)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 56)
        .padding(.top, 30)
    }

    private var actionRow: some View {
        HStack(spacing: 16) {
            if item.isPlayable {
                actionButton("Watch", icon: "play.fill") {
                    // TVDisneyDetailView is launched from places that don't
                    // present a player; for now, route Watch on a Disney VOD
                    // to the same path we use for ESPN events. If you want
                    // a Disney-specific player, plug it here later.
                }
                .disabled(true)
                .opacity(0.6)
                if item.supportsStartover {
                    actionButton("Start Over", icon: "arrow.counterclockwise") {}
                        .disabled(true)
                        .opacity(0.6)
                }
            }
        }
        .padding(.horizontal, 56)
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 18, weight: .bold))
                Text(title).font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22).padding(.vertical, 12)
            .background(Color(red: 0.95, green: 0.18, blue: 0.18), in: Capsule())
        }
        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 999))
    }

    private func capabilityChips(_ exp: DXPlayerExperience) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let v = exp.videoCodecs, !v.isEmpty {
                    chip(v.joined(separator: " · "))
                }
                if let a = exp.audioCodecs, !a.isEmpty {
                    chip(a.joined(separator: " · "))
                }
                if let cc = exp.captions, !cc.isEmpty {
                    chip("CC \(cc.count)")
                }
            }
            .padding(.horizontal, 56)
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color.white.opacity(0.08), in: Capsule())
    }

    // MARK: Load

    private func load() async {
        do {
            let target = item.browseTarget ?? item.target
            if let target {
                if let pageId = target.pageId, !pageId.isEmpty {
                    page = try await repo.loadPage(pageId: pageId, target: target)
                } else if let setId = target.setId, !setId.isEmpty {
                    if let container = try await repo.loadSetFromTarget(target) {
                        page = DXPage(id: setId, pageId: setId, title: nil, style: nil, pageStyle: nil,
                                      containers: [container], visuals: nil)
                    }
                }
            }
            if page == nil, let deeplinkId = item.deeplinkId, !deeplinkId.isEmpty {
                let action = try await repo.resolveDeeplink(refId: deeplinkId, refIdType: "deeplinkId")
                if let pageId = action?.pageId, !pageId.isEmpty {
                    page = try await repo.loadPage(pageId: pageId)
                }
            }
            if let availId = item.playback?.availId, !availId.isEmpty {
                experience = try? await repo.loadPlayerExperience(mediaId: availId)
            }
        } catch {
            loadError = error.localizedDescription
        }
    }
}
#endif
