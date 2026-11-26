//
//  Photo.swift
//  GalleryApp
//
//  Created by Irina on 23.11.26.
//

import Foundation

struct Photo: Decodable {
    let id: String
    let description: String?
    let urls: ImageURLs

    struct ImageURLs: Decodable {
        let small: URL
        let regular: URL
    }
}
