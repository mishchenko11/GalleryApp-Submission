//
//  GalleryViewController.swift
//  GalleryApp
//
//  Created by Irina on 23.11.26.
//

import UIKit

class GalleryViewController: UIViewController {
    private let viewModel = GalleryViewModel()
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeGridLayout()
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Gallery"
        setupCollectionView()

        Task {
            do {
                try await viewModel.loadPhotos()
                navigationItem.title = "Gallery (\(viewModel.photos.count))"
                collectionView.reloadData()
            } catch {
                print("Error:", error)
            }
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

    private func makeGridLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1)
        ))
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)

        let row = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalWidth(0.5)
            ),
            subitems: [item, item]
        )

        let section = NSCollectionLayoutSection(group: row)
        section.interGroupSpacing = 8
        return UICollectionViewCompositionalLayout(section: section)
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
            photoCell.configure(with: viewModel.photos[indexPath.item].urls.small)
        }

        return cell
    }
    
}

extension GalleryViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let photo = viewModel.photos[indexPath.item]
        let detail = PhotoDetailViewController(photo: photo)
        navigationController?.pushViewController(detail, animated: true)
    }
}
