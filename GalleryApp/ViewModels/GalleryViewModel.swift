//
//  GalleryViewModel.swift
//  GalleryApp
//
//  Created by Irina on 23.11.26.
//

@MainActor
final class GalleryViewModel {
    private let service = UnsplashService()
    private var nextPage: Int? = 1
    private var isLoading = false

    private(set) var photos: [Photo] = []

    func loadNextPage() async throws -> Bool {
        guard !isLoading else { return false }

        isLoading = true
        defer { isLoading = false }

        var knownIDs = Set(photos.map(\.id))
        while let pageNumber = nextPage {
            let page = try await service.fetchPage(pageNumber)
            nextPage = page.hasNextPage ? pageNumber + 1 : nil

            let newPhotos = page.photos.filter { knownIDs.insert($0.id).inserted }

            if !newPhotos.isEmpty {
                photos.append(contentsOf: newPhotos)
                return true
            }
        }

        return false
    }
}
