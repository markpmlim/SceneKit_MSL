//  Created by Mark Lim Pak Mun on 31/03/2019.
//  Copyright © 2019 Incremental Innovation. All rights reserved.

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct PlaneNodeBuffer {
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

struct vertexOutput
{
    float4 position [[position]];   // clip space
    float2 texCoords;
};

// We will not be using the values encapuslated in SCNSceneBuffer
vertex vertexOutput
vertex_function(VertexInput                 in          [[ stage_in ]],
                constant SCNSceneBuffer&    scn_frame   [[buffer(0)]],
                constant PlaneNodeBuffer&   scn_node    [[buffer(1)]])
{
    vertexOutput vert;
    vert.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    // Pass the texture coords to fragment function.
    vert.texCoords = in.texCoords;
    return vert;
}

fragment half4
fragment_function(vertexOutput              interpolated    [[stage_in]],
                  texture2d_array<float>    diffuseTexture  [[texture(0)]],
                  constant uint&            layer           [[buffer(2)]])
{
    constexpr sampler sampler2d(coord::normalized,
                                filter::linear, address::repeat);
    float4 color = diffuseTexture.sample(sampler2d,
                                         interpolated.texCoords, layer);
    return half4(color);

}

