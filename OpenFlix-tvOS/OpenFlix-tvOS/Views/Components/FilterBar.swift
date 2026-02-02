import SwiftUI

// MARK: - Filter Bar
// Horizontal filter chips for genre and sort options

struct FilterBar: View {
    let genres: [String]
    @Binding var selectedGenre: String?
    @Binding var selectedSort: SortOption
    var onNavigateDown: (() -> Void)?

    @FocusState private var focusedChip: String?
    @Namespace private var namespace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // All button
                FilterChip(
                    id: "_all",
                    title: "All",
                    icon: "rectangle.grid.2x2",
                    isSelected: selectedGenre == nil,
                    isFocused: focusedChip == "_all",
                    namespace: namespace
                ) {
                    selectedGenre = nil
                }
                .focused($focusedChip, equals: "_all")

                // Divider
                Rectangle()
                    .fill(OpenFlixColors.textTertiary.opacity(0.3))
                    .frame(width: 1, height: 30)
                    .padding(.horizontal, 4)

                // Genre chips
                ForEach(genres.prefix(8), id: \.self) { genre in
                    FilterChip(
                        id: genre,
                        title: genre,
                        icon: genreIcon(for: genre),
                        isSelected: selectedGenre == genre,
                        isFocused: focusedChip == genre,
                        namespace: namespace
                    ) {
                        selectedGenre = genre
                    }
                    .focused($focusedChip, equals: genre)
                }

                // Divider
                Rectangle()
                    .fill(OpenFlixColors.textTertiary.opacity(0.3))
                    .frame(width: 1, height: 30)
                    .padding(.horizontal, 4)

                // Sort menu
                SortChip(selectedSort: $selectedSort)
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 16)
        }
        .focusSection()
        .background(OpenFlixColors.surface)
        .onMoveCommand { direction in
            if direction == .down {
                focusedChip = nil
                onNavigateDown?()
            }
        }
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

// MARK: - Filter Chip

struct FilterChip: View {
    let id: String
    let title: String
    var icon: String?
    let isSelected: Bool
    let isFocused: Bool
    let namespace: Namespace.ID
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
                    .fill(isSelected ? OpenFlixColors.primary : OpenFlixColors.surfaceVariant)
            )
            .overlay(
                Capsule()
                    .stroke(isFocused ? OpenFlixColors.primary : .clear, lineWidth: 3)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.card)
    }
}

// MARK: - Sort Chip

struct SortChip: View {
    @Binding var selectedSort: SortOption
    @FocusState private var isFocused: Bool

    var body: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(action: { selectedSort = option }) {
                    HStack {
                        Text(option.displayName)
                        if selectedSort == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16))
                Text(selectedSort.displayName)
                    .font(.system(size: 20, weight: .medium))
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
                    .stroke(isFocused ? OpenFlixColors.primary : .clear, lineWidth: 3)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .focused($isFocused)
    }
}

// MARK: - Compact Filter Bar
// Smaller version for use in overlays or compact spaces

struct CompactFilterBar: View {
    let genres: [String]
    @Binding var selectedGenre: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CompactFilterChip(title: "All", isSelected: selectedGenre == nil) {
                    selectedGenre = nil
                }

                ForEach(genres.prefix(6), id: \.self) { genre in
                    CompactFilterChip(title: genre, isSelected: selectedGenre == genre) {
                        selectedGenre = genre
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .focusSection()
    }
}

struct CompactFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? OpenFlixColors.primary : Color.white.opacity(0.2))
                )
                .overlay(
                    Capsule()
                        .stroke(isFocused ? .white : .clear, lineWidth: 2)
                )
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        FilterBar(
            genres: ["Action", "Comedy", "Drama", "Horror", "Sci-Fi", "Thriller", "Romance", "Documentary"],
            selectedGenre: .constant(nil),
            selectedSort: .constant(.titleAsc)
        )

        CompactFilterBar(
            genres: ["Action", "Comedy", "Drama", "Horror"],
            selectedGenre: .constant("Action")
        )
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
    .background(OpenFlixColors.background)
}
