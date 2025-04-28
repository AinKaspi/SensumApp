Структура Проекта SensumApp (Форматированный Список):

[F0] SensumApp
ID: [F0]
Имя: SensumApp
Путь: SensumApp/
Тип: Папка
Назначение: Точка входа, конфигурация, главный координатор
Описание: Эта папка инициализирует приложение. Она отвечает за запуск жизненного цикла приложения (AppDelegate), настройку UI сцен (SceneDelegate), содержит главный координатор (AppCoordinator), который управляет переключением между флоу аутентификации и основным интерфейсом (TabBar), и базовый протокол для всех координаторов (Coordinator.swift). Также здесь лежат конфигурационные файлы (Info.plist, GoogleService-Info.plist), ресурсы (Assets.xcassets, Base.lproj) и модель MediaPipe. Связана со всеми папками Features через AppCoordinator, который создает и запускает координаторы фичей. Связана с Core через использование DIContainer и сервисов.
Содержит: Папки Assets.xcassets, Base.lproj, Файлы: AppDelegate.swift, SceneDelegate.swift (содержит AppCoordinator), Coordinator.swift, Info.plist, GoogleService-Info.plist, pose_landmarker_full.task
Технологии: UIKit, Combine, FirebaseCore
Где используется: Системой iOS для запуска.
Зависимости: Core (через DIContainer), Features (запускает координаторы фичей)

[F0][AppDelegate.swift] AppDelegate.swift
ID: [F0][AppDelegate.swift]
Имя: AppDelegate.swift
Путь: SensumApp/AppDelegate.swift
Тип: Файл
Назначение: Управление глобальным жизненным циклом приложения и первичная настройка.
Описание: Класс, отвечающий за основные события жизненного цикла приложения (запуск, переход в фон и т.д.). В данном проекте он инициализирует Firebase (FirebaseApp.configure()) при запуске и настраивает конфигурацию сцен (UISceneConfiguration) для SceneDelegate. Не содержит сложной логики, делегируя управление UI сценам. Связан с SceneDelegate через конфигурацию сцен.
Содержит: Класс AppDelegate, реализующий UIApplicationDelegate, методы application(:didFinishLaunchingWithOptions:), application(:configurationForConnecting:options:).
Технологии: UIKit, FirebaseCore.
Где используется: Является точкой входа приложения после системного запуска. Вызывает FirebaseApp.configure().
Зависимости: (Не указано в исходном описании для файла)

[F0][SceneDelegate.swift] SceneDelegate.swift
ID: [F0][SceneDelegate.swift]
Имя: SceneDelegate.swift
Путь: SensumApp/SceneDelegate.swift
Тип: Файл
Назначение: Управление UI сценой, главный координатор
Описание: Этот файл содержит два основных класса: SceneDelegate и AppCoordinator. SceneDelegate отвечает за настройку окна (UIWindow) при подключении сцены UI. Он создает экземпляр DIContainer и AppCoordinator, передавая им окно и контейнер, а затем запускает AppCoordinator. AppCoordinator является главным координатором приложения. Он решает, какой поток (аутентификация или основное приложение с UITabBarController) показать пользователю, основываясь на состоянии AuthService (полученного из DIContainer). Он создает и управляет дочерними координаторами для каждого таба (Feed, Person, Leveling, Progress, Store) и для флоу аутентификации (AuthCoordinator). Также реализует AuthCoordinatorDelegate для обработки завершения аутентификации и содержит метод showNotifications для модального показа экрана уведомлений. Связан с AppDelegate, DIContainer, AuthService, всеми основными координаторами фичей (FeedCoordinator, CurrentUserProfileCoordinator и т.д.).
Содержит: Класс SceneDelegate (реализует UIWindowSceneDelegate), класс AppCoordinator (реализует Coordinator, AuthCoordinatorDelegate), методы scene(_:willConnectTo:options:), AppCoordinator.start(), AppCoordinator.showMainAppFlow(), AppCoordinator.showAuthenticationFlow(), AppCoordinator.showNotifications().
Технологии: UIKit, Combine.
Где используется: Вызывается AppDelegate для настройки сцены. Создает и запускает AppCoordinator. AppCoordinator определяет и запускает либо AuthCoordinator, либо координаторы для табов (FeedCoordinator, CurrentUserProfileCoordinator и т.д.), которые в свою очередь создают VC/VM для своих фичей.
Зависимости: (Не указано в исходном описании для файла, но упомянуты в описании: DIContainer, AuthService, Координаторы фичей)

[F0][Coordinator.swift] Coordinator.swift
ID: [F0][Coordinator.swift]
Имя: Coordinator.swift
Путь: SensumApp/Coordinator.swift
Тип: Файл
Назначение: Определение базового протокола Coordinator и связанных протоколов делегатов.
Описание: Содержит протокол Coordinator, который определяет основной интерфейс для всех координаторов навигации в приложении (наличие navigationController, массива childCoordinators и метода start()). Также содержит extension с базовой реализацией добавления/удаления дочерних координаторов. В этот файл были также перенесены протоколы EditProfileViewControllerDelegate и EditProfileViewModelDelegate для обеспечения их глобальной доступности. Используется всеми классами-координаторами (AppCoordinator, FeedCoordinator и т.д.).
Содержит: Протокол Coordinator, extension Coordinator, протокол EditProfileViewControllerDelegate, протокол EditProfileViewModelDelegate.
Технологии: UIKit, Foundation.
Где используется: Используется как базовый тип/интерфейс при создании и управлении всеми координаторами в приложении, начиная с AppCoordinator.
Зависимости: (Не указано в исходном описании для файла)

[F1] Core
ID: [F1]
Имя: Core
Путь: Core/
Тип: Папка
Назначение: Основные переиспользуемые компоненты
Описание: Эта папка содержит фундаментальные строительные блоки приложения: модели данных (Models), сервисы для взаимодействия с бэкендом и выполнения бизнес-логики (Services), и контейнер для управления зависимостями (DI). Код в этой папке используется многими другими частями приложения, особенно ViewModel'ями из папки Features.
Содержит: Папки [F1.1] DI, [F1.2] Models, [F1.3] Services
Технологии: Foundation, FirebaseFirestore, FirebaseStorage, UIKit (в некоторых сервисах), Combine (в некоторых сервисах)
Где используется: SensumApp (через DIContainer), Features (ViewModel'и используют сервисы и модели). Компоненты из Core (сервисы, модели) используются повсеместно, начиная от AppCoordinator (который использует DIContainer для получения сервисов) и далее во всех ViewModel'ях фичей для загрузки/сохранения данных и выполнения действий.
Зависимости: Foundation, Firebase

[F1.1] Core/DI
ID: [F1.1]
Имя: DI
Путь: Core/DI/
Тип: Папка
Назначение: Dependency Injection
Описание: Содержит компоненты, отвечающие за создание и предоставление экземпляров сервисов другим частям приложения. Это помогает уменьшить связанность кода и упростить тестирование. В данном случае содержит DIContainer.
Содержит: Файлы: [F1.1][DIContainer.swift]
Технологии: Foundation.
Где используется: SensumApp/SceneDelegate. DIContainer создается один раз в SceneDelegate и передается в AppCoordinator, который затем использует его для получения экземпляров сервисов (AuthService, ProgressService и т.д.) и передачи их дочерним координаторам.
Зависимости: Core/Services

[F1.1][DIContainer.swift] DIContainer.swift
ID: [F1.1][DIContainer.swift]
Имя: DIContainer.swift
Путь: Core/DI/DIContainer.swift
Тип: Файл
Назначение: DI Контейнер
Описание: Реализует простой контейнер внедрения зависимостей. Он создает экземпляры всех основных сервисов (AuthService, UserProfileService, PostService, FollowService, StorageService, ProgressService) с использованием lazy var, что означает, что сервис создается только при первом обращении к нему. Контейнер также управляет зависимостями между сервисами (например, передает authService и userProfileService в PostService). Экземпляр DIContainer создается в SceneDelegate и используется AppCoordinator.
Содержит: Класс DIContainer со свойствами lazy var для каждого сервиса и init().
Технологии: Foundation.
Где используется: SceneDelegate создает DIContainer. AppCoordinator получает DIContainer и использует его свойства для доступа к сервисам (container.authService, container.progressService и т.д.).
Зависимости: Core/Services.

[F1.2] Core/Models
ID: [F1.2]
Имя: Models
Путь: Core/Models/
Тип: Папка
Назначение: Модели данных (Firestore)
Описание: Определяет структуры данных для Firestore (User, Post, ProgressData, AppNotification, TrainingProgram, Chat). Эта папка содержит основные модели данных приложения: User (информация о пользователе), Post (данные поста), Comment (данные комментария - ошибка: файл Comment.swift находится в Models/, а не Core/Models/), ProgressData (RPG-статистика), Attribute (атрибуты внутри ProgressData), AppNotification (уведомления), TrainingProgram и ProgramStep (программы тренировок). Эти модели реализуют Codable для легкого кодирования/декодирования при работе с Firestore. Они используются сервисами (Core/Services) для получения и сохранения данных, а также ViewModel'ями (Features/*) для отображения данных в UI. Исправление: Модель Comment.swift находится в корневой папке Models/, а не в Core/Models/. Модель Exercise.swift находится в Features/Leveling/Models/. Это небольшое несоответствие в структуре.
Содержит: Файлы: [F1.2][User.swift], [F1.2][Post.swift], [F1.2][ProgressData.swift], [F1.2][AppNotification.swift], [F1.2][TrainingProgram.swift], [F1.2][Chat.swift]. Ожидается также Comment.swift (находится в /Models/). Отсутствует: Exercise.swift (находится в Features/Leveling/Models/)
Технологии: Foundation, FirebaseFirestore.
Где используется: Core/Services, Features (ViewModel'и). Модели используются сервисами при получении данных из Firestore или перед их сохранением. ViewModel'и получают эти модели от сервисов и используют их для подготовки данных к отображению в ViewControllers.
Зависимости: Foundation, FirebaseFirestore.

[F1.2][User.swift] User.swift
ID: [F1.2][User.swift]
Имя: User.swift
Путь: Core/Models/User.swift
Тип: Файл
Назначение: Модель данных пользователя
Описание: Представляет пользователя в системе. Содержит основные данные (ID, имя, email, URL аватара, статус), социальную статистику (подписчики, подписки) и дату создания. Реализует Codable и Identifiable. Использует @DocumentID для связи с ID документа Firestore. Поля followerCount и followingCount опциональны для совместимости с Firestore. Поля RPG (level, xp) удалены, так как они теперь в ProgressData. Используется UserProfileService для сохранения/загрузки и ViewModel'ями профиля для отображения.
Содержит: Структура User (Codable, Identifiable), свойства (id, username, email, avatarURL, status, followerCount?, followingCount?, createdAt), CodingKeys.
Технологии: Foundation, FirebaseFirestore.
Где используется: UserProfileService, UserProfile*ViewModel, EditProfileViewModel. AuthService -> UserProfileService.createUserProfile (при регистрации). UserProfileService.fetchUserProfile -> ViewModel'и (UserProfileFeedViewModel, UserProfileCardViewModel, UserProfileStatsViewModel, EditProfileViewModel).
Зависимости: (Не указано в исходном описании для файла)

[F1.2][Post.swift] Post.swift
ID: [F1.2][Post.swift]
Имя: Post.swift
Путь: Core/Models/Post.swift
Тип: Файл
Назначение: Модель данных поста
Описание: Представляет пост в ленте или профиле. Содержит ID поста, ID автора, URL изображения, текст, дату создания, счетчики лайков/комментариев, а также денормализованные данные автора (имя, URL аватара) для эффективности. Свойство isLiked вычисляется на клиенте. Реализует Codable и Identifiable. Использует @DocumentID и ручную реализацию Codable для исключения isLiked. Используется PostService и ViewModel'ями (FeedViewModel, UserProfileFeedViewModel, UserPostScrollViewModel).
Содержит: Структура Post (Codable, Identifiable), свойства (id, userID, imageURL, caption?, createdAt, likeCount, commentCount, isLiked, authorUsername?, authorAvatarURL?), CodingKeys, init(from:), encode(to:), дополнительный init.
Технологии: Foundation, FirebaseFirestore.
Где используется: PostService, *FeedViewModel, UserPostScrollViewModel, *PostCell. CreatePostViewModel -> PostService.createPost. PostService.fetchPosts/fetchFeedPosts -> ViewModel'и (FeedViewModel, UserProfileFeedViewModel, UserPostScrollViewModel) -> ViewControllers/Cells (PostCell, FullPostCell, PostGridCell). PostService.likePost/unlikePost обновляет likeCount.
Зависимости: (Не указано в исходном описании для файла)

[F1.2][ProgressData.swift] ProgressData.swift
ID: [F1.2][ProgressData.swift]
Имя: ProgressData.swift
Путь: Core/Models/ProgressData.swift
Тип: Файл
Назначение: Модель RPG-прогресса
Описание: Хранит всю информацию, связанную с RPG-прогрессом: уровень, текущий опыт, опыт до следующего уровня, ранг и массив атрибутов. Также содержит структуру Attribute и перечисление AttributeType. Реализует Codable. Используется ProgressService для загрузки/обновления и ViewModel'ями (ExerciseExecutionViewModel, UserProfileFeedViewModel, UserProfileCardViewModel, UserProfileStatsViewModel, ProgressViewModel) для отображения статистики.
Содержит: Структуры ProgressData (Codable), Attribute (Codable), enum AttributeType (String, Codable, CaseIterable, Identifiable), свойства, CodingKeys, метод value(for:).
Технологии: Foundation, FirebaseFirestore.
Где используется: ProgressService, ExerciseExecutionViewModel, UserProfile*ViewModel, ProgressViewModel. ProgressService.fetchProgressData/updateProgressData/addXP <-> Firestore. ProgressService -> ViewModel'и (ExerciseExecutionViewModel, UserProfileFeedViewModel, UserProfileCardViewModel, UserProfileStatsViewModel, ProgressViewModel) -> ViewControllers.
Зависимости: (Не указано в исходном описании для файла)

[F1.2][AppNotification.swift] AppNotification.swift
ID: [F1.2][AppNotification.swift]
Имя: AppNotification.swift
Путь: Core/Models/AppNotification.swift
Тип: Файл
Назначение: Модель уведомлений
Описание: Представляет уведомление. Содержит ID, ID получателя, тип уведомления (NotificationType), информацию об отправителе (опционально), связанном посте (опционально), тексте комментария (опционально), системное сообщение (опционально), статус прочтения и дату создания. Используется NotificationService (заглушка) и будет использоваться NotificationsViewModel/ViewController.
Содержит: Enum NotificationType (String, Codable), структура AppNotification (Codable, Identifiable), свойства, CodingKeys.
Технологии: Foundation, FirebaseFirestore.
Где используется: NotificationService. (В будущем) Бэкенд/Cloud Functions -> Firestore. NotificationService.fetchNotifications -> NotificationsViewModel -> NotificationsViewController.
Зависимости: (Не указано в исходном описании для файла)

[F1.2][TrainingProgram.swift] TrainingProgram.swift
ID: [F1.2][TrainingProgram.swift]
Имя: TrainingProgram.swift
Путь: Core/Models/TrainingProgram.swift
Тип: Файл
Назначение: Модели программ тренировок
Описание: Содержит структуру TrainingProgram (основная информация о программе, включая массив шагов [ProgramStep]) и структуру ProgramStep (один шаг программы с указанием упражнения и цели). Модели реализуют Codable. Используются ProgramService (заглушка) и будут использоваться соответствующими ViewModel/VC для создания, просмотра и выполнения программ.
Содержит: Структуры TrainingProgram (Codable, Identifiable), ProgramStep (Codable, Identifiable, Hashable), enum ProgramStep.TargetType (String, Codable), свойства, CodingKeys.
Технологии: Foundation, FirebaseFirestore.
Где используется: ProgramService. (В будущем) CreateProgramViewModel/VC -> ProgramService.createProgram/updateProgram. ProgramService.fetchUserPrograms/fetchProgram -> ViewModel'и (UserProfileFeedViewModel?, ProgramListViewModel?) -> ViewControllers. LevelingCoordinator/ViewModel -> ProgramService.fetchProgram для запуска.
Зависимости: (Не указано в исходном описании для файла)

[F1.2][Chat.swift] Chat.swift
ID: [F1.2][Chat.swift]
Имя: Chat.swift
Путь: Core/Models/Chat.swift
Тип: Файл
Назначение: Модели чата и сообщений
Описание: Содержит структуру Chat (информация о диалоге между двумя пользователями, включая ID участников, их денормализованные данные и информацию о последнем сообщении LastMessage), структуру LastMessage и структуру ChatMessage (отдельное сообщение). Используются MessagingService (заглушка) и будут использоваться компонентами чата.
Содержит: Структуры Chat (Codable, Identifiable), LastMessage (Codable), ChatMessage (Codable, Identifiable), свойства, CodingKeys.
Технологии: Foundation, FirebaseFirestore.
Где используется: MessagingService. (В будущем) MessagingService <-> Firestore. MessagingService -> ChatListViewModel, ChatViewModel -> ChatListViewController, ChatViewController.
Зависимости: (Не указано в исходном описании для файла)

[F1.3] Core/Services
ID: [F1.3]
Имя: Services
Путь: Core/Services/
Тип: Папка
Назначение: Сервисы бизнес-логики и API
Описание: Содержит классы, инкапсулирующие логику взаимодействия с внешними системами (в основном Firebase) и выполняющие основные операции бизнес-логики. Эта папка является сердцем бэкенд-взаимодействия приложения. Каждый сервис отвечает за определенную область данных или функциональности (аутентификация, профили, посты, прогресс, хранилище и т.д.). Они предоставляют четкие API (через протоколы) для ViewModel, скрывая детали реализации работы с Firestore, Firebase Storage и Firebase Auth. Сервисы создаются и управляются через DIContainer.
Содержит: Файлы: AuthService.swift, FollowService.swift, MessagingService.swift, NotificationService.swift, PostService.swift, ProgramService.swift, ProgressService.swift, StorageService.swift, UserProfileService.swift
Технологии: Foundation, FirebaseFirestore, FirebaseAuth, FirebaseStorage, Combine (в AuthService).
Где используется: Core/DI/DIContainer.swift, Features (ViewModel'и). DIContainer создает экземпляры сервисов. ViewModel'и (в Features/*) получают экземпляры сервисов (через координаторы или DI) и вызывают их методы для загрузки/сохранения данных или выполнения действий.
Зависимости: Core/Models, Foundation, Firebase.

[F1.3][AuthService.swift] AuthService.swift
ID: [F1.3][AuthService.swift]
Имя: AuthService.swift
Путь: Core/Services/AuthService.swift
Тип: Файл
Назначение: Сервис Аутентификации
Описание: Предоставляет методы для регистрации (registerUser), входа (signInUser, signInWithGoogle), выхода (signOut) и проверки текущего состояния аутентификации (checkAuthenticationState, currentUserID). Использует FirebaseAuth и GoogleSignIn. Публикует текущее состояние аутентификации (authenticationState) через CurrentValueSubject из Combine, что позволяет AppCoordinator реагировать на изменения.
Содержит: Протокол AuthServiceProtocol, класс AuthService, enum AuthenticationState, методы аутентификации, свойства authenticationState и currentUserID.
Технологии: Foundation, FirebaseAuth, GoogleSignIn, Combine, FirebaseCore.
Где используется: DIContainer, AppCoordinator, AuthCoordinator, RegisterViewModel, LoginViewModel, другие сервисы/VM (для currentUserID). Создается в DIContainer. Используется AppCoordinator (для подписки на состояние и вызова checkAuthenticationState/signOut), AuthCoordinator (для вызова signInUser/registerUser/signInWithGoogle), RegisterViewModel (вызывает registerUser), LoginViewModel (вызывает signInUser). Многие другие ViewModel'и и сервисы используют authService.currentUserID.
Зависимости: (Не указано в исходном описании для файла)

[F1.3][FollowService.swift] FollowService.swift
ID: [F1.3][FollowService.swift]
Имя: FollowService.swift
Путь: Core/Services/FollowService.swift
Тип: Файл
Назначение: Сервис Подписок
Описание: Предоставляет методы для подписки (follow), отписки (unfollow) и проверки статуса подписки (checkIfFollowing, fetchFollowers, fetchFollowing). Работает с Firestore, обновляя счетчики followerCount и followingCount в документах пользователей (users collection) и создавая/удаляя документы в подколлекциях user-followers и user-following для хранения связей. Используется ViewModel'ями профиля (UserProfileFeedViewModel, UserProfileCardViewModel).
Содержит: Протокол FollowServiceProtocol, класс FollowService, методы follow, unfollow, checkIfFollowing, fetchFollowers, fetchFollowing.
Технологии: Foundation, FirebaseFirestore.
Где используется: DIContainer, UserProfileFeedViewModel, UserProfileCardViewModel. Создается в DIContainer. Используется UserProfileFeedViewModel, UserProfileCardViewModel для проверки и обновления статуса подписки.
Зависимости: (Не указано в исходном описании для файла)

[F1.3][MessagingService.swift] MessagingService.swift
ID: [F1.3][MessagingService.swift]
Имя: MessagingService.swift
Путь: Core/Services/MessagingService.swift
Тип: Файл
Назначение: Сервис Сообщений (Заглушка)
Описание: Должен предоставлять методы для загрузки списка чатов, загрузки сообщений чата (с пагинацией), отправки сообщений и создания новых чатов. В текущей реализации содержит только протокол и пустые методы-заглушки. Будет использоваться компонентами чата (ViewModel/VC).
Содержит: Протокол MessagingServiceProtocol, класс MessagingService (заглушка).
Технологии: Foundation, FirebaseFirestore (в будущем).
Где используется: DIContainer. (В будущем) Создается в DIContainer. Используется ChatListViewModel, ChatViewModel.
Зависимости: (Не указано в исходном описании для файла)

[F1.3][NotificationService.swift] NotificationService.swift
ID: [F1.3][NotificationService.swift]
Имя: NotificationService.swift
Путь: Core/Services/NotificationService.swift
Тип: Файл
Назначение: Сервис Уведомлений (Заглушка)
Описание: Должен предоставлять методы для загрузки уведомлений и отметки их как прочитанных. Текущая реализация - заглушка. Будет использоваться NotificationsViewModel.
Содержит: Протокол NotificationServiceProtocol, класс NotificationService (заглушка).
Технологии: Foundation, FirebaseFirestore (в будущем).
Где используется: DIContainer. (В будущем) Создается в DIContainer. Используется NotificationsViewModel.
Зависимости: (Не указано в исходном описании для файла)

[F1.3][PostService.swift] PostService.swift
ID: [F1.3][PostService.swift]
Имя: PostService.swift
Путь: Core/Services/PostService.swift
Тип: Файл
Назначение: Сервис Постов
Описание: Предоставляет методы для создания поста (createPost - с денормализацией данных автора), загрузки постов пользователя (fetchPosts - с пагинацией), загрузки ленты (fetchFeedPosts - с пагинацией), установки/снятия лайка (likePost, unlikePost - с обновлением счетчика и записи в подколлекцию), загрузки и добавления комментариев (fetchComments, addComment - с денормализацией и обновлением счетчика). Использует Firestore.
Содержит: Протокол PostServiceProtocol, класс PostService, методы для работы с постами, лайками, комментариями.
Технологии: Foundation, FirebaseFirestore, FirebaseFirestoreSwift.
Где используется: DIContainer, FeedViewModel, UserProfileFeedViewModel, UserPostScrollViewModel, CommentsViewModel, CreatePostViewModel. Создается в DIContainer.
Зависимости: (Не указано в исходном описании для файла)

[F1.3][ProgramService.swift] ProgramService.swift
ID: [F1.3][ProgramService.swift]
Имя: ProgramService.swift
Путь: Core/Services/ProgramService.swift
Тип: Файл
Назначение: Сервис Программ Тренировок (Заглушка)
Описание: Должен предоставлять CRUD-операции для программ тренировок (TrainingProgram, ProgramStep) в Firestore. Текущая реализация - заглушка. Будет использоваться компонентами создания/просмотра/выполнения программ.
Содержит: Протокол ProgramServiceProtocol, класс ProgramService (заглушка).
Технологии: Foundation, FirebaseFirestore (в будущем).
Где используется: DIContainer. (В будущем) Создается в DIContainer. Используется CreateProgramViewModel, ProgramListViewModel, ProgramExecutionViewModel и т.д.
Зависимости: (Не указано в исходном описании для файла)

[F1.3][ProgressService.swift] ProgressService.swift
ID: [F1.3][ProgressService.swift]
Имя: ProgressService.swift
Путь: Core/Services/ProgressService.swift
Тип: Файл
Назначение: Сервис RPG-Прогресса
Описание: Предоставляет методы для загрузки (fetchProgressData) и обновления (updateProgressData, addXP) данных ProgressData в Firestore. Метод addXP инкапсулирует логику добавления опыта, расчета бонуса от атрибутов, повышения уровня (с расчетом xpToNextLevel), обновления ранга (calculateRank) и применения прироста атрибутов (applyAttributeGains). Используется ViewModel'ями, связанными с отображением или изменением прогресса.
Содержит: Протокол ProgressServiceProtocol, класс ProgressService, методы fetchProgressData, updateProgressData, addXP, calculateRank, calculateXPForLevel, calculateXpBonus, applyAttributeGains.
Технологии: Foundation, FirebaseFirestore, FirebaseFirestoreSwift.
Где используется: DIContainer, RegisterViewModel, ExerciseExecutionViewModel, UserProfile*ViewModel, ProgressViewModel. Создается в DIContainer. Используется RegisterViewModel (для создания), ExerciseExecutionViewModel (для addXP), UserProfileFeedViewModel, UserProfileCardViewModel, UserProfileStatsViewModel, ProgressViewModel (для fetchProgressData).
Зависимости: (Не указано в исходном описании для файла)

[F1.3][StorageService.swift] StorageService.swift
ID: [F1.3][StorageService.swift]
Имя: StorageService.swift
Путь: Core/Services/StorageService.swift
Тип: Файл
Назначение: Сервис Хранилища
Описание: Предоставляет методы для загрузки изображений постов (uploadPostImage) и аватаров (uploadAvatarImage). Загружает UIImage (конвертируя в Data) в указанную папку (post_images или avatars) и возвращает URL для скачивания.
Содержит: Протокол StorageServiceProtocol, класс StorageService, методы uploadPostImage, uploadAvatarImage. (Содержит также общий метод uploadImage, который не используется напрямую в протоколе).
Технологии: Foundation, FirebaseStorage, UIKit.
Где используется: DIContainer, CreatePostViewModel, EditProfileViewModel. Создается в DIContainer. Используется CreatePostViewModel (для uploadPostImage), EditProfileViewModel (для uploadAvatarImage).
Зависимости: (Не указано в исходном описании для файла)

[F1.3][UserProfileService.swift] UserProfileService.swift
ID: [F1.3][UserProfileService.swift]
Имя: UserProfileService.swift
Путь: Core/Services/UserProfileService.swift
Тип: Файл
Назначение: Сервис Профиля Пользователя
Описание: Предоставляет методы для создания документа пользователя (createUserProfile), загрузки профиля по ID (fetchUserProfile) и частичного обновления профиля (updateUserProfile). Работает с коллекцией users в Firestore и моделью User.
Содержит: Протокол UserProfileServiceProtocol, класс UserProfileService, методы createUserProfile, fetchUserProfile, updateUserProfile.
Технологии: Foundation, FirebaseFirestore.
Где используется: DIContainer, RegisterViewModel, PostService, EditProfileViewModel, UserProfile*ViewModel. Создается в DIContainer. Используется RegisterViewModel (для createUserProfile), PostService (для fetchUserProfile при создании поста), EditProfileViewModel (для fetchUserProfile и updateUserProfile), UserProfileFeedViewModel, UserProfileCardViewModel, UserProfileStatsViewModel (для fetchUserProfile).
Зависимости: (Не указано в исходном описании для файла)

[F2] Features
ID: [F2]
Имя: Features
Путь: Features/
Тип: Папка
Назначение: Функциональные модули (фичи)
Описание: Организует код по основным разделам приложения (Лента, Профиль, Тренировки и т.д.), следуя MVVM+C. Эта папка организует код по функциональным модулям (например, Аутентификация, Лента, Профиль, Тренировки). Каждая подпапка обычно следует паттерну MVVM+C, содержа внутри себя координатор(ы), сцены/экраны (ViewControllers), ViewModel'и и кастомные View, относящиеся к данной фиче. Это помогает разделить логику и UI по функциональным блокам, улучшая структуру и поддерживаемость проекта. ViewModel'и из этой папки активно взаимодействуют с сервисами из Core/Services.
Содержит: Папки [F2.1] Authentication, [F2.2] Create, [F2.3] CurrentUserProfile, [F2.4] Feed, [F2.5] Leveling, [F2.6] Notifications, [F2.7] Progress, [F2.8] Store, [F2.9] UserProfile
Технологии: UIKit, Combine, DGCharts, Kingfisher, MediaPipeTasksVision и другие, специфичные для каждой фичи.
Где используется: SensumApp/AppCoordinator. Координаторы фичей (AuthCoordinator, FeedCoordinator и т.д.) запускаются AppCoordinator. Они, в свою очередь, создают и показывают ViewControllers и ViewModel'и из соответствующих подпапок внутри Features.
Зависимости: Core, UIKit, Combine и др.

[F2.1] Features/Authentication
ID: [F2.1]
Имя: Authentication
Путь: Features/Authentication/
Тип: Папка
Назначение: Флоу Аутентификации
Описание: Содержит координатор и экраны (Login, Register) для входа/регистрации пользователя. Содержит все компоненты, необходимые для аутентификации: координатор (AuthCoordinator), который управляет навигацией между экранами входа и регистрации, и сами экраны (Scenes), реализованные по MVVM (LoginViewController/LoginViewModel, RegisterViewController/RegisterViewModel). ViewModel'и взаимодействуют с AuthService и UserProfileService для выполнения операций и создания пользователя.
Содержит: Папки Coordinators, Scenes
Технологии: UIKit, Combine, Foundation.
Где используется: AppCoordinator. AppCoordinator (при состоянии .signedOut или .unknown) -> AuthCoordinator.start() -> AuthCoordinator.showLoginScreen() (создает LoginViewModel, LoginViewController) -> (при нажатии "Register") AuthCoordinator.showRegisterScreen() (создает RegisterViewModel, RegisterViewController).
Зависимости: Core/Services, UIKit, Combine.

[F2.1][AuthCoordinator.swift] AuthCoordinator.swift
ID: [F2.1][AuthCoordinator.swift]
Имя: AuthCoordinator.swift
Путь: Features/Authentication/Coordinators/AuthCoordinator.swift
Тип: Файл
Назначение: Координатор Аутентификации
Описание: Управление навигацией в рамках флоу аутентификации. Отвечает за показ экрана входа (showLoginScreen) и переход на экран регистрации (showRegisterScreen). Создает и связывает LoginViewModel с LoginViewController и RegisterViewModel с RegisterViewController. Реализует делегаты (LoginViewControllerDelegate, LoginViewModelCoordinatorDelegate, RegisterViewControllerDelegate) для обработки пользовательских действий (нажатие кнопок "Register", "Google Sign In") и инициирования навигации или вызова AuthService. Уведомляет родительский AppCoordinator (через AuthCoordinatorDelegate) об успешном завершении аутентификации (хотя сейчас основная логика переключения флоу завязана на AuthService.authenticationState). Получает зависимости (AuthService, ProgressService) через init.
Содержит: Класс AuthCoordinator, протокол AuthCoordinatorDelegate, методы start, showLoginScreen, showRegisterScreen, реализации методов делегатов.
Технологии: UIKit.
Где используется: AppCoordinator (запускает), LoginViewController, RegisterViewController, LoginViewModel. AppCoordinator -> AuthCoordinator.start() -> showLoginScreen() / showRegisterScreen().
Зависимости: (Не указано в исходном описании для файла)

[F2.2] Features/Create
ID: [F2.2]
Имя: Create
Путь: Features/Create/
Тип: Папка
Назначение: Создание контента
Описание: Содержит экран и ViewModel для создания нового поста. Содержит компоненты для экрана создания нового поста с изображением и текстом. Используется UserProfileFeedViewController для инициации флоу создания поста после выбора изображения.
Содержит: Папки Scenes, ViewModels
Технологии: Core/Services, UIKit, Combine, PhotosUI.
Где используется: UserProfileFeedViewController. UserProfileFeedViewController (после выбора изображения через PHPicker) -> Создание CreatePostViewModel и CreatePostViewController -> Модальный показ CreatePostViewController.
Зависимости: Core/Services, UIKit, Combine, PhotosUI.

[F2.2][CreatePostViewController.swift] CreatePostViewController.swift
ID: [F2.2][CreatePostViewController.swift]
Имя: CreatePostViewController.swift
Путь: Features/Create/Scenes/CreatePostViewController.swift
Тип: Файл
Назначение: UI Экрана Создания Поста
Описание: Отображение превью, поля текста. Кнопки Share/Cancel. Обработка делегата CreatePostViewModelDelegate. Отображает выбранное изображение (postImageView), поле для ввода текста (captionTextView), кнопку "Поделиться" (shareButton) и кнопку отмены ("Назад"). Связан с CreatePostViewModel через Combine для отображения изображения, управления состоянием кнопки "Поделиться" и индикатора загрузки. При нажатии "Поделиться" вызывает viewModel.sharePost(). Уведомляет своего делегата (CreatePostViewControllerDelegate - реализуется UserProfileFeedViewController) о завершении (didFinishCreatingPost) или отмене (didCancelCreatingPost).
Содержит: Класс CreatePostViewController, протокол CreatePostViewControllerDelegate, UI элементы (UIImageView, UITextView, UIBarButtonItem), @objc методы, setupBindings(), setupViews(), setupConstraints().
Технологии: UIKit, Combine.
Где используется: UserProfileFeedViewController (показывает), CreatePostViewModel. Создается и показывается модально из UserProfileFeedViewController.showCreatePostScreen(). Вызывает viewModel.sharePost(). Вызывает методы своего делегата (UserProfileFeedViewController) для закрытия.
Зависимости: (Не указано в исходном описании для файла)

[F2.2][CreatePostViewModel.swift] CreatePostViewModel.swift
ID: [F2.2][CreatePostViewModel.swift]
Имя: CreatePostViewModel.swift
Путь: Features/Create/ViewModels/CreatePostViewModel.swift
Тип: Файл
Назначение: Логика Экрана Создания Поста
Описание: Вызов StorageService (загрузка фото), PostService (создание поста). Управление isLoading/errorMessage. Хранит выбранное изображение (selectedImage) и введенный текст (captionText). Содержит метод sharePost(). Уведомляет делегата (delegate) об успешном завершении или ошибке.
Содержит: Класс CreatePostViewModel, протокол CreatePostViewModelDelegate, @Published свойства, метод sharePost().
Технологии: Combine, Foundation, UIKit (для UIImage).
Где используется: UserProfileFeedViewController (создает), CreatePostViewController. Создается в UserProfileFeedViewController.showCreatePostScreen(). Вызывается sharePost() из CreatePostViewController. Взаимодействует с StorageService и PostService.
Зависимости: (Не указано в исходном описании для файла)

[F2.3] Features/CurrentUserProfile
ID: [F2.3]
Имя: CurrentUserProfile
Путь: Features/CurrentUserProfile/
Тип: Папка
Назначение: Логика Таба 2 (Свой профиль)
Описание: Содержит координатор для Таба 2 и специфичные для него экраны/VM (редактирование профиля). Содержит координатор (CurrentUserProfileCoordinator), отвечающий за запуск и управление флоу Таба 2. Он показывает основной экран профиля (UserProfileFeedViewController из папки UserProfile), обрабатывает действия, специфичные для текущего пользователя (например, выход из системы, переход к редактированию профиля, создание нового поста/программы), и инициирует навигацию на другие экраны (редактирование, скролл постов, комментарии). Также содержит специфичные для этого флоу ViewModel'и (например, EditProfileViewModel) и экраны (EditProfileViewController).
Содержит: Папки Coordinators, Scenes, ViewModels
Технологии: Core/Services, Features/UserProfile, UIKit, Combine.
Где используется: AppCoordinator. AppCoordinator (в showMainAppFlow) -> CurrentUserProfileCoordinator.start() -> Показ UserProfileFeedViewController.
Зависимости: Core/Services, Features/UserProfile, UIKit, Combine.

[F2.3][CurrentUserProfileCoordinator.swift] CurrentUserProfileCoordinator.swift
ID: [F2.3][CurrentUserProfileCoordinator.swift]
Имя: CurrentUserProfileCoordinator.swift
Путь: Features/CurrentUserProfile/Coordinators/CurrentUserProfileCoordinator.swift
Тип: Файл
Назначение: Координатор Таба 2 (Свой профиль)
Описание: Запуск UserProfileFeedViewController (с isCurrentUser=true). Обработка делегатов от VC (Sign Out, Edit, New Program). Навигация на Edit/Comments/UserPostScroll. Инициализирует и показывает UserProfileFeedViewController (передавая ему isCurrentUser: true). Реализует UserProfileFeedViewControllerDelegate для обработки действий: выход (didRequestSignOut -> authService.signOut), переход к редактированию (didTapEditProfileButton -> showEditProfile), создание программы (didTapNewProgramButton - заглушка). Также реализует EditProfileViewControllerDelegate (для закрытия экрана редактирования) и UserPostScrollViewControllerDelegate (для навигации на комментарии из ленты постов). Создает и показывает EditProfileViewController и UserPostScrollViewController (заглушка).
Содержит: Класс CurrentUserProfileCoordinator, реализации делегатов UserProfileFeedViewControllerDelegate, EditProfileViewControllerDelegate, UserPostScrollViewControllerDelegate, методы start, showEditProfile, showUserPostScroll, didTapCommentsButton.
Технологии: UIKit.
Где используется: AppCoordinator (запускает), UserProfileFeedViewController, EditProfileViewController, UserPostScrollViewController. AppCoordinator -> CurrentUserProfileCoordinator.start().
Зависимости: (Не указано в исходном описании для файла)

[F2.3][EditProfileViewController.swift] EditProfileViewController.swift
ID: [F2.3][EditProfileViewController.swift]
Имя: EditProfileViewController.swift
Путь: Features/CurrentUserProfile/Scenes/EditProfile/EditProfileViewController.swift
Тип: Файл
Назначение: UI Экрана Редактирования
Описание: Отображение полей (аватар, имя, статус). Выбор фото (PHPicker). Вызов VM для сохранения. Отображает текущий аватар, поля для редактирования имени и статуса/био, кнопку смены аватара. Использует PHPickerViewController для выбора нового изображения. Реализует UITextViewDelegate для логики плейсхолдера. Связан с EditProfileViewModel через Combine для загрузки начальных данных и отображения состояния загрузки/ошибок. При нажатии "Save" вызывает viewModel.saveProfile, при нажатии "Cancel" уведомляет делегата (CurrentUserProfileCoordinator) через EditProfileViewControllerDelegate.
Содержит: Класс EditProfileViewController, протокол EditProfileViewControllerDelegate, реализация PHPickerViewControllerDelegate, UITextViewDelegate, методы setupBindings, checkForChanges.
Технологии: UIKit, Combine, PhotosUI, Kingfisher.
Где используется: CurrentUserProfileCoordinator (показывает), EditProfileViewModel. CurrentUserProfileCoordinator.showEditProfile() -> Создание и показ EditProfileViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.3][EditProfileViewModel.swift] EditProfileViewModel.swift
ID: [F2.3][EditProfileViewModel.swift]
Имя: EditProfileViewModel.swift
Путь: Features/CurrentUserProfile/ViewModels/EditProfileViewModel.swift
Тип: Файл
Назначение: Логика Экрана Редактирования
Описание: Загрузка данных (UserProfileService), сохранение (вызов StorageService для аватара, UserProfileService для данных). Загружает начальные данные пользователя (loadInitialData через UserProfileService). Содержит метод saveProfile, который определяет измененные данные, загружает новый аватар (если выбран) через StorageService, а затем обновляет документ пользователя в Firestore через UserProfileService.updateUserProfile. Управляет состояниями isLoading, errorMessage. Уведомляет координатора о завершении через EditProfileViewModelDelegate.
Содержит: Класс EditProfileViewModel, протокол EditProfileViewModelDelegate, @Published свойства, методы loadInitialData, saveProfile.
Технологии: Combine, Foundation, UIKit, FirebaseFirestore.
Где используется: CurrentUserProfileCoordinator (создает), EditProfileViewController. Создается в CurrentUserProfileCoordinator.showEditProfile(). Вызывается из EditProfileViewController. Взаимодействует с UserProfileService, StorageService, AuthService.
Зависимости: (Не указано в исходном описании для файла)

[F2.4] Features/Feed
ID: [F2.4]
Имя: Feed
Путь: Features/Feed/
Тип: Папка
Назначение: Лента постов (Таб 1)
Описание: Содержит координатор, экран ленты, ViewModel, кастомные View (ячейки поста, сторис), а также компоненты для комментариев и скролла постов.
Содержит: Папки Coordinators, Models (пусто), Scenes, ViewModels, Views
Технологии: Core/Services, Features/UserProfile, UIKit, Combine, Kingfisher
Где используется: AppCoordinator.
Зависимости: Core/Services, Features/UserProfile, UIKit, Combine, Kingfisher.

[F2.4][FeedCoordinator.swift] FeedCoordinator.swift
ID: [F2.4][FeedCoordinator.swift]
Имя: FeedCoordinator.swift
Путь: Features/Feed/Coordinators/FeedCoordinator.swift
Тип: Файл
Назначение: Координатор Таба 1 (Лента)
Описание: Запуск FeedViewController. Навигация на профиль пользователя (showUserProfile) и комментарии (showComments).
Содержит: Класс FeedCoordinator.
Технологии: UIKit.
Где используется: AppCoordinator (запускает), FeedViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.4][FeedViewModel.swift] FeedViewModel.swift
ID: [F2.4][FeedViewModel.swift]
Имя: FeedViewModel.swift
Путь: Features/Feed/ViewModels/FeedViewModel.swift
Тип: Файл
Назначение: Логика Ленты
Описание: Загрузка постов ленты (WorkspacePosts с пагинацией через PostService). Загрузка пользователей для "сторис" (заглушка). Обработка лайков (toggleLike). Обновление по NotificationCenter.
Содержит: Класс FeedViewModel.
Технологии: Combine, Foundation, FirebaseFirestore.
Где используется: FeedCoordinator (создает), FeedViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.4][FeedViewController.swift] FeedViewController.swift
ID: [F2.4][FeedViewController.swift]
Имя: FeedViewController.swift
Путь: Features/Feed/Scenes/FeedList/FeedViewController.swift
Тип: Файл
Назначение: UI Экрана Ленты
Описание: Отображение TopBarView, StoriesHeaderView (с UICollectionView), UITableView с постами (PostCell). Обработка пагинации, pull-to-refresh. Реализация делегатов (PostCellDelegate, UICollectionViewDataSource/Delegate).
Содержит: Класс FeedViewController, реализация делегатов.
Технологии: UIKit, Combine.
Где используется: FeedCoordinator (создает), FeedViewModel, PostCell, StoryCell, StoriesHeaderView.
Зависимости: (Не указано в исходном описании для файла)

[F2.4][CommentsViewController.swift] CommentsViewController.swift
ID: [F2.4][CommentsViewController.swift]
Имя: CommentsViewController.swift
Путь: Features/Feed/Scenes/Comments/CommentsViewController.swift
Тип: Файл
Назначение: UI Экрана Комментариев
Описание: Отображение списка комментариев (UITableView с CommentCell). Поле ввода текста, кнопка отправки.
Содержит: Класс CommentsViewController, реализация UITableViewDataSource, UITextViewDelegate.
Технологии: UIKit, Combine, Kingfisher.
Где используется: FeedCoordinator, CurrentUserProfileCoordinator (показывают), CommentsViewModel.
Зависимости: (Не указано в исходном описании для файла)

[F2.4][CommentsViewModel.swift] CommentsViewModel.swift
ID: [F2.4][CommentsViewModel.swift]
Имя: CommentsViewModel.swift
Путь: Features/Feed/ViewModels/CommentsViewModel.swift
Тип: Файл
Назначение: Логика Экрана Комментариев
Описание: Загрузка (WorkspaceComments) и добавление (addComment) комментариев через PostService.
Содержит: Класс CommentsViewModel.
Технологии: Combine, Foundation.
Где используется: FeedCoordinator, CurrentUserProfileCoordinator (создают), CommentsViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.4][CommentCell.swift] CommentCell.swift
ID: [F2.4][CommentCell.swift]
Имя: CommentCell.swift
Путь: Features/Feed/Views/CommentCell.swift
Тип: Файл
Назначение: Ячейка Комментария
Описание: Отображение аватара, имени, текста комментария и времени.
Содержит: Класс CommentCell.
Технологии: UIKit, Kingfisher.
Где используется: CommentsViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.4][UserPostScrollViewController.swift] UserPostScrollViewController.swift
ID: [F2.4][UserPostScrollViewController.swift]
Имя: UserPostScrollViewController.swift
Путь: Features/Feed/Scenes/UserPostScroll/UserPostScrollViewController.swift
Тип: Файл
Назначение: UI Экрана Ленты Постов Пользователя
Описание: Отображение постов (FullPostCell) в UICollectionView (с пагинацией). Обработка действий (лайк, коммент, автор).
Содержит: Класс UserPostScrollViewController, реализация UICollectionViewDataSource, Delegate, FlowLayout, FullPostCellDelegate.
Технологии: UIKit, Combine.
Где используется: CurrentUserProfileCoordinator (показывает), UserPostScrollViewModel, FullPostCell.
Зависимости: (Не указано в исходном описании для файла)

[F2.4][UserPostScrollViewModel.swift] UserPostScrollViewModel.swift
ID: [F2.4][UserPostScrollViewModel.swift]
Имя: UserPostScrollViewModel.swift
Путь: Features/Feed/ViewModels/UserPostScrollViewModel.swift
Тип: Файл
Назначение: Логика Ленты Постов Пользователя
Описание: Загрузка постов для userID (WorkspaceMorePosts с пагинацией через PostService). Обработка лайков (toggleLike).
Содержит: Класс UserPostScrollViewModel.
Технологии: Combine, Foundation, FirebaseFirestore.
Где используется: CurrentUserProfileCoordinator (создает), UserPostScrollViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.4][FullPostCell.swift] FullPostCell.swift
ID: [F2.4][FullPostCell.swift]
Имя: FullPostCell.swift
Путь: Features/Feed/Views/FullPostCell.swift
Тип: Файл
Назначение: Ячейка Поста (Детальная)
Описание: Отображение поста в полном виде (шапка автора, фото, кнопки действий, счетчик лайков, текст, кнопка "все комментарии").
Содержит: Класс FullPostCell, протокол FullPostCellDelegate.
Технологии: UIKit, Kingfisher.
Где используется: UserPostScrollViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.4][StoryCell.swift] StoryCell.swift
ID: [F2.4][StoryCell.swift]
Имя: StoryCell.swift
Путь: Features/Feed/Views/StoryCell.swift
Тип: Файл
Назначение: Ячейка "Сторис"
Описание: Отображение круглого аватара и имени пользователя.
Содержит: Класс StoryCell.
Технологии: UIKit, Kingfisher.
Где используется: FeedViewController (через StoriesHeaderView).
Зависимости: (Не указано в исходном описании для файла)

[F2.4][StoriesHeaderView.swift] StoriesHeaderView.swift
ID: [F2.4][StoriesHeaderView.swift]
Имя: StoriesHeaderView.swift
Путь: Features/Feed/Views/StoriesHeaderView.swift
Тип: Файл
Назначение: View для Хедера со "Сторис"
Описание: Содержит UICollectionView для горизонтальной прокрутки StoryCell. Используется как tableHeaderView.
Содержит: Класс StoriesHeaderView.
Технологии: UIKit.
Где используется: FeedViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.5] Features/Leveling
ID: [F2.5]
Имя: Leveling
Путь: Features/Leveling/
Тип: Папка
Назначение: Флоу Тренировок (Таб 3)
Описание: Содержит координатор, экраны выбора/выполнения упражнений, ViewModel'и, анализаторы, хелперы для MediaPipe, модель Exercise. Это одна из самых сложных фичей. Содержит координатор, экраны выбора и выполнения упражнения, ViewModel'и для них, модели данных (Exercise), специализированные классы-анализаторы для конкретных упражнений (Analyzers), хелперы для работы с MediaPipe (Helpers) и другие утилиты (например, фильтры Калмана). ViewModel (ExerciseExecutionViewModel) тесно интегрирована с PoseLandmarkerHelper, анализаторами и ProgressService для обработки позы, подсчета повторений и начисления наград.
Содержит: Папки Analyzers, Coordinators, Helpers, Models, Utils, ViewControllers, ViewModels, Views
Технологии: Core/Services, UIKit, Combine, MediaPipeTasksVision, AVFoundation, CoreMotion, simd.
Где используется: AppCoordinator. AppCoordinator -> LevelingCoordinator.start() -> ExerciseSelectionViewController -> (выбор упражнения) -> LevelingCoordinator.exerciseSelectionViewModelDidSelect() -> ExerciseExecutionViewController.
Зависимости: Core/Services, UIKit, Combine, MediaPipeTasksVision, AVFoundation, CoreMotion, simd.

[F2.5][LevelingCoordinator.swift] LevelingCoordinator.swift
ID: [F2.5][LevelingCoordinator.swift]
Имя: LevelingCoordinator.swift
Путь: Features/Leveling/Coordinators/LevelingCoordinator.swift
Тип: Файл
Назначение: Координатор Тренировок
Описание: Навигация Выбор <-> Выполнение. Создание VC/VM. Инициализация PoseLandmarkerHelper. Реализует Coordinator. В start показывает экран выбора упражнения (ExerciseSelectionViewController), создавая для него ExerciseSelectionViewModel. Реализует ExerciseSelectionViewModelCoordinatorDelegate: при выборе упражнения (exerciseSelectionViewModelDidSelect) создает ExerciseExecutionViewModel (передавая ему упражнение, PoseLandmarkerHelper, сервисы) и ExerciseExecutionViewController, а затем показывает экран выполнения упражнения (pushViewController). Инициализирует PoseLandmarkerHelper в фоновом потоке при своем создании. Получает зависимости (AuthService, ProgressService) через init.
Содержит: Класс LevelingCoordinator, реализация ExerciseSelectionViewModelCoordinatorDelegate, методы start, exerciseSelectionViewModelDidSelect, setupPoseLandmarkerHelperInBackground.
Технологии: UIKit, MediaPipeTasksVision.
Где используется: AppCoordinator (запускает), ExerciseSelectionViewController, ExerciseExecutionViewController. AppCoordinator -> LevelingCoordinator.start() -> ExerciseSelectionViewController. ExerciseSelectionViewModel -> LevelingCoordinator.exerciseSelectionViewModelDidSelect() -> ExerciseExecutionViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.5][ExerciseAnalyzerProtocols.swift] ExerciseAnalyzerProtocols.swift
ID: [F2.5][ExerciseAnalyzerProtocols.swift]
Имя: ExerciseAnalyzerProtocols.swift
Путь: Features/Leveling/Analyzers/ExerciseAnalyzerProtocols.swift
Тип: Файл
Назначение: Протоколы Анализаторов
Описание: Определение протоколов и констант для анализаторов упражнений. Содержит протокол ExerciseAnalyzerDelegate (для обратной связи от анализатора к ViewModel о повторениях и смене состояния) и протокол ExerciseAnalyzer (основной интерфейс анализатора с методами analyze и reset). Также содержит enum PoseConnections с индексами ключевых точек MediaPipe и связями для отрисовки скелета.
Содержит: Протоколы ExerciseAnalyzerDelegate, ExerciseAnalyzer. Enum PoseConnections (с вложенным LandmarkIndex).
Технологии: Foundation, MediaPipeTasksVision.
Где используется: ExerciseExecutionViewModel, SquatAnalyzer3D. Протоколы реализуются классами анализаторов (SquatAnalyzer3D) и их делегатами (ExerciseExecutionViewModel).
Зависимости: (Не указано в исходном описании для файла)

[F2.5][SquatAnalyzer3D.swift] SquatAnalyzer3D.swift
ID: [F2.5][SquatAnalyzer3D.swift]
Имя: SquatAnalyzer3D.swift
Путь: Features/Leveling/Analyzers/SquatAnalyzer3D.swift
Тип: Файл
Назначение: Анализатор Приседаний
Описание: Логика анализа 3D-позы для подсчета приседаний. Реализует протокол ExerciseAnalyzer. Принимает 3D-координаты позы (worldLandmarks), рассчитывает углы в коленях и бедрах с помощью angle3D, сглаживает их скользящим средним, определяет состояние пользователя (up/down) на основе пороговых значений углов и засчитывает повторение при переходе из down в up. Уведомляет своего делегата (ExerciseExecutionViewModel) о смене состояния и засчитанных повторениях.
Содержит: Класс SquatAnalyzer3D, enum State, enum LandmarkIndex (дублирует?), enum Thresholds, свойства для состояния и сглаживания, методы analyze, reset, angle3D, updateState, addAngleToHistory, calculateSmoothedAngle.
Технологии: Foundation, MediaPipeTasksVision, simd.
Где используется: ExerciseExecutionViewModel. Создается и используется ExerciseExecutionViewModel.
Зависимости: (Не указано в исходном описании для файла)

[F2.5][PoseLandmarkerHelper.swift] PoseLandmarkerHelper.swift
ID: [F2.5][PoseLandmarkerHelper.swift]
Имя: PoseLandmarkerHelper.swift
Путь: Features/Leveling/Helpers/PoseLandmarkerHelper.swift
Тип: Файл
Назначение: Хелпер MediaPipe
Описание: Обертка для PoseLandmarker. Асинхронная детекция. Инкапсулирует создание и настройку PoseLandmarker (из MediaPipeTasksVision). Предоставляет метод detectAsync для асинхронной обработки видеокадров (CVPixelBuffer). Получает результаты детекции поз (2D и 3D координаты, сегментацию) и передает их своему делегату (PoseLandmarkerHelperLiveStreamDelegate - реализуется ExerciseExecutionViewModel) через метод poseLandmarkerHelper(_:didFinishDetection:error:). Обрабатывает ошибки MediaPipe.
Содержит: Класс PoseLandmarkerHelper, протокол PoseLandmarkerHelperLiveStreamDelegate, структура ResultBundle, методы для инициализации (liveStreamPoseLandmarkerHelper), детекции (detectAsync), реализация PoseLandmarkerLiveStreamDelegate.
Технологии: Foundation, MediaPipeTasksVision, AVFoundation, UIKit (для UIImage.Orientation).
Где используется: LevelingCoordinator (создает), ExerciseExecutionViewModel. Создается в LevelingCoordinator. Передается и используется в ExerciseExecutionViewModel.
Зависимости: (Не указано в исходном описании для файла)

[F2.5][Exercise.swift] Exercise.swift
ID: [F2.5][Exercise.swift]
Имя: Exercise.swift
Путь: Features/Leveling/Models/Exercise.swift
Тип: Файл
Назначение: Модель Упражнения
Описание: Структура Exercise (ID, имя, описание, иконка). Простая структура, представляющая упражнение. Используется для отображения в списке выбора (ExerciseSelectionViewController) и для выбора нужного анализатора (ExerciseExecutionViewModel).
Содержит: Структура Exercise (Identifiable).
Технологии: Foundation.
Где используется: ExerciseSelectionViewModel, LevelingCoordinator, ExerciseExecutionViewModel.
Зависимости: (Не указано в исходном описании для файла)

[F2.5][KalmanFilter3D.swift] KalmanFilter3D.swift
ID: [F2.5][KalmanFilter3D.swift]
Имя: KalmanFilter3D.swift
Путь: Features/Leveling/Utils/KalmanFilter3D.swift
Тип: Файл
Назначение: Фильтр Калмана 3D
Описание: Реализация фильтра Калмана для сглаживания 3D-координат. Предоставляет фильтр Калмана для сглаживания 3D-координат (например, точек позы). Учитывает шум процесса и шум измерения (который может зависеть от видимости точки). Имеет методы predict и update.
Содержит: Класс KalmanFilter3D, методы predict, update, свойства для состояния фильтра.
Технологии: simd (для векторной математики).
Где используется: ExerciseExecutionViewModel. Используется ExerciseExecutionViewModel для сглаживания worldLandmarks.
Зависимости: (Не указано в исходном описании для файла)

[F2.5][MotionManager.swift] MotionManager.swift
ID: [F2.5][MotionManager.swift]
Имя: MotionManager.swift
Путь: Features/Leveling/Utils/MotionManager.swift
Тип: Файл
Назначение: Менеджер CoreMotion
Описание: Получение данных об ориентации устройства. Singleton (shared), предоставляющий доступ к данным гироскопа и акселерометра через CoreMotion. Запускает (startUpdates) и останавливает (stopUpdates) получение данных об ориентации устройства (currentAttitude). Используется для получения кватерниона ориентации, который (пока закомментировано) может применяться для преобразования координат позы в мировую систему.
Содержит: Класс MotionManager (Singleton), свойства motionManager, currentAttitude, методы startUpdates, stopUpdates.
Технологии: CoreMotion, simd.
Где используется: ExerciseExecutionViewModel. Используется ExerciseExecutionViewModel для получения deviceAttitude.
Зависимости: (Не указано в исходном описании для файла)

[F2.5][PoseValidator.swift] PoseValidator.swift
ID: [F2.5][PoseValidator.swift]
Имя: PoseValidator.swift
Путь: Features/Leveling/Utils/PoseValidator.swift
Тип: Файл
Назначение: Валидатор Позы
Описание: (Предположительно) Проверка корректности позы. Код этого файла не был предоставлен или проанализирован ранее. Предположительно, он содержит логику для проверки корректности позы пользователя перед началом упражнения или во время выполнения (например, достаточно ли видимы ключевые точки, находится ли пользователь в кадре).
Содержит: (Неизвестно).
Технологии: (Неизвестно, вероятно Foundation, MediaPipeTasksVision).
Где используется: (Предположительно) ExerciseExecutionViewModel.
Зависимости: (Не указано в исходном описании для файла)

[F2.5][ExerciseExecutionViewController.swift] ExerciseExecutionViewController.swift
ID: [F2.5][ExerciseExecutionViewController.swift]
Имя: ExerciseExecutionViewController.swift
Путь: Features/Leveling/ViewControllers/ExerciseExecutionViewController.swift
Тип: Файл
Назначение: UI Экрана Тренировки
Описание: Камера (AVCaptureSession), 2D-оверлей (PoseOverlayView), статистика, отладка. Основной экран тренировки. Настраивает и управляет AVCaptureSession для получения видео с фронтальной камеры. Отображает видеопоток в previewLayer. Использует PoseOverlayView для отрисовки 2D-скелета поверх видео. Отображает статистику (XP, цель, счетчик, таймер) и отладочную информацию. Реализует ExerciseExecutionViewModelViewDelegate для получения обновлений от ViewModel и отрисовки позы/статистики. Передает видеокадры в ViewModel для обработки.
Содержит: Класс ExerciseExecutionViewController, UI элементы (PoseOverlayView, AVCaptureVideoPreviewLayer, UILabel, UIProgressView и т.д.), реализация AVCaptureVideoDataOutputSampleBufferDelegate, ExerciseExecutionViewModelViewDelegate, методы setupAVSession, startSession, stopSession.
Технологии: UIKit, AVFoundation, MediaPipeTasksVision, SceneKit (частично).
Где используется: LevelingCoordinator (показывает), ExerciseExecutionViewModel. LevelingCoordinator -> Создание и показ ExerciseExecutionViewController. Взаимодействует с ExerciseExecutionViewModel.
Зависимости: (Не указано в исходном описании для файла)

[F2.5][ExerciseSelectionViewController.swift] ExerciseSelectionViewController.swift
ID: [F2.5][ExerciseSelectionViewController.swift]
Имя: ExerciseSelectionViewController.swift
Путь: Features/Leveling/ViewControllers/ExerciseSelectionViewController.swift
Тип: Файл
Назначение: UI Экрана Выбора Упражнения
Описание: Список упражнений (UITableView, ExerciseCell). Отображает список доступных упражнений с помощью UITableView и кастомной ячейки ExerciseCell. Получает данные из ExerciseSelectionViewModel. При выборе упражнения уведомляет ViewModel (viewModel.didSelectExercise), которая затем сообщает координатору.
Содержит: Класс ExerciseSelectionViewController, класс ExerciseCell, реализация UITableViewDataSource, Delegate.
Технологии: UIKit.
Где используется: LevelingCoordinator (показывает), ExerciseSelectionViewModel. LevelingCoordinator.start() -> Создание и показ ExerciseSelectionViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.5][ExerciseExecutionViewModel.swift] ExerciseExecutionViewModel.swift
ID: [F2.5][ExerciseExecutionViewModel.swift]
Имя: ExerciseExecutionViewModel.swift
Путь: Features/Leveling/ViewModels/ExerciseExecutionViewModel.swift
Тип: Файл
Назначение: Логика Экрана Тренировки
Описание: Обработка кадров, MediaPipe, Kalman, вызов анализатора, расчет XP, обновление UI. Сердце фичи Leveling. Инициализируется с выбранным упражнением и PoseLandmarkerHelper. Обрабатывает видеокадры (processVideoFrame), передавая их в PoseLandmarkerHelper. Получает результаты детекции поз через PoseLandmarkerHelperLiveStreamDelegate. Применяет фильтр Калмана к 3D координатам. Передает сглаженные координаты в соответствующий ExerciseAnalyzer. Реализует ExerciseAnalyzerDelegate для получения событий о повторениях и смене состояния. Вызывает ProgressService.addXP для начисления опыта и обновления прогресса. Управляет таймерами и состояниями (подготовка, выполнение). Уведомляет ExerciseExecutionViewController об изменениях UI через ExerciseExecutionViewModelViewDelegate.
Содержит: Класс ExerciseExecutionViewModel, протокол ExerciseExecutionViewModelViewDelegate, реализация PoseLandmarkerHelperLiveStreamDelegate, ExerciseAnalyzerDelegate, методы processVideoFrame, fetchInitialData, startTimer, stopTimer и т.д.
Технологии: Combine, Foundation, AVFoundation, MediaPipeTasksVision, CoreMotion, simd
Где используется: LevelingCoordinator (создает), ExerciseExecutionViewController. Создается в LevelingCoordinator. Взаимодействует с ExerciseExecutionViewController, PoseLandmarkerHelper, ExerciseAnalyzer, ProgressService, UserProfileService, AuthService, MotionManager, KalmanFilter3D.
Зависимости: (Не указано в исходном описании для файла)

[F2.5][ExerciseSelectionViewModel.swift] ExerciseSelectionViewModel.swift
ID: [F2.5][ExerciseSelectionViewModel.swift]
Имя: ExerciseSelectionViewModel.swift
Путь: Features/Leveling/ViewModels/ExerciseSelectionViewModel.swift
Тип: Файл
Назначение: Логика Выбора Упражнения
Описание: Предоставление списка упражнений (моки), обработка выбора, вызов координатора. Предоставляет список упражнений (exercises - пока моковые данные) для ExerciseSelectionViewController. Обрабатывает выбор пользователя (didSelectExercise) и уведомляет координатора (LevelingCoordinator) через ExerciseSelectionViewModelCoordinatorDelegate.
Содержит: Класс ExerciseSelectionViewModel, протокол ExerciseSelectionViewModelCoordinatorDelegate, массив exercises, методы numberOfExercises, exercise(at:), didSelectExercise(at:).
Технологии: Foundation.
Где используется: LevelingCoordinator (создает), ExerciseSelectionViewController. Создается в LevelingCoordinator. Используется ExerciseSelectionViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.5][PoseOverlayView.swift] PoseOverlayView.swift
ID: [F2.5][PoseOverlayView.swift]
Имя: PoseOverlayView.swift
Путь: Features/Leveling/Views/PoseOverlayView.swift
Тип: Файл
Назначение: View для 2D Скелета
Описание: Отрисовка точек и линий скелета на основе 2D-координат. Получает нормализованные 2D-координаты точек позы (NormalizedLandmark) и размер кадра через метод drawResult. В методе draw(_:) рисует точки (круги) и линии (соединения) скелета, преобразуя нормализованные координаты в координаты View. Использует константы PoseConnections для определения связей.
Содержит: Класс PoseOverlayView, метод drawResult, метод draw.
Технологии: UIKit, CoreGraphics.
Где используется: ExerciseExecutionViewController. Создается и используется в ExerciseExecutionViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.6] Features/Notifications
ID: [F2.6]
Имя: Notifications
Путь: Features/Notifications/
Тип: Папка
Назначение: Экран Уведомлений
Описание: Заглушка для фичи уведомлений. Содержит координатор и ViewController-заглушку. Не содержит ViewModel или логики загрузки/отображения уведомлений ([P2.NOT.4]).
Содержит: Папки Coordinators, Файлы: NotificationsViewController.swift
Технологии: UIKit.
Где используется: AppCoordinator. AppCoordinator.showNotifications() -> NotificationsCoordinator.start() -> NotificationsViewController.
Зависимости: UIKit.

[F2.6][NotificationsCoordinator.swift] NotificationsCoordinator.swift
ID: [F2.6][NotificationsCoordinator.swift]
Имя: NotificationsCoordinator.swift
Путь: Features/Notifications/Coordinators/NotificationsCoordinator.swift
Тип: Файл
Назначение: Координатор Уведомлений (Заглушка)
Описание: Показ NotificationsViewController (модально). Заглушка координатора. В методе start создает и показывает NotificationsViewController (в переданном ему navigationController, который создается в AppCoordinator для модального показа). Содержит метод dismissNotifications для закрытия модального окна.
Содержит: Класс NotificationsCoordinator, методы init, start, dismissNotifications, setupNavigationBarAppearance.
Технологии: UIKit.
Где используется: AppCoordinator. AppCoordinator.showNotifications() -> Создание и запуск NotificationsCoordinator.
Зависимости: (Не указано в исходном описании для файла)

[F2.6][NotificationsViewController.swift] NotificationsViewController.swift
ID: [F2.6][NotificationsViewController.swift]
Имя: NotificationsViewController.swift
Путь: Features/Notifications/NotificationsViewController.swift
Тип: Файл
Назначение: UI Экрана Уведомлений (Заглушка)
Описание: Отображает заглушку. Заглушка ViewController'а. Отображает текст "Экран Уведомлений (TODO)". Не содержит логики или UI для списка уведомлений.
Содержит: Класс NotificationsViewController, viewDidLoad, setupPlaceholder.
Технологии: UIKit.
Где используется: NotificationsCoordinator. NotificationsCoordinator.start() -> Создание и показ NotificationsViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.7] Features/Progress
ID: [F2.7]
Имя: Progress
Путь: Features/Progress/
Тип: Папка
Назначение: Экран Прогресса (Таб 4)
Описание: Эта фича отвечает за визуализацию прогресса пользователя, включая текущий уровень, ранг, шкалу XP. В текущей реализации содержит координатор, ViewModel и ViewController, которые отображают базовую информацию. Функционал Фазы 2 (история тренировок, графики, рекорды, атрибуты) не реализован.
Содержит: Папки Coordinators, Scenes, Файлы: ProgressViewModel.swift
Технологии: Core/Services, UIKit, Combine.
Где используется: AppCoordinator. AppCoordinator -> ProgressCoordinator.start() -> ProgressViewController.
Зависимости: Core/Services, UIKit, Combine.

[F2.7][ProgressCoordinator.swift] ProgressCoordinator.swift
ID: [F2.7][ProgressCoordinator.swift]
Имя: ProgressCoordinator.swift
Путь: Features/Progress/Coordinators/ProgressCoordinator.swift
Тип: Файл
Назначение: Координатор Прогресса (Таб 4)
Описание: Создание и показ ProgressViewController и ProgressViewModel. Инициализирует и показывает ProgressViewController, создавая и передавая ему ProgressViewModel с необходимыми зависимостями (AuthService, ProgressService).
Содержит: Класс ProgressCoordinator, методы init, start.
Технологии: UIKit.
Где используется: AppCoordinator. AppCoordinator -> ProgressCoordinator.start().
Зависимости: (Не указано в исходном описании для файла)

[F2.7][ProgressViewModel.swift] ProgressViewModel.swift
ID: [F2.7][ProgressViewModel.swift]
Имя: ProgressViewModel.swift
Путь: Features/Progress/ProgressViewModel.swift
Тип: Файл
Назначение: Логика Экрана Прогресса
Описание: Загрузка ProgressData текущего пользователя через ProgressService. Предоставляет данные (progressData, isLoading, errorMessage) для ProgressViewController через @Published свойства.
Содержит: Класс ProgressViewModel, @Published свойства, методы init, fetchProgressData, refreshData.
Технологии: Combine, Foundation.
Где используется: ProgressCoordinator (создает), ProgressViewController. Взаимодействует с AuthService, ProgressService.
Зависимости: (Не указано в исходном описании для файла)

[F2.7][ProgressViewController.swift] ProgressViewController.swift
ID: [F2.7][ProgressViewController.swift]
Имя: ProgressViewController.swift
Путь: Features/Progress/Scenes/ProgressViewController.swift
Тип: Файл
Назначение: UI Экрана Прогресса
Описание: Отображение Ранга, Уровня, XP, прогресс-бара. Связан с ProgressViewModel через Combine для получения данных и обновления UI. Отображает индикатор загрузки и сообщения об ошибках. Не реализует отображение истории тренировок, графиков, рекордов ([P2.PRG.*]).
Содержит: Класс ProgressViewController, UI элементы (UILabel, UIProgressView, UIStackView, UIActivityIndicatorView), setupBindings.
Технологии: UIKit, Combine.
Где используется: ProgressCoordinator (показывает), ProgressViewModel. ProgressCoordinator.start() -> Создание и показ ProgressViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.8] Features/Store
ID: [F2.8]
Имя: Store
Путь: Features/Store/
Тип: Папка
Назначение: Магазин (Таб 5)
Описание: Заглушка для фичи магазина. Содержит координатор и ViewController-заглушку. Функционал Фазы 2 (покупки IAP) не реализован.
Содержит: Папки Coordinators, Scenes
Технологии: UIKit.
Где используется: AppCoordinator. AppCoordinator -> StoreCoordinator.start() -> StoreViewController.
Зависимости: UIKit.

[F2.8][StoreCoordinator.swift] StoreCoordinator.swift
ID: [F2.8][StoreCoordinator.swift]
Имя: StoreCoordinator.swift
Путь: Features/Store/Coordinators/StoreCoordinator.swift
Тип: Файл
Назначение: Координатор Магазина (Заглушка)
Описание: Показ StoreViewController. Заглушка координатора. В методе start просто создает и показывает StoreViewController. Не имеет зависимостей или сложной логики.
Содержит: Класс StoreCoordinator, методы init, start.
Технологии: UIKit.
Где используется: AppCoordinator. AppCoordinator -> StoreCoordinator.start().
Зависимости: (Не указано в исходном описании для файла)

[F2.8][StoreViewController.swift] StoreViewController.swift
ID: [F2.8][StoreViewController.swift]
Имя: StoreViewController.swift
Путь: Features/Store/Scenes/Storefront/StoreViewController.swift
Тип: Файл
Назначение: UI Экрана Магазина (Заглушка)
Описание: Отображает заглушку. Заглушка ViewController'а. Отображает только заголовок "Магазин". Не содержит логики или реального UI магазина.
Содержит: Класс StoreViewController, UILabel, viewDidLoad, setupConstraints.
Технологии: UIKit.
Где используется: StoreCoordinator. StoreCoordinator.start() -> Создание и показ StoreViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.9] Features/UserProfile
ID: [F2.9]
Имя: UserProfile
Путь: Features/UserProfile/
Тип: Папка
Назначение: Компоненты Профиля (Переиспользуемые)
Описание: Содержит координатор для чужого профиля, контейнерный VC и переиспользуемые экраны (Card, Person/FeedGrid, Stats) и их ViewModel'и/View для отображения профиля. Эта папка предоставляет набор экранов (Card, Person/FeedGrid, Stats), управляемых контейнером (UserProfileContainerViewController), и соответствующие ViewModel'и и View. Координатор UserProfileCoordinator отвечает за запуск этого флоу для конкретного userID (обычно при переходе из ленты). Компоненты из этой папки используются как CurrentUserProfileCoordinator (для Таба 2), так и UserProfileCoordinator (для просмотра чужих профилей).
Содержит: Папки Coordinators, Scenes, ViewModels, Views
Технологии: Core/Services, UIKit, Combine, DGCharts, Kingfisher.
Где используется: FeedCoordinator, CurrentUserProfileCoordinator. FeedCoordinator -> UserProfileCoordinator.start() -> UserProfileContainerViewController ИЛИ CurrentUserProfileCoordinator.start() -> UserProfileFeedViewController.
Зависимости: Core/Services, UIKit, Combine, DGCharts, Kingfisher.

[F2.9][UserProfileCoordinator.swift] UserProfileCoordinator.swift
ID: [F2.9][UserProfileCoordinator.swift]
Имя: UserProfileCoordinator.swift
Путь: Features/UserProfile/Coordinators/UserProfileCoordinator.swift
Тип: Файл
Назначение: Координатор Профиля Другого Пользователя
Описание: Запуск UserProfileContainerViewController для заданного userID. Инициализируется с userID пользователя, чей профиль нужно показать, и необходимыми сервисами. В методе start создает и показывает UserProfileContainerViewController, передавая ему userID и сервисы. Реализует метод dismissProfile для возврата назад (например, в ленту).
Содержит: Класс UserProfileCoordinator, методы start, dismissProfile.
Технологии: UIKit.
Где используется: FeedCoordinator. FeedCoordinator.showUserProfile() -> Создание и запуск UserProfileCoordinator.
Зависимости: (Не указано в исходном описании для файла)

[F2.9][UserProfileContainerViewController.swift] UserProfileContainerViewController.swift
ID: [F2.9][UserProfileContainerViewController.swift]
Имя: UserProfileContainerViewController.swift
Путь: Features/UserProfile/Scenes/Container/UserProfileContainerViewController.swift
Тип: Файл
Назначение: Контейнер Экрана Профиля
Описание: Управление переключением между Card/Person/Stats. Отображение TopMenuView. Получает userID и сервисы через метод configure. Создает экземпляры дочерних VC (UserProfileCardViewController, UserProfileFeedViewController, UserProfileStatsViewController) и их ViewModel'и (кроме Card VC). Отображает TopMenuView поверх контента и использует его делегата (TopMenuViewDelegate) для переключения между дочерними VC с помощью displayChildViewController. Обрабатывает нажатие кнопки "Назад" в TopMenuView, вызывая coordinator.dismissProfile().
Содержит: Класс UserProfileContainerViewController, lazy var для дочерних VC, lazy var для TopMenuView, метод configure, метод displayChildViewController, реализация TopMenuViewDelegate.
Технологии: UIKit.
Где используется: UserProfileCoordinator, CurrentUserProfileCoordinator (косвенно). UserProfileCoordinator.start() -> Создание и показ UserProfileContainerViewController.
Зависимости: (Не указано в исходном описании для файла)

[F2.9][UserProfileCardViewController.swift] UserProfileCardViewController.swift
ID: [F2.9][UserProfileCardViewController.swift]
Имя: UserProfileCardViewController.swift
Путь: Features/UserProfile/Scenes/Card/UserProfileCardViewController.swift
Тип: Файл
Назначение: UI Вкладки "Card"
Описание: Отображение фона, инфо-блока (аватар, имя, статус, follow, уровень, XP). Отображает фоновое изображение (аватар на весь экран) и информационный блок внизу (86% ширины) с мини-аватаром, именем, статусом, кнопкой Follow/Following, уровнем и XP. Использует UserProfileCardViewModel для получения данных и состояния подписки. Обновляет UI через Combine (setupBindings). Обрабатывает нажатие кнопки Follow, вызывая метод ViewModel.
Содержит: Класс UserProfileCardViewController, UI элементы, @objc методы, setupBindings, updateAvatar, configureFollowButton.
Технологии: UIKit, Combine, Kingfisher.
Где используется: UserProfileContainerViewController. UserProfileContainerViewController -> displayChildViewController(cardVC).
Зависимости: (Не указано в исходном описании для файла)

[F2.9][UserProfileFeedViewController.swift] UserProfileFeedViewController.swift
ID: [F2.9][UserProfileFeedViewController.swift]
Имя: UserProfileFeedViewController.swift
Путь: Features/UserProfile/Scenes/FeedGrid/UserProfileFeedViewController.swift
Тип: Файл
Назначение: UI Вкладки "Person"
Описание: Отображение шапки профиля, кнопок действий (Follow/Message или Edit/New Post/Program), сегментов (Posts/Programs), сетки постов. Флоу создания поста. Отображает основной контент профиля в контейнере 86% ширины: шапка (аватар, статы), имя, статус, кнопки действий (Edit/New Post/New Program для своего профиля, Follow/Message для чужого), переключатель Posts/Programs и сетку постов (UICollectionView с PostGridCell). Использует UIScrollView для корректного отступа под TopMenuView. Реализует флоу создания нового поста (выбор фото через PHPicker, показ CreatePostViewController). Связан с UserProfileFeedViewModel через Combine для отображения данных и состояний. Реализует делегаты для обработки нажатий на кнопки, сегменты, ячейки сетки, завершения создания поста.
Содержит: Класс UserProfileFeedViewController, протокол UserProfileFeedViewControllerDelegate, UI элементы, lazy var свойства, @objc методы, setupBindings, configureActionButtons, логика PHPicker, реализация делегатов UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, CreatePostViewControllerDelegate.
Технологии: UIKit, Combine, Kingfisher, PhotosUI.
Где используется: UserProfileContainerViewController, CurrentUserProfileCoordinator. CurrentUserProfileCoordinator.start() ИЛИ UserProfileContainerViewController -> displayChildViewController(personFeedVC).
Зависимости: (Не указано в исходном описании для файла)

[F2.9][UserProfileStatsViewController.swift] UserProfileStatsViewController.swift
ID: [F2.9][UserProfileStatsViewController.swift]
Имя: UserProfileStatsViewController.swift
Путь: Features/UserProfile/Scenes/Stats/UserProfileStatsViewController.swift
Тип: Файл
Назначение: UI Вкладки "Stats"
Описание: Отображение радар-чарта атрибутов (DGCharts), инфо-блока (ранг, уровень, XP, список атрибутов). Отображает статистику RPG в контейнере 86% ширины: радар-диаграмму атрибутов (RadarChartView из DGCharts), информационный блок (имя, ранг, список атрибутов) и блок уровня/XP. Использует UIScrollView. Связан с UserProfileStatsViewModel через Combine для получения данных и отображения состояний. Реализует AxisValueFormatter для настройки осей чарта.
Содержит: Класс UserProfileStatsViewController, UI элементы (UIScrollView, RadarChartView, UILabel, UIStackView, UIProgressView, UIActivityIndicatorView), классы-форматеры XAxisValueFormatter, YAxisValueFormatter, реализация AxisValueFormatter, setupBindings, updateUI, updateRadarChart.
Технологии: UIKit, Combine, DGCharts.
Где используется: UserProfileContainerViewController. UserProfileContainerViewController -> displayChildViewController(statsVC).
Зависимости: (Не указано в исходном описании для файла)

[F2.9][UserProfileCardViewModel.swift] UserProfileCardViewModel.swift
ID: [F2.9][UserProfileCardViewModel.swift]
Имя: UserProfileCardViewModel.swift
Путь: Features/UserProfile/ViewModels/UserProfileCardViewModel.swift
Тип: Файл
Назначение: Логика Вкладки "Card"
Описание: Загрузка User, ProgressData, статуса подписки. Обработка followButtonTapped. Загружает User и ProgressData для указанного userID с помощью UserProfileService и ProgressService. Проверяет статус подписки через FollowService (если это не профиль текущего пользователя). Обрабатывает нажатие кнопки Follow, вызывая FollowService и оптимистично обновляя состояние isFollowing. Предоставляет данные через @Published свойства.
Содержит: Класс UserProfileCardViewModel, @Published свойства, методы fetchCardData, checkFollowingStatus, followButtonTapped, refreshData.
Технологии: Combine, Foundation.
Где используется: UserProfileContainerViewController. Создается в UserProfileContainerViewController. Используется UserProfileCardViewController. Взаимодействует с UserProfileService, ProgressService, FollowService.
Зависимости: (Не указано в исходном описании для файла)

[F2.9][UserProfileFeedViewModel.swift] UserProfileFeedViewModel.swift
ID: [F2.9][UserProfileFeedViewModel.swift]
Имя: UserProfileFeedViewModel.swift
Путь: Features/UserProfile/ViewModels/UserProfileFeedViewModel.swift
Тип: Файл
Назначение: Логика Вкладки "Person"
Описание: Загрузка User, ProgressData, постов. Обработка followButtonTapped. Загружает User, ProgressData и посты ([Post]) для указанного userID с помощью UserProfileService, ProgressService и PostService. Не реализует пагинацию для постов (загружает только первую страницу). Проверяет и обрабатывает статус подписки (isFollowing, followButtonTapped) через FollowService. Предоставляет данные через @Published свойства.
Содержит: Класс UserProfileFeedViewModel, @Published свойства, методы fetchAllUserData, checkFollowingStatus, followButtonTapped.
Технологии: Combine, Foundation.
Где используется: UserProfileContainerViewController, CurrentUserProfileCoordinator. Создается в CurrentUserProfileCoordinator или UserProfileContainerViewController. Используется UserProfileFeedViewController. Взаимодействует с UserProfileService, PostService, FollowService, ProgressService.
Зависимости: (Не указано в исходном описании для файла)

[F2.9][UserProfileStatsViewModel.swift] UserProfileStatsViewModel.swift
ID: [F2.9][UserProfileStatsViewModel.swift]
Имя: UserProfileStatsViewModel.swift
Путь: Features/UserProfile/ViewModels/UserProfileStatsViewModel.swift
Тип: Файл
Назначение: Логика Вкладки "Stats"
Описание: Загрузка User, ProgressData. Загружает User и ProgressData для указанного userID с помощью UserProfileService и ProgressService. Предоставляет данные через @Published свойства.
Содержит: Класс UserProfileStatsViewModel, @Published свойства, метод fetchStatsData, refreshData.
Технологии: Combine, Foundation.
Где используется: UserProfileContainerViewController. Создается в UserProfileContainerViewController. Используется UserProfileStatsViewController. Взаимодействует с UserProfileService, ProgressService.
Зависимости: (Не указано в исходном описании для файла)

[F2.9][PostGridCell.swift] PostGridCell.swift
ID: [F2.9][PostGridCell.swift]
Имя: PostGridCell.swift
Путь: Features/UserProfile/Views/PostGridCell.swift
Тип: Файл
Назначение: Ячейка Сетки Постов
Описание: Отображение превью изображения поста. Простая ячейка UICollectionViewCell, содержащая UIImageView на весь размер ячейки. Метод configure(with:) загружает изображение поста с помощью Kingfisher.
Содержит: Класс PostGridCell, UIImageView, метод configure.
Технологии: UIKit, Kingfisher.
Где используется: UserProfileFeedViewController. Используется UserProfileFeedViewController в collectionView(_:cellForItemAt:).
Зависимости: (Не указано в исходном описании для файла)

[F2.9][TopMenuView.swift] TopMenuView.swift
ID: [F2.9][TopMenuView.swift]
Имя: TopMenuView.swift
Путь: Features/UserProfile/Views/TopMenuView.swift
Тип: Файл
Назначение: View Верхнего Меню Профиля
Описание: Кастомная навигационная панель с кнопкой назад, сегментами Card/Person/Stats, кнопкой настроек. Отображает кнопку "Назад" (опционально), кнопки-сегменты "Card", "Person", "Stats" и кнопку "Настройки". Реализует логику переключения сегментов с анимацией индикатора. Уведомляет делегата (UserProfileContainerViewController) о нажатиях через TopMenuViewDelegate.
Содержит: Класс TopMenuView, enum Segment, протокол TopMenuViewDelegate, UI элементы (UIButton, UIStackView, UIView), методы для настройки UI и обработки нажатий.
Технологии: UIKit.
Где используется: UserProfileContainerViewController. Используется UserProfileContainerViewController.
Зависимости: (Не указано в исходном описании для файла)

[F3] Common
ID: [F3]
Имя: Common
Путь: Common/
Тип: Папка
Назначение: Общие Утилиты
Описание: Содержит переиспользуемые расширения стандартных классов. Содержит вспомогательный код, который может использоваться в разных частях приложения. В данном случае, содержит расширения для стандартных типов.
Содержит: Папки [F3.1] Extensions
Технологии: UIKit, Combine.
Где используется: Различные VC и VM. Файлы из Common импортируются и используются по мере необходимости в других файлах проекта.
Зависимости: UIKit, Combine.

[F3.1] Common/Extensions
ID: [F3.1]
Имя: Extensions
Путь: Common/Extensions/
Тип: Папка
Назначение: Расширения
Описание: Содержит расширения для UITextView (Combine) и Date (timeAgo).
Содержит: Файлы: [F3.1][UITextView+Combine.swift]
Технологии: UIKit, Combine.
Где используется: CommentCell, потенциально другие VC/VM.
Зависимости: UIKit, Combine.

[F3.1][UITextView+Combine.swift] UITextView+Combine.swift
ID: [F3.1][UITextView+Combine.swift]
Имя: UITextView+Combine.swift
Путь: Common/Extensions/UITextView+Combine.swift
Тип: Файл
Назначение: Расширения UITextView и Date
Описание: Добавляет textPublisher для UITextView и timeAgoDisplay() для Date. Содержит два extension: extension UITextView: Добавляет вычисляемое свойство textPublisher, которое создает AnyPublisher<String, Never>, эмитящий текст UITextView при каждом его изменении (используя NotificationCenter). extension Date: Добавляет метод timeAgoDisplay(), который форматирует дату в относительное время ("5 минут назад", "вчера" и т.д.) с помощью RelativeDateTimeFormatter.
Содержит: extension UITextView, extension Date.
Технологии: UIKit, Combine, Foundation.
Где используется: CommentCell, потенциально другие VC/VM. Date.timeAgoDisplay() используется в CommentCell. UITextView.textPublisher может использоваться ViewModel'ями для реактивного получения текста (например, в CreatePostViewModel или CommentsViewModel, хотя сейчас там используется UITextViewDelegate).
Зависимости: (Не указано в исходном описании для файла)
