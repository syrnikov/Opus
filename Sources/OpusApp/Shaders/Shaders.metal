#include <metal_stdlib>
using namespace metal;

struct StrokeVertexIn {
    float2 position [[attribute(0)]];
    float size [[attribute(1)]];
    float4 color [[attribute(2)]];
};

struct StrokeVertexOut {
    float4 position [[position]];
    float4 color;
    float pointSize [[point_size]];
};

struct CanvasUniforms {
    float2 canvasSize;
    float2 viewSize;
    float2 translation;
    float scale;
    float padding;
};

struct CanvasBackgroundVertexOut {
    float4 position [[position]];
    float2 canvasCoord;
};

vertex StrokeVertexOut stroke_vertex(StrokeVertexIn in [[stage_in]]) {
    StrokeVertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.color = in.color;
    out.pointSize = max(in.size, 1.0);
    return out;
}

fragment half4 stroke_fragment(StrokeVertexOut in [[stage_in]], float2 pointCoord [[point_coord]]) {
    float2 centered = pointCoord * 2.0 - 1.0;
    float distanceToCenter = length(centered);
    float falloff = smoothstep(1.0, 0.8, distanceToCenter);
    float alpha = in.color.a * (1.0 - falloff);
    return half4(half3(in.color.rgb), half(alpha));
}

vertex CanvasBackgroundVertexOut canvas_background_vertex(
    const device float2* positions [[buffer(0)]],
    constant CanvasUniforms& uniforms [[buffer(1)]],
    uint vid [[vertex_id]]) {
    float2 canvas = positions[vid];
    float2 canvasCenter = uniforms.canvasSize * 0.5;
    float2 viewCenter = uniforms.viewSize * 0.5;
    float2 centered = canvas - canvasCenter;
    float2 scaled = centered * uniforms.scale;
    float2 translated = scaled + uniforms.translation;
    float2 viewPoint = translated + viewCenter;

    float2 clip = float2(
        (viewPoint.x / uniforms.viewSize.x) * 2.0 - 1.0,
        ((uniforms.viewSize.y - viewPoint.y) / uniforms.viewSize.y) * 2.0 - 1.0
    );

    CanvasBackgroundVertexOut out;
    out.position = float4(clip, 0.0, 1.0);
    out.canvasCoord = canvas;
    return out;
}

fragment half4 canvas_background_fragment(
    CanvasBackgroundVertexOut in [[stage_in]],
    constant CanvasUniforms& uniforms [[buffer(0)]]) {
    float2 coord = in.canvasCoord;
    float checker = fmod(floor(coord.x) + floor(coord.y), 2.0);
    float3 lightColor = float3(0.94, 0.94, 0.96);
    float3 darkColor = float3(0.90, 0.90, 0.94);

    float pixelWidth = max(fwidth(coord.x), 1e-5);
    float pixelHeight = max(fwidth(coord.y), 1e-5);
    float2 local = fract(coord);
    float lineX = 1.0 - smoothstep(0.0, pixelWidth * 0.5, min(local.x, 1.0 - local.x));
    float lineY = 1.0 - smoothstep(0.0, pixelHeight * 0.5, min(local.y, 1.0 - local.y));
    float gridEmphasis = clamp(max(lineX, lineY), 0.0, 1.0);

    float3 baseColor = mix(lightColor, darkColor, checker);
    baseColor = mix(baseColor, float3(0.75, 0.75, 0.78), gridEmphasis * 0.35);

    bool isBorder = coord.x < 0.5 || coord.y < 0.5 || coord.x > uniforms.canvasSize.x - 0.5 || coord.y > uniforms.canvasSize.y - 0.5;
    float3 borderColor = float3(0.20, 0.20, 0.23);
    float3 finalColor = isBorder ? borderColor : baseColor;
    return half4(half3(finalColor), half(1.0));
}
