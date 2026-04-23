#if os(tvOS)
import SwiftUI

// MARK: - TVESPNHubView
//
// Apple TV ESPN destination. Reads /api/tuner-backends/active/espn/hub
// (linearChannels + optional disneyHub). Polls every 45s while visible,
// pauses while playback is active. Layout:
//
//   ┌───────────────────────────────────────────────────────────┐
//   │ ESPN brand band (or Disney hub hero when present)         │
//   ├───────────────────────────────────────────────────────────┤
//   │ LIVE LINEAR                                               │
//   │ [ESPN] [ESPN2] [ESPNU] [ESPNews] [SEC] [ACC]              │   ← focusSection
//   ├───────────────────────────────────────────────────────────┤
//   │ Disney rails from hub.disneyHub (when hasDisneyHub)       │
//   └───────────────────────────────────────────────────────────┘

struct TVESPNHubView: View {
    @StateObject private var repo = ESPNRepository()
    @StateObject private var disneyRepo = DisneyExploreRepository()
    @State private var linearToPlay: ESPNLinearChannel?
    @State private var eventToPlay: ESPNEventPlayback?
    /// Disney "ESPN" page resolved from globalNav. Used as a fallback
    /// when hub.disneyHub is null so the rails still surface.
    @State private var disneyESPNPage: DXPage?

    private var renderableDisneyPage: DXPage? {
        if let p = repo.browsePage { return p }
        if let h = repo.hub?.disneyHub { return h }
        return disneyESPNPage
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                heroBand

                if let hub = repo.hub {
                    if let channels = hub.linearChannels, !channels.isEmpty {
                        TVLinearChannelRail(channels: channels) { channel in
                            linearToPlay = channel
                        }
                    }

                    if let disneyHub = renderableDisneyPage {
                        TVDisneyPageRenderer(
                            page: disneyHub,
                            repo: disneyRepo,
                            onOpenDetail: { _, _ in },
                            onPlayEvent: { item, container in
                                eventToPlay = ESPNEventPlayback(item: item, container: container, mode: nil)
                            },
                            onOpenPage: { _, _ in }
                        )
                    } else if hub.hasDisneyHub != true {
                        emptyDisneyState
                    }
                } else if repo.isLoadingHub {
                    ProgressView().tint(.white).padding(.top, 80)
                } else if let error = repo.error {
                    errorView(error)
                }
            }
            .padding(.bottom, 80)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 6/255, green: 4/255, blue: 16/255),
                         Color(red: 14/255, green: 8/255, blue: 28/255)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .task {
            disneyRepo.namespace = .espn
            await repo.loadHub()
            await repo.loadBrowsePage()
            repo.startPolling()
            if repo.browsePage == nil && repo.hub?.disneyHub == nil && disneyESPNPage == nil {
                disneyESPNPage = try? await disneyRepo.loadESPNPageFromGlobalNav()
            }
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
    }

    // MARK: Hero band

    @ViewBuilder
    private var heroBand: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.05, blue: 0.05),
                         Color(red: 0.30, green: 0.0, blue: 0.0)],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 240)

            Text("ESPN")
                .font(.system(size: 220, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.06))
                .offset(x: 540, y: -10)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle().fill(Color.white).frame(width: 10, height: 10)
                    Text("LIVE")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(2.5)
                }
                Text("ESPN")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                if let count = repo.hub?.linearChannels?.count, count > 0 {
                    Text("\(count) linear channels • \(repo.hub?.hasDisneyHub == true ? "ESPN+ events available" : "ESPN+ unavailable")")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(40)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 56)
        .padding(.top, 40)
    }

    private var emptyDisneyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tv.slash")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.4))
            Text("ESPN+ events unavailable")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
            Text("Live linear channels are above. ESPN+ events appear here when the upstream is connected.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 80)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func errorView(_ raw: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48)).foregroundStyle(.orange)
            Text("ESPN unavailable")
                .font(.system(size: 22, weight: .heavy)).foregroundStyle(.white)
            Text(raw)
                .font(.system(size: 14)).foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center).padding(.horizontal, 60)
            Button("Retry") { Task { await repo.loadHub(force: true) } }
                .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 999))
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity).padding(.top, 80)
    }
}

// MARK: - Linear rail

private struct TVLinearChannelRail: View {
    let channels: [ESPNLinearChannel]
    let onSelect: (ESPNLinearChannel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Circle().fill(Color.red).frame(width: 10, height: 10)
                Text("LIVE LINEAR")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
                    .tracking(2)
            }
            .padding(.horizontal, 56)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 18) {
                    ForEach(channels) { channel in
                        Button { onSelect(channel) } label: {
                            TVLinearChannelTile(channel: channel)
                        }
                        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 56)
                .padding(.vertical, 12)
            }
        }
        .focusSection()
    }
}

private struct TVLinearChannelTile: View {
    let channel: ESPNLinearChannel
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.05, blue: 0.05),
                             Color(red: 0.45, green: 0.0, blue: 0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text(channel.key ?? channel.name)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 1, y: 1)
            }
            .frame(width: 280, height: 158)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(channel.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isFocused ? .white : .white.opacity(0.85))
                .lineLimit(1)
                .frame(width: 280)
            if let n = channel.number {
                Text("CH \(n)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}
#endif
