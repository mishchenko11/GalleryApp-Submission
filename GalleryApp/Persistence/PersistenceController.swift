//
//  PersistenceController.swift
//  GalleryApp
//
//  Created by Irina on 24.11.26.
//

import CoreData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "GalleryStore")
        container.loadPersistentStores { _, error in
            if let error {
                print("Core Data error:", error.localizedDescription)
            } else {
                print("Core Data store loaded")
            }
        }
    }
}
