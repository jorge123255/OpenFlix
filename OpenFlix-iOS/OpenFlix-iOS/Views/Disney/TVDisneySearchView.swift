#if os(tvOS)
import SwiftUI

// MARK: - TVDisneySearchView
//
// Apple TV Disney+ search. Server-side via /disney/explore/search.
// Result page rendered through TVDisneyPageRenderer.

struct TVDisneySearchView: View {
    @ObservedObject var repo: DisneyExploreRepository
    @State private var query = ""
    @State private var page: DXPage?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var pushedDetail: TVDisneyPushedDetail?
    @State private var pushedPage: TVDisneyPushedPage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                searchField
                    .padding(.top, 30)
                    .padding(.horizontal, 56)

                if let page {
                    TVDisneyPageRenderer(
                        page: page, repo: repo,
                        onOpenDetail: { i, c in pushedDetail = TVDisneyPushedDetail(item: i, container: c) },
                        onPlayEvent: { i, c in pushedDetail = TVDisneyPushedDetail(item: i, container: c) },
                        onOpenPage: { t, l in pushedPage = TVDisneyPushedPage(target: t, label: l) }
                    )
                } else if isLoading {
                    ProgressView().tint(.white).padding(.top, 40)
                } else if let loadError {
                    Text(loadError).foregroundStyle(.red).padding()
                } else if !query.isEmpty {
                    Text("No results")
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 40).padding(.horizontal, 56)
                }
            }
            .padding(.bottom, 80)
        }
        .background(Color(red: 6/255, green: 4/255, blue: 16/255).ignoresSafeArea())
        .navigationDestination(item: $pushedPage) { p in
            TVDisneySubPageView(target: p.target, title: p.label, repo: repo)
        }
        .navigationDestination(item: $pushedDetail) { d in
            TVDisneyDetailView(item: d.item, container: d.container, repo: repo)
        }
    }

    private var searchField: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
            TextField("Search Disney+", text: $query)
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .submitLabel(.search)
                .onSubmit { Task { await runSearch() } }
        }
        .padding(.horizontal, 22).padding(.vertical, 18)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func runSearch() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        loadError = nil
        do {
            page = try await repo.search(query: q)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
#endif
