//
//  ImageLoader.swift
//  GalleryApp
//
//  Created by Irina on 24.11.26.
//

import Foundation
import UIKit

@MainActor
final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 40
    }

    func image(for photo: Photo, thumbnail: Bool) async throws -> UIImage {
        if let image = await FavouritePhotos.shared.localImage(for: photo, thumbnail: thumbnail) {
            return image
        }
        try Task.checkCancellation()

        let url = thumbnail ? photo.urls.small : photo.urls.regular
        let cacheKey = url as NSURL

        if let image = cache.object(forKey: cacheKey) {
            return image
        }

        let data = try await Self.download(url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        cache.setObject(image, forKey: cacheKey)
        return image
    }

    nonisolated static func download(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
