//
//  CameraViewController.swift
//  SimpleCamera
//
//  Created by 陳鈺翔 on 2022/8/12.
//

import UIKit

class CameraViewController: UIViewController {

    @IBOutlet var cameraBtn:UIButton!
    
    @IBAction func capture(sender: UIButton) {
        
    }
    
    @IBAction func closePhotoView(segue: UIStoryboardSegue) {
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 50)
        let largeBoldDoc = UIImage(systemName: "circle.inset.filled", withConfiguration: largeConfig)
        
        cameraBtn.setImage(largeBoldDoc, for: .normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
