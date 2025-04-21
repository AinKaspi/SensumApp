import UIKit

// Делегат для обработки нажатий на кнопки меню
protocol TopMenuViewDelegate: AnyObject {
    func topMenuViewDidSelect(segment: TopMenuView.Segment)
    func topMenuViewDidTapSettings()
    func topMenuViewDidTapBack() // Добавляем метод для кнопки "Назад"
}

class TopMenuView: UIView {

    // Обновляем Enum для новых сегментов
    enum Segment: Int, CaseIterable {
        case card = 0     // Бывший profile
        case person = 1   // Новый сегмент FeedGrid
        case stats = 2    // Бывший stats (Radar)
        // Добавь новые, если нужно
    }

    weak var delegate: TopMenuViewDelegate?
    
    // Добавляем опциональный показ кнопки "Назад"
    var showBackButton: Bool = false { // По умолчанию скрыта
        didSet {
            backButton.isHidden = !showBackButton
            // Возможно, нужно пересчитать констрейнты или обновить layout
            updateLayoutForBackButton()
        }
    }
    
    // --- UI Elements ---
    // Добавляем кнопку "Назад"
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        button.isHidden = true // Скрыта по умолчанию
        return button
    }()
    
    // Убираем старое лого
    /*
    private lazy var logoImageView: UIImageView = { ... }()
    */
    
    // Переименовываем кнопки для ясности
    private lazy var cardButton: UIButton = createMenuButton(title: "Card", segment: .card)
    private lazy var personButton: UIButton = createMenuButton(title: "Person", segment: .person)
    private lazy var statsButton: UIButton = createMenuButton(title: "Stats", segment: .stats)
    
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

    // Обновляем StackView
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [cardButton, personButton, statsButton]) // Обновляем кнопки
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 15
        return stackView
    }()
    
    private var selectedSegment: Segment = .card { // Начальный сегмент - Card
        didSet {
            updateButtonSelection()
            moveSelectionIndicator()
        }
    }
    
    // Ссылки на констрейнты для кнопки "Назад"
    private var backButtonLeadingConstraint: NSLayoutConstraint?
    private var buttonStackLeadingConstraint: NSLayoutConstraint?

    // --- Initialization ---
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear 
        setupView()
        setupConstraints()
        updateButtonSelection()
        updateLayoutForBackButton() // Применить начальное состояние кнопки назад
    }

    override func layoutSubviews() {
        // ... (без изменений) ...
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // --- Setup ---
    private func setupView() {
        addSubview(buttonStackView)
        addSubview(selectionIndicatorView)
        // Добавляем backButton и settingsButton
        addSubview(backButton)
        addSubview(settingsButton)
        
        selectedSegment = .card // Устанавливаем начальный сегмент
    }

    private func setupConstraints() {
        let padding: CGFloat = 15
        let buttonHeight: CGFloat = 44
        let buttonWidth: CGFloat = 30 // Ширина для иконок назад/настроек
        let horizontalSpacing: CGFloat = 15
        
        // Сохраняем ссылки на изменяемые констрейнты
        backButtonLeadingConstraint = backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding)
        buttonStackLeadingConstraint = buttonStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding) // Начальное положение стека

        NSLayoutConstraint.activate([
            // Вертикальные
            backButton.topAnchor.constraint(equalTo: topAnchor),
            backButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonStackView.topAnchor.constraint(equalTo: topAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            settingsButton.topAnchor.constraint(equalTo: topAnchor),
            settingsButton.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Кнопка Назад
            backButtonLeadingConstraint!, // Активируем
            backButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            
            // Кнопка настроек
            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            settingsButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            
            // Стек кнопок меню
            buttonStackLeadingConstraint!, // Активируем начальный констрейнт
            buttonStackView.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -horizontalSpacing),
            
            // Индикатор (привязан к первой кнопке - cardButton)
            selectionIndicatorView.heightAnchor.constraint(equalToConstant: 2),
            selectionIndicatorView.bottomAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: -4),
            selectionIndicatorView.centerXAnchor.constraint(equalTo: cardButton.centerXAnchor),
            selectionIndicatorView.widthAnchor.constraint(equalTo: cardButton.widthAnchor, constant: -20)
        ])
    }
    
    // --- Helper Methods ---
    // Восстанавливаем createMenuButton
    private func createMenuButton(title: String, segment: Segment) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.tag = segment.rawValue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(menuButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    // ... (updateButtonSelection - обновляем для новых кнопок) ...
    private func updateButtonSelection() {
        let buttons = [cardButton, personButton, statsButton]
        for button in buttons {
            let isSelected = (button.tag == selectedSegment.rawValue)
            button.setTitleColor(isSelected ? .white : .lightGray, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: isSelected ? .semibold : .medium)
        }
    }
    
    // ... (moveSelectionIndicator - обновляем для новых кнопок) ...
    private func moveSelectionIndicator(animated: Bool = true) {
        let buttons = [cardButton, personButton, statsButton]
        guard let currentButton = buttons.first(where: { $0.tag == selectedSegment.rawValue }),
              let firstButton = buttons.first else { return }
        // ... (расчет и анимация transform - без изменений) ...
    }
    
    // НОВЫЙ МЕТОД: Обновляет констрейнты при показе/скрытии кнопки "Назад"
    private func updateLayoutForBackButton() {
        let padding: CGFloat = 15
        let buttonWidth: CGFloat = 30
        let horizontalSpacing: CGFloat = 15
        
        if showBackButton {
            // Кнопка Назад видна, стек кнопок сдвигается
            buttonStackLeadingConstraint?.constant = padding + buttonWidth + horizontalSpacing
        } else {
            // Кнопка Назад скрыта, стек кнопок начинается от края
            buttonStackLeadingConstraint?.constant = padding
        }
        // Применяем изменения констрейнтов с анимацией (опционально)
        UIView.animate(withDuration: 0.2) { 
            self.layoutIfNeeded() 
        }
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
    
    // Добавляем action для кнопки "Назад"
    @objc private func backButtonTapped() {
        delegate?.topMenuViewDidTapBack()
    }
} 