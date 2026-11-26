//
//  GalleryViewModel.swift
//  GalleryApp
//
//  Created by Irina on 23.11.26.
//

@MainActor
final class GalleryViewModel {
    private let service = UnsplashService()
    private(set) var photos: [Photo] = []
    
    func loadPhotos() async throws {
        photos = try await service.fetchFirstPage()
    }
}
