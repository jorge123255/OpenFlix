import SwiftUI

// MARK: - Media Detail View
// Apple TV-inspired detail layout for movies and TV shows

struct MediaDetailView: View {
    let mediaId: Int

    @StateObject private var viewModel = MediaDetailViewModel()
    @State private var pendingPlayerItem: MediaItem?
    @State private var showMoreOptions = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    #if os(tvOS)
    @Namespace private var detailFocusNamespace
    #endif

    private var isCompact: Bool { hSizeClass == .compact }
    private var isLandscape: Bool { vSizeClass == .compact }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading details...")
            } else if let error = viewModel.error {
                ErrorView(message: error) {
                    Task { await viewModel.loadMedia(id: mediaId) }
                }
            } else if let item = viewModel.mediaItem {
                detailContent(item)
            } else {
                ErrorView(message: "Failed to load media details") {
                    Task { await viewModel.loadMedia(id: mediaId) }
                }
            }
        }
        .task {
            await viewModel.loadMedia(id: mediaId)
        }
        .onChange(of: pendingPlayerItem) { _, item in
            guard let item else { return }
            pendingPlayerItem = nil
            presentPlayerViaUIKit(item: item)
        }
        #if os(tvOS)
        .sheet(isPresented: $showMoreOptions) {
            TVMoreOptionsSheet(
                onWatched: {
                    showMoreOptions = false
                    Task { await viewModel.markAsWatched() }
                },
                onUnwatched: {
                    showMoreOptions = false
                    Task { await viewModel.markAsUnwatched() }
                },
                onCancel: {
                    showMoreOptions = false
                }
            )
            .presentationDetents([.medium])
        }
        #else
        .confirmationDialog("Options", isPresented: $showMoreOptions) {
            Button("Mark as Watched") {
                Task { await viewModel.markAsWatched() }
            }
            Button("Mark as Unwatched") {
                Task { await viewModel.markAsUnwatched() }
            }
            Button("Cancel", role: .cancel) {}
        }
        #endif
        .onExitCommand {
            dismiss()
            // Surface the global sidecar so a single Menu press both backs out
            // of the detail view AND opens the navigation drawer.
            NotificationCenter.default.post(name: .sidecarToggle, object: nil)
        }
    }

    // MARK: - UIKit Player Presentation (separate UIWindow, immune to SwiftUI rotation)

    private func presentPlayerViaUIKit(item: MediaItem) {
        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
        else { return }
        PlayerWindowManager.shared.present(mediaItem: item, in: windowScene)
    }

    // MARK: - Detail Content

    private func detailContent(_ item: MediaItem) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section (70% height artwork)
                heroSection(item)
                    #if os(iOS)
                    .overlay(alignment: .topLeading) {
                        // Close button — needed when presented modally on iOS
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.black.opacity(0.55))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 58)
                        .padding(.leading, 16)
                    }
                    #endif

                // Content sections
                VStack(alignment: .leading, spacing: 40) {
                    // Summary (expanded) - uses TMDB fallback
                    if let summary = viewModel.effectiveSummary, !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(OpenFlixColors.textPrimary)

                            Text(summary)
                                .font(.body)
                                .foregroundColor(OpenFlixColors.textSecondary)
                                .lineLimit(6)
                                .frame(maxWidth: isCompact ? .infinity : 900, alignment: .leading)
                        }
                    }

                    // Genres (from server or TMDB)
                    if !viewModel.effectiveGenres.isEmpty {
                        genresSection
                    }

                    // Directors and Writers (from server or TMDB)
                    if !viewModel.effectiveDirectors.isEmpty || !item.writers.isEmpty {
                        crewSectionEnhanced
                    }

                    // Seasons & Episodes (for TV shows)
                    if viewModel.hasSeasons {
                        seasonsSection
                    }

                    // Cast & Crew (from server or TMDB)
                    if !viewModel.effectiveCast.isEmpty {
                        castSection(viewModel.effectiveCast)
                    }

                    // Related content
                    if !viewModel.relatedItems.isEmpty {
                        relatedSection
                    }

                    Spacer().frame(height: 48)
                }
                .padding(.horizontal, isCompact ? 16 : 80)
                .padding(.top, isCompact ? 16 : 32)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(OpenFlixColors.background)
    }

    // MARK: - Hero Section

    private func heroSection(_ item: MediaItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Artwork
            AuthenticatedImage(
                path: item.art ?? item.thumb,
                systemPlaceholder: item.type == .movie ? "film" : "tv"
            )
            .aspectRatio(contentMode: .fill)
            .frame(height: isLandscape ? 200 : (isCompact ? 350 : 650))
            .clipped()

            // Side gradient overlay
            if !isCompact {
                OpenFlixColors.sideGradient
            }

            // Bottom gradient
            OpenFlixColors.heroBottomGradient

            // Content overlay
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Title
                Text(item.title)
                    .font(.system(size: isLandscape ? 22 : (isCompact ? 28 : 56), weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
                    .lineLimit(isLandscape ? 1 : 2)

                // Tagline (if available)
                if let tagline = item.tagline, !tagline.isEmpty {
                    Text("\"\(tagline)\"")
                        .font(.title3)
                        .italic()
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .padding(.top, 8)
                }

                Spacer().frame(height: 16)

                // Metadata row
                HStack(spacing: 12) {
                    // Media type icon
                    HStack(spacing: 6) {
                        Image(systemName: item.type == .movie ? "film" : "tv")
                            .font(.subheadline)
                        Text(item.type.displayName)
                            .font(.subheadline)
                    }
                    .foregroundColor(.white.opacity(0.9))

                    // Genres
                    if !item.genres.isEmpty {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))
                        Text(item.genres.prefix(2).joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // Content rating
                    if let rating = item.contentRating {
                        ContentRatingBadge(rating: rating, size: .medium)
                    }
                }

                Spacer().frame(height: 8)

                // Second metadata row
                HStack(spacing: 12) {
                    if let year = item.year {
                        Text(String(year))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    let duration = item.durationFormatted
                    if !duration.isEmpty {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))
                        Text(duration)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    if let resolution = item.resolution {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))
                        Text(resolution)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    if let audienceRating = item.audienceRating {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", audienceRating))
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                    }

                    // Studio
                    if let studio = item.studio, !studio.isEmpty {
                        Text("·")
                            .foregroundColor(.white.opacity(0.6))
                        Text(studio)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer().frame(height: 24)

                // Action buttons
                actionButtons(item)

                Spacer().frame(height: isCompact ? 20 : 48)
            }
            .padding(.horizontal, isCompact ? 16 : 80)
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(_ item: MediaItem) -> some View {
        ActionButtonGroup(
            playTitle: viewModel.playButtonTitle,
            isInWatchlist: viewModel.isInWatchlist,
            onPlay: {
                if viewModel.hasSeasons, let nextUp = viewModel.nextUpEpisode {
                    pendingPlayerItem = nextUp
                } else if viewModel.canPlay {
                    pendingPlayerItem = item
                }
            },
            onWatchlist: {
                Task { await viewModel.toggleWatchlist() }
            },
            onMore: {
                showMoreOptions = true
            }
        )
        #if os(tvOS)
        .prefersDefaultFocus(true, in: detailFocusNamespace)
        .focusSection()
        #endif
    }

    // MARK: - Crew Section (Directors & Writers)

    // MARK: - Genres Section

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Genres")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(OpenFlixColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.effectiveGenres.prefix(5), id: \.self) { genre in
                        Text(genre)
                            .font(.subheadline)
                            .foregroundColor(OpenFlixColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(OpenFlixColors.surface)
                            .cornerRadius(OpenFlixColors.cornerRadiusSmall)
                    }
                }
            }
        }
    }

    // MARK: - Crew Section (Enhanced with TMDB fallback)

    private var crewSectionEnhanced: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Directors (from server or TMDB)
            if !viewModel.effectiveDirectors.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("Directed by:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(OpenFlixColors.textTertiary)
                        .frame(width: 110, alignment: .leading)

                    Text(viewModel.effectiveDirectors.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)
                        .lineLimit(2)
                }
            }

            // Writers (from server)
            if let item = viewModel.mediaItem, !item.writers.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("Written by:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(OpenFlixColors.textTertiary)
                        .frame(width: 110, alignment: .leading)

                    Text(item.writers.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private func crewSection(_ item: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Directors
            if !item.directors.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("Directed by:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(OpenFlixColors.textTertiary)
                        .frame(width: 110, alignment: .leading)

                    Text(item.directors.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)
                        .lineLimit(2)
                }
            }

            // Writers
            if !item.writers.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("Written by:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(OpenFlixColors.textTertiary)
                        .frame(width: 110, alignment: .leading)

                    Text(item.writers.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(OpenFlixColors.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Cast Section

    private func castSection(_ roles: [CastMember]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section divider with title
            HStack {
                Text("Cast & Crew")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(OpenFlixColors.textPrimary)

                Rectangle()
                    .fill(OpenFlixColors.textTertiary)
                    .frame(height: 1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: isCompact ? 12 : 20) {
                    ForEach(roles.prefix(12)) { member in
                        CastMemberCard(member: member, compact: isCompact)
                    }
                }
            }
        }
    }

    // MARK: - Seasons Section

    private var seasonsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Season picker with diamond
            SeasonPicker(
                seasons: viewModel.seasons,
                selectedSeason: $viewModel.selectedSeason,
                onSeasonChange: { season in
                    Task { await viewModel.selectSeason(season) }
                }
            )

            // Episodes grid
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(viewModel.episodes) { episode in
                        EpisodeCard(episode: episode) {
                            pendingPlayerItem = episode
                        }
                    }
                }
            }
        }
    }

    // MARK: - Related Section

    private var relatedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Related", showChevron: true)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 24) {
                    ForEach(viewModel.relatedItems) { item in
                        MediaCard(item: item, showProgress: false)
                    }
                }
            }
        }
    }
}

// MARK: - Cast Member Card

struct CastMemberCard: View {
    let member: CastMember
    var compact: Bool = false

    @FocusState private var isFocused: Bool

    private var photoSize: CGFloat { compact ? 64 : 100 }
    private var cardWidth: CGFloat { compact ? 80 : 120 }

    var body: some View {
        Button(action: {}) {
            VStack(spacing: compact ? 6 : 12) {
                // Circular photo
                if member.thumb != nil {
                    AuthenticatedImage(path: member.thumb, systemPlaceholder: "person.circle.fill")
                        .aspectRatio(contentMode: .fill)
                        .frame(width: photoSize, height: photoSize)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(OpenFlixColors.surfaceElevated)
                        .frame(width: photoSize, height: photoSize)
                        .overlay(
                            Text(String(member.name.prefix(1)).uppercased())
                                .font(compact ? .body : .title)
                                .fontWeight(.bold)
                                .foregroundColor(OpenFlixColors.textSecondary)
                        )
                }

                // Name
                Text(member.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isFocused ? OpenFlixColors.accent : OpenFlixColors.textPrimary)
                    .lineLimit(1)

                // Role
                if let role = member.role {
                    Text(role)
                        .font(.caption2)
                        .foregroundColor(OpenFlixColors.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: cardWidth)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: OpenFlixColors.animationFast), value: isFocused)
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

// MARK: - Player Window Manager
// Presents the player in a completely independent UIWindow so SwiftUI rotation
// events can never dismiss it. The window sits above all SwiftUI hierarchy.

final class PlayerWindowManager: NSObject {
    static let shared = PlayerWindowManager()

    private var playerWindow: UIWindow?
    private var containerVC: PlayerContainerViewController?

    func present(mediaItem: MediaItem, in windowScene: UIWindowScene) {
        present(playerView: VideoPlayerView(mediaItem: mediaItem), in: windowScene)
    }

    func present(playerView: VideoPlayerView, in windowScene: UIWindowScene) {
        guard playerWindow == nil else { return } // Already presenting

        let container = PlayerContainerViewController()
        container.onWindowDismiss = { [weak self] in
            self?.playerWindow?.isHidden = true
            self?.playerWindow = nil
            self?.containerVC = nil
        }

        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = UIWindow.Level.alert + 1
        window.rootViewController = container
        window.makeKeyAndVisible()

        playerWindow = window
        containerVC = container

        let hosting = UIHostingController(rootView: playerView)
        hosting.modalPresentationStyle = .overFullScreen

        container.present(hosting, animated: true)
    }
}

// Container VC whose dismiss() is intercepted to hide the window instead
final class PlayerContainerViewController: UIViewController {
    var onWindowDismiss: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        // UIKit forwards dismiss() here when the presented UIHostingController
        // (VideoPlayerView) calls SwiftUI's @Environment(\.dismiss) action.
        super.dismiss(animated: flag) { [weak self] in
            completion?()
            self?.onWindowDismiss?()
        }
    }
}

#if os(tvOS)
private struct TVMoreOptionsSheet: View {
    let onWatched: () -> Void
    let onUnwatched: () -> Void
    let onCancel: () -> Void

    @FocusState private var focusedOption: Option?

    private enum Option: Hashable {
        case watched
        case unwatched
        case cancel
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 16/255, green: 12/255, blue: 28/255),
                    Color(red: 27/255, green: 20/255, blue: 46/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Text("More Options")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Choose an action for this title.")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                VStack(spacing: 16) {
                    optionButton(
                        title: "Mark as Watched",
                        systemImage: "checkmark.circle.fill",
                        focus: .watched,
                        action: onWatched
                    )

                    optionButton(
                        title: "Mark as Unwatched",
                        systemImage: "arrow.uturn.backward.circle.fill",
                        focus: .unwatched,
                        action: onUnwatched
                    )

                    optionButton(
                        title: "Cancel",
                        systemImage: "xmark.circle.fill",
                        focus: .cancel,
                        action: onCancel
                    )
                }
                .focusSection()
            }
            .padding(40)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                focusedOption = .watched
            }
        }
    }

    private func optionButton(title: String, systemImage: String, focus: Option, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .bold))
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        focusedOption == focus
                            ? LinearGradient(
                                colors: [Color.white, Color(red: 230/255, green: 224/255, blue: 255/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .foregroundStyle(focusedOption == focus ? Color.black : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(focusedOption == focus ? Color.white : Color.white.opacity(0.14), lineWidth: focusedOption == focus ? 4 : 1.5)
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(focusedOption == focus ? Color.black.opacity(0.88) : .clear)
                    .frame(width: 8)
                    .padding(.vertical, 6)
                    .padding(.leading, 6)
            }
            .overlay(alignment: .trailing) {
                if focusedOption == focus {
                    Text("Selected")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.88), in: Capsule())
                        .padding(.trailing, 12)
                }
            }
            .shadow(color: focusedOption == focus ? Color.white.opacity(0.3) : .clear, radius: 20, y: 8)
            .scaleEffect(focusedOption == focus ? 1.05 : 1.0)
            .opacity(focusedOption == focus ? 1.0 : 0.86)
            .animation(.easeInOut(duration: 0.18), value: focusedOption)
        }
        .buttonStyle(.plain)
        .focused($focusedOption, equals: focus)
    }
}
#endif

// MARK: - Preview

#Preview {
    MediaDetailView(mediaId: 1)
}
