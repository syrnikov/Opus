import SwiftUI

@main
struct OpusDrawingApp: App {
    @StateObject private var canvasViewModel = CanvasViewModel()
    @StateObject private var brushSettings = BrushSettings()
    @State private var isShowingCanvas = false

    var body: some Scene {
        WindowGroup("Opus Studio") {
            RootView(isShowingCanvas: $isShowingCanvas, onCreateCanvas: openNewCanvas)
                .environmentObject(canvasViewModel)
                .environmentObject(brushSettings)
        }
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Canvas", action: openNewCanvas)
                    .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { canvasViewModel.undo() }
                    .keyboardShortcut("z", modifiers: [.command])
                    .disabled(canvasViewModel.snapshotStrokes().isEmpty)
                Button("Redo") { canvasViewModel.redo() }
                    .keyboardShortcut("Z", modifiers: [.command, .shift])
                    .disabled(canvasViewModel.redoStack.isEmpty)
            }

            CommandMenu("Canvas") {
                Button("Reset View") { canvasViewModel.resetView() }
                    .keyboardShortcut("0", modifiers: [.command])
            }

            CommandMenu("Brush") {
                Slider(value: Binding(get: { Double(brushSettings.size) }, set: { brushSettings.size = CGFloat($0) }), in: 1...128) {
                    Text("Size")
                }
                Slider(value: Binding(get: { Double(brushSettings.opacity) }, set: { brushSettings.opacity = CGFloat($0) }), in: 0.1...1) {
                    Text("Opacity")
                }
                // TODO: Offer brush preset picker within the command menu.
            }
        }
    }

    private func openNewCanvas() {
        canvasViewModel.prepareForNewCanvas()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            isShowingCanvas = true
        }
    }
}
