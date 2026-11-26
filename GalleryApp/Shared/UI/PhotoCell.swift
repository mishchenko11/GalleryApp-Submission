//
//  PhotoCell.swift
//  GalleryApp
//
//  Created by Irina on 23.11.26.
//

import UIKit

final class PhotoCell: UICollectionViewCell {
    static let reuseIdentifier = "PhotoCell"
    
    private let imageView = UIImageView()
    private let favouriteButton = UIButton(type: .system)
    private var imageTask: Task<Void, Never>?
    private var onFavouriteTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        var buttonStyle = UIButton.Configuration.filled()
        buttonStyle.baseBackgroundColor = .black.withAlphaComponent(0.65)
        buttonStyle.baseForegroundColor = .white
        buttonStyle.cornerStyle = .capsule
        buttonStyle.contentInsets = .zero
        buttonStyle.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: 17,
            weight: .semibold
        )
        favouriteButton.configuration = buttonStyle
        favouriteButton.translatesAutoresizingMaskIntoConstraints = false
        favouriteButton.addTarget(self, action: #selector(handleFavouriteTap), for: .touchUpInside)
        contentView.addSubview(favouriteButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            favouriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            favouriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            favouriteButton.widthAnchor.constraint(equalToConstant: 44),
            favouriteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("PhotoCell is created programmatically")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageView.image = nil
        onFavouriteTap = nil
    }
    
    func configure(with url: URL, isFavourite: Bool, onFavouriteTap: @escaping () -> Void) {
        self.onFavouriteTap = onFavouriteTap
        setFavourite(isFavourite)

        imageTask?.cancel()
        imageView.image = nil
        
        imageTask = Task { [weak self] in
            guard let image = try? await ImageLoader.shared.image(from: url),
                  !Task.isCancelled else { return }

            self?.imageView.image = image
        }
    }

    func setFavourite(_ isFavourite: Bool) {
        favouriteButton.configuration?.image = UIImage(systemName: isFavourite ? "heart.fill" : "heart")
        favouriteButton.accessibilityLabel = isFavourite ? "Remove from Favourites" : "Add to Favourites"
    }

    @objc private func handleFavouriteTap() {
        onFavouriteTap?()
    }
}
