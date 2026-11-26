//
//  PhotoDetailViewController.swift
//  GalleryApp
//
//  Created by Irina on 23.11.26.
//

import UIKit

final class PhotoDetailViewController: UIViewController {
    let photoIndex: Int

    private let viewModel: PhotoDetailViewModel
    private let imageView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let imageErrorView = UIStackView()
    private var imageTask: Task<Void, Never>?

    init(photo: Photo, photoIndex: Int) {
        viewModel = PhotoDetailViewModel(photo: photo)
        self.photoIndex = photoIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(photo:photoIndex:)")
    }

    deinit {
        imageTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        let imageContainer = makeImageContainer()

        let descriptionLabel = UILabel()
        descriptionLabel.text = viewModel.descriptionText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [imageContainer, descriptionLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        let safeArea = view.safeAreaLayoutGuide
        let content = scrollView.contentLayoutGuide

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),

            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
            imageContainer.heightAnchor.constraint(equalTo: safeArea.heightAnchor, multiplier: 0.6)
        ])

        loadImage()
    }

    private func makeImageContainer() -> UIView {
        let container = UIView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true

        let errorLabel = UILabel()
        errorLabel.text = "Couldn’t load image"
        errorLabel.font = .preferredFont(forTextStyle: .body)
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0

        let retryButton = UIButton(type: .system)
        var configuration = UIButton.Configuration.bordered()
        configuration.title = "Try Again"
        retryButton.configuration = configuration
        retryButton.addTarget(self, action: #selector(loadImage), for: .touchUpInside)

        imageErrorView.axis = .vertical
        imageErrorView.alignment = .center
        imageErrorView.spacing = 8
        imageErrorView.addArrangedSubview(errorLabel)
        imageErrorView.addArrangedSubview(retryButton)
        imageErrorView.isHidden = true

        for subview in [imageView, loadingIndicator, imageErrorView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(subview)
        }

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageErrorView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageErrorView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            imageErrorView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
        ])
        return container
    }

    @objc private func loadImage() {
        imageTask?.cancel()
        imageErrorView.isHidden = true
        loadingIndicator.startAnimating()

        let photo = viewModel.photo
        imageTask = Task { [weak self] in
            do {
                let image = try await ImageLoader.shared.image(for: photo, thumbnail: false)
                guard !Task.isCancelled else { return }

                self?.loadingIndicator.stopAnimating()
                self?.imageView.image = image
            } catch {
                guard !Task.isCancelled else { return }

                self?.loadingIndicator.stopAnimating()
                self?.imageErrorView.isHidden = false
            }
        }
    }
}
