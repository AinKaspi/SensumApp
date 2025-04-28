Папка: Features/UserProfile
Название папки: UserProfile
Назначение папки: Содержит переиспользуемые компоненты UI и логики для отображения профиля пользователя (как своего, так и чужого).
Описание: Эта папка предоставляет набор экранов (Card, Person/FeedGrid, Stats), управляемых контейнером (UserProfileContainerViewController), и соответствующие ViewModel'и и View. Координатор UserProfileCoordinator отвечает за запуск этого флоу для конкретного userID (обычно при переходе из ленты). Компоненты из этой папки используются как CurrentUserProfileCoordinator (для Таба 2), так и UserProfileCoordinator (для просмотра чужих профилей).
Содержит: Папки Coordinators/, Scenes/, ViewModels/, Views/.
Технологии: UIKit, Combine, DGCharts, Kingfisher.
Путь: FeedCoordinator -> UserProfileCoordinator.start() -> UserProfileContainerViewController ИЛИ CurrentUserProfileCoordinator.start() -> UserProfileFeedViewController.
