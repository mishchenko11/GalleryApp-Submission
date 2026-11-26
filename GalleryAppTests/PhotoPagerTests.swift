//
//  PhotoPagerTests.swift
//  PhotoPagerTests
//
//  Created by Irina on 23.11.26.
//

import Foundation
import Testing
import UIKit
@testable import GalleryApp

@Test
@MainActor
func testPagerStartsOnSelectedPhotoAndStopsAtBothEnds() throws {
    let imageURL = URL(fileURLWithPath: "/dev/null")
    let photos = ["first", "middle", "last"].map { id in
        Photo(id: id, description: id, urls: .init(small: imageURL, regular: imageURL))
    }
    let pager = PhotoPagerViewController(photos: photos, selectedIndex: 1)
    pager.loadViewIfNeeded()
    
    let selected = try #require(pager.viewControllers?.first as? PhotoDetailViewController)
    #expect(selected.photoIndex == 1)
    
    let previous = try #require(
        pager.pageViewController(pager, viewControllerBefore: selected) as? PhotoDetailViewController
    )
    #expect(previous.photoIndex == 0)
    #expect(pager.pageViewController(pager, viewControllerBefore: previous) == nil)
    
    let next = try #require(
        pager.pageViewController(pager, viewControllerAfter: selected) as? PhotoDetailViewController
    )
    #expect(next.photoIndex == 2)
    #expect(pager.pageViewController(pager, viewControllerAfter: next) == nil)
}

