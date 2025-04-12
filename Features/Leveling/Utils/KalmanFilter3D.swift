import Foundation
import simd
import Surge // Используем Surge для матриц

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
    // R вычисляется динамически

    // Базовые шумы (сохраняются при инициализации)
    private let baseMeasurementNoise: Double
    private let processNoise: Double // <--- Свойство добавлено

    // --- Инициализация ---
    init(initialMeasurement: simd_float3,
         initialUncertainty P0: Double = 10.0,
         processNoise q: Double = 0.01,
         measurementNoise r: Double = 0.2) { // Оставим увеличенное r по умолчанию

        // Начальное состояние
        self.state = Vector([Double(initialMeasurement.x), Double(initialMeasurement.y), Double(initialMeasurement.z), 0.0, 0.0, 0.0])

        // Начальная ковариация P
        self.P = P0 * Matrix<Double>.identity(size: stateDimension)

        // Матрица измерения H
        var hValues = [[Double]](repeating: [Double](repeating: 0.0, count: stateDimension), count: measurementDimension)
        for i in 0..<measurementDimension { hValues[i][i] = 1.0 }
        self.H = Matrix(hValues)

        // Ковариация шума процесса Q (инициализируем нулями)
        self.Q = Matrix<Double>(rows: stateDimension, columns: stateDimension, repeatedValue: 0.0)

        // Сохраняем базовые шумы
        self.baseMeasurementNoise = r
        self.processNoise = q // <--- Сохраняем q

        // Матрица перехода F
        self.F = Matrix<Double>.identity(size: stateDimension)
    }

    // --- Шаг Предсказания ---
    mutating func predict(deltaTime: Double) {
        let dt = deltaTime
        guard dt > 0 && dt < 1.0 else { return }

        // 1. Обновляем матрицу перехода F
        var fMatrix = Matrix<Double>.identity(size: stateDimension)
        for i in 0..<measurementDimension {
            fMatrix[i, i + measurementDimension] = dt
        }
        self.F = fMatrix

        // 2. Обновляем матрицу шума процесса Q
        let qVal = self.processNoise // <--- Используем сохраненное свойство
        let dt_2 = dt * dt
        let dt_3_over_2 = dt_2 * dt / 2.0
        let dt_4_over_4 = dt_2 * dt_2 / 4.0

        var qMatrix = Matrix<Double>(rows: stateDimension, columns: stateDimension, repeatedValue: 0.0)
        for i in 0..<3 {
            qMatrix[i, i] = dt_4_over_4
            qMatrix[i, i + 3] = dt_3_over_2
            qMatrix[i + 3, i] = dt_3_over_2
            qMatrix[i + 3, i + 3] = dt_2
        }
        self.Q = qVal * qMatrix

        // 3. Предсказание состояния
        state = Surge.mul(F, state)

        // 4. Предсказание ковариации
        P = Surge.add(Surge.mul(Surge.mul(F, P), Surge.transpose(F)), Q)
    }

    // --- Шаг Обновления ---
    mutating func update(measurement: simd_float3, measurementVisibility visibility: Float) {
        let z = Vector([Double(measurement.x), Double(measurement.y), Double(measurement.z)])
        let R_adaptive = calculateMeasurementCovariance(visibility: Double(visibility))

        let predictedMeasurement = Surge.mul(H, state)
        let y = Surge.sub(z, predictedMeasurement)

        let PHT = Surge.mul(P, Surge.transpose(H))
        let S = Surge.add(Surge.mul(H, PHT), R_adaptive)

        guard let S_inv = try? Surge.inv(S) else {
            // print("[KalmanFilter3D] Warning: Failed to invert S. Skipping update.")
            return
        }
        let K = Surge.mul(PHT, S_inv)

        let stateCorrection = Surge.mul(K, y)
        state = Surge.add(state, stateCorrection)

        if visibility < 0.4 {
            state[3] = 0.0
            state[4] = 0.0
            state[5] = 0.0
        }

        let I = Matrix<Double>.identity(size: stateDimension)
        let KH = Surge.mul(K, H)
        let I_KH = Surge.sub(I, KH)
        P = Surge.mul(I_KH, P)
    }

    // Расчет адаптивной матрицы R
    private func calculateMeasurementCovariance(visibility: Double) -> Matrix<Double> {
        let epsilon = 1e-6
        let clampedVisibility = max(visibility, epsilon)
        let factor = 1.0 / (clampedVisibility * clampedVisibility)
        let adaptiveNoise = baseMeasurementNoise * factor
        let maxNoiseFactor = 100.0
        let cappedAdaptiveNoise = min(adaptiveNoise, baseMeasurementNoise * maxNoiseFactor)
        return cappedAdaptiveNoise * Matrix<Double>.identity(size: measurementDimension)
    }

    // Отфильтрованное положение
    var filteredPosition: simd_float3 {
        return simd_float3(Float(state[0]), Float(state[1]), Float(state[2]))
    }

    // Отфильтрованная скорость
    var filteredVelocity: simd_float3 {
         return simd_float3(Float(state[3]), Float(state[4]), Float(state[5]))
    }

    /// Возвращает стандартное отклонение для оценки позиции (извлекается из диагонали P)
    var positionStandardDeviation: simd_float3 {
        // P - ковариационная матрица 6x6
        // Дисперсии для x, y, z находятся на диагонали P[0,0], P[1,1], P[2,2]
        // Стандартное отклонение = корень из дисперсии
        // Убедимся, что индексы корректны и значения не отрицательны
        let P00 = (P.rows > 0 && P.columns > 0) ? max(0, P[0,0]) : 0.0
        let P11 = (P.rows > 1 && P.columns > 1) ? max(0, P[1,1]) : 0.0
        let P22 = (P.rows > 2 && P.columns > 2) ? max(0, P[2,2]) : 0.0
        
        return simd_float3(Float(sqrt(P00)), Float(sqrt(P11)), Float(sqrt(P22)))
    }
}
