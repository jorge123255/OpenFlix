import SwiftUI

// MARK: - Channel Groups View
/// Organize channels into custom groups for quick access.
/// Create groups like "Sports", "News", "Kids", etc.

struct ChannelGroupsView: View {
    @StateObject private var viewModel = CustomChannelGroupsViewModel()
    @State private var showCreateSheet = false
    @State private var editingGroup: CustomChannelGroup?
    @FocusState private var focusedGroup: String?
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "0d0d0d")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.groups.isEmpty {
                    emptyView
                } else {
                    groupsGrid
                }
            }
        }
        .onAppear {
            viewModel.loadGroups()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateGroupSheet(
                onCreate: { name, icon, channelIds in
                    viewModel.createGroup(name: name, icon: icon, channelIds: channelIds)
                    showCreateSheet = false
                },
                onCancel: { showCreateSheet = false },
                availableChannels: viewModel.allChannels
            )
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Channel Groups")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Organize your channels")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Create group button
            Button(action: { showCreateSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Group")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(hex: "00D4AA"))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 48)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }
    
    // MARK: - Groups Grid
    
    private var groupsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 24)
                ],
                spacing: 24
            ) {
                ForEach(viewModel.groups) { group in
                    ChannelGroupCard(
                        group: group,
                        onTap: { viewModel.playGroup(group) },
                        onEdit: { editingGroup = group },
                        onDelete: { viewModel.deleteGroup(group) }
                    )
                    .focused($focusedGroup, equals: group.id)
                }
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 48)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "00D4AA"))
            
            Text("Loading channel groups...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Channel Groups")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Create groups to organize your channels\nlike Sports, News, Kids, etc.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            
            Button(action: { showCreateSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Create Your First Group")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(hex: "00D4AA"))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Channel Group Card

struct ChannelGroupCard: View {
    let group: CustomChannelGroup
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isFocused = false
    @State private var showActions = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [group.color, group.color.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: group.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(group.channels.count) channels")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Play button
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "00D4AA"))
                }
                
                // Channel logos preview
                if !group.channels.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(group.channels.prefix(5)) { channel in
                            AsyncImage(url: URL(string: channel.logoUrl ?? "")) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(hex: "0d0d0d"), lineWidth: 2))
                        }
                        
                        if group.channels.count > 5 {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                Text("+\(group.channels.count - 5)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isFocused ? 0.12 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? Color(hex: "00D4AA") : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .onFocusChange { focused in
            isFocused = focused
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Group", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete Group", systemImage: "trash")
            }
        }
    }
}

// MARK: - Create Group Sheet

struct CreateGroupSheet: View {
    let onCreate: (String, String, [String]) -> Void
    let onCancel: () -> Void
    let availableChannels: [CustomGroupChannel]
    
    @State private var name = ""
    @State private var selectedIcon = "tv"
    @State private var selectedChannels: Set<String> = []
    
    private let icons = [
        "tv", "sportscourt", "newspaper", "film", "music.note",
        "theatermasks", "gamecontroller", "figure.child", "house",
        "globe", "airplane", "car", "fork.knife", "leaf"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Group Name") {
                    TextField("Enter name", text: $name)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedIcon == icon ? .black : .white)
                                    .frame(width: 50, height: 50)
                                    .background(selectedIcon == icon ? Color(hex: "00D4AA") : Color.gray.opacity(0.3))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Section("Channels (\(selectedChannels.count) selected)") {
                    ForEach(availableChannels) { channel in
                        Button {
                            if selectedChannels.contains(channel.id) {
                                selectedChannels.remove(channel.id)
                            } else {
                                selectedChannels.insert(channel.id)
                            }
                        } label: {
                            HStack {
                                AsyncImage(url: URL(string: channel.logoUrl ?? "")) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    Rectangle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 40, height: 40)
                                .cornerRadius(6)
                                
                                VStack(alignment: .leading) {
                                    Text(channel.name)
                                        .foregroundColor(.white)
                                    if let number = channel.number {
                                        Text("Ch \(number)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedChannels.contains(channel.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "00D4AA"))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Create Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(name, selectedIcon, Array(selectedChannels))
                    }
                    .disabled(name.isEmpty || selectedChannels.isEmpty)
                }
            }
        }
    }
}

// MARK: - Local Models (UI-specific, distinct from Domain.ChannelGroup)

struct CustomChannelGroup: Identifiable {
    let id: String
    let name: String
    let icon: String
    let channels: [CustomGroupChannel]
    var color: Color = Color(hex: "00D4AA")
}

struct CustomGroupChannel: Identifiable {
    let id: String
    let name: String
    let number: String?
    let logoUrl: String?
}

// MARK: - ViewModel

@MainActor
class CustomChannelGroupsViewModel: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published var groups: [CustomChannelGroup] = []
    @Published var allChannels: [CustomGroupChannel] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadGroups() {
        isLoading = true
        error = nil
        Task {
            do {
                // Load all channels for the picker
                let channelsResponse = try await api.getChannels()
                allChannels = channelsResponse.allChannels.map { dto in
                    CustomGroupChannel(
                        id: dto.safeId,
                        name: dto.safeName,
                        number: dto.number.map { String($0) },
                        logoUrl: dto.logo ?? dto.thumb
                    )
                }

                // Load channel groups
                let groupsResponse = try await api.getChannelGroups()
                groups = groupsResponse.groups.map { dto in
                    let memberChannels = (dto.members ?? []).compactMap { member in
                        allChannels.first { $0.id == member.channelId } ??
                        CustomGroupChannel(
                            id: member.channelId,
                            name: member.channelName ?? "Channel \(member.channelId)",
                            number: nil,
                            logoUrl: nil
                        )
                    }
                    return CustomChannelGroup(
                        id: String(dto.id),
                        name: dto.name,
                        icon: "tv",
                        channels: memberChannels
                    )
                }
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }

    func createGroup(name: String, icon: String, channelIds: [String]) {
        Task {
            do {
                try await api.createChannelGroup(name: name, channelIds: channelIds)
                // Reload groups to get the server-assigned ID
                loadGroups()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func deleteGroup(_ group: CustomChannelGroup) {
        Task {
            do {
                try await api.deleteChannelGroup(id: group.id)
                groups.removeAll { $0.id == group.id }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func playGroup(_ group: CustomChannelGroup) {
        guard let firstChannel = group.channels.first else { return }
        // Navigate to live TV player with the first channel in the group
        Task {
            if let url = await api.channelStreamURL(id: firstChannel.id) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("PlayLiveChannel"),
                    object: nil,
                    userInfo: ["url": url, "channelName": firstChannel.name]
                )
            }
        }
    }
}

#Preview {
    ChannelGroupsView()
}
