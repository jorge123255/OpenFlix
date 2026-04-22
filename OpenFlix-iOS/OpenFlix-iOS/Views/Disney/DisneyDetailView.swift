import SwiftUI

// MARK: - Disney Detail
//
// Used for any non-list Disney leaf — series detail, brand pages,
// VOD asset detail, etc. Resolution order:
//   1. item.browseTarget.pageId / setId / refId
//   2. item.target.pageId / setId / refId
//   3. item.deeplinkId via /disney/explore/deeplink → page
// For VOD-shaped items, also pulls /playerExperience/:mediaId for
// diagnostic capability badges (codecs, audio renditions). Does NOT
// build a playback URL from this — that remains server-owned.

struct DisneyDetailView: View {
    let item: DXItem
    let container: DXContainer?
    @ObservedObject var repo: DisneyExploreRepository
    /// Called for ESPN-shaped event items that the renderer detects as
    /// playable. The hosting screen routes this to `ESPNPlayerView`.
    let onPlayEvent: (DXItem, DXContainer?, String?) -> Void

    @State private var page: DXPage?
    @State private var experience: DXPlayerExperience?
    @State private var loadError: String?
    @State private var pushedSubPage: DisneyHomePushedPage?
    @State private var pushedDetail: DisneyHomePushedDetail?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let experience {
                    capabilityChips(experience)
                }

                if item.isPlayable {
                    Button {
                        onPlayEvent(item, container, nil)
                    } label: {
                        Label("Watch", systemImage: "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color(red: 0.95, green: 0.18, blue: 0.18), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                    if item.supportsStartover {
                        Button {
                            onPlayEvent(item, container, "startover")
                        } label: {
                            Label("Start Over", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(.white)
                                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)
                    }
                }

                if let page {
                    DisneyPageRenderer(
                        page: page,
                        repo: repo,
                        onOpenDetail: { item, container in
                            pushedDetail = DisneyHomePushedDetail(item: item, container: container)
                        },
                        onPlayEvent: { item, container in
                            onPlayEvent(item, container, nil)
                        },
                        onOpenPage: { target, label in
                            pushedSubPage = DisneyHomePushedPage(target: target, label: label)
                        }
                    )
                } else if loadError == nil {
                    ProgressView().tint(.white).frame(maxWidth: .infinity).padding(.top, 24)
                }

                if let loadError {
                    Text(loadError)
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 60)
        }
        .background(Color(red: 8/255, green: 12/255, blue: 28/255).ignoresSafeArea())
        .navigationTitle(item.displayTitle ?? "")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
        .navigationDestination(item: $pushedSubPage) { p in
            DisneySubPageView(target: p.target, title: p.label, repo: repo, onPlayEvent: { _, _ in })
        }
        .navigationDestination(item: $pushedDetail) { d in
            DisneyDetailView(item: d.item, container: d.container, repo: repo, onPlayEvent: onPlayEvent)
        }
    }

    // MARK: Header / capability

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let urlString = item.bestImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.white.opacity(0.05)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 16)
            }
            Text(item.displayTitle ?? "")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
            if let sub = item.displaySubtitle {
                Text(sub)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 16)
            }
            if let desc = item.visuals?.description?.medium ?? item.visuals?.description?.brief ?? item.description {
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 16)
            }
        }
    }

    private func capabilityChips(_ exp: DXPlayerExperience) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if let codecs = exp.videoCodecs, !codecs.isEmpty {
                    capabilityChip(codecs.joined(separator: " · "))
                }
                if let codecs = exp.audioCodecs, !codecs.isEmpty {
                    capabilityChip(codecs.joined(separator: " · "))
                }
                if let captions = exp.captions, !captions.isEmpty {
                    capabilityChip("CC \(captions.count)")
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func capabilityChip(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.white.opacity(0.08), in: Capsule())
    }

    // MARK: Load

    private func load() async {
        do {
            // 1. Resolve the navigation target (pageId / setId / refId).
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

            // 2. If the item has a deeplinkId and we still have no page,
            //    resolve it via the deeplink endpoint.
            if page == nil, let deeplinkId = item.deeplinkId, !deeplinkId.isEmpty {
                let action = try await repo.resolveDeeplink(refId: deeplinkId, refIdType: "deeplinkId")
                if let pageId = action?.pageId, !pageId.isEmpty {
                    page = try await repo.loadPage(pageId: pageId)
                }
            }

            // 3. For VOD-style items with a mediaId in the playback context,
            //    fetch player experience for capability chips. Diagnostic
            //    only — never used to build a playback URL.
            if let availId = item.playback?.availId, !availId.isEmpty {
                if let exp = try? await repo.loadPlayerExperience(mediaId: availId) {
                    experience = exp
                }
            }
        } catch {
            loadError = error.localizedDescription
        }
    }
}
