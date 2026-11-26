//
//  GalleryViewController.swift
//  GalleryApp
//
//  Created by Irina on 23.11.26.
//

import UIKit

class GalleryViewController: UIViewController {
    private let viewModel = GalleryViewModel()
    private let favouriteStore = FavouriteStore()
    private var favouriteIDs: Set<String> = []

    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: PhotoGridLayout.make()
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Gallery"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        setupCollectionView()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favouritesDidChange(_:)),
            name: FavouritePhotos.didChange,
            object: FavouritePhotos.shared
        )
        loadMorePhotos()
    }

    private func loadMorePhotos() {
        Task { [weak self] in
            guard let self else { return }

            do {
                if try await viewModel.loadNextPage() {
                    collectionView.reloadData()
                    print("Photos loaded:", viewModel.photos.count)
                }
            } catch {
                print("Could not load photos:", error)

                let alert = UIAlertController(
                    title: "Couldn’t load photos",
                    message: "Please try again.",
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
                    self?.loadMorePhotos()
                })

                present(alert, animated: true)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshFavourites()
    }

    @objc private func favouritesDidChange(_ notification: Notification) {
        refreshFavourites()
    }

    private func refreshFavourites() {
        do {
            let savedIDs = try favouriteStore.favouriteIDs()
            let changedIDs = favouriteIDs.symmetricDifference(savedIDs)
            guard !changedIDs.isEmpty else { return }

            favouriteIDs = savedIDs
            for indexPath in collectionView.indexPathsForVisibleItems {
                guard viewModel.photos.indices.contains(indexPath.item) else { continue }
                let id = viewModel.photos[indexPath.item].id
                if changedIDs.contains(id),
                   let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
                    cell.setFavourite(savedIDs.contains(id))
                }
            }
        } catch {
            print("Could not read favourites:", error)
            showErrorAlert(title: "Couldn’t load favourites")
        }
    }

    private func toggleFavourite(_ photo: Photo) async {
        do {
            _ = try await FavouritePhotos.shared.toggle(photo)
        } catch {
            print("Could not change favourite:", error)
            showErrorAlert(title: "Couldn’t update favourites", message: "Please try again.")
        }
    }

    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            PhotoCell.self,
            forCellWithReuseIdentifier: PhotoCell.reuseIdentifier
        )
        view.addSubview(collectionView)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor)
        ])
    }
}

extension GalleryViewController: UICollectionViewDataSource {
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
            photoCell.configure(
                with: photo,
                isFavourite: favouriteIDs.contains(photo.id)
            ) { [weak self] in
                Task { await self?.toggleFavourite(photo) }
            }
        }

        return cell
    }
}

extension GalleryViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if let photoCell = cell as? PhotoCell, viewModel.photos.indices.contains(indexPath.item) {
            photoCell.setFavourite(favouriteIDs.contains(viewModel.photos[indexPath.item].id))
        }

        let loadThreshold = max(viewModel.photos.count - 4, 0)
        if indexPath.item >= loadThreshold {
            loadMorePhotos()
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let viewer = PhotoPagerViewController(
            photos: viewModel.photos,
            selectedIndex: indexPath.item
        )
        navigationController?.pushViewController(viewer, animated: true)
    }
}
