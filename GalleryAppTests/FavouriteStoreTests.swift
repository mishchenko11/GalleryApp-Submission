import CoreData
import Foundation
import Testing
@testable import GalleryApp

@Test
@MainActor
func testSavedPhotoCanBeReadAndRemovedAfterReopeningStore() throws {
    let model = PersistenceController.shared.container.managedObjectModel
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    
    let storeURL = directory.appendingPathComponent("Favourites.sqlite")
    let small = try #require(URL(string: "https://example.invalid/thumbnail"))
    let regular = try #require(URL(string: "https://example.invalid/regular"))
    let photo = Photo(id: "saved-photo", description: "A saved photo", urls: .init(small: small, regular: regular))
    
    do {
        let store = try openStore(model: model, at: storeURL)
        #expect(try store.toggle(photo))
    }
    
    do {
        let store = try openStore(model: model, at: storeURL)
        let savedPhotos = try store.fetchPhotos()
        #expect(savedPhotos.map(\.id) == [photo.id])
        let saved = try #require(savedPhotos.first)
        #expect(saved.description == photo.description)
        #expect(saved.urls.small == small)
        #expect(saved.urls.regular == regular)
        
        try store.remove(photoID: photo.id)
        try store.remove(photoID: photo.id)
    }
    
    let reopenedStore = try openStore(model: model, at: storeURL)
    let isSaved = try reopenedStore.isFavourite(photo.id)
    #expect(!isSaved)
    #expect(try reopenedStore.fetchPhotos().isEmpty)
}

@MainActor
private func openStore(model: NSManagedObjectModel, at url: URL) throws -> FavouriteStore {
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    _ = try coordinator.addPersistentStore(type: .sqlite, at: url)
    
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    return FavouriteStore(context: context)
}

