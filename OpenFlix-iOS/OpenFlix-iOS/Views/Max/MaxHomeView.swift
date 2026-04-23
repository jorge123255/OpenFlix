import SwiftUI

// MARK: - Max+ Home (iPhone)
//
// Browse home for HBO Max. Reads /max/hub?inline=8 to get the route
// + page + inlined collections. Renders via MaxPageRenderer; tile
// taps push MaxDetailView. Search is a sheet.

struct MaxHomeView: View {
    @StateObject private var repo = MaxRepository()
    @State private var pushedDetail: MaxPushedDetail?
    @State private var showSearch = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if repo.hub != nil {
                    MaxPageRenderer(repo: repo) { entity, contentId in
                        pushedDetail = MaxPushedDetail(contentId: contentId,
                                                       fallbackTitle: MXEntityMap.entityTitle(entity))
                    }
                } else if repo.error != nil {
                    errorView
                } else {
                    ProgressView().tint(.white).frame(maxWidth: .infinity).padding(.top, 80)
                }
            }
            .padding(.bottom, 60)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 12/255, green: 4/255, blue: 24/255),
                         Color(red: 24/255, green: 8/255, blue: 36/255)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Max")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass").foregroundStyle(.white)
                }
            }
        }
        .task {
            await repo.loadHub()
            await repo.loadStatus()
        }
        .navigationDestination(item: $pushedDetail) { d in
            MaxDetailView(contentId: d.contentId, fallbackTitle: d.fallbackTitle, repo: repo)
        }
        .sheet(isPresented: $showSearch) {
            NavigationStack { MaxSearchView(repo: repo) }
        }
    }

    private var errorView: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32)).foregroundStyle(.orange)
            Text("Max unavailable").font(.headline).foregroundStyle(.white)
            if let err = repo.error {
                Text(err).font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center).padding(.horizontal, 28)
            }
            Button("Retry") { Task { await repo.loadHub(force: true) } }
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

struct MaxPushedDetail: Hashable, Identifiable {
    let contentId: String
    let fallbackTitle: String
    var id: String { contentId }
}
