//
//  PhotoPagerViewController.swift
//  GalleryApp
//
//  Created by Irina on 24.11.26.
//

import UIKit

final class PhotoPagerViewController: UIPageViewController {
    private let photos: [Photo]
    private let selectedIndex: Int
    private let favouriteStore = FavouriteStore()
    
    private lazy var favouriteButton = UIBarButtonItem(
        image: UIImage(systemName: "heart"),
        style: .plain,
        target: self,
        action: #selector(toggleFavourite)
    )
    
    init(photos: [Photo], selectedIndex: Int) {
        self.photos = photos
        self.selectedIndex = selectedIndex
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Use init(photos:selectedIndex:)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Photo Detail"
        view.backgroundColor = .systemBackground
        dataSource = self
        delegate = self
        navigationItem.rightBarButtonItem = favouriteButton
        
        if let selectedPage = makePage(at: selectedIndex) {
            setViewControllers([selectedPage], direction: .forward, animated: false)
        }
        refreshFavouriteButton()
    }
    
    private var currentPhoto: Photo? {
        guard let page = viewControllers?.first as? PhotoDetailViewController else {
            return nil
        }
        
        return photos[page.photoIndex]
    }
    
    private func refreshFavouriteButton() {
        guard let photo = currentPhoto else { return }
        
        do {
            let isSaved = try favouriteStore.isFavourite(photo.id)
            showFavouriteState(isSaved)
        } catch {
            print("Could not read favourite:", error)
        }
    }
    
    @objc private func toggleFavourite() {
        guard let photo = currentPhoto else { return }
        
        do {
            let isSaved = try favouriteStore.toggle(photo)
            showFavouriteState(isSaved)
        } catch {
            print("Could not change favourite:", error)
        }
    }
    
    private func showFavouriteState(_ isSaved: Bool) {
        favouriteButton.image = UIImage(systemName: isSaved ? "heart.fill" : "heart")
        favouriteButton.accessibilityLabel = isSaved
            ? "Remove from Favourites"
            : "Add to Favourites"
    }
    
    private func makePage(at index: Int) -> PhotoDetailViewController? {
        guard photos.indices.contains(index) else { return nil }
        return PhotoDetailViewController(photo: photos[index], photoIndex: index)
    }
}

extension PhotoPagerViewController: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let page = viewController as? PhotoDetailViewController else { return nil }
        return makePage(at: page.photoIndex - 1)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let page = viewController as? PhotoDetailViewController else { return nil }
        return makePage(at: page.photoIndex + 1)
    }
}

extension PhotoPagerViewController: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if completed {
            refreshFavouriteButton()
        }
    }
}
