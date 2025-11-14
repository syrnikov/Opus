import SwiftUI

struct RootView: View {
    @EnvironmentObject private var canvasViewModel: CanvasViewModel
    @EnvironmentObject private var brushSettings: BrushSettings
    @Binding var isShowingCanvas: Bool
    var onCreateCanvas: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if isShowingCanvas {
                    ContentView()
                        .environmentObject(canvasViewModel)
                        .environmentObject(brushSettings)
                        .toolbar {
                            ToolbarItem(placement: .navigation) {
                                Button {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                        isShowingCanvas = false
                                    }
                                } label: {
                                    Label("Home", systemImage: "rectangle.grid.2x2")
                                }
                                .help("Return to the home gallery")
                            }
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    onCreateCanvas()
                                } label: {
                                    Label("New Canvas", systemImage: "plus")
                                }
                                .keyboardShortcut("n", modifiers: [.command])
                                .help("Start a fresh canvas")
                            }
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    HomeScreenView(onCreateCanvas: {
                        onCreateCanvas()
                    })
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isShowingCanvas)
        }
    }
}
