import MetalKit
import SwiftUI

struct MetalCanvasView: NSViewRepresentable {
    @EnvironmentObject private var canvasViewModel: CanvasViewModel
    @EnvironmentObject private var brushSettings: BrushSettings

    func makeCoordinator() -> Coordinator {
        Coordinator(canvasViewModel: canvasViewModel, brushSettings: brushSettings)
    }

    func makeNSView(context: Context) -> CanvasMTKView {
        let view = CanvasMTKView()
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.interactionDelegate = context.coordinator
        view.toolProvider = { context.coordinator.canvasViewModel.activeTool }
        context.coordinator.configure(view: view)
        return view
    }

    func updateNSView(_ nsView: CanvasMTKView, context: Context) {
        context.coordinator.canvasViewModel = canvasViewModel
        context.coordinator.brushSettings = brushSettings
        nsView.toolProvider = { canvasViewModel.activeTool }
        context.coordinator.syncRenderer()
    }

    final class Coordinator: NSObject, CanvasInteractionDelegate {
        var canvasViewModel: CanvasViewModel
        var brushSettings: BrushSettings
        private weak var renderer: MetalCanvasRenderer?

        init(canvasViewModel: CanvasViewModel, brushSettings: BrushSettings) {
            self.canvasViewModel = canvasViewModel
            self.brushSettings = brushSettings
        }

        func configure(view: CanvasMTKView) {
            if let renderer = MetalCanvasRenderer(metalView: view) {
                renderer.viewModel = canvasViewModel
                view.renderer = renderer
                self.renderer = renderer
                DispatchQueue.main.async { [weak view, weak canvasViewModel] in
                    guard let view = view, let canvasViewModel = canvasViewModel else { return }
                    canvasViewModel.fitCanvasToViewIfNeeded(viewSize: view.bounds.size)
                }
            }
        }

        func syncRenderer() {
            renderer?.viewModel = canvasViewModel
        }

        func beginStroke(at viewPoint: CGPoint, pressure: CGFloat, in view: CanvasMTKView) {
            guard canvasViewModel.activeTool == .brush || canvasViewModel.activeTool == .eraser else { return }
            let canvasPoint = canvasViewModel.canvasPoint(from: viewPoint, in: view.bounds.size)
            canvasViewModel.beginStroke(at: canvasPoint, pressure: pressure, brush: brushSettings)
        }

        func continueStroke(at viewPoint: CGPoint, pressure: CGFloat, in view: CanvasMTKView) {
            guard canvasViewModel.activeTool == .brush || canvasViewModel.activeTool == .eraser else { return }
            let canvasPoint = canvasViewModel.canvasPoint(from: viewPoint, in: view.bounds.size)
            canvasViewModel.continueStroke(at: canvasPoint, pressure: pressure, brush: brushSettings)
            renderer?.viewModel = canvasViewModel
        }

        func endStroke(in view: CanvasMTKView) {
            canvasViewModel.endStroke()
            renderer?.viewModel = canvasViewModel
        }

        func cancelStroke() {
            canvasViewModel.cancelStroke()
        }

        func translate(by delta: CGSize) {
            canvasViewModel.translate(by: delta)
        }

        func magnify(by scaleDelta: CGFloat) {
            let currentScale = canvasViewModel.transform.scale
            canvasViewModel.setScale(currentScale * scaleDelta)
        }

        func setRendererNeedsDisplay() {
            renderer?.viewModel = canvasViewModel
        }

        func undo() {
            canvasViewModel.undo()
            renderer?.viewModel = canvasViewModel
        }

        func redo() {
            canvasViewModel.redo()
            renderer?.viewModel = canvasViewModel
        }
    }
}

protocol CanvasInteractionDelegate: AnyObject {
    func beginStroke(at viewPoint: CGPoint, pressure: CGFloat, in view: CanvasMTKView)
    func continueStroke(at viewPoint: CGPoint, pressure: CGFloat, in view: CanvasMTKView)
    func endStroke(in view: CanvasMTKView)
    func cancelStroke()
    func translate(by delta: CGSize)
    func magnify(by scaleDelta: CGFloat)
    func setRendererNeedsDisplay()
    func undo()
    func redo()
}

final class CanvasMTKView: MTKView {
    weak var interactionDelegate: CanvasInteractionDelegate?
    var toolProvider: (() -> Tool)?
    fileprivate var renderer: MetalCanvasRenderer?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let location = convert(event.locationInWindow, from: nil)
        interactionDelegate?.beginStroke(at: location, pressure: pressure(from: event), in: self)
    }

    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        interactionDelegate?.continueStroke(at: location, pressure: pressure(from: event), in: self)
    }

    override func mouseUp(with event: NSEvent) {
        interactionDelegate?.endStroke(in: self)
    }

    override func scrollWheel(with event: NSEvent) {
        let isTrackpadGesture = event.hasPreciseScrollingDeltas || event.phase != .none || event.momentumPhase != .none
        if isTrackpadGesture || toolProvider?() == .hand {
            let delta = CGSize(width: event.scrollingDeltaX, height: -event.scrollingDeltaY)
            interactionDelegate?.translate(by: delta)
            interactionDelegate?.setRendererNeedsDisplay()
        } else {
            super.scrollWheel(with: event)
        }
    }

    override func magnify(with event: NSEvent) {
        let delta = 1.0 + event.magnification
        interactionDelegate?.magnify(by: delta)
        interactionDelegate?.setRendererNeedsDisplay()
    }

    override func keyDown(with event: NSEvent) {
        guard let characters = event.charactersIgnoringModifiers else {
            super.keyDown(with: event)
            return
        }
        let command = event.modifierFlags.contains(.command)
        switch (characters, command, event.modifierFlags.contains(.shift)) {
        case ("z", true, false):
            interactionDelegate?.undo()
        case ("Z", true, true), ("z", true, true):
            interactionDelegate?.redo()
        default:
            super.keyDown(with: event)
        }
    }

    private func pressure(from event: NSEvent) -> CGFloat {
        event.pressure > 0 ? event.pressure : 1.0
    }
}
