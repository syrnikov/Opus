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
    float2 canvasSize = uniforms.canvasSize;
    float2 coord = in.canvasCoord;

    float distanceToEdge = min(
        min(coord.x, canvasSize.x - coord.x),
        min(coord.y, canvasSize.y - coord.y)
    );

    float borderWidth = 1.0;
    float smoothing = max(max(fwidth(coord.x), fwidth(coord.y)), 0.5);
    float transition = smoothstep(borderWidth, borderWidth + smoothing, distanceToEdge);

    float3 borderColor = float3(0.80, 0.80, 0.82);
    float3 fillColor = float3(1.0, 1.0, 1.0);
    float3 color = mix(borderColor, fillColor, transition);

    return half4(half3(color), half(1.0));
}
