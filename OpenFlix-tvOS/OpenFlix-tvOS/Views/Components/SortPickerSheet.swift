import SwiftUI

// MARK: - Sort Picker Sheet
// Fullscreen overlay for tvOS sort selection

struct SortPickerSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedSort: SortOption

    @FocusState private var focusedOption: SortOption?

    var body: some View {
        ZStack {
            // Dark semi-transparent background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Centered card with options
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.title2)
                        .foregroundColor(OpenFlixColors.accent)

                    Text("Sort By")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(OpenFlixColors.textPrimary)

                    Spacer()

                    // Close button hint
                    Text("Menu to close")
                        .font(.caption)
                        .foregroundColor(OpenFlixColors.textTertiary)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .background(OpenFlixColors.surface)

                Divider()
                    .background(OpenFlixColors.textTertiary.opacity(0.3))

                // Sort options grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            SortOptionCard(
                                option: option,
                                isSelected: selectedSort == option,
                                isFocused: focusedOption == option
                            ) {
                                selectedSort = option
                                isPresented = false
                            }
                            .focused($focusedOption, equals: option)
                        }
                    }
                    .padding(24)
                }
            }
            .frame(width: 600, height: 500)
            .background(
                RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusLarge)
                    .fill(OpenFlixColors.surfaceElevated)
            )
            .clipShape(RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusLarge))
            .shadow(color: .black.opacity(0.5), radius: 30)
        }
        .onAppear {
            focusedOption = selectedSort
        }
        .onExitCommand {
            isPresented = false
        }
    }
}

// MARK: - Sort Option Card

private struct SortOptionCard: View {
    let option: SortOption
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: option.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? OpenFlixColors.accent : OpenFlixColors.textSecondary)
                    .frame(width: 28)

                // Label
                Text(option.displayName)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? OpenFlixColors.accent : OpenFlixColors.textPrimary)

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(OpenFlixColors.accent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusMedium)
                    .fill(isSelected ? OpenFlixColors.accent.opacity(0.15) : (isFocused ? OpenFlixColors.focusBackground : OpenFlixColors.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: OpenFlixColors.cornerRadiusMedium)
                    .stroke(isFocused ? OpenFlixColors.accent : (isSelected ? OpenFlixColors.accent.opacity(0.5) : Color.clear), lineWidth: isFocused ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.03 : 1.0)
        .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
    }
}

// MARK: - Preview

#Preview {
    SortPickerSheet(
        isPresented: .constant(true),
        selectedSort: .constant(.addedDesc)
    )
}
