import UIKit

class PersonContainerViewController: UIViewController {

    // MARK: - Dependencies
    // Пока не используем ViewModel для контейнера, но может понадобиться
    // var viewModel: PersonContainerViewModel?
    var coordinator: PersonCoordinator? // Координатор для навигации к настройкам

    // MARK: - Child View Controllers
    private lazy var profileVC: ProfileViewController = {
        // TODO: Передать сюда ProfileViewModel
        let vc = ProfileViewController()
        vc.coordinator = self.coordinator // Передаем координатора дальше
        vc.viewModel = PersonViewModel() // ВРЕМЕННО: Создаем ViewModel здесь
        return vc
    }()
    
    private lazy var statsVC: StatsViewController = {
        // TODO: Передать сюда StatsViewModel
        let vc = StatsViewController()
        return vc
    }()
    
    // Текущий отображаемый дочерний контроллер
    private var currentChildVC: UIViewController?

    // MARK: - UI Properties
    private lazy var topMenuView: TopMenuView = {
        let view = TopMenuView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self // Контейнер будет делегатом меню
        return view
    }()
    
    // Убираем contentContainerView
    /*
    private lazy var contentContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    */

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Отключали ранее из-за ошибки компиляции
        // self.contentInsetAdjustmentBehavior = .never
        
        // Позволяем layout расширяться под непрозрачные бары
        self.extendedLayoutIncludesOpaqueBars = true
        
        setupViews()
        setupConstraints()
        displayChildViewController(profileVC)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Скрываем стандартный Navigation Bar, так как у нас есть кастомное меню
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup
    private func setupViews() {
        // Добавляем TopMenuView сразу на основное view
        view.addSubview(topMenuView)
        // contentContainerView больше нет
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Верхнее меню: Возвращаем привязку к safeAreaLayoutGuide.topAnchor
            topMenuView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topMenuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topMenuView.heightAnchor.constraint(equalToConstant: 50),
            
            // Констрейнты для contentContainerView больше не нужны
            /*
            contentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            */
        ])
    }
    
    // MARK: - Child VC Management
    
    private func displayChildViewController(_ childVC: UIViewController) {
        // 1. Удаляем предыдущий
        if let existingChild = currentChildVC {
            existingChild.willMove(toParent: nil)
            existingChild.view.removeFromSuperview()
            existingChild.removeFromParent()
        }
        
        // 2. Добавляем новый дочерний контроллер
        addChild(childVC)
        view.addSubview(childVC.view)
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        // Исправляем: Устанавливаем свойство для самого childVC, а не его view
        // Снова комментируем из-за необъяснимой ошибки компиляции
        // (childVC as UIViewController).contentInsetAdjustmentBehavior = .never
        
        // 3. Устанавливаем констрейнты для view дочернего контроллера:
        NSLayoutConstraint.activate([
            childVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            childVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 4. Важно: Перемещаем TopMenuView на самый верх иерархии слоев
        view.bringSubviewToFront(topMenuView)
        
        // 5. Завершаем добавление
        childVC.didMove(toParent: self)
        currentChildVC = childVC
    }
}

// MARK: - TopMenuViewDelegate
extension PersonContainerViewController: TopMenuViewDelegate {
    func topMenuViewDidSelect(segment: TopMenuView.Segment) {
        print("--- PersonContainerVC: Выбран сегмент: \(segment) ---")
        switch segment {
        case .profile:
            // Проверяем, не показываем ли мы уже этот VC
            if currentChildVC is ProfileViewController { return }
            displayChildViewController(profileVC)
        case .stats:
            // Проверяем, не показываем ли мы уже этот VC
            if currentChildVC is StatsViewController { return }
            displayChildViewController(statsVC)
        }
        // Анимацию перехода можно добавить в displayChildViewController
    }
    
    func topMenuViewDidTapSettings() {
        print("--- PersonContainerVC: Нажаты настройки -> Вызов координатора ---")
        // Передаем вызов координатору
        coordinator?.showSettings()
    }
}
