import UIKit
import Combine // Импортируем Combine

class ProgressViewController: UIViewController {

    // ViewModel
    var viewModel: ProgressViewModel! // Будет инжектирован координатором
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements

    private lazy var rankLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "-" // Placeholder
        return label
    }()
    
    private lazy var rankTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .lightGray
        label.textAlignment = .center
        label.text = "Ранг"
        return label
    }()

    private lazy var levelLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "Уровень: -" // Placeholder
        return label
    }()
    
    private lazy var xpLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .lightGray
        label.textAlignment = .center
        label.text = "--/-- XP" // Placeholder
        return label
    }()

    private lazy var xpProgressBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemCyan
        progressView.trackTintColor = .darkGray
        progressView.progress = 0.0
        progressView.layer.cornerRadius = 5
        progressView.clipsToBounds = true
        progressView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        return progressView
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var errorLabel: UILabel = {
           let label = UILabel()
           label.translatesAutoresizingMaskIntoConstraints = false
           label.textColor = .systemRed
           label.font = .systemFont(ofSize: 14)
           label.textAlignment = .center
           label.numberOfLines = 0
           label.isHidden = true
           return label
       }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [rankLabel, rankTitleLabel, levelLabel, xpProgressBar, xpLabel, errorLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        // Устанавливаем кастомные отступы
        stack.setCustomSpacing(2, after: rankLabel) 
        stack.setCustomSpacing(20, after: rankTitleLabel)
        stack.setCustomSpacing(4, after: levelLabel)
        stack.setCustomSpacing(4, after: xpProgressBar)
        stack.setCustomSpacing(20, after: xpLabel)
        return stack
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "ViewModel not injected into ProgressViewController")
        view.backgroundColor = .black // Основной фон
        title = "Прогресс" // Заголовок для Navigation Bar (если он будет показан)
        setupUI()
        setupConstraints()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Можно добавить обновление данных при появлении экрана
        // viewModel.fetchProgressData()
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(stackView)
        view.addSubview(activityIndicator)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Стек по центру
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Прогресс бар во всю ширину стека
            xpProgressBar.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.8),
            
            // Индикатор загрузки по центру
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Лейбл ошибки (может быть над или под стеком)
            errorLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    // MARK: - Bindings
    private func setupBindings() {
        // Подписка на данные прогресса
        viewModel.$progressData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progressData in
                guard let data = progressData else { return }
                self?.rankLabel.text = data.rank
                self?.levelLabel.text = "Уровень: \(data.level)"
                self?.xpLabel.text = "\(data.currentXP)/\(data.xpToNextLevel) XP"
                
                let progress = data.xpToNextLevel > 0 ? Float(data.currentXP) / Float(data.xpToNextLevel) : 0
                self?.xpProgressBar.setProgress(max(0.0, min(1.0, progress)), animated: true)
            }
            .store(in: &cancellables)
        
        // Подписка на состояние загрузки
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                    self?.stackView.isHidden = true // Скрываем контент во время загрузки
                    self?.errorLabel.isHidden = true
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.stackView.isHidden = false
                }
            }
            .store(in: &cancellables)
            
        // Подписка на ошибки
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.errorLabel.text = message
                // Показываем ошибку, только если не идет загрузка
                let shouldShowError = message != nil && !(self?.viewModel.isLoading ?? false)
                self?.errorLabel.isHidden = !shouldShowError
                // Можно также скрыть stackView при ошибке, если нужно
                 self?.stackView.isHidden = shouldShowError
            }
            .store(in: &cancellables)
    }
} 