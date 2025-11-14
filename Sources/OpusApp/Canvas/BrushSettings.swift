import SwiftUI
#if os(macOS)
import AppKit
#endif
import simd

final class BrushSettings: ObservableObject {
    @Published var size: CGFloat = 12
    @Published var opacity: CGFloat = 0.85
    @Published var flow: CGFloat = 0.9
    @Published var hardness: CGFloat = 0.6
    @Published var color: Color = .blue

    var simdColor: SIMD4<Float> {
        #if os(macOS)
        let nsColor: NSColor
        if let cgColor = color.cgColor, let converted = NSColor(cgColor: cgColor) {
            nsColor = converted
        } else {
            nsColor = .systemBlue
        }
        return SIMD4<Float>(
            Float(nsColor.redComponent),
            Float(nsColor.greenComponent),
            Float(nsColor.blueComponent),
            Float(nsColor.alphaComponent * Double(opacity))
        )
        #else
        return SIMD4<Float>(0, 0, 0, 1)
        #endif
    }

    // TODO: Support brush presets, texture maps, and pressure curves.
}
