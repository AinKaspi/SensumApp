# Дорожная карта SensumApp - Социальная Платформа

## Концептуальное Дерево Архитектуры (Планируемое)

```
SensumApp/
|-- App/
|   |-- AppDelegate.swift
|   |-- SceneDelegate.swift  (Содержит AppCoordinator)
|   +-- Coordinator.swift    (Базовый протокол)
|
|-- Core/
|   |-- Models/              (User.swift, Post.swift, Follow.swift, Stats.swift, etc.)
|   |-- Networking/          (APIService.swift, FirebaseService.swift, etc.)
|   |-- Services/            (AuthService.swift, StorageService.swift, FeedService.swift, etc.)
|   +-- Utils/               (Extensions, Helpers, etc.)
|
|-- Features/
|   |-- Authentication/      (Флоу входа/регистрации)
|   |   |-- Coordinators/    (AuthCoordinator.swift)
|   |   |-- Scenes/
|   |   |   |-- Login/       (LoginViewController.swift, LoginViewModel.swift)
|   |   |   +-- Register/    (RegisterViewController.swift, RegisterViewModel.swift)
|   |
|   |-- Feed/                (Таб 1: Лента)
|   |   |-- Coordinators/    (FeedCoordinator.swift)
|   |   |-- Scenes/
|   |   |   +-- FeedList/    (FeedViewController.swift, FeedViewModel.swift)
|   |   +-- Views/           (StoryCircleCell.swift, PostCell.swift, etc.)
|   |
|   |-- UserProfile/         (Экраны для профиля *ДРУГОГО* пользователя - НЕ в таббаре)
|   |   |-- Coordinators/    (UserProfileCoordinator.swift)
|   |   |-- Scenes/
|   |   |   |-- Container/   (UserProfileContainerViewController.swift)
|   |   |   |-- Card/        (UserProfileCardViewController.swift)
|   |   |   |-- FeedGrid/    (UserProfileFeedViewController.swift)
|   |   |   +-- Stats/       (UserProfileStatsViewController.swift)
|   |   +-- Views/           (TopMenuView.swift)
|   |   +-- ViewModels/      (PersonViewModel.swift - TODO: Rename?)
|   |
|   |-- CurrentUserProfile/  (Таб 2: Профиль Текущего Пользователя)
|   |   |-- Coordinators/    (CurrentUserProfileCoordinator.swift)
|   |   |-- Scenes/          (Использует UserProfileFeedViewController, UserProfileStatsViewController)
|   |   |   +-- Container?/  (Возможно, нужен свой контейнер или доп. логика)
|   |
|   |-- Create/              (Таб 3: Создать - Пока заменен на Leveling)
|   |   |-- ... (Заглушка)
|   |
|   |-- Leveling/            (Таб 3: Тренировки)
|   |   |-- Coordinators/    (LevelingCoordinator.swift)
|   |   |-- Scenes/          (ExerciseSelectionViewController.swift, ExerciseExecutionViewController.swift)
|   |   +-- ... (ViewModels, Helpers, Views)
|   |
|   |-- Progress/            (Таб 4: Прогресс - Заглушка)
|   |   |-- Coordinators/    (ProgressCoordinator.swift)
|   |   +-- Scenes/          (ProgressViewController.swift)
|   |
|   |-- Store/               (Таб 5: Магазин - Заглушка)
|   |   |-- Coordinators/    (StoreCoordinator.swift)
|   |   +-- Scenes/          (StoreViewController.swift)
|   |
|   +-- Messaging/           (Позже: Чаты)
|       |-- Coordinators/    (MessagingCoordinator.swift)
|       +-- Scenes/          (ChatListViewController.swift, ChatViewController.swift)
```

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

## Phase 2: Backend & Authentication

*Цель: Настроить Firebase, реализовать вход и регистрацию.*

-   [ ] Настроить Firebase Project (Auth, Firestore, Storage).
-   [ ] Реализовать `AuthService`.
-   [ ] Создать `AuthCoordinator`.
-   [ ] Реализовать `AppCoordinator` для запуска `AuthCoordinator`.
-   [ ] Создать UI и ViewModel для Login/Register (Email/Password, Google Sign-In).

## Phase 3: Core Models & Services

*Цель: Определить структуру данных и сервисы для взаимодействия с бэкендом.*

-   [ ] Определить Firestore Модели (`User`, `Post` - фото+текст, `Follow`, `Stats`).
-   [ ] Создать `StorageService`.
-   [ ] Создать `UserProfileService`.
-   [ ] Создать `PostService`.
-   [ ] Создать `FollowService`.
-   [ ] Создать `FeedService`.

## Phase 4: Feature Implementation - Feed & CurrentUserProfile

*Цель: Реализовать основные экраны - ленту и профиль текущего пользователя.*

-   [ ] **Feed (Tab 1):** UI ленты, "сторис", ViewModel, загрузка данных, навигация на `UserProfileCoordinator`.
-   [ ] **CurrentUserProfile (Tab 2):** Координатор, переиспользование `UserProfileFeedViewController`, отображение данных текущего юзера, настройка UI (Edit).

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

## Ongoing / TODOs

-   [ ] Исследовать и исправить баги компиляции Xcode 16 beta (`contentInsetAdjustmentBehavior`, `isTranslucent`).
-   [ ] Добавить проверку прав доступа к галерее.
-   [ ] Решить, как будет работать навигация на Настройки (из `UserProfile` или `CurrentUserProfile`).
