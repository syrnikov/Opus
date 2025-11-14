import SwiftUI

@main
struct OpusDrawingApp: App {
    @StateObject private var canvasViewModel = CanvasViewModel()
    @StateObject private var brushSettings = BrushSettings()

    var body: some Scene {
        WindowGroup("Opus Studio") {
            ContentView()
                .environmentObject(canvasViewModel)
                .environmentObject(brushSettings)
        }
        .defaultSize(width: 1280, height: 800)
        .commands {
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
}
