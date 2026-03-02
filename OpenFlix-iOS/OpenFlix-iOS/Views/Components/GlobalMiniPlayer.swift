import SwiftUI
import AVKit

// MARK: - Global Mini Player
// Persistent mini player overlay that appears when minimizing live TV

struct GlobalMiniPlayer: View {
    @ObservedObject var manager: MiniPlayerManager
    @State private var showFullPlayer = false
    
    var body: some View {
        Group {
            if manager.isShowing, let channel = manager.currentChannel {
                VStack {
                    Spacer()
                    
                    MiniPlayerView(
                        channel: channel,
                        program: manager.currentProgram,
                        isPlaying: manager.isPlaying,
                        onTap: {
                            showFullPlayer = true
                        },
                        onClose: {
                            manager.hide()
                        },
                        onPlayPause: {
                            manager.togglePlayPause()
                        },
                        onChannelUp: {
                            // TODO: Channel navigation
                        },
                        onChannelDown: {
                            // TODO: Channel navigation
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 90) // Above tab bar
            }
        }
        .animation(.spring(response: 0.3), value: manager.isShowing)
        .fullScreenCover(isPresented: $showFullPlayer) {
            if let channel = manager.currentChannel, let url = manager.streamURL {
                AdaptiveLivePlayerView(
                    channel: channel,
                    program: manager.currentProgram,
                    streamURL: url,
                    channels: [],
                    onChannelChange: { _ in },
                    onClose: {
                        showFullPlayer = false
                    }
                )
            }
        }
    }
}

// MARK: - Mini Player Modifier
// Add to root view to enable global mini player

struct MiniPlayerModifier: ViewModifier {
    @ObservedObject var manager = MiniPlayerManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            GlobalMiniPlayer(manager: manager)
        }
    }
}

extension View {
    func withMiniPlayer() -> some View {
        modifier(MiniPlayerModifier())
    }
}

// MARK: - AirPlay Route Picker
// Native AirPlay button for casting

struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = .white
        routePickerView.activeTintColor = UIColor(Color(hex: "6138f5"))
        routePickerView.prioritizesVideoDevices = true
        return routePickerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - PiP Button
// Picture-in-Picture toggle button

struct PiPButton: View {
    let isPiPActive: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            Image(systemName: isPiPActive ? "pip.exit" : "pip.enter")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .padding(12)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Text("Main Content")
                .foregroundColor(.white)
        }
        
        GlobalMiniPlayer(manager: {
            let manager = MiniPlayerManager.shared
            manager.isShowing = true
            manager.currentChannel = Channel(
                id: "1",
                channelId: nil,
                number: 2,
                name: "CBS",
                logo: nil,
                sourceId: nil,
                sourceName: nil,
                streamUrl: nil,
                enabled: true,
                isFavorite: false,
                group: "Local",
                archiveEnabled: false,
                archiveDays: 0
            )
            return manager
        }())
    }
}
