import SwiftUI

// MARK: - Catchup View
/// Browse and watch archived programs from channels that support catch-up TV.
/// Allows viewing programs from the past 7 days on supported channels.

struct CatchupView: View {
    @StateObject private var viewModel = CatchupViewModel()
    @State private var selectedDayIndex = 0
    @State private var showManageChannels = false
    @State private var playbackURL: URL?
    @State private var showPlayer = false
    @FocusState private var focusedChannel: String?
    
    private let days = (0..<7).map { offset -> (String, Date) in
        let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = offset == 0 ? "'Today'" : (offset == 1 ? "'Yesterday'" : "EEEE")
        return (formatter.string(from: date), date)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "1a0a2e"), Color(hex: "0d0d0d")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Day selector
                daySelector
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.channels.isEmpty {
                    emptyView
                } else {
                    channelList
                }
            }
        }
        .onAppear {
            viewModel.loadCatchupChannels()
        }
        .sheet(isPresented: $showManageChannels) {
            ManageCatchupChannelsSheet(onDismiss: {
                showManageChannels = false
                viewModel.loadCatchupChannels()
            })
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let url = playbackURL {
                VideoPlayerView(
                    mediaItem: nil,
                    liveChannelURL: url,
                    startPosition: nil
                )
            }
        }
    }
    
    // MARK: - Header

    private var header: some View {
        #if os(tvOS)
        catchupHeroBanner
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 8)
        #else
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Catch Up TV")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(viewModel.channels.isEmpty ? "Enable catch-up to watch past programs" : "Rewatch programs from enabled channels")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Manage channels button
            HStack(spacing: 6) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                Text("Manage")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(hex: "8B5CF6").opacity(0.4))
            .overlay(
                Capsule()
                    .stroke(Color(hex: "8B5CF6").opacity(0.7), lineWidth: 1)
            )
            .clipShape(Capsule())
            .onTapGesture { showManageChannels = true }
        }
        .padding(.horizontal, 48)
        .padding(.top, 32)
        .padding(.bottom, 24)
        #endif
    }

    // MARK: - tvOS Hero Banner

    #if os(tvOS)
    private var catchupHeroBanner: some View {
        let totalPrograms = viewModel.channels.reduce(0) { $0 + $1.totalPrograms }
        let channelCount  = viewModel.channels.count

        return ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.08, blue: 0.55),
                    Color(red: 0.08, green: 0.05, blue: 0.22)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 200, weight: .light))
                .foregroundStyle(.white.opacity(0.07))
                .offset(x: 380, y: -10)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: "8B5CF6")).frame(width: 8, height: 8)
                    Text("CATCH UP")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(2)
                }
                Text("Catch Up")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                if channelCount > 0 {
                    Text("\(channelCount) channel\(channelCount == 1 ? "" : "s") · \(totalPrograms) program\(totalPrograms == 1 ? "" : "s") from the past 7 days")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                } else {
                    Text("Enable catch-up on your channels to rewatch programs")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
            .padding(28)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    #endif
    
    // MARK: - Day Selector
    
    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    DayPill(
                        title: day.0,
                        isSelected: selectedDayIndex == index,
                        action: { selectedDayIndex = index }
                    )
                }
            }
            .padding(.horizontal, 48)
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Channel List
    
    private var channelList: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                ForEach(viewModel.channels) { channel in
                    CatchupChannelRow(
                        channel: channel,
                        programs: viewModel.programs(for: channel.id, on: days[selectedDayIndex].1),
                        selectedDate: days[selectedDayIndex].1,
                        onProgramSelected: { program in
                            if let url = viewModel.getStreamURL(for: program) {
                                playbackURL = url
                                showPlayer = true
                            }
                        }
                    )
                    .focused($focusedChannel, equals: channel.id)
                }
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 48)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "8B5CF6"))
            
            Text("Loading catch-up channels...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tv.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("No Catch-Up Channels")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Enable catch-up on your channels to watch past programs")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                Text("Enable Channels")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(hex: "8B5CF6"))
            .clipShape(Capsule())
            .onTapGesture { showManageChannels = true }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Day Pill

struct DayPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: "8B5CF6") : Color.white.opacity(0.1))
                )
        }
        #if os(tvOS)
        .buttonStyle(DayPillButtonStyle(isSelected: isSelected))
        #else
        .buttonStyle(.plain)
        #endif
    }
}

#if os(tvOS)
private struct DayPillButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        Inner(configuration: configuration, isSelected: isSelected)
    }

    private struct Inner: View {
        let configuration: ButtonStyle.Configuration
        let isSelected: Bool
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .overlay(
                    Capsule()
                        .stroke(isFocused ? Color.white.opacity(0.9) : Color.clear, lineWidth: 3)
                )
                .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.08 : 1.0))
                .shadow(color: isFocused ? Color(hex: "8B5CF6").opacity(0.5) : .clear, radius: 14, y: 6)
                .animation(.easeInOut(duration: 0.18), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .contentShape(Capsule())
        }
    }
}
#endif

// MARK: - Catchup Channel Row

struct CatchupChannelRow: View {
    let channel: CatchupChannel
    let programs: [CatchupProgram]
    let selectedDate: Date
    let onProgramSelected: (CatchupProgram) -> Void

    private var archiveStartedRecently: Bool {
        guard let start = channel.archiveStart else { return false }
        return Date().timeIntervalSince(start) < 3600 // Less than 1 hour
    }

    private var archiveStartedAfterSelectedDate: Bool {
        guard let start = channel.archiveStart else { return true }
        return !Calendar.current.isDate(start, inSameDayAs: selectedDate) &&
               start > Calendar.current.startOfDay(for: selectedDate.addingTimeInterval(86400))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Channel header
            HStack(spacing: 16) {
                // Logo
                AsyncImage(url: URL(string: channel.logoUrl ?? "")) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if let number = channel.number {
                            Text(number)
                                .font(.headline)
                                .foregroundColor(Color(hex: "8B5CF6"))
                        }
                        Text(channel.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }

                    #if os(tvOS)
                    // Subtitle line — always show something meaningful
                    Group {
                        if channel.totalPrograms > 0 {
                            Text("\(channel.totalPrograms) episode\(channel.totalPrograms == 1 ? "" : "s") from the past \(channel.catchupDays) days")
                        } else if let start = channel.archiveStart {
                            let formatter = RelativeDateTimeFormatter()
                            Text("Archiving since \(formatter.localizedString(for: start, relativeTo: Date()))")
                                .foregroundColor(.orange)
                        } else {
                            Text("No recordings yet")
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    #else
                    if channel.totalPrograms > 0 {
                        Text("\(channel.totalPrograms) programs recorded")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else if let start = channel.archiveStart {
                        let formatter = RelativeDateTimeFormatter()
                        Text("Archiving since \(formatter.localizedString(for: start, relativeTo: Date()))")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    } else {
                        Text("No recordings yet")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    #endif
                }

                Spacer()

                // Catch-up badge
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("\(channel.catchupDays) days")
                }
                .font(.caption)
                .foregroundColor(Color(hex: "8B5CF6"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "8B5CF6").opacity(0.2))
                .cornerRadius(12)
            }

            // Programs row
            if programs.isEmpty {
                VStack(spacing: 6) {
                    if archiveStartedAfterSelectedDate {
                        Text("Archiving wasn't active on this day")
                            .foregroundColor(.gray)
                    } else if archiveStartedRecently {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.gray)
                            Text("Archiving just started - programs will appear as they finish airing")
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("No recorded programs for this day")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(programs) { program in
                            CatchupProgramCard(
                                program: program,
                                action: { onProgramSelected(program) }
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Catchup Program Card

struct CatchupProgramCard: View {
    let program: CatchupProgram
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: program.thumbnailUrl ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "play.tv")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 280, height: 158)
                    .clipped()

                    // Duration badge
                    Text(program.durationFormatted)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(8)

                    // Unavailable overlay
                    if !program.available {
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                        VStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 24))
                            Text("Not Available")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                }
                .cornerRadius(12)

                // Title
                Text(program.title)
                    .font(.headline)
                    .foregroundColor(program.available ? .white : .gray)
                    .lineLimit(2)

                // Time
                Text(program.timeFormatted)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(width: 280)
            .opacity(program.available ? 1.0 : 0.6)
        }
        #if os(tvOS)
        .buttonStyle(CatchupCardButtonStyle())
        #else
        .buttonStyle(.plain)
        #endif
        .disabled(!program.available)
    }
}

#if os(tvOS)
/// Focus-aware ButtonStyle for CatchupProgramCard on tvOS.
/// Inner View pattern is required so @Environment(\.isFocused) resolves
/// against the Button's real focus state and not a stale value.
private struct CatchupCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Inner(configuration: configuration)
    }

    private struct Inner: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isFocused ? Color(hex: "8B5CF6").opacity(0.95) : Color.clear, lineWidth: 3)
                )
                .scaleEffect(configuration.isPressed ? 0.97 : (isFocused ? 1.07 : 1.0))
                .shadow(color: isFocused ? Color(hex: "8B5CF6").opacity(0.38) : .clear, radius: 22, y: 10)
                .animation(.easeInOut(duration: 0.18), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
#endif

// MARK: - Models

struct CatchupChannel: Identifiable {
    let id: String
    let name: String
    let number: String?
    let logoUrl: String?
    let catchupDays: Int
    var archiveStart: Date?
    var totalPrograms: Int = 0
}

struct CatchupProgram: Identifiable {
    let id: String
    let title: String
    let description: String?
    let thumbnailUrl: String?
    let startTime: Date
    let endTime: Date
    let channelId: String
    let available: Bool
    let streamUrl: URL?

    var durationFormatted: String {
        let duration = Int(endTime.timeIntervalSince(startTime) / 60)
        return "\(duration) min"
    }

    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }
}

// MARK: - ViewModel

@MainActor
class CatchupViewModel: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published var channels: [CatchupChannel] = []
    @Published var programsByChannel: [String: [CatchupProgram]] = [:]
    @Published var isLoading = false
    @Published var error: String?

    func loadCatchupChannels() {
        isLoading = true
        error = nil
        Task {
            do {
                // Fetch all channels and filter to those with catchup/archive enabled
                let channelsResponse = try await api.getChannels()
                let archiveChannels = channelsResponse.allChannels.filter { $0.archiveEnabled == true }

                channels = archiveChannels.map { dto in
                    CatchupChannel(
                        id: dto.safeId,
                        name: dto.safeName,
                        number: dto.number.map { String($0) },
                        logoUrl: dto.logo ?? dto.thumb,
                        catchupDays: dto.archiveDays ?? 7
                    )
                }

                // Load catchup programs for each channel concurrently
                await withTaskGroup(of: (String, [CatchupProgram], Date?).self) { group in
                    for channel in channels {
                        group.addTask { [api] in
                            do {
                                let response = try await api.getCatchupPrograms(channelId: channel.id)
                                let isoFormatter = ISO8601DateFormatter()

                                // Pre-build stream URLs (requires actor context)
                                var streamUrls: [String: URL] = [:]
                                for dto in response.programs {
                                    if let urlStr = dto.streamUrl, !urlStr.isEmpty {
                                        if urlStr.hasPrefix("http") {
                                            if let url = URL(string: urlStr) { streamUrls[dto.id.stringValue] = url }
                                        } else if let url = await api.buildURL(path: urlStr) {
                                            streamUrls[dto.id.stringValue] = url
                                        }
                                    }
                                }

                                let programs = response.programs.compactMap { dto -> CatchupProgram? in
                                    guard let start = isoFormatter.date(from: dto.startTime),
                                          let end = isoFormatter.date(from: dto.endTime) else { return nil }
                                    return CatchupProgram(
                                        id: dto.id.stringValue,
                                        title: dto.title,
                                        description: dto.description,
                                        thumbnailUrl: dto.icon,
                                        startTime: start,
                                        endTime: end,
                                        channelId: channel.id,
                                        available: dto.available ?? false,
                                        streamUrl: streamUrls[dto.id.stringValue]
                                    )
                                }
                                var archiveStart: Date?
                                if let startStr = response.archiveStart {
                                    archiveStart = isoFormatter.date(from: startStr)
                                }
                                return (channel.id, programs, archiveStart)
                            } catch {
                                return (channel.id, [], nil)
                            }
                        }
                    }
                    for await (channelId, programs, archiveStart) in group {
                        programsByChannel[channelId] = programs
                        if let idx = channels.firstIndex(where: { $0.id == channelId }) {
                            channels[idx].archiveStart = archiveStart
                            channels[idx].totalPrograms = programs.count
                        }
                    }
                }
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }

    func programs(for channelId: String, on date: Date) -> [CatchupProgram] {
        return programsByChannel[channelId]?.filter { program in
            Calendar.current.isDate(program.startTime, inSameDayAs: date)
        } ?? []
    }

    func getStreamURL(for program: CatchupProgram) -> URL? {
        program.streamUrl
    }
}

// MARK: - Manage Catchup Channels Sheet

struct ManageCatchupChannelsSheet: View {
    let onDismiss: () -> Void
    @StateObject private var viewModel = ManageCatchupViewModel()
    @State private var searchText = ""

    private var filteredChannels: [ManageChannel] {
        if searchText.isEmpty { return viewModel.channels }
        return viewModel.channels.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.number?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var enabledChannels: [ManageChannel] {
        filteredChannels.filter { $0.archiveEnabled }
    }

    private var disabledChannels: [ManageChannel] {
        filteredChannels.filter { !$0.archiveEnabled }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0d0d0d").ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(hex: "8B5CF6"))
                } else {
                    List {
                        if !enabledChannels.isEmpty {
                            Section {
                                ForEach(enabledChannels) { channel in
                                    channelRow(channel)
                                }
                            } header: {
                                Text("Catch-Up Enabled (\(enabledChannels.count))")
                                    .foregroundColor(Color(hex: "8B5CF6"))
                            }
                        }

                        Section {
                            ForEach(disabledChannels) { channel in
                                channelRow(channel)
                            }
                        } header: {
                            Text("Available Channels (\(disabledChannels.count))")
                                .foregroundColor(.gray)
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search channels")
                }
            }
            .navigationTitle("Manage Catch-Up")
            #if !os(tvOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { onDismiss() }
                        .foregroundColor(Color(hex: "8B5CF6"))
                }
            }
        }
        .onAppear { viewModel.loadAllChannels() }
    }

    private func channelRow(_ channel: ManageChannel) -> some View {
        HStack(spacing: 12) {
            // Channel logo
            AsyncImage(url: URL(string: channel.logoUrl ?? "")) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .cornerRadius(6)

            // Channel info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if let number = channel.number {
                        Text(number)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }
                    Text(channel.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                if channel.archiveEnabled {
                    Text("7-day catch-up active")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
            }

            Spacer()

            // Toggle
            if viewModel.togglingIds.contains(channel.id) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Color(hex: "8B5CF6"))
            } else {
                Toggle("", isOn: Binding(
                    get: { channel.archiveEnabled },
                    set: { enabled in
                        viewModel.toggleArchive(channelId: channel.id, enable: enabled)
                    }
                ))
                .tint(Color(hex: "8B5CF6"))
                .labelsHidden()
            }
        }
        .listRowBackground(Color.white.opacity(0.05))
    }
}

// MARK: - Manage Channel Model

struct ManageChannel: Identifiable {
    let id: String
    let name: String
    let number: String?
    let logoUrl: String?
    var archiveEnabled: Bool
}

// MARK: - Manage Catchup ViewModel

@MainActor
class ManageCatchupViewModel: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published var channels: [ManageChannel] = []
    @Published var isLoading = false
    @Published var togglingIds: Set<String> = []

    func loadAllChannels() {
        isLoading = true
        Task {
            do {
                let response = try await api.getChannels()
                channels = response.allChannels
                    .sorted { ($0.number ?? 9999) < ($1.number ?? 9999) }
                    .map { dto in
                        ManageChannel(
                            id: dto.safeId,
                            name: dto.safeName,
                            number: dto.number.map { String($0) },
                            logoUrl: dto.logo ?? dto.thumb,
                            archiveEnabled: dto.archiveEnabled ?? false
                        )
                    }
            } catch {
                print("Failed to load channels: \(error)")
            }
            isLoading = false
        }
    }

    func toggleArchive(channelId: String, enable: Bool) {
        togglingIds.insert(channelId)
        Task {
            do {
                if enable {
                    try await api.enableArchive(channelId: channelId, days: 7)
                } else {
                    try await api.disableArchive(channelId: channelId)
                }
                if let index = channels.firstIndex(where: { $0.id == channelId }) {
                    channels[index].archiveEnabled = enable
                }
            } catch {
                print("Failed to toggle archive for \(channelId): \(error)")
            }
            togglingIds.remove(channelId)
        }
    }
}

// Color(hex:) extension defined in OpenFlixColors.swift

#Preview {
    CatchupView()
}
