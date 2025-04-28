Файл: Core/Services/PostService.swift
Название файла: PostService.swift
Назначение файла: Управление постами (создание, загрузка, лайки, комментарии).
Описание: Предоставляет методы для создания поста (createPost - с денормализацией данных автора), загрузки постов пользователя (fetchPosts - с пагинацией), загрузки ленты (fetchFeedPosts - с пагинацией), установки/снятия лайка (likePost, unlikePost - с обновлением счетчика и записи в подколлекцию), загрузки и добавления комментариев (fetchComments, addComment - с денормализацией и обновлением счетчика). Использует Firestore.
Содержит: Протокол PostServiceProtocol, класс PostService, методы для работы с постами, лайками, комментариями.
Технологии: Foundation, FirebaseFirestore.
Путь: Создается в DIContainer. Используется FeedViewModel, UserProfileFeedViewModel, UserPostScrollViewModel, CommentsViewModel, CreatePostViewModel.
