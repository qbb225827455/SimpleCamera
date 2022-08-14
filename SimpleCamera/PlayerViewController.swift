//
//  PlayerViewController.swift
//  SimpleCamera
//
//  Created by 陳鈺翔 on 2022/8/14.
//

import UIKit
import AVKit
import AVFoundation

class PlayerViewController: AVPlayerViewController {

    var videoURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        do {
            try FileManager.default.removeItem(at: videoURL)
        } catch {
            print(error)
        }
    }

}
