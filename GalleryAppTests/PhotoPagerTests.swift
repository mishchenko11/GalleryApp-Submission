//
//  PhotoPagerTests.swift
//  PhotoPagerTests
//
//  Created by Irina on 23.11.26.
//

import Foundation
import XCTest
@testable import GalleryApp

final class PhotoPagerTests: XCTestCase {
    @MainActor
    func testPagerStartsOnSelectedPhotoAndStopsAtBothEnds() throws {
        let imageURL = URL(fileURLWithPath: "/dev/null")
        let photos = ["first", "middle", "last"].map { id in
            Photo(id: id, description: id, urls: .init(small: imageURL, regular: imageURL))
        }
        let pager = PhotoPagerViewController(photos: photos, selectedIndex: 1)
        pager.loadViewIfNeeded()

        let selected = try XCTUnwrap(pager.viewControllers?.first as? PhotoDetailViewController)
        XCTAssertEqual(selected.photoIndex, 1)

        let previous = try XCTUnwrap(
            pager.pageViewController(pager, viewControllerBefore: selected) as? PhotoDetailViewController
        )
        XCTAssertEqual(previous.photoIndex, 0)
        XCTAssertNil(pager.pageViewController(pager, viewControllerBefore: previous))

        let next = try XCTUnwrap(
            pager.pageViewController(pager, viewControllerAfter: selected) as? PhotoDetailViewController
        )
        XCTAssertEqual(next.photoIndex, 2)
        XCTAssertNil(pager.pageViewController(pager, viewControllerAfter: next))
    }
}
