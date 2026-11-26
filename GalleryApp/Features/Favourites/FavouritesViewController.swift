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

    private lazy var dataSource = UICollectionViewDiffableDataSource<Int, String>(
        collectionView: collectionView
    ) { [weak self] collectionView, indexPath, photoID in
        guard let self, let photo = viewModel.photos.first(where: { $0.id == photoID }) else { return nil }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoCell.reuseIdentifier,
            for: indexPath
        )

        if let photoCell = cell as? PhotoCell {
            photoCell.configure(with: photo, isFavourite: true) { [weak self] in
                Task { await self?.removePhoto(withID: photoID) }
            }
        }

        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Favourites"
        setupCollectionView()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favouritesDidChange(_:)),
            name: FavouritePhotos.didChange,
            object: FavouritePhotos.shared
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshFavourites()
    }

    @objc private func favouritesDidChange(_ notification: Notification) {
        refreshFavourites()
    }

    private func refreshFavourites() {
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
        collectionView.delegate = self
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.reuseIdentifier)
        view.addSubview(collectionView)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor)
        ])
    }

    private func updateGrid() {
        let photoIDs = viewModel.photos.map(\.id)
        if dataSource.snapshot().itemIdentifiers != photoIDs {
            var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
            snapshot.appendSections([0])
            snapshot.appendItems(photoIDs)
            dataSource.apply(snapshot, animatingDifferences: view.window != nil)
        }

        if photoIDs.isEmpty {
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.image = UIImage(systemName: "heart")
            configuration.text = "No favourites yet"
            configuration.secondaryText = "Tap a heart to save a photo."
            contentUnavailableConfiguration = configuration
        } else {
            contentUnavailableConfiguration = nil
        }
    }

    private func removePhoto(withID id: String) async {
        do {
            try await viewModel.removePhoto(withID: id)
        } catch {
            showErrorAlert(title: "Couldn’t remove photo", message: "Please try again.")
        }
    }
}

extension FavouritesViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let photoID = dataSource.itemIdentifier(for: indexPath),
              let selectedIndex = viewModel.photos.firstIndex(where: { $0.id == photoID }) else { return }

        let viewer = PhotoPagerViewController(photos: viewModel.photos, selectedIndex: selectedIndex)
        navigationController?.pushViewController(viewer, animated: true)
    }
}
