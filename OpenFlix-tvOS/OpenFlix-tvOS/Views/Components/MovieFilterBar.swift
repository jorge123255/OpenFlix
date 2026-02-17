import SwiftUI

// MARK: - Movie Filter Bar
// Combined filter bar with genre chips and sort button for tvOS

struct MovieFilterBar: View {
    let genres: [String]
    @Binding var selectedGenre: String?
    @Binding var showSortPicker: Bool
    let currentSort: SortOption

    @FocusState private var focusedItem: FilterItem?
    @Namespace private var namespace

    // Track all focusable items
    private enum FilterItem: Hashable {
        case all
        case genre(String)
        case sort
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" chip - always first
                MovieFilterChip(
                    title: "All",
                    icon: "rectangle.grid.2x2",
                    isSelected: selectedGenre == nil,
                    isFocused: focusedItem == .all
                ) {
                    selectedGenre = nil
                }
                .focused($focusedItem, equals: .all)

                // Genre chips
                ForEach(genres.prefix(8), id: \.self) { genre in
                    MovieFilterChip(
                        title: genre,
                        icon: genreIcon(for: genre),
                        isSelected: selectedGenre == genre,
                        isFocused: focusedItem == .genre(genre)
                    ) {
                        selectedGenre = genre
                    }
                    .focused($focusedItem, equals: .genre(genre))
                }

                // Divider
                Rectangle()
                    .fill(OpenFlixColors.textTertiary.opacity(0.3))
                    .frame(width: 1, height: 30)
                    .padding(.horizontal, 8)

                // Sort button
                SortButton(
                    currentSort: currentSort,
                    isFocused: focusedItem == .sort
                ) {
                    showSortPicker = true
                }
                .focused($focusedItem, equals: .sort)
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 12)
        }
        .focusSection()
    }

    private func genreIcon(for genre: String) -> String? {
        let g = genre.lowercased()
        if g.contains("action") { return "bolt.fill" }
        if g.contains("comedy") { return "face.smiling" }
        if g.contains("drama") { return "theatermasks" }
        if g.contains("horror") { return "moon.fill" }
        if g.contains("sci") || g.contains("fiction") { return "sparkles" }
        if g.contains("thriller") { return "exclamationmark.triangle" }
        if g.contains("romance") { return "heart.fill" }
        if g.contains("documentary") { return "doc.text" }
        if g.contains("animation") { return "wand.and.stars" }
        if g.contains("family") || g.contains("kids") { return "figure.2.and.child.holdinghands" }
        if g.contains("music") { return "music.note" }
        if g.contains("western") { return "sun.dust" }
        if g.contains("crime") { return "magnifyingglass" }
        if g.contains("mystery") { return "questionmark" }
        if g.contains("war") { return "shield" }
        if g.contains("sport") { return "sportscourt" }
        return nil
    }
}

// MARK: - Movie Filter Chip

private struct MovieFilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 16))
                }
                Text(title)
                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .black : OpenFlixColors.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? OpenFlixColors.accent : OpenFlixColors.surfaceVariant)
            )
            .overlay(
                Capsule()
                    .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
    }
}

// MARK: - Sort Button

private struct SortButton: View {
    let currentSort: SortOption
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16))
                Text(currentSort.displayName)
                    .font(.system(size: 20, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
            }
            .foregroundColor(OpenFlixColors.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(OpenFlixColors.surfaceVariant)
            )
            .overlay(
                Capsule()
                    .stroke(isFocused ? OpenFlixColors.accent : .clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        MovieFilterBar(
            genres: ["Action", "Comedy", "Drama", "Horror", "Sci-Fi", "Thriller", "Romance", "Documentary"],
            selectedGenre: .constant(nil),
            showSortPicker: .constant(false),
            currentSort: .titleAsc
        )

        MovieFilterBar(
            genres: ["Action", "Comedy", "Drama", "Horror"],
            selectedGenre: .constant("Action"),
            showSortPicker: .constant(false),
            currentSort: .yearDesc
        )
    }
    .background(OpenFlixColors.background)
}
