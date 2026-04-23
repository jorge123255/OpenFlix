#if os(tvOS)
import SwiftUI

struct TVMaxSearchView: View {
    @ObservedObject var repo: MaxRepository
    @State private var query = ""
    @State private var results: [MXSearchResult] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var pushedDetail: TVMaxPushedDetail?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 14) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                    TextField("Search Max", text: $query)
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .submitLabel(.search)
                        .onSubmit { Task { await search() } }
                }
                .padding(.horizontal, 22).padding(.vertical, 18)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 56).padding(.top, 30)

                LazyVStack(spacing: 14) {
                    if isLoading {
                        ProgressView().tint(.white).padding(.top, 40)
                    } else if let loadError {
                        Text(loadError).foregroundStyle(.red).padding()
                    } else if !query.isEmpty && results.isEmpty {
                        Text("No results")
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.top, 40).padding(.horizontal, 56)
                    } else {
                        ForEach(results) { result in
                            Button {
                                if let id = result.id {
                                    pushedDetail = TVMaxPushedDetail(
                                        contentId: id,
                                        fallbackTitle: result.title ?? "Result"
                                    )
                                }
                            } label: {
                                TVMaxSearchRow(result: result)
                            }
                            .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal, 56)
            }
            .padding(.bottom, 80)
        }
        .background(Color(red: 12/255, green: 4/255, blue: 24/255).ignoresSafeArea())
        .navigationDestination(item: $pushedDetail) { d in
            TVMaxDetailView(contentId: d.contentId, fallbackTitle: d.fallbackTitle, repo: repo)
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

private struct TVMaxSearchRow: View {
    let result: MXSearchResult

    var body: some View {
        HStack(spacing: 16) {
            if let s = result.imageUrl, let url = URL(string: s) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.white.opacity(0.06)
                }
                .frame(width: 200, height: 112)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 200, height: 112)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title ?? "Untitled")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white).lineLimit(2)
                if let y = result.releaseYear {
                    Text(String(y))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                }
                if let desc = result.description {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
#endif
