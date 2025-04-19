import UIKit

class StatsViewController: UIViewController {
    
    // Добавляем фоновое view
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // Возвращаем исходный цвет
        view.backgroundColor = .systemIndigo
        // zPosition можно оставить или убрать, скорее всего, он не нужен
        // view.layer.zPosition = -1
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
        // title = "Статистика" // Устанавливаем заголовок <-- Временно комментируем для теста
        
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
        
        // TODO: Добавить отображение статистики (например, Radar Chart)
        // Здесь будет добавляться реальный контент StatsViewController.
        // Если ему нужно будет игнорировать отступ сверху (safe area + top menu),
        // его можно будет привязать к view.topAnchor вместо view.safeAreaLayoutGuide.topAnchor.
    }
}
