# SimpleCamera

## 使⽤ AVFoundation 來控制內建相機並擷取影像
AVFoundation 媒體擷取器的核⼼是 AVCaptureSession 物件。它控制輸入（例如後置鏡 頭相機）與輸出（例如圖⽚檔）間的資料流（data flow）。
通常要使⽤ AVFoundation 框架來擷取⼀個靜態圖⽚或影像
1. 首先需要取得 AVCaptureDevice 實例來呈現底層的輸入裝置，例如後置鏡頭相機
2. 建⽴裝置的 AVCaptureDeviceInput 實例（instance）
3. 建⽴ AVCapturePhotoOutput 實例來處理靜態圖⽚輸出 
    或 
    建立 AVCaptureMovieFileOutput 實例來處理影片輸出
4. 使⽤ AVCaptureSession 來協調輸入與輸出的資料流
5. 以 session 來建⽴⼀個 AVCaptureVideoPreviewLayer 的實例來顯⽰相機預覽

|:pushpin: NOTICE|
|----------------|
|記得要在 Info.plist 插入⼀個項⽬插入⼀個名稱為 Privacy - Camera Usage Description 的 key，並在 value 處寫下理由來指定為什麼你需要存取相機。這個訊息會在 App 使⽤時會通知使⽤者。|
