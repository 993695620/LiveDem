//
//  LiveViewController.swift
//  LiveDemo
//
//  Created by yuzhengkai on 2021/3/13.
//

import UIKit


class LiveViewController: UIViewController {

    let live = Live()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.white
        
        live.start { (layer) in
            layer.frame = self.view.bounds
            self.view.layer.addSublayer(layer)
        }
        
        
//        let button = UIButton(frame: CGRect(x: (self.view.frame.width - 80)/2.0, y: self.view.frame.height - 60, width: 80, height: 40))
//        button.backgroundColor = UIColor.orange
//        button.setTitle("切换", for: .normal)
//        button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
//        self.view.addSubview(button)
        
    }
    

    @objc func buttonClick() {
        
        live.updateDeviceWithPosition()
        
    }
    
    
    deinit {
        live.stop()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
