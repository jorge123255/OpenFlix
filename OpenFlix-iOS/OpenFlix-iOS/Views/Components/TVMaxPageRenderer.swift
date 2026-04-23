#if os(tvOS)
import SwiftUI

// MARK: - TV Max+ page renderer
//
// 10-foot focus-aware version of MaxPageRenderer. Same hub walk
// (route → page → items → collection refs). Hero collection becomes
// a big focusable banner; other collections become focus-section
// rails. Lazy-load via /max/explore/collection/:id on row appear.

struct TVMaxPageRenderer: View {
    @ObservedObject var repo: MaxRepository
    let onSelect: (_ entity: MXEntity, _ contentId: String) -> Void

    private var orderedIds: [String] {
        MXEntityMap.orderedCollectionIds(repo.hub)
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 36) {
            if let heroId = orderedIds.first(where: isHero(id:)),
               let heroResp = repo.collection(for: heroId) {
                TVMaxHeroBanner(collection: heroResp, onSelect: onSelect)
                    .padding(.horizontal, 56)
            }
            ForEach(orderedIds.filter { !isHero(id: $0) }, id: \.self) { id in
                TVMaxRailView(collectionId: id, repo: repo, onSelect: onSelect)
            }
        }
    }

    private func isHero(id: String) -> Bool {
        guard let resp = repo.collection(for: id) else { return false }
        return MXEntityMap.isHeroCollection(resp.data)
    }
}

private struct TVMaxHeroBanner: View {
    let collection: MXExploreCollectionResponse
    let onSelect: (_ entity: MXEntity, _ contentId: String) -> Void

    private var heroItem: MXEntity? {
        MXEntityMap.collectionItems(collection).first
    }

    var body: some View {
        let map = MXEntityMap.build(collection)
        let item = heroItem
        let imageUrl = MXEntityMap.entityImage(item, in: map, immersive: true)
        let title = MXEntityMap.entityTitle(item)
        let desc = MXEntityMap.entityDescription(item)

        Button {
            if let item, let contentId = MXEntityMap.contentId(item) {
                onSelect(item, contentId)
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let s = imageUrl, let url = URL(string: s) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.black.opacity(0.4)
                    }
                    .frame(maxWidth: .infinity).frame(height: 480).clipped()
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.06, blue: 0.30),
                                 Color(red: 0.20, green: 0.10, blue: 0.45)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(height: 480)
                }
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.85)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 480)
                VStack(alignment: .leading, spacing: 10) {
                    Text(MXEntityMap.attrString(collection.data, "title")
                         ?? MXEntityMap.attrString(collection.data, "name") ?? "Featured")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white).tracking(2.5)
                    Text(title)
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(.white).lineLimit(2)
                    if let desc {
                        Text(desc)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(3)
                            .frame(maxWidth: 760, alignment: .leading)
                    }
                }
                .padding(34)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 22))
    }
}

private struct TVMaxRailView: View {
    let collectionId: String
    @ObservedObject var repo: MaxRepository
    let onSelect: (_ entity: MXEntity, _ contentId: String) -> Void

    @State private var didRequestLoad = false

    private var response: MXExploreCollectionResponse? {
        repo.collection(for: collectionId)
    }
    private var title: String {
        MXEntityMap.attrString(response?.data, "title")
            ?? MXEntityMap.attrString(response?.data, "name")
            ?? "Collection"
    }
    private var items: [MXEntity] { MXEntityMap.collectionItems(response) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 56)

            if items.isEmpty && repo.loadingCollections.contains(collectionId) {
                HStack { ProgressView().tint(.white); Spacer() }.padding(.horizontal, 56)
            } else if items.isEmpty, let err = repo.collectionErrors[collectionId] {
                Text(err).font(.system(size: 16)).foregroundStyle(.red.opacity(0.8))
                    .padding(.horizontal, 56)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 18) {
                        ForEach(items) { entity in
                            Button {
                                if let contentId = MXEntityMap.contentId(entity) {
                                    onSelect(entity, contentId)
                                }
                            } label: {
                                TVMaxTile(entity: entity, response: response)
                            }
                            .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 56)
                    .padding(.vertical, 12)
                }
            }
        }
        .focusSection()
        .onAppear {
            guard !didRequestLoad else { return }
            didRequestLoad = true
            if response == nil {
                Task { await repo.loadCollection(id: collectionId) }
            }
        }
    }
}

private struct TVMaxTile: View {
    let entity: MXEntity
    let response: MXExploreCollectionResponse?
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        let map = MXEntityMap.build(response)
        let imageUrl = MXEntityMap.entityImage(entity, in: map, immersive: false)
        let title = MXEntityMap.entityTitle(entity)
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let s = imageUrl, let url = URL(string: s) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.white.opacity(0.06)
                    }
                    .frame(width: 320, height: 180)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 320, height: 180)
                        .overlay(
                            Text(title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(8)
                        )
                }
            }
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isFocused ? .white : .white.opacity(0.85))
                .lineLimit(2)
                .frame(width: 320, alignment: .leading)
        }
    }
}
#endif
