import Metal
import QuartzCore

final class GlassSurfaceCore {

    let layer: CAMetalLayer

    var ping: MTLTexture?
    var pong: MTLTexture?
    var blurPixelSize: (width: Int, height: Int) = (0, 0)
    var appliedDrawableSize: CGSize = .zero

    init(layer: CAMetalLayer) {
        self.layer = layer
    }

    func releaseBlurTextures() {
        ping = nil
        pong = nil
        blurPixelSize = (0, 0)
    }
}

struct GlassDrawRequest {
    let surface: GlassSurfaceCore
    let backdrop: MTLTexture
    let glass: GlassParams
    let uvRect: SIMD4<Float>
    let drawableSize: CGSize
    let needsBlur: Bool
    let blurRadiusTexels: Float
    let blurPixelSize: (width: Int, height: Int)
}

final class GlassRenderer {

    static let shared = GlassRenderer()

    private let queue = DispatchQueue(
        label: "expo.liquidglass.render",
        qos: .userInteractive
    )

    private let admission = DispatchSemaphore(value: 2)

    private init() {}

    @discardableResult
    func submit(_ requests: [GlassDrawRequest]) -> Bool {
        guard !requests.isEmpty else { return true }
        guard admission.wait(timeout: .now()) == .success else { return false }

        queue.async { [admission] in
            self.encode(requests)
            admission.signal()
        }
        return true
    }

    private func encode(_ requests: [GlassDrawRequest]) {
        guard let context = GlassRenderContext.shared,
              let commandBuffer = context.commandQueue.makeCommandBuffer()
        else { return }

        commandBuffer.label = "GlassFrame"

        var presented = false
        for request in requests {
            if encode(request, into: commandBuffer, context: context) {
                presented = true
            }
        }

        guard presented else { return }
        commandBuffer.commit()
    }

    private func encode(
        _ request: GlassDrawRequest,
        into commandBuffer: MTLCommandBuffer,
        context: GlassRenderContext
    ) -> Bool {
        let surface = request.surface

        if surface.appliedDrawableSize != request.drawableSize {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            surface.layer.drawableSize = request.drawableSize
            CATransaction.commit()
            surface.appliedDrawableSize = request.drawableSize
            surface.releaseBlurTextures()
        }

        var source = request.backdrop
        var glass = request.glass

        if request.needsBlur {
            ensureBlurTextures(for: surface, size: request.blurPixelSize, context: context)
            guard let ping = surface.ping, let pong = surface.pong else { return false }

            var horizontal = BlurParams(
                uvRect: request.uvRect,
                texelStep: SIMD2<Float>(1.0 / Float(max(request.backdrop.width, 1)), 0),
                radius: request.blurRadiusTexels
            )
            context.encodeQuad(
                into: commandBuffer,
                descriptor: GlassRenderContext.offscreenPass(target: ping),
                pipeline: context.blurPipeline,
                source: request.backdrop,
                params: &horizontal,
                length: MemoryLayout<BlurParams>.stride,
                label: "GlassBlurH"
            )

            var vertical = BlurParams(
                uvRect: SIMD4<Float>(0, 0, 1, 1),
                texelStep: SIMD2<Float>(0, 1.0 / Float(max(ping.height, 1))),
                radius: request.blurRadiusTexels
            )
            context.encodeQuad(
                into: commandBuffer,
                descriptor: GlassRenderContext.offscreenPass(target: pong),
                pipeline: context.blurPipeline,
                source: ping,
                params: &vertical,
                length: MemoryLayout<BlurParams>.stride,
                label: "GlassBlurV"
            )

            source = pong
        } else {

            surface.releaseBlurTextures()
        }

        guard let drawable = surface.layer.nextDrawable() else { return false }

        let finalPass = MTLRenderPassDescriptor()
        finalPass.colorAttachments[0].texture = drawable.texture
        finalPass.colorAttachments[0].loadAction = .clear
        finalPass.colorAttachments[0].storeAction = .store
        finalPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)

        context.encodeQuad(
            into: commandBuffer,
            descriptor: finalPass,
            pipeline: context.glassPipeline,
            source: source,
            params: &glass,
            length: MemoryLayout<GlassParams>.stride,
            label: "GlassComposite"
        )

        commandBuffer.present(drawable)
        return true
    }

    private func ensureBlurTextures(
        for surface: GlassSurfaceCore,
        size: (width: Int, height: Int),
        context: GlassRenderContext
    ) {
        guard surface.blurPixelSize != size || surface.ping == nil || surface.pong == nil else {
            return
        }
        surface.ping = context.makeRenderTarget(width: size.width, height: size.height, label: "GlassBlurPing")
        surface.pong = context.makeRenderTarget(width: size.width, height: size.height, label: "GlassBlurPong")
        surface.blurPixelSize = size
    }
}
