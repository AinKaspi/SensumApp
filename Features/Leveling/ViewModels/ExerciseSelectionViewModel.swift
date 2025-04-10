import Foundation

// TODO: Определить протокол для связи с координатором
// protocol ExerciseSelectionViewModelCoordinatorDelegate: AnyObject { ... }

class ExerciseSelectionViewModel {

    // weak var coordinatorDelegate: ExerciseSelectionViewModelCoordinatorDelegate?
    
    // --- Данные --- 
    // Массив доступных упражнений (пока моковые данные)
    private let exercises: [Exercise] = [
        Exercise(id: "squats", name: "Приседания", description: "Классические приседания для проработки ног и ягодиц.", iconName: "figure.squat.square"),
        Exercise(id: "pushups", name: "Отжимания (Скоро)", description: "Базовое упражнение для груди, плеч и трицепсов.", iconName: "figure.pushups"),
        Exercise(id: "lunges", name: "Выпады (Скоро)", description: "Упражнение для ног и ягодиц, улучшает баланс.", iconName: "figure.lunges"),
        Exercise(id: "plank", name: "Планка (Скоро)", description: "Статическое упражнение для укрепления мышц кора.", iconName: "figure.plank")
    ]
    
    // --- Публичный интерфейс для View Controller --- 
    
    /// Количество доступных упражнений
    var numberOfExercises: Int {
        return exercises.count
    }
    
    /// Возвращает модель упражнения по индексу
    /// - Parameter index: Индекс упражнения в массиве
    /// - Returns: Модель `Exercise` или `nil`, если индекс некорректен
    func exercise(at index: Int) -> Exercise? {
        guard index >= 0 && index < exercises.count else {
            return nil
        }
        return exercises[index]
    }
    
    // TODO: Добавить логику загрузки упражнений (из сети/базы)
    // TODO: Добавить метод для обработки выбора упражнения и вызова делегата координатора

    init(/* coordinatorDelegate: ExerciseSelectionViewModelCoordinatorDelegate? */) {
        // self.coordinatorDelegate = coordinatorDelegate
        print("ExerciseSelectionViewModel initialized")
    }
}
