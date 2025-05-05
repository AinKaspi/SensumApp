### Features/Create

_Модуль отвечает за создание контента._

*   `/Users/inga/Desktop/SensumApp/Features/Create`: Модуль отвечает за создание контента (вероятно, постов). Содержит следующие поддиректории:
    *   `Scenes/`: Содержит различные сцены, связанные с созданием контента:
        *   `Cells/`: Кастомные ячейки для создания контента.
            *   `MediaThumbnailCell.swift`: `UICollectionViewCell` для отображения миниатюр изображений в сетке выбора медиа (`PostMediaSelectionViewController`). Содержит `UIImageView`. Поддержка видео удалена.
                *   **Назначение**: Простая ячейка (`UICollectionViewCell`) для отображения миниатюры изображения. **Не поддерживает видео**. Вероятно, используется в сетке выбора медиа из галереи.
                *   **UI**: Содержит один `UIImageView`, занимающий всю ячейку.
                *   **Функционал**: Метод `configure(with image: UIImage?)` для установки изображения. Очищается при переиспользовании.
                *   **Зависимости**: `UIKit`.
            *   `PreviewCell.swift`: `UICollectionViewCell` для отображения превью изображения с заданным `aspectRatio`. Используется, вероятно, в `PostReviewViewController`. Динамически изменяет размер внутреннего контейнера для сохранения пропорций.
                *   **Назначение**: `UICollectionViewCell` для отображения превью изображения (`UIImage`) с заданным соотношением сторон (`PostAspectRatio`). Используется в `PostMediaSelectionViewController`.
                *   **UI**: Содержит `imageView` внутри `containerView`. `containerView` динамически изменяет свой размер (через `width`/`height` constraints), чтобы соответствовать `PostAspectRatio`, центрируясь внутри `contentView` ячейки. `containerView` имеет скругленные углы.
                *   **Функционал**: Метод `configure(with:aspectRatio:)` устанавливает изображение и обновляет размеры `containerView`. `prepareForReuse` сбрасывает изображение и размеры.
        *   `CropDelegate.swift`: Протокол (`protocol CropDelegate: AnyObject`) для уведомления о завершении обрезки изображения. Содержит метод `cropViewControllerDidFinishCropping(item: EditableMediaItem)`.
        *   `PostCropViewController.swift`: 
            *   **Назначение**: Экран (`UIViewController`) для ручной обрезки **одного** изображения (`EditableMediaItem`) под заданное соотношение сторон (`PostAspectRatio`).
            *   **Архитектура**: MVC-подобная. Получает данные через `init`. Использует `PostCropViewControllerDelegate` (отмена) и `CropDelegate` (успех с результатом).
            *   **UI**: Основной элемент - кастомный `ImageCropView`, позволяющий панорамировать/масштабировать изображение. Навбар с "Cancel"/"Done".
            *   **Функционал**:
                *   Получает `EditableMediaItem` и `PostAspectRatio`.
                *   Настраивает `ImageCropView` с изображением и соотношением сторон.
                *   Загружает/применяет сохраненные параметры обрезки (`manualZoomScale`, `manualContentOffset`) из `EditableMediaItem`, если есть.
                *   По кнопке "Done": сохраняет параметры обрезки в `EditableMediaItem`, генерирует обрезанное изображение (`getCroppedImage()`) и сохраняет его в `EditableMediaItem.finalImage`, уведомляет `CropDelegate.cropViewControllerDidFinishCropping` с обновленным `EditableMediaItem`.
                *   По кнопке "Cancel": уведомляет `PostCropViewControllerDelegate.postCropDidCancel`.
            *   **Зависимости**: `EditableMediaItem`, `PostAspectRatio`, `ImageCropView`.
            *   **Делегаты**: `PostCropViewControllerDelegate`, `CropDelegate`.
        *   `PostMediaSelectionViewController.swift`: 
            *   **Назначение**: Экран (`UIViewController`) выбора единого соотношения сторон (`.portrait` 9:16 или `.square` 1:1) для всех медиафайлов поста и предпросмотра/выбора медиа для редактирования (обрезки).
            *   **Архитектура**: MVC-подобная, работает с `[EditableMediaItem]`, использует делегирование.
            *   **UI**: Горизонтальный `UICollectionView` (`previewCollectionView`) с `PreviewCell`, высота которого динамически меняется под выбранный формат. Кнопки выбора формата (`portraitRatioButton`, `squareRatioButton`).
            *   **Функционал**:
                *   Принимает `[EditableMediaItem]`. 
                *   Выбор формата кнопками.
                *   Обновление layout `previewCollectionView`.
                *   Обработка тапа на медиа (вызов `delegate.postMediaSelectionDidTapItem` для перехода к редактированию).
                *   Обработка "Next" (вызов `delegate.postMediaSelectionDidTapNext`).
                *   Обработка "Cancel" (вызов `delegate.postMediaSelectionDidCancel`).
                *   Реализация `CropDelegate` (`cropViewControllerDidFinishCropping`) для получения результата обрезки, обновления UI и уведомления `delegate.postMediaSelectionDidFinishCropping`.
            *   **Зависимости**: `[EditableMediaItem]`.
            *   **Делегаты**: `PostMediaSelectionDelegate`, `UICollectionViewDataSource`, `UICollectionViewDelegate`, `UICollectionViewDelegateFlowLayout`, `UIScrollViewDelegate`, `CropDelegate`.
        *   `PostReviewViewController.swift`: 
            *   **Назначение**: Финальный экран (`UIViewController`) создания поста. Отображает превью всех обрезанных медиа, позволяет добавить подпись и инициировать публикацию.
            *   **Архитектура**: MVVM. Управляется `CreatePostViewModel`. Использует `Combine` для биндингов.
            *   **UI**: `UIScrollView` содержит `UICollectionView` (`previewCollectionView`) для горизонтального показа превью (с динамическим размером ячеек под `viewModel.postAspectRatio`), `UITextView` (`captionTextView`) для подписи, `UIButton` (`shareButton`) для публикации, `UIActivityIndicatorView`.
            *   **Функционал**:
                *   Получает `CreatePostViewModel`.
                *   Отображает данные из `viewModel.editableMedia` в `previewCollectionView`.
                *   Связывает `captionTextView` с `viewModel.caption`.
                *   По кнопке "Share" вызывает `viewModel.sharePost()`.
                *   Через `Combine` биндит состояние `viewModel.isSharing` к UI (индикатор, кнопка) и `viewModel.errorMessage` к показу ошибок.
                *   При успехе вызывает `delegate.postReviewDidFinishSuccessfully()`.
            *   **Зависимости**: `CreatePostViewModel`, `Combine`, `UIKit`.
            *   **Делегаты**: `PostReviewViewControllerDelegate`, `UICollectionViewDataSource`, `UICollectionViewDelegateFlowLayout`, `UITextViewDelegate`.
    *   `ViewControllers/`: (ПУСТО) Общие/базовые ViewController'ы отсутствуют.
    *   `ViewModels/`: ViewModel'и для сцен фичи.
        *   `CreatePostViewModel.swift`: `final class`. Управляет состоянием (`@Published`: `editableMedia`, `postAspectRatio`, `caption`, `isSharing`, `errorMessage`) и логикой экрана `PostReviewViewController`. Инкапсулирует весь процесс публикации: генерирует финальные изображения (с учетом ручного/автоматического кропа), загружает их и миниатюру в `StorageService` (используя Combine), создает запись поста через `PostService`. Содержит сложную логику кропа изображений.

### Features/CurrentUserProfile