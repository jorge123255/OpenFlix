import Foundation

extension String {
    /// Formats duration in milliseconds to human readable string (e.g., "1h 30m")
    static func formatDuration(milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Formats duration for player display (e.g., "1:30:45")
    static func formatPlayerTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    /// Converts relative time to human readable (e.g., "2 hours ago")
    static func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Truncates string with ellipsis
    func truncated(to length: Int) -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length - 3)) + "..."
    }

    /// Removes HTML tags from string
    var strippingHTML: String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        return attributedString.string
    }

    /// Parses channel number from string (e.g., "5.1" -> 5.1)
    var channelNumber: Double? {
        Double(self)
    }
}

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
