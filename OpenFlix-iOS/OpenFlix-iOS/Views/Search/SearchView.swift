import SwiftUI

// MARK: - Search View
// Clean, Xfinity-style search with voice support

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var voiceManager = VoiceSearchManager.shared
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false
    @State private var showVoiceSheet = false
    @FocusState private var isSearchFocused: Bool
    
    // Recent searches (persisted)
    @AppStorage("recentSearches") private var recentSearchesData: Data = Data()
    @State private var recentSearches: [String] = []
    
    // Xfinity theme colors
    private let backgroundColor = Color(red: 17/255, green: 12/255, blue: 33/255) // #110c21
    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255) // #6138f5
    private let cardBackground = Color(red: 26/255, green: 20/255, blue: 46/255) // Slightly lighter

    var body: some View {
        VStack(spacing: 0) {
            // Search bar - prominent at top
            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            // Content
            if viewModel.isSearching {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                Spacer()
            } else if viewModel.hasResults {
                resultsView
            } else if !viewModel.query.isEmpty {
                noResultsView
            } else {
                idleView
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationDestination(isPresented: $showDetail) {
            if let item = selectedItem {
                MediaDetailView(mediaId: item.id)
            }
        }
        .onAppear {
            loadRecentSearches()
            // Auto-focus the search field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
        }
        .onChange(of: viewModel.query) { _, newValue in
            // Debounced search
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                if viewModel.query == newValue && !newValue.isEmpty {
                    await viewModel.search()
                }
            }
        }
    }

    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            TextField("Search movies, shows, sports...", text: $viewModel.query)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    if !viewModel.query.isEmpty {
                        addToRecentSearches(viewModel.query)
                        Task { await viewModel.search() }
                    }
                }
            
            if !viewModel.query.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Voice search button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showVoiceSheet = true
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(cardBackground)
        .cornerRadius(12)
        .sheet(isPresented: $showVoiceSheet) {
            VoiceSearchSheet(
                voiceManager: voiceManager,
                onResult: { text in
                    viewModel.query = text
                    addToRecentSearches(text)
                    Task { await viewModel.search() }
                    showVoiceSheet = false
                },
                onCancel: {
                    showVoiceSheet = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Idle View (Recent Searches + Trending)
    
    private var idleView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recent Searches
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Button("Clear") {
                                clearRecentSearches()
                            }
                            .font(.system(size: 14))
                            .foregroundColor(accentColor)
                        }
                        
                        ForEach(recentSearches, id: \.self) { search in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.query = search
                                Task { await viewModel.search() }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    Text(search)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.left")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .padding(.vertical, 8)
                            }
                            
                            if search != recentSearches.last {
                                Divider()
                                    .background(.white.opacity(0.1))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Trending / Popular (if available from API)
                if !viewModel.trending.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trending")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.trending) { item in
                                    TrendingCard(item: item) {
                                        selectedItem = item
                                        showDetail = true
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                
                // Quick Categories - prominent buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Browse")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        QuickCategoryButton(title: "Movies", icon: "film", accentColor: accentColor, cardBackground: cardBackground) {
                            viewModel.query = "Movies"
                            Task { await viewModel.search() }
                        }
                        QuickCategoryButton(title: "TV Shows", icon: "tv", accentColor: accentColor, cardBackground: cardBackground) {
                            viewModel.query = "TV Shows"
                            Task { await viewModel.search() }
                        }
                        QuickCategoryButton(title: "Sports", icon: "sportscourt", accentColor: accentColor, cardBackground: cardBackground) {
                            viewModel.query = "Sports"
                            Task { await viewModel.search() }
                        }
                        QuickCategoryButton(title: "News", icon: "newspaper", accentColor: accentColor, cardBackground: cardBackground) {
                            viewModel.query = "News"
                            Task { await viewModel.search() }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.results) { hub in
                    if !hub.items.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(hub.title)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(hub.items) { item in
                                        SearchResultCard(item: item, cardBackground: cardBackground) {
                                            addToRecentSearches(viewModel.query)
                                            selectedItem = item
                                            showDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - No Results
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.4))
            
            Text("No results for \"\(viewModel.query)\"")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
            
            Text("Check the spelling or try different keywords")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
        }
    }
    
    // MARK: - Recent Searches Persistence
    
    private func loadRecentSearches() {
        if let decoded = try? JSONDecoder().decode([String].self, from: recentSearchesData) {
            recentSearches = decoded
        }
    }
    
    private func addToRecentSearches(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Remove if already exists, then add to front
        recentSearches.removeAll { $0.lowercased() == trimmed.lowercased() }
        recentSearches.insert(trimmed, at: 0)
        
        // Keep only last 10
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        
        saveRecentSearches()
    }
    
    private func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }
    
    private func saveRecentSearches() {
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            recentSearchesData = encoded
        }
    }
}

// MARK: - Quick Category Button

struct QuickCategoryButton: View {
    let title: String
    let icon: String
    var accentColor: Color = Color(red: 97/255, green: 56/255, blue: 245/255)
    var cardBackground: Color = Color(red: 26/255, green: 20/255, blue: 46/255)
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search Result Card

struct SearchResultCard: View {
    let item: MediaItem
    var cardBackground: Color = Color(red: 26/255, green: 20/255, blue: 46/255)
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Poster
                AuthenticatedImage(
                    path: item.thumb,
                    systemPlaceholder: item.type == .movie ? "film" : "tv"
                )
                .aspectRatio(2/3, contentMode: .fill)
                .frame(width: 110, height: 165)
                .background(cardBackground)
                .cornerRadius(8)
                
                // Title
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(width: 110, alignment: .leading)
                
                // Year/Type
                if let year = item.year {
                    Text(String(year))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trending Card

struct TrendingCard: View {
    let item: MediaItem
    var cardBackground: Color = Color(red: 26/255, green: 20/255, blue: 46/255)
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottomLeading) {
                AuthenticatedImage(
                    path: item.art ?? item.thumb,
                    systemPlaceholder: "rectangle"
                )
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: 280, height: 158)
                .background(cardBackground)
                .cornerRadius(10)
                
                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .cornerRadius(10)
                
                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(item.type.displayName)
                            .font(.system(size: 12))
                        if let year = item.year {
                            Text("•")
                            Text(String(year))
                                .font(.system(size: 12))
                        }
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(12)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Voice Search Sheet

struct VoiceSearchSheet: View {
    @ObservedObject var voiceManager: VoiceSearchManager
    let onResult: (String) -> Void
    let onCancel: () -> Void
    
    private let backgroundColor = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let accentColor = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let cardBackground = Color(red: 26/255, green: 20/255, blue: 46/255)
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text("Voice Search")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 16)
            
            Spacer()
            
            // Mic animation
            ZStack {
                // Pulse animation when listening
                if voiceManager.isListening {
                    Circle()
                        .fill(accentColor.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .scaleEffect(voiceManager.isListening ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: voiceManager.isListening)
                }
                
                Circle()
                    .fill(voiceManager.isListening ? accentColor : cardBackground)
                    .frame(width: 100, height: 100)
                
                Image(systemName: voiceManager.isListening ? "waveform" : "mic.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(voiceManager.isListening ? .white : accentColor)
                    .symbolEffect(.variableColor.iterative, isActive: voiceManager.isListening)
            }
            
            // Transcript or instruction
            if !voiceManager.transcript.isEmpty {
                Text(voiceManager.transcript)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else if voiceManager.isListening {
                Text("Listening...")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
            } else if let error = voiceManager.error {
                Text(error)
                    .font(.system(size: 15))
                    .foregroundColor(.red)
            } else {
                Text("Tap to start speaking")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 20) {
                Button {
                    voiceManager.stopListening()
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 120, height: 50)
                        .background(cardBackground)
                        .cornerRadius(12)
                }
                
                if voiceManager.isListening {
                    Button {
                        voiceManager.stopListening()
                        if !voiceManager.transcript.isEmpty {
                            onResult(voiceManager.transcript)
                        }
                    } label: {
                        Text("Search")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(accentColor)
                            .cornerRadius(12)
                    }
                } else {
                    Button {
                        voiceManager.startListening()
                    } label: {
                        Text("Start")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(accentColor)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .background(backgroundColor.ignoresSafeArea())
        .onAppear {
            // Auto-start listening when sheet appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                voiceManager.startListening()
            }
        }
        .onDisappear {
            voiceManager.stopListening()
        }
    }
}

#Preview {
    SearchView()
}
