import SwiftUI

struct ToolColumnView: View {
    @EnvironmentObject private var canvasViewModel: CanvasViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 24)
            ForEach(Tool.allCases) { tool in
                Button {
                    canvasViewModel.activeTool = tool
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tool.systemImage)
                            .font(.system(size: 20, weight: .medium))
                        Text(tool.description)
                            .font(.caption2)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(canvasViewModel.activeTool == tool ? Color.accentColor.opacity(0.2) : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .help(tool.description)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}
