import UIKit

class NotificationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black // Фон
        setupPlaceholder()
        // В реальной реализации здесь будет UITableView/UICollectionView
        // и подписка на ViewModel для загрузки уведомлений
    }
    
    private func setupPlaceholder() {
        let placeholderLabel = UILabel()
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = "Экран Уведомлений (TODO)"
        placeholderLabel.textColor = .white
        placeholderLabel.textAlignment = .center
        
        view.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
