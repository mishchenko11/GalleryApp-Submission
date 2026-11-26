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

    func image(from url: URL) async throws -> UIImage {
        try Task.checkCancellation()
        let cacheKey = url as NSURL

        if let image = cache.object(forKey: cacheKey) {
            return image
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        cache.setObject(image, forKey: cacheKey)
        return image
    }
}
