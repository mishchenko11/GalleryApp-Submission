//
//  PhotoDetailViewController.swift
//  GalleryApp
//
//  Created by Irina on 23.11.26.
//

import UIKit

final class PhotoDetailViewController: UIViewController {
    private let photo: Photo
    private let imageView = UIImageView()
    
    init(photo: Photo) {
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Use init(photo:)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Photo Detail"
        view.backgroundColor = .systemBackground
        imageView.contentMode = .scaleAspectFit
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = photo.description ?? "No description"
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.adjustsFontForContentSizeCategory = true
        
        let stack = UIStackView(arrangedSubviews: [imageView, descriptionLabel])
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
            imageView.heightAnchor.constraint(equalTo: safeArea.heightAnchor, multiplier: 0.6)
        ])
        
        let url = photo.urls.regular
        Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
            self?.imageView.image = UIImage(data: data)
        }
    }
}
