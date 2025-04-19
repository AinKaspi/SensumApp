import UIKit

// Делегат для обработки нажатий на кнопки меню
protocol TopMenuViewDelegate: AnyObject {
    func topMenuViewDidSelect(segment: TopMenuView.Segment)
    func topMenuViewDidTapSettings()
}

class TopMenuView: UIView {

    enum Segment: Int, CaseIterable { // Добавляем CaseIterable
        case profile = 0
        case stats = 1
        case achievements = 2
    }

    weak var delegate: TopMenuViewDelegate?
    
    // --- UI Elements ---
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        // TODO: Установить реальное изображение логотипа
        imageView.image = UIImage(systemName: "figure.mixed.cardio")?.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    private lazy var profileButton: UIButton = createMenuButton(title: "Profile", segment: .profile)
    private lazy var statsButton: UIButton = createMenuButton(title: "Stats", segment: .stats)
    private lazy var achievementsButton: UIButton = createMenuButton(title: "Achivements", segment: .achievements)
    
    private lazy var selectionIndicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white // Цвет индикатора
        return view
    }()
    
    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        button.tintColor = .lightGray // Цвет иконки настроек
        button.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [profileButton, statsButton, achievementsButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 15 // Увеличим немного расстояние
        return stackView
    }()
    
    // Constraints for indicator
    private var indicatorLeadingConstraint: NSLayoutConstraint?
    private var indicatorWidthConstraint: NSLayoutConstraint?
    
    private var selectedSegment: Segment = .profile {
        didSet {
            updateButtonSelection()
            moveSelectionIndicator()
        }
    }

    // --- Initialization ---
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        updateButtonSelection() // Установить начальное выделение
        // Задержка для корректного позиционирования индикатора после автолейаута
        DispatchQueue.main.async {
             self.moveSelectionIndicator(animated: false)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // --- Setup ---
    private func setupView() {
        // Добавляем сначала стек с кнопками и индикатор, чтобы они были под лого и настройками (если нужно)
        addSubview(buttonStackView)
        addSubview(selectionIndicatorView)
        addSubview(logoImageView)
        addSubview(settingsButton)
        
        // Устанавливаем начальный выбранный сегмент
        selectedSegment = .profile
    }

    private func setupConstraints() {
        let padding: CGFloat = 15
        let buttonHeight: CGFloat = 44 // Стандартная высота для тапа
        
        NSLayoutConstraint.activate([
            // Кнопки занимают всю высоту
            buttonStackView.topAnchor.constraint(equalTo: topAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            settingsButton.topAnchor.constraint(equalTo: topAnchor),
            settingsButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            logoImageView.topAnchor.constraint(equalTo: topAnchor),
            logoImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Логотип
            logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            logoImageView.widthAnchor.constraint(equalToConstant: 40),
            
            // Кнопка настроек
            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            settingsButton.widthAnchor.constraint(equalToConstant: 30),
            
            // Стек кнопок меню
            buttonStackView.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: padding * 1.5), // Больше отступ от лого
            buttonStackView.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -padding * 1.5), // Больше отступ от настроек
            
            // Индикатор
            selectionIndicatorView.heightAnchor.constraint(equalToConstant: 2),
            selectionIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Начальные констрейнты индикатора
        if let firstButton = buttonStackView.arrangedSubviews.first {
            indicatorLeadingConstraint = selectionIndicatorView.leadingAnchor.constraint(equalTo: firstButton.leadingAnchor)
            indicatorWidthConstraint = selectionIndicatorView.widthAnchor.constraint(equalTo: firstButton.widthAnchor)
            indicatorLeadingConstraint?.isActive = true
            indicatorWidthConstraint?.isActive = true
        }
    }
    
    // --- Helper Methods ---
    private func createMenuButton(title: String, segment: Segment) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.tag = segment.rawValue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(menuButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func updateButtonSelection() {
        let buttons = buttonStackView.arrangedSubviews.compactMap { $0 as? UIButton }
        for button in buttons {
            let isSelected = (button.tag == selectedSegment.rawValue)
            button.setTitleColor(isSelected ? .white : .lightGray, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: isSelected ? .semibold : .medium)
        }
    }
    
    private func moveSelectionIndicator(animated: Bool = true) {
        guard let buttons = buttonStackView.arrangedSubviews as? [UIButton],
              let targetButton = buttons.first(where: { $0.tag == selectedSegment.rawValue }) else { return }
        
        // Деактивируем старые констрейнты
        indicatorLeadingConstraint?.isActive = false
        indicatorWidthConstraint?.isActive = false
        
        // Создаем и активируем новые
        indicatorLeadingConstraint = selectionIndicatorView.leadingAnchor.constraint(equalTo: targetButton.leadingAnchor)
        indicatorWidthConstraint = selectionIndicatorView.widthAnchor.constraint(equalTo: targetButton.widthAnchor)
        
        indicatorLeadingConstraint?.isActive = true
        indicatorWidthConstraint?.isActive = true
        
        // Анимируем изменение layout'а
        let duration = animated ? 0.3 : 0.0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.layoutIfNeeded() // Принудительно обновляем layout для анимации
        }, completion: nil)
    }

    // --- Actions ---
    @objc private func menuButtonTapped(_ sender: UIButton) {
        guard let newSegment = Segment(rawValue: sender.tag) else { return }
        selectedSegment = newSegment
        delegate?.topMenuViewDidSelect(segment: newSegment)
    }
    
    @objc private func settingsButtonTapped() {
        delegate?.topMenuViewDidTapSettings()
    }
}
