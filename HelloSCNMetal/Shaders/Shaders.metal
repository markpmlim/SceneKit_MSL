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
fragment_function(vertexOutput                      interpolated    [[stage_in]],
                  texture2d<float, access::sample>  diffuseTexture  [[texture(0)]])
{
    constexpr sampler sampler2d(coord::normalized,
                                filter::linear, address::repeat);
    float4 color = diffuseTexture.sample(sampler2d,
                                         interpolated.texCoords);
    return half4(color);

}

// Generate a texture.
void kernel kernel_function(uint2                           gid         [[ thread_position_in_grid ]],
                            texture2d<float, access::write> outTexture  [[texture(0)]])
{
    // Check if the pixel is within the bounds of the output texture
    if ((gid.x >= outTexture.get_width()) ||
        (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    float2 textureSize = float2(outTexture.get_width(),
                                outTexture.get_height());
    float2 position = float2(gid);
    float4 pixelColor = float4(position/textureSize, 0.0, 1.0);
    pixelColor.y = 1.0 - pixelColor.y;  // invert the green component.
    outTexture.write(pixelColor, gid);
}
