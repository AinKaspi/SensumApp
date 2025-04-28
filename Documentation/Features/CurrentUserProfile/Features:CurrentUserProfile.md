Папка: Features/CurrentUserProfile
Название папки: CurrentUserProfile
Назначение папки: Управление навигацией и специфичной логикой для Таба 2 ("Person" - профиль текущего пользователя).
Описание: Содержит координатор (CurrentUserProfileCoordinator), отвечающий за запуск и управление флоу Таба 2. Он показывает основной экран профиля (UserProfileFeedViewController из папки UserProfile), обрабатывает действия, специфичные для текущего пользователя (например, выход из системы, переход к редактированию профиля, создание нового поста/программы), и инициирует навигацию на другие экраны (редактирование, скролл постов, комментарии). Также содержит специфичные для этого флоу ViewModel'и (например, EditProfileViewModel) и экраны (EditProfileViewController).
Содержит: Папки Coordinators/, Scenes/, ViewModels/.
Технологии: UIKit, Combine.
Путь: AppCoordinator (в showMainAppFlow) -> CurrentUserProfileCoordinator.start() -> Показ UserProfileFeedViewController.
