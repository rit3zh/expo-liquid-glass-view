import Metal
import UIKit

protocol GlassFrameParticipant: AnyObject {

    var glassWindow: UIWindow? { get }

    var glassRegionInWindow: CGRect? { get }

    var glassBackdropPadding: CGFloat { get }

    var glassCaptureScale: CGFloat { get }

    func glassDrawRequest(backdrop: MTLTexture, captureScale: CGFloat, backdropDidChange: Bool)
        -> GlassDrawRequest?
}

final class GlassFrameScheduler {

    static let shared = GlassFrameScheduler()

    private final class Weak {
        weak var value: GlassFrameParticipant?
        init(_ value: GlassFrameParticipant) { self.value = value }
    }

    private var participants: [Weak] = []
    private var displayLink: CADisplayLink?
    private var observer: CFRunLoopObserver?

    private var batch: [GlassDrawRequest] = []

    private var frameIsPending = false

    private var backdropDidChange = false

    private var lastSubmissionDropped = false

    private var frameDuration: CFTimeInterval = 1.0 / 60.0

    private var lastFrameTimestamp: CFTimeInterval = 0
    private var isUnderLoad = false

    private init() {}

    func add(_ participant: GlassFrameParticipant) {
        prune()
        guard !participants.contains(where: { $0.value === participant }) else { return }
        participants.append(Weak(participant))
        start()
    }

    func remove(_ participant: GlassFrameParticipant) {
        participants.removeAll { $0.value === participant || $0.value == nil }
        stopIfIdle()
    }

    private func prune() {
        participants.removeAll { $0.value == nil }
    }

    private func start() {
        guard displayLink == nil else { return }

        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link

        let observer = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault,
            CFRunLoopActivity.beforeWaiting.rawValue,
            true,
            0
        ) { [weak self] _, _ in
            self?.gatherIfPending()
        }

        if let observer {
            CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
            self.observer = observer
        }
    }

    private func stopIfIdle() {
        guard participants.isEmpty else { return }

        displayLink?.invalidate()
        displayLink = nil

        if let observer {
            CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, .commonModes)
        }
        observer = nil
        frameIsPending = false
        batch.removeAll(keepingCapacity: false)

        BackdropCapturer.shared.releaseResources()
    }

    @objc private func tick(_ link: CADisplayLink) {
        frameDuration = max(link.targetTimestamp - link.timestamp, 1.0 / 120.0)

        let elapsed = link.timestamp - lastFrameTimestamp
        isUnderLoad = lastFrameTimestamp > 0 && elapsed > frameDuration * 1.5
        lastFrameTimestamp = link.timestamp

        if frameIsPending { gather() }

        prune()
        guard !participants.isEmpty else { return }

        backdropDidChange = captureBackdrop()
        frameIsPending = true
    }

    private func captureBackdrop() -> Bool {

        var region: CGRect = .null
        var window: UIWindow?
        var scale: CGFloat = 1
        for entry in participants {
            guard let participant = entry.value,
                  let frame = participant.glassRegionInWindow
            else { continue }
            window = window ?? participant.glassWindow
            let padding = participant.glassBackdropPadding
            let padded = frame.insetBy(dx: -padding, dy: -padding)
            region = region.isNull ? padded : region.union(padded)
            scale = max(scale, participant.glassCaptureScale)
        }
        guard !region.isNull, let window else { return false }

        return BackdropCapturer.shared.capture(
            window: window,
            region: region,
            scale: scale,
            frameDuration: frameDuration,
            isUnderLoad: isUnderLoad
        )
    }

    private func gatherIfPending() {
        guard frameIsPending else { return }
        frameIsPending = false
        gather()
    }

    private func gather() {
        let capturer = BackdropCapturer.shared
        guard let backdrop = capturer.texture else { return }

        let changed = backdropDidChange || lastSubmissionDropped
        backdropDidChange = false

        let scale = capturer.textureScale
        batch.removeAll(keepingCapacity: true)

        for entry in participants {
            guard let participant = entry.value,
                  let request = participant.glassDrawRequest(
                      backdrop: backdrop,
                      captureScale: scale,
                      backdropDidChange: changed
                  )
            else { continue }
            batch.append(request)
        }

        lastSubmissionDropped = !GlassRenderer.shared.submit(batch)
    }
}
