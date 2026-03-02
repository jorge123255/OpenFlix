import SwiftUI
import AVKit

@main
struct OpenFlixApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(settingsViewModel)
                    .preferredColorScheme(.dark)

                if showSplash {
                    VideoSplashView {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}

// MARK: - Video Splash Screen

struct VideoSplashView: View {
    let onFinished: () -> Void

    @State private var player: AVPlayer?
    @State private var overlayOpacity: Double = 1.0
    @State private var finished = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .disabled(true) // disable AVKit controls — we handle tap ourselves
            }

            // Tap anywhere to skip
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !finished else { return }
                    finish()
                }

            // Skip hint
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("Tap to skip")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20)
                        .padding(.trailing, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear { setupPlayer() }
        .onDisappear { player?.pause() }
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "splash_video", withExtension: "mp4") else {
            // Video not found — skip straight to app
            onFinished()
            return
        }

        // Configure audio session to play with sound
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)

        let avPlayer = AVPlayer(url: url)
        avPlayer.isMuted = false
        self.player = avPlayer
        avPlayer.play()

        // Listen for video end
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in
            finish()
        }

        // Safety fallback — always dismiss after 12s
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
            finish()
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        player?.pause()
        onFinished()
    }
}
