//
//  ZKPlayerView.swift
//  MetalTestDemo
//
//  Created by wujiu on 2021/5/14.
//

import UIKit
import MetalKit
import CoreMedia


class ZKPlayerView: MTKView {

    var commandQueue: MTLCommandQueue!
    var reader: ZKReaderTool!
    var pipelineState: MTLRenderPipelineState!
    var vertices: MTLBuffer!
    var viewportSize: vector_uint2!
    var textureCache: CVMetalTextureCache!
    var convertMatrix: MTLBuffer!
    var numberVertices: Int!
    
    var sampleImageBuffer: CVImageBuffer?
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        
        viewportSize = vector_uint2(UInt32(self.drawableSize.width), UInt32(self.drawableSize.height))
        self.delegate = self
        // 读取纹理数据
        CVMetalTextureCacheCreate(nil, nil, self.device!, nil, &textureCache)
        // 测试直接读取视频打开，如果直播方式注释掉
        createZKRederTool()
        
        createPipeline()
        createVertex()
        createMatrix()
    }
    
    func setSampleBuffer(imageBuffer: CVImageBuffer) {
        
        sampleImageBuffer = imageBuffer
    }
    
    //MARK: 创建ZKRederTool
    func createZKRederTool() {
        // 视频文件路径
        let path = Bundle.main.path(forResource: "girl", ofType: "mp4")
        let url = URL(fileURLWithPath: path!)
        // 初始化Reader
        reader = ZKReaderTool(url: url)
        
    }
    //MARK: 创建渲染管线
    func createPipeline() {
        
        // 获取metal文件
        let library = self.device!.makeDefaultLibrary()
        
        // 顶点shader
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        
        // 片元shader
        let fragmentFunction = library?.makeFunction(name: "samplingShader")
        
        // 渲染管线描述信息
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        
        // 设置顶点
        pipelineStateDescriptor.vertexFunction = vertexFunction
        
        // 设置片元
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        
        // 设置颜色格式
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
        
        // 根据渲染管线描述初始化渲染管线
        pipelineState = try! self.device!.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        // 初始化渲染队列，保证渲染指令有序提交到GPU
        commandQueue = self.device?.makeCommandQueue()
        
    }
    
    //MARK: 创建顶点数据
    func createVertex() {
        
        let vertexs = [Vertex(position: vector_float4(SIMD4<Float>(1.0, -1.0, 0.0, 1.0)), textureCoordinate: vector_float2(SIMD2<Float>(1.0, 1.0))),
                       Vertex(position: vector_float4(SIMD4<Float>(-1.0, -1.0, 0.0, 1.0)), textureCoordinate: vector_float2(SIMD2<Float>(0.0, 1.0))),
                       Vertex(position: vector_float4(SIMD4<Float>(-1.0, 1.0, 0.0, 1.0)), textureCoordinate: vector_float2(SIMD2<Float>(0.0, 0.0))),
                       
                       Vertex(position: vector_float4(SIMD4<Float>(1.0, -1.0, 0.0, 1.0)), textureCoordinate: vector_float2(SIMD2<Float>(1.0, 1.0))),
                       Vertex(position: vector_float4(SIMD4<Float>(-1.0, 1.0, 0.0, 1.0)), textureCoordinate: vector_float2(SIMD2<Float>(0.0, 0.0))),
                       Vertex(position: vector_float4(SIMD4<Float>(1.0, 1.0, 0.0, 1.0)), textureCoordinate: vector_float2(SIMD2<Float>(1.0, 0.0)))]
        
        let size = MemoryLayout<Vertex>.stride * 6
        // 创建顶点缓存区
        vertices = self.device?.makeBuffer(bytes: vertexs, length: size, options: .storageModeShared)
        // 顶点个数
        numberVertices = vertexs.count
       
    }
    
    //MARK: 创建转换矩阵
    func createMatrix() {
        
        /*
        let matrixs = [[simd_float3(repeating: 1.164), simd_float3(repeating: 1.164), simd_float3(repeating: 1.164)],
                       [simd_float3(repeating: 0.0), simd_float3(repeating: -0.392),simd_float3(repeating: 2.017)],
                       [simd_float3(repeating: 1.596), simd_float3(repeating: -0.813), simd_float3(repeating: 0.0)]]

        let colorMatrx = unsafeBitCast(matrixs, to: matrix_float3x3.self)

        let matrixoffsets = [[vector_float3(repeating: -(16.0/255.0)), vector_float3(repeating: -0.5), vector_float3(repeating: -0.5)]]
        let rangeOffset = unsafeBitCast(matrixoffsets, to: vector_float3.self)
        */
        
        let colorMatrxs = matrix_float3x3(SIMD3<Float>(1.0, 1.0, 1.0),
                                          SIMD3<Float>(0.0, -0.343, 1.765),
                                          SIMD3<Float>(1.4, -0.711, 0.0))
        let rangeOffset = vector_float3(SIMD3<Float>(-16.0/255.0, -0.5, -0.5))
        // 创建矩阵结构体
        var matrix = ConvertMatrix()
        matrix.matrix = colorMatrxs
        matrix.offset = rangeOffset
        let size = MemoryLayout<ConvertMatrix>.stride
        // 创建矩阵缓冲区
        convertMatrix = self.device?.makeBuffer(bytes: &matrix, length: size, options: .storageModeShared)
        
    }
    
    //MARK: 设置CMSampleBuffer纹理
    func setTextureWithEncoder(encoder: MTLRenderCommandEncoder, buffer sampleBuffer: CMSampleBuffer) {
        
        // 从CMSmpleBuffer中读取CVPixelBuffer
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        /*---------------------Y纹理---------------------*/
        var textureY: MTLTexture? = nil
        // 设置Y纹理
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer!, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer!, 0)
        
        // 设置像素格式为普通格式，一个8位规范化的无符号整数组件
        let pixelFormat = MTLPixelFormat.r8Unorm
        
        // 纹理
        var textue: CVMetalTexture? = nil
        
        // 根据视频像素缓冲区创建Metal纹理缓存区
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer!, nil, pixelFormat, width, height, 0, &textue)
        
        if status == kCVReturnSuccess {
            
            // 纹理创建成功
            // 转成Metal用的纹理
            textureY = CVMetalTextureGetTexture(textue!)!
            textue = nil
        }
        
        /*---------------------UV纹理---------------------*/
        var textureUV: MTLTexture? = nil
        // 设置UV纹理
        let uvwidt = CVPixelBufferGetWidthOfPlane(pixelBuffer!, 1)
        let uvheight = CVPixelBufferGetHeightOfPlane(pixelBuffer!, 1)
        
        // 这里不要设置错是rg8Unorm
        let uvpixelFormat = MTLPixelFormat.rg8Unorm
        var uvtextue: CVMetalTexture? = nil
        let uvstatus = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer!, nil, uvpixelFormat, uvwidt, uvheight, 1, &uvtextue)
        if uvstatus == kCVReturnSuccess {
            textureUV = CVMetalTextureGetTexture(uvtextue!)!
            uvtextue = nil
        }
        
        
        
        if textureY != nil && textureUV != nil {
            
            //向片元函数设置textureY纹理
            encoder.setFragmentTexture(textureY!, index: 0)
            
            //向片元函数设置textureUV纹理
            encoder.setFragmentTexture(textureUV!, index: 1)
        }
    }
    
    //MARK: 设置直接CVImageBuffer
    func setTextureWithEncoder(encoder: MTLRenderCommandEncoder, buffer imageBuffer: CVImageBuffer) {
        
        let pixelBuffer = imageBuffer
        /*---------------------Y纹理---------------------*/
        var textureY: MTLTexture? = nil
        // 设置Y纹理
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        
        // 设置像素格式为普通格式，一个8位规范化的无符号整数组件
        let pixelFormat = MTLPixelFormat.r8Unorm
        
        // 纹理
        var textue: CVMetalTexture? = nil
        
        // 根据视频像素缓冲区创建Metal纹理缓存区
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, 0, &textue)
        
        if status == kCVReturnSuccess {
            
            // 纹理创建成功
            // 转成Metal用的纹理
            textureY = CVMetalTextureGetTexture(textue!)!
            textue = nil
        }
        
        /*---------------------UV纹理---------------------*/
        var textureUV: MTLTexture? = nil
        // 设置UV纹理
        let uvwidt = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1)
        let uvheight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
        
        // 这里不要设置错是rg8Unorm
        let uvpixelFormat = MTLPixelFormat.rg8Unorm
        var uvtextue: CVMetalTexture? = nil
        let uvstatus = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, uvpixelFormat, uvwidt, uvheight, 1, &uvtextue)
        if uvstatus == kCVReturnSuccess {
            textureUV = CVMetalTextureGetTexture(uvtextue!)!
            uvtextue = nil
        }
        
        
        
        if textureY != nil && textureUV != nil {
            
            //向片元函数设置textureY纹理
            encoder.setFragmentTexture(textureY!, index: 0)
            
            //向片元函数设置textureUV纹理
            encoder.setFragmentTexture(textureUV!, index: 1)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}


