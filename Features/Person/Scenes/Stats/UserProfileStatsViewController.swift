import UIKit

// Переименовываем класс
class UserProfileStatsViewController: UIViewController {
    
    // Оставляем backgroundView для фона
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // Вернем фиолетовый фон (или можно сделать черный, как в макете?)
        view.backgroundColor = .systemIndigo // Или .black?
        // view.layer.zPosition = -1 // zPosition, скорее всего, не нужен
        return view
    }()
    
    // Убираем временный визуализатор
    /*
    private lazy var safeAreaVisualizer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .green
        return view
    }()
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear // Фон основного view прозрачный
        // title = "Статистика" // Убираем title, т.к. управляется TopMenuView
        
        // Добавляем фон НАЗАД
        view.insertSubview(backgroundView, at: 0)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Убираем добавление визуализатора
        /*
        view.addSubview(safeAreaVisualizer)
        NSLayoutConstraint.activate([
            safeAreaVisualizer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            safeAreaVisualizer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            safeAreaVisualizer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            safeAreaVisualizer.heightAnchor.constraint(equalToConstant: 50)
        ])
        */
        
        // TODO: Реализовать UI Макета 4:
        // - Радар-диаграмма (Radar Chart) - потребует импорта/реализации библиотеки
        // - Плашка с именем и рангом
        // - Плашка со статами (STR, ACC, DFT, SPD, RSH, CON)
        // - Прогресс-бар Level/XP (можно переиспользовать из UserProfileCardVC?)
        setupPlaceholderUI()
    }
    
    // Временная заглушка для UI
    private func setupPlaceholderUI() {
        let placeholderLabel = UILabel()
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = "Stats Screen (Radar Chart Here)"
        placeholderLabel.textColor = .white
        placeholderLabel.textAlignment = .center
        placeholderLabel.font = .systemFont(ofSize: 20, weight: .bold)
        
        view.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor) // Центрируем по Safe Area
        ])
    }
}
