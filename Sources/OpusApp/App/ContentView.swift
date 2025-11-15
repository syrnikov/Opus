import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var canvasViewModel: CanvasViewModel
    @EnvironmentObject private var brushSettings: BrushSettings

    var body: some View {
        HStack(spacing: 0) {
            ToolColumnView()
                .frame(width: 72)
                .background(.regularMaterial)
                .environmentObject(canvasViewModel)
                .environmentObject(brushSettings)

            MetalCanvasView()
                .environmentObject(canvasViewModel)
                .environmentObject(brushSettings)
                .background(Color.white)
                .overlay(alignment: .topLeading) {
                    CanvasHUDView()
                        .padding(12)
                }

            InspectorView()
                .frame(width: 320)
                .environmentObject(canvasViewModel)
                .environmentObject(brushSettings)
                .background(.ultraThickMaterial)
        }
        .toolbarRemind()
    }
}

private extension View {
    func toolbarRemind() -> some View {
        self
            .navigationTitle("Opus Studio")
            .toolbarRole(.editor)
    }
}

struct CanvasHUDView: View {
    @EnvironmentObject private var canvasViewModel: CanvasViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Scale: \(String(format: "%.1f", Double(canvasViewModel.transform.scale * 100)))%", systemImage: "magnifyingglass")
            Label("Offset: x=\(Int(canvasViewModel.transform.translation.x)), y=\(Int(canvasViewModel.transform.translation.y))", systemImage: "arrow.up.left.and.down.right")
            Label("Canvas: \(Int(canvasViewModel.canvasSize.width)) × \(Int(canvasViewModel.canvasSize.height)) px", systemImage: "ruler")
        }
        .font(.footnote)
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
