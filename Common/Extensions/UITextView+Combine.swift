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


// TODO: Добавить расширение Date для timeAgoDisplay(), если его еще нет
// Пример расширения:

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

