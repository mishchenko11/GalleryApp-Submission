@MainActor
final class FavouritesViewModel {
    private let store = FavouriteStore()
    private(set) var photos: [Photo] = []

    func loadPhotos() throws {
        photos = try store.fetchPhotos()
    }

    func removePhoto(withID id: String) async throws {
        _ = try await FavouritePhotos.shared.remove(id)
    }
}
