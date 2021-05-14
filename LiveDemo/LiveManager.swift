//
//  LiveManager.swift
//  LiveDemo
//
//  Created by yuzhengkai on 2021/3/13.
//

import UIKit
import AVFoundation


class Live: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    /*
    let base: T
    init(_ base: T) {
        self.base = base
    }
    */
    fileprivate let tool = BlueToothTool.ble
    
    fileprivate var videoDevice, audioDevice: AVCaptureDevice?
    fileprivate var videoInpue, audioInput: AVCaptureDeviceInput?
    fileprivate var videoOutput: AVCaptureVideoDataOutput?
    fileprivate var audioOutput: AVCaptureAudioDataOutput?
    fileprivate var videoConnection, audioConnection: AVCaptureConnection?
    fileprivate var previLayer: AVCaptureVideoPreviewLayer?
    fileprivate var session: AVCaptureSession!
    fileprivate var position: AVCaptureDevice.Position = .front
    lazy fileprivate var videoQueue = DispatchQueue(label: "Video Capture Queue")
    lazy fileprivate var audioQueue = DispatchQueue(label: "Audio Capture Queue")
    
    fileprivate var videoEncoder = VideoH264Encoder()
    
    func start(block: @escaping (AVCaptureVideoPreviewLayer) -> Void) {
        
//        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        input()
        
        output()
        
        previLayer = AVCaptureVideoPreviewLayer(session: session)
        previLayer?.videoGravity = .resizeAspectFill
        
        block(previLayer!)
        
        session.startRunning()
        
        // 编码完成回调
        videoEncoder.videoEncodeCallBack { (data) in
        
            let temp: [UInt8] = [0x01]
            let result: Data = temp + data
            self.tool.sendMessage(data: result)
        }
        
        //SPS和PPS回调
        videoEncoder.videoEncodeCallbackSPSANDPPS { (sps, pps) in
            
            let spstemp: [UInt8] = [0x02]
            let spsresult: Data = spstemp + sps
            self.tool.sendMessage(data: spsresult)
            
            let ppstemp: [UInt8] = [0x03]
            let ppsresult: Data = ppstemp + pps
            self.tool.sendMessage(data: ppsresult)
        }
        
    }
    
    func stop() {
        session.stopRunning()
    }
    
    fileprivate func input() {
        
        //MARK:初始化session
        session = AVCaptureSession()
        
        //MARK:初始化视频采集和音频采集
        videoDevice = AVCaptureDevice.default(for: .video)
        audioDevice = AVCaptureDevice.default(for: .audio)
        
        do {
            //MARK:初始化视频输入对象和音频输入对象
            videoInpue = try AVCaptureDeviceInput(device: videoDevice!)
            audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            guard let vinput = videoInpue, let ainput = audioInput else {
                return
            }
            
            //MARK:添加到AVCaptureSession中
            if session.canAddInput(vinput) {
                session.addInput(vinput)
            }
            
            if session.canAddInput(ainput) {
                session.addInput(ainput)
            }
            
        } catch {
            
            return
        }
    }
    
    fileprivate func output() {
        
        //MARK:初始化视频数据输出和音频数据输出
        videoOutput = AVCaptureVideoDataOutput()
        audioOutput = AVCaptureAudioDataOutput()
        
        //MARK:设置代理
        videoOutput?.setSampleBufferDelegate(self, queue: videoQueue)
        audioOutput?.setSampleBufferDelegate(self, queue: audioQueue)
        
        //MARK:设置视频图像格式
        videoOutput?.videoSettings = ["\(kCVPixelBufferPixelFormatTypeKey)" : kCVPixelFormatType_32BGRA]
        videoOutput?.alwaysDiscardsLateVideoFrames = true

        
        guard let voutput = videoOutput, let aoutput = audioOutput else {
            return
        }
        
        if session.canAddOutput(voutput) {
            session.addOutput(voutput)
        }
        
        if session.canAddOutput(aoutput) {
            session.addOutput(aoutput)
        }
        
        videoConnection = videoOutput?.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        audioConnection = audioOutput?.connection(with: .audio)
    }
    
    func updateDeviceWithPosition() {
        
        let discoverSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: position)
        let devices = discoverSession.devices
        
        for device in devices {
            
            if position == device.position {
                
                position = .back
                session.beginConfiguration()
                session.removeInput(videoInpue!)
                videoDevice = device
                videoInpue = try! AVCaptureDeviceInput(device: videoDevice!)
                if session.canAddInput(videoInpue!) {
                    session.addInput(videoInpue!)
                }
                videoConnection = videoOutput?.connection(with: .video)
                session.commitConfiguration()
            }
        }
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if connection == self.videoConnection {
            print("做视频编码h.264")
            videoEncoder.encodeVideo(sampleBuffer: sampleBuffer)
            
        } else if connection == self.audioConnection {
            print("做音频编码aac")
        }
    }
    
    deinit {
        print("========释放了我草==========")
    }
}

/*
protocol LiveProtocol {
    
    associatedtype T
    var capture: Live<T> {get}
    static var capture: Live<T>.Type {get}
}

extension LiveProtocol {
    
    var capture: Live<Self> {
        
        return Live(self)
    }
    
    static var capture: Live<Self>.Type {
    
        return Live<Self>.self
    }
}

extension UIView: LiveProtocol {}

*/
