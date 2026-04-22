import SwiftUI

// MARK: - Disney Search
//
// Server-side search through `/api/tuner-backends/active/disney/explore/search`.
// Results come back as a Disney page; reuse the shared page renderer.

struct DisneySearchView: View {
    @ObservedObject var repo: DisneyExploreRepository
    @State private var query = ""
    @State private var page: DXPage?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var pushedDetail: DisneyHomePushedDetail?
    @State private var pushedPage: DisneyHomePushedPage?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.6))
                TextField("Search Disney+", text: $query)
                    .foregroundStyle(.white)
                    .submitLabel(.search)
                    .onSubmit { Task { await search() } }
                    .textFieldStyle(.plain)
                if !query.isEmpty {
                    Button { query = ""; page = nil } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16).padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let page {
                        DisneyPageRenderer(
                            page: page,
                            repo: repo,
                            onOpenDetail: { item, container in
                                pushedDetail = DisneyHomePushedDetail(item: item, container: container)
                            },
                            onPlayEvent: { item, container in
                                pushedDetail = DisneyHomePushedDetail(item: item, container: container)
                            },
                            onOpenPage: { target, label in
                                pushedPage = DisneyHomePushedPage(target: target, label: label)
                            }
                        )
                    } else if isLoading {
                        ProgressView().tint(.white).padding(.top, 40)
                    } else if let loadError {
                        Text(loadError).foregroundStyle(.red).padding()
                    } else if !query.isEmpty {
                        Text("No results")
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 60)
                    }
                }
                .padding(.bottom, 60)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(red: 8/255, green: 12/255, blue: 28/255).ignoresSafeArea())
        .navigationTitle("Search")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") { dismiss() }.foregroundStyle(.white)
            }
        }
        .navigationDestination(item: $pushedPage) { p in
            DisneySubPageView(target: p.target, title: p.label, repo: repo, onPlayEvent: { _, _ in })
        }
        .navigationDestination(item: $pushedDetail) { d in
            DisneyDetailView(item: d.item, container: d.container, repo: repo,
                             onPlayEvent: { _, _, _ in })
        }
    }

    private func search() async {
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
