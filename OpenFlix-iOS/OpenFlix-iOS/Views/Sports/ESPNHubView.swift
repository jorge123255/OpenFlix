import SwiftUI

// MARK: - ESPN Hub
//
// Top-level ESPN browse screen. Polls `/espn/browse` every 45s to keep
// live/upcoming state fresh. Tapping a tile uses `browseTarget` (or
// `target` as fallback) to push another browse screen, OR the event
// detail when the item is playable.

/// Shared "ESPN entry tile" label used inside the iPhone Sports/Team Pass
/// view and the tvOS Sports view. Lives here so both call sites get the
/// same look + share the focus-aware button style applied at the
/// NavigationLink call site.
struct ESPNTileLabel: View {
    let logoSize: CGSize

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.05, blue: 0.05), Color(red: 0.45, green: 0.0, blue: 0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text("ESPN")
                    .font(.system(size: logoSize.width >= 100 ? 28 : 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
            }
            .frame(width: logoSize.width, height: logoSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text("ESPN")
                    .font(.system(size: logoSize.width >= 100 ? 22 : 17, weight: .bold))
                    .foregroundStyle(.white)
                Text("Live games, studio shows, and 30 for 30")
                    .font(.system(size: logoSize.width >= 100 ? 14 : 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        // Liquid Glass tile on iOS 26 (translucent, picks up backdrop);
        // soft white-on-dark fallback on iOS 17–18 + tvOS.
        #if os(iOS)
        .openFlixGlass(
            in: RoundedRectangle(cornerRadius: 14, style: .continuous),
            tint: Color(red: 0.95, green: 0.05, blue: 0.05).opacity(0.18)
        )
        #else
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 14)
        )
        #endif
    }
}

/// Focus-aware ButtonStyle used across OpenFlix surfaces (Home, Sports,
/// ESPN, DVR, etc. — NOT the Live TV guide cells, which have their own
/// dense layout). Replaces tvOS' bright white halo with a soft accent
/// ring + scale. Pass `cornerRadius` to match the wrapped content's clip
/// shape so the focus border traces the actual edge.
struct OFFocusableButtonStyle: ButtonStyle {
    /// Larger scale + glow for cinematic surfaces (hero / detail buttons).
    var prominent: Bool = false
    /// Must match the wrapped content's `.clipShape` corner radius —
    /// otherwise the focus ring traces a different shape than the button
    /// edge and looks misaligned. Default 12 matches the standard cards.
    var cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        Inner(prominent: prominent, cornerRadius: cornerRadius, isPressed: configuration.isPressed) {
            configuration.label
        }
    }

    private struct Inner<Label: View>: View {
        let prominent: Bool
        let cornerRadius: CGFloat
        let isPressed: Bool
        @ViewBuilder let label: () -> Label
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            label()
                .scaleEffect(scale)
                .opacity(isPressed ? 0.75 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            isFocused ? Color(red: 0.95, green: 0.18, blue: 0.18) : Color.clear,
                            lineWidth: prominent ? 4 : 3
                        )
                )
                .shadow(
                    color: isFocused ? Color(red: 0.95, green: 0.18, blue: 0.18).opacity(0.35) : .clear,
                    radius: prominent ? 18 : 10,
                    y: 4
                )
                .animation(.easeOut(duration: 0.15), value: isFocused)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }

        private var scale: CGFloat {
            #if os(tvOS)
            if prominent { return isFocused ? 1.06 : 1.0 }
            return isFocused ? 1.04 : 1.0
            #else
            return isPressed ? 0.97 : 1.0
            #endif
        }
    }
}

/// Back-compat alias — earlier code referenced `ESPNFocusableButtonStyle`.
/// Use `OFFocusableButtonStyle` directly in new code.
typealias ESPNFocusableButtonStyle = OFFocusableButtonStyle

/// Static-factory shorthand so callsites can write
/// `.buttonStyle(.openFlix(cornerRadius: 14))` instead of the longer form.
extension ButtonStyle where Self == OFFocusableButtonStyle {
    static var openFlix: OFFocusableButtonStyle {
        OFFocusableButtonStyle()
    }
    static func openFlix(cornerRadius: CGFloat, prominent: Bool = false) -> OFFocusableButtonStyle {
        OFFocusableButtonStyle(prominent: prominent, cornerRadius: cornerRadius)
    }
}

/// Halo-suppressor — same as `.plain` but kills the system focus halo.
/// Use this on tvOS buttons whose label already supplies its own
/// `@Environment(\.isFocused)`-driven scale/shadow (Home cards, etc.) so
/// the harsh white system glow doesn't stack on top of the custom polish.
struct OFNoHaloButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == OFNoHaloButtonStyle {
    /// `.buttonStyle(.openFlixNoHalo)` — drop in for `.plain` on tvOS
    /// callsites that already have custom focus indication.
    static var openFlixNoHalo: OFNoHaloButtonStyle { OFNoHaloButtonStyle() }
}

// MARK: - ESPN Hub
//
// Top-level ESPN screen for the Sports tab. Renders the always-present
// linear channel strip from `/api/tuner-backends/active/espn/hub` first,
// then — when `hasDisneyHub` is true — the embedded Disney-shaped hub
// page through the shared DisneyPageRenderer. Polls the hub every 45s
// while visible; pauses while playback is active.

struct ESPNHubView: View {
    @StateObject private var repo = ESPNRepository()
    @StateObject private var disneyRepo = DisneyExploreRepository()
    @State private var linearToPlay: ESPNLinearChannel?
    @State private var eventToPlay: ESPNEventPlayback?
    @State private var pushedPage: ESPNPushedPage?
    @State private var pushedDetail: ESPNPushedDetail?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let hub = repo.hub {
                    if let channels = hub.linearChannels, !channels.isEmpty {
                        LinearChannelStrip(channels: channels) { channel in
                            linearToPlay = channel
                        }
                    }

                    if hub.hasDisneyHub == true, let disneyHub = hub.disneyHub {
                        DisneyPageRenderer(
                            page: disneyHub,
                            repo: disneyRepo,
                            onOpenDetail: { item, container in
                                pushedDetail = ESPNPushedDetail(item: item, container: container)
                            },
                            onPlayEvent: { item, container in
                                eventToPlay = ESPNEventPlayback(item: item, container: container, mode: nil)
                            },
                            onOpenPage: { target, label in
                                pushedPage = ESPNPushedPage(target: target, label: label)
                            }
                        )
                    } else if hub.hasDisneyHub != true {
                        emptyDisneyState
                    }
                } else if repo.isLoadingHub {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                } else if let error = repo.error {
                    errorView(error)
                }
            }
            .padding(.bottom, 60)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 6/255, green: 4/255, blue: 16/255),
                    Color(red: 14/255, green: 8/255, blue: 28/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("ESPN")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await repo.loadHub()
            repo.startPolling()
        }
        .onDisappear { repo.stopPolling() }
        .fullScreenCover(item: $linearToPlay) { channel in
            ESPNPlayerView(linear: channel, repo: repo) { linearToPlay = nil }
        }
        .fullScreenCover(item: $eventToPlay) { ctx in
            ESPNPlayerView(event: ctx.item, container: ctx.container, repo: repo, initialMode: ctx.mode) {
                eventToPlay = nil
            }
        }
        .navigationDestination(item: $pushedPage) { page in
            DisneySubPageView(target: page.target, title: page.label, repo: disneyRepo,
                              onPlayEvent: { item, container in
                                  eventToPlay = ESPNEventPlayback(item: item, container: container, mode: nil)
                              })
        }
        .navigationDestination(item: $pushedDetail) { detail in
            DisneyDetailView(item: detail.item, container: detail.container, repo: disneyRepo,
                             onPlayEvent: { item, container, mode in
                                 eventToPlay = ESPNEventPlayback(item: item, container: container, mode: mode)
                             })
        }
    }

    private var emptyDisneyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tv.slash")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.4))
            Text("ESPN+ unavailable")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
            Text("Live linear channels are available above. ESPN+ events will appear here when the upstream is connected.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func errorView(_ raw: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("ESPN unavailable")
                .font(.headline)
                .foregroundStyle(.white)
            Text(raw)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Button("Retry") {
                Task { await repo.loadHub(force: true) }
            }
            .buttonStyle(OFFocusableButtonStyle(cornerRadius: 999))
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Linear strip

private struct LinearChannelStrip: View {
    let channels: [ESPNLinearChannel]
    let onSelect: (ESPNLinearChannel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(Color.red).frame(width: 8, height: 8)
                Text("LIVE LINEAR")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
                    .tracking(1.5)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(channels) { channel in
                        Button {
                            onSelect(channel)
                        } label: {
                            LinearChannelTile(channel: channel)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

private struct LinearChannelTile: View {
    let channel: ESPNLinearChannel

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.05, blue: 0.05),
                             Color(red: 0.45, green: 0.0, blue: 0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text(channel.key ?? channel.name)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 1, y: 1)
            }
            .frame(width: 130, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(channel.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .frame(width: 130)
        }
    }
}

// MARK: - Identifiable presentation wrappers

struct ESPNEventPlayback: Identifiable {
    let item: DXItem
    let container: DXContainer?
    let mode: String?
    var id: String { (item.id) + ":" + (mode ?? "live") }
}

struct ESPNPushedPage: Hashable, Identifiable {
    let target: DXTarget
    let label: String?
    var id: String { (target.pageId ?? target.setId ?? target.entityId ?? "?") + (label ?? "") }
    static func == (lhs: ESPNPushedPage, rhs: ESPNPushedPage) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ESPNPushedDetail: Hashable, Identifiable {
    let item: DXItem
    let container: DXContainer?
    var id: String { item.id + ":" + (container?.id ?? "no-container") }
    static func == (lhs: ESPNPushedDetail, rhs: ESPNPushedDetail) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Sub-page (used by both ESPN-embedded Disney and Library Disney+)

struct DisneySubPageView: View {
    let target: DXTarget
    let title: String?
    @ObservedObject var repo: DisneyExploreRepository
    let onPlayEvent: (DXItem, DXContainer?) -> Void

    @State private var page: DXPage?
    @State private var loadError: String?
    @State private var pushedDetail: ESPNPushedDetail?
    @State private var pushedPage: ESPNPushedPage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let page {
                    DisneyPageRenderer(
                        page: page,
                        repo: repo,
                        onOpenDetail: { item, container in
                            pushedDetail = ESPNPushedDetail(item: item, container: container)
                        },
                        onPlayEvent: onPlayEvent,
                        onOpenPage: { target, label in
                            pushedPage = ESPNPushedPage(target: target, label: label)
                        }
                    )
                } else if let loadError {
                    Text(loadError).foregroundStyle(.red).padding()
                } else {
                    ProgressView().tint(.white).padding(.top, 60)
                }
            }
            .padding(.bottom, 60)
        }
        .background(Color(red: 6/255, green: 4/255, blue: 16/255).ignoresSafeArea())
        .navigationTitle(title ?? page?.title ?? "")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
        .navigationDestination(item: $pushedPage) { page in
            DisneySubPageView(target: page.target, title: page.label, repo: repo, onPlayEvent: onPlayEvent)
        }
        .navigationDestination(item: $pushedDetail) { detail in
            DisneyDetailView(item: detail.item, container: detail.container, repo: repo,
                             onPlayEvent: { item, container, _ in
                                 onPlayEvent(item, container)
                             })
        }
    }

    private func load() async {
        do {
            if let pageId = target.pageId, !pageId.isEmpty {
                page = try await repo.loadPage(pageId: pageId, target: target)
            } else if let setId = target.setId, !setId.isEmpty {
                if let container = try await repo.loadSetFromTarget(target) {
                    page = DXPage(
                        id: setId, pageId: setId, title: title, style: nil, pageStyle: nil,
                        containers: [container], visuals: nil
                    )
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
