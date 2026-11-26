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
        case invalidResponse
        case httpStatus(Int)
    }
    
    func fetchFirstPage() async throws -> [Photo] {
        guard let key = ProcessInfo.processInfo.environment["UNSPLASH_ACCESS_KEY"],
              !key.isEmpty else {
            throw RequestError.missingAccessKey
        }
        
        let url = URL(string: "https://api.unsplash.com/photos?page=1&per_page=30")!
        var request = URLRequest(url: url)
        request.setValue("Client-ID \(key)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw RequestError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw RequestError.httpStatus(http.statusCode)
        }
        
        return try JSONDecoder().decode([Photo].self, from: data)
    }
}
