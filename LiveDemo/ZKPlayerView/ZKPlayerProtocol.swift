//
//  ZKPlayerProtocol.swift
//  MetalTestDemo
//
//  Created by wujiu on 2021/5/14.
//

import Foundation
import MetalKit

protocol ZKPlayerProtocol: MTKViewDelegate { }

extension ZKPlayerView: ZKPlayerProtocol {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
        
        // 创建命令缓冲区
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        // 获取渲染描述信息
        let renderPassDescriptor = view.currentRenderPassDescriptor
    
        // 读取图像数据
        // 直播方式注释掉下面的打开上面的，直接读取视频反之
//        let sampleBuffer = sampleImageBuffer
        let sampleBuffer = reader?.redBuffer()
        if renderPassDescriptor != nil && sampleBuffer != nil {
            
            // 设置渲染描述颜色
            renderPassDescriptor!.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0)
            
            // 创建渲染命令编码器
            let renderEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
            
            // 设置视图窗口大小
            renderEncoder?.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0))
    
            // 渲染编码器渲染管道
            renderEncoder?.setRenderPipelineState(pipelineState)
            
            // 设置顶点缓存
            renderEncoder?.setVertexBuffer(vertices, offset: 0, index: 0)
            
            // 设置纹理将sampleBuffer数据设置到renderEncoder中
            setTextureWithEncoder(encoder: renderEncoder!, buffer: sampleBuffer!)
            
            // 设置片元函数转矩阵
            renderEncoder?.setFragmentBuffer(convertMatrix, offset: 0, index: 0)
        
            // 开始绘制
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numberVertices!)
            
            // 显示结束编码
            commandBuffer!.present(self.currentDrawable!)
            
            renderEncoder?.endEncoding()
        }
        // 提交命令
        commandBuffer?.commit()
    }
    
}
