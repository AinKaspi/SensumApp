import Foundation

struct Exercise: Identifiable { // Identifiable может быть полезен для таблиц/коллекций
    let id: String // Уникальный идентификатор (можно UUID)
    let name: String
    let description: String
    let iconName: String // Имя системной иконки или ассета
    // TODO: Добавить информацию о прокачиваемых атрибутах
}
