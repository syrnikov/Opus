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
