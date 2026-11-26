import Foundation

enum Constants {
    static let unsplashAccessKeyPlaceholder = "<put your key here>"
    static let unsplashAccessKey = ProcessInfo.processInfo.environment["UNSPLASH_ACCESS_KEY"]
        ?? unsplashAccessKeyPlaceholder
}
