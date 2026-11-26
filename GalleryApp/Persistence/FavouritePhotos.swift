import Foundation
import UIKit

@MainActor
final class FavouritePhotos {
    static let didChange = Notification.Name("FavouritePhotos.didChange")
    static let shared = FavouritePhotos(store: FavouriteStore(), images: FavouriteImageStore())

    private let store: FavouriteStore
    private let images: FavouriteImageStore
    private let download: (URL) async throws -> Data
    private var updating: Set<String> = []
    private var backfilling: Set<String> = []

    init(
        store: FavouriteStore,
        images: FavouriteImageStore,
        download: @escaping (URL) async throws -> Data = ImageLoader.download
    ) {
        self.store = store
        self.images = images
        self.download = download
    }

    func toggle(_ photo: Photo) async throws -> Bool? {
        guard updating.insert(photo.id).inserted else { return nil }
        defer { updating.remove(photo.id) }

        if try store.isFavourite(photo.id) {
            try store.remove(photoID: photo.id)
            await removeImage(for: photo.id)
            NotificationCenter.default.post(name: Self.didChange, object: self)
            return false
        }

        let data = try await download(photo.urls.regular)
        try Task.checkCancellation()
        try await images.save(data, for: photo.id)

        do {
            let isSaved = try store.toggle(photo)
            NotificationCenter.default.post(name: Self.didChange, object: self)
            return isSaved
        } catch {
            await removeImage(for: photo.id)
            throw error
        }
    }

    func remove(_ photoID: String) async throws -> Bool {
        guard updating.insert(photoID).inserted else { return false }
        defer { updating.remove(photoID) }

        try store.remove(photoID: photoID)
        await removeImage(for: photoID)
        NotificationCenter.default.post(name: Self.didChange, object: self)
        return true
    }

    func localImage(for photo: Photo, thumbnail: Bool) async -> UIImage? {
        guard (try? store.isFavourite(photo.id)) == true else { return nil }
        if let image = await images.image(for: photo.id, thumbnail: thumbnail) {
            return image
        }
        guard !Task.isCancelled, !updating.contains(photo.id),
              backfilling.insert(photo.id).inserted else { return nil }
        defer { backfilling.remove(photo.id) }

        do {
            let data = try await download(photo.urls.regular)
            try Task.checkCancellation()
            guard try store.isFavourite(photo.id),
                  updating.insert(photo.id).inserted else { return nil }
            defer { updating.remove(photo.id) }
            try await images.save(data, for: photo.id)
            return await images.image(for: photo.id, thumbnail: thumbnail)
        } catch {
            return nil
        }
    }

    private func removeImage(for photoID: String) async {
        do {
            try await images.remove(for: photoID)
        } catch {
            print("Could not remove the local favourite image:", error)
        }
    }
}
