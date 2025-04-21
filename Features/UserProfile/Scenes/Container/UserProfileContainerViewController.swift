import UIKit

class UserProfileContainerViewController: UIViewController {

    // MARK: - Dependencies
    var coordinator: UserProfileCoordinator?

    // MARK: - Child View Controllers
    // Обновляем типы и имена переменных
    private lazy var cardVC: UserProfileCardViewController = {
        let vc = UserProfileCardViewController()
        // TODO: Configure with ViewModel using self.userID
        return vc
    }()
    
    private lazy var personFeedVC: UserProfileFeedViewController = {
        let vc = UserProfileFeedViewController()
        // TODO: Configure with ViewModel using self.userID
        return vc
    }()
    
    private lazy var statsVC: UserProfileStatsViewController = {
        let vc = UserProfileStatsViewController()
        // TODO: Configure with ViewModel using self.userID
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
    private var userID: String? 
    
    func configure(with userID: String) {
        self.userID = userID
        // TODO: Передать userID во ViewModel-и дочерних VC при их создании
        // Важно: Нужно убедиться, что ViewModel создается/обновляется ЗДЕСЬ 
        // перед первым вызовом displayChildViewController, или при каждом вызове.
        print("UserProfileContainerViewController configured for userID: \(userID)")
        // После конфигурации можно показать начальный экран
        // TODO: Определить, какой экран показывать первым (Card? Person?)
        displayChildViewController(cardVC) // Показываем Card по умолчанию
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
       // ... (логика удаления старого и добавления нового - без изменений) ...
        
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
extension UserProfileContainerViewController: TopMenuViewDelegate {
    // Обновляем логику в соответствии с новыми сегментами (Card, Person, Stats)
    func topMenuViewDidSelect(segment: TopMenuView.Segment) {
        print("--- UserProfileContainerVC: Selected segment: \(segment) ---")
        
        guard userID != nil else { 
            print("Error: UserID not configured in UserProfileContainerVC")
            return 
        }
        
        switch segment {
        case .card: // Теперь это .card
             if currentChildVC is UserProfileCardViewController { return }
             // TODO: Передать userID в cardVC.viewModel 
             displayChildViewController(cardVC)
             
        case .person: // Теперь это .person
             if currentChildVC is UserProfileFeedViewController { return }
             // TODO: Передать userID в personFeedVC.viewModel
             displayChildViewController(personFeedVC)
             
        case .stats: // Теперь это .stats
             if currentChildVC is UserProfileStatsViewController { return }
             // TODO: Передать userID в statsVC.viewModel
             displayChildViewController(statsVC)
        // default убран, т.к. Segment - CaseIterable и мы должны обработать все кейсы
        }
    }
    
    func topMenuViewDidTapBack() {
         print("--- UserProfileContainerVC: Back tapped --- ")
         coordinator?.dismissProfile() 
    }
    
    func topMenuViewDidTapSettings() {
        print("--- UserProfileContainerVC: Settings tapped --- ")
        // Убираем вызов, т.к. показ настроек для другого пользователя нелогичен
        // coordinator?.showSettings()
    }
} 