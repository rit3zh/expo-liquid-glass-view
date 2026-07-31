import ExpoModulesCore
import CoreGraphics

public struct GlassCornerRadii: Record {
    @Field public var topLeft: Double = 0
    @Field public var topRight: Double = 0
    @Field public var bottomRight: Double = 0
    @Field public var bottomLeft: Double = 0

    public init() {}
}

struct CornerRadiiValues: Equatable {
    var topLeft: CGFloat = 0
    var topRight: CGFloat = 0
    var bottomRight: CGFloat = 0
    var bottomLeft: CGFloat = 0

    static func uniform(_ radius: CGFloat) -> CornerRadiiValues {
        CornerRadiiValues(topLeft: radius, topRight: radius, bottomRight: radius, bottomLeft: radius)
    }

    var isUniform: Bool {
        topLeft == topRight && topRight == bottomRight && bottomRight == bottomLeft
    }

    func clamped(to size: CGSize) -> CornerRadiiValues {
        let limit = min(size.width, size.height) / 2
        return CornerRadiiValues(
            topLeft: min(max(0, topLeft), limit),
            topRight: min(max(0, topRight), limit),
            bottomRight: min(max(0, bottomRight), limit),
            bottomLeft: min(max(0, bottomLeft), limit)
        )
    }

    func simd(for size: CGSize) -> SIMD4<Float> {
        let c = clamped(to: size)
        return SIMD4<Float>(
            Float(c.bottomLeft),
            Float(c.bottomRight),
            Float(c.topRight),
            Float(c.topLeft)
        )
    }
}

extension CornerRadiiValues {

    init(_ prop: Either<Double, GlassCornerRadii>?) {
        guard let prop else {
            self = .uniform(0)
            return
        }

        let radius: Double? = prop.get()
        if let radius {
            self = .uniform(CGFloat(radius))
            return
        }

        let radii: GlassCornerRadii? = prop.get()
        guard let radii else {
            self = .uniform(0)
            return
        }

        self = CornerRadiiValues(
            topLeft: CGFloat(radii.topLeft),
            topRight: CGFloat(radii.topRight),
            bottomRight: CGFloat(radii.bottomRight),
            bottomLeft: CGFloat(radii.bottomLeft)
        )
    }
}
