import SwiftUI

// MARK: - Max page renderer (iPhone)
//
// Walks Max's JSON:API home tree (route → page → items[] → collections),
// renders the hero collection (component.id == "hero" or templateId ==
// "immersive") plus rails for the rest. Inline-resolved collections
// render immediately; missing ones lazy-fetch via /max/explore/collection/:id
// on row appear.

struct MaxPageRenderer: View {
    @ObservedObject var repo: MaxRepository
    let onSelect: (_ entity: MXEntity, _ contentId: String) -> Void

    private var orderedIds: [String] {
        MXEntityMap.orderedCollectionIds(repo.hub)
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            if let heroId = orderedIds.first(where: isHero(id:)),
               let heroResp = repo.collection(for: heroId) {
                MaxHeroBanner(collection: heroResp, onSelect: onSelect)
                    .padding(.horizontal, 16)
            }
            ForEach(orderedIds.filter { !isHero(id: $0) }, id: \.self) { id in
                MaxRowView(collectionId: id, repo: repo, onSelect: onSelect)
            }
        }
    }

    private func isHero(id: String) -> Bool {
        guard let resp = repo.collection(for: id) else { return false }
        return MXEntityMap.isHeroCollection(resp.data)
    }
}

// MARK: Hero

private struct MaxHeroBanner: View {
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
                    .frame(maxWidth: .infinity).frame(height: 240).clipped()
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.06, blue: 0.30),
                                 Color(red: 0.20, green: 0.10, blue: 0.45)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(height: 240)
                }
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.85)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 240)
                VStack(alignment: .leading, spacing: 6) {
                    Text(MXEntityMap.attrString(collection.data, "title")
                         ?? MXEntityMap.attrString(collection.data, "name")
                         ?? "Featured")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .tracking(2)
                    Text(title)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    if let desc {
                        Text(desc)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                }
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: Row

private struct MaxRowView: View {
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

    private var items: [MXEntity] {
        MXEntityMap.collectionItems(response)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)

            if items.isEmpty && repo.loadingCollections.contains(collectionId) {
                HStack { ProgressView().tint(.white); Spacer() }
                    .padding(.horizontal, 16)
            } else if items.isEmpty, let err = repo.collectionErrors[collectionId] {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.horizontal, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(items) { entity in
                            Button {
                                if let contentId = MXEntityMap.contentId(entity) {
                                    onSelect(entity, contentId)
                                }
                            } label: {
                                MaxTile(entity: entity, response: response)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear {
            guard !didRequestLoad else { return }
            didRequestLoad = true
            if response == nil {
                Task { await repo.loadCollection(id: collectionId) }
            }
        }
    }
}

// MARK: Tile

private struct MaxTile: View {
    let entity: MXEntity
    let response: MXExploreCollectionResponse?

    var body: some View {
        let map = MXEntityMap.build(response)
        let imageUrl = MXEntityMap.entityImage(entity, in: map, immersive: false)
        let title = MXEntityMap.entityTitle(entity)
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                if let s = imageUrl, let url = URL(string: s) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.white.opacity(0.06)
                    }
                    .frame(width: 168, height: 95)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 168, height: 95)
                        .overlay(
                            Text(title)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(6)
                        )
                }
            }
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(width: 168, alignment: .leading)
        }
    }
}
