//
//  PhotoPagerViewController.swift
//  GalleryApp
//
//  Created by Irina on 24.11.26.
//

import UIKit

final class PhotoPagerViewController: UIPageViewController {
    private let viewModel: PhotoPagerViewModel

    private lazy var favouriteButton = UIBarButtonItem(
        image: UIImage(systemName: "heart"),
        style: .plain,
        target: self,
        action: #selector(toggleFavourite)
    )

    init(photos: [Photo], selectedIndex: Int) {
        viewModel = PhotoPagerViewModel(photos: photos, selectedIndex: selectedIndex)
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favouritesDidChange(_:)),
            name: FavouritePhotos.didChange,
            object: FavouritePhotos.shared
        )

        if let selectedPage = makePage(at: viewModel.selectedIndex) {
            setViewControllers([selectedPage], direction: .forward, animated: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshFavouriteButton()
    }

    private var currentPhoto: Photo? {
        guard let page = viewControllers?.first as? PhotoDetailViewController else {
            return nil
        }

        return viewModel.photo(at: page.photoIndex)
    }

    @objc private func favouritesDidChange(_ notification: Notification) {
        refreshFavouriteButton()
    }

    private func refreshFavouriteButton() {
        guard let photo = currentPhoto else { return }

        do {
            let isSaved = try viewModel.isFavourite(photo)
            showFavouriteState(isSaved)
        } catch {
            print("Could not read favourite:", error)
            favouriteButton.image = UIImage(systemName: "heart")
            favouriteButton.accessibilityLabel = "Favourite status unavailable"
            favouriteButton.isEnabled = false
            showErrorAlert(title: "Couldn’t load favourite status")
        }
    }

    @objc private func toggleFavourite() {
        guard let photo = currentPhoto else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                try await viewModel.toggleFavourite(photo)
            } catch {
                print("Could not change favourite:", error)
                showErrorAlert(title: "Couldn’t update favourites", message: "Please try again.")
            }
        }
    }

    private func showFavouriteState(_ isSaved: Bool) {
        favouriteButton.isEnabled = true
        favouriteButton.image = UIImage(systemName: isSaved ? "heart.fill" : "heart")
        favouriteButton.accessibilityLabel = isSaved
        ? "Remove from Favourites"
        : "Add to Favourites"
    }

    private func makePage(at index: Int) -> PhotoDetailViewController? {
        guard let photo = viewModel.photo(at: index) else { return nil }
        return PhotoDetailViewController(photo: photo, photoIndex: index)
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
