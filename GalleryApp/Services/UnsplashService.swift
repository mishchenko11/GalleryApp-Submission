//
//  UnsplashService.swift
//  GalleryApp
//
//  Created by Irina on 23.11.26.
//

import Foundation

struct UnsplashService {
    enum RequestError: Error {
        case missingAccessKey
        case invalidURL
        case invalidResponse
        case httpStatus(Int)
    }
    
    struct Page {
        let photos: [Photo]
        let hasNextPage: Bool
    }

    func fetchPage(_ page: Int) async throws -> Page {
        let key = Constants.unsplashAccessKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, key != Constants.unsplashAccessKeyPlaceholder else {
            throw RequestError.missingAccessKey
        }
        
        guard let url = URL(string: "https://api.unsplash.com/photos?page=\(page)&per_page=30") else {
            throw RequestError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("Client-ID \(key)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw RequestError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw RequestError.httpStatus(http.statusCode)
        }
        
        let photos = try JSONDecoder().decode([Photo].self, from: data)
        let link = http.value(forHTTPHeaderField: "Link")
        let hasNextPage = link?.contains("rel=\"next\"") == true

        return Page(photos: photos, hasNextPage: hasNextPage)
    }
}
