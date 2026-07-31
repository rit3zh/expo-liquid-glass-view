import ExpoModulesCore
import UIKit

public enum GlassVariant: String, Enumerable {

    case regular

    case clear

    struct MetalDefaults {
        var blur: CGFloat

        var width: CGFloat
        var height: CGFloat

        var amount: CGFloat

        var depthEffect: CGFloat

        var profile: SIMD2<Float>

        var dispersion: CGFloat
        var light: CGFloat

        var frost: CGFloat
        var saturation: CGFloat
        var highlight: CGFloat
        var noise: CGFloat
        var borderOpacity: CGFloat
    }

    var metalDefaults: MetalDefaults {
        switch self {
        case .regular:
            return MetalDefaults(
                blur: 0,
                width: 20,
                height: 20,
                amount: 60,
                depthEffect: 1,
                profile: SIMD2<Float>(1, 0),
                dispersion: 6,
                light: 0.0,
                frost: 0.36,
                saturation: 1.8,
                highlight: 0.25,
                noise: 0.05,
                borderOpacity: 0.28
            )
        case .clear:
            return MetalDefaults(
                blur: 0,
                width: 10,
                height: 10,
                amount: 30,
                depthEffect: 0,
                profile: SIMD2<Float>(1, 0),
                dispersion: 10,
                light: 0.0,
                frost: 0.06,
                saturation: 1.15,
                highlight: 0.35,
                noise: 0.06,
                borderOpacity: 0.4
            )
        }
    }
}

public enum GlassBackend: String, Enumerable {

    case auto

    case native

    case metal
}

public enum GlassCornerStyle: String, Enumerable {
    case continuous
    case circular

    var layerCurve: CALayerCornerCurve {
        self == .circular ? .circular : .continuous
    }
}
