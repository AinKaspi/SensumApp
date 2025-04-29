import UIKit

class UserProfileContainerViewController: UIViewController {

    // MARK: - Dependencies
    var coordinator: UserProfileCoordinator?
    // Добавляем свойства для зависимостей
    private var userID: String!
    private var progressService: ProgressServiceProtocol!
    private var userProfileService: UserProfileServiceProtocol!

    // MARK: - Child View Controllers
    private lazy var cardVC: UserProfileCardViewController = {
        let vc = UserProfileCardViewController()
        // Создаем и инжектируем UserProfileCardViewModel
        let viewModel = UserProfileCardViewModel(
            userID: self.userID, 
            isCurrentUser: false, // Предполагаем, что контейнер используется для чужих профилей
            userProfileService: self.userProfileService, 
            progressService: self.progressService,
            followService: FollowService() // Создаем или передаем self.followService если он есть
        )
        vc.viewModel = viewModel
        return vc
    }()
    
    private lazy var personFeedVC: UserProfileFeedViewController = {
        let vc = UserProfileFeedViewController()
        let viewModel = UserProfileFeedViewModel(
            userID: self.userID,
            isCurrentUser: false, 
            // Передаем userProfileService
            userProfileService: self.userProfileService,
            postService: PostService(),
            followService: FollowService(),
            progressService: self.progressService
        )
        vc.viewModel = viewModel
        // vc.delegate = coordinator // Делегат UserProfileFeedViewControllerDelegate нужен координатору
        return vc
    }()
    
    private lazy var statsVC: UserProfileStatsViewController = {
        let vc = UserProfileStatsViewController()
        let viewModel = UserProfileStatsViewModel(
            userID: self.userID,
            progressService: self.progressService,
            // Передаем userProfileService
            userProfileService: self.userProfileService 
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
    func configure(with userID: String, progressService: ProgressServiceProtocol, userProfileService: UserProfileServiceProtocol) {
        self.userID = userID
        self.progressService = progressService
        self.userProfileService = userProfileService
        print("UserProfileContainerViewController configured for userID: \(userID)")
        // Устанавливаем начальный сегмент в TopMenuView
        topMenuView.setSelectedSegment(.card, animated: false)
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
        // let topBarHeight: CGFloat = 80 // Старая высота
        let topBarHeight: CGFloat = 55 // Новая уменьшенная высота
        // Убираем topBarTopPadding и containerWidthMultiplier
        // let sidePadding: CGFloat = 80 // Старый боковой отступ
        let sidePadding: CGFloat = 20 // Новый боковой отступ (20)
        let topPadding: CGFloat = 15 // Новый верхний отступ от safe area
        
        NSLayoutConstraint.activate([
            // Верхнее меню (отступы по 20 слева/справа, отступ 15 сверху от safe area)
            topMenuView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topPadding), // Привязка к safe area
            topMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sidePadding),
            topMenuView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sidePadding),
            // Убираем старые centerXAnchor и widthAnchor
            // topMenuView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // topMenuView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: containerWidthMultiplier),
            topMenuView.heightAnchor.constraint(equalToConstant: topBarHeight),
        ])
    }
    
    // MARK: - Child VC Management
    private func displayChildViewController(_ childVC: UIViewController) {
        if let currentChild = currentChildVC {
            currentChild.willMove(toParent: nil)
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }
        
        addChild(childVC)
        view.addSubview(childVC.view)
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Возвращаем констрейнты: дочерний VC снова на весь экран
        NSLayoutConstraint.activate([
            childVC.view.topAnchor.constraint(equalTo: view.topAnchor), 
            childVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Возвращаем TopMenuView на передний план
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
             // Сообщаем TopMenuView об изменении
             topMenuView.setSelectedSegment(.card, animated: true)
             
        case .person: 
             if currentChildVC is UserProfileFeedViewController { return }
             // ViewModel уже создан при инициализации lazy var
             // Принудительно обновляем данные
             displayChildViewController(personFeedVC)
             // Принудительно обновляем посты при переключении на эту вкладку
             personFeedVC.refreshUserData()
             // Сообщаем TopMenuView об изменении
             topMenuView.setSelectedSegment(.person, animated: true)
             
        case .stats: 
             if currentChildVC is UserProfileStatsViewController { return }
             // ViewModel уже создан при инициализации lazy var
             // Можно добавить обновление данных: statsVC.viewModel.fetchProgressData()
             displayChildViewController(statsVC)
             // Сообщаем TopMenuView об изменении
             topMenuView.setSelectedSegment(.stats, animated: true)
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