import SwiftUI

// MARK: - Max+ Search (iPhone)
//
// /max/explore/search?q=...&size=30 returns a flat list of
// MXSearchResult. Tap → MaxDetailView with the result's id.

struct MaxSearchView: View {
    @ObservedObject var repo: MaxRepository
    @State private var query = ""
    @State private var results: [MXSearchResult] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var pushedDetail: MaxPushedDetail?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.6))
                TextField("Search Max", text: $query)
                    .foregroundStyle(.white)
                    .submitLabel(.search)
                    .onSubmit { Task { await search() } }
                    .textFieldStyle(.plain)
                if !query.isEmpty {
                    Button { query = ""; results = [] } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16).padding(.top, 12)

            ScrollView {
                LazyVStack(spacing: 8) {
                    if isLoading {
                        ProgressView().tint(.white).padding(.top, 40)
                    } else if let loadError {
                        Text(loadError).foregroundStyle(.red).padding()
                    } else if !query.isEmpty && results.isEmpty {
                        Text("No results").foregroundStyle(.white.opacity(0.5)).padding(.top, 40)
                    } else {
                        ForEach(results) { result in
                            Button {
                                if let id = result.id {
                                    pushedDetail = MaxPushedDetail(contentId: id,
                                                                   fallbackTitle: result.title ?? "Result")
                                }
                            } label: {
                                MaxSearchRow(result: result)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 16)
                .padding(.bottom, 60)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(red: 12/255, green: 4/255, blue: 24/255).ignoresSafeArea())
        .navigationTitle("Search")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") { dismiss() }.foregroundStyle(.white)
            }
        }
        .navigationDestination(item: $pushedDetail) { d in
            MaxDetailView(contentId: d.contentId, fallbackTitle: d.fallbackTitle, repo: repo)
        }
    }

    private func search() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { results = []; return }
        isLoading = true
        defer { isLoading = false }
        loadError = nil
        do {
            results = try await repo.search(q)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct MaxSearchRow: View {
    let result: MXSearchResult

    var body: some View {
        HStack(spacing: 12) {
            if let s = result.imageUrl, let url = URL(string: s) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.white.opacity(0.06)
                }
                .frame(width: 110, height: 62)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 110, height: 62)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(result.title ?? "Untitled")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white).lineLimit(2)
                if let y = result.releaseYear {
                    Text(String(y))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                }
                if let desc = result.description {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                }
            }
            Spacer()
        }
    }
}
