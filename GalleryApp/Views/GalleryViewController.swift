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
        setupCollectionView()

        Task {
            do {
                try await viewModel.loadPhotos()
                print("Photos received:", viewModel.photos.count)
                collectionView.reloadData()
            } catch {
                print("Error:", error)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        do {
            let savedIDs = try favouriteStore.favouriteIDs()
            guard savedIDs != favouriteIDs else { return }
            favouriteIDs = savedIDs
            collectionView.reloadData()
        } catch {
            print("Could not read favourites:", error)
        }
    }

    private func toggleFavourite(_ photo: Photo, in cell: PhotoCell?) {
        do {
            let isSaved = try favouriteStore.toggle(photo)
            if isSaved {
                favouriteIDs.insert(photo.id)
            } else {
                favouriteIDs.remove(photo.id)
            }
            cell?.setFavourite(isSaved)
        } catch {
            print("Could not change favourite:", error)
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
            collectionView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
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
                with: photo.urls.small,
                isFavourite: favouriteIDs.contains(photo.id)
            ) { [weak self, weak photoCell] in
                self?.toggleFavourite(photo, in: photoCell)
            }
        }

        return cell
    }
    
}

extension GalleryViewController: UICollectionViewDelegate {
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
