#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct BlurParams {

    float4 uvRect;

    float2 texelStep;
    float  radius;
    float  _pad0;
};

struct GlassParams {
    float4 cornerRadii;
    float4 tintColor;
    float4 frostColor;

    float4 sourceRect;
    float2 viewSize;
    float2 shapeSize;

    float2 refractionScale;

    float  refractionAmount;

    float  depthEffect;

    float  profilePower;
    float  profileBias;

    float  dispersionHeight;
    float  dispersionAmount;
    float  highlightIntensity;
    float  highlightAngle;
    float  lightIntensity;
    float  glassOpacity;
    float  saturation;
    float  noiseAmount;
    float2 _pad0;
};

vertex VertexOut liquid_glass_vertex(const device float4 *vertices [[buffer(0)]],
                                     uint vid [[vertex_id]]) {
    VertexOut out;
    out.position = float4(vertices[vid].xy, 0.0, 1.0);
    out.uv = vertices[vid].zw;
    return out;
}

inline float radiusAt(float2 coord, float4 radii) {
    if (coord.x >= 0.0) {
        return (coord.y <= 0.0) ? radii.z : radii.y;
    }
    return (coord.y <= 0.0) ? radii.w : radii.x;
}

inline float sdRoundedRect(float2 coord, float2 halfSize, float4 radii) {
    float r = radiusAt(coord, radii);
    float2 innerHalf = halfSize - float2(r);
    float2 cornerCoord = abs(coord) - innerHalf;
    float outside = length(max(cornerCoord, float2(0.0))) - r;
    float inside = min(max(cornerCoord.x, cornerCoord.y), 0.0);
    return outside + inside;
}

inline float2 gradSdRoundedRect(float2 coord, float2 halfSize, float4 radii) {
    float r = radiusAt(coord, radii);
    float2 innerHalf = halfSize - float2(r);
    float2 cornerCoord = abs(coord) - innerHalf;

    float insideCorner = step(0.0, min(cornerCoord.x, cornerCoord.y));
    float xMajor = step(cornerCoord.y, cornerCoord.x);
    float2 gradEdge = float2(xMajor, 1.0 - xMajor);
    float2 gradCorner = (length(cornerCoord) > 1e-4) ? normalize(cornerCoord) : float2(0.0);
    return sign(coord) * mix(gradEdge, gradCorner, insideCorner);
}

inline float circleMap(float x) {
    return 1.0 - sqrt(max(0.0, 1.0 - x * x));
}

inline float hashNoise(float2 co) {
    return fract(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
}

constexpr sampler linearSampler(mag_filter::linear,
                                min_filter::linear,
                                address::clamp_to_edge);

constant int kBlurTaps = 8;
constant int kDispersionTaps = 16;

fragment float4 blurFragment(VertexOut in [[stage_in]],
                             texture2d<float> source [[texture(0)]],
                             constant BlurParams &params [[buffer(1)]]) {
    float2 base = params.uvRect.xy + in.uv * params.uvRect.zw;

    if (params.radius <= 0.01) {
        return source.sample(linearSampler, base);
    }

    float sigma = max(params.radius * 0.5, 0.0001);
    float invTwoSigmaSq = -1.0 / (2.0 * sigma * sigma);

    float stride = max(params.radius * 1.5 / float(kBlurTaps), 1.0);

    float4 sum = source.sample(linearSampler, base);
    float weightSum = 1.0;

    for (int i = 0; i < kBlurTaps; ++i) {
        float offset = (float(i) + 0.5) * stride;
        float weight = exp2(offset * offset * invTwoSigmaSq * 1.4426950);
        float2 delta = params.texelStep * offset;

        sum += source.sample(linearSampler, base + delta) * weight;
        sum += source.sample(linearSampler, base - delta) * weight;
        weightSum += weight * 2.0;
    }

    return sum / weightSum;
}

struct GlassGeometry {

    float sd;

    float scale;

    float t;

    float2 direction;

    float2 normal;
};

inline GlassGeometry glassGeometry(float2 centered, constant GlassParams &params) {
    float2 halfSize = params.shapeSize * 0.5;

    GlassGeometry g;
    g.sd = sdRoundedRect(centered, halfSize, params.cornerRadii);

    float4 maxGradRadius = float4(min(halfSize.x, halfSize.y));
    float4 gradRadius = min(params.cornerRadii * 1.5, maxGradRadius);
    float2 normal = gradSdRoundedRect(centered, halfSize, gradRadius);
    g.normal = (length(normal) > 1e-5) ? normalize(normal) : float2(0.0, 1.0);

    float2 radial = (length(centered) > 1e-4) ? normalize(centered) : float2(0.0);
    float2 blended = g.normal + params.depthEffect * radial;
    g.direction = (length(blended) > 1e-5) ? normalize(blended) : g.normal;

    float2 limit = max(halfSize, float2(1e-3));
    float2 scale2 = clamp(params.refractionScale, float2(1e-3), limit);
    g.scale = max(dot(g.normal * g.normal, scale2), 1e-3);

    g.t = clamp(-min(g.sd, 0.0) / g.scale, 0.0, 1.0);

    return g;
}

inline float2 refractedPixels(float2 pixels, GlassGeometry g, constant GlassParams &params) {
    float profile = circleMap(pow(1.0 - g.t, max(params.profilePower, 1e-3)));
    float amount = (profile + params.profileBias * (1.0 - g.t)) * params.refractionAmount;
    return pixels - amount * g.direction;
}

inline float3 sampleBackdrop(texture2d<float> source,
                             float2 pixels,
                             constant GlassParams &params) {
    float2 uv = pixels / params.viewSize;
    float2 texUV = params.sourceRect.xy + uv * params.sourceRect.zw;

    return source.sample(linearSampler, clamp(texUV, float2(0.0), float2(1.0))).rgb;
}

fragment float4 glassFragment(VertexOut in [[stage_in]],
                              texture2d<float> source [[texture(0)]],
                              constant GlassParams &params [[buffer(1)]]) {
    float2 halfSize = params.shapeSize * 0.5;
    float2 pixels = in.uv * params.viewSize;
    float2 centered = pixels - params.viewSize * 0.5;

    GlassGeometry g = glassGeometry(centered, params);

    float aa = max(fwidth(g.sd), 1e-4);
    float shapeAlpha = 1.0 - smoothstep(-aa, aa, g.sd);
    if (shapeAlpha <= 0.001) {
        return float4(0.0);
    }

    float3 color;
    float inside = -min(g.sd, 0.0);

    if (inside >= g.scale) {
        color = sampleBackdrop(source, pixels, params);
    } else {
        float dispersionT = clamp(inside / max(params.dispersionHeight, 1e-3), 0.0, 1.0);
        float spread = circleMap(1.0 - dispersionT) * params.dispersionAmount;

        if (spread < 2.0) {
            color = sampleBackdrop(source, refractedPixels(pixels, g, params), params);
        } else {
            float2 base = refractedPixels(pixels, g, params);
            float2 tangent = float2(g.direction.y, -g.direction.x);

            float3 accumulated = float3(0.0);
            float3 weight = float3(0.0);
            float maxI = min(spread, float(kDispersionTaps));

            for (int i = 0; i < kDispersionTaps; ++i) {
                float u = float(i) / maxI;
                if (u > 1.0) break;

                float3 tap = sampleBackdrop(source, base + tangent * (u - 0.5) * spread, params);
                float3 mask = float3(step(0.5, u),
                                     step(0.25, u) * step(u, 0.75),
                                     step(u, 0.5));

                accumulated += tap * mask;
                weight += mask;
            }

            color = accumulated / max(weight, float3(1e-6));
        }
    }

    color = clamp(color, 0.0, 1.0);

    float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
    color = mix(float3(luma), color, params.saturation);
    color = mix(color, params.frostColor.rgb, params.frostColor.a);
    color = mix(color, params.tintColor.rgb, params.tintColor.a);

    if (params.noiseAmount > 0.0) {
        float grain = hashNoise(in.position.xy * 1e-3) - 0.5;
        color += grain * params.noiseAmount;
    }

    float2 normalized = centered / max(halfSize, float2(1e-4));
    float glow = sin(atan2(normalized.y, normalized.x) - params.highlightAngle);
    float band = 1.0 - smoothstep(0.0, 1.0, g.t);

    color *= 1.0 + glow * params.highlightIntensity * band + params.lightIntensity;

    float contour = 1.0 - smoothstep(0.0, 1.5, abs(g.sd));
    color += contour * params.highlightIntensity * 0.35 * max(glow, 0.0);

    color = clamp(color, 0.0, 1.0);

    float alpha = shapeAlpha * params.glassOpacity;
    return float4(color * alpha, alpha);
}
