@MainActor
final class FavouritesViewModel {
    private let store = FavouriteStore()
    private(set) var photos: [Photo] = []

    func loadPhotos() throws {
        photos = try store.fetchPhotos()
    }

    func removePhoto(withID id: String) throws {
        try store.remove(photoID: id)
        photos.removeAll { $0.id == id }
    }
}
