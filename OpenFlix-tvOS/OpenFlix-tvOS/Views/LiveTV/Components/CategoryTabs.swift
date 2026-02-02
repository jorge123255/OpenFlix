import SwiftUI

// MARK: - Category Filter Tabs
// Horizontal scrolling category filter for EPG

struct CategoryTabs: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    var onFavoritesSelected: (() -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // All channels tab
                CategoryTab(
                    title: "All",
                    icon: "rectangle.grid.2x2",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                // Favorites tab
                CategoryTab(
                    title: "Favorites",
                    icon: "star.fill",
                    isSelected: false,
                    accentColor: .yellow,
                    action: { onFavoritesSelected?() }
                )

                // Divider
                Rectangle()
                    .fill(EPGTheme.textMuted.opacity(0.3))
                    .frame(width: 1, height: 30)
                    .padding(.horizontal, 8)

                // Category tabs
                ForEach(categories.prefix(10), id: \.self) { category in
                    CategoryTab(
                        title: category,
                        icon: categoryIcon(for: category),
                        isSelected: selectedCategory == category,
                        accentColor: EPGTheme.categoryColor(for: category),
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 16)
        }
        .focusSection()
        .background(EPGTheme.surface)
    }

    private func categoryIcon(for category: String) -> String? {
        let cat = category.lowercased()
        if cat.contains("sport") { return "sportscourt" }
        if cat.contains("movie") || cat.contains("film") { return "film" }
        if cat.contains("news") { return "newspaper" }
        if cat.contains("kid") || cat.contains("child") { return "figure.2.and.child.holdinghands" }
        if cat.contains("doc") { return "doc.text" }
        if cat.contains("music") { return "music.note" }
        if cat.contains("entertain") { return "tv" }
        return nil
    }
}

// MARK: - Category Tabs With External Focus Control
// Version that accepts external focus control for EPG integration

struct CategoryTabsWithFocus: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    @Binding var shouldFocus: Bool
    var onFavoritesSelected: (() -> Void)?
    var onNavigateDown: (() -> Void)?

    @FocusState private var focusedTab: String?
    @Namespace private var namespace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // All channels tab
                FocusableTab(
                    id: "_all",
                    title: "All",
                    icon: "rectangle.grid.2x2",
                    isSelected: selectedCategory == nil,
                    isFocused: focusedTab == "_all",
                    namespace: namespace,
                    action: { selectedCategory = nil }
                )
                .focused($focusedTab, equals: "_all")

                // Favorites tab
                FocusableTab(
                    id: "_favorites",
                    title: "Favorites",
                    icon: "star.fill",
                    isSelected: false,
                    isFocused: focusedTab == "_favorites",
                    accentColor: .yellow,
                    namespace: namespace,
                    action: { onFavoritesSelected?() }
                )
                .focused($focusedTab, equals: "_favorites")

                // Divider
                Rectangle()
                    .fill(EPGTheme.textMuted.opacity(0.3))
                    .frame(width: 1, height: 30)
                    .padding(.horizontal, 8)

                // Category tabs
                ForEach(categories.prefix(10), id: \.self) { category in
                    FocusableTab(
                        id: category,
                        title: category,
                        icon: categoryIcon(for: category),
                        isSelected: selectedCategory == category,
                        isFocused: focusedTab == category,
                        accentColor: EPGTheme.categoryColor(for: category),
                        namespace: namespace,
                        action: { selectedCategory = category }
                    )
                    .focused($focusedTab, equals: category)
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 16)
        }
        .background(EPGTheme.surface)
        .onChange(of: shouldFocus) { newValue in
            if newValue {
                // When shouldFocus becomes true, focus the "All" tab
                focusedTab = "_all"
            }
        }
        .onChange(of: focusedTab) { newValue in
            // If we have focus, mark shouldFocus as true
            if newValue != nil {
                shouldFocus = true
            }
        }
        .onMoveCommand { direction in
            if direction == .down {
                // User pressed down, return focus to grid
                focusedTab = nil
                onNavigateDown?()
            }
        }
    }

    private func categoryIcon(for category: String) -> String? {
        let cat = category.lowercased()
        if cat.contains("sport") { return "sportscourt" }
        if cat.contains("movie") || cat.contains("film") { return "film" }
        if cat.contains("news") { return "newspaper" }
        if cat.contains("kid") || cat.contains("child") { return "figure.2.and.child.holdinghands" }
        if cat.contains("doc") { return "doc.text" }
        if cat.contains("music") { return "music.note" }
        if cat.contains("entertain") { return "tv" }
        return nil
    }
}

// MARK: - Focusable Tab Button
// Individual tab that can receive and report focus

struct FocusableTab: View {
    let id: String
    let title: String
    var icon: String?
    let isSelected: Bool
    let isFocused: Bool
    var accentColor: Color = EPGTheme.accent
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                }
                Text(title)
                    .font(.system(size: 24, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .black : EPGTheme.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor : EPGTheme.surfaceElevated)
            )
            .overlay(
                Capsule()
                    .stroke(isFocused ? accentColor : .clear, lineWidth: 4)
            )
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.card)
        .prefersDefaultFocus(isFocused, in: namespace)
    }
}

// MARK: - Single Category Tab

struct CategoryTab: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    var accentColor: Color = EPGTheme.accent
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                }
                Text(title)
                    .font(.system(size: 24, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .black : EPGTheme.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor : EPGTheme.surfaceElevated)
            )
            .overlay(
                Capsule()
                    .stroke(isFocused ? accentColor : .clear, lineWidth: 4)
            )
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Compact Category Pills (for player overlay)

struct CompactCategoryPills: View {
    let categories: [String]
    @Binding var selectedCategory: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CompactPill(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(categories.prefix(6), id: \.self) { category in
                    CompactPill(
                        title: category,
                        isSelected: selectedCategory == category,
                        color: EPGTheme.categoryColor(for: category)
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .focusSection()
    }
}

struct CompactPill: View {
    let title: String
    let isSelected: Bool
    var color: Color = EPGTheme.accent
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.white.opacity(0.2))
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

// MARK: - Sort Options Menu

struct SortOptionsMenu: View {
    @Binding var selectedOption: ChannelSortOption
    var onSelect: ((ChannelSortOption) -> Void)?

    var body: some View {
        Menu {
            ForEach(ChannelSortOption.allCases, id: \.self) { option in
                Button {
                    selectedOption = option
                    onSelect?(option)
                } label: {
                    Label(option.displayName, systemImage: option.icon)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.arrow.down")
                Text(selectedOption.displayName)
            }
            .font(.system(size: 20))
            .foregroundColor(EPGTheme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(EPGTheme.surfaceElevated)
            )
        }
    }
}

// MARK: - Channel Sort Option Extension

extension ChannelSortOption {
    var displayName: String {
        switch self {
        case .number: return "Number"
        case .name: return "Name"
        case .recent: return "Recent"
        case .favorite, .favorites: return "Favorites"
        }
    }

    var icon: String {
        switch self {
        case .number: return "number"
        case .name: return "textformat.abc"
        case .recent: return "clock"
        case .favorite, .favorites: return "star"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CategoryTabs(
            categories: ["Sports", "Movies", "News", "Kids", "Entertainment", "Documentary"],
            selectedCategory: .constant(nil)
        )

        CompactCategoryPills(
            categories: ["Sports", "Movies", "News", "Kids"],
            selectedCategory: .constant("Sports")
        )
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
    .background(EPGTheme.background)
}
