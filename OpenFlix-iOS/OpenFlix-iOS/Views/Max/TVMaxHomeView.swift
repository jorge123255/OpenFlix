#if os(tvOS)
import SwiftUI

// MARK: - TV Max+ Home

struct TVMaxHomeView: View {
    @StateObject private var repo = MaxRepository()
    @State private var pushedDetail: TVMaxPushedDetail?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color(red: 12/255, green: 4/255, blue: 24/255),
                             Color(red: 24/255, green: 8/255, blue: 36/255)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        if repo.hub != nil {
                            TVMaxPageRenderer(repo: repo) { entity, contentId in
                                pushedDetail = TVMaxPushedDetail(
                                    contentId: contentId,
                                    fallbackTitle: MXEntityMap.entityTitle(entity)
                                )
                            }
                        } else if repo.error != nil {
                            errorView
                        } else {
                            ProgressView().tint(.white).padding(.top, 80)
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
            .task {
                await repo.loadHub()
                await repo.loadStatus()
            }
            .navigationDestination(item: $pushedDetail) { d in
                TVMaxDetailView(contentId: d.contentId, fallbackTitle: d.fallbackTitle, repo: repo)
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40)).foregroundStyle(.orange)
            Text("Max unavailable").font(.system(size: 22, weight: .heavy)).foregroundStyle(.white)
            if let err = repo.error {
                Text(err).font(.system(size: 14)).foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center).padding(.horizontal, 60)
            }
            Button("Retry") { Task { await repo.loadHub(force: true) } }
                .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 999))
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity).padding(.top, 80)
    }
}

struct TVMaxPushedDetail: Hashable, Identifiable {
    let contentId: String
    let fallbackTitle: String
    var id: String { contentId }
}
#endif
