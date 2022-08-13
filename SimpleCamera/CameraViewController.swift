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
        dismiss(animated: true)
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
        
        // 切換相機
        toggleCameraSwipeUp.direction = .up
        toggleCameraSwipeUp.addTarget(self, action: #selector(toggleCamera))
        toggleCameraSwipeDown.direction = .down
        toggleCameraSwipeDown.addTarget(self, action: #selector(toggleCamera))
        view.addGestureRecognizer(toggleCameraSwipeUp)
        view.addGestureRecognizer(toggleCameraSwipeDown)
        
        pinchGesture.addTarget(self, action: #selector(pinchToZoom(_:)))
        view.addGestureRecognizer(pinchGesture)
    }
    
    @objc func toggleCamera() {
        
        captureSession.beginConfiguration()
        
        guard let newCurrentDevice = (currentDevice.position == AVCaptureDevice.Position.back) ? frontCamera : rearCamera else {
            return
        }
        
        // Remove all input from session
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        
        let cameraInput: AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: newCurrentDevice)
        } catch {
            print(error)
            return
        }
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        currentDevice = newCurrentDevice
        captureSession.commitConfiguration()
    }
    
    @objc func pinchToZoom(_ gesture: UIPinchGestureRecognizer) {
        
        let scale = currentDevice.videoZoomFactor
        
        switch gesture.state {
        case .began:
            fallthrough
            
        case .changed:
            let minAvailableZoomScale = currentDevice.minAvailableVideoZoomFactor
            let maxAvailableZoomScale = 5.0
            
            var result = max(minAvailableZoomScale, min(gesture.scale * scale, maxAvailableZoomScale))
            result = (result * 10.0).rounded() / 10
            
            let resultTemp = Int(result * 10) % 10
            if resultTemp == 0 {
                self.scaleLabel.text = "\(Int(result))x"
            } else {
                self.scaleLabel.text = "\(result)x"
            }
            
            do {
                try currentDevice.lockForConfiguration()
                currentDevice?.ramp(toVideoZoomFactor: result, withRate: 1.0)
                //currentDevice.videoZoomFactor = result
                currentDevice.unlockForConfiguration()
            } catch {
                print(error)
            }
            
        default:
            return
        }
    }

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard error == nil else {
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        captureImage = UIImage(data: imageData)
        performSegue(withIdentifier: "showImage", sender: self)
    }
}
