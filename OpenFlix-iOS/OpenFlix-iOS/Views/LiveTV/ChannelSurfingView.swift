import SwiftUI

// MARK: - Channel Surfing View

struct ChannelSurfingView: View {
    @StateObject private var viewModel = ChannelSurfingViewModel()
    @State private var showPlayer = false
    @State private var dragOffset: CGFloat = 0
    @Environment(\.dismiss) var dismiss

    private let bgColor = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let accentPurple = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else if viewModel.channels.isEmpty {
                ContentUnavailableView("No Channels", systemImage: "tv.slash", description: Text("No channels available."))
                    .foregroundColor(.white)
            } else {
                VStack(spacing: 0) {
                    // Header
                    headerBar

                    Spacer()

                    // Channel Card
                    channelCard
                        .offset(x: dragOffset)
                        .gesture(swipeGesture)

                    Spacer()

                    // Controls
                    controlBar
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Channel Surfing")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .task {
            await viewModel.loadChannels()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let channel = viewModel.currentChannel {
                LiveChannelPlayerView(
                    channel: channel,
                    viewModel: LiveTVViewModel(),
                    channels: viewModel.channels,
                    onDismiss: { showPlayer = false }
                )
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            // Channel counter
            Text("\(viewModel.currentIndex + 1) / \(viewModel.channels.count)")
                .font(.subheadline.monospacedDigit())
                .foregroundColor(.secondary)

            Spacer()

            // Favorites filter
            Button {
                viewModel.toggleFavoritesFilter()
            } label: {
                Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                    .foregroundColor(viewModel.showFavoritesOnly ? .yellow : .secondary)
            }

            // Auto-surf toggle
            Button {
                viewModel.toggleAutoSurf()
            } label: {
                Image(systemName: viewModel.isAutoSurfing ? "pause.circle.fill" : "play.circle")
                    .font(.title3)
                    .foregroundColor(viewModel.isAutoSurfing ? accentPurple : .secondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Channel Card

    private var channelCard: some View {
        VStack(spacing: 16) {
            if let channel = viewModel.currentChannel {
                // Channel Identity
                HStack(spacing: 12) {
                    if let logo = channel.logo, !logo.isEmpty {
                        AuthenticatedImage(path: logo, systemPlaceholder: "tv")
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: "tv")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        if let number = channel.number {
                            Text("CH \(number)")
                                .font(.caption.bold())
                                .foregroundColor(accentPurple)
                        }
                        Text(channel.name)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if let group = channel.group {
                            Text(group)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if channel.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }

                Divider().background(Color.white.opacity(0.2))

                // Now Playing
                if let program = channel.nowPlaying {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOW PLAYING")
                            .font(.caption2.bold())
                            .foregroundColor(accentPurple)

                        Text(program.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)

                        if let subtitle = program.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 4)

                                Capsule()
                                    .fill(accentPurple)
                                    .frame(width: geo.size.width * program.progress, height: 4)
                            }
                        }
                        .frame(height: 4)

                        HStack {
                            Text(program.timeRangeFormatted)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            if program.remainingMinutes > 0 {
                                Text("\(program.remainingMinutes) min left")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Badges
                        if !program.badges.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(program.badges, id: \.self) { badge in
                                    Text(badge)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(accentPurple.opacity(0.6))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                } else {
                    Text("No program info available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Up Next
                if let nextProgram = channel.nextProgram {
                    Divider().background(Color.white.opacity(0.1))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("UP NEXT")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)

                        HStack {
                            Text(nextProgram.title)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                            Spacer()
                            Text(nextProgram.startTimeFormatted)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Watch button
                Button {
                    showPlayer = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Watch")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accentPurple)
                    .cornerRadius(12)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
    }

    // MARK: - Controls

    private var controlBar: some View {
        HStack(spacing: 40) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.previousChannel()
                }
                hapticFeedback()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(accentPurple)
            }

            VStack(spacing: 2) {
                Text("Swipe or tap")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("to navigate")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.nextChannel()
                }
                hapticFeedback()
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(accentPurple)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Gestures

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                dragOffset = value.translation.width * 0.5
            }
            .onEnded { value in
                let threshold: CGFloat = 60
                withAnimation(.spring(response: 0.3)) {
                    if value.translation.width < -threshold {
                        viewModel.nextChannel()
                        hapticFeedback()
                    } else if value.translation.width > threshold {
                        viewModel.previousChannel()
                        hapticFeedback()
                    }
                    dragOffset = 0
                }
            }
    }

    private func hapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Channel Surfing ViewModel

@MainActor
class ChannelSurfingViewModel: ObservableObject {
    private let repository = LiveTVRepository()

    @Published var allChannels: [Channel] = []
    @Published var currentIndex = 0
    @Published var isLoading = false
    @Published var showFavoritesOnly = false
    @Published var isAutoSurfing = false

    private var autoSurfTimer: Timer?

    var channels: [Channel] {
        if showFavoritesOnly {
            return allChannels.filter { $0.isFavorite }
        }
        return allChannels
    }

    var currentChannel: Channel? {
        guard !channels.isEmpty, currentIndex >= 0, currentIndex < channels.count else { return nil }
        return channels[currentIndex]
    }

    func loadChannels() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.loadChannels()
            allChannels = repository.sortedChannels(by: .number).filter { $0.enabled }
        } catch {
            // Silently fail
        }
    }

    func nextChannel() {
        guard !channels.isEmpty else { return }
        currentIndex = (currentIndex + 1) % channels.count
    }

    func previousChannel() {
        guard !channels.isEmpty else { return }
        currentIndex = (currentIndex - 1 + channels.count) % channels.count
    }

    func toggleFavoritesFilter() {
        showFavoritesOnly.toggle()
        if currentIndex >= channels.count {
            currentIndex = 0
        }
    }

    func toggleAutoSurf() {
        isAutoSurfing.toggle()
        if isAutoSurfing {
            startAutoSurf()
        } else {
            stopAutoSurf()
        }
    }

    private func startAutoSurf() {
        autoSurfTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.nextChannel()
            }
        }
    }

    private func stopAutoSurf() {
        autoSurfTimer?.invalidate()
        autoSurfTimer = nil
    }

    deinit {
        autoSurfTimer?.invalidate()
    }
}
