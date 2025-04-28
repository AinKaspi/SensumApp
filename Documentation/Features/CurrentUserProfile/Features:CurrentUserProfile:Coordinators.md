Папка: Features/CurrentUserProfile/Coordinators
Название папки: Coordinators
Содержит: CurrentUserProfileCoordinator.swift.
Файл: Features/CurrentUserProfile/Coordinators/CurrentUserProfileCoordinator.swift
Название файла: CurrentUserProfileCoordinator.swift
Назначение файла: Координатор для Таба 2 (профиль текущего пользователя).
Описание: Инициализирует и показывает UserProfileFeedViewController (передавая ему isCurrentUser: true). Реализует UserProfileFeedViewControllerDelegate для обработки действий: выход (didRequestSignOut -> authService.signOut), переход к редактированию (didTapEditProfileButton -> showEditProfile), создание программы (didTapNewProgramButton - заглушка). Также реализует EditProfileViewControllerDelegate (для закрытия экрана редактирования) и UserPostScrollViewControllerDelegate (для навигации на комментарии из ленты постов). Создает и показывает EditProfileViewController и UserPostScrollViewController (заглушка).
Содержит: Класс CurrentUserProfileCoordinator, реализации делегатов UserProfileFeedViewControllerDelegate, EditProfileViewControllerDelegate, UserPostScrollViewControllerDelegate, методы start, showEditProfile, showUserPostScroll, didTapCommentsButton.
Технологии: UIKit.
Путь: AppCoordinator -> CurrentUserProfileCoordinator.start().
