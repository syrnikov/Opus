import Foundation
import QuartzCore
import SwiftUI
import simd

final class CanvasViewModel: ObservableObject {
    @Published private(set) var strokes: [Stroke] = []
    @Published private(set) var redoStack: [Stroke] = []
    @Published var transform: CanvasTransform = .identity
    @Published var activeTool: Tool = .brush
    let backgroundColor = SIMD4<Float>(0.96, 0.96, 0.98, 1.0)

    private var currentStroke: Stroke?

    func beginStroke(at location: CGPoint, pressure: CGFloat, brush: BrushSettings) {
        guard activeTool == .brush || activeTool == .eraser else { return }
        let color: SIMD4<Float> = activeTool == .eraser ? backgroundColor : brush.simdColor
        let stroke = Stroke(
            id: UUID(),
            points: [StrokePoint(position: SIMD2<Float>(Float(location.x), Float(location.y)), pressure: Float(pressure), timestamp: CACurrentMediaTime())],
            color: color,
            baseSize: Float(brush.size)
        )
        currentStroke = stroke
        redoStack.removeAll()
    }

    func continueStroke(at location: CGPoint, pressure: CGFloat, brush: BrushSettings) {
        guard var stroke = currentStroke else { return }
        let point = StrokePoint(position: SIMD2<Float>(Float(location.x), Float(location.y)), pressure: Float(pressure), timestamp: CACurrentMediaTime())
        if let lastPoint = stroke.points.last {
            let delta = simd_length(lastPoint.position - point.position)
            if delta < 0.5 { return }
        }
        stroke.points.append(point)
        currentStroke = stroke
    }

    func endStroke() {
        guard let stroke = currentStroke else { return }
        strokes.append(stroke)
        currentStroke = nil
    }

    func snapshotStrokes() -> [Stroke] {
        if let currentStroke {
            return strokes + [currentStroke]
        }
        return strokes
    }

    func cancelStroke() {
        currentStroke = nil
    }

    func undo() {
        guard let stroke = strokes.popLast() else { return }
        redoStack.append(stroke)
    }

    func redo() {
        guard let stroke = redoStack.popLast() else { return }
        strokes.append(stroke)
    }

    func setScale(_ scale: CGFloat) {
        transform.scale = max(0.1, min(scale, 8.0))
    }

    func setTranslation(_ translation: CGPoint) {
        transform.translation = SIMD2<Float>(Float(translation.x), Float(translation.y))
    }

    func translate(by delta: CGSize) {
        transform.translation += SIMD2<Float>(Float(delta.width), Float(delta.height))
    }

    func resetView() {
        transform = .identity
    }

    func canvasPoint(from viewPoint: CGPoint, in viewSize: CGSize) -> CGPoint {
        let scale = transform.scale
        let translatedX = (viewPoint.x - viewSize.width / 2.0) / scale - CGFloat(transform.translation.x) + viewSize.width / 2.0
        let translatedY = (viewPoint.y - viewSize.height / 2.0) / scale - CGFloat(transform.translation.y) + viewSize.height / 2.0
        return CGPoint(x: translatedX, y: translatedY)
    }
}

struct CanvasTransform {
    var scale: CGFloat
    var translation: SIMD2<Float>

    static let identity = CanvasTransform(scale: 1.0, translation: .zero)
}

enum Tool: String, CaseIterable, Identifiable {
    case brush
    case eraser
    case colorPicker
    case hand

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .brush: return "pencil.tip"
        case .eraser: return "eraser"
        case .colorPicker: return "eyedropper"
        case .hand: return "hand.draw"
        }
    }

    var description: String {
        switch self {
        case .brush: return "Brush"
        case .eraser: return "Eraser"
        case .colorPicker: return "Color Pick"
        case .hand: return "Pan"
        }
    }
}

struct Stroke: Identifiable {
    let id: UUID
    var points: [StrokePoint]
    var color: SIMD4<Float>
    var baseSize: Float
}

struct StrokePoint {
    var position: SIMD2<Float>
    var pressure: Float
    var timestamp: CFTimeInterval
}
