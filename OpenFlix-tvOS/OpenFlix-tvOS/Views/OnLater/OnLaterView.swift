import SwiftUI

// MARK: - On Later View
/// Browse upcoming programs across all channels.
/// Set reminders and see what's coming up in the next 24-48 hours.

struct OnLaterView: View {
    @StateObject private var viewModel = OnLaterViewModel()
    @State private var selectedTimeRange: TimeRange = .next2Hours
    @FocusState private var focusedProgram: String?
    
    enum TimeRange: String, CaseIterable {
        case next2Hours = "Next 2 Hours"
        case tonight = "Tonight"
        case tomorrow = "Tomorrow"
        case thisWeek = "This Week"
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0a1628"), Color(hex: "0d0d0d")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Time range selector
                timeRangeSelector
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.upcomingPrograms.isEmpty {
                    emptyView
                } else {
                    programsGrid
                }
            }
        }
        .onAppear {
            viewModel.loadUpcomingPrograms()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("On Later")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("See what's coming up")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Clock icon
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "3B82F6"), Color(hex: "60A5FA")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.horizontal, 48)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }
    
    // MARK: - Time Range Selector
    
    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    TimeRangePill(
                        title: range.rawValue,
                        isSelected: selectedTimeRange == range,
                        action: { selectedTimeRange = range }
                    )
                }
            }
            .padding(.horizontal, 48)
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Programs Grid
    
    private var programsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 320, maximum: 400), spacing: 24)
                ],
                spacing: 24
            ) {
                ForEach(filteredPrograms) { program in
                    OnLaterProgramCard(
                        program: program,
                        onTap: { viewModel.selectProgram(program) },
                        onReminder: { viewModel.toggleReminder(for: program) }
                    )
                    .focused($focusedProgram, equals: program.id)
                }
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 48)
        }
    }
    
    private var filteredPrograms: [UpcomingProgram] {
        viewModel.programs(for: selectedTimeRange)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "3B82F6"))
            
            Text("Loading upcoming programs...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Upcoming Programs")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Check back later for upcoming content")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Time Range Pill

struct TimeRangePill: View {
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
                        .fill(isSelected ? Color(hex: "3B82F6") : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - On Later Program Card

struct OnLaterProgramCard: View {
    let program: UpcomingProgram
    let onTap: () -> Void
    let onReminder: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Thumbnail
                AsyncImage(url: URL(string: program.thumbnailUrl ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "tv")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 140, height: 80)
                .clipped()
                .cornerRadius(8)
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    // Channel & time
                    HStack(spacing: 8) {
                        Text(program.channelName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "3B82F6"))
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(program.startTimeFormatted)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Title
                    Text(program.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Duration & category
                    HStack(spacing: 8) {
                        Text(program.durationFormatted)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let category = program.category {
                            Text("•")
                                .foregroundColor(.gray)
                            Text(category)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Reminder button
                VStack(spacing: 8) {
                    Button(action: onReminder) {
                        Image(systemName: program.hasReminder ? "bell.fill" : "bell")
                            .font(.system(size: 20))
                            .foregroundColor(program.hasReminder ? Color(hex: "F59E0B") : .gray)
                    }
                    .buttonStyle(.plain)
                    
                    if program.hasReminder {
                        Text("Reminder")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "F59E0B"))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isFocused ? 0.15 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color(hex: "3B82F6") : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

// MARK: - Models

struct UpcomingProgram: Identifiable {
    let id: String
    let title: String
    let description: String?
    let thumbnailUrl: String?
    let startTime: Date
    let endTime: Date
    let channelId: String
    let channelName: String
    let category: String?
    var hasReminder: Bool = false
    
    var startTimeFormatted: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(startTime) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "E h:mm a"
        }
        return formatter.string(from: startTime)
    }
    
    var durationFormatted: String {
        let duration = Int(endTime.timeIntervalSince(startTime) / 60)
        if duration >= 60 {
            return "\(duration / 60)h \(duration % 60)m"
        }
        return "\(duration) min"
    }
}

// MARK: - ViewModel

@MainActor
class OnLaterViewModel: ObservableObject {
    @Published var upcomingPrograms: [UpcomingProgram] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadUpcomingPrograms() {
        isLoading = true
        Task {
            // TODO: Fetch from API
            try? await Task.sleep(nanoseconds: 500_000_000)
            isLoading = false
        }
    }
    
    func programs(for range: OnLaterView.TimeRange) -> [UpcomingProgram] {
        let now = Date()
        let calendar = Calendar.current
        
        return upcomingPrograms.filter { program in
            switch range {
            case .next2Hours:
                let twoHoursLater = calendar.date(byAdding: .hour, value: 2, to: now)!
                return program.startTime >= now && program.startTime <= twoHoursLater
            case .tonight:
                let tonight = calendar.startOfDay(for: now)
                let midnight = calendar.date(byAdding: .day, value: 1, to: tonight)!
                let evening = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
                return program.startTime >= evening && program.startTime < midnight
            case .tomorrow:
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
                let dayAfter = calendar.date(byAdding: .day, value: 1, to: tomorrow)!
                return program.startTime >= tomorrow && program.startTime < dayAfter
            case .thisWeek:
                let weekLater = calendar.date(byAdding: .day, value: 7, to: now)!
                return program.startTime >= now && program.startTime <= weekLater
            }
        }
    }
    
    func selectProgram(_ program: UpcomingProgram) {
        // TODO: Show detail or tune to channel
        print("Selected: \(program.title)")
    }
    
    func toggleReminder(for program: UpcomingProgram) {
        if let index = upcomingPrograms.firstIndex(where: { $0.id == program.id }) {
            upcomingPrograms[index].hasReminder.toggle()
        }
    }
}

#Preview {
    OnLaterView()
}
