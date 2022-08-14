//
//  CameraViewController.swift
//  SimpleCamera
//
//  Created by 陳鈺翔 on 2022/8/12.
//

import UIKit
import AVFoundation
import AVKit

class CameraViewController: UIViewController {
    
    let captureSession = AVCaptureSession()
    
    // MARK: -
    
    var rearCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice!
    
    // MARK: -
    
    var imageOutput: AVCapturePhotoOutput!
    var captureImage: UIImage?
    
    // MARK: -
    
    var videoOutput: AVCaptureMovieFileOutput!
    var isRecording = false
    
    // MARK: -
    
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Timer
    
    var timer: Timer = Timer()
    var timeCount: Int = 0
    var timerIsCounting: Bool = false
    
    // MARK: - UISwipeGestureRecognizer
    
    var toggleCameraSwipeUp = UISwipeGestureRecognizer()
    var toggleCameraSwipeDown = UISwipeGestureRecognizer()
    var swipeLeft = UISwipeGestureRecognizer()
    var pinchGesture = UIPinchGestureRecognizer()
    
    // MARK: - @Outlet

    @IBOutlet var photoBtn: UIButton!
    @IBOutlet var videoBtn: UIButton!
    
    @IBOutlet var scaleLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    // MARK: - 拍照
    
    @IBAction func capturePhoto(sender: UIButton) {
        
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
    
    // MARK: - 錄影
    
    @IBAction func captureVideo(sender: UIButton) {
        
        isRecording.toggle()
        if isRecording {
            
            timeCount = 0
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nibName, repeats: true)
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat, .autoreverse, .allowUserInteraction], animations: { () -> Void in
                
                self.videoBtn.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }, completion: nil)
            
            let outputPath = NSTemporaryDirectory() + "output.mov"
            let outputFileURL = URL(fileURLWithPath: outputPath)
            videoOutput.startRecording(to: outputFileURL, recordingDelegate: self)
            
        } else {
            
            timer.invalidate()
            
            UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: { () -> Void in
                self.videoBtn.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: nil)
            timeLabel.text = "  00 : 00 : 00  "
            videoBtn.layer.removeAllAnimations()
            videoOutput.stopRecording()
        }
    }
    
    // MARK: - 關閉相片預覽頁面
    
    @IBAction func closePhotoView(segue: UIStoryboardSegue) {
        dismiss(animated: true)
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 50)
        let largeBoldDoc = UIImage(systemName: "circle.inset.filled", withConfiguration: largeConfig)
        
        photoBtn.setImage(largeBoldDoc, for: .normal)
        
        let largeBoldDoc2 = UIImage(systemName: "viewfinder.circle.fill", withConfiguration: largeConfig)
        
        videoBtn.setImage(largeBoldDoc2, for: .normal)
        videoBtn.isHidden = true
        
        timeLabel.isHidden = true
        timeLabel.layer.masksToBounds = true
        timeLabel.layer.cornerRadius = 10
        
        scaleLabel.layer.masksToBounds = true
        scaleLabel.layer.cornerRadius = 15
        
        configure()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - 判斷裝置有無旋轉，更新預覽畫面
    
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
    
    // MARK: - captureSession 初始化
    
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
        videoOutput = AVCaptureMovieFileOutput()
        
        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(imageOutput)
        
        
        // 建立相機預覽
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = view.layer.frame

        view.bringSubviewToFront(photoBtn)
        view.bringSubviewToFront(videoBtn)
        view.bringSubviewToFront(scaleLabel)
        view.bringSubviewToFront(timeLabel)
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
        
        swipeLeft.direction = .left
        swipeLeft.addTarget(self, action: #selector(changeBtn))
        view.addGestureRecognizer(swipeLeft)
    }
    
    // MARK: - 更換使用的相機(前置 or 後置)
    
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
    
    // MARK: - 縮放手勢
    
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
    
    // MARK: - SwipeLeft 更換相機模式(拍照 or 錄影)
    
    @objc func changeBtn() {
        photoBtn.isHidden.toggle()
        videoBtn.isHidden.toggle()
        timeLabel.isHidden.toggle()
        
        if !photoBtn.isHidden {
            for output in captureSession.outputs {
                captureSession.removeOutput(output)
            }
            if captureSession.canAddOutput(imageOutput) {
                captureSession.addOutput(imageOutput)
            }
        }
        if !videoBtn.isHidden {
            for output in captureSession.outputs {
                captureSession.removeOutput(output)
            }
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
        }
    }
    
    // MARK: - timeLabel 的時間顯示
    
    @objc func timerCounter() {
        
        timeCount += 1
        let time = timeCountToHoursMinutesSeconds(timeCount: timeCount)
        let timeString = timeCountToString(hours: time.0, minutes: time.1, seconds: time.2)
        timeLabel.text = timeString
    }
    
    func timeCountToHoursMinutesSeconds(timeCount : Int) -> (Int, Int, Int) {
        
        return ((timeCount / 3600), ((timeCount % 3600) / 60), ((timeCount % 3600) % 60))
    }
    
    func timeCountToString(hours: Int, minutes: Int, seconds: Int) -> String {
        
        var timeString = "  "
        timeString += String(format: "%02d", hours)
        timeString += " : "
        timeString += String(format: "%02d", minutes)
        timeString += " : "
        timeString += String(format: "%02d", seconds)
        timeString += "  "
        
        return timeString
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showImage":
            let destinationVC = segue.destination as! PhotoViewController
            destinationVC.image = captureImage
            
        case "playVideo":
            let destinationVC = segue.destination as! PlayerViewController
            let videoFileURL = sender as! URL
            destinationVC.videoURL = videoFileURL
            destinationVC.player = AVPlayer(url: videoFileURL)
            
        default:
            return
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

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

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        guard error == nil else {
            return
        }
        
        performSegue(withIdentifier: "playVideo", sender: outputFileURL)
    }
}
