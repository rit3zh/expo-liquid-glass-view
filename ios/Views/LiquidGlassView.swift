import ExpoModulesCore
import UIKit

class LiquidGlassView: ExpoView {

    override class var layerClass: AnyClass { NonRenderableLayer.self }

    private var glassLayerView: UIView?
    private let surface = GlassSurfaceView()
    private var visualEffectView: UIVisualEffectView?

    private let contentContainer = NonRenderableView()

    private let borderLayer = CAGradientLayer()
    private let borderMask = CAShapeLayer()

    private let contentMask = CAShapeLayer()
    private let effectMask = CAShapeLayer()

    var variant: GlassVariant = .regular {
        didSet {
            guard variant != oldValue else { return }
            setNeedsAppearanceUpdate()
            refreshBackend()
        }
    }

    var backend: GlassBackend = .auto {
        didSet {
            guard backend != oldValue else { return }
            refreshBackend()
        }
    }

    var cornerStyle: GlassCornerStyle = .continuous {
        didSet {
            guard cornerStyle != oldValue else { return }
            invalidateShape()
        }
    }

    var cornerRadii: CornerRadiiValues = .uniform(0) {
        didSet {
            guard cornerRadii != oldValue else { return }
            invalidateShape()
        }
    }

    var tint: UIColor = .clear {
        didSet {
            guard tint != oldValue else { return }
            setNeedsAppearanceUpdate()
            applyNativeTint()
            invalidateShape()
        }
    }

    var isInteractive: Bool = false {
        didSet {
            guard isInteractive != oldValue else { return }

            if shouldUseNativeGlass {
                visualEffectView?.effect = UIVisualEffect()
            }
            applyNativeTint()
        }
    }

    var metal = GlassMetalOptions() {
        didSet {
            setNeedsAppearanceUpdate()
            if borderWidth != cachedBorderWidth { invalidateShape() }
        }
    }

    private var borderWidth: CGFloat {
        CGFloat(metal.border?.width ?? 1)
    }

    let onRendererChange = EventDispatcher()

    private var isUsingNativeGlass = false
    private var didReportRenderer = false
    private var lastReportedRenderer = ""

    private var hasPendingAppearanceUpdate = false

    private var resolvedFrostColor = SIMD4<Float>(1, 1, 1, 1)

    private var mountedChildren: [UIView] = []

    private var hasAppliedEffectAfterLayout = false

    private var shapeIsValid = false
    private var cachedRadii = CornerRadiiValues()
    private var cachedShapeSize: CGSize = .zero
    private var cachedBorderWidth: CGFloat = -1

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)

        clipsToBounds = false
        backgroundColor = .clear

        contentContainer.isUserInteractionEnabled = true
        addSubview(contentContainer)

        borderLayer.mask = borderMask

        borderLayer.opacity = 0

        borderLayer.colors = [
            UIColor.black.cgColor,
            UIColor.white.cgColor,
            UIColor.white.cgColor,
            UIColor.black.cgColor,
        ]
        borderLayer.locations = [0, 0.25, 0.75, 1]
        borderLayer.startPoint = CGPoint(x: 0, y: 1)
        borderLayer.endPoint = CGPoint(x: 1, y: 0)
        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.white.cgColor
        layer.addSublayer(borderLayer)

        contentMask.fillColor = UIColor.white.cgColor
        effectMask.fillColor = UIColor.white.cgColor

        updateResolvedFrostColor()
        applyAppearance()
        refreshBackend()
    }

    private var shouldUseNativeGlass: Bool {
        switch backend {
        case .metal:
            return false
        case .native, .auto:
            if #available(iOS 26.0, *) { return Self.isGlassEffectAvailable }
            return false
        }
    }

    private static let isGlassEffectAvailable: Bool = {
        if #available(iOS 26.0, *) {
            guard let glassEffectClass = NSClassFromString("UIGlassEffect") as? NSObject.Type else {
                return false
            }
            return glassEffectClass.responds(to: NSSelectorFromString("effectWithStyle:"))
        }
        return false
    }()

    private func refreshBackend() {
        let wantsNative = shouldUseNativeGlass

        let useNative = wantsNative || !surface.isOperational

        isUsingNativeGlass = useNative

        if useNative, !wantsNative {
            installFallbackBlur()
        } else if useNative {
            installNativeGlass()
        } else {
            installMetalGlass()
        }

        updateBackdropExclusion()
        restoreChildren()
        reportRenderer()
        invalidateShape()
    }

    private func updateBackdropExclusion() {
        let excluded = !isUsingNativeGlass
        (layer as? NonRenderableLayer)?.isExcludedFromBackdrop = excluded
        contentContainer.isExcludedFromBackdrop = excluded
    }

    private func installNativeGlass() {
        surface.removeFromSuperview()

        let effectView = existingOrNewEffectView()
        applyNativeTint()
        setGlassLayerView(effectView)
    }

    private func installFallbackBlur() {
        surface.removeFromSuperview()

        let effectView = existingOrNewEffectView()
        effectView.effect = UIBlurEffect(style: .systemThinMaterial)
        setGlassLayerView(effectView)
    }

    private func existingOrNewEffectView() -> UIVisualEffectView {
        if let visualEffectView { return visualEffectView }
        let effectView = UIVisualEffectView(effect: nil)

        effectView.isUserInteractionEnabled = true
        visualEffectView = effectView
        return effectView
    }

    private func installMetalGlass() {
        visualEffectView?.removeFromSuperview()
        visualEffectView = nil
        setGlassLayerView(surface)
    }

    private func setGlassLayerView(_ view: UIView) {
        guard glassLayerView !== view else { return }
        glassLayerView?.removeFromSuperview()
        insertSubview(view, at: 0)
        glassLayerView = view
    }

    private func applyNativeTint() {
        guard #available(iOS 26.0, *),
              let visualEffectView,
              isUsingNativeGlass,
              shouldUseNativeGlass
        else { return }
        let effect = UIGlassEffect(style: variant == .clear ? .clear : .regular)
        effect.isInteractive = isInteractive
        effect.tintColor = tint.cgColor.alpha > 0 ? tint : nil
        visualEffectView.effect = effect
    }

    private func setNeedsAppearanceUpdate() {
        guard !hasPendingAppearanceUpdate else { return }
        hasPendingAppearanceUpdate = true
        DispatchQueue.main.async { [weak self] in
            guard let self, self.hasPendingAppearanceUpdate else { return }
            self.hasPendingAppearanceUpdate = false
            self.applyAppearance()
        }
    }

    private func applyAppearance() {
        let defaults = variant.metalDefaults

        let refraction = metal.refraction
        let dispersion = metal.dispersion
        let highlight = metal.highlight

        surface.blurRadius = resolve(metal.blurRadius, defaults.blur)
        surface.captureQuality = max(CGFloat(metal.captureQuality ?? 1), 0.25)

        surface.refractionScale = CGSize(
            width: resolve(refraction?.width, defaults.width),
            height: resolve(refraction?.height, defaults.height)
        )
        surface.refractionAmount = resolve(refraction?.amount, defaults.amount)
        surface.depthEffect = resolve(refraction?.depth, defaults.depthEffect)
        surface.refractionProfile = refraction?.curve?.simd ?? defaults.profile

        surface.dispersionAmount = resolve(dispersion?.amount, defaults.dispersion)
        surface.dispersionHeight = resolve(dispersion?.reach, defaults.height)

        surface.highlightIntensity = resolve(highlight?.intensity, defaults.highlight)
        surface.highlightAngle = CGFloat(highlight?.angle ?? 135) * .pi / 180

        surface.frostAmount = resolve(metal.frost, defaults.frost)
        surface.saturation = resolve(metal.saturation, defaults.saturation)
        surface.noiseAmount = resolve(metal.noise, defaults.noise)
        surface.lightIntensity = resolve(metal.light, defaults.light)

        surface.glassOpacity = CGFloat(metal.opacity ?? 1)
        surface.tintRGBA = tint.simdRGBA
        surface.frostRGB = resolvedFrostColor

        borderLayer.opacity = Float(metal.border?.opacity ?? Double(defaults.borderOpacity))
    }

    private func resolve(_ override: Double?, _ fallback: CGFloat) -> CGFloat {
        guard let override else { return fallback }
        return CGFloat(override)
    }

    private func updateResolvedFrostColor() {
        resolvedFrostColor = UIColor.systemBackground
            .resolvedColor(with: traitCollection)
            .simdRGBA
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        guard traitCollection.userInterfaceStyle != previous?.userInterfaceStyle else { return }
        updateResolvedFrostColor()
        applyAppearance()
    }

    private func reportRenderer() {

        guard window != nil else { return }

        let name = isUsingNativeGlass
            ? (shouldUseNativeGlass ? "native" : "fallback-blur")
            : "metal"
        guard !didReportRenderer || name != lastReportedRenderer else { return }
        didReportRenderer = true
        lastReportedRenderer = name
        onRendererChange(["renderer": name])
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil else {
            hasAppliedEffectAfterLayout = false
            return
        }

        setNeedsLayout()
        reportRenderer()
    }

    private var contentHost: UIView {
        if isUsingNativeGlass, let visualEffectView {
            return visualEffectView.contentView
        }
        return contentContainer
    }

    private func restoreChildren() {
        guard !mountedChildren.isEmpty else { return }
        let host = contentHost
        for (index, child) in mountedChildren.enumerated() {
            host.insertSubview(child, at: min(index, host.subviews.count))
        }
    }

    override func mountChildComponentView(_ childComponentView: UIView, index: Int) {
        mountedChildren.insert(childComponentView, at: min(index, mountedChildren.count))
        let host = contentHost
        host.insertSubview(childComponentView, at: min(index, host.subviews.count))
    }

    override func unmountChildComponentView(_ childComponentView: UIView, index: Int) {
        mountedChildren.removeAll { $0 === childComponentView }
        childComponentView.removeFromSuperview()
    }

    private func invalidateShape() {
        shapeIsValid = false
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !hasAppliedEffectAfterLayout, window != nil, shouldUseNativeGlass {
            hasAppliedEffectAfterLayout = true

            visualEffectView?.effect = UIVisualEffect()
            applyNativeTint()
        }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        for child in [glassLayerView, contentContainer].compactMap({ $0 }) {
            child.bounds = CGRect(origin: .zero, size: bounds.size)
            child.center = center
        }

        let radii = cornerRadii

        guard !shapeIsValid
            || cachedShapeSize != bounds.size
            || cachedRadii != radii
            || cachedBorderWidth != borderWidth
        else { return }

        shapeIsValid = true
        cachedShapeSize = bounds.size
        cachedRadii = radii
        cachedBorderWidth = borderWidth

        let clamped = radii.clamped(to: bounds.size)
        surface.cornerRadii = radii.simd(for: bounds.size)

        applyCornerShaping(clamped)
        applyBorder(clamped)
        updateBackdropFill(clamped)
    }

    private func updateBackdropFill(_ radii: CornerRadiiValues) {
        guard let layer = layer as? NonRenderableLayer else { return }
        guard isUsingNativeGlass, tint.cgColor.alpha > 0 else {
            layer.backdropFillColor = nil
            layer.backdropFillPath = nil
            return
        }
        layer.backdropFillColor = tint.cgColor
        layer.backdropFillPath = path(for: radii).cgPath
    }

    private func applyCornerShaping(_ radii: CornerRadiiValues) {
        contentContainer.layer.cornerCurve = cornerStyle.layerCurve

        if radii.isUniform {
            contentContainer.layer.mask = nil
            contentContainer.layer.cornerRadius = radii.topLeft
            contentContainer.clipsToBounds = radii.topLeft > 0
        } else {
            contentContainer.layer.cornerRadius = 0
            contentMask.frame = bounds
            contentMask.path = path(for: radii).cgPath
            contentContainer.layer.mask = contentMask
            contentContainer.clipsToBounds = true
        }

        guard let visualEffectView else { return }
        visualEffectView.layer.cornerCurve = cornerStyle.layerCurve
        if radii.isUniform {
            visualEffectView.layer.mask = nil
            visualEffectView.layer.cornerRadius = radii.topLeft
            visualEffectView.clipsToBounds = true
        } else {
            visualEffectView.layer.cornerRadius = 0
            effectMask.frame = bounds
            effectMask.path = path(for: radii).cgPath
            visualEffectView.layer.mask = effectMask
            visualEffectView.clipsToBounds = true
        }
    }

    private func applyBorder(_ radii: CornerRadiiValues) {

        let visible = !isUsingNativeGlass && borderWidth > 0
        borderLayer.isHidden = !visible
        guard visible else { return }

        borderLayer.frame = bounds
        borderMask.frame = bounds
        borderMask.lineWidth = borderWidth

        borderMask.path = path(for: radii, inset: borderWidth / 2).cgPath
    }

    private func path(for radii: CornerRadiiValues, inset: CGFloat = 0) -> UIBezierPath {
        let rect = bounds.insetBy(dx: inset, dy: inset)
        guard rect.width > 0, rect.height > 0 else { return UIBezierPath() }

        let adjusted = CornerRadiiValues(
            topLeft: max(0, radii.topLeft - inset),
            topRight: max(0, radii.topRight - inset),
            bottomRight: max(0, radii.bottomRight - inset),
            bottomLeft: max(0, radii.bottomLeft - inset)
        ).clamped(to: rect.size)

        if adjusted.isUniform {
            return UIBezierPath(
                roundedRect: rect,
                cornerRadius: adjusted.topLeft
            )
        }

        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + adjusted.topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - adjusted.topRight, y: rect.minY))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - adjusted.topRight, y: rect.minY + adjusted.topRight),
            radius: adjusted.topRight, startAngle: -.pi / 2, endAngle: 0, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - adjusted.bottomRight))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - adjusted.bottomRight, y: rect.maxY - adjusted.bottomRight),
            radius: adjusted.bottomRight, startAngle: 0, endAngle: .pi / 2, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX + adjusted.bottomLeft, y: rect.maxY))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + adjusted.bottomLeft, y: rect.maxY - adjusted.bottomLeft),
            radius: adjusted.bottomLeft, startAngle: .pi / 2, endAngle: .pi, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + adjusted.topLeft))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + adjusted.topLeft, y: rect.minY + adjusted.topLeft),
            radius: adjusted.topLeft, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true
        )
        path.close()
        return path
    }
}

extension UIColor {

    var simdRGBA: SIMD4<Float> {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else {
            var white: CGFloat = 0
            if getWhite(&white, alpha: &a) {
                return SIMD4<Float>(Float(white), Float(white), Float(white), Float(a))
            }
            return SIMD4<Float>(0, 0, 0, 0)
        }
        return SIMD4<Float>(Float(r), Float(g), Float(b), Float(a))
    }
}
