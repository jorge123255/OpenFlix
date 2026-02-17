import SwiftUI

struct ProfileSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showPinEntry = false
    @State private var selectedProfile: Profile?
    @State private var pin = ""

    var body: some View {
        ZStack {
            // Background gradient
            OpenFlixColors.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 60) {
                // Header
                VStack(spacing: 16) {
                    Text("OpenFlix")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(OpenFlixColors.primary)

                    Text("Who's Watching?")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundColor(OpenFlixColors.textPrimary)
                }

                // Profile Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 40) {
                    ForEach(authViewModel.profiles) { profile in
                        ProfileCard(profile: profile) {
                            selectProfile(profile)
                        }
                    }
                }
                .padding(.horizontal, 120)

                if let error = authViewModel.error {
                    Text(error)
                        .foregroundColor(OpenFlixColors.error)
                        .font(.subheadline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(OpenFlixColors.error.opacity(0.2))
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding(.top, 80)
            .padding(48)

            // PIN Entry
            if showPinEntry {
                PinEntryOverlay(
                    profile: selectedProfile,
                    pin: $pin,
                    onSubmit: submitPin,
                    onCancel: cancelPinEntry
                )
            }

            // Loading
            if authViewModel.isLoading {
                LoadingOverlay(isLoading: true, message: "Switching profile...")
            }
        }
        .task {
            if authViewModel.profiles.isEmpty {
                try? await authViewModel.loadProfiles()
            }
        }
    }

    private func selectProfile(_ profile: Profile) {
        if profile.isProtected {
            selectedProfile = profile
            pin = ""
            showPinEntry = true
        } else {
            Task {
                await authViewModel.selectProfile(profile)
            }
        }
    }

    private func submitPin() {
        guard let profile = selectedProfile else { return }
        showPinEntry = false
        Task {
            await authViewModel.selectProfile(profile, pin: pin)
        }
    }

    private func cancelPinEntry() {
        showPinEntry = false
        selectedProfile = nil
        pin = ""
    }
}

struct ProfileCard: View {
    let profile: Profile
    var onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 20) {
                // Avatar
                ZStack {
                    if let avatar = profile.avatar,
                       let serverURL = UserDefaults.standard.serverURL,
                       let url = URL(string: avatar.hasPrefix("http") ? avatar : serverURL.appendingPathComponent(avatar).absoluteString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                defaultAvatar
                            }
                        }
                    } else {
                        defaultAvatar
                    }

                    // Lock icon for protected profiles
                    if profile.isProtected {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(OpenFlixColors.surface.opacity(0.8))
                            .clipShape(Circle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(8)
                    }

                    // Kid profile badge
                    if profile.isKid {
                        Text("KIDS")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(OpenFlixColors.background)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(OpenFlixColors.success)
                            .cornerRadius(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(8)
                    }
                }
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isFocused ? OpenFlixColors.primary : OpenFlixColors.surfaceVariant, lineWidth: isFocused ? 4 : 2)
                )
                .shadow(color: isFocused ? OpenFlixColors.primary.opacity(0.5) : .clear, radius: 20)
                .scaleEffect(isFocused ? 1.1 : 1.0)

                // Name
                Text(profile.name)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(isFocused ? OpenFlixColors.primary : OpenFlixColors.textPrimary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    private var defaultAvatar: some View {
        ZStack {
            LinearGradient(
                colors: [OpenFlixColors.primary.opacity(0.3), OpenFlixColors.primaryDark.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(profile.initials)
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(OpenFlixColors.textPrimary)
        }
    }
}


struct PinEntryOverlay: View {
    let profile: Profile?
    @Binding var pin: String
    var onSubmit: () -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            OpenFlixColors.overlayDark
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Profile avatar
                if let profile = profile {
                    ZStack {
                        Circle()
                            .fill(OpenFlixColors.primary.opacity(0.3))
                        Text(profile.initials)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(OpenFlixColors.textPrimary)
                    }
                    .frame(width: 100, height: 100)
                }

                Text("Enter PIN for \(profile?.name ?? "")")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(OpenFlixColors.textPrimary)

                // PIN Display
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(index < pin.count ? OpenFlixColors.primary : OpenFlixColors.surfaceVariant)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .fill(index < pin.count ? OpenFlixColors.background : .clear)
                                    .frame(width: 16, height: 16)
                            )
                    }
                }

                // Number Pad for tvOS
                VStack(spacing: 16) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 16) {
                            ForEach(1...3, id: \.self) { col in
                                let number = row * 3 + col
                                NumberPadButton(number: "\(number)") {
                                    appendDigit("\(number)")
                                }
                            }
                        }
                    }
                    // Bottom row: Clear, 0, Delete
                    HStack(spacing: 16) {
                        NumberPadButton(number: "C", isSpecial: true) {
                            pin = ""
                        }
                        NumberPadButton(number: "0") {
                            appendDigit("0")
                        }
                        NumberPadButton(number: "⌫", isSpecial: true) {
                            if !pin.isEmpty {
                                pin.removeLast()
                            }
                        }
                    }
                }

                HStack(spacing: 32) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(OpenFlixColors.textSecondary)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(OpenFlixColors.surfaceVariant)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: onSubmit) {
                        Text("Submit")
                            .font(.headline)
                            .foregroundColor(OpenFlixColors.background)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(pin.count == 4 ? OpenFlixColors.primary : OpenFlixColors.primary.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(pin.count != 4)
                }
            }
            .padding(48)
            .background(OpenFlixColors.surface)
            .cornerRadius(24)
        }
    }

    private func appendDigit(_ digit: String) {
        if pin.count < 4 {
            pin += digit
        }
        if pin.count == 4 {
            // Auto-submit after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSubmit()
            }
        }
    }
}

struct NumberPadButton: View {
    let number: String
    var isSpecial: Bool = false
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: isSpecial ? 24 : 32, weight: .semibold))
                .foregroundColor(isFocused ? OpenFlixColors.background : OpenFlixColors.textPrimary)
                .frame(width: 80, height: 80)
                .background(isFocused ? OpenFlixColors.primary : OpenFlixColors.surfaceVariant)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }
}

#Preview {
    ProfileSelectionView()
        .environmentObject(AuthViewModel())
}
