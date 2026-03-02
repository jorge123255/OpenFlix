import SwiftUI
import AVKit

/// Transform DVR stream URL to HLS proxy URL for iOS compatibility.
/// The proxy host/port are configured via server settings, not hardcoded.
func transformToHLSProxy(_ url: URL, proxyHost: String, proxyPort: Int) -> URL {
    let path = url.path
    if path.hasPrefix("/stream/") {
        let channelId = String(path.dropFirst("/stream/".count))
        let hlsUrlString = "http://\(proxyHost):\(proxyPort)/hls/\(channelId)/index.m3u8"
        if let hlsUrl = URL(string: hlsUrlString) {
            return hlsUrl
        }
    }
    return url
}

// MARK: - Adaptive Live TV View
// Clean YouTube TV-inspired design

struct AdaptiveLiveTVView: View {
    @StateObject private var viewModel = LiveTVViewModel()
    
    // Player state
    @State private var currentChannel: Channel?
    @State private var currentProgram: Program?
    @State private var streamURL: URL?
    @State private var showFullPlayer = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.channels.isEmpty {
                    LoadingView(message: "Loading channels...")
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.loadChannels() }
                    }
                } else if viewModel.channels.isEmpty {
                    EmptyStateView(
                        icon: "play.tv",
                        title: "No Channels",
                        message: "Add M3U or Xtream sources in Settings."
                    )
                } else {
                    channelListView
                }
            }
            .navigationTitle("Live")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search channels")
        }
        .fullScreenCover(isPresented: $showFullPlayer) {
            if let channel = currentChannel, let url = streamURL {
                AdaptiveLivePlayerView(
                    channel: channel,
                    program: currentProgram,
                    streamURL: url,
                    channels: filteredChannels,
                    onChannelChange: { newChannel in
                        playChannel(newChannel)
                    },
                    onClose: {
                        showFullPlayer = false
                    }
                )
            } else {
                // Fallback - shouldn't happen but prevents black screen
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading...")
                        .foregroundColor(.white)
                        .padding(.top)
                    Button("Close") {
                        showFullPlayer = false
                    }
                    .foregroundColor(.red)
                    .padding(.top, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
        .task {
            await viewModel.loadChannels()
            await viewModel.loadGuide()
        }
    }
    
    // MARK: - Filtered Channels
    
    private var filteredChannels: [Channel] {
        let channels = viewModel.channels
        if searchText.isEmpty {
            return channels
        }
        return channels.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.displayNumber.contains(searchText)
        }
    }
    
    // MARK: - Channel List View (YouTube TV Style)
    
    private var channelListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Category pills at top
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        CategoryPill(title: "All", isSelected: viewModel.selectedGroup == nil) {
                            viewModel.selectedGroup = nil
                        }
                        CategoryPill(title: "Favorites", isSelected: viewModel.selectedGroup == "favorites") {
                            viewModel.selectedGroup = "favorites"
                        }
                        ForEach(viewModel.availableGroups, id: \.self) { group in
                            CategoryPill(title: group, isSelected: viewModel.selectedGroup == group) {
                                viewModel.selectedGroup = group
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                // Channel list
                ForEach(filteredChannels) { channel in
                    YouTubeTVChannelRow(
                        channel: channel,
                        currentProgram: getCurrentProgram(for: channel)
                    ) {
                        playChannel(channel)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadChannels()
            await viewModel.loadGuide()
        }
    }
    
    // MARK: - Helpers
    
    private func getCurrentProgram(for channel: Channel) -> Program? {
        // First check guide data
        if let guide = viewModel.guide.first(where: { $0.channel.id == channel.id }) {
            let now = Date()
            if let program = guide.programs.first(where: { $0.startTime <= now && $0.endTime > now }) {
                return program
            }
        }
        // Fallback to channel's nowPlaying
        return channel.nowPlaying
    }
    
    private func playChannel(_ channel: Channel) {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        print("🎯 playChannel called for: \(channel.name)")
        print("🎯 channel.streamUrl: \(channel.streamUrl ?? "nil")")
        
        currentChannel = channel
        currentProgram = getCurrentProgram(for: channel)
        
        if let streamUrl = channel.streamUrl, let url = URL(string: streamUrl) {
            // Transform DVR stream URL to HLS proxy URL for iOS compatibility
            let hlsUrl = transformToHLSProxy(url)
            print("🔄 Original URL: \(url)")
            print("🔄 Transformed HLS URL: \(hlsUrl)")
            NSLog("OPENFLIX: Playing HLS URL: %@", hlsUrl.absoluteString)
            streamURL = hlsUrl
            showFullPlayer = true
            return
        }
        
        print("⚠️ No direct streamUrl, fetching from API...")
        Task {
            do {
                let url = try await viewModel.getChannelStream(channel)
                print("✅ Got stream URL from API: \(url)")
                streamURL = url
                showFullPlayer = true
            } catch {
                print("❌ Failed to get stream: \(error)")
                viewModel.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .white : Color.white.opacity(0.15))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - YouTube TV Style Channel Row

struct YouTubeTVChannelRow: View {
    let channel: Channel
    let currentProgram: Program?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Large channel logo
                AsyncImage(url: URL(string: channel.logo ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text(String(channel.name.prefix(2)).uppercased())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Channel info
                VStack(alignment: .leading, spacing: 4) {
                    // Channel name
                    Text(channel.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Current program
                    HStack(spacing: 6) {
                        // LIVE badge
                        Text("LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(3)
                        
                        if let program = currentProgram {
                            Text(program.title)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        } else {
                            Text("Live TV")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }
                }
                
                Spacer()
                
                // Channel number (subtle)
                if !channel.displayNumber.isEmpty {
                    Text(channel.displayNumber)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.black)
        }
        .buttonStyle(HighlightButtonStyle())
    }
}

// Custom button style with highlight effect
struct HighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.white.opacity(0.1) : Color.clear)
    }
}

// MARK: - Live Player View (Full Screen)

struct AdaptiveLivePlayerView: View {
    let channel: Channel
    let program: Program?
    let streamURL: URL
    let channels: [Channel]
    let onChannelChange: (Channel) -> Void
    let onClose: () -> Void
    
    @State private var player: AVPlayer?
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var isBuffering = false  // Web view handles its own loading
    @State private var hasError = false
    @State private var errorMessage = ""
    @State private var playerObserver: Any?
    @State private var resourceLoaderDelegate: TSResourceLoaderDelegate?
    @Environment(\.dismiss) private var dismiss
    
    // Mini player integration
    @ObservedObject private var miniPlayerManager = MiniPlayerManager.shared
    
    var body: some View {
        ZStack {
            // Video player background
            Color.black.ignoresSafeArea()
            
            // Use the same PlayerViewModel approach as tvOS
            LiveTVPlayerContainer(streamURL: streamURL, channel: channel)
                .ignoresSafeArea()
            
            // Tap area for controls (covers whole screen)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls.toggle()
                    }
                    if showControls {
                        resetControlsTimer()
                    }
                }
            
            // Loading/Error indicator (always on top)
            if isBuffering || hasError {
                VStack(spacing: 16) {
                    if hasError {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Playback Error")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    } else {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Loading \(channel.name)...")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(streamURL.absoluteString)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                .padding(24)
                .frame(maxWidth: 300)
                .background(Color.black.opacity(0.85))
                .cornerRadius(16)
            }
            
            // Controls overlay (tap to show/hide, swipe down to close)
            if showControls {
                VStack {
                    // Top bar with controls
                    HStack(alignment: .top) {
                        // Close button (X)
                        Button(action: { onClose() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Channel info card
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: channel.logo ?? "")) { phase in
                                if case .success(let image) = phase {
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.3))
                                }
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(channel.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                if let program = program {
                                    Text(program.title)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        
                        Spacer()
                        
                        // Minimize button (pip icon) - shows mini player
                        Button(action: { minimizeToMiniPlayer() }) {
                            Image(systemName: "pip.enter")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Bottom controls - channel switcher
                    HStack(spacing: 50) {
                        Button(action: channelDown) {
                            VStack(spacing: 4) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("CH-")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(12)
                        }
                        
                        Button(action: channelUp) {
                            VStack(spacing: 4) {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("CH+")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.bottom, 50)
                }
                .transition(.opacity)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 80)
                .onEnded { value in
                    // Swipe down to minimize to mini player
                    if value.translation.height > 100 {
                        minimizeToMiniPlayer()
                    }
                    // Swipe up/down for channels
                    else if value.translation.height < -50 {
                        channelUp()
                    } else if value.translation.height > 50 && value.translation.height <= 100 {
                        channelDown()
                    }
                }
        )
        .onAppear {
            // Web view handles playback - just start controls timer
            resetControlsTimer()
        }
        .onDisappear {
            controlsTimer?.invalidate()
        }
        .statusBarHidden()
    }
    
    private func setupPlayer() {
        isBuffering = true
        hasError = false
        errorMessage = ""
        
        print("▶️ Setting up player for: \(streamURL)")
        NSLog("OPENFLIX: Setting up player for URL: %@", streamURL.absoluteString)
        
        let playerItem: AVPlayerItem
        
        // Check if this is an HLS URL (.m3u8) - use native AVPlayer for HLS
        if streamURL.pathExtension.lowercased() == "m3u8" || streamURL.absoluteString.contains(".m3u8") {
            print("▶️ HLS stream detected - using native AVPlayer")
            NSLog("OPENFLIX: HLS stream - using native AVPlayer")
            
            // For HLS, just use the URL directly - AVPlayer handles it natively
            let asset = AVURLAsset(url: streamURL)
            playerItem = AVPlayerItem(asset: asset)
        } else {
            print("▶️ Non-HLS stream - using custom resource loader")
            NSLog("OPENFLIX: Non-HLS stream - using custom handler")
            
            // For raw MPEG-TS, use custom scheme to intercept and add MIME type
            var components = URLComponents(url: streamURL, resolvingAgainstBaseURL: false)!
            let originalScheme = components.scheme
            components.scheme = "mpegts"
            
            guard let customURL = components.url else {
                hasError = true
                errorMessage = "Failed to create custom URL"
                return
            }
            
            print("▶️ Using custom URL: \(customURL)")
            
            let asset = AVURLAsset(url: customURL)
            let resourceLoader = TSResourceLoaderDelegate(originalScheme: originalScheme ?? "http")
            asset.resourceLoader.setDelegate(resourceLoader, queue: .main)
            self.resourceLoaderDelegate = resourceLoader  // Keep strong reference
            
            playerItem = AVPlayerItem(asset: asset)
        }
        
        playerItem.preferredForwardBufferDuration = 5
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = false
        player = newPlayer
        
        // Observe player item status
        playerObserver = playerItem.observe(\.status, options: [.new, .initial]) { item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    print("🎬 Player ready - starting playback")
                    isBuffering = false
                    hasError = false
                case .failed:
                    let errorDesc = item.error?.localizedDescription ?? "Unknown error"
                    print("❌ Player failed: \(errorDesc)")
                    isBuffering = false
                    hasError = true
                    errorMessage = errorDesc
                case .unknown:
                    print("⏳ Player status unknown - waiting...")
                @unknown default:
                    break
                }
            }
        }
        
        // Observe for playback errors
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { notification in
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                print("❌ Playback error: \(error.localizedDescription)")
                hasError = true
                errorMessage = error.localizedDescription
            }
        }
        
        // Observe for new error log entries
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewErrorLogEntry,
            object: playerItem,
            queue: .main
        ) { _ in
            if let log = playerItem.errorLog()?.events.last {
                print("⚠️ Error log: \(log.errorComment ?? "no comment") - \(log.errorDomain) \(log.errorStatusCode)")
            }
        }
        
        // Observe timeControlStatus for buffering
        newPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { _ in
            if newPlayer.timeControlStatus == .playing {
                isBuffering = false
                hasError = false
            } else if newPlayer.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                isBuffering = true
                if let reason = newPlayer.reasonForWaitingToPlay {
                    print("⏳ Buffering reason: \(reason.rawValue)")
                }
            }
        }
        
        print("▶️ Calling play()")
        newPlayer.play()
        
        // Timeout - if still loading after 15 seconds, show error
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak newPlayer] in
            if isBuffering && !hasError {
                // Check the actual error
                if let error = playerItem.error {
                    errorMessage = error.localizedDescription
                } else if let errorLog = playerItem.errorLog()?.events.last {
                    errorMessage = "Error \(errorLog.errorStatusCode): \(errorLog.errorComment ?? "Unknown")"
                } else if newPlayer?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                    if let reason = newPlayer?.reasonForWaitingToPlay {
                        errorMessage = "Waiting: \(reason.rawValue)"
                    } else {
                        errorMessage = "Stream not responding (timeout)"
                    }
                } else {
                    errorMessage = "Connection timeout - stream may not be available"
                }
                hasError = true
                isBuffering = false
            }
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        if showControls {
            controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls = false
                }
            }
        }
    }
    
    private func channelUp() {
        guard let currentIndex = channels.firstIndex(where: { $0.id == channel.id }) else { return }
        let nextIndex = (currentIndex + 1) % channels.count
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onChannelChange(channels[nextIndex])
    }
    
    private func channelDown() {
        guard let currentIndex = channels.firstIndex(where: { $0.id == channel.id }) else { return }
        let prevIndex = currentIndex > 0 ? currentIndex - 1 : channels.count - 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onChannelChange(channels[prevIndex])
    }
    
    private func minimizeToMiniPlayer() {
        // Show mini player with current channel
        miniPlayerManager.show(channel: channel, program: program, streamURL: streamURL)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onClose()
    }
}

// MARK: - Live TV Player Container (uses PlayerViewModel like tvOS)

struct LiveTVPlayerContainer: View {
    let streamURL: URL
    let channel: Channel
    @StateObject private var playerViewModel = PlayerViewModel()
    
    var body: some View {
        ZStack {
            Color.black
            
            if let player = playerViewModel.player {
                AVPlayerControllerView(player: player)
            }
            
            if playerViewModel.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading \(channel.name)...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }
            
            if let error = playerViewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("Playback Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .task {
            await playerViewModel.loadLiveChannel(url: streamURL)
        }
        .onDisappear {
            playerViewModel.cleanup()
        }
    }
}

// MARK: - Web Player View (HLS.js for MPEG-TS support)

import WebKit

struct TSWebPlayerView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        
        // Load HTML with HLS.js player
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
            <style>
                * { margin: 0; padding: 0; }
                body { background: #000; overflow: hidden; }
                video { 
                    width: 100vw; 
                    height: 100vh; 
                    object-fit: contain;
                    background: #000;
                }
                .error { 
                    color: #f90; 
                    font-family: -apple-system, sans-serif;
                    text-align: center;
                    padding: 20px;
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                }
            </style>
        </head>
        <body>
            <video id="video" autoplay playsinline></video>
            <div id="error" class="error" style="display:none;"></div>
            <script>
                const video = document.getElementById('video');
                const errorDiv = document.getElementById('error');
                const streamUrl = '\(url.absoluteString)';
                
                console.log('Loading stream:', streamUrl);
                
                if (Hls.isSupported()) {
                    const hls = new Hls({
                        enableWorker: true,
                        lowLatencyMode: true,
                        backBufferLength: 30
                    });
                    
                    hls.loadSource(streamUrl);
                    hls.attachMedia(video);
                    
                    hls.on(Hls.Events.MANIFEST_PARSED, () => {
                        console.log('Manifest parsed, starting playback');
                        video.play().catch(e => console.error('Play error:', e));
                    });
                    
                    hls.on(Hls.Events.ERROR, (event, data) => {
                        console.error('HLS Error:', data.type, data.details);
                        if (data.fatal) {
                            errorDiv.textContent = 'Stream error: ' + data.details;
                            errorDiv.style.display = 'block';
                            if (data.type === Hls.ErrorTypes.NETWORK_ERROR) {
                                console.log('Attempting recovery...');
                                hls.startLoad();
                            }
                        }
                    });
                } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
                    // Native HLS support (Safari)
                    video.src = streamUrl;
                    video.play().catch(e => console.error('Play error:', e));
                } else {
                    errorDiv.textContent = 'HLS not supported';
                    errorDiv.style.display = 'block';
                }
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // URL changes handled by parent recreating the view
    }
}

// MARK: - MPEG-TS Resource Loader Delegate

class TSResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    let originalScheme: String
    private var pendingRequests: [AVAssetResourceLoadingRequest] = []
    private var dataTask: URLSessionDataTask?
    private var response: URLResponse?
    private var data = Data()
    
    init(originalScheme: String) {
        self.originalScheme = originalScheme
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, 
                       shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let url = loadingRequest.request.url else {
            print("❌ No URL in loading request")
            return false
        }
        
        // Convert back to original scheme
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.scheme = originalScheme
        
        guard let originalURL = components.url else {
            print("❌ Failed to restore original URL")
            return false
        }
        
        print("🔄 Resource loader intercepted: \(originalURL)")
        
        // Create request with proper headers
        var request = URLRequest(url: originalURL)
        request.setValue("video/mp2t, video/mpeg, */*", forHTTPHeaderField: "Accept")
        request.setValue("OpenFlix-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        pendingRequests.append(loadingRequest)
        
        // Start streaming data
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
        dataTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Stream error: \(error.localizedDescription)")
                loadingRequest.finishLoading(with: error)
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse else {
                print("❌ No data or invalid response")
                loadingRequest.finishLoading(with: NSError(domain: "TSLoader", code: -1))
                return
            }
            
            print("✅ Got \(data.count) bytes, status: \(response.statusCode)")
            
            // Fill in content information
            if let contentInfo = loadingRequest.contentInformationRequest {
                contentInfo.contentType = "public.mpeg-2-transport-stream"
                contentInfo.isByteRangeAccessSupported = false
                contentInfo.contentLength = -1  // Unknown for live streams
            }
            
            // Provide data
            if let dataRequest = loadingRequest.dataRequest {
                dataRequest.respond(with: data)
            }
            
            loadingRequest.finishLoading()
        }
        dataTask?.resume()
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, 
                       didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        print("🛑 Loading request cancelled")
        dataTask?.cancel()
        pendingRequests.removeAll { $0 == loadingRequest }
    }
}

// MARK: - AVPlayerController View (UIKit wrapper for better TS support)

struct AVPlayerControllerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false  // We show our own
        controller.videoGravity = .resizeAspect
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

#Preview {
    AdaptiveLiveTVView()
}
