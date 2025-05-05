## Features

_Раздел для описания функциональных модулей приложения._

### Features/Authentication

_Модуль отвечает за процессы входа и регистрации пользователя._

*   `/Users/inga/Desktop/SensumApp/Features/Authentication/Coordinators/AuthCoordinator.swift`: Координирует навигацию внутри потока аутентификации. Отвечает за показ экранов Login и Register, обработку переходов между ними и запуск Google Sign-In. Зависит от `AuthService`, `ProgressService`. Определяет `AuthCoordinatorDelegate` для оповещения о завершении. Реализует `Coordinator`, `LoginViewControllerDelegate`, `LoginViewModelCoordinatorDelegate`, `RegisterViewControllerDelegate`.
*   `/Users/inga/Desktop/SensumApp/Features/Authentication/Scenes/Login/`: Содержит компоненты экрана входа (MVVM):
    *   `LoginViewController.swift`: `UIViewController` для экрана входа (текстовые поля, кнопки Login/Register/Google, индикатор, лейбл ошибки). Связан с `LoginViewModel` через Combine для отображения состояния (активность кнопки, загрузка, ошибки) и передачи введенных данных. Уведомляет `AuthCoordinator` (через делегат) о запросах навигации (на регистрацию, Google Sign In).
    *   `LoginViewModel.swift`: Логика представления экрана входа. Хранит email/пароль, состояние загрузки (`isLoading`), сообщение об ошибке (`errorMessage`). Валидирует ввод, определяет активность кнопки входа (`isLoginButtonEnabled`). Вызывает `AuthService.signInUser()`. Уведомляет координатора о запросе на регистрацию.
*   `/Users/inga/Desktop/SensumApp/Features/Authentication/Scenes/Register/`: Содержит компоненты экрана регистрации (MVVM):
    *   `RegisterViewController.swift`: `UIViewController` для экрана регистрации (поля email/username/password, кнопка Register, индикатор, лейбл ошибки). Показывает Navigation Bar для возврата. Связан с `RegisterViewModel` через Combine для отображения состояния и передачи данных.
    *   `RegisterViewModel.swift`: Логика представления экрана регистрации. Хранит email/username/password, состояние загрузки (`isLoading`), сообщение об ошибке (`errorMessage`). Валидирует ввод, определяет активность кнопки (`isRegisterButtonEnabled`). Вызывает `AuthService.registerUser()`. После успешной аутентификации вызывает `UserProfileService` и `ProgressService` для создания записей в Firestore.

### Features/Create

_Модуль отвечает за создание контента._

*   `/Users/inga/Desktop/SensumApp/Features/Create`: Модуль отвечает за создание контента (вероятно, постов). Содержит следующие поддиректории:
    *   `Scenes/`: Содержит различные сцены, связанные с созданием контента:
        *   `Cells/`: Кастомные ячейки для создания контента.
            *   `MediaThumbnailCell.swift`: `UICollectionViewCell` для отображения миниатюр изображений в сетке выбора медиа (`PostMediaSelectionViewController`). Содержит `UIImageView`. Поддержка видео удалена.
                *   **Назначение**: Простая ячейка (`UICollectionViewCell`) для отображения миниатюры изображения. **Не поддерживает видео**. Вероятно, используется в сетке выбора медиа из галереи.
                *   **UI**: Содержит один `UIImageView`, занимающий всю ячейку.
                *   **Функционал**: Метод `configure(with image: UIImage?)` для установки изображения. Очищается при переиспользовании.
                *   **Зависимости**: `UIKit`.
            *   `PreviewCell.swift`: `UICollectionViewCell` для отображения превью изображения с заданным `aspectRatio`. Используется, вероятно, в `PostReviewViewController`. Динамически изменяет размер внутреннего контейнера для сохранения пропорций.
                *   **Назначение**: `UICollectionViewCell` для отображения превью изображения (`UIImage`) с заданным соотношением сторон (`PostAspectRatio`). Используется в `PostMediaSelectionViewController`.
                *   **UI**: Содержит `imageView` внутри `containerView`. `containerView` динамически изменяет свой размер (через `width`/`height` constraints), чтобы соответствовать `PostAspectRatio`, центрируясь внутри `contentView` ячейки. `containerView` имеет скругленные углы.
                *   **Функционал**: Метод `configure(with:aspectRatio:)` устанавливает изображение и обновляет размеры `containerView`. `prepareForReuse` сбрасывает изображение и размеры.
        *   `CropDelegate.swift`: Протокол (`protocol CropDelegate: AnyObject`) для уведомления о завершении обрезки изображения. Содержит метод `cropViewControllerDidFinishCropping(item: EditableMediaItem)`.
        *   `PostCropViewController.swift`: 
            *   **Назначение**: Экран (`UIViewController`) для ручной обрезки **одного** изображения (`EditableMediaItem`) под заданное соотношение сторон (`PostAspectRatio`).
            *   **Архитектура**: MVC-подобная. Получает данные через `init`. Использует `PostCropViewControllerDelegate` (отмена) и `CropDelegate` (успех с результатом).
            *   **UI**: Основной элемент - кастомный `ImageCropView`, позволяющий панорамировать/масштабировать изображение. Навбар с "Cancel"/"Done".
            *   **Функционал**:
                *   Получает `EditableMediaItem` и `PostAspectRatio`.
                *   Настраивает `ImageCropView` с изображением и соотношением сторон.
                *   Загружает/применяет сохраненные параметры обрезки (`manualZoomScale`, `manualContentOffset`) из `EditableMediaItem`, если есть.
                *   По кнопке "Done": сохраняет параметры обрезки в `EditableMediaItem`, генерирует обрезанное изображение (`getCroppedImage()`) и сохраняет его в `EditableMediaItem.finalImage`, уведомляет `CropDelegate.cropViewControllerDidFinishCropping` с обновленным `EditableMediaItem`.
                *   По кнопке "Cancel": уведомляет `PostCropViewControllerDelegate.postCropDidCancel`.
            *   **Зависимости**: `EditableMediaItem`, `PostAspectRatio`, `ImageCropView`.
            *   **Делегаты**: `PostCropViewControllerDelegate`, `CropDelegate`.
        *   `PostMediaSelectionViewController.swift`: 
            *   **Назначение**: Экран (`UIViewController`) выбора единого соотношения сторон (`.portrait` 9:16 или `.square` 1:1) для всех медиафайлов поста и предпросмотра/выбора медиа для редактирования (обрезки).
            *   **Архитектура**: MVC-подобная, работает с `[EditableMediaItem]`, использует делегирование.
            *   **UI**: Горизонтальный `UICollectionView` (`previewCollectionView`) с `PreviewCell`, высота которого динамически меняется под выбранный формат. Кнопки выбора формата (`portraitRatioButton`, `squareRatioButton`).
            *   **Функционал**:
                *   Принимает `[EditableMediaItem]`. 
                *   Выбор формата кнопками.
                *   Обновление layout `previewCollectionView`.
                *   Обработка тапа на медиа (вызов `delegate.postMediaSelectionDidTapItem` для перехода к редактированию).
                *   Обработка "Next" (вызов `delegate.postMediaSelectionDidTapNext`).
                *   Обработка "Cancel" (вызов `delegate.postMediaSelectionDidCancel`).
                *   Реализация `CropDelegate` (`cropViewControllerDidFinishCropping`) для получения результата обрезки, обновления UI и уведомления `delegate.postMediaSelectionDidFinishCropping`.
            *   **Зависимости**: `[EditableMediaItem]`.
            *   **Делегаты**: `PostMediaSelectionDelegate`, `UICollectionViewDataSource`, `UICollectionViewDelegate`, `UICollectionViewDelegateFlowLayout`, `UIScrollViewDelegate`, `CropDelegate`.
        *   `PostReviewViewController.swift`: 
            *   **Назначение**: Финальный экран (`UIViewController`) создания поста. Отображает превью всех обрезанных медиа, позволяет добавить подпись и инициировать публикацию.
            *   **Архитектура**: MVVM. Управляется `CreatePostViewModel`. Использует `Combine` для биндингов.
            *   **UI**: `UIScrollView` содержит `UICollectionView` (`previewCollectionView`) для горизонтального показа превью (с динамическим размером ячеек под `viewModel.postAspectRatio`), `UITextView` (`captionTextView`) для подписи, `UIButton` (`shareButton`) для публикации, `UIActivityIndicatorView`.
            *   **Функционал**:
                *   Получает `CreatePostViewModel`.
                *   Отображает данные из `viewModel.editableMedia` в `previewCollectionView`.
                *   Связывает `captionTextView` с `viewModel.caption`.
                *   По кнопке "Share" вызывает `viewModel.sharePost()`.
                *   Через `Combine` биндит состояние `viewModel.isSharing` к UI (индикатор, кнопка) и `viewModel.errorMessage` к показу ошибок.
                *   При успехе вызывает `delegate.postReviewDidFinishSuccessfully()`.
            *   **Зависимости**: `CreatePostViewModel`, `Combine`, `UIKit`.
            *   **Делегаты**: `PostReviewViewControllerDelegate`, `UICollectionViewDataSource`, `UICollectionViewDelegateFlowLayout`, `UITextViewDelegate`.
    *   `ViewControllers/`: (ПУСТО) Общие/базовые ViewController'ы отсутствуют.
    *   `ViewModels/`: ViewModel'и для сцен фичи.
        *   `CreatePostViewModel.swift`: `final class`. Управляет состоянием (`@Published`: `editableMedia`, `postAspectRatio`, `caption`, `isSharing`, `errorMessage`) и логикой экрана `PostReviewViewController`. Инкапсулирует весь процесс публикации: генерирует финальные изображения (с учетом ручного/автоматического кропа), загружает их и миниатюру в `StorageService` (используя Combine), создает запись поста через `PostService`. Содержит сложную логику кропа изображений.
    *   `Views/`: (Новая директория для переиспользуемых View)
        *   `PostGridCell.swift`: `UICollectionViewCell`. Ячейка для отображения миниатюры поста в сетке (`UserProfileFeedViewController`). Содержит `postImageView` с закругленными углами. Метод `configure(with post: Post)` использует `Kingfisher` для загрузки изображения (приоритет `gridThumbnailURL`, затем `mediaItems.first?.url`) с плейсхолдером, индикатором, ретраями и обработкой ошибок. Отменяет загрузку в `prepareForReuse`.
        *   `TopMenuView.swift`: `UIView`. Кастомная верхняя панель навигации (используется в `UserProfileContainerViewController`). Содержит кнопки для выбора сегментов (`enum Segment`: `.card`, `.person`, `.stats`), опциональную кнопку `backButton` и кнопку `settingsButton`. Имеет анимированный `selectionIndicatorView` (подчеркивание). Управляет лейаутом в зависимости от `showBackButton`. Взаимодействует с VC через `TopMenuViewDelegate`.

### Features/CurrentUserProfile

_Модуль отвечает за отображение и управление профилем текущего пользователя._

*   `/Users/inga/Desktop/SensumApp/Features/CurrentUserProfile`
    *   `Coordinators/`: Координатор для навигации в рамках фичи.
        *   `CurrentUserProfileCoordinator.swift`: `final class`. Управляет навигацией для профиля *текущего* пользователя. Запускает `UserProfileFeedViewController`, обрабатывает переходы (редактирование, создание поста, просмотр постов/комментариев, выход), реализуя множество делегатов (`UserProfileFeedViewControllerDelegate`, `EditProfileViewControllerDelegate`, `PostMediaSelectionDelegate` и др.). Управляет полным циклом создания поста, инициированным из профиля. Может запускать дочерний `UserProfileCoordinator` для показа других профилей. Передает зависимости (сервисы) в ViewModel'ы.
    *   `Scenes/`: Сцены (экраны) профиля.
        *   `EditProfile/`: Содержит компоненты экрана редактирования профиля.
            *   `EditProfileViewController.swift`: `UIViewController` для экрана редактирования профиля. Отображает текущие данные (аватар через Kingfisher, имя, статус). Позволяет выбрать новый аватар (`PHPickerViewControllerDelegate`) и изменить текстовые поля. Использует `EditProfileViewModel` (инъекция) и Combine (`setupBindings`) для загрузки начальных данных, отслеживания состояния загрузки/ошибок, активации кнопки "Save" (`checkForChanges`). Вызывает `viewModel.saveProfile()` при сохранении. Уведомляет координатора через `EditProfileViewControllerDelegate`.
            *   `EditProfileViewModel.swift`: `class`. Логика представления для `EditProfileViewController`. Загружает начальные данные профиля (`loadInitialData`) через `UserProfileService`. Предоставляет `@Published` свойства для UI (`initialUsername`, `initialStatus`, `initialAvatarURL`, `isLoading`, `errorMessage`). Метод `saveProfile` обрабатывает сохранение изменений: определяет измененные поля, использует `Future` (Combine) для загрузки нового аватара через `StorageService` (если нужно), затем обновляет данные в Firestore через `UserProfileService.updateUserProfile()`. Уведомляет координатора об успехе/ошибке через `EditProfileViewModelDelegate`.
    *   `ViewModels/`: ViewModel'и для сцен фичи.

### Features/UserProfile

_Модуль отвечает за отображение профиля другого пользователя._

*   `/Users/inga/Desktop/SensumApp/Features/UserProfile`
    *   `Coordinators/`: 
        *   `UserProfileCoordinator.swift`: `class`. Координатор для отображения профиля *другого* пользователя (`userID`). Принимает `userID`, сервисы (`UserProfile`, `Post`, `Follow`, `Progress`) и `appCoordinator` в `init`. В методе `start()` создает и конфигурирует `UserProfileContainerViewController` (передавая ему `userID` и сервисы), а затем делает `push` этого контейнера в `navigationController`. Содержит метод `dismissProfile()` для закрытия (с TODO по логике). Не создает `UserProfileFeedViewController` напрямую.
    *   `Scenes/`:
        *   `Card/`: (Новая директория для "карточки" профиля)
            *   `UserProfileCardViewController.swift`: `UIViewController`. Отображает основную "карточку" профиля пользователя (как дочерний VC для `UserProfileContainerViewController`). Показывает большой фоновый аватар (`backgroundImageView`), нижнюю плашку (`bottomInfoContainerView`) с градиентом, содержащую мини-аватар, имя, статус, кнопку Follow/Following, уровень и прогресс XP. Использует `UserProfileCardViewModel` (инъекция) и Combine (`setupBindings`) для получения данных (`userProfile`, `progressData`, `isFollowing`), управления состоянием загрузки (`isLoading`, `errorMessage`) и обновления UI. Вызывает `viewModel.followButtonTapped()`.
        *   `Container/`: (Новая директория, вероятно для контейнерных ViewController'ов)
            *   `UserProfileContainerViewController.swift`: `UIViewController`. Контейнер для отображения профиля *другого* пользователя (`userID`). Управляет переключением между дочерними VC (`UserProfileCardViewController`, `UserProfileFeedViewController`, `UserProfileStatsViewController`) с помощью `TopMenuView` (содержит сегменты 'Card', 'Person', 'Stats' и кнопку 'Назад'). Получает `userID` и сервисы через `configure()`. Инициализирует дочерние VC и их ViewModel'ы (с `isCurrentUser: false`). Реализует `TopMenuViewDelegate` для переключения VC и вызова `coordinator.dismissProfile()`.
        *   `FeedGrid/`:
            *   `UserProfileFeedViewController.swift`: `UIViewController`. Отображает профиль пользователя (текущего или другого): аватар (Kingfisher), имя, статус, статистика (посты, подписчики, подписки, лайки). Показывает сетку постов пользователя (`UICollectionView` с `PostGridCell`), поддерживает пагинацию (`prefetchItemsAt`, `viewModel.loadMorePosts`) и KVO для динамической высоты. UI (кнопки Edit/Follow/Message, TopBar/NavBar) адаптируется в зависимости от `viewModel.isCurrentUser`. Использует `UserProfileFeedViewModel` (инъекция) и Combine для получения данных и управления состоянием (`isLoading`, `isLoadingPosts`, `errorMessage`, `isFollowing`). Уведомляет координатор через `UserProfileFeedViewControllerDelegate`.
        *   `Stats/`: (Новая директория для статистики пользователя)
            *   `UserProfileStatsViewController.swift`: `UIViewController`. Отображает статистику профиля (как дочерний VC для `UserProfileContainerViewController`). Ключевой элемент - радарная диаграмма (`DGCharts.RadarChartView`) для визуализации атрибутов (`AttributeType`). Также показывает имя, ранг, атрибуты списком, уровень и XP. Использует `UserProfileStatsViewModel` (инъекция) и Combine (`setupBindings`) для получения данных (`userProfile`, `progressData`) и обновления UI (`updateUI`, `setupRadarChartData`). Управляет `activityIndicator` и `errorLabel`. Содержит вспомогательные классы/расширения `AxisValueFormatter`, `YAxisValueFormatter` для диаграммы.
    *   `ViewModels/`: 
        *   `UserProfileCardViewModel.swift`: `class`. Логика для `UserProfileCardViewController`. Принимает `userID`, `isCurrentUser`. Использует `UserProfileService`, `ProgressService`, `FollowService`. Загружает данные профиля и RPG-прогресса (`fetchCardData` с `DispatchGroup`). Проверяет и обрабатывает подписку (`checkFollowingStatus`, `followButtonTapped` с оптимистичным обновлением). Предоставляет `@Published private(set)` свойства для UI (`userProfile`, `progressData`, `isFollowing`, `isLoading`, `errorMessage`). Содержит метод `refreshData()`. (Присутствует закомментированный протокол и метод для трансформации данных чарта).
        *   `UserProfileFeedViewModel.swift`: `class`. Логика для `UserProfileFeedViewController`. Принимает `userID` и `isCurrentUser`. Использует `UserProfileService`, `PostService`, `FollowService`, `ProgressService`. Загружает данные профиля, RPG-прогресс и первую страницу постов (`fetchAllUserData` с `DispatchGroup`). Загружает следующие страницы постов (`loadMorePosts`). Проверяет и изменяет статус подписки (`checkFollowingStatus`, `followButtonTapped` с оптимистичным обновлением). Предоставляет `@Published` свойства для UI (`userProfile`, `userPosts`, `progressData`, `isFollowing`, `isLoading...`, `isLastPageReached`, `errorMessage`). Для `isCurrentUser` подписывается на `.didCreateNewPost` для обновления.
        *   `UserProfileStatsViewModel.swift`: `class`. Логика для `UserProfileStatsViewController`. Принимает `userID`. Использует `UserProfileService`, `ProgressService`. Загружает данные профиля и RPG-прогресса (`fetchStatsData` с `DispatchGroup`). Предоставляет `@Published private(set)` свойства для UI (`userProfile`, `progressData`, `isLoading`, `errorMessage`). Содержит метод `refreshData()`. (Присутствует закомментированный протокол и метод для трансформации данных чарта).
    *   `Views/`: (Новая директория для переиспользуемых View)
        *   `PostGridCell.swift`: `UICollectionViewCell`. Ячейка для отображения миниатюры поста в сетке (`UserProfileFeedViewController`). Содержит `postImageView` с закругленными углами. Метод `configure(with post: Post)` использует `Kingfisher` для загрузки изображения (приоритет `gridThumbnailURL`, затем `mediaItems.first?.url`) с плейсхолдером, индикатором, ретраями и обработкой ошибок. Отменяет загрузку в `prepareForReuse`.
        *   `TopMenuView.swift`: `UIView`. Кастомная верхняя панель навигации (используется в `UserProfileContainerViewController`). Содержит кнопки для выбора сегментов (`enum Segment`: `.card`, `.person`, `.stats`), опциональную кнопку `backButton` и кнопку `settingsButton`. Имеет анимированный `selectionIndicatorView` (подчеркивание). Управляет лейаутом в зависимости от `showBackButton`. Взаимодействует с VC через `TopMenuViewDelegate`.

### Features/Feed

_Модуль отвечает за ленту новостей._

*   `/Users/inga/Desktop/SensumApp/Features/Feed`: 
    *   `Coordinators/`: Координатор(ы) для управления навигацией в ленте.
        *   `FeedCoordinator.swift`: `class`. Реализует `Coordinator`, `FeedViewControllerDelegate`. Управляет навигацией в фиче Ленты. В `start()` создает `FeedViewModel` и `FeedViewController`, устанавливает зависимости и делает его корневым. Обрабатывает действия из `FeedViewController` (делегат): переход к профилю (`UserProfileCoordinator`), к комментариям (вызывает `showComments`, который планирует использовать `CommentsCoordinator`), к уведомлениям (`showNotifications` -> `appCoordinator`), к сообщениям (`showMessages` -> `appCoordinator` - TODO). Принимает сервисы (`Post`, `UserProfile`, `Follow`, `Progress`) и `appCoordinator`.
    *   `Models/`: (ПУСТО) Специфичные для ленты модели данных отсутствуют (вероятно, используются общие из `Domain/Models`).
    *   `Scenes/`: Экраны/сцены, относящиеся к ленте.
        *   `Comments/`: Экран(ы) комментариев к посту.
            *   `/Users/inga/Desktop/SensumApp/Features/Feed/Scenes/Comments/CommentsViewController.swift`
                *   **Назначение**: Экран (`UIViewController`, `@MainActor`) для отображения и добавления комментариев к посту.
                *   **Архитектура**: MVVM, управляется `CommentsViewModel`.
                *   **UI**: Использует `UITableView` с `CommentCell` (динамическая высота), `UITextView` для ввода текста (`commentTextView` с авто-высотой), контейнер для ввода (`inputContainerView`), индикатор ответа (`replyIndicatorView`) с кнопкой отмены (`cancelReplyButton`).
                *   **Функционал**:
                    *   Отображение комментариев (из `viewModel.$comments`).
                    *   Добавление новых комментариев (`viewModel.addComment`).
                    *   **Поддержка ответов на комментарии**: инициируется через `CommentCellDelegate`, показывает `replyIndicatorView`, вызывает `viewModel.startReplyTo/cancelReply`.
                    *   Обработка состояний загрузки, отправки, ошибок (из `viewModel`).
                    *   Управление клавиатурой и автопрокрутка.
                *   **Зависимости**: `CommentsViewModel`.
                *   **Делегаты**: `UITableViewDataSource`, `UITableViewDelegate`, `UITextViewDelegate`, `CommentCellDelegate`.
            *   `Views/`: Кастомные View для экрана комментариев.
                *   `CommentCell.swift`: `UITableViewCell`. Ячейка для отображения одного комментария в `CommentsViewController`. Отображает аватар (`avatarImageView`, Kingfisher), имя (`usernameLabel`), текст (`commentTextLabel`), время (`timestampLabel`). Содержит кнопку "Ответить" (`replyButton`). Для комментариев-ответов (с `parentCommentId`) показывает визуальный отступ (`indentationView`) и метку `replyToLabel`. Реализует `configure(with:)` для заполнения данными из `Comment`. Определяет протокол `CommentCellDelegate` и уведомляет делегата через `didTapReplyButton(for:)` при нажатии кнопки ответа.
        *   `FeedList/`: Основной экран ленты новостей.
            *   `/Users/inga/Desktop/SensumApp/Features/Feed/Scenes/FeedList/FeedViewController.swift`
                *   **Назначение**: Главный экран ленты (`UIViewController`), отображающий вертикальный список постов.
                *   **Архитектура**: MVVM, использует `Combine`.
                *   **Зависимости**: `FeedViewModelProtocol` (для постов), (требуется сервис для сторис).
                *   **Состояние (`@Published`)**: `feedPosts: [Post]`, `storyUsers: [User]` (моковые), `isLoading: Bool`, `isFetchingMore: Bool`, `canLoadMore: Bool`, `errorMessage: String?`.
                *   **Функционал**:
                    *   Загрузка ленты постов (`fetchPosts`) с пагинацией (`lastDocumentSnapshot`, `postsLimit`) через `PostService`.
                    *   Обновление ленты (`refreshFeed`) по pull-to-refresh.
                    *   Дозагрузка постов (`loadMorePostsIfNeeded`).
                    *   Загрузка пользователей для сторис (`fetchStoryUsers` - **заглушка**).
                    *   Обработка лайков (`toggleLike`) с **оптимистичным обновлением UI** и откатом при ошибке.
                    *   Подписка на `Notification.Name.didCreateNewPost` для автоматического обновления ленты после создания поста.
        *   `PostDetail/`: (ПУСТО) Экран детального просмотра поста.
        *   `UserPostScroll/`: Экран прокрутки постов конкретного пользователя.
            *   `UserPostScrollViewController.swift`: `UIViewController`. Показывает ленту постов *конкретного* пользователя, позволяя начать просмотр с определенного поста (`startIndex`). Использует `UICollectionView` с `FullPostCell` и `PaginationIndicatorFooterView`, динамическую высоту ячеек, пагинацию (`UICollectionViewDataSourcePrefetching`). Очень похож на `FeedViewController`. Получает данные от `UserPostScrollViewModel` (инъекция через `init`). Реализует `FullPostCellDelegate` для обработки действий в ячейке (лайк, коммент, закладка, профиль, разворачивание описания), а также кнопку опций, которая показывает `actionSheet` с возможностью *удаления* поста (`showDeleteConfirmation`, вызывает `viewModel.deletePost`). Уведомляет координатор через `UserPostScrollViewControllerDelegate`.
    *   `ViewModels/`: ViewModel'и для сцен ленты.
        *   `CommentsViewModel.swift`: `@MainActor ObservableObject`. Управляет экраном комментариев (`CommentsViewController`). Получает `postId` и сервисы (`PostService`, `AuthService`) через `init`. **Использует Firestore listener (`listenForComments`, `commentsListener`) для получения комментариев в реальном времени**, обновляя `@Published var comments`. Управляет состояниями загрузки (`@Published isLoading`) и отправки (`@Published isSending`). Обрабатывает добавление комментариев (`addComment`), **поддерживая ответы** (устанавливает `parentCommentId`). Управляет режимом ответа через `@Published replyingToComment` и `@Published isInReplyMode`, предоставляя методы `startReplyTo(comment:)` и `cancelReply()`. Публикует ошибки через `@Published errorMessage`.
        *   `/Users/inga/Desktop/SensumApp/Features/Feed/ViewModels/FeedViewModel.swift`
            *   **Назначение**: ViewModel для `FeedViewController`. Отвечает за логику и состояние ленты новостей.
            *   **Архитектура**: MVVM, использует `Combine`.
            *   **Зависимости**: `PostServiceProtocol` (для постов), (требуется сервис для сторис).
            *   **Состояние (`@Published`)**: `feedPosts: [Post]`, `storyUsers: [User]` (моковые), `isLoading: Bool`, `isFetchingMore: Bool`, `canLoadMore: Bool`, `errorMessage: String?`.
            *   **Функционал**:
                *   Загрузка ленты постов (`fetchPosts`) с пагинацией (`lastDocumentSnapshot`, `postsLimit`) через `PostService`.
                *   Обновление ленты (`refreshFeed`) по pull-to-refresh.
                *   Дозагрузка постов (`loadMorePostsIfNeeded`).
                *   Загрузка пользователей для сторис (`fetchStoryUsers` - **заглушка**).
                *   Обработка лайков (`toggleLike`) с **оптимистичным обновлением UI** и откатом при ошибке.
                *   Подписка на `Notification.Name.didCreateNewPost` для автоматического обновления ленты после создания поста.
        *   `UserPostScrollViewModel.swift`: `@MainActor ObservableObject`. Управляет экраном прокрутки постов конкретного пользователя (`UserPostScrollViewController`). Получает `userId` и сервисы (`PostService`, `AuthService`, `FollowService`, `ProgressService`) через `init`. **Использует Firestore listener (`listenForUserPosts`, `userPostsListener`) для получения постов пользователя в реальном времени**, обновляя `@Published var userPosts`. Управляет состояниями загрузки (`@Published isLoading`) и пагинации (`@Published isFetchingMore`). Обрабатывает лайки (`likePost`), комментарии (`showComments`), удаление поста (`deletePost`). Публикует ошибки через `@Published errorMessage`.
    *   `Views/`: Переиспользуемые `UIView` и `UICollectionViewCell`, специфичные для фичи Feed.
        *   `CarouselMediaCell.swift`: `UICollectionViewCell`. Ячейка для отображения одного медиа-элемента (`mediaImageView`) в карусели внутри `FullPostCell`. Метод `configure(with mediaURL: String)` использует `Kingfisher` для асинхронной загрузки изображения по URL (с плейсхолдером, индикатором активности и базовой обработкой ошибок). Отменяет загрузку (`kf.cancelDownloadTask()`) в `prepareForReuse`.
        *   `FullPostCell.swift`: Ключевая `UICollectionViewCell` для отображения поста в ленте (`FeedViewController`, `UserPostScrollViewController`). **Очень комплексная ячейка.** Содержит: **Header** (`authorAvatarImageView`, `authorUsernameButton`, `followButton`); **Media** (горизонтальная `mediaCollectionView` с `MediaItemCell`, `pageControl`, **поддерживает динамический aspect ratio** на основе первого медиа); **Actions** (`likeButton`, `commentButton`, `bookmarkButton`, `optionsButton`, счетчики лайков/комментариев); **Caption** (`captionLabel`, **поддерживает разворачивание/сворачивание** текста). Метод `configure(with post: Post, isFollowed: Bool)` заполняет ячейку данными, загружает изображения (Kingfisher), настраивает состояние кнопок и caption. При тапе на caption вызывает `delegate.fullPostCellDidRequestLayoutUpdate(at:)` для обновления высоты ячейки. Уведомляет обо всех других действиях через `FullPostCellDelegate` (методы `didTapUsername`, `didTapFollowButton`, `didTapLikeButton`, `didTapCommentButton`, `didTapOptionsButton`).
        *   `MediaItemCell.swift`: `UICollectionViewCell`. Ячейка для отображения одного медиа-элемента (`imageView`) в `FullPostCell` (внутри `mediaCollectionView`), а также, возможно, в сетке (`PostMediaSelectionViewController`). Содержит `imageView` с закругленными углами и `contentMode = .scaleAspectFill`. Метод `configure(with url: URL?)` использует `Kingfisher` для загрузки изображения по URL (с плейсхолдером, индикатором активности, fade-переходом). Отменяет загрузку (`kf.cancelDownloadTask()`) в `prepareForReuse`.
        *   `PaginationIndicatorFooterView.swift`: `UICollectionReusableView`. Простой футер для `UICollectionView`, используемый для отображения индикатора загрузки (`UIActivityIndicatorView`) при пагинации. Управляется состоянием `viewModel.isFetchingMore` в `UserPostScrollViewController`.
        *   `PostCellDelegate.swift`: Определяет протокол (`protocol PostCellDelegate: AnyObject`) для уведомления о взаимодействии с ячейкой поста типа `UITableViewCell` (вероятно, для другого экрана/представления, не используется `FullPostCell`). Содержит методы: `postCellDidTapAuthor(_:)`, `postCellDidTapLikeButton(_:currentLikeState:)`, `postCellDidTapCommentButton(_:)`, `postCellDidToggleCaption(_:)`.
        *   `StoriesHeaderView.swift`: Кастомный `UIView`, используемый как заголовок (например, для `FeedViewController`). Содержит горизонтальную `collectionView` (`UICollectionView`), которая отображает ячейки `StoryCell`. Настраивает layout для коллекции (горизонтальный скролл, размеры ячеек, отступы). Предоставляет метод `setCollectionViewDataSourceDelegate` для установки `dataSource` и `delegate` извне (например, из контроллера).
        *   `StoryCell.swift`: `UICollectionViewCell`. Ячейка для отображения **одной** истории (аватара и имени пользователя) в горизонтальной ленте `StoriesHeaderView`. Содержит `avatarImageView` (круглый, с временной цветной рамкой для новых сторис) и `usernameLabel`. Метод `configure(username: String, avatarURL: String?, hasNewContent: Bool)` загружает аватар через Kingfisher и устанавливает имя/рамку. **Не содержит сложной логики или делегатов.**

### Features/Leveling

_Модуль отвечает за выполнение упражнений с использованием анализа движений (Pose Estimation) и связанную с этим логику._

*   `/Users/inga/Desktop/SensumApp/Features/Leveling`:
    *   `Analyzers/`: Содержит протоколы и конкретные реализации анализаторов упражнений.
        *   `ExerciseAnalyzerProtocols.swift`: Определяет основные протоколы для системы анализа упражнений: `ExerciseAnalyzerDelegate` (для уведомления о подсчете повторений и смене состояния) и `ExerciseAnalyzer` (интерфейс для конкретных анализаторов, требует метод `analyze(worldLandmarks:)` и `reset()`). Также содержит перечисление `PoseConnections` с индексами ключевых точек MediaPipe (`LandmarkIndex`) и списком соединений (`connections`) для отрисовки скелета.