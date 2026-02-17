import SwiftUI

struct EPGGuideView: View {
    @ObservedObject var viewModel: LiveTVViewModel
    @Environment(\.dismiss) var dismiss

    @State private var guide: [ChannelWithPrograms] = []
    @State private var isLoading = true
    @State private var selectedDate = Date()
    @State private var timeOffset: TimeInterval = 0

    private let hourWidth: CGFloat = 300
    private let channelWidth: CGFloat = 200
    private let rowHeight: CGFloat = 100

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView(message: "Loading guide...")
                } else if guide.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No Guide Data",
                        message: "EPG data is not available for your channels."
                    )
                } else {
                    guideContent
                }
            }
            .navigationTitle("TV Guide")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    datePicker
                }
            }
        }
        .task {
            await loadGuide()
        }
    }

    private var guideContent: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Channel column
                VStack(spacing: 0) {
                    // Time header spacer
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 50)

                    // Channel list
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(guide) { channelPrograms in
                                channelHeader(channelPrograms.channel)
                                    .frame(height: rowHeight)
                            }
                        }
                    }
                }
                .frame(width: channelWidth)
                .background(Color.black.opacity(0.5))

                // Programs grid
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    VStack(spacing: 0) {
                        // Time header
                        timeHeader

                        // Program rows
                        LazyVStack(spacing: 0) {
                            ForEach(guide) { channelPrograms in
                                programRow(channelPrograms)
                                    .frame(height: rowHeight)
                            }
                        }
                    }
                }
            }
        }
    }

    private func channelHeader(_ channel: Channel) -> some View {
        HStack(spacing: 12) {
            if let logo = channel.logo {
                AsyncImage(url: logoURL(logo)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    default:
                        Image(systemName: "tv")
                    }
                }
                .frame(width: 50, height: 30)
            }

            VStack(alignment: .leading) {
                if let number = channel.number {
                    Text("\(number)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(channel.name)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
    }

    private var timeHeader: some View {
        HStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate)!

                VStack {
                    Text(timeFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: hourWidth)
                .frame(height: 50)
                .background(isCurrentHour(hour) ? Color.red.opacity(0.3) : Color.clear)
            }
        }
        .background(Color.black.opacity(0.3))
    }

    private func programRow(_ channelPrograms: ChannelWithPrograms) -> some View {
        HStack(spacing: 0) {
            ForEach(channelPrograms.programs) { program in
                ProgramCell(
                    program: program,
                    width: programWidth(for: program)
                ) {
                    // Show program details
                } onRecord: {
                    // Record program
                }
            }
        }
    }

    private func programWidth(for program: Program) -> CGFloat {
        let durationHours = program.endTime.timeIntervalSince(program.startTime) / 3600
        return CGFloat(durationHours) * hourWidth
    }

    private func isCurrentHour(_ hour: Int) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(selectedDate) &&
               calendar.component(.hour, from: Date()) == hour
    }

    private var datePicker: some View {
        Menu {
            ForEach(0..<7, id: \.self) { dayOffset in
                let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
                Button(dateFormatter.string(from: date)) {
                    selectedDate = date
                    Task { await loadGuide() }
                }
            }
        } label: {
            Label(dateFormatter.string(from: selectedDate), systemImage: "calendar")
        }
    }

    private func loadGuide() async {
        isLoading = true
        defer { isLoading = false }

        await viewModel.loadGuide()
        guide = viewModel.guide
    }

    private func logoURL(_ logo: String) -> URL? {
        if logo.hasPrefix("http") {
            return URL(string: logo)
        }
        guard let serverURL = UserDefaults.standard.serverURL else { return nil }
        return serverURL.appendingPathComponent(logo)
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }
}

#Preview {
    EPGGuideView(viewModel: LiveTVViewModel())
}
