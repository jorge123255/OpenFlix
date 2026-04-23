#if os(tvOS)
import SwiftUI

struct TVMaxDetailView: View {
    let contentId: String
    let fallbackTitle: String
    @ObservedObject var repo: MaxRepository

    @State private var detail: ProviderDetailResponse?
    @State private var fallbackEntity: MXEntity?
    @State private var fallbackResponse: MXExploreResponse?
    @State private var loadError: String?
    @State private var resolveError: String?
    @State private var resolving = false
    @State private var playSession: OFProviderPlaySession?

    private var title: String {
        detail?.title ?? MXEntityMap.entityTitle(fallbackEntity)
    }
    private var description: String? {
        detail?.longDesc ?? detail?.shortDesc ?? MXEntityMap.entityDescription(fallbackEntity)
    }
    private var heroURL: URL? {
        if let s = detail?.artwork?.bestHeroURL, let u = URL(string: s) { return u }
        if let s = MXEntityMap.entityImage(fallbackEntity, in: MXEntityMap.build(fallbackResponse), immersive: true),
           let u = URL(string: s) { return u }
        return nil
    }
    private var chips: [String] {
        var c: [String] = []
        if let y = detail?.year { c.append(String(y)) }
        if let r = detail?.rating, !r.isEmpty { c.append(r) }
        if let m = detail?.runtimeMinutes, m > 0 { c.append("\(m) min") }
        for g in (detail?.genres ?? []) { c.append(g) }
        return c
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                heroSection
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
                    .padding(.horizontal, 56)
                }
                playButton
                if let desc = description {
                    Text(desc)
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 56)
                        .frame(maxWidth: 900, alignment: .leading)
                }
                if let err = loadError {
                    Text(err).font(.system(size: 12)).foregroundStyle(.red.opacity(0.8))
                        .padding(.horizontal, 56)
                }
            }
            .padding(.bottom, 80)
        }
        .background(Color(red: 12/255, green: 4/255, blue: 24/255).ignoresSafeArea())
        .task { await load() }
        .alert("Unable to play", isPresented: Binding(
            get: { resolveError != nil },
            set: { if !$0 { resolveError = nil } }
        )) {
            Button("OK") { resolveError = nil }
        } message: { Text(resolveError ?? "") }
        .fullScreenCover(item: $playSession) { session in
            OFProviderPlayerView(streamUrl: session.streamUrl,
                                 title: session.title,
                                 subtitle: session.subtitle) {
                playSession = nil
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = heroURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.white.opacity(0.06)
                }
                .frame(maxWidth: .infinity).frame(height: 540).clipped()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.06, blue: 0.30),
                             Color(red: 0.20, green: 0.10, blue: 0.45)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 540)
            }
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.92)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 540)
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white).lineLimit(2)
            }
            .padding(40)
        }
        .padding(.horizontal, 56)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var playButton: some View {
        Button { startPlay() } label: {
            HStack(spacing: 10) {
                if resolving { ProgressView().tint(.black) }
                else { Image(systemName: "play.fill").font(.system(size: 22, weight: .bold)) }
                Text("Play").font(.system(size: 20, weight: .bold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 28).padding(.vertical, 14)
            .background(Capsule().fill(Color.white))
        }
        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 999))
        .padding(.horizontal, 56)
        .disabled(resolving)
    }

    private func load() async {
        do {
            if let d = try await repo.loadDetail(contentId: contentId), d.success != false {
                detail = d
                return
            }
        } catch {}
        do {
            let env = try await repo.loadContentEnvelope(contentId: contentId)
            fallbackResponse = env
            fallbackEntity = env.data
        } catch {
            loadError = "Couldn't load detail: \(error.localizedDescription)"
        }
    }

    private func startPlay() {
        resolving = true
        Task {
            defer { resolving = false }
            do {
                let session = try await ProviderPlaybackService.shared.maxPlay(
                    contentId: contentId, quality: "1080p"
                )
                if let err = session.error, !err.isEmpty {
                    resolveError = "Unable to play: \(err)"; return
                }
                guard let stream = session.streamUrl,
                      let url = URL(string: stream) else {
                    resolveError = "Unable to play: server returned no streamUrl."; return
                }
                playSession = OFProviderPlaySession(streamUrl: url, title: title, subtitle: nil)
            } catch {
                resolveError = "Unable to play: \(error.localizedDescription)"
            }
        }
    }
}
#endif
