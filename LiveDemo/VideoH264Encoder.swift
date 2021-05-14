//
//  VideoH264Encoder.swift
//  LiveDemo
//
//  Created by wujiu on 2021/3/15.
//

import Foundation
import VideoToolbox

class VideoH264Encoder {
    
    /**
     FPS ：Frames Per Second 的简称缩写，意思是每秒传输帧数，可以理解为我们常说的“刷新率”（单位为Hz）；FPS是测量用于保存、显示动态视频的信息数量。每秒钟帧数愈多，所显示的画面就会愈流畅，fps值越低就越卡顿，所以这个值在一定程度上可以衡量应用在图像绘制渲染处理时的性能。
     */
    fileprivate var frameID: Int64 = 0
    fileprivate var width: Int32 = 480
    fileprivate var height: Int32 = 640
    fileprivate var bitRate: Int32 = 480 * 640 * 3 * 4
    fileprivate var fps: Int32 = 10
    fileprivate var encodeSession: VTCompressionSession!
    fileprivate var encodeCallBack: VTCompressionOutputCallback?
    fileprivate var videoEncodeCallback: ((Data) -> Void)?
    fileprivate var videoEncodeCallBackSPSAndPPS: ((Data, Data) -> Void)?
    fileprivate var encodeQueue = DispatchQueue(label: "encode")
    fileprivate var callBackQueue = DispatchQueue(label: "callBack")
    
    init(width: Int32 = 480, height: Int32 = 640, bitRate: Int32? = nil, fps: Int32? = nil) {
        
        self.width = width
        self.height = height
        self.bitRate = bitRate != nil ? bitRate! : 480 * 640 * 3 * 4
        self.fps = fps != nil ? fps! : 10
        setCallBack()
        initVideoToolBox()
    }
    
    
    deinit {
        print("释放H264Encoder")
        if encodeSession != nil {
            
            VTCompressionSessionCompleteFrames(encodeSession, untilPresentationTimeStamp: .invalid)
            VTCompressionSessionInvalidate(encodeSession)
            encodeCallBack = nil
        }
    }
    
}

extension VideoH264Encoder {
    
    // 初始化VideoToolBox
    func initVideoToolBox() {
        
        let state = VTCompressionSessionCreate(allocator: kCFAllocatorDefault, width: width, height: height, codecType: kCMVideoCodecType_H264, encoderSpecification: nil, imageBufferAttributes: nil, compressedDataAllocator: nil, outputCallback: encodeCallBack, refcon: unsafeBitCast(self, to: UnsafeMutableRawPointer.self), compressionSessionOut: &encodeSession)
        
        if state != 0 {
            
            return
        }
        
        // 设置实时编码输出
        VTSessionSetProperty(encodeSession, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        
        // 设置编码方式
        VTSessionSetProperty(encodeSession, key: kVTCompressionPropertyKey_GammaLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
        
        // 设置是否产生B帧，B帧在解码的时候不是必须的
        VTSessionSetProperty(encodeSession, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
        
        // 设置关键帧间隔
        var frameInterval = 10
        let number = CFNumberCreate(kCFAllocatorDefault, CFNumberType.intType, &frameInterval)
        VTSessionSetProperty(encodeSession, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: number)
        
        // 设置期望帧率
        let fpscf = CFNumberCreate(kCFAllocatorDefault, CFNumberType.intType, &fps)
        VTSessionSetProperty(encodeSession, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: fpscf)
        
        //设置码率平均值，单位bps，码率大了话会非常清晰，但文件也会较大，较小图像有时候会模糊
        let bitrateAverage = CFNumberCreate(kCFAllocatorDefault, CFNumberType.intType, &bitRate)
        VTSessionSetProperty(encodeSession, key: kVTCompressionPropertyKey_AverageBitRate, value: bitrateAverage)
        
        // 码率限制
        let bitRatesLimit: CFArray = [bitRate * 2, 1] as CFArray
        VTSessionSetProperty(encodeSession, key: kVTCompressionPropertyKey_DataRateLimits, value: bitRatesLimit)
    }
    
    // 开始编码
    func encodeVideo(sampleBuffer: CMSampleBuffer) {
        
        encodeQueue.async {
            
            let imageBufferr = CMSampleBufferGetImageBuffer(sampleBuffer)
            let time = CMTime(value: self.frameID, timescale: 1000)
            let state = VTCompressionSessionEncodeFrame(self.encodeSession, imageBuffer: imageBufferr!, presentationTimeStamp: time, duration: CMTime.invalid, frameProperties: nil, sourceFrameRefcon: nil, infoFlagsOut: nil)
            if state != 0 {
                
                print("编码失败了")
            }
        }
    }
    
    // 编码回调
    func setCallBack() {
        
        
        encodeCallBack = { outputCallbackRefCon, out2, status, flag, sampleBuffer in
            
            let encoder: VideoH264Encoder = unsafeBitCast(outputCallbackRefCon, to: VideoH264Encoder.self)
            
            guard sampleBuffer != nil else {
                return
            }
            
            // 原始字节数据 8个字节
            let buffer: [UInt8] = [0x00, 0x00, 0x00, 0x01]
            // buffer -> UnsafeBufferPoint<UInt8>
            let unsafeBufferPointer = buffer.withUnsafeBufferPointer { $0 }
            let unsafePointer = unsafeBufferPointer.baseAddress
            guard let startCode = unsafePointer else {
                return
            }
            
            let attachArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer!, createIfNecessary: false)
            let key = unsafeBitCast(kCMSampleAttachmentKey_NotSync, to: UnsafeRawPointer.self)
            let cfdict = unsafeBitCast(CFArrayGetValueAtIndex(attachArray, 0), to: CFDictionary.self)
            let keyFrame = CFDictionaryContainsKey(cfdict, key)
            
            // 获取：SPS Sequence Parameter Set(序列参数集)
            // 获取：PPS Picture Parameter Set(图像参数集)
            if keyFrame {
                
                if let description = CMSampleBufferGetFormatDescription(sampleBuffer!) {
                    
                    var spsSize: Int = 0
                    var pspCount: Int = 0
                    var spsHeaderLength: Int32 = 0
                    
                    var ppsSize: Int = 0
                    var ppsCount: Int = 0
                    var ppsHeaderLength: Int32 = 0
                    
                    var spsDataPointer: UnsafePointer<UInt8>? = UnsafePointer(UnsafeMutablePointer<UInt8>.allocate(capacity: 0))
                    var ppsDataPointer = UnsafePointer<UInt8>(bitPattern: 0)
                    
                    
                    let spsstatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: 0, parameterSetPointerOut: &spsDataPointer, parameterSetSizeOut: &spsSize, parameterSetCountOut: &pspCount, nalUnitHeaderLengthOut: &spsHeaderLength)
                    
                    if spsstatus != 0 {
                        
                        print("SPS获取失败")
                    }
                    
                    let ppsstatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: 1, parameterSetPointerOut: &ppsDataPointer, parameterSetSizeOut: &ppsSize, parameterSetCountOut: &ppsCount, nalUnitHeaderLengthOut: &ppsHeaderLength)
                    
                    if ppsstatus != 0 {
                        
                        print("PPS获取失败")
                    }
                    
                    if let spsData = spsDataPointer, let ppsData = ppsDataPointer {
                        
                        var spsDataValue = Data(capacity: 4 + spsSize)
                        spsDataValue.append(buffer, count: 4)
                        spsDataValue.append(spsData, count: spsSize)
                        
                        
                        var ppsDataValue = Data(capacity: 4 + ppsSize)
                        ppsDataValue.append(startCode, count: 4)
                        ppsDataValue.append(ppsData, count: ppsSize)
                        
                        encoder.callBackQueue.async {
                            
                            encoder.videoEncodeCallBackSPSAndPPS?(spsDataValue,ppsDataValue)
                        }
                    }
                }
            }
            
            
            let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer!)
            var dataPointer: UnsafeMutablePointer<Int8>? = nil
            var totalLength: Int = 0
            
            let blockState = CMBlockBufferGetDataPointer(dataBuffer!, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &totalLength, dataPointerOut: &dataPointer)
            
            if blockState != 0 {
                
                print("获取data失败")
            }
            
            var offset: UInt32 = 0
            let lengthInfoSize = 4
            
            while offset < totalLength - lengthInfoSize {
                
                var dataLength: UInt32 = 0
                memcpy(&dataLength, dataPointer! + UnsafeMutablePointer<Int8>.Stride(offset), lengthInfoSize)
                
                //大端
                dataLength = CFSwapInt32BigToHost(dataLength)
                
                //获取到编码好的视频数据
                var data = Data(capacity: Int(dataLength) + lengthInfoSize)
                data.append(buffer, count: 4)
                
                let unsapepoint = unsafeBitCast(dataPointer, to: UnsafePointer<UInt8>.self)
                data.append(unsapepoint + UnsafePointer<UInt8>.Stride(offset + UInt32(lengthInfoSize)), count: Int(dataLength))
                
                encoder.callBackQueue.async {
                    
                    encoder.videoEncodeCallback?(data)
                }
                
                offset += dataLength + UInt32(lengthInfoSize)
            }
        }
    }
    
  
    // 编码完成回调
    func videoEncodeCallBack(finish: @escaping (Data) -> Void) {
        
        videoEncodeCallback = finish
    }
    
    //获取sps和pps回调
    func videoEncodeCallbackSPSANDPPS(finish: @escaping (Data, Data) -> Void) {
        
        videoEncodeCallBackSPSAndPPS = finish
    }


}
