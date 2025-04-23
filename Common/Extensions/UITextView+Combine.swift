import UIKit
import Combine

extension UITextView {
    /// A publisher that emits the text whenever it changes.
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.publisher(for: UITextView.textDidChangeNotification, object: self)
            .compactMap { $0.object as? UITextView } // Ensure the object is the UITextView itself
            .map { $0.text ?? "" } // Map to the text property
            .eraseToAnyPublisher()
    }
} 