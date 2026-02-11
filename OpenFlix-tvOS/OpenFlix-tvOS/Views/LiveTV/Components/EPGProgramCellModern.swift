import SwiftUI

// MARK: - Modern EPG Program Cell
// Channels DVR-inspired design with rich visuals and smooth animations

struct EPGProgramCellModern: View {
    let program: Program
    let channel: Channel
    let width: CGFloat
    let height: CGFloat
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed = false
    
    private var isCurrentlyAiring: Bool {
        program.isCurrentlyAiring
    }
    
    private var categoryColor: Color {
        if program.isSports { return EPGTheme.sports }
        if program.category?.lowercased().contains("movie") == true { return EPGTheme.movie }
        if program.category?.lowercased().contains("news") == true { return EPGTheme.news }
        if program.isKids { return EPGTheme.kids }
        return EPGTheme.categoryColor(for: program.category)
    }
    
    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottomLeading) {
                // Background with optional artwork
                backgroundView
                
                // Content overlay
                VStack(alignment: .leading, spacing: 6) {
                    Spacer()
                    
                    // Badges row at top
                    if !program.badges.isEmpty || program.isLive {
                        badgesRow
                    }
                    
                    Spacer()
                    
                    // Title with glow effect when focused
                    Text(program.title)
                        .font(.system(size: isFocused ? 22 : 20, weight: isCurrentlyAiring ? .bold : .semibold))
                        .foregroundColor(.white)
                        .lineLimit(isFocused ? 3 : 2)
                        .shadow(color: isFocused ? categoryColor.opacity(0.5) : .clear, radius: 8)
                    
                    // Subtitle/Episode info
                    if let subtitle = program.subtitle, isFocused {
                        Text(subtitle)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    // Time and metadata row
                    HStack(spacing: 8) {
                        // Time
                        Text(program.startTimeFormatted)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        if let rating = program.rating {
                            Text("•")
                                .foregroundColor(.white.opacity(0.4))
                            Text(rating)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.15))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        // Duration
                        Text("\(program.duration)m")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Progress bar for currently airing
                    if isCurrentlyAiring {
                        progressBar
                    }
                }
                .padding(12)
                
                // Category accent stripe (left edge)
                categoryStripe
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(focusOverlay)
            .scaleEffect(isFocused ? 1.05 : (isPressed ? 0.98 : 1.0))
            .shadow(color: isFocused ? categoryColor.opacity(0.4) : .black.opacity(0.3), 
                    radius: isFocused ? 20 : 8, y: isFocused ? 8 : 4)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: [
                    categoryColor.opacity(isCurrentlyAiring ? 0.4 : 0.2),
                    Color.black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Program artwork if available
            if let art = program.art, let url = URL(string: art) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.7), .black.opacity(0.95)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    default:
                        EmptyView()
                    }
                }
            }
            
            // Glass overlay when focused
            if isFocused {
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.3))
            }
        }
    }
    
    // MARK: - Badges Row
    
    private var badgesRow: some View {
        HStack(spacing: 6) {
            if program.isLive {
                liveIndicator
            }
            
            if program.isNew {
                modernBadge("NEW", color: .green)
            }
            
            if program.isPremiere {
                modernBadge("PREMIERE", color: categoryColor)
            }
            
            if program.isFinale {
                modernBadge("FINALE", color: .orange)
            }
            
            if program.hasRecording {
                recordingIndicator
            }
            
            Spacer()
        }
    }
    
    private var liveIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                        .scaleEffect(1.5)
                        .opacity(isCurrentlyAiring ? 1 : 0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isCurrentlyAiring)
                )
            
            Text("LIVE")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red)
        .cornerRadius(4)
    }
    
    private func modernBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color)
            .cornerRadius(4)
    }
    
    private var recordingIndicator: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
            Text("REC")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.red)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.red.opacity(0.2))
        .cornerRadius(4)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.2))
                
                // Progress fill with gradient
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [categoryColor, categoryColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(program.progress))
                
                // Glow dot at progress point
                if isFocused {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: categoryColor, radius: 4)
                        .offset(x: geo.size.width * CGFloat(program.progress) - 4)
                }
            }
        }
        .frame(height: 4)
    }
    
    // MARK: - Category Stripe
    
    private var categoryStripe: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [categoryColor, categoryColor.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: isFocused ? 5 : 4)
                .padding(.vertical, 8)
                .shadow(color: isFocused ? categoryColor : .clear, radius: 4)
            Spacer()
        }
    }
    
    // MARK: - Focus Overlay
    
    private var focusOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    colors: isFocused ? [categoryColor, categoryColor.opacity(0.5)] : [.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isFocused ? 3 : 0
            )
    }
}

// MARK: - Modern Channel Cell

struct EPGChannelCellModern: View {
    let channel: Channel
    let height: CGFloat
    let isPlaying: Bool
    let onSelect: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Channel logo
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    if let logo = channel.logo, let url = URL(string: logo) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 48)
                            default:
                                channelNumberView
                            }
                        }
                    } else {
                        channelNumberView
                    }
                    
                    // Playing indicator
                    if isPlaying {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .offset(x: 20, y: -20)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    // Channel number
                    if let number = channel.number {
                        Text("\(number)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(EPGTheme.accent)
                    }
                    
                    // Channel name
                    Text(channel.name)
                        .font(.system(size: 16, weight: isFocused ? .semibold : .regular))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Favorite indicator
                    if channel.isFavorite {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("Favorite")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.yellow.opacity(0.8))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isFocused ? EPGTheme.accent.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? EPGTheme.accent : .clear, lineWidth: 2)
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
    
    private var channelNumberView: some View {
        Text(channel.number.map { "\($0)" } ?? "?")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(EPGTheme.textSecondary)
    }
}

// MARK: - Modern Time Header

struct EPGTimeHeaderModern: View {
    let timeSlots: [Date]
    let timeSlotWidth: CGFloat
    let headerHeight: CGFloat
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(timeSlots.enumerated()), id: \.offset) { index, time in
                VStack(spacing: 4) {
                    Text(dateFormatter.string(from: time))
                        .font(.system(size: 16, weight: isCurrentSlot(time) ? .bold : .medium))
                        .foregroundColor(isCurrentSlot(time) ? EPGTheme.accent : EPGTheme.textSecondary)
                    
                    // Current time indicator
                    if isCurrentSlot(time) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(EPGTheme.accent)
                            .frame(width: 40, height: 3)
                    }
                }
                .frame(width: timeSlotWidth, height: headerHeight)
                .background(
                    isCurrentSlot(time) ? EPGTheme.accent.opacity(0.1) : Color.clear
                )
            }
        }
    }
    
    private func isCurrentSlot(_ time: Date) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let slotEnd = calendar.date(byAdding: .minute, value: 30, to: time) ?? time
        return now >= time && now < slotEnd
    }
}

// MARK: - Now Playing Mini Card (Corner overlay)

struct NowPlayingMiniCard: View {
    let channel: Channel
    let program: Program?
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Mini video preview placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black)
                    .frame(width: 120, height: 68)
                    .overlay(
                        Image(systemName: "play.tv.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    )
                    .overlay(
                        // Live badge
                        VStack {
                            HStack {
                                Spacer()
                                Text("LIVE")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(3)
                                    .padding(4)
                            }
                            Spacer()
                        }
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let program = program {
                        Text(program.title)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        
                        if program.isCurrentlyAiring {
                            EPGProgressBar(progress: program.progress, height: 3)
                                .frame(width: 100)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .frame(width: 280)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Quick Navigation Bar

struct EPGQuickNavBar: View {
    let onJumpToNow: () -> Void
    let onJumpToPrimetime: () -> Void
    let onShowCategories: () -> Void
    let onSearch: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            quickNavButton(icon: "clock.fill", label: "Now", action: onJumpToNow)
            quickNavButton(icon: "moon.stars.fill", label: "Tonight", action: onJumpToPrimetime)
            quickNavButton(icon: "line.3.horizontal.decrease", label: "Filter", action: onShowCategories)
            quickNavButton(icon: "magnifyingglass", label: "Search", action: onSearch)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(0.5))
    }
    
    private func quickNavButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.white.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let sampleProgram = Program(
        id: "p1",
        title: "NFL Football: Chiefs vs Bills",
        subtitle: "AFC Championship Game",
        description: "The Kansas City Chiefs face the Buffalo Bills.",
        startTime: Date().addingTimeInterval(-1800),
        endTime: Date().addingTimeInterval(5400),
        duration: 120,
        icon: nil,
        art: nil,
        rating: "TV-G",
        category: "Sports",
        isNew: false,
        isLive: true,
        isPremiere: false,
        isFinale: false,
        isSports: true,
        isKids: false,
        teams: "Chiefs, Bills",
        league: "NFL",
        hasRecording: true,
        recordingId: nil
    )
    
    let sampleChannel = Channel(
        id: "1",
        number: 206,
        name: "ESPN",
        logo: nil,
        sourceId: nil,
        sourceName: nil,
        streamUrl: nil,
        enabled: true,
        isFavorite: true,
        group: "Sports",
        archiveEnabled: false,
        archiveDays: 0,
        nowPlaying: nil,
        nextProgram: nil
    )
    
    return ScrollView {
        VStack(spacing: 30) {
            EPGQuickNavBar(
                onJumpToNow: {},
                onJumpToPrimetime: {},
                onShowCategories: {},
                onSearch: {}
            )
            
            EPGProgramCellModern(
                program: sampleProgram,
                channel: sampleChannel,
                width: 400,
                height: 120,
                onSelect: {}
            )
            
            EPGChannelCellModern(
                channel: sampleChannel,
                height: 80,
                isPlaying: true,
                onSelect: {}
            )
            .frame(width: 280)
            
            NowPlayingMiniCard(
                channel: sampleChannel,
                program: sampleProgram,
                onTap: {}
            )
        }
        .padding()
    }
    .background(EPGTheme.background)
}
