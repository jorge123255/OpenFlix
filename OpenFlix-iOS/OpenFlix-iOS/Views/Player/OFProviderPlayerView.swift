import SwiftUI
import AVFoundation

#if !targetEnvironment(simulator) && os(iOS)
import MobileVLCKit
#elseif !targetEnvironment(simulator) && os(tvOS)
import TVVLCKit
#endif

// MARK: - Cross-provider player surface
//
// Minimal playback surface used by Disney VOD and Max VOD after a
// `/<provider>/play` session resolves. Hands `streamUrl` to VLC
// (which handles HLS / MPEG-TS / MP4 transparently). Not used for
// ESPN — that stays on ESPNPlayerView for its richer event chrome
// (Start Over, team/league metadata).

struct OFProviderPlayerView: View {
    let streamUrl: URL
    let title: String
    let subtitle: String?
    let onClose: () -> Void

    @StateObject private var vlcPlayer = VLCPlayerViewModel()
    @State private var showControls = true
    @State private var hideTask: Task<Void, Never>?

    private let accent = Color(red: 0.95, green: 0.18, blue: 0.18)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VLCPlayerView(viewModel: vlcPlayer)
                .ignoresSafeArea()

            LinearGradient(
                colors: [Color.black.opacity(0.45), .clear, .clear, Color.black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .opacity(showControls ? 1 : 0)
            .animation(.easeInOut(duration: 0.25), value: showControls)

            Color.clear
                .contentShape(Rectangle())
                .allowsHitTesting(!showControls)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) { showControls = true }
                    scheduleAutoHide()
                }

            if !vlcPlayer.hasReachedPlaying && (vlcPlayer.isLoading || vlcPlayer.isBuffering) {
                bufferingHUD
            }

            if let error = vlcPlayer.error {
                errorOverlay(error)
            }

            if showControls {
                controlsOverlay
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        #if os(iOS)
        .statusBarHidden(true)
        #endif
        .task {
            vlcPlayer.play(url: streamUrl)
            scheduleAutoHide()
        }
        .onDisappear {
            vlcPlayer.stop()
            hideTask?.cancel()
        }
        #if os(tvOS)
        .onPlayPauseCommand { vlcPlayer.togglePlayPause(); scheduleAutoHide() }
        .onExitCommand { onClose() }
        #endif
    }

    // MARK: Chrome

    private var controlsOverlay: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.5), in: Circle())
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            Spacer()
            centerTransport
            Spacer()
        }
    }

    private var centerTransport: some View {
        HStack(spacing: 36) {
            transportIcon(systemName: "gobackward.15") {
                vlcPlayer.mediaPlayer.jumpBackward(15)
            }
            transportIcon(
                systemName: vlcPlayer.isPlaying ? "pause.fill" : "play.fill",
                size: 46, primary: true
            ) {
                vlcPlayer.togglePlayPause()
            }
            transportIcon(systemName: "goforward.15") {
                vlcPlayer.mediaPlayer.jumpForward(15)
            }
        }
        #if os(tvOS)
        .focusSection()
        #endif
    }

    private func transportIcon(systemName: String, size: CGFloat = 28, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: { action(); scheduleAutoHide() }) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: primary ? 76 : 52, height: primary ? 76 : 52)
                .background(Circle().fill(primary ? accent : Color.white.opacity(0.06)))
                .shadow(color: primary ? accent.opacity(0.5) : .clear, radius: 12, y: 4)
        }
        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: primary ? 38 : 26))
    }

    private var bufferingHUD: some View {
        VStack(spacing: 12) {
            ProgressView().scaleEffect(1.3).tint(.white)
            Text("Loading stream…")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 22).padding(.vertical, 16)
        .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func errorOverlay(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40)).foregroundStyle(.orange)
            Text("Unable to play")
                .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            Text(msg)
                .font(.system(size: 13)).foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center).padding(.horizontal, 30)
            Button("Close", action: onClose)
                .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 999))
                .padding(.top, 6)
        }
    }

    private func scheduleAutoHide() {
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.25)) { showControls = false }
            }
        }
    }
}

// MARK: - Identifiable wrapper so .fullScreenCover(item:) can key off
// a single stream URL + title pair.

struct OFProviderPlaySession: Identifiable {
    let id = UUID()
    let streamUrl: URL
    let title: String
    let subtitle: String?
}
