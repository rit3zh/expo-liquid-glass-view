import UIKit

final class NonRenderableLayer: CALayer {

    static var isCapturingBackdrop = false

    var isExcludedFromBackdrop = true

    var backdropFillColor: CGColor?
    var backdropFillPath: CGPath?

    override func render(in ctx: CGContext) {
        guard !(Self.isCapturingBackdrop && isExcludedFromBackdrop) else { return }

        if Self.isCapturingBackdrop, let backdropFillColor, let backdropFillPath {
            ctx.saveGState()
            ctx.setFillColor(backdropFillColor)
            ctx.addPath(backdropFillPath)
            ctx.fillPath()
            ctx.restoreGState()
        }

        super.render(in: ctx)
    }
}

final class NonRenderableView: UIView {
    override class var layerClass: AnyClass { NonRenderableLayer.self }

    var isExcludedFromBackdrop: Bool {
        get { (layer as? NonRenderableLayer)?.isExcludedFromBackdrop ?? true }
        set { (layer as? NonRenderableLayer)?.isExcludedFromBackdrop = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}
