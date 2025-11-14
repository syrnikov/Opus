import Foundation
import Metal
import MetalKit
import simd

final class MetalCanvasRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState

    weak var viewModel: CanvasViewModel?

    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        metalView.device = device
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.clearColor = MTLClearColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
        metalView.framebufferOnly = false
        metalView.preferredFramesPerSecond = 120

        self.device = device
        self.commandQueue = commandQueue

        guard let shaderURL = Bundle.module.url(forResource: "Shaders", withExtension: "metal"),
              let shaderSource = try? String(contentsOf: shaderURL),
              let library = try? device.makeLibrary(source: shaderSource, options: nil) else {
            return nil
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "stroke_vertex")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "stroke_fragment")
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[2].format = .float4
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<Float>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<StrokeVertex>.stride
        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            return nil
        }

        super.init()
        metalView.delegate = self
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        if let background = viewModel?.backgroundColor {
            view.clearColor = MTLClearColor(
                red: Double(background.x),
                green: Double(background.y),
                blue: Double(background.z),
                alpha: Double(background.w)
            )
        }

        encoder.setRenderPipelineState(pipelineState)

        guard let viewModel else {
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            return
        }

        let viewSize = SIMD2<Float>(Float(view.bounds.width), Float(view.bounds.height))
        let transform = viewModel.transform
        let strokes = viewModel.snapshotStrokes()
        var vertices: [StrokeVertex] = []
        vertices.reserveCapacity(strokes.reduce(0) { $0 + $1.points.count * 4 })

        for stroke in strokes {
            guard let firstPoint = stroke.points.first else { continue }
            if stroke.points.count == 1 {
                appendSegment(from: firstPoint, to: firstPoint, baseSize: stroke.baseSize, color: stroke.color, transform: transform, viewSize: viewSize, into: &vertices)
            } else {
                var previousPoint = firstPoint
                for point in stroke.points.dropFirst() {
                    appendSegment(from: previousPoint, to: point, baseSize: stroke.baseSize, color: stroke.color, transform: transform, viewSize: viewSize, into: &vertices)
                    previousPoint = point
                }
            }
        }

        if !vertices.isEmpty {
            let dataSize = vertices.count * MemoryLayout<StrokeVertex>.stride
            let vertexBuffer = device.makeBuffer(bytes: vertices, length: dataSize, options: .storageModeShared)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

    private func appendSegment(from start: StrokePoint, to end: StrokePoint, baseSize: Float, color: SIMD4<Float>, transform: CanvasTransform, viewSize: SIMD2<Float>, into buffer: inout [StrokeVertex]) {
        let vector = end.position - start.position
        let distance = simd_length(vector)
        let steps = max(1, Int(distance / 1.0))
        for step in 0...steps {
            let t = steps == 0 ? 0 : Float(step) / Float(steps)
            let canvasPosition = start.position + vector * t
            let pressure = start.pressure + (end.pressure - start.pressure) * t
            let viewPoint = projectToView(canvas: canvasPosition, transform: transform, viewSize: viewSize)
            let clipPosition = convertToClipSpace(viewPoint: viewPoint, viewSize: viewSize)
            let size = max(1.0, (baseSize * pressure) * Float(transform.scale))
            buffer.append(StrokeVertex(position: clipPosition, size: size, color: color))
        }
    }

    private func projectToView(canvas: SIMD2<Float>, transform: CanvasTransform, viewSize: SIMD2<Float>) -> SIMD2<Float> {
        let width = viewSize.x
        let height = viewSize.y
        let translation = transform.translation
        let scale = Float(transform.scale)
        let centered = canvas - SIMD2<Float>(width / 2.0, height / 2.0)
        let translated = (centered + translation) * scale
        let viewPoint = translated + SIMD2<Float>(width / 2.0, height / 2.0)
        return viewPoint
    }

    private func convertToClipSpace(viewPoint: SIMD2<Float>, viewSize: SIMD2<Float>) -> SIMD2<Float> {
        let normalizedX = (viewPoint.x / viewSize.x) * 2.0 - 1.0
        let normalizedY = ((viewSize.y - viewPoint.y) / viewSize.y) * 2.0 - 1.0
        return SIMD2<Float>(normalizedX, normalizedY)
    }
}

private struct StrokeVertex {
    var position: SIMD2<Float>
    var size: Float
    var color: SIMD4<Float>
}
