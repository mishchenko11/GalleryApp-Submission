import CoreData
import Foundation
import Testing
import UIKit
@testable import GalleryApp

@Test
@MainActor
func testFavouriteThumbnailAndDetailCanBeReadOfflineAfterReopening() async throws {
    let directory = try makeTestDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let photo = try makeTestPhoto()
    let data = try makeTestImage()
    let imageDirectory = directory.appending(path: "Images")
    let database = directory.appending(path: "Favourites.sqlite")

    do {
        let context = try makeContext(database: database)
        let favourites = FavouritePhotos(
            store: FavouriteStore(context: context),
            images: FavouriteImageStore(directory: imageDirectory),
            download: { url in
                #expect(url == photo.urls.regular)
                return data
            }
        )
        #expect(try await favourites.toggle(photo) == true)
        try closeStore(in: context)
    }

    let context = try makeContext(database: database)
    defer { try? closeStore(in: context) }
    let store = FavouriteStore(context: context)
    let disk = FavouriteImageStore(directory: imageDirectory)
    let favourites = FavouritePhotos(store: store, images: disk, download: { _ in
        Issue.record("Opening a saved photo should use its local image.")
        throw URLError(.notConnectedToInternet)
    })

    let saved = try #require(try store.fetchPhotos().first)
    #expect(saved.id == photo.id)
    let fullImage = try #require(await favourites.localImage(for: saved, thumbnail: false))
    let thumbnail = try #require(await favourites.localImage(for: saved, thumbnail: true))
    #expect(fullImage.size.width == 700)
    #expect(thumbnail.size.width == 512)
    #expect(try await favourites.remove(photo.id))
    #expect(try store.fetchPhotos().isEmpty)
    #expect(await disk.image(for: photo.id, thumbnail: false) == nil)
}

@Test
@MainActor
func testExistingFavouriteGetsALocalCopyAndInvalidImagesAreNotSaved() async throws {
    let directory = try makeTestDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let photo = try makeTestPhoto()
    let data = try makeTestImage()
    let context = try makeContext(database: directory.appending(path: "Favourites.sqlite"))
    defer { try? closeStore(in: context) }
    let store = FavouriteStore(context: context)
    let disk = FavouriteImageStore(directory: directory.appending(path: "Images"))
    let favourites = FavouritePhotos(store: store, images: disk, download: { _ in data })

    #expect(try store.toggle(photo))
    #expect(await disk.image(for: photo.id, thumbnail: false) == nil)
    #expect(await favourites.localImage(for: photo, thumbnail: true) != nil)
    #expect(await disk.image(for: photo.id, thumbnail: false) != nil)
    #expect(try await favourites.toggle(photo) == false)

    let invalidImageFavourites = FavouritePhotos(store: store, images: disk, download: { _ in Data() })
    await #expect(throws: URLError.self) { try await invalidImageFavourites.toggle(photo) }
    #expect(try !store.isFavourite(photo.id))
    #expect(await disk.image(for: photo.id, thumbnail: false) == nil)
}

private func makeTestDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

private func makeTestPhoto() throws -> Photo {
    let small = try #require(URL(string: "https://example.invalid/thumbnail"))
    let regular = try #require(URL(string: "https://example.invalid/regular"))
    return Photo(id: "saved-photo", description: "Test photo", urls: .init(small: small, regular: regular))
}

@MainActor
private func makeTestImage() throws -> Data {
    let size = CGSize(width: 700, height: 550)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
        UIColor.red.setFill()
        renderer.fill(CGRect(origin: .zero, size: size))
    }
    return try #require(image.pngData())
}

@MainActor
private func makeContext(database: URL) throws -> NSManagedObjectContext {
    let model = PersistenceController.shared.container.managedObjectModel
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    _ = try coordinator.addPersistentStore(type: .sqlite, at: database)
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    return context
}

@MainActor
private func closeStore(in context: NSManagedObjectContext) throws {
    context.reset()
    guard let coordinator = context.persistentStoreCoordinator,
          let store = coordinator.persistentStores.first else { return }
    try coordinator.remove(store)
}
