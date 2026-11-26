import Foundation

enum Constants {
    static let unsplashAccessKeyPlaceholder = ""
    static let unsplashAccessKey = ProcessInfo.processInfo.environment["UNSPLASH_ACCESS_KEY"]
        ?? unsplashAccessKeyPlaceholder
}
