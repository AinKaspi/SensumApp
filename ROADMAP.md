---
*Легенда:*
*   `[ ]` - To Do
*   `[~]` - In Progress
*   `[X]` - Done
*   `(Px.THEME.y)` - Phase.Theme.TaskID

## Фаза 1: MVP

### Theme: Core & Foundation
*   `[X]` (P1.CORE.1) Настроить базовую структуру проекта (папки, основные зависимости CocoaPods).
*   `[X]` (P1.CORE.2) Определить основные модели данных (User, Post, MediaItem) + Firestore Codable.
*   `[X]` (P1.CORE.3) Реализовать базовый AuthService (Firebase Auth).
*   `[X]` (P1.CORE.4) Реализовать базовый UserProfileService (CRUD для User).
*   `[X]` (P1.CORE.5) Реализовать базовый PostService (CRUD для Post/MediaItem).
*   `[X]` (P1.CORE.6) Реализовать базовый FollowService.
*   `[X]` (P1.CORE.7) Реализовать ProgressService (CRUD для ProgressData).
*   `[X]` (P1.CORE.8) Настроить базовые координаторы (App, TabBar, Auth, Main).

### Theme: Authentication
*   `[X]` (P1.AUTH.1) Экран входа (LoginViewController + ViewModel).
*   `[X]` (P1.AUTH.2) Экран регистрации (RegisterViewController + ViewModel).
*   `[X]` (P1.AUTH.3) Логика перехода между Auth и Main.

### Theme: Profile (Current User)
*   `[X]` (P1.PROFILE.1) Экран профиля (UserProfileFeedViewController + ViewModel).
*   `[X]` (P1.PROFILE.2) Отображение данных пользователя (аватар, имя, статистика).
*   `[X]` (P1.PROFILE.3) Отображение сетки постов пользователя (UserProfileGridCell).
*   `[X]` (P1.PROFILE.4) Отображение Радар-диаграммы аттрибутов (Stats Tab - DGCharts).
*   `[X]` (P1.PROFILE.5) Кнопка "Edit Profile" и переход к экрану редактирования.
*   `[X]` (P1.PROFILE.6) Кнопка "Settings" и переход к экрану настроек (пока заглушка).
*   `[X]` (P1.PROFILE.7) Реализовать выход из аккаунта (Logout).
*   `[X]` (P1.PROFILE.8) Загрузка постов пользователя с пагинацией (Firestore).
*   `[X]` (P1.PROFILE.9) Обновление профиля при Pull-to-refresh.

### Theme: Profile Editing
*   `[X]` (P1.EDITPRF.1) Экран редактирования профиля (EditProfileViewController + ViewModel).
*   `[X]` (P1.EDITPRF.2) Возможность изменить имя, username, bio.
*   `[X]` (P1.EDITPRF.3) Возможность изменить аватар (выбор из галереи, загрузка в Storage).

### Theme: New Post Creation
*   `[X]` (P1.NEWPOST.1) Логика выбора фото/видео из галереи (Image Picker).
*   `[X]` (P1.NEWPOST.2) Экран кадрирования (`PostCropViewController` + `ImageCropView` + ViewModel). 
*   `[X]` (P1.NEWPOST.3) Реализация кадрирования с разными соотношениями сторон (9:16, 1:1, 1.91:1).
*   `[X]` (P1.NEWPOST.4) Экран добавления описания и публикации (`PostReviewViewController` + ViewModel).
*   `[X]` (P1.NEWPOST.5) Логика публикации поста (загрузка медиа в Storage, сохранение Post в Firestore).
*   `[X]` (P1.NEWPOST.6) Обработка нескольких изображений/видео в одном посте (карусель на экране кадрирования/ревью).
*   `[X]` (P1.NEWPOST.7) Навигация после успешной публикации (возврат к профилю/ленте).

### Theme: Feed (Post Scroll View)
*   `[X]` (P1.FEEDSCROLL.1) Исправить расчет высоты ячейки `FullPostCell` для разных соотношений сторон.
*   `[X]` (P1.FEEDSCROLL.2) Реализовать пагинацию при прокрутке ленты постов (`UserPostScrollViewModel`).
*   `[X]` (P1.FEEDSCROLL.3) Анимация при сворачивании/разворачивании описания поста (`captionLabel`).
*   `[X]` (P1.FEEDSCROLL.4) Отображение ошибок загрузки/пагинации пользователю (`UserPostScrollViewController`).
*   `[X]` (P1.FEEDSCROLL.5) Проверить и доработать `UserPostScrollViewModel` (логика лайков, обработка ошибок).
*   `[X]` (P1.FEEDSCROLL.6) Реализовать поддержку нескольких изображений в посте (`mediaCollectionView` в `FullPostCell`).
*   `[X]` (P1.FEEDSCROLL.7) Добавить `UIPageControl` для постов с несколькими изображениями.
*   `[X]` (P1.FEEDSCROLL.8) Реализовать предзагрузку изображений для `mediaCollectionView` (`Kingfisher.ImagePrefetcher`).
*   `[X]` (P1.FEEDSCROLL.9) Улучшить UI/UX `FullPostCell` (расположение кнопок, лайков, комментов).

### Theme: Comments (MVP)
*   `[X]` (P1.COMMENT.1) Исправить установку делегата `UserPostScrollViewControllerDelegate` для открытия экрана комментариев.
*   `[X]` (P1.COMMENT.2) Реализовать pull-to-refresh в `CommentsViewController`.
*   `[X]` (P1.COMMENT.3) Оптимизировать добавление комментария (возвращать добавленный `Comment`, не перезагружать все).

## Фаза 2: Улучшения и Новые Фичи

### Theme: Feed (Main)
*   `[ ]` (P2.FEEDMAIN.1) Реализовать основной экран ленты (`FeedViewController` + `FeedViewModel`).
*   `[ ]` (P2.FEEDMAIN.2) Загрузка постов от подписок пользователя (агрегация на клиенте или Cloud Functions?).
*   `[ ]` (P2.FEEDMAIN.3) Pull-to-refresh для основной ленты.
*   `[ ]` (P2.FEEDMAIN.4) Пагинация для основной ленты.

### Theme: Profile (Other User)
*   `[ ]` (P2.PROFILEOTH.1) Возможность открыть профиль другого пользователя (из ленты, из комментариев).
*   `[ ]` (P2.PROFILEOTH.2) Отображение кнопки "Follow"/"Unfollow" и логика подписки/отписки.

### Theme: Search/Explore
*   `[ ]` (P2.SEARCH.1) Экран поиска пользователей (`SearchViewController` + `SearchViewModel`).
*   `[ ]` (P2.SEARCH.2) Логика поиска пользователей в Firebase.
*   `[ ]` (P2.SEARCH.3) Отображение результатов поиска.
*   `[ ]` (P2.SEARCH.4) (Опционально) Вкладка "Explore" с рекомендуемыми постами/пользователями.

### Theme: Comments (Improvements)
*   `[ ]` (P2.COMMENT.1) Внедрить real-time обновления для комментариев (Firestore `addSnapshotListener`).
*   `[ ]` (P2.COMMENT.2) Реализовать лайки для комментариев (UI, Service, ViewModel).

## Фаза 3: Fitness & RPG

### Theme: Pose Estimation
*   `[ ]` (P3.POSE.1) Интегрировать MediaPipe (`pose_landmarker_full.task`, Float16, 256x256).
*   `[ ]` (P3.POSE.2) Экран записи упражнения с отображением камеры и оверлея скелета.
*   `[ ]` (P3.POSE.3) Базовый анализатор для одного-двух упражнений (например, приседания, отжимания).
*   `[ ]` (P3.POSE.4) Подсчет повторений и оценка качества выполнения.

### Theme: Progress Tracking
*   `[ ]` (P3.PROG.1) Сохранение результатов тренировок (упражнение, повторения, дата, оценка).
*   `[ ]` (P3.PROG.2) Отображение истории тренировок пользователя.
*   `[ ]` (P3.PROG.3) Расчет XP и обновление уровня/ранга пользователя на основе тренировок.
*   `[ ]` (P3.PROG.4) Расчет и обновление аттрибутов (STR, CON и т.д.) на основе выполненных упражнений.

### Theme: Comments (Advanced)
*   `[ ]` (P3.COMMENT.1) Реализовать ответы на комментарии (вложенность) (UI, Data Model, Service, ViewModel).
