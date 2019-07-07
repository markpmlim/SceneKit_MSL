//  Created by Mark Lim Pak Mun on 31/03/2019.
//  Copyright © 2019 Incremental Innovation. All rights reserved.

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

// A node with a geometry of class SCNPlane was instantiated.
struct myPlaneNodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
    float2x3 boundingBox;
};

typedef struct {
    float3 position     [[ attribute(SCNVertexSemanticPosition) ]];
    float2 texCoords    [[ attribute(SCNVertexSemanticTexcoord0) ]];
} VertexInput;

struct Uniforms
{
    float2 resolution;
};

struct SimpleVertex
{
    float4 position [[position]];   // clip space
};

// prototype
float4 t(float2 uv, float time);
float srgbToLinear(float c);

// Returns a color
float4 t(float2 uv, float time)
{
    float j = sin(uv.y*3.14 + time*5.0);
    float i = sin(uv.x*15.0 - uv.y*2.0*3.14 + time*3.0);
    float n = -clamp(i, -0.2, 0.0) - 0.0*clamp(j, -0.2, 0.0);
    // To see a 4-blade "propeller"
    //float n = -clamp(i, -0.2, 0.0) - 1.0*clamp(j, -0.2, 0.0);
    
    return 3.5*(float4(0.2, 0.5, 1.0, 1.0) * n);
    
}

float srgbToLinear(float c) {
    if (c <= 0.04045)
        return c / 12.92;
    else
        return pow((c + 0.055) / 1.055, 2.4);
}

vertex SimpleVertex
vertex_function(VertexInput                 in          [[ stage_in ]],
                constant SCNSceneBuffer&    scn_frame   [[buffer(0)]],
                constant myPlaneNodeBuffer& scn_node    [[buffer(1)]])
{
    SimpleVertex vert;
    vert.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);

    return vert;
}

// SimpleVertex interpolated [[ stage_in ]] can also be passed.
fragment half4
fragment_function(float4            fragCoord   [[position]],
                  constant float2&  resolution  [[buffer(2)]],
                  constant float&   time        [[buffer(3)]],
                  constant float&   fadeFactor  [[buffer(4)]])
{

    float2 position = fragCoord.xy;
    float2 p = -1.0 + 2.0 * (position / resolution);
    float r = sqrt(dot(p, p));
    float a = atan2(p.y*(0.3 + 0.1*cos(time*2.0 + p.y)),
                    p.x*(0.3 + 0.1*sin(time + p.x))) + time;

    float2 uv;
    uv.x = time + 1.0/( r + .01);
    uv.y = 4.0*a/3.1416;

    float4 pixelColor = mix(float4(0.0), t(uv, time)*r*r*2.0,
                            fadeFactor);
    pixelColor.r = srgbToLinear(pixelColor.r);
    pixelColor.g = srgbToLinear(pixelColor.g);
    pixelColor.b = srgbToLinear(pixelColor.b);
    return half4(pixelColor);

}



