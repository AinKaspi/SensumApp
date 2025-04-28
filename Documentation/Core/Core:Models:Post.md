Файл: Core/Models/Post.swift
Название файла: Post.swift
Назначение файла: Определение структуры данных для поста.
Описание: Представляет пост в ленте или профиле. Содержит ID поста, ID автора, URL изображения, текст, дату создания, счетчики лайков/комментариев, а также денормализованные данные автора (имя, URL аватара) для эффективности. Свойство isLiked вычисляется на клиенте. Реализует Codable и Identifiable. Использует @DocumentID и ручную реализацию Codable для исключения isLiked. Используется PostService и ViewModel'ями (FeedViewModel, UserProfileFeedViewModel, UserPostScrollViewModel).
Содержит: Структура Post (Codable, Identifiable), свойства (id, userID, imageURL, caption?, createdAt, likeCount, commentCount, isLiked, authorUsername?, authorAvatarURL?), CodingKeys, init(from:), encode(to:), дополнительный init.
Технологии: Foundation, FirebaseFirestore.
Путь: CreatePostViewModel -> PostService.createPost. PostService.fetchPosts/fetchFeedPosts -> ViewModel'и (FeedViewModel, UserProfileFeedViewModel, UserPostScrollViewModel) -> ViewControllers/Cells (PostCell, FullPostCell, PostGridCell). PostService.likePost/unlikePost обновляет likeCount.
