import Foundation
import QuartzCore
import SwiftUI
import simd

final class CanvasViewModel: ObservableObject {
    @Published private(set) var strokes: [Stroke] = []
    @Published private(set) var redoStack: [Stroke] = []
    @Published var transform: CanvasTransform = .identity
    @Published var canvasSize: CGSize = CGSize(width: 2048, height: 2048)
    @Published var activeTool: Tool = .brush
    let backgroundColor = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)

    private var currentStroke: Stroke?
    private var shouldAutoFitCanvas = true
    private var lastAutoFitViewSize: CGSize?

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
        markViewAsManuallyAdjusted()
        transform.scale = max(0.1, min(scale, 8.0))
    }

    func setTranslation(_ translation: CGPoint) {
        markViewAsManuallyAdjusted()
        transform.translation = SIMD2<Float>(Float(translation.x), Float(translation.y))
    }

    func translate(by delta: CGSize) {
        markViewAsManuallyAdjusted()
        transform.translation += SIMD2<Float>(Float(delta.width), Float(delta.height))
    }

    func resetView() {
        transform = .identity
        shouldAutoFitCanvas = true
        lastAutoFitViewSize = nil
    }

    func updateCanvasSize(width: CGFloat? = nil, height: CGFloat? = nil) {
        let newWidth = max(1, width ?? canvasSize.width)
        let newHeight = max(1, height ?? canvasSize.height)
        if newWidth != canvasSize.width || newHeight != canvasSize.height {
            canvasSize = CGSize(width: newWidth, height: newHeight)
            resetView()
        }
    }

    func updateCanvasSize(width: CGFloat? = nil, height: CGFloat? = nil) {
        let newWidth = max(1, width ?? canvasSize.width)
        let newHeight = max(1, height ?? canvasSize.height)
        if newWidth != canvasSize.width || newHeight != canvasSize.height {
            canvasSize = CGSize(width: newWidth, height: newHeight)
            resetView()
        }
    }

    func prepareForNewCanvas() {
        strokes.removeAll()
        redoStack.removeAll()
        currentStroke = nil
        resetView()
    }

    func fitCanvasToViewIfNeeded(viewSize: CGSize) {
        guard shouldAutoFitCanvas else { return }
        guard viewSize.width > 0, viewSize.height > 0 else { return }

        if let lastSize = lastAutoFitViewSize,
           abs(lastSize.width - viewSize.width) < 0.5,
           abs(lastSize.height - viewSize.height) < 0.5 {
            return
        }

        let widthRatio = viewSize.width / max(canvasSize.width, 1)
        let heightRatio = viewSize.height / max(canvasSize.height, 1)
        let targetScale = min(widthRatio, heightRatio)
        guard targetScale.isFinite, targetScale > 0 else { return }

        let clampedScale = min(1.0, max(0.1, min(targetScale, 8.0)))
        let needsScaleUpdate = abs(transform.scale - clampedScale) > 0.0001
        let needsTranslationUpdate = simd_length(transform.translation) > 0.0001

        lastAutoFitViewSize = viewSize

        if needsScaleUpdate || needsTranslationUpdate {
            transform.scale = clampedScale
            transform.translation = .zero
        }
    }

    func canvasPoint(from viewPoint: CGPoint, in viewSize: CGSize) -> CGPoint {
        let scale = transform.scale
        let viewCenter = CGPoint(x: viewSize.width / 2.0, y: viewSize.height / 2.0)
        let canvasCenter = CGPoint(x: canvasSize.width / 2.0, y: canvasSize.height / 2.0)

        let offsetX = (viewPoint.x - viewCenter.x - CGFloat(transform.translation.x)) / scale
        let offsetY = (viewPoint.y - viewCenter.y - CGFloat(transform.translation.y)) / scale
        return CGPoint(x: offsetX + canvasCenter.x, y: offsetY + canvasCenter.y)
    }

    private func markViewAsManuallyAdjusted() {
        shouldAutoFitCanvas = false
        lastAutoFitViewSize = nil
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
