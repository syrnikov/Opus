import SwiftUI

struct InspectorView: View {
    @EnvironmentObject private var canvasViewModel: CanvasViewModel
    @EnvironmentObject private var brushSettings: BrushSettings

    @State private var isCanvasExpanded = true
    @State private var isLayersExpanded = true
    @State private var isBrushExpanded = true
    @State private var isColorExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    InspectorSection(title: "Canvas", isExpanded: $isCanvasExpanded) {
                        CanvasSettingsView()
                    }

                    InspectorSection(title: "Layers", isExpanded: $isLayersExpanded) {
                        LayerStackView()
                    }

                    InspectorSection(title: "Brush", isExpanded: $isBrushExpanded) {
                        BrushSettingsView()
                    }

                    InspectorSection(title: "Color", isExpanded: $isColorExpanded) {
                        VStack(alignment: .leading, spacing: 12) {
                            ColorPicker("Active Color", selection: $brushSettings.color)
                            ColorWheelPlaceholder()
                        }
                    }
                }
                .padding(16)
            }

            Divider()

            HStack {
                Button("Undo") { canvasViewModel.undo() }
                    .disabled(canvasViewModel.snapshotStrokes().isEmpty)
                Button("Redo") { canvasViewModel.redo() }
                    .disabled(canvasViewModel.redoStack.isEmpty)
                Spacer()
                Button("Reset View") { canvasViewModel.resetView() }
            }
            .padding([.horizontal, .bottom], 16)
        }
    }
}

private struct InspectorSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder var content: Content

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content
                .padding(.top, 8)
        } label: {
            Text(title.uppercased())
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        }
        .disclosureGroupStyle(.automatic)
    }
}

private struct BrushSettingsView: View {
    @EnvironmentObject private var brushSettings: BrushSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledSlider(label: "Size", value: $brushSettings.size, range: 1...64, format: "%.0f px")
            LabeledSlider(label: "Opacity", value: $brushSettings.opacity, range: 0.1...1, format: "%.0f%%", multiplier: 100)
            LabeledSlider(label: "Flow", value: $brushSettings.flow, range: 0.1...1, format: "%.0f%%", multiplier: 100)
            LabeledSlider(label: "Hardness", value: $brushSettings.hardness, range: 0...1, format: "%.0f%%", multiplier: 100)
            // TODO: Introduce shape dynamics, spacing, texture, and blending controls.
        }
    }
}

private struct LabeledSlider: View {
    let label: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    var format: String = "%.0f"
    var multiplier: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value * multiplier))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: Binding(get: { Double(value) }, set: { value = CGFloat($0) }), in: Double(range.lowerBound)...Double(range.upperBound))
        }
    }
}

private struct LayerStackView: View {
    @EnvironmentObject private var canvasViewModel: CanvasViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Background")
                .font(.body)
            Text("Layer 1")
                .font(.body)
                .foregroundStyle(.primary)
            Text("Add layers coming soon")
                .font(.caption)
                .foregroundStyle(.secondary)
            // TODO: Implement a full layer stack with blend modes, visibility toggles, and reordering.
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ColorWheelPlaceholder: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red]), center: .center), lineWidth: 20)
                .frame(height: 180)
            Circle()
                .fill(.thinMaterial)
                .frame(height: 120)
            Text("Coolorus-style wheel coming soon")
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(16)
        }
        .frame(maxWidth: .infinity)
        // TODO: Replace placeholder with full HSV color wheel and harmonies.
    }
}

private struct CanvasSettingsView: View {
    @EnvironmentObject private var canvasViewModel: CanvasViewModel

    private static let dimensionFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimum = 1
        return formatter
    }()

    private var widthBinding: Binding<Double> {
        Binding(
            get: { Double(canvasViewModel.canvasSize.width) },
            set: { canvasViewModel.updateCanvasSize(width: CGFloat(max(1, $0))) }
        )
    }

    private var heightBinding: Binding<Double> {
        Binding(
            get: { Double(canvasViewModel.canvasSize.height) },
            set: { canvasViewModel.updateCanvasSize(height: CGFloat(max(1, $0))) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DimensionField(label: "Width", value: widthBinding)
            DimensionField(label: "Height", value: heightBinding)
            Button("Center Canvas") {
                canvasViewModel.resetView()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private struct DimensionField: View {
        let label: String
        @Binding var value: Double

        var body: some View {
            HStack {
                Text(label)
                Spacer()
                TextField(label, value: $value, formatter: CanvasSettingsView.dimensionFormatter)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .labelsHidden()
            }
        }
    }
}
