//
//  FavouritesViewController.swift
//  GalleryApp
//
//  Created by Irina on 23.11.26.
//

import UIKit

final class FavouritesViewController: UIViewController {
    private let viewModel = FavouritesViewModel()
    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: PhotoGridLayout.make()
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Favourites"
        setupCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            try viewModel.loadPhotos()
            updateGrid()
        } catch {
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.text = "Couldn’t load favourites"
            contentUnavailableConfiguration = configuration
            print("Could not read favourites:", error)
        }
    }

    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.reuseIdentifier)
        view.addSubview(collectionView)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor)
        ])
    }

    private func updateGrid() {
        collectionView.reloadData()

        if viewModel.photos.isEmpty {
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.image = UIImage(systemName: "heart")
            configuration.text = "No favourites yet"
            configuration.secondaryText = "Tap a heart to save a photo."
            contentUnavailableConfiguration = configuration
        } else {
            contentUnavailableConfiguration = nil
        }
    }

    private func removePhoto(withID id: String) {
        do {
            try viewModel.removePhoto(withID: id)
            updateGrid()
        } catch {
            let alert = UIAlertController(
                title: "Couldn’t remove photo",
                message: "Please try again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

extension FavouritesViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        viewModel.photos.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoCell.reuseIdentifier,
            for: indexPath
        )

        if let photoCell = cell as? PhotoCell {
            let photo = viewModel.photos[indexPath.item]
            photoCell.configure(with: photo.urls.small, isFavourite: true) { [weak self] in
                self?.removePhoto(withID: photo.id)
            }
        }

        return cell
    }
}

extension FavouritesViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let viewer = PhotoPagerViewController(photos: viewModel.photos, selectedIndex: indexPath.item)
        navigationController?.pushViewController(viewer, animated: true)
    }
}
