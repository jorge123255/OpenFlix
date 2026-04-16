import SwiftUI

// MARK: - On Later View
/// Browse upcoming programs across all channels.
/// Set reminders and see what's coming up in the next 24-48 hours.

struct OnLaterView: View {
    @StateObject private var viewModel = OnLaterViewModel()
    @State private var selectedTimeRange: TimeRange = .next2Hours
    @State private var selectedCategory: OnLaterCategory = .all
    @FocusState private var focusedProgram: String?

    enum TimeRange: String, CaseIterable {
        case next2Hours = "Next 2 Hours"
        case tonight = "Tonight"
        case tomorrow = "Tomorrow"
        case thisWeek = "This Week"
    }

    enum OnLaterCategory: String, CaseIterable, Identifiable {
        case all      = "All"
        case movies   = "Movies"
        case sports   = "Sports"
        case kids     = "Kids"
        case news     = "News"
        case holiday  = "Holiday"
        case halloween = "Halloween"
        case seasonal = "Special Events"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .all:      return "square.grid.2x2"
            case .movies:   return "film"
            case .sports:   return "sportscourt"
            case .kids:     return "figure.play"
            case .news:     return "newspaper"
            case .holiday:  return "gift"
            case .halloween: return "moon.stars"
            case .seasonal: return "bolt"
            }
        }
        var endpoint: String {
            switch self {
            case .all:      return "all"
            case .movies:   return "movies"
            case .sports:   return "sports"
            case .kids:     return "kids"
            case .news:     return "news"
            case .holiday:  return "holiday"
            case .halloween: return "halloween"
            case .seasonal: return "seasonal"
            }
        }
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

                // Category selector
                categorySelector

                // Time range selector (only for non-seasonal categories)
                if selectedCategory == .all || selectedCategory == .movies ||
                   selectedCategory == .sports || selectedCategory == .kids || selectedCategory == .news {
                    timeRangeSelector
                }

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
            viewModel.loadByCategory(selectedCategory)
        }
        .onChange(of: selectedCategory) { _, newCat in
            viewModel.loadByCategory(newCat)
        }
    }

    // MARK: - tvOS Hero Banner

    #if os(tvOS)
    private var onLaterHeroBanner: some View {
        let count = viewModel.upcomingPrograms.count
        return ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.08, blue: 0.45),
                    Color(red: 0.06, green: 0.04, blue: 0.18)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 200, weight: .light))
                .foregroundStyle(.white.opacity(0.07))
                .offset(x: 380, y: -10)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(red: 139/255, green: 92/255, blue: 246/255))
                        .frame(width: 8, height: 8)
                    Text("ON LATER")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(2)
                }
                Text("On Later")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                if count > 0 {
                    Text("\(count) program\(count == 1 ? "" : "s") scheduled")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                } else {
                    Text("See what's coming up across all channels")
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

    // MARK: - Category Selector

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(OnLaterCategory.allCases) { cat in
                    Button {
                        selectedCategory = cat
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 14))
                            Text(cat.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedCategory == cat
                                ? Color(hex: "3B82F6")
                                : Color.white.opacity(0.08)
                        )
                        .foregroundColor(selectedCategory == cat ? .white : .gray)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Header

    private var header: some View {
        #if os(tvOS)
        onLaterHeroBanner
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 8)
        #else
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
        #endif
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
    
    private var gridColumns: [GridItem] {
        #if os(tvOS)
        [GridItem(.adaptive(minimum: 260, maximum: 480), spacing: 32)]
        #else
        [GridItem(.adaptive(minimum: 320, maximum: 400), spacing: 24)]
        #endif
    }

    private var programsGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 24) {
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
        #if os(tvOS)
        .buttonStyle(TimeRangePillButtonStyle(isSelected: isSelected))
        #else
        .buttonStyle(.plain)
        #endif
    }
}

#if os(tvOS)
private struct TimeRangePillButtonStyle: ButtonStyle {
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
                        .stroke(
                            isFocused ? Color(red: 139/255, green: 92/255, blue: 246/255).opacity(0.95) : Color.clear,
                            lineWidth: 3
                        )
                )
                .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.08 : 1.0))
                .shadow(
                    color: isFocused ? Color(red: 139/255, green: 92/255, blue: 246/255).opacity(0.5) : .clear,
                    radius: 14, y: 6
                )
                .animation(.easeInOut(duration: 0.18), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .contentShape(Capsule())
        }
    }
}
#endif

// MARK: - On Later Program Card

struct OnLaterProgramCard: View {
    let program: UpcomingProgram
    let onTap: () -> Void
    let onReminder: () -> Void

    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        #if os(tvOS)
        .buttonStyle(OnLaterCardButtonStyle())
        #else
        .buttonStyle(.plain)
        #endif
    }

    private var cardContent: some View {
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

            // Reminder indicator (reminder button not focusable separately on tvOS)
            VStack(spacing: 8) {
                Image(systemName: program.hasReminder ? "bell.fill" : "bell")
                    .font(.system(size: 20))
                    .foregroundColor(program.hasReminder ? Color(hex: "F59E0B") : .gray)

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
                .fill(Color.white.opacity(0.08))
        )
    }
}

#if os(tvOS)
/// Focus-aware ButtonStyle for OnLaterProgramCard on tvOS.
/// Inner View pattern required so @Environment(\.isFocused) resolves
/// against the Button's real focus state.
private struct OnLaterCardButtonStyle: ButtonStyle {
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
                        .stroke(
                            isFocused ? Color(red: 139/255, green: 92/255, blue: 246/255).opacity(0.95) : Color.clear,
                            lineWidth: 3
                        )
                )
                .scaleEffect(configuration.isPressed ? 0.97 : (isFocused ? 1.07 : 1.0))
                .shadow(
                    color: isFocused ? Color(red: 139/255, green: 92/255, blue: 246/255).opacity(0.38) : .clear,
                    radius: 22, y: 10
                )
                .animation(.easeInOut(duration: 0.18), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
#endif

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
    private let api = OpenFlixAPI.shared

    @Published var upcomingPrograms: [UpcomingProgram] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Category Loading

    func loadByCategory(_ category: OnLaterView.OnLaterCategory) {
        isLoading = true
        error = nil
        Task {
            do {
                let response = try await api.getOnLater(endpoint: category.endpoint)
                let programs = response.allItems.compactMap { dto -> UpcomingProgram? in
                    guard let start = dto.program.startDate,
                          let end = dto.program.endDate else { return nil }
                    return UpcomingProgram(
                        id: dto.program.safeId.isEmpty ? "\(dto.safeChannelId)-\(Int(start.timeIntervalSince1970))" : dto.program.safeId,
                        title: dto.program.safeTitle,
                        description: dto.program.description,
                        thumbnailUrl: dto.program.icon ?? dto.safeChannelLogo,
                        startTime: start,
                        endTime: end,
                        channelId: dto.safeChannelId,
                        channelName: dto.safeChannelName,
                        category: dto.program.category
                    )
                }
                await MainActor.run { self.upcomingPrograms = programs }
            } catch {
                await MainActor.run { self.error = error.localizedDescription }
            }
            await MainActor.run { self.isLoading = false }
        }
    }

    func loadUpcomingPrograms() {
        loadByCategory(.all)
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
