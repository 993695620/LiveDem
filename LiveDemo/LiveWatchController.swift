//
//  LiveWatchController.swift
//  LiveDemo
//
//  Created by wujiu on 2021/5/10.
//

import UIKit

class LiveWatchController: UIViewController {

    fileprivate var player: AAPLEAGLLayer!
    let tool = BlueToothTool.ble
    fileprivate var videodecoder = VideoH264Decoder()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "观看直播了"
        self.view.backgroundColor = UIColor.white
        
        player = AAPLEAGLLayer(frame: self.view.frame)
        self.view.layer.addSublayer(player)
        
        videodecoder.setVideoDecodeCallback { [weak self] imagebuffer in
            
            self?.player.pixelBuffer = imagebuffer
        }
        tool.messageBlock  = { [weak self] data in
            
            let msgtype = data[0]
            
            switch msgtype {
            case 0x01:
                print("图像数据")
                var resultdata = data
                resultdata.remove(at: 0)
                self?.videodecoder.decode(data: resultdata)
                
            case 0x02:
                print("SPS数据")
                var resultspsdata = data
                resultspsdata.remove(at: 0)
                self?.videodecoder.decode(data: resultspsdata)
            case 0x03:
                print("PPS数据")
                var resultppsdata = data
                resultppsdata.remove(at: 0)
                self?.videodecoder.decode(data: resultppsdata)
            default:
                print("")
            }
        }
        
    }
    
    deinit {
        print("------释放----")
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
