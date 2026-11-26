import UIKit

extension UIViewController {
    func showErrorAlert(title: String, message: String? = nil) {
        guard viewIfLoaded?.window != nil, presentedViewController == nil else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
