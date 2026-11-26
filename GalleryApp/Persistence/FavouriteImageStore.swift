import CryptoKit
import Foundation
import ImageIO
import UIKit

actor FavouriteImageStore {
    private let directory: URL

    init(directory: URL? = nil) {
        self.directory = directory
            ?? URL.applicationSupportDirectory.appending(path: "FavouriteImages", directoryHint: .isDirectory)
    }

    func save(_ data: Data, for photoID: String) throws {
        guard UIImage(data: data) != nil else {
            throw URLError(.cannotDecodeContentData)
        }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var storageDirectory = directory
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try storageDirectory.setResourceValues(resourceValues)
        try data.write(to: fileURL(for: photoID), options: .atomic)
    }

    func image(for photoID: String, thumbnail: Bool) -> UIImage? {
        let url = fileURL(for: photoID)
        guard thumbnail else { return UIImage(contentsOfFile: url.path) }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceCreateThumbnailWithTransform: true,
                  kCGImageSourceThumbnailMaxPixelSize: 512
              ] as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: image)
    }

    func remove(for photoID: String) throws {
        do {
            try FileManager.default.removeItem(at: fileURL(for: photoID))
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            return
        }
    }

    private func fileURL(for photoID: String) -> URL {
        let filename = SHA256.hash(data: Data(photoID.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: filename, directoryHint: .notDirectory)
    }
}
