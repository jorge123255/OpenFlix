import SwiftUI

// MARK: - Catchup View
/// Browse and watch archived programs from channels that support catch-up TV.
/// Allows viewing programs from the past 7 days on supported channels.

struct CatchupView: View {
    @StateObject private var viewModel = CatchupViewModel()
    @State private var selectedDayIndex = 0
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
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Catch Up TV")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Watch programs from the past 7 days")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Catch-up icon
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "8B5CF6"), Color(hex: "A78BFA")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.horizontal, 48)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }
    
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
                        onProgramSelected: { program in
                            viewModel.playProgram(program, from: channel)
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
            
            Text("None of your channels support catch-up TV")
                .foregroundColor(.gray)
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
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: "8B5CF6") : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Catchup Channel Row

struct CatchupChannelRow: View {
    let channel: CatchupChannel
    let programs: [CatchupProgram]
    let onProgramSelected: (CatchupProgram) -> Void
    
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
                    
                    Text("\(programs.count) programs available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Catch-up badge
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("7 days")
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
                Text("No programs available for this day")
                    .foregroundColor(.gray)
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
    @State private var isFocused = false
    
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
                }
                .cornerRadius(12)
                
                // Title
                Text(program.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Time
                Text(program.timeFormatted)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(width: 280)
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .onFocusChange { focused in
            isFocused = focused
        }
    }
}

// MARK: - Models

struct CatchupChannel: Identifiable {
    let id: String
    let name: String
    let number: String?
    let logoUrl: String?
    let catchupDays: Int
}

struct CatchupProgram: Identifiable {
    let id: String
    let title: String
    let description: String?
    let thumbnailUrl: String?
    let startTime: Date
    let endTime: Date
    let channelId: String
    
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
    @Published var channels: [CatchupChannel] = []
    @Published var programsByChannel: [String: [CatchupProgram]] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    func loadCatchupChannels() {
        isLoading = true
        // TODO: Fetch from API
        Task {
            // Simulate API call
            try? await Task.sleep(nanoseconds: 500_000_000)
            isLoading = false
        }
    }
    
    func programs(for channelId: String, on date: Date) -> [CatchupProgram] {
        return programsByChannel[channelId]?.filter { program in
            Calendar.current.isDate(program.startTime, inSameDayAs: date)
        } ?? []
    }
    
    func playProgram(_ program: CatchupProgram, from channel: CatchupChannel) {
        // TODO: Navigate to archive player
        print("Playing: \(program.title) from \(channel.name)")
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#Preview {
    CatchupView()
}
