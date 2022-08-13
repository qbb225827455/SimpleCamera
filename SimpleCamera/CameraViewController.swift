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
        
        let photoSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSetting.isAutoStillImageStabilizationEnabled = true
        photoSetting.isHighResolutionPhotoEnabled = true
        if currentDevice.hasFlash {
            photoSetting.flashMode = .auto
        } else {
            photoSetting.flashMode = .off
        }
        
        imageOutput.isHighResolutionCaptureEnabled = true
        imageOutput.capturePhoto(with: photoSetting, delegate: self)
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
    
    override func viewWillLayoutSubviews() {
        
        if let connection = cameraPreviewLayer?.connection {
            
            let currentDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection: AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                
                switch orientation {
                    
                case .portrait:
                    self.updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    
                case .landscapeRight:
                    self.updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    
                case .landscapeLeft:
                    self.updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    
                case .portraitUpsideDown:
                    self.updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    
                default:
                    self.updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                }
            }
        }
    }
    
    func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        
        layer.videoOrientation = orientation

        cameraPreviewLayer!.frame = view.layer.bounds
    }
    
    func configure() {
        
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        for device in deviceDiscoverySession.devices {
            if device.position == .back {
                rearCamera = device
            } else if device.position == .front {
                frontCamera = device
            }
        }

        currentDevice = rearCamera

        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice) else {
            return
        }
        
        imageOutput = AVCapturePhotoOutput()
        
        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(imageOutput)
        
        // 建立相機預覽
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = view.layer.frame

        view.bringSubviewToFront(cameraBtn)
        view.bringSubviewToFront(scaleLabel)
        captureSession.startRunning()
}
