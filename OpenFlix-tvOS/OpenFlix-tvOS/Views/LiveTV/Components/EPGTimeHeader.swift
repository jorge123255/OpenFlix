import SwiftUI

// MARK: - EPG Time Header
// Displays time slots with a "now" line indicator

struct EPGTimeHeader: View {
    let timeSlots: [Date]
    let timeSlotWidth: CGFloat
    let headerHeight: CGFloat
    let scrollOffset: CGFloat

    @State private var currentTimePosition: CGFloat = 0

    private let updateTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Time slots
            HStack(spacing: 0) {
                ForEach(timeSlots, id: \.self) { slot in
                    TimeSlotHeader(
                        time: slot,
                        width: timeSlotWidth,
                        height: headerHeight,
                        isNow: isCurrentTimeSlot(slot)
                    )
                }
            }

            // Now line indicator
            if currentTimePosition > 0 {
                NowLineIndicator(height: headerHeight)
                    .offset(x: currentTimePosition - scrollOffset)
            }
        }
        .onAppear {
            updateCurrentTimePosition()
        }
        .onReceive(updateTimer) { _ in
            updateCurrentTimePosition()
        }
    }

    private func isCurrentTimeSlot(_ slot: Date) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let slotEnd = calendar.date(byAdding: .minute, value: 30, to: slot) ?? slot
        return slot <= now && now < slotEnd
    }

    private func updateCurrentTimePosition() {
        guard let firstSlot = timeSlots.first else {
            currentTimePosition = 0
            return
        }

        let now = Date()
        let secondsSinceStart = now.timeIntervalSince(firstSlot)
        let minutesSinceStart = secondsSinceStart / 60.0

        // Each 30-minute slot = timeSlotWidth
        currentTimePosition = CGFloat(minutesSinceStart / 30.0) * timeSlotWidth
    }
}

// MARK: - Time Slot Header Cell

struct TimeSlotHeader: View {
    let time: Date
    let width: CGFloat
    let height: CGFloat
    let isNow: Bool

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }

    var body: some View {
        VStack {
            Spacer()

            Text(formattedTime)
                .font(.system(size: 24, weight: isNow ? .bold : .medium))
                .foregroundColor(isNow ? EPGTheme.accent : EPGTheme.textSecondary)

            Spacer()

            // Bottom border tick
            Rectangle()
                .fill(EPGTheme.textMuted.opacity(0.5))
                .frame(width: 1, height: 10)
        }
        .frame(width: width, height: height)
        .background(EPGTheme.surface)
        .overlay(
            Rectangle()
                .fill(EPGTheme.background)
                .frame(width: 1),
            alignment: .leading
        )
    }
}

// MARK: - Now Line Indicator

struct NowLineIndicator: View {
    let height: CGFloat
    var extendedHeight: CGFloat?

    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 0) {
            // Time label bubble
            Text(currentTimeString)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(EPGTheme.nowLine)
                .cornerRadius(4)

            // Vertical line
            Rectangle()
                .fill(EPGTheme.nowLine)
                .frame(width: 2)
                .frame(height: extendedHeight ?? (height - 30))
                .opacity(isPulsing ? 0.8 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - Extended Now Line (for full grid height)

struct EPGNowLine: View {
    let timeSlots: [Date]
    let timeSlotWidth: CGFloat
    let totalHeight: CGFloat
    let scrollOffset: CGFloat

    @State private var position: CGFloat = 0

    private let updateTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        if position > scrollOffset && position < scrollOffset + UIScreen.main.bounds.width {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(EPGTheme.nowLine)
                    .frame(width: 2, height: totalHeight)
            }
            .offset(x: position - scrollOffset)
            .onAppear { updatePosition() }
            .onReceive(updateTimer) { _ in updatePosition() }
        }
    }

    private func updatePosition() {
        guard let firstSlot = timeSlots.first else {
            position = 0
            return
        }

        let now = Date()
        let minutesSinceStart = now.timeIntervalSince(firstSlot) / 60.0
        position = CGFloat(minutesSinceStart / 30.0) * timeSlotWidth
    }
}

#Preview {
    let calendar = Calendar.current
    let now = Date()
    let startOfHour = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: now))!

    let timeSlots = (0..<6).map { i in
        calendar.date(byAdding: .minute, value: i * 30, to: startOfHour)!
    }

    return VStack(spacing: 0) {
        EPGTimeHeader(
            timeSlots: timeSlots,
            timeSlotWidth: 300,
            headerHeight: 60,
            scrollOffset: 0
        )

        Divider()

        // Simulated grid content
        Rectangle()
            .fill(EPGTheme.background)
            .frame(height: 400)
    }
    .background(EPGTheme.background)
}
