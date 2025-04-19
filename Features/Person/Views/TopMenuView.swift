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
        let stackView = UIStackView(arrangedSubviews: [profileButton, statsButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 15 // Увеличим немного расстояние
        return stackView
    }()
    
    private var selectedSegment: Segment = .profile {
        didSet {
            updateButtonSelection()
            moveSelectionIndicator()
        }
    }

    // --- Initialization ---
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Возвращаем прозрачный фон
        backgroundColor = .clear 
        setupView()
        setupConstraints()
        updateButtonSelection() // Установить начальное выделение
    }

    // Переносим обновление индикатора в layoutSubviews
    override func layoutSubviews() {
        super.layoutSubviews()
        // Вызываем обновление позиции индикатора без анимации при первой отрисовке/изменении размера
        // Чтобы избежать вызова до установки начальных констрейнтов, добавим проверку
        if selectionIndicatorView.transform != .identity {
             moveSelectionIndicator(animated: false) // Устанавливаем в нужную позицию без анимации
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
        let logoWidth: CGFloat = 40
        let settingsWidth: CGFloat = 30
        let horizontalSpacing: CGFloat = 15 // Отступ между элементами
        
        NSLayoutConstraint.activate([
            // Вертикальные констрейнты для всех элементов
            logoImageView.topAnchor.constraint(equalTo: topAnchor),
            logoImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonStackView.topAnchor.constraint(equalTo: topAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            settingsButton.topAnchor.constraint(equalTo: topAnchor),
            settingsButton.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Логотип
            logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            logoImageView.widthAnchor.constraint(equalToConstant: logoWidth),
            
            // Кнопка настроек
            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            settingsButton.widthAnchor.constraint(equalToConstant: settingsWidth),
            
            // Стек кнопок меню (жестко привязан слева и справа)
            buttonStackView.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: horizontalSpacing),
            buttonStackView.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -horizontalSpacing),
            
            // Индикатор - статичные констрейнты относительно profileButton
            selectionIndicatorView.heightAnchor.constraint(equalToConstant: 2),
            selectionIndicatorView.bottomAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: -4),
            selectionIndicatorView.centerXAnchor.constraint(equalTo: profileButton.centerXAnchor),
            selectionIndicatorView.widthAnchor.constraint(equalTo: profileButton.widthAnchor, constant: -20)
        ])
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
              let currentButton = buttons.first(where: { $0.tag == selectedSegment.rawValue }),
              let firstButton = buttons.first else { return }
        
        // Рассчитываем смещение по X от первой кнопки до текущей
        // Используем frame, убедившись, что layout посчитан
        self.layoutIfNeeded() // Обновляем layout перед расчетом frame
        let targetX = currentButton.frame.origin.x
        let firstX = firstButton.frame.origin.x
        let translationX = targetX - firstX
        
        // Создаем transform для смещения
        let transform = CGAffineTransform(translationX: translationX, y: 0)
        
        // Анимируем изменение transform
        let duration = animated ? 0.3 : 0.0
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.selectionIndicatorView.transform = transform
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
