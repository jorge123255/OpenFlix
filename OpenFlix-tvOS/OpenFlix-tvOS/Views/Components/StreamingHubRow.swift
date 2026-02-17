import SwiftUI

// MARK: - Streaming Hub Row
// Horizontal scrolling row for content grouped by streaming service

struct StreamingHubRow: View {
    let serviceName: String
    let serviceIcon: String?
    let items: [MediaItem]
    var onItemSelected: ((MediaItem) -> Void)?
    var onSeeAll: (() -> Void)?

    @FocusState private var isSeeAllFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                // Service icon/logo
                if let icon = serviceIcon {
                    AsyncImage(url: iconURL(icon)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        default:
                            serviceDefaultIcon
                        }
                    }
                    .frame(width: 36, height: 36)
                    .cornerRadius(8)
                } else {
                    serviceDefaultIcon
                }

                Text(serviceName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                if items.count > 5 {
                    Button(action: { onSeeAll?() }) {
                        HStack(spacing: 6) {
                            Text("See All")
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline)
                        .foregroundColor(isSeeAllFocused ? OpenFlixColors.accent : OpenFlixColors.textSecondary)
                    }
                    .buttonStyle(.card)
                    .focused($isSeeAllFocused)
                }
            }
            .padding(.horizontal, 50)

            // Content scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(items) { item in
                        MediaCard(item: item, showProgress: true) {
                            onItemSelected?(item)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 10)
            }
            .focusSection()
        }
    }

    private var serviceDefaultIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(serviceColor.opacity(0.2))
                .frame(width: 40, height: 40)

            Image(systemName: "play.tv")
                .font(.title3)
                .foregroundColor(serviceColor)
        }
    }

    private var serviceColor: Color {
        // Color coding for known services
        let name = serviceName.lowercased()
        if name.contains("netflix") { return Color.red }
        if name.contains("disney") { return Color.blue }
        if name.contains("hbo") || name.contains("max") { return Color.purple }
        if name.contains("prime") || name.contains("amazon") { return Color.cyan }
        if name.contains("hulu") { return Color.green }
        if name.contains("apple") { return Color.gray }
        if name.contains("paramount") { return Color.blue }
        if name.contains("peacock") { return Color.yellow }
        return OpenFlixColors.primary
    }

    private func iconURL(_ path: String) -> URL? {
        guard let serverURL = UserDefaults.standard.serverURL else { return nil }
        if path.hasPrefix("http") {
            return URL(string: path)
        }
        return serverURL.appendingPathComponent(path)
    }
}

// MARK: - Streaming Service
// Model for streaming service hub

struct StreamingService: Identifiable {
    let id: String
    let name: String
    let icon: String?
    var items: [MediaItem]

    static func from(items: [MediaItem]) -> [StreamingService] {
        // Group items by source/service
        var services: [String: StreamingService] = [:]

        for item in items {
            // Try to determine service from metadata
            let serviceName = item.studio ?? "Other"

            if var service = services[serviceName] {
                service.items.append(item)
                services[serviceName] = service
            } else {
                services[serviceName] = StreamingService(
                    id: serviceName.lowercased().replacingOccurrences(of: " ", with: "-"),
                    name: serviceName,
                    icon: nil,
                    items: [item]
                )
            }
        }

        return Array(services.values)
            .filter { $0.items.count >= 3 } // Only show services with 3+ items
            .sorted { $0.items.count > $1.items.count }
    }
}

// MARK: - Featured Row
// A simpler row for featured/promoted content

struct FeaturedRow: View {
    let title: String
    let items: [MediaItem]
    var onItemSelected: ((MediaItem) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(items) { item in
                        MediaCard(item: item, showProgress: false) {
                            onItemSelected?(item)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 10)
            }
            .focusSection()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        StreamingHubRow(
            serviceName: "Netflix",
            serviceIcon: nil,
            items: []
        )

        FeaturedRow(
            title: "Recommended For You",
            items: []
        )
    }
    .background(OpenFlixColors.background)
}
