import Foundation
import CoreMotion
import simd // Для CMQuaternion -> simd_quatd

class MotionManager {
    
    // Синглтон для удобства доступа (опционально)
    static let shared = MotionManager()
    
    private let motionManager = CMMotionManager()
    private let updateQueue = OperationQueue() // Отдельная очередь для получения данных
    
    // Последний известный кватернион ориентации устройства
    private(set) var currentAttitude: simd_quatd?
    
    // Флаг активности
    var isTracking: Bool {
        return motionManager.isDeviceMotionActive
    }
    
    private init() {
        // Настраиваем интервал обновлений (например, 60 раз в секунду)
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        updateQueue.name = "com.sensum.motionQueue"
        updateQueue.maxConcurrentOperationCount = 1
    }
    
    /// Запускает получение обновлений ориентации устройства.
    /// - Parameter errorHandler: Замыкание для обработки ошибок Core Motion.
    func startUpdates(errorHandler: ((Error) -> Void)? = nil) {
        guard motionManager.isDeviceMotionAvailable else {
            print("[MotionManager] Ошибка: Device Motion недоступен на этом устройстве.")
            // TODO: Обработать ошибку - возможно, приложение не может работать без этого
            return
        }
        
        guard !motionManager.isDeviceMotionActive else {
            print("[MotionManager] Предупреждение: Обновления уже запущены.")
            return
        }
        
        print("[MotionManager] Запуск обновлений Device Motion...")
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, // Стабильная система координат
                                               to: updateQueue)
        { [weak self] (motion, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("[MotionManager] Ошибка получения Device Motion: \(error)")
                self.stopUpdates() // Останавливаем при ошибке
                errorHandler?(error)
                return
            }
            
            if let attitude = motion?.attitude {
                // Сохраняем кватернион (тип Double)
                self.currentAttitude = simd_quatd(ix: attitude.quaternion.x,
                                                  iy: attitude.quaternion.y,
                                                  iz: attitude.quaternion.z,
                                                  r: attitude.quaternion.w)
                // Можно добавить лог для отладки, но он будет очень частым
                // print("[MotionManager] Attitude updated: \(self.currentAttitude!)")
            }
        }
    }
    
    /// Останавливает получение обновлений ориентации.
    func stopUpdates() {
        if motionManager.isDeviceMotionActive {
            print("[MotionManager] Остановка обновлений Device Motion.")
            motionManager.stopDeviceMotionUpdates()
            currentAttitude = nil // Сбрасываем ориентацию
        }
    }
}

// Расширение для удобного создания simd_quatd из CMQuaternion
// (Можно оставить здесь или вынести в отдельный файл утилит)
extension simd_quatd {
    init(_ quaternion: CMQuaternion) {
        self.init(ix: quaternion.x, iy: quaternion.y, iz: quaternion.z, r: quaternion.w)
    }
}
