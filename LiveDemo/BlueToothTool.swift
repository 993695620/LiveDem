//
//  BlueToothTool.swift
//  LiveDemo
//
//  Created by wujiu on 2021/5/6.
//

import UIKit
import MultipeerConnectivity


class BlueToothTool: NSObject {
    
    static let ble = BlueToothTool()
    var session: MCSession?
    var peer: MCPeerID?
    var advertiser: MCAdvertiserAssistant?
    var messageBlock: ((Data) -> Void)?
    private override init() {
        super.init()
        
        // 创建一个PeerID
        peer = MCPeerID(displayName: UIDevice.current.name)
        // 创建session
        session = MCSession(peer: peer!, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        advertiser = MCAdvertiserAssistant(serviceType: "yuzhengkai", discoveryInfo: nil, session: session!)
        advertiser?.delegate = self
        
    }
    

    func start() {
        
        advertiser?.start()
    }
    
    
    func setupBrowserVC() -> MCBrowserViewController? {
        
        guard let session = session else {
            return nil
        }
        let browser = MCBrowserViewController(serviceType: "yuzhengkai", session: session)
        browser.delegate = self
        return browser
    }
    
    
    // 发送数据
    func sendMessage(data: Data) {
        
        do {
            try session!.send(data, toPeers: session!.connectedPeers, with: .reliable)
        } catch  {
            
            print("发送失败")
        }
       
    }
    
    deinit {
        print("====================================================")
    }
    
}

extension BlueToothTool: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        switch state {
        case .notConnected:
            print("未连接")
        case .connecting:
            print("正在连接中")
        case .connected:
            print("已经连接了")
            
        default:
            print("")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    
        messageBlock?(data)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
        
    }
    
}

extension BlueToothTool: MCAdvertiserAssistantDelegate {
    
    func advertiserAssistantWillPresentInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        
        
    }
    
    func advertiserAssistantDidDismissInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        
        
    }
}

extension BlueToothTool: MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        
        browserViewController.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        
        browserViewController.dismiss(animated: true, completion: nil)
    }
}
