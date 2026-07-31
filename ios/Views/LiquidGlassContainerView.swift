import ExpoModulesCore
import UIKit

class LiquidGlassContainerView: ExpoView {

    private var effectView: UIVisualEffectView?

    private var hasAppliedEffectAfterLayout = false

    private var contentHost: UIView {
        effectView?.contentView ?? self
    }

    var spacing: Double? {
        didSet {
            guard spacing != oldValue else { return }
            applyEffect()
        }
    }

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)

        backgroundColor = .clear
        clipsToBounds = false

        guard #available(iOS 26.0, *), Self.isContainerEffectAvailable else { return }

        let effectView = UIVisualEffectView(effect: nil)

        effectView.isUserInteractionEnabled = true

        addSubview(effectView)
        self.effectView = effectView

        applyEffect()
    }

    private static let isContainerEffectAvailable: Bool = {
        if #available(iOS 26.0, *) {
            return NSClassFromString("UIGlassContainerEffect") != nil
        }
        return false
    }()

    private func applyEffect() {
        guard #available(iOS 26.0, *), Self.isContainerEffectAvailable, let effectView else {
            return
        }

        let effect = UIGlassContainerEffect()
        if let spacing {
            effect.spacing = CGFloat(spacing)
        }
        effectView.effect = effect
    }

    override func mountChildComponentView(_ childComponentView: UIView, index: Int) {
        contentHost.insertSubview(childComponentView, at: index)
    }

    override func unmountChildComponentView(_ childComponentView: UIView, index: Int) {
        childComponentView.removeFromSuperview()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil else {
            hasAppliedEffectAfterLayout = false
            return
        }

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let effectView else { return }

        effectView.bounds = CGRect(origin: .zero, size: bounds.size)
        effectView.center = CGPoint(x: bounds.midX, y: bounds.midY)

        guard !hasAppliedEffectAfterLayout, window != nil else { return }
        hasAppliedEffectAfterLayout = true

        effectView.effect = UIVisualEffect()
        applyEffect()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        if hit === self || hit === effectView || hit === effectView?.contentView {
            return nil
        }
        return hit
    }
}
