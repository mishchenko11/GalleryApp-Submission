@MainActor
final class PhotoPagerViewModel {
    let selectedIndex: Int

    private let photos: [Photo]
    private let favouriteStore = FavouriteStore()

    init(photos: [Photo], selectedIndex: Int) {
        self.photos = photos
        self.selectedIndex = selectedIndex
    }

    func photo(at index: Int) -> Photo? {
        guard photos.indices.contains(index) else { return nil }
        return photos[index]
    }

    func isFavourite(_ photo: Photo) throws -> Bool {
        try favouriteStore.isFavourite(photo.id)
    }

    func toggleFavourite(_ photo: Photo) async throws {
        _ = try await FavouritePhotos.shared.toggle(photo)
    }
}
