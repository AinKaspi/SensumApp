import UIKit

// Переименовываем класс
class UserProfileContainerViewController: UIViewController {

    // MARK: - Dependencies
    // Координатор теперь UserProfileCoordinator
    var coordinator: UserProfileCoordinator?

    // MARK: - Child View Controllers
    // Переименовываем VC
    private lazy var cardVC: UserProfileCardViewController = {
        let vc = UserProfileCardViewController()
        // vc.coordinator = self.coordinator // Координатор нужен самому контейнеру, дочерним - вряд ли
        // vc.viewModel = ... // ViewModel нужно будет создать и передать userID
        return vc
    }()
    
    private lazy var personFeedVC: UserProfileFeedViewController = {
        let vc = UserProfileFeedViewController()
        // vc.viewModel = ... // ViewModel нужно будет создать и передать userID
        return vc
    }()
    
    private lazy var statsVC: UserProfileStatsViewController = {
        let vc = UserProfileStatsViewController()
        // vc.viewModel = ... // ViewModel нужно будет создать и передать userID
        return vc
    }()
    
    private var currentChildVC: UIViewController?

    // MARK: - UI Properties
    private lazy var topMenuView: TopMenuView = {
        let view = TopMenuView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        // TODO: Добавить настройку для показа стрелки назад
        // view.showBackButton = true 
        return view
    }()
    
    // MARK: - Configuration
    private var userID: String? 
    
    func configure(with userID: String) {
        self.userID = userID
        // TODO: Передать userID во ViewModel-и дочерних VC при их создании
        // или перезагрузить/сконфигурировать существующие
    }

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
        // Отображаем начальный VC (например, Card)
        displayChildViewController(cardVC)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Скрываем стандартный Navigation Bar
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup
    private func setupViews() {
        view.addSubview(topMenuView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Верхнее меню
            topMenuView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topMenuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topMenuView.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    // MARK: - Child VC Management
    private func displayChildViewController(_ childVC: UIViewController) {
        if let existingChild = currentChildVC {
            existingChild.willMove(toParent: nil)
            existingChild.view.removeFromSuperview()
            existingChild.removeFromParent()
        }
        
        addChild(childVC)
        view.addSubview(childVC.view)
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        // Снова комментируем из-за необъяснимой ошибки компиляции
        // (childVC as UIViewController).contentInsetAdjustmentBehavior = .never
        
        NSLayoutConstraint.activate([
            childVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            childVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        view.bringSubviewToFront(topMenuView)
        
        childVC.didMove(toParent: self)
        currentChildVC = childVC
    }
}

// MARK: - TopMenuViewDelegate
// Переименовываем Extension
extension UserProfileContainerViewController: TopMenuViewDelegate {
    // Обновляем сегменты в соответствии с новым дизайном
    func topMenuViewDidSelect(segment: TopMenuView.Segment) {
        print("--- UserProfileContainerVC: Selected segment: \(segment) ---")
        switch segment {
        case .profile: // Теперь это 'Card' по идее
             if currentChildVC is UserProfileCardViewController { return }
             displayChildViewController(cardVC)
        case .stats:   // Теперь это 'Person' (FeedGrid)
             if currentChildVC is UserProfileFeedViewController { return }
             displayChildViewController(personFeedVC)
        // case .newSegment: // Теперь это 'Stats' (Radar)
        //     if currentChildVC is UserProfileStatsViewController { return }
        //     displayChildViewController(statsVC)
        // TODO: Обновить enum Segment в TopMenuView и логику здесь
        }
    }
    
    // Добавляем обработку кнопки Назад
    func topMenuViewDidTapBack() {
         print("--- UserProfileContainerVC: Back tapped --- ")
         // Сообщаем координатору, что нужно закрыть этот экран
         coordinator?.dismissProfile() // Пример названия метода
    }
    
    func topMenuViewDidTapSettings() {
        print("--- UserProfileContainerVC: Settings tapped --- ")
        coordinator?.showSettings() // Этот метод в координаторе тоже под вопросом
    }
}
