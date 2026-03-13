import SwiftUI

// MARK: - Channel Surfing View (tvOS)
// D-pad left/right to navigate channels. Menu to exit.

struct ChannelSurfingView: View {
    @StateObject private var viewModel = ChannelSurfingViewModel()
    @State private var showPlayer = false
    @Environment(\.dismiss) var dismiss

    private let bgColor = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let accentPurple = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Loading channels...").foregroundColor(.gray)
                }
            } else if viewModel.channels.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tv.slash").font(.system(size: 64)).foregroundColor(.gray)
                    Text("No Channels").font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                }
            } else {
                mainContent
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

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 40) {
            // Header
            HStack {
                Text("Channel Surfing")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.currentIndex + 1) / \(viewModel.channels.count)")
                    .font(.system(size: 22).monospacedDigit())
                    .foregroundColor(.secondary)

                Button {
                    viewModel.toggleFavoritesFilter()
                } label: {
                    Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.showFavoritesOnly ? .yellow : .secondary)
                }
                .buttonStyle(.card)

                Button {
                    viewModel.toggleAutoSurf()
                } label: {
                    Image(systemName: viewModel.isAutoSurfing ? "pause.circle.fill" : "play.circle")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.isAutoSurfing ? accentPurple : .secondary)
                }
                .buttonStyle(.card)
            }
            .padding(.horizontal, 80)
            .padding(.top, 40)

            Spacer()

            // Channel card
            channelCard
                .frame(maxWidth: 900)
                .onMoveCommand { direction in
                    switch direction {
                    case .left: viewModel.previousChannel()
                    case .right: viewModel.nextChannel()
                    default: break
                    }
                }

            Spacer()

            // Nav hint
            HStack(spacing: 40) {
                Image(systemName: "arrow.left.circle")
                    .font(.system(size: 28))
                    .foregroundColor(.gray)
                Text("D-pad left/right to browse • Select to watch")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 28))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Channel Card

    private var channelCard: some View {
        VStack(spacing: 24) {
            if let channel = viewModel.currentChannel {
                // Channel Identity
                HStack(spacing: 16) {
                    if let logo = channel.logo, !logo.isEmpty {
                        AuthenticatedImage(path: logo, systemPlaceholder: "tv")
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "tv")
                            .font(.title)
                            .foregroundColor(.secondary)
                            .frame(width: 72, height: 72)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        if let number = channel.number {
                            Text("CH \(number)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(accentPurple)
                        }
                        Text(channel.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if let group = channel.group {
                            Text(group)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if channel.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                    }
                }

                Divider().background(Color.white.opacity(0.2))

                // Now Playing
                if let program = channel.nowPlaying {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("NOW PLAYING")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(accentPurple)

                        Text(program.title)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        if let subtitle = program.subtitle {
                            Text(subtitle)
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.15)).frame(height: 6)
                                Capsule().fill(accentPurple).frame(width: geo.size.width * program.progress, height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text(program.timeRangeFormatted)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Spacer()
                            if program.remainingMinutes > 0 {
                                Text("\(program.remainingMinutes) min left")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    Text("No program info available")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Up Next
                if let nextProgram = channel.nextProgram {
                    Divider().background(Color.white.opacity(0.1))
                    HStack {
                        Text("UP NEXT")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(nextProgram.title)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                        Spacer()
                        Text(nextProgram.startTimeFormatted)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }

                // Watch button
                Button {
                    showPlayer = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                        Text("Watch")
                    }
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(accentPurple)
                    .cornerRadius(12)
                }
                .buttonStyle(.card)
                .padding(.top, 8)
            }
        }
        .padding(32)
        .background(cardBg)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
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
        } catch { }
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
        if currentIndex >= channels.count { currentIndex = 0 }
    }

    func toggleAutoSurf() {
        isAutoSurfing.toggle()
        if isAutoSurfing { startAutoSurf() } else { stopAutoSurf() }
    }

    private func startAutoSurf() {
        autoSurfTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.nextChannel() }
        }
    }

    private func stopAutoSurf() {
        autoSurfTimer?.invalidate()
        autoSurfTimer = nil
    }

    deinit { autoSurfTimer?.invalidate() }
}
