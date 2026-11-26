import CoreData
import Foundation
import XCTest
@testable import GalleryApp

final class FavouriteStoreTests: XCTestCase {
    @MainActor
    func testSavedPhotoCanBeReadAndRemovedAfterReopeningStore() throws {
        let model = PersistenceController.shared.container.managedObjectModel
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appendingPathComponent("Favourites.sqlite")
        let small = try XCTUnwrap(URL(string: "https://example.invalid/thumbnail"))
        let regular = try XCTUnwrap(URL(string: "https://example.invalid/regular"))
        let photo = Photo(id: "saved-photo", description: "A saved photo", urls: .init(small: small, regular: regular))

        do {
            let store = try openStore(model: model, at: storeURL)
            XCTAssertTrue(try store.toggle(photo))
        }

        do {
            let store = try openStore(model: model, at: storeURL)
            let savedPhotos = try store.fetchPhotos()
            XCTAssertEqual(savedPhotos.map(\.id), [photo.id])
            let saved = try XCTUnwrap(savedPhotos.first)
            XCTAssertEqual(saved.description, photo.description)
            XCTAssertEqual(saved.urls.small, small)
            XCTAssertEqual(saved.urls.regular, regular)

            try store.remove(photoID: photo.id)
            try store.remove(photoID: photo.id)
        }

        let reopenedStore = try openStore(model: model, at: storeURL)
        XCTAssertTrue(try reopenedStore.fetchPhotos().isEmpty)
        XCTAssertFalse(try reopenedStore.isFavourite(photo.id))
    }

    @MainActor
    private func openStore(model: NSManagedObjectModel, at url: URL) throws -> FavouriteStore {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        _ = try coordinator.addPersistentStore(type: .sqlite, at: url)

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return FavouriteStore(context: context)
    }
}
