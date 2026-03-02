import SwiftUI

// MARK: - DVR Storage Meter
// Xfinity-style storage usage indicator

struct DVRStorageMeter: View {
    let usedGB: Double
    let totalGB: Double
    let recordingCount: Int
    
    var usedPercentage: Double {
        guard totalGB > 0 else { return 0 }
        return min(usedGB / totalGB, 1.0)
    }
    
    var remainingGB: Double {
        max(totalGB - usedGB, 0)
    }
    
    var statusColor: Color {
        if usedPercentage > 0.9 {
            return .red
        } else if usedPercentage > 0.75 {
            return .yellow
        } else {
            return Color(hex: "6138f5") // Xfinity purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 16))
                    .foregroundColor(statusColor)
                
                Text("DVR Storage")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(recordingCount) recordings")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Used space
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * usedPercentage, height: 8)
                }
            }
            .frame(height: 8)
            
            // Labels
            HStack {
                Text("\(String(format: "%.1f", usedGB)) GB used")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(String(format: "%.1f", remainingGB)) GB free")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Recording Progress Indicator
// Shows recording progress for in-progress recordings

struct RecordingProgressIndicator: View {
    let progress: Double // 0.0 to 1.0
    let isRecording: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray5))
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(isRecording ? Color.red : Color(hex: "6138f5"))
                    .frame(width: geometry.size.width * progress, height: 4)
                
                // Recording pulse animation
                if isRecording {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: geometry.size.width * progress - 4)
                        .shadow(color: .red.opacity(0.5), radius: 4)
                }
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Enhanced Recording Row
// Row with progress indicator

struct EnhancedRecordingRow: View {
    let recording: Recording
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    var progress: Double {
        guard recording.duration > 0 else { return 0 }
        return Double(recording.viewOffset ?? 0) / Double(recording.duration)
    }
    
    var isInProgress: Bool {
        recording.status == .recording
    }
    
    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack(alignment: .bottomLeading) {
                    if let thumb = recording.thumb, let url = URL(string: thumb) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "tv.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Recording badge
                    if isInProgress {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("REC")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(4)
                    }
                }
                .frame(width: 120, height: 68)
                .cornerRadius(8)
                .clipped()
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let subtitle = recording.subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 6) {
                        Text(recording.channelName ?? "")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(formatDuration(recording.duration / 1000))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress bar
                    if progress > 0 || isInProgress {
                        RecordingProgressIndicator(
                            progress: isInProgress ? recordingProgress : progress,
                            isRecording: isInProgress
                        )
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
                .padding(8)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var recordingProgress: Double {
        let start = recording.startTime
        let end = recording.endTime
        
        let now = Date()
        let total = end.timeIntervalSince(start)
        let elapsed = now.timeIntervalSince(start)
        
        guard total > 0 else { return 0.5 }
        return min(max(elapsed / total, 0), 1)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DVRStorageMeter(
            usedGB: 45.2,
            totalGB: 100,
            recordingCount: 24
        )
        
        DVRStorageMeter(
            usedGB: 92,
            totalGB: 100,
            recordingCount: 58
        )
    }
    .padding()
}
