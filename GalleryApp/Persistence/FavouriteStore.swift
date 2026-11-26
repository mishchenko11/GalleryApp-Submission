//
//  FavouriteStore.swift
//  GalleryApp
//
//  Created by Irina on 24.11.26.
//

import CoreData
import Foundation

@MainActor
struct FavouriteStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext? = nil) {
        self.context = context ?? PersistenceController.shared.container.viewContext
    }

    func isFavourite(_ photoID: String) throws -> Bool {
        try find(photoID: photoID) != nil
    }

    func favouriteIDs() throws -> Set<String> {
        let request = FavouritePhoto.fetchRequest()
        return Set(try context.fetch(request).compactMap { $0.photoID })
    }

    func fetchPhotos() throws -> [Photo] {
        let request = FavouritePhoto.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "photoID", ascending: true)]

        return try context.fetch(request).compactMap { record in
            guard let id = record.photoID,
                  let smallURL = record.smallURL, let small = URL(string: smallURL),
                  let regularURL = record.regularURL, let regular = URL(string: regularURL) else {
                return nil
            }

            return Photo(id: id, description: record.photoDescription, urls: .init(small: small, regular: regular))
        }
    }

    func remove(photoID: String) throws {
        guard let record = try find(photoID: photoID) else { return }
        context.delete(record)
        try saveChanges()
    }

    func toggle(_ photo: Photo) throws -> Bool {
        let isSaved: Bool

        if let existing = try find(photoID: photo.id) {
            context.delete(existing)
            isSaved = false
        } else {
            let record = FavouritePhoto(context: context)
            record.photoID = photo.id
            record.photoDescription = photo.description
            record.smallURL = photo.urls.small.absoluteString
            record.regularURL = photo.urls.regular.absoluteString
            isSaved = true
        }
        try saveChanges()
        return isSaved
    }

    private func saveChanges() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func find(photoID: String) throws -> FavouritePhoto? {
        let request = FavouritePhoto.fetchRequest()
        request.predicate = NSPredicate(format: "photoID == %@", photoID)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
