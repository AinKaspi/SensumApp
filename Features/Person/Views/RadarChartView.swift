import UIKit

class RadarChartView: UIView {

    // --- Настраиваемые свойства ---
    var labels: [String] = ["STR", "DEX", "CON", "INT", "LCK"] { 
        didSet { setNeedsDisplay(); addAxisLabels() } // Обновляем и лейблы
    }
    // Значения от 0.0 до 1.0
    var values: [CGFloat] = [0.8, 0.6, 0.7, 0.5, 0.9] { // Заглушки
        didSet { updateDataLayer() } // Обновить слой данных
    }

    var gridColor: UIColor = UIColor.gray.withAlphaComponent(0.5)
    var axisColor: UIColor = UIColor.gray.withAlphaComponent(0.8)
    var dataStrokeColor: UIColor = .systemOrange
    var dataFillColor: UIColor = UIColor.systemOrange.withAlphaComponent(0.4)
    var labelFont: UIFont = .systemFont(ofSize: 10)
    var labelColor: UIColor = .lightGray
    var dataPointColor: UIColor = .systemPurple // Цвет для точек

    private let dataLayer = CAShapeLayer()
    private let gridLayer = CAShapeLayer() // Слой для сетки и осей
    private let dataPointsLayer = CALayer() // НОВЫЙ слой для точек

    // --- Инициализация ---
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear // Фон самой View прозрачный
        layer.addSublayer(gridLayer)
        layer.addSublayer(dataLayer)
        layer.addSublayer(dataPointsLayer) // Добавляем слой точек
    }

    // --- Отрисовка ---
    override func layoutSubviews() {
        super.layoutSubviews()
        // Обновляем пути слоев при изменении размера view
        gridLayer.path = createGridPath()
        updateDataLayer()
        // Позиционируем слои
        gridLayer.frame = bounds
        dataLayer.frame = bounds
        dataPointsLayer.frame = bounds // Слой точек тоже занимает все bounds
        // Обновляем лейблы
        addAxisLabels()
    }
    
    // Рисуем сетку и оси
    private func createGridPath() -> CGPath {
        let path = UIBezierPath()
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        // Оставляем место для лейблов, берем меньшую сторону за основу радиуса
        let radius = min(bounds.width, bounds.height) / 2 * 0.75
        let numAxes = labels.count
        guard numAxes > 2 else { return path.cgPath } // Нужно хотя бы 3 оси

        // 1. Рисуем оси
        for i in 0..<numAxes {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(numAxes)) - .pi / 2 // Начинаем сверху
            let endPoint = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            path.move(to: center)
            path.addLine(to: endPoint)
        }

        // 2. Рисуем концентрические сетки (например, 3 уровня)
        let gridLevels = 3
        for level in 1...gridLevels {
            let levelRadius = radius * (CGFloat(level) / CGFloat(gridLevels))
            path.move(to: CGPoint(x: center.x + levelRadius * cos(-.pi / 2), y: center.y + levelRadius * sin(-.pi / 2))) // Начинаем сверху
            for i in 1...numAxes {
                 let angle = CGFloat(i) * (2 * .pi / CGFloat(numAxes)) - .pi / 2
                 let point = CGPoint(
                     x: center.x + levelRadius * cos(angle),
                     y: center.y + levelRadius * sin(angle)
                 )
                 path.addLine(to: point)
            }
        }

        gridLayer.strokeColor = axisColor.cgColor
        gridLayer.lineWidth = 0.5
        gridLayer.fillColor = nil // Оси и сетка не заполняются

        return path.cgPath
    }

    // Добавляем текстовые лейблы осей (ВОЗВРАЩАЕМ наружу)
    private var labelLayers: [CATextLayer] = []
    
    private func addAxisLabels() {
        labelLayers.forEach { $0.removeFromSuperlayer() }
        labelLayers.removeAll()

        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        // Радиус чуть БОЛЬШЕ радиуса сетки для позиционирования текста
        let textRadius = min(bounds.width, bounds.height) / 2 * 0.85 
        let numAxes = labels.count
        guard numAxes > 0 else { return }

        for i in 0..<numAxes {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(numAxes)) - .pi / 2
            let labelPoint = CGPoint(
                x: center.x + textRadius * cos(angle),
                y: center.y + textRadius * sin(angle)
            )

            let textLayer = CATextLayer()
            textLayer.string = labels[i]
            textLayer.font = labelFont
            textLayer.fontSize = labelFont.pointSize
            textLayer.foregroundColor = labelColor.cgColor
            textLayer.alignmentMode = .center // Теперь можно центрировать
            textLayer.contentsScale = UIScreen.main.scale

            let attributes = [NSAttributedString.Key.font: labelFont]
            let textSize = labels[i].size(withAttributes: attributes)
            
            // Позиционируем текст относительно точки на радиусе
            var textRect = CGRect(origin: .zero, size: textSize)
            // Центрируем текст по labelPoint
            textRect.origin.x = labelPoint.x - textSize.width / 2
            textRect.origin.y = labelPoint.y - textSize.height / 2

            textLayer.frame = textRect

            layer.addSublayer(textLayer)
            labelLayers.append(textLayer)
        }
    }

    // Обновляем слой данных и добавляем точки
    private func updateDataLayer() {
        let path = UIBezierPath()
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let radius = min(bounds.width, bounds.height) / 2 * 0.75
        let numAxes = labels.count
        guard numAxes > 0, numAxes == values.count else {
            dataLayer.path = nil
            dataPointsLayer.sublayers?.forEach { $0.removeFromSuperlayer() } // Очищаем точки
            return
        }
        
        var points: [CGPoint] = []
        for i in 0..<numAxes {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(numAxes)) - .pi / 2
            let valueRadius = radius * max(0, min(1, values[i]))
            let point = CGPoint(
                x: center.x + valueRadius * cos(angle),
                y: center.y + valueRadius * sin(angle)
            )
            points.append(point)
        }

        if let firstPoint = points.first {
             path.move(to: firstPoint)
             for i in 1..<points.count {
                 path.addLine(to: points[i])
             }
             path.close()
        }
        
        dataLayer.path = path.cgPath
        dataLayer.strokeColor = dataStrokeColor.cgColor
        dataLayer.fillColor = dataFillColor.cgColor
        dataLayer.lineWidth = 1.5

        // --- ДОБАВЛЯЕМ ТОЧКИ --- 
        // Удаляем старые точки перед добавлением новых
        dataPointsLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let pointSize: CGFloat = 5.0 // Размер точек
        for point in points {
            let pointLayer = CALayer()
            pointLayer.backgroundColor = dataPointColor.cgColor
            pointLayer.bounds.size = CGSize(width: pointSize, height: pointSize)
            pointLayer.cornerRadius = pointSize / 2
            pointLayer.position = point // Центрируем слой по точке данных
            dataPointsLayer.addSublayer(pointLayer)
        }
    }
} 