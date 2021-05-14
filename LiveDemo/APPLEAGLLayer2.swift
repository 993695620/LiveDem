//
//  APPLEAGLLayer.swift
//  LiveDemo
//
//  Created by wujiu on 2021/5/10.
//
// OC 写法换成Swift写法还有写完
import UIKit
import CoreVideo

class APPLEAGLLayer2: CAEAGLLayer {

    
    let backingWidth: GLint = 0
    let backingHeight: GLint = 0
    var contxt: EAGLContext?
    var lumaTexture: CVOpenGLESTexture!
    var chromaTexture: CVOpenGLESTexture!
    var frameBufferHandle: GLuint! = 0
    let colorBufferHandle: GLuint! = 0
    
    let preferredConverion: [GLfloat] = [1.164, 1.164,1.164,
                                         0.0, -0.213, 2.112,
                                         1.793, -0.533, 0.0]
    
    
    
    
    
    
    
    var pixelBuffer: CVPixelBuffer!
    
    init(frame: CGRect) {
        
        super.init()
        
        let scale = UIScreen.main.scale
        self.isOpaque = true
        self.drawableProperties = [kEAGLDrawablePropertyRetainedBacking : true]
        self.frame = frame
        if let contxt = EAGLContext(api: EAGLRenderingAPI.openGLES2) {
            
            self.contxt = contxt
            
        } else {
            
            return
        }
        
        setupGL()
        
        
    }
    
    
    func setupGL() {
        
        if contxt == nil || EAGLContext.setCurrent(contxt) == nil {
            return
        }
    }
    
    func setupBuffers() {
            
        glDisable(GLenum(GL_DEPTH_TEST))
        
        glEnableVertexAttribArray(GLuint(GL_VERTEX_ATTRIB_ARRAY_SIZE))
        glVertexAttribPointer(GLuint(GL_VERTEX_ATTRIB_ARRAY_POINTER), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout.size(ofValue: GLfloat.self) * 2), nil)
        
        glEnableVertexAttribArray(GLuint(GL_TEXTURE_COORD_ARRAY_SIZE))
        glVertexAttribPointer(GLuint(GL_TEXTURE_COORD_ARRAY_POINTER), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout.size(ofValue: GLfloat.self) * 2), nil)
        
        createBuffers()
    }
    
    
    func createBuffers() {
        
        glGenFramebuffers(1, &frameBufferHandle)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBufferHandle)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
