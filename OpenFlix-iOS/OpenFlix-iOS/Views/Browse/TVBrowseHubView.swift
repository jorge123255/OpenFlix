#if os(tvOS)
import SwiftUI

// MARK: - tvOS Browse hub
//
// Mirrors the iPhone XfinityBrowseWrapper: a card grid of provider
// destinations (Disney+, Max, more later). Replaces the previous
// per-provider sidecar entries so the sidecar stays compact and
// users see all browse destinations in one place.

struct TVBrowseHubView: View {
    @State private var pushedDest: BrowseDestination?

    private let cards: [BrowseCard] = [
        BrowseCard(id: "disneyPlus",
                   title: "Disney+",
                   subtitle: "Movies, series, originals, and ESPN+ events",
                   gradient: [Color(red: 12/255, green: 18/255, blue: 60/255),
                              Color(red: 24/255, green: 36/255, blue: 100/255)],
                   icon: "sparkles"),
        BrowseCard(id: "max",
                   title: "Max",
                   subtitle: "HBO Max library, originals, and live channels",
                   gradient: [Color(red: 30/255, green: 8/255, blue: 60/255),
                              Color(red: 60/255, green: 20/255, blue: 100/255)],
                   icon: "play.rectangle.fill"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    Text("Browse")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 56)
                        .padding(.top, 60)
                    Text("Pick a destination")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 56)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 22),
                        GridItem(.flexible(), spacing: 22),
                    ], spacing: 22) {
                        ForEach(cards) { card in
                            Button {
                                pushedDest = BrowseDestination(id: card.id)
                            } label: {
                                cardLabel(card)
                            }
                            .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 22))
                        }
                    }
                    .padding(.horizontal, 56)
                    .focusSection()
                }
                .padding(.bottom, 80)
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 6/255, green: 4/255, blue: 16/255),
                             Color(red: 14/255, green: 8/255, blue: 28/255)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationDestination(item: $pushedDest) { dest in
                switch dest.id {
                case "disneyPlus": TVDisneyHomeView()
                case "max": TVMaxHomeView()
                default: Text(dest.id)
                }
            }
        }
    }

    private func cardLabel(_ card: BrowseCard) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: card.gradient,
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 240)
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: card.icon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(card.title)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(card.subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }
            .padding(28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct BrowseCard: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let icon: String
}

struct BrowseDestination: Hashable, Identifiable {
    let id: String
}
#endif
