import Foundation

struct PhotoDetailViewModel {
    let descriptionText: String
    let imageURL: URL

    init(photo: Photo) {
        descriptionText = photo.description ?? "No description"
        imageURL = photo.urls.regular
    }
}
