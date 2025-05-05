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
            *   `ViewModels/`: (ПУСТО) Папка для ViewModel'ей, специфичных для экрана комментариев (если они потребуются). На данный момент пуста, основная ViewModel (`CommentsViewModel`) находится уровнем выше.
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
        *   `PostCellDelegate.swift`: Определяет протокол (`protocol PostCellDelegate: AnyObject`) для уведомления о взаимодействии с ячейкой поста типа `UITableViewCell` (вероятно, для другого экрана/представления, не используется `FullPostCell`). Содержит методы: `postCellDidTapAuthor(_:)`, `postCellDidTapLikeButton(_:currentLikeState:)`, `postCellDidTapCommentButton(_:)`, `postCellDidToggleCaption(_:)`.
        *   `StoriesHeaderView.swift`: Кастомный `UIView`, используемый как заголовок (например, для `FeedViewController`). Содержит горизонтальную `collectionView` (`UICollectionView`), которая отображает ячейки `StoryCell`. Настраивает layout для коллекции (горизонтальный скролл, размеры ячеек, отступы). Предоставляет метод `setCollectionViewDataSourceDelegate` для установки `dataSource` и `delegate` извне (например, из контроллера).
        *   `StoryCell.swift`: `UICollectionViewCell`. Ячейка для отображения **одной** истории (аватара и имени пользователя) в горизонтальной ленте `StoriesHeaderView`. Содержит `avatarImageView` (круглый, с временной цветной рамкой для новых сторис) и `usernameLabel`. Метод `configure(username: String, avatarURL: String?, hasNewContent: Bool)` загружает аватар через Kingfisher и устанавливает имя/рамку. **Не содержит сложной логики или делегатов.**
