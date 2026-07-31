import ExpoModulesCore

public struct GlassRefractionOptions: Record {

    @Field public var amount: Double?

    @Field public var width: Double?

    @Field public var height: Double?

    @Field public var depth: Double?

    @Field public var curve: GlassRefractionCurve?

    public init() {}
}

public struct GlassDispersionOptions: Record {

    @Field public var amount: Double?

    @Field public var reach: Double?

    public init() {}
}

public struct GlassHighlightOptions: Record {

    @Field public var intensity: Double?

    @Field public var angle: Double?

    public init() {}
}

public struct GlassBorderOptions: Record {

    @Field public var width: Double?

    @Field public var opacity: Double?

    public init() {}
}

public struct GlassMetalOptions: Record {

    @Field public var blurRadius: Double?
    @Field public var captureQuality: Double?
    @Field public var opacity: Double?

    @Field public var frost: Double?
    @Field public var saturation: Double?
    @Field public var noise: Double?
    @Field public var light: Double?

    @Field public var refraction: GlassRefractionOptions?
    @Field public var dispersion: GlassDispersionOptions?
    @Field public var highlight: GlassHighlightOptions?
    @Field public var border: GlassBorderOptions?

    public init() {}
}
