import UIKit

class ExerciseSelectionViewController: UIViewController {

    // MARK: - Properties
    var viewModel: ExerciseSelectionViewModel! // Используем ! т.к. он будет установлен до viewDidLoad

    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped) // Используем стиль insetGrouped для красивого вида
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ExerciseCell.self, forCellReuseIdentifier: ExerciseCell.identifier) // Регистрируем ячейку
        tableView.backgroundColor = .clear // Фон таблицы прозрачный
        tableView.separatorStyle = .singleLine // Стиль разделителя
        tableView.rowHeight = UITableView.automaticDimension // Автоматическая высота
        tableView.estimatedRowHeight = 60 // Примерная высота для оптимизации
        return tableView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black // Устанавливаем темный фон для всего view
        title = "Выберите упражнение"
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Actions
    // Обработка выбора будет в UITableViewDelegate
}

// MARK: - UITableViewDataSource
extension ExerciseSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfExercises
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ExerciseCell.identifier, for: indexPath) as? ExerciseCell else {
            // В реальном приложении лучше вернуть пустую ячейку или обработать ошибку
            fatalError("Unable to dequeue ExerciseCell") 
        }
        
        if let exercise = viewModel.exercise(at: indexPath.row) {
            cell.configure(with: exercise)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ExerciseSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Снимаем выделение с ячейки
        
        if let selectedExercise = viewModel.exercise(at: indexPath.row) {
            print("--- ExerciseSelectionVC: Выбрано упражнение: \(selectedExercise.name) (ID: \(selectedExercise.id)) ---")
            // Вызываем метод ViewModel для обработки выбора
            viewModel.didSelectExercise(at: indexPath.row)
        } else {
            print("--- ExerciseSelectionVC: Ошибка: Не удалось получить данные для выбранной строки \(indexPath.row) ---")
        }
    }
}

// MARK: - ExerciseCell (Простая кастомная ячейка)

class ExerciseCell: UITableViewCell {
    static let identifier = "ExerciseCell"
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white // Цвет иконки
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .white // Цвет текста
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        
        // Устанавливаем темный фон для ячейки
        backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        // Добавляем стрелку справа
        accessoryType = .disclosureIndicator
        
        let padding: CGFloat = 15
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            // Отступ сверху/снизу >= 10 для автоматической высоты
            iconImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
            iconImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: padding),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding), // Отступ справа
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with exercise: Exercise) {
        nameLabel.text = exercise.name
        iconImageView.image = UIImage(systemName: exercise.iconName)
        // Можно добавить отображение description или других данных при необходимости
    }
}
