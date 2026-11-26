import Foundation

struct PhotoDetailViewModel {
    let descriptionText: String
    let photo: Photo

    init(photo: Photo) {
        descriptionText = photo.description ?? "No description"
        self.photo = photo
    }
}
