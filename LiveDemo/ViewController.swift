//
//  ViewController.swift
//  LiveDemo
//
//  Created by yuzhengkai on 2021/3/13.
//

import UIKit

class ViewController: UIViewController {

    let bluetooth = BlueToothTool.ble
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        let startLiveButton = UIButton(frame: CGRect(x: 20, y: 150, width: self.view.frame.width - 40, height: 50))
        startLiveButton.setTitle("开始直播", for: .normal)
        startLiveButton.backgroundColor = UIColor.red
        startLiveButton.addTarget(self, action: #selector(startLiveClick), for: .touchUpInside)
        self.view.addSubview(startLiveButton)
        
        
        let watchLiveButton = UIButton(frame: CGRect(x: 20, y: startLiveButton.frame.maxY + 30, width: self.view.frame.width - 40, height: 50))
        watchLiveButton.setTitle("观看直播", for: .normal)
        watchLiveButton.backgroundColor = UIColor.green
        watchLiveButton.addTarget(self, action: #selector(startLiveWatchClick), for: .touchUpInside)
        self.view.addSubview(watchLiveButton)
        
        
        let contentBLEButton = UIButton(frame: CGRect(x: 20, y: watchLiveButton.frame.maxY + 30, width: self.view.frame.width - 40, height: 50))
        contentBLEButton.setTitle("广播蓝牙", for: .normal)
        contentBLEButton.addTarget(self, action: #selector(blueClick(sender:)), for: .touchUpInside)
        contentBLEButton.backgroundColor = UIColor.blue
        self.view.addSubview(contentBLEButton)
        
        
        let findBLEButton = UIButton(frame: CGRect(x: 20, y: contentBLEButton.frame.maxY + 30, width: self.view.frame.width - 40, height: 50))
        findBLEButton.setTitle("发现蓝牙", for: .normal)
        findBLEButton.addTarget(self, action: #selector(findClick(sender:)), for: .touchUpInside)
        findBLEButton.backgroundColor = UIColor.orange
        self.view.addSubview(findBLEButton)
        
    }

    
    @objc func startLiveClick() {
    
        let liveVC = LiveViewController()
        self.navigationController?.pushViewController(liveVC, animated: true)
    }
    
    @objc func startLiveWatchClick() {
        
//        let watchVC = LiveWatchController()
//        self.navigationController?.pushViewController(watchVC, animated: true)
        
        let metalVC = LiveWatchMeatalController()
        self.navigationController?.pushViewController(metalVC, animated: true)
    }
    
    @objc func blueClick(sender: UIButton) {
        
        bluetooth.start()
        
    }

    
    @objc func findClick(sender: UIButton) {
        
        guard let browser = bluetooth.setupBrowserVC() else {
            return
        }
        
        self.present(browser, animated: true, completion: nil)
    }
    
    
    deinit {
        print("--------------------------------------------------------------------------")
    }
}

