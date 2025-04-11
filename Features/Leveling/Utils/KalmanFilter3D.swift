import Foundation
import simd
// Убираем Accelerate, добавляем Surge
// import Accelerate
import Surge

// Реализация Фильтра Калмана с использованием Surge
struct KalmanFilter3D {
    
    // --- Состояние и Ковариация --- 
    private(set) var state: Vector<Double> // Вектор состояния [x, y, z, vx, vy, vz] (6x1)
    private var P: Matrix<Double>         // Ковариация ошибки состояния P (6x6)
    
    // --- Параметры Модели --- 
    private let stateDimension: Int = 6
    private let measurementDimension: Int = 3
    
    // --- Матрицы Модели (Surge) ---
    private var F: Matrix<Double> // Матрица перехода состояния F (6x6)
    private var H: Matrix<Double> // Матрица измерения H (3x6)
    private var Q: Matrix<Double> // Ковариация шума процесса Q (6x6)
    private var R: Matrix<Double> // Ковариация шума измерения R (3x3)
    
    // --- Инициализация --- 
    init(initialMeasurement: simd_float3, 
         initialUncertainty P0: Double = 10.0,
         processNoise q: Double = 0.01,
         measurementNoise r: Double = 0.1) {
        
        // Начальное состояние
        self.state = Vector([Double(initialMeasurement.x), Double(initialMeasurement.y), Double(initialMeasurement.z), 0.0, 0.0, 0.0])
        
        // Начальная ковариация P (единичная * P0)
        self.P = P0 * Matrix<Double>.identity(size: stateDimension)
        
        // Матрица измерения H = [I(3x3) | 0(3x3)]
        var hValues = [[Double]](repeating: [Double](repeating: 0.0, count: stateDimension), count: measurementDimension)
        for i in 0..<measurementDimension { hValues[i][i] = 1.0 }
        self.H = Matrix(hValues)
        
        // Ковариация шума процесса Q (диагональная, шум для скорости)
        var qValues = [[Double]](repeating: [Double](repeating: 0.0, count: stateDimension), count: stateDimension)
        for i in measurementDimension..<stateDimension { qValues[i][i] = q }
        self.Q = Matrix(qValues)
        
        // Ковариация шума измерения R (диагональная)
        self.R = r * Matrix<Double>.identity(size: measurementDimension)
        
        // Матрица перехода F (инициализируем единичной, обновится в predict)
        self.F = Matrix<Double>.identity(size: stateDimension)
    }
    
    // --- Шаг Предсказания --- 
    mutating func predict(deltaTime: Double) {
        let dt = deltaTime
        guard dt > 0 else { return }

        // Обновляем матрицу перехода F
        // F = [ I  dt*I ]
        //     [ 0    I  ]
        // Создаем F заново или копируем и модифицируем
        var fMatrix = Matrix<Double>.identity(size: stateDimension) // Начинаем с единичной
        for i in 0..<measurementDimension {
            // Устанавливаем значение dt в соответствующий элемент
            // Индексация в Surge: matrix[row, column]
            fMatrix[i, i + measurementDimension] = dt 
        }
        self.F = fMatrix
        
        // Предсказание состояния: x_k = F * x_{k-1}
        state = Surge.mul(F, state)
        
        // Предсказание ковариации: P_k = F * P_{k-1} * F^T + Q
        P = Surge.add(Surge.mul(Surge.mul(F, P), Surge.transpose(F)), Q)
    }
    
    // --- Шаг Обновления --- 
    mutating func update(measurement: simd_float3) {
        // Измерение (вектор 3x1)
        let z = Vector([Double(measurement.x), Double(measurement.y), Double(measurement.z)])
        
        // Инновация: y = z - H * x_k
        let y = Surge.sub(z, Surge.mul(H, state))
        
        // Ковариация инновации: S = H * P * H^T + R
        let PHT = Surge.mul(P, Surge.transpose(H))
        let S = Surge.add(Surge.mul(H, PHT), R)
        
        // Коэффициент Калмана: K = P * H^T * S^{-1}
        guard let S_inv = try? Surge.inv(S) else {
            print("[KalmanFilter3D] Warning: Failed to invert S. Skipping update.")
            return
        }
        let K = Surge.mul(PHT, S_inv) // K будет 6x3
        
        // Обновление состояния: x_k+1 = x_k + K * y
        state = Surge.add(state, Surge.mul(K, y))
        
        // Обновление ковариации: P_k+1 = (I - K * H) * P_k
        let I = Matrix<Double>.identity(size: stateDimension)
        let KH = Surge.mul(K, H)
        let I_KH = Surge.sub(I, KH)
        P = Surge.mul(I_KH, P)
    }
    
    /// Возвращает отфильтрованное положение
    var filteredPosition: simd_float3 {
        return simd_float3(Float(state[0]), Float(state[1]), Float(state[2]))
    }
    
    /// Возвращает отфильтрованную скорость (опционально)
    var filteredVelocity: simd_float3 {
         return simd_float3(Float(state[3]), Float(state[4]), Float(state[5]))
    }
}

// Удаляем расширения для Accelerate-специфичных типов
/*
extension matrix_double6x6 { ... }
...
*/
