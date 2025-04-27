import UIKit

class UserProfileContainerViewController: UIViewController {

    // MARK: - Dependencies
    var coordinator: UserProfileCoordinator?
    // Добавляем свойства для зависимостей
    private var userID: String!
    private var progressService: ProgressServiceProtocol!

    // MARK: - Child View Controllers
    private lazy var cardVC: UserProfileCardViewController = {
        let vc = UserProfileCardViewController()
        // TODO: Configure with ViewModel using self.userID & progressService?
        // Пока оставляем без VM, т.к. PersonViewModel устарел
        return vc
    }()
    
    private lazy var personFeedVC: UserProfileFeedViewController = {
        let vc = UserProfileFeedViewController()
        // Создаем ViewModel здесь (или передаем из координатора?)
        // Пока создаем здесь для простоты
        let viewModel = UserProfileFeedViewModel(
            userID: self.userID,
            isCurrentUser: false, // Предполагаем, что это чужой профиль 
            // Явно передаем все сервисы
            userProfileService: UserProfileService(), // Или self.userProfileService, если он есть в контейнере
            postService: PostService(),             // Или self.postService
            followService: FollowService(),           // Или self.followService
            progressService: self.progressService // Передаем progressService из контейнера
        )
        vc.viewModel = viewModel
        // vc.delegate = coordinator // Делегат UserProfileFeedViewControllerDelegate нужен координатору
        return vc
    }()
    
    private lazy var statsVC: UserProfileStatsViewController = {
        let vc = UserProfileStatsViewController()
        // Создаем ViewModel здесь и передаем зависимости
        let viewModel = UserProfileStatsViewModel(
            userID: self.userID,
            progressService: self.progressService
        )
        vc.viewModel = viewModel
        return vc
    }()
    
    private var currentChildVC: UIViewController?

    // MARK: - UI Properties
    private lazy var topMenuView: TopMenuView = {
        let view = TopMenuView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        // Явно показываем кнопку "Назад" для этого контейнера
        view.showBackButton = true 
        return view
    }()
    
    // MARK: - Configuration
    func configure(with userID: String, progressService: ProgressServiceProtocol) {
        self.userID = userID
        self.progressService = progressService
        print("UserProfileContainerViewController configured for userID: \(userID)")
        // Показываем Card по умолчанию
        displayChildViewController(cardVC)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Отключали ранее из-за ошибки компиляции
        // self.contentInsetAdjustmentBehavior = .never
        
        // Позволяем layout расширяться под непрозрачные бары
        self.extendedLayoutIncludesOpaqueBars = true
        
        // Восстанавливаем вызовы
        setupViews()
        setupConstraints()
        // Убираем отображение начального VC отсюда, будет в configure
        // displayChildViewController(cardVC)
    }
    
    // ... (viewWillAppear, setupViews, setupConstraints - без изменений) ...
    
    // MARK: - Setup
    // Восстанавливаем метод setupViews
    private func setupViews() {
        // Добавляем TopMenuView сразу на основное view
        view.addSubview(topMenuView)
    }

    // Восстанавливаем метод setupConstraints
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
        // Удаляем предыдущий дочерний контроллер
        if let currentChild = currentChildVC {
            currentChild.willMove(toParent: nil)
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }
        
        // Добавляем новый дочерний контроллер
        addChild(childVC)
        view.addSubview(childVC.view)
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Устанавливаем констрейнты
        NSLayoutConstraint.activate([
            childVC.view.topAnchor.constraint(equalTo: view.topAnchor), // Растягиваем на весь экран
            childVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Помещаем topMenuView поверх дочернего контроллера
        view.bringSubviewToFront(topMenuView)
        
        childVC.didMove(toParent: self)
        currentChildVC = childVC
    }
}

// MARK: - TopMenuViewDelegate
extension UserProfileContainerViewController: TopMenuViewDelegate {
    // Обновляем логику создания/передачи ViewModel
    func topMenuViewDidSelect(segment: TopMenuView.Segment) {
        print("--- UserProfileContainerVC: Selected segment: \(segment) ---")
        
        guard userID != nil else { 
            print("Error: UserID not configured in UserProfileContainerVC")
            return 
        }
        
        switch segment {
        case .card: 
             if currentChildVC is UserProfileCardViewController { return }
             // TODO: Передать/обновить ViewModel для cardVC?
             displayChildViewController(cardVC)
             
        case .person: 
             if currentChildVC is UserProfileFeedViewController { return }
             // ViewModel уже создан при инициализации lazy var
             // Можно добавить обновление данных, если нужно: personFeedVC.viewModel.fetchAllUserData()
             displayChildViewController(personFeedVC)
             
        case .stats: 
             if currentChildVC is UserProfileStatsViewController { return }
             // ViewModel уже создан при инициализации lazy var
             // Можно добавить обновление данных: statsVC.viewModel.fetchProgressData()
             displayChildViewController(statsVC)
        }
    }
    
    func topMenuViewDidTapBack() {
         print("--- UserProfileContainerVC: Back tapped --- ")
         coordinator?.dismissProfile() 
    }
    
    func topMenuViewDidTapSettings() {
        print("--- UserProfileContainerVC: Settings tapped --- ")
    }
} 