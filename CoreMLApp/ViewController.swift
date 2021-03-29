//
//  ViewController.swift
//  CoreMLApp
//
//  Created by Ali MAHFOUDHI on 03/03/2021.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var predictionLabel: UILabel!
    
    
    let mediaType = AVMediaType.video
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var position = AVCaptureDevice.Position.back
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Launch camera
        autorisationAndLaunchCamera()
    }
    
    func autorisationAndLaunchCamera() {
        let autorisation = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch autorisation {
        case .notDetermined:
            requestAutorisationCamera()
        case .restricted:
            print("denied")
        case .denied:
            print("denied")
        case .authorized:
            launchCamera()
        default: break
        }
    }

    func requestAutorisationCamera() {
        AVCaptureDevice.requestAccess(for: mediaType) { (success) in
            DispatchQueue.main.async {
                self.autorisationAndLaunchCamera()
            }
        }
    }
    
    func launchCamera() {
        previewLayer?.removeFromSuperlayer()
        
        session = AVCaptureSession()
        guard session != nil,
              let captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                                                for: mediaType,
                                                                position: position) else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if session!.canAddInput(input) {
                session!.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            output.alwaysDiscardsLateVideoFrames = true
            if session!.canAddOutput(output) {
                session!.addOutput(output)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: session!)
            previewLayer?.frame = cameraView.bounds
            previewLayer?.connection?.videoOrientation = .portrait
            previewLayer?.videoGravity = .resizeAspect
            
            guard previewLayer != nil else { return }
            cameraView.layer.addSublayer(previewLayer!)
            
            let queue = DispatchQueue(label: "CameraQueue")
            output.setSampleBufferDelegate(self, queue: queue)
            session!.startRunning()
            
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    
    
    @IBAction func rotationAction(_ sender: Any) {
        session?.stopRunning()
        switch position {
        case .back: position = .front
        case .front: position = .back
        case .unspecified: position = .back
        default: break
        }
        requestAutorisationCamera()
    }
    
}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let copie = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) else { return }
        
        let ciImage = CIImage(cvImageBuffer: pixel,
                              options: copie as? [CIImageOption : Any])
        if position == .front {
            self.requete(ciImage.oriented(forExifOrientation: Int32(UIImage.Orientation.leftMirrored.rawValue)))
        } else {
            self.requete(ciImage.oriented(forExifOrientation: Int32(UIImage.Orientation.downMirrored.rawValue)))
        }
    }
}
