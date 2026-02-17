import SwiftUI

/// Sports scores overlay widget for Live TV
struct SportsOverlayView: View {
    @ObservedObject var viewModel: SportsOverlayViewModel

    var body: some View {
        if viewModel.isVisible && !viewModel.games.isEmpty {
            VStack(alignment: .trailing, spacing: 8) {
                ForEach(viewModel.games) { game in
                    GameScoreCard(game: game, isFavorite: isFavorite(game))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.85))
            )
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }

    private func isFavorite(_ game: LiveGame) -> Bool {
        viewModel.favoriteTeams.contains(game.homeTeam.code) ||
        viewModel.favoriteTeams.contains(game.awayTeam.code)
    }
}

struct GameScoreCard: View {
    let game: LiveGame
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Sport icon
            sportIcon
                .font(.system(size: 16))
                .foregroundColor(sportColor)

            // Teams and scores
            VStack(alignment: .leading, spacing: 2) {
                // Away team
                HStack(spacing: 8) {
                    Text(game.awayTeam.code)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(game.awayScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                // Home team
                HStack(spacing: 8) {
                    Text(game.homeTeam.code)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(game.homeScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 80)

            // Status
            VStack(alignment: .trailing, spacing: 2) {
                if game.isLive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text(game.clock)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                    Text(game.period)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                } else {
                    Text(game.status.uppercased())
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            // Close game indicator
            if game.isClose {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 12))
            }

            // Favorite indicator
            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(game.isClose ? Color.yellow.opacity(0.15) : Color.white.opacity(0.1))
        )
    }

    private var sportIcon: some View {
        switch game.sport {
        case "nfl", "ncaaf":
            return Image(systemName: "sportscourt")
        case "nba", "ncaab":
            return Image(systemName: "basketball")
        case "mlb":
            return Image(systemName: "baseball")
        case "nhl":
            return Image(systemName: "hockey.puck")
        default:
            return Image(systemName: "sportscourt")
        }
    }

    private var sportColor: Color {
        switch game.sport {
        case "nfl": return .green
        case "nba": return .orange
        case "mlb": return .red
        case "nhl": return .blue
        case "ncaaf": return .green
        case "ncaab": return .orange
        default: return .white
        }
    }
}

// MARK: - Preview

struct SportsOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    SportsOverlayView(viewModel: {
                        let vm = SportsOverlayViewModel()
                        // Mock data would go here
                        return vm
                    }())
                    .frame(width: 280)
                }
            }
            .padding()
        }
    }
}
