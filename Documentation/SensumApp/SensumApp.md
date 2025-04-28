Папка: SensumApp
Название папки: SensumApp
Назначение папки: Основная папка приложения, содержащая точку входа, конфигурационные файлы и базовые компоненты координации.
Описание: Эта папка инициализирует приложение. Она отвечает за запуск жизненного цикла приложения (AppDelegate), настройку UI сцен (SceneDelegate), содержит главный координатор (AppCoordinator), который управляет переключением между флоу аутентификации и основным интерфейсом (TabBar), и базовый протокол для всех координаторов (Coordinator.swift). Также здесь лежат конфигурационные файлы (Info.plist, GoogleService-Info.plist), ресурсы (Assets.xcassets, Base.lproj) и модель MediaPipe. Связана со всеми папками Features через AppCoordinator, который создает и запускает координаторы фичей. Связана с Core через использование DIContainer и сервисов.
Содержит:
AppDelegate.swift
SceneDelegate.swift (включая AppCoordinator)
Coordinator.swift
Info.plist
GoogleService-Info.plist
Assets.xcassets/
Base.lproj/
pose_landmarker_full.task
Технологии: UIKit, Combine, FirebaseCore.
Путь: Запуск приложения -> AppDelegate.application(_:didFinishLaunchingWithOptions:) (настройка Firebase) -> AppDelegate.application(_:configurationForConnecting...) -> SceneDelegate.scene(_:willConnectTo:options:) (создание UIWindow, DIContainer, AppCoordinator) -> AppCoordinator.start() (проверка состояния аутентификации AuthService) -> AppCoordinator.showAuthenticationFlow() или AppCoordinator.showMainAppFlow(). Coordinator.swift используется как базовый протокол для всех координаторов.
Файл: AppDelegate.swift
Название файла: AppDelegate.swift
Назначение файла: Управление глобальным жизненным циклом приложения и первичная настройка.
Описание: Класс, отвечающий за основные события жизненного цикла приложения (запуск, переход в фон и т.д.). В данном проекте он инициализирует Firebase (FirebaseApp.configure()) при запуске и настраивает конфигурацию сцен (UISceneConfiguration) для SceneDelegate. Не содержит сложной логики, делегируя управление UI сценам. Связан с SceneDelegate через конфигурацию сцен.
Содержит: Класс AppDelegate, реализующий UIApplicationDelegate, методы application(_:didFinishLaunchingWithOptions:), application(_:configurationForConnecting:options:).
Технологии: UIKit, FirebaseCore.
Путь: Является точкой входа приложения после системного запуска. Вызывает FirebaseApp.configure().
Файл: SceneDelegate.swift
Название файла: SceneDelegate.swift
Назначение файла: Управление жизненным циклом UI сцены, инициализация основного UI и главного координатора приложения.
Описание: Этот файл содержит два основных класса: SceneDelegate и AppCoordinator. SceneDelegate отвечает за настройку окна (UIWindow) при подключении сцены UI. Он создает экземпляр DIContainer и AppCoordinator, передавая им окно и контейнер, а затем запускает AppCoordinator. AppCoordinator является главным координатором приложения. Он решает, какой поток (аутентификация или основное приложение с UITabBarController) показать пользователю, основываясь на состоянии AuthService (полученного из DIContainer). Он создает и управляет дочерними координаторами для каждого таба (Feed, Person, Leveling, Progress, Store) и для флоу аутентификации (AuthCoordinator). Также реализует AuthCoordinatorDelegate для обработки завершения аутентификации и содержит метод showNotifications для модального показа экрана уведомлений. Связан с AppDelegate, DIContainer, AuthService, всеми основными координаторами фичей (FeedCoordinator, CurrentUserProfileCoordinator и т.д.).
Содержит: Класс SceneDelegate (реализует UIWindowSceneDelegate), класс AppCoordinator (реализует Coordinator, AuthCoordinatorDelegate), методы scene(_:willConnectTo:options:), AppCoordinator.start(), AppCoordinator.showMainAppFlow(), AppCoordinator.showAuthenticationFlow(), AppCoordinator.showNotifications().
Технологии: UIKit, Combine.
Путь: Вызывается AppDelegate для настройки сцены. Создает и запускает AppCoordinator. AppCoordinator определяет и запускает либо AuthCoordinator, либо координаторы для табов (FeedCoordinator, CurrentUserProfileCoordinator и т.д.), которые в свою очередь создают VC/VM для своих фичей.
Файл: Coordinator.swift
Название файла: Coordinator.swift
Назначение файла: Определение базового протокола Coordinator и связанных протоколов делегатов.
Описание: Содержит протокол Coordinator, который определяет основной интерфейс для всех координаторов навигации в приложении (наличие navigationController, массива childCoordinators и метода start()). Также содержит extension с базовой реализацией добавления/удаления дочерних координаторов. В этот файл были также перенесены протоколы EditProfileViewControllerDelegate и EditProfileViewModelDelegate для обеспечения их глобальной доступности. Используется всеми классами-координаторами (AppCoordinator, FeedCoordinator и т.д.).
Содержит: Протокол Coordinator, extension Coordinator, протокол EditProfileViewControllerDelegate, протокол EditProfileViewModelDelegate.
Технологии: UIKit, Foundation.
Путь: Используется как базовый тип/интерфейс при создании и управлении всеми координаторами в приложении, начиная с AppCoordinator.