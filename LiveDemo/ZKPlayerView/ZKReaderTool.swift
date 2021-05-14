//
//  ZKReaderTool.swift
//  MetalTestDemo
//
//  Created by wujiu on 2021/5/11.
//

import UIKit
import AVFoundation

class ZKReaderTool: NSObject {
    fileprivate var videoURL: URL!
    fileprivate var lock: NSLock!
    fileprivate var assetReader: AVAssetReader!
    fileprivate var readerTrackOutPut: AVAssetReaderTrackOutput!
    
    init(url: URL) {
        super.init()
        videoURL = url
        lock = NSLock()
        setAsset()
    }
    
    
    func setAsset() {
        
        let inputOptions = [AVURLAssetPreferPreciseDurationAndTimingKey : true]
        let inputAsset = AVURLAsset(url: videoURL, options: inputOptions)
        let assetKey = "tracks"
        
        inputAsset.loadValuesAsynchronously(forKeys: [assetKey]) {
            
            DispatchQueue.global().async {
                
                let errorpoint: ErrorPointer = nil
                let status: AVKeyValueStatus = inputAsset.statusOfValue(forKey: assetKey, error: errorpoint)
                
                if status != AVKeyValueStatus.loaded {

                    print("视频轨道状态失败：\(String(describing: errorpoint))")
                    return
                }
                
                self.processWithAsset(asset: inputAsset)
            }
        }
    }
    
    func processWithAsset(asset: AVAsset) {
        
        self.lock.lock()
        
        // 创建AVAssetReader
        do {
            self.assetReader = try AVAssetReader(asset: asset)
        } catch {
            print("错误了")
        }
        
        // 设置YUV 4:2:0
        let outputSettings: [String : Any] = [String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
    
        // 读取视频源中信息
        self.readerTrackOutPut = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: .video).first!, outputSettings: outputSettings)
        
        // 缓存区的数据输出之前是否被复制
        self.readerTrackOutPut.alwaysCopiesSampleData = false
        
        // 填充输出
        self.assetReader.add(self.readerTrackOutPut)
        
        if !self.assetReader.startReading() {
            
            print("URL错误无法读取")
        }
        self.lock.unlock()
    }
    
    // MARK: 读取CMSampleBuffer
    func redBuffer() -> CMSampleBuffer? {
        
        lock.lock()
        var sampleBufferr: CMSampleBuffer!
        if readerTrackOutPut != nil {
            
            // 缓冲区内容复制到sampleBuffer
            sampleBufferr = readerTrackOutPut!.copyNextSampleBuffer()
        }
        if assetReader != nil && assetReader.status == .completed {
            
            readerTrackOutPut = nil
            assetReader = nil
            setAsset()
        }
        lock.unlock()
        return sampleBufferr
    }
}
