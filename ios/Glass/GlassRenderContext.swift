import Metal
import simd

struct BlurParams {
    var uvRect: SIMD4<Float>
    var texelStep: SIMD2<Float>
    var radius: Float
    var pad0: Float = 0
}

struct GlassParams {
    var cornerRadii: SIMD4<Float>
    var tintColor: SIMD4<Float>
    var frostColor: SIMD4<Float>
    var sourceRect: SIMD4<Float>
    var viewSize: SIMD2<Float>
    var shapeSize: SIMD2<Float>
    var refractionScale: SIMD2<Float>
    var refractionAmount: Float
    var depthEffect: Float
    var profilePower: Float
    var profileBias: Float
    var dispersionHeight: Float
    var dispersionAmount: Float
    var highlightIntensity: Float
    var highlightAngle: Float
    var lightIntensity: Float
    var glassOpacity: Float
    var saturation: Float
    var noiseAmount: Float
    var pad0: SIMD2<Float> = .zero
}

final class GlassRenderContext {

    static let shared: GlassRenderContext? = GlassRenderContext()

    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let blurPipeline: MTLRenderPipelineState
    let glassPipeline: MTLRenderPipelineState

    let quadBuffer: MTLBuffer

    let linearTextureAlignment: Int

    private init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = Self.loadShaderLibrary(device: device)
        else { return nil }

        let quad: [SIMD4<Float>] = [
            SIMD4(-1, -1, 0, 1),
            SIMD4( 1, -1, 1, 1),
            SIMD4(-1,  1, 0, 0),
            SIMD4( 1,  1, 1, 0),
        ]
        guard let quadBuffer = device.makeBuffer(
            bytes: quad,
            length: MemoryLayout<SIMD4<Float>>.stride * quad.count,
            options: .storageModeShared
        ) else { return nil }

        func pipeline(fragment: String) -> MTLRenderPipelineState? {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.label = fragment
            descriptor.vertexFunction = library.makeFunction(name: "liquid_glass_vertex")
            descriptor.fragmentFunction = library.makeFunction(name: fragment)
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

            return try? device.makeRenderPipelineState(descriptor: descriptor)
        }

        guard let blurPipeline = pipeline(fragment: "blurFragment"),
              let glassPipeline = pipeline(fragment: "glassFragment")
        else { return nil }

        self.device = device
        self.commandQueue = commandQueue
        self.blurPipeline = blurPipeline
        self.glassPipeline = glassPipeline
        self.quadBuffer = quadBuffer
        self.linearTextureAlignment = max(
            device.minimumLinearTextureAlignment(for: .bgra8Unorm),
            MemoryLayout<UInt32>.alignment
        )

        commandQueue.label = "ExpoLiquidGlass"
    }

    private static func loadShaderLibrary(device: MTLDevice) -> MTLLibrary? {
        let base = Bundle(for: GlassRenderContext.self)

        if let url = base.url(forResource: "ExpoLiquidGlassShaders", withExtension: "bundle"),
           let nested = Bundle(url: url),
           let library = try? device.makeDefaultLibrary(bundle: nested) {
            return library
        }

        return try? device.makeDefaultLibrary(bundle: base)
    }

    func makeRenderTarget(width: Int, height: Int, label: String) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: max(width, 1),
            height: max(height, 1),
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        let texture = device.makeTexture(descriptor: descriptor)
        texture?.label = label
        return texture
    }

    func encodeQuad(
        into commandBuffer: MTLCommandBuffer,
        descriptor: MTLRenderPassDescriptor,
        pipeline: MTLRenderPipelineState,
        source: MTLTexture,
        params: UnsafeRawPointer,
        length: Int,
        label: String
    ) {
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        encoder.label = label
        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(quadBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(source, index: 0)
        encoder.setFragmentBytes(params, length: length, index: 1)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
    }

    static func offscreenPass(target: MTLTexture) -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = target
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        return descriptor
    }
}
