Файл: Common/Extensions/UITextView+Combine.swift
Название файла: UITextView+Combine.swift
Назначение файла: Добавление Combine-паблишера для изменений текста в UITextView и расширение Date.
Описание: Содержит два extension:
extension UITextView: Добавляет вычисляемое свойство textPublisher, которое создает AnyPublisher<String, Never>, эмитящий текст UITextView при каждом его изменении (используя NotificationCenter).
extension Date: Добавляет метод timeAgoDisplay(), который форматирует дату в относительное время ("5 минут назад", "вчера" и т.д.) с помощью RelativeDateTimeFormatter.
Содержит: extension UITextView, extension Date.
Технологии: UIKit, Combine, Foundation.
Путь: Date.timeAgoDisplay() используется в CommentCell. UITextView.textPublisher может использоваться ViewModel'ями для реактивного получения текста (например, в CreatePostViewModel или CommentsViewModel, хотя сейчас там используется UITextViewDelegate).
