Папка: Features/CurrentUserProfile/Scenes
Название папки: Scenes
Содержит: Папку EditProfile/.
Папка: Features/CurrentUserProfile/Scenes/EditProfile
Название папки: EditProfile
Назначение папки: Экран редактирования профиля.
Содержит: EditProfileViewController.swift.
Файл: Features/CurrentUserProfile/Scenes/EditProfile/EditProfileViewController.swift
Название файла: EditProfileViewController.swift
Назначение файла: UI экрана редактирования профиля.
Описание: Отображает текущий аватар, поля для редактирования имени и статуса/био, кнопку смены аватара. Использует PHPickerViewController для выбора нового изображения. Реализует UITextViewDelegate для логики плейсхолдера. Связан с EditProfileViewModel через Combine для загрузки начальных данных и отображения состояния загрузки/ошибок. При нажатии "Save" вызывает viewModel.saveProfile, при нажатии "Cancel" уведомляет делегата (CurrentUserProfileCoordinator) через EditProfileViewControllerDelegate.
Содержит: Класс EditProfileViewController, протокол EditProfileViewControllerDelegate, UI элементы (UIImageView, UIButton, UITextField, UITextView, UIActivityIndicatorView), реализация PHPickerViewControllerDelegate, UITextViewDelegate, методы setupBindings, checkForChanges.
Технологии: UIKit, Combine, PhotosUI, Kingfisher.
Путь: CurrentUserProfileCoordinator.showEditProfile() -> Создание и показ EditProfileViewController.
