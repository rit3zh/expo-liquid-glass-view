import Metal
import UIKit

final class BackdropCapturer {

    static let shared = BackdropCapturer()

    private(set) var texture: MTLTexture?

    private(set) var capturedOrigin: CGPoint = .zero

    private(set) var textureSizePoints: CGSize = .zero

    private(set) var textureScale: CGFloat = Tuning.fallbackCaptureScale

    private var requestedScale: CGFloat = Tuning.fallbackCaptureScale

    private enum Tuning {

        static let fallbackCaptureScale: CGFloat = 2.0

        static let maxCapturePixels: CGFloat = 4_500_000

        static let dutyCycle: Double = 0.30

        static let maxStride = 3

        static let strideHysteresisFrames = 45

        static let staleCapturesBeforeIdle = 4
        static let idleStride = 4

        static let digestStride = 97

        static let emptyCapturesBeforeSwitch = 3

        static let costSmoothing: Double = 0.2

        static let shrinkDelay: CFTimeInterval = 1.0

        static let allocationBucket = 64

        static let movementMargin: CGFloat = 220

        static let movementMemory: CFTimeInterval = 0.4
    }

    private enum Debug {
        static let enabled =
            ProcessInfo.processInfo.environment["EXPO_LIQUID_GLASS_DEBUG"] == "1"
    }

    private var debugCaptures = 0
    private var debugTotalCost: Double = 0
    private var debugWindowStart: CFTimeInterval = 0

    private func recordDebug(cost: Double, region: CGRect, now: CFTimeInterval) {
        guard Debug.enabled else { return }
        debugCaptures += 1
        debugTotalCost += cost

        if debugWindowStart == 0 { debugWindowStart = now }
        let elapsed = now - debugWindowStart
        guard elapsed >= 1.0 else { return }

        let mean = debugTotalCost / Double(debugCaptures) * 1000
        print(String(
            format: "[LiquidGlass] %.0f cap/s  %.2fms each (%.0f%% of a 60Hz frame)  "
                + "stride %d  scale %.2f  region %.0fx%.0f  %dk px  path %@",
            Double(debugCaptures) / elapsed, mean, mean / 16.67 * 100,
            strideFrames, Double(textureScale),
            Double(region.width), Double(region.height), capturedPixelCount / 1000,
            slots.first?.uploadSource == nil ? "zero-copy" : "upload"
        ))

        debugCaptures = 0
        debugTotalCost = 0
        debugWindowStart = now
    }

    private var captureCost: Double = 0

    private var strideFrames = 1
    private var candidateStride = 1
    private var candidateStrideAge = 0
    private var frameCounter = 0

    private var capturedPixelCount: Int = 0

    private var lastDigest: UInt64 = 0
    private var staleCaptures = 0

    private enum Strategy {
        case layerRender
        case compositedDraw
    }

    private var strategy: Strategy = .layerRender

    private var emptyCaptures = 0

    private var lastRegion: CGRect = .null

    private var capturedRegion: CGRect = .null

    private var lastMovementTime: CFTimeInterval = -.greatestFiniteMagnitude

    private final class Slot {
        let texture: MTLTexture
        let context: CGContext
        let pixelSize: (width: Int, height: Int)
        let bytesPerRow: Int
        let uploadSource: UnsafeMutableRawPointer?

        private let ownedMemory: UnsafeMutableRawPointer?
        private let buffer: MTLBuffer?

        var bufferContents: UnsafeMutableRawPointer? {
            ownedMemory ?? buffer?.contents()
        }

        init(
            texture: MTLTexture,
            context: CGContext,
            pixelSize: (width: Int, height: Int),
            bytesPerRow: Int,
            buffer: MTLBuffer?,
            ownedMemory: UnsafeMutableRawPointer?
        ) {
            self.texture = texture
            self.context = context
            self.pixelSize = pixelSize
            self.bytesPerRow = bytesPerRow
            self.buffer = buffer
            self.ownedMemory = ownedMemory
            self.uploadSource = ownedMemory
        }

        deinit { ownedMemory?.deallocate() }
    }

    private var slots: [Slot] = []
    private var slotIndex = 0
    private var smallerSizeSince: CFTimeInterval?

    private init() {}

    func capture(
        window: UIWindow,
        region: CGRect,
        scale: CGFloat,
        frameDuration: CFTimeInterval,
        isUnderLoad: Bool
    ) -> Bool {
        guard !region.isNull, !region.isEmpty,
              window.bounds.width > 0, window.bounds.height > 0
        else { return false }

        if scale != requestedScale {
            requestedScale = scale
            slots.removeAll()
        }

        let clipped = region.intersection(window.bounds)
        guard !clipped.isEmpty else { return false }

        frameCounter &+= 1

        let moved = clipped != lastRegion
        lastRegion = clipped

        if moved { lastMovementTime = CACurrentMediaTime() }

        let mustRefreshGeometry = !capturedRegion.contains(clipped)

        let isMoving = CACurrentMediaTime() - lastMovementTime < Tuning.movementMemory
        let stride = staleCaptures >= Tuning.staleCapturesBeforeIdle
            ? Tuning.idleStride
            : strideFrames
        let dueByCadence = !isMoving && frameCounter % stride == 0
        guard mustRefreshGeometry || dueByCadence else { return false }

        let margin = isMoving ? Tuning.movementMargin : 0
        let target = margin > 0
            ? clipped.insetBy(dx: -margin, dy: -margin).intersection(window.bounds)
            : clipped

        let start = CACurrentMediaTime()
        let didCapture = rasterise(window: window, region: target)
        guard didCapture else { return false }

        capturedRegion = target

        let elapsed = CACurrentMediaTime() - start
        captureCost = captureCost == 0
            ? elapsed
            : captureCost + (elapsed - captureCost) * Tuning.costSmoothing

        updateStride(frameDuration: frameDuration)
        recordDebug(cost: elapsed, region: target, now: start)
        return true
    }

    private func updateStride(frameDuration: CFTimeInterval) {
        let frame = frameDuration > 0 ? frameDuration : 1.0 / 60.0
        let budget = frame * Tuning.dutyCycle
        guard budget > 0, captureCost > 0 else { return }

        let needed = Int((captureCost / budget).rounded(.up))
        let target = min(max(needed, 1), Tuning.maxStride)

        guard target != strideFrames else {
            candidateStride = strideFrames
            candidateStrideAge = 0
            return
        }

        if candidateStride != target {
            candidateStride = target
            candidateStrideAge = 0
            return
        }

        candidateStrideAge += 1
        guard candidateStrideAge >= Tuning.strideHysteresisFrames else { return }

        strideFrames = target
        candidateStrideAge = 0
    }

    private func digest(of slot: Slot, width: Int, height: Int) -> UInt64 {
        guard width > 0, height > 0, let base = slot.bufferContents else { return 0 }

        let rowWords = slot.bytesPerRow / 4
        let cols = min(width, rowWords)
        let rows = min(height, slot.pixelSize.height)
        let total = cols * rows
        guard total > 0 else { return 0 }

        let pixels = base.assumingMemoryBound(to: UInt32.self)
        var hash: UInt64 = 0xcbf29ce484222325
        var index = 0
        while index < total {
            let row = index / cols
            hash = (hash ^ UInt64(pixels[row * rowWords + (index - row * cols)])) &* 0x100000001b3
            index += Tuning.digestStride
        }
        return hash
    }

    private func rasterise(window: UIWindow, region: CGRect) -> Bool {

        let area = max(region.width * region.height, 1)
        let ceiling = (Tuning.maxCapturePixels / area).squareRoot()
        let pinned = max(((min(requestedScale, ceiling)) * 4).rounded(.down) / 4, 1.0)
        if pinned != textureScale {
            textureScale = pinned
            slots.removeAll()
        }

        let scale = textureScale
        let origin = CGPoint(
            x: (region.minX * scale).rounded(.down) / scale,
            y: (region.minY * scale).rounded(.down) / scale
        )
        let size = CGSize(
            width: region.maxX - origin.x,
            height: region.maxY - origin.y
        )

        guard prepareSlots(for: size) else { return false }

        slotIndex = (slotIndex + 1) % slots.count
        let slot = slots[slotIndex]
        let context = slot.context

        capturedOrigin = origin
        textureSizePoints = CGSize(
            width: CGFloat(slot.pixelSize.width) / scale,
            height: CGFloat(slot.pixelSize.height) / scale
        )

        context.saveGState()

        context.interpolationQuality = .high
        context.setShouldAntialias(true)
        context.setShouldSubpixelPositionFonts(true)
        context.setShouldSubpixelQuantizeFonts(false)

        context.setShouldSmoothFonts(false)

        context.translateBy(x: 0, y: CGFloat(slot.pixelSize.height))
        context.scaleBy(x: scale, y: -scale)
        context.translateBy(x: -origin.x, y: -origin.y)

        let regionRect = CGRect(origin: origin, size: size)
        context.clip(to: regionRect)
        context.clear(regionRect)

        let regionPixelWidth = max(Int(size.width * scale), 1)
        let regionPixelHeight = max(Int(size.height * scale), 1)
        capturedPixelCount = regionPixelWidth * regionPixelHeight

        switch strategy {
        case .layerRender:
            NonRenderableLayer.isCapturingBackdrop = true
            window.layer.render(in: context)
            NonRenderableLayer.isCapturingBackdrop = false

            drawHostedContent(window: window, region: regionRect, context: context)

        case .compositedDraw:
            drawComposited(window: window, region: regionRect, context: context)
        }

        context.restoreGState()

        if let uploadSource = slot.uploadSource {
            slot.texture.replace(
                region: MTLRegionMake2D(0, 0, slot.pixelSize.width, slot.pixelSize.height),
                mipmapLevel: 0,
                withBytes: uploadSource,
                bytesPerRow: slot.bytesPerRow
            )
        }

        if strategy == .layerRender,
           isEmpty(slot, width: regionPixelWidth, height: regionPixelHeight) {
            emptyCaptures += 1
            if emptyCaptures >= Tuning.emptyCapturesBeforeSwitch {
                strategy = .compositedDraw
                emptyCaptures = 0
                NSLog(
                    "[LiquidGlass] CALayer.render(in:) returns nothing for this "
                    + "window (iOS 26 and up) — switching the backdrop capture "
                    + "to composited snapshots."
                )
            }
        } else {
            emptyCaptures = 0
        }

        let current = digest(of: slot, width: regionPixelWidth, height: regionPixelHeight)
        staleCaptures = current == lastDigest ? staleCaptures + 1 : 0
        lastDigest = current

        texture = slot.texture
        return true
    }

    private func isEmpty(_ slot: Slot, width: Int, height: Int) -> Bool {
        guard let base = slot.bufferContents, width > 8, height > 8 else { return false }

        let rowWords = slot.bytesPerRow / 4
        let columns = min(width, rowWords)
        let pixels = base.assumingMemoryBound(to: UInt32.self)
        let first = pixels[0]

        for row in 0..<8 {
            let y = height * row / 8
            for column in 0..<8 where pixels[y * rowWords + columns * column / 8] != first {
                return false
            }
        }

        return (first >> 24) == 0 || (first & 0x00FF_FFFF) == 0
    }

    private func drawComposited(window: UIWindow, region: CGRect, context: CGContext) {
        excludedViews.removeAll(keepingCapacity: true)
        defer { excludedViews.removeAll(keepingCapacity: true) }

        collectExcludedViews(in: window)

        UIGraphicsPushContext(context)
        defer { UIGraphicsPopContext() }

        drawSubviews(of: window, window: window, region: region, context: context)
    }

    private var excludedViews: [UIView] = []

    private func collectExcludedViews(in view: UIView) {
        for subview in view.subviews {
            if let layer = subview.layer as? NonRenderableLayer, layer.isExcludedFromBackdrop {
                excludedViews.append(subview)
                continue
            }
            collectExcludedViews(in: subview)
        }
    }

    private func leadsToExcludedView(_ view: UIView) -> Bool {
        excludedViews.contains { $0.isDescendant(of: view) }
    }

    private func drawSubviews(
        of parent: UIView,
        window: UIWindow,
        region: CGRect,
        context: CGContext
    ) {
        for subview in parent.subviews {
            guard !subview.isHidden, subview.alpha > 0.01 else { continue }
            guard !excludedViews.contains(subview) else { continue }

            let frame = subview.convert(subview.bounds, to: window)
            let leadsToGlass = leadsToExcludedView(subview)

            if subview.clipsToBounds, !frame.intersects(region), !leadsToGlass { continue }

            context.saveGState()
            defer { context.restoreGState() }

            if subview.alpha < 1 { context.setAlpha(subview.alpha) }

            guard leadsToGlass else {
                subview.drawHierarchy(in: frame, afterScreenUpdates: false)
                continue
            }

            if subview.clipsToBounds { context.clip(to: frame) }

            if let background = subview.backgroundColor?.cgColor, background.alpha > 0 {
                context.setFillColor(background)
                context.fill(frame)
            }

            drawSubviews(of: subview, window: window, region: region, context: context)
        }
    }

    private func drawHostedContent(window: UIWindow, region: CGRect, context: CGContext) {
        hostedViews.removeAll(keepingCapacity: true)
        defer { hostedViews.removeAll(keepingCapacity: true) }

        collectHostedViews(in: window, window: window, region: region)
        guard !hostedViews.isEmpty else { return }

        UIGraphicsPushContext(context)
        defer { UIGraphicsPopContext() }

        for (view, frame) in hostedViews {
            context.saveGState()
            view.drawHierarchy(in: frame, afterScreenUpdates: false)
            context.restoreGState()
        }
    }

    private var hostedViews: [(view: UIView, frame: CGRect)] = []

    private func collectHostedViews(in root: UIView, window: UIWindow, region: CGRect) {
        for subview in root.subviews {
            guard !subview.isHidden, subview.alpha > 0.01 else { continue }

            if let layer = subview.layer as? NonRenderableLayer,
               layer.isExcludedFromBackdrop {
                continue
            }

            if isHostingView(subview) {
                let frame = subview.convert(subview.bounds, to: window)
                if frame.intersects(region), !frame.isEmpty {
                    hostedViews.append((subview, frame))
                }
                continue
            }

            collectHostedViews(in: subview, window: window, region: region)
        }
    }

    private var hostingClasses: [ObjectIdentifier: Bool] = [:]

    private func isHostingView(_ view: UIView) -> Bool {
        let type = type(of: view)
        let key = ObjectIdentifier(type)
        if let known = hostingClasses[key] { return known }

        let isHosting = String(describing: type).contains("HostingView")
        hostingClasses[key] = isHosting
        return isHosting
    }

    private func prepareSlots(for size: CGSize) -> Bool {
        guard let context = GlassRenderContext.shared else { return false }

        func bucketed(_ value: CGFloat) -> Int {
            let pixels = max(Int((value * textureScale).rounded(.up)), 1)
            let bucket = Tuning.allocationBucket
            return ((pixels + bucket - 1) / bucket) * bucket
        }

        let requested = (width: bucketed(size.width), height: bucketed(size.height))

        if let current = slots.first?.pixelSize {
            let fits = requested.width <= current.width && requested.height <= current.height
            let wastes = requested.width * 2 <= current.width || requested.height * 2 <= current.height

            if fits, !wastes {
                smallerSizeSince = nil
                return true
            }

            if fits {
                let now = CACurrentMediaTime()
                let since = smallerSizeSince ?? now
                smallerSizeSince = since
                if now - since < Tuning.shrinkDelay { return true }
            }
        }

        smallerSizeSince = nil

        let device = context.device
        let alignment = context.linearTextureAlignment
        let width = requested.width
        let height = requested.height
        let bytesPerRow = ((width * 4 + alignment - 1) / alignment) * alignment

        var built: [Slot] = []
        built.reserveCapacity(2)

        for index in 0..<2 {
            guard let slot = makeSlot(
                device: device,
                index: index,
                width: width,
                height: height,
                bytesPerRow: bytesPerRow
            ) else { return false }
            built.append(slot)
        }

        slots = built
        slotIndex = 0
        texture = nil
        return true
    }

    private func makeSlot(
        device: MTLDevice,
        index: Int,
        width: Int,
        height: Int,
        bytesPerRow: Int
    ) -> Slot? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = .shaderRead
        descriptor.storageMode = .shared

        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
            | CGBitmapInfo.byteOrder32Little.rawValue

        #if !targetEnvironment(simulator)

        if let buffer = device.makeBuffer(
            length: bytesPerRow * height,
            options: .storageModeShared
        ) {
            buffer.label = "GlassBackdrop\(index)"

            if let texture = buffer.makeTexture(
                descriptor: descriptor,
                offset: 0,
                bytesPerRow: bytesPerRow
            ), let cgContext = CGContext(
                data: buffer.contents(),
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo
            ) {
                texture.label = "GlassBackdrop\(index)"
                return Slot(
                    texture: texture,
                    context: cgContext,
                    pixelSize: (width, height),
                    bytesPerRow: bytesPerRow,
                    buffer: buffer,
                    ownedMemory: nil
                )
            }
        }
        #endif

        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        texture.label = "GlassBackdrop\(index)"

        let memory = UnsafeMutableRawPointer.allocate(
            byteCount: bytesPerRow * height,
            alignment: MemoryLayout<UInt32>.alignment
        )

        guard let cgContext = CGContext(
            data: memory,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else {
            memory.deallocate()
            return nil
        }

        return Slot(
            texture: texture,
            context: cgContext,
            pixelSize: (width, height),
            bytesPerRow: bytesPerRow,
            buffer: nil,
            ownedMemory: memory
        )
    }

    func releaseResources() {
        slots.removeAll()
        texture = nil
        emptyCaptures = 0
        textureSizePoints = .zero
        captureCost = 0
        capturedPixelCount = 0
        lastDigest = 0
        staleCaptures = 0
        lastRegion = .null
        capturedRegion = .null
        lastMovementTime = -.greatestFiniteMagnitude
        strideFrames = 1
        candidateStride = 1
        candidateStrideAge = 0
        smallerSizeSince = nil
        textureScale = requestedScale
    }
}
