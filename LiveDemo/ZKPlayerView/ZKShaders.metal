
#include <metal_stdlib>
#include <simd/simd.h>
#import "ZKShaderTypes.h"

using namespace metal;

/*
// 顶点数据结构体
typedef struct {
    // 顶点坐标 x,y,z,w
    vector_float4 position;

    // 纹理坐标 s,t
    vector_float2 textureCoordinate;
} Vertex;


// 顶点函数输入索引
typedef enum VertexInputIndex {
    
    VertexInputIndexVertices = 0,
    
} VertexInputIndex;


// 片元函数缓存区索引
typedef enum FragmentBufferIndex {
    
    FragmentInputIndexMatrix = 0,
    
} FragmentBufferIndex;


// 片元函数纹理索引
typedef enum FragmentTextureIndex {
    
    // 纹理Y
    FragmentTextureIndexTextureY = 0,
    
    // 纹理UV
    FragmentTextureIndexTextureUV = 1,
    
} FragmentTextureIndex;

// 转换矩阵
typedef struct {
    // 三维矩阵
    matrix_float3x3 matrix;
    
    // 偏移量
    vector_float3 offset;
    
} ConvertMatrix;

*/


// 结构体，用于顶点函数输出，片元函数输入
typedef struct {
    
    // position修饰符表示顶点
    float4 clipSpacePositionn [[position]];
    
    // 纹理坐标
    float2 textureCoordinate;
    
} RasterizerData;


// 顶点函数
vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]], constant Vertex * vertexArray [[buffer(VertexInputIndexVertices)]] ) {
    
    RasterizerData out;
    // 顶点坐标
    out.clipSpacePositionn = vertexArray[vertexID].position;
    
    // 纹理坐标
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return  out;
}


// 片元函数
fragment float4
samplingShader(RasterizerData input [[stage_in]], texture2d<float> textureY [[ texture(FragmentTextureIndexTextureY) ]],
                                                  texture2d<float> textureUV [[ texture(FragmentTextureIndexTextureUV) ]],
                                                  constant ConvertMatrix * convertMatrrix [[ buffer(FragmentInputIndexMatrix) ]]) {
    
    //获取纹理采样器
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    //读取YUV颜色值
    float3 yuv = float3(textureY.sample(textureSampler, input.textureCoordinate).r,
                        textureUV.sample(textureSampler, input.textureCoordinate).rg);
    
    //将YUV颜色转化为RGB
    float3 rgb = convertMatrrix -> matrix * (yuv + convertMatrrix -> offset);
    
    //返回RGBA
    return float4(rgb, 1.0);
}

