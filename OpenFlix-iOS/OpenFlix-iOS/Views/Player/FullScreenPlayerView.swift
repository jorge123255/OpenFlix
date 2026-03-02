import SwiftUI
import AVKit

// MARK: - Full Screen Player View
// Expanded player from mini player with swipe to minimize

struct FullScreenPlayerView: View {
    let channel: Channel
    let program: Program?
    let streamURL: URL
    let onMinimize: () -> Void
    let onClose: () -> Void
    
    @StateObject private var playerViewModel = PlayerViewModel()
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var dragOffset: CGFloat = 0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video player
                Color.black.ignoresSafeArea()
                
                if let player = playerViewModel.player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showControls.toggle()
                            }
                            resetControlsTimer()
                        }
                }
                
                // Controls overlay
                if showControls {
                    controlsOverlay(geometry: geometry)
                        .transition(.opacity)
                }
            }
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 150 {
                            // Swipe down to minimize
                            withAnimation(.spring()) {
                                dragOffset = geometry.size.height
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onMinimize()
                            }
                        } else {
                            withAnimation(.spring()) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .task {
            await playerViewModel.loadLiveChannel(url: streamURL)
            resetControlsTimer()
        }
        .onDisappear {
            playerViewModel.cleanup()
            controlsTimer?.invalidate()
        }
        .statusBarHidden(true)
    }
    
    // MARK: - Controls Overlay
    
    @ViewBuilder
    private func controlsOverlay(geometry: GeometryProxy) -> some View {
        VStack {
            // Top bar
            HStack {
                // Minimize button (swipe indicator)
                Button(action: onMinimize) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Channel info
                VStack(spacing: 2) {
                    Text(channel.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    if let program = program {
                        Text(program.title)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Close button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, geometry.safeAreaInsets.top + 10)
            
            Spacer()
            
            // Center play/pause
            HStack(spacing: 50) {
                // Skip back 10s
                Button(action: { playerViewModel.skipBackward() }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                
                // Play/Pause
                Button(action: { playerViewModel.togglePlayPause() }) {
                    Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                // Skip forward 10s
                Button(action: { playerViewModel.skipForward() }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Bottom bar
            HStack {
                // Channel down
                Button(action: { /* channel down */ }) {
                    VStack(spacing: 4) {
                        Image(systemName: "chevron.down")
                        Text("CH-")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(4)
                
                Spacer()
                
                // Channel up
                Button(action: { /* channel up */ }) {
                    VStack(spacing: 4) {
                        Image(systemName: "chevron.up")
                        Text("CH+")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
        }
        .background(
            LinearGradient(
                colors: [.black.opacity(0.7), .clear, .clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in
            withAnimation {
                showControls = false
            }
        }
    }
}

#Preview {
    FullScreenPlayerView(
        channel: Channel(
            id: "1", channelId: nil, number: 2, name: "CBS", logo: nil,
            sourceId: nil, sourceName: nil, streamUrl: nil,
            enabled: true, isFavorite: false, group: "Local",
            archiveEnabled: false, archiveDays: 0
        ),
        program: nil,
        streamURL: URL(string: "https://example.com/stream.m3u8")!,
        onMinimize: {},
        onClose: {}
    )
}
