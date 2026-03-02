import SwiftUI
import AVKit

// MARK: - Mini Player View
// Floating mini player at bottom of screen while browsing

struct MiniPlayerView: View {
    let channel: Channel
    let program: Program?
    let isPlaying: Bool
    let onTap: () -> Void
    let onClose: () -> Void
    let onPlayPause: () -> Void
    let onChannelUp: () -> Void
    let onChannelDown: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            HStack(spacing: 12) {
                // Thumbnail / Live indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black)
                        .frame(width: 80, height: 45)
                    
                    if let logo = channel.logo, let url = URL(string: logo) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "tv.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 70, height: 40)
                    } else {
                        Image(systemName: "tv.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    // Live badge
                    VStack {
                        HStack {
                            Spacer()
                            Text("LIVE")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(2)
                        }
                        Spacer()
                    }
                    .padding(4)
                }
                .onTapGesture(perform: onTap)
                
                // Channel & Program info
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let program = program {
                        Text(program.title)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .onTapGesture(perform: onTap)
                
                Spacer()
                
                // Controls
                HStack(spacing: 16) {
                    // Channel down
                    Button(action: onChannelDown) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    // Play/Pause
                    Button(action: onPlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primary)
                    }
                    
                    // Channel up
                    Button(action: onChannelUp) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    // Close
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, y: -2)
        )
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    isDragging = false
                    if value.translation.height > 100 {
                        // Swipe down to close
                        withAnimation(.spring()) {
                            dragOffset = 300
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onClose()
                        }
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .animation(.spring(response: 0.3), value: dragOffset)
    }
}

// MARK: - Mini Player Container
// Manages mini player state across the app

class MiniPlayerManager: ObservableObject {
    static let shared = MiniPlayerManager()
    
    @Published var isShowing = false
    @Published var currentChannel: Channel?
    @Published var currentProgram: Program?
    @Published var isPlaying = true
    @Published var streamURL: URL?
    
    func show(channel: Channel, program: Program?, streamURL: URL) {
        self.currentChannel = channel
        self.currentProgram = program
        self.streamURL = streamURL
        self.isPlaying = true
        withAnimation(.spring()) {
            self.isShowing = true
        }
    }
    
    func hide() {
        withAnimation(.spring()) {
            self.isShowing = false
        }
    }
    
    func togglePlayPause() {
        isPlaying.toggle()
    }
}

#Preview {
    VStack {
        Spacer()
        MiniPlayerView(
            channel: Channel(
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
            ),
            program: Program(
                id: "p1",
                title: "CBS Mornings",
                subtitle: nil,
                description: nil,
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                duration: 60,
                icon: nil,
                art: nil,
                rating: nil,
                category: "News",
                isNew: false,
                isLive: true,
                isPremiere: false,
                isFinale: false,
                isSports: false,
                isKids: false,
                teams: nil,
                league: nil,
                hasRecording: false,
                recordingId: nil
            ),
            isPlaying: true,
            onTap: {},
            onClose: {},
            onPlayPause: {},
            onChannelUp: {},
            onChannelDown: {}
        )
    }
    .background(Color(.systemBackground))
}
