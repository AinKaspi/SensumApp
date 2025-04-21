import UIKit

// Протокол для навигации из VC (только для настроек)
// Удалим этот протокол, он больше не релевантен для профиля другого пользователя
/*
protocol PersonViewControllerDelegate: AnyObject {
    func personViewControllerDidTapSettings(_ controller: UIViewController) 
}
*/

// Переименовываем класс
class UserProfileCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    // Добавим свойство для ID пользователя, чей профиль показываем
    private let userID: String // Или какой у тебя тип ID?
    
    // Инициализатор теперь принимает ID
    init(navigationController: UINavigationController, userID: String) {
        self.navigationController = navigationController
        self.userID = userID
        // Настройка внешнего вида бара здесь может быть не нужна, 
        // если представление будет модальным или кастомным push
        // setupNavigationBarAppearance()
    }

    func start() {
        // Метод start теперь должен создавать и ПРЕДСТАВЛЯТЬ 
        // UserProfileContainerViewController модально или через кастомный push.
        // Пока оставим заглушку, т.к. AppCoordinator его больше не вызывает.
        print("--- UserProfileCoordinator started for userID: \(userID) (Needs presentation logic) ---")
        // Примерная логика (потребует доработки):
        // let containerVC = UserProfileContainerViewController()
        // containerVC.coordinator = self
        // containerVC.configure(with: userID) // Передаем ID дальше
        // navigationController.present(containerVC, animated: true) // Или push
    }
    
    // Убираем старый метод настройки, он будет мешать при модальном представлении
    /*
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black 
        appearance.shadowColor = .clear 
        // appearance.isTranslucent = false // <-- Комментируем из-за ошибки компиляции
        
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = .white 
    }
    */

    // Метод для показа настроек (вероятно, не нужен здесь или требует переосмысления)
    // Оставим пока закомментированным
    /*
    func showSettings() {
        print("--- UserProfileCoordinator: Show Settings Tapped --- ")
        let settingsVC = SettingsViewController() 
        settingsVC.title = "Настройки Пользователя \(userID)?"
        settingsVC.hidesBottomBarWhenPushed = true 
        // Как представлять? Если мы модально, push не сработает.
        // navigationController.pushViewController(settingsVC, animated: true)
    }
    */
    
}

// Удаляем старое расширение
/*
extension PersonCoordinator: PersonViewControllerDelegate { ... }
*/ 
