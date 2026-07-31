import ExpoModulesCore

public struct GlassRefractionCurve: Record {

    @Field public var power: Double = 1

    @Field public var bias: Double = 0

    public init() {}

    var simd: SIMD2<Float> {
        SIMD2<Float>(Float(power), Float(bias))
    }
}
