# Дорожная карта SensumApp - Социальная Платформа

## Концептуальное Дерево Архитектуры (Планируемое)

## Phase 1: Refactoring & Setup (ЗАВЕРШЕНО!)

*Цель: Перестроить структуру проекта под новую концепцию, переименовать компоненты, настроить базовые координаторы для всех вкладок.*

-   [x] **Refactor Feature:** Create `Features/UserProfile` folder structure and move/rename components from old `Features/Person`. (Выполнено)
-   [x] **Rename/Create UserProfile Components (Модальный профиль другого пользователя):**
    -   [x] Rename `PersonCoordinator` -> `UserProfileCoordinator` (file & class). (Выполнено)
    -   [x] Rename `PersonContainerViewController` -> `UserProfileContainerViewController` (file & class). (Выполнено)
    -   [x] Rename `ProfileViewController` -> `UserProfileCardViewController` (file & class, Макет 2). (Выполнено)
    -   [x] Rename `StatsViewController` -> `UserProfileStatsViewController` (file & class, Макет 4). (Выполнено)
    -   [x] Create placeholder `UserProfileFeedViewController.swift` (file & class, Макет 3). (Выполнено)
    -   [x] Update `UserProfileContainerViewController` to manage Card/Person/Stats VCs. (Выполнено)
    -   [x] Update `TopMenuView.swift` segments: "Card", "Person", "Stats". Add back arrow delegate?. (Выполнено)
-   [x] **Create Feed Components (Tab 1 - Placeholders):**
    -   [x] Create folder `Features/Feed`. (Выполнено пользователем)
    -   [x] Create `FeedCoordinator.swift` (file & class). (Выполнено)
    -   [x] Create `FeedViewController.swift` (file & class). (Выполнено)
-   [x] **Create CurrentUserProfile Components (Tab 2 - Placeholders):**
    -   [x] Create folder `Features/CurrentUserProfile`. (Выполнено пользователем)
    -   [x] Create `CurrentUserProfileCoordinator.swift` (file & class). (Выполнено)
    -   [x] Create placeholder `CurrentUserProfileContainerViewController.swift`? (Or use `UserProfileFeedVC` directly). (Выполнено - пока без контейнера)
-   [x] **Verify/Update Leveling Components (Tab 3):**
    -   [x] Verify `Features/Leveling` exists. (Выполнено)
    *   [x] Verify `LevelingCoordinator.swift` exists (update if needed). (Создан)
    *   [x] Verify `ExerciseSelectionViewController.swift` & `ExerciseExecutionViewController.swift` exist. (Выполнено)
-   [x] **Create Progress Components (Tab 4 - Placeholders):**
    *   [x] Create folder `Features/Progress`. (Выполнено)
    *   [x] Create `ProgressCoordinator.swift` (file & class). (Выполнено)
    *   [x] Create `ProgressViewController.swift` (file & class). (Выполнено)
-   [x] **Verify/Update Store Components (Tab 5 - Placeholders):**
    *   [x] Verify `Features/Store` exists. (Выполнено)
    *   [x] Verify `StoreCoordinator.swift` exists (update if needed). (Создан)
    *   [x] Verify `StoreViewController.swift` exists. (Выполнено)
-   [x] **Update AppCoordinator (`SceneDelegate.swift`):**
    *   [x] Configure `UITabBarController` with: `FeedCoordinator`, `CurrentUserProfileCoordinator`, `LevelingCoordinator`, `ProgressCoordinator`, `StoreCoordinator`. (Выполнено)
    *   [x] Ensure all coordinators are initialized and started correctly. (Выполнено)
-   [x] **Update Imports & References:** Systematically fix all broken imports and class/file references project-wide after renames. (Выполнено)
-   [x] **Delete Unused Files/Folders:** Delete `SensumApp/ViewController.swift`, `Features/Person`, `Features/Rank`, `Features/Events`. (Выполнено пользователем)
-   [x] **Build & Test:** Ensure the app compiles and runs with the new structure (mostly placeholders). (Выполнено - Компилируется!)

## Phase 2: Backend & Authentication (Завершено - База)
*Цель: Настроить Firebase, реализовать вход и регистрацию.*

-   [x] Настроить Firebase Project (Auth, Firestore, Storage). (Выполнено)
-   [x] Реализовать `AuthService`. (Выполнено)
-   [x] Создать `AuthCoordinator`. (Выполнено)
-   [x] Реализовать `AppCoordinator` для запуска `AuthCoordinator`. (Выполнено)
-   [x] Создать UI и ViewModel для Login/Register (Email/Password). (Базово выполнено)
-   [ ] Реализовать Google Sign-In.
-   [ ] Реализовать UI биндинги и показ ошибок в Login/Register.

## Phase 3: Core Models & Services (Завершено - База)
*Цель: Определить структуру данных и сервисы для взаимодействия с бэкендом.*

-   [x] Определить Firestore Модели (`User`, `Post` - фото+текст). (Выполнено)
-   [x] Создать `StorageService`. (Выполнено)
-   [x] Создать `UserProfileService`. (Выполнено)
-   [x] Создать `PostService`. (Выполнено)
-   [x] Создать `FollowService`. (Выполнено)
-   [ ] Определить модель `Follow`?
-   [ ] Создать `FeedService`.

## Phase 4: Feature Implementation - Feed & CurrentUserProfile (В процессе)
*Цель: Реализовать основные экраны - ленту и профиль текущего пользователя.*

-   [ ] **Feed (Tab 1):** UI ленты, "сторис", ViewModel, загрузка данных, навигация на `UserProfileCoordinator`.
-   [x] **CurrentUserProfile (Tab 2):** Координатор, переиспользование `UserProfileFeedViewController`, отображение данных (аватар, шапка, сетка постов), настройка UI (Edit). (Базово выполнено)

## Phase 5: Feature Implementation - UserProfile (Modal)
*Цель: Реализовать показ профиля другого пользователя.*

-   [ ] Реализация `UserProfileContainerViewController` (слайдер Card/Person/Stats).
-   [ ] Реализация `UserProfileCardViewController` (Макет 2).
-   [ ] Реализация `UserProfileFeedViewController` (Макет 3) - переиспользование.
-   [ ] Реализация `UserProfileStatsViewController` (Макет 4).
-   [ ] Настроить представление/переход из `FeedCoordinator`.

## Phase 6: Other Tabs & Features
*Цель: Реализовать заглушки/базовый функционал остальных вкладок и фич.*

-   [ ] Leveling (Tab 3) - Интеграция существующей логики.
-   [ ] Progress (Tab 4) - Базовый UI.
-   [ ] Store (Tab 5) - Базовый UI.
-   [ ] Create (Центральная кнопка) - Базовый UI/флоу (Заменен на Leveling).
-   [ ] Сообщения (иконка в Feed) - Базовый UI.
-   [ ] Подписки (логика и UI).
-   [ ] Статы/Достижения (логика и UI).
-   [ ] **Comments:** Реализовать UI и логику для просмотра и добавления комментариев к постам.
-   [ ] **Image Slider:** Поддержка нескольких фото в посте, реализация горизонтального свайпа и индикатора в `FullPostCell`.

## Ongoing / TODOs

-   [x] Analyze project structure, logic, and architecture (Completed)
-   [ ] Исследовать и исправить баги компиляции Xcode 16 beta (`contentInsetAdjustmentBehavior`, `isTranslucent`).
-   [ ] Добавить проверку прав доступа к галерее.
-   [ ] Решить, как будет работать навигация на Настройки (из `UserProfile` или `CurrentUserProfile`).
-   [x] Implement `FeedViewController` to display posts (basic structure)
-   [x] Implement `PostCell` for displaying individual posts
-   [x] Connect `FeedViewModel` to `FeedViewController`
-   [x] Implement denormalization for author data in posts (`Post` model, `PostService`)
-   [x] Update `PostCell` to use denormalized data
-   [x] Add "New Post" button to `UserProfileFeedViewController`
-   [x] Implement image selection logic in `UserProfileFeedViewController`
-   [x] Create `CreatePostViewController.swift` (UI Structure)
-   [x] Create `CreatePostViewModel.swift` (Logic for sharing)
-   [x] Connect `CreatePostViewController` and `CreatePostViewModel`
-   [x] Update `CurrentUserProfileCoordinator` to show `CreatePostViewController`
-   [x] Implement Post Detail View (Navigate from grid/feed)
-   [x] Create fullscreen post carousel viewer (`UserPostScrollViewController.swift`)
-   [x] Implement fullscreen post cell (`FullPostCell.swift`)
-   [x] Update `CurrentUserProfileCoordinator` to show fullscreen post carousel
