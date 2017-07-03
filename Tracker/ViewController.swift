//
//  ViewController.swift
//  Tracker
//
//  Created by Jack Guo on 8/24/16.
//  Copyright © 2016 InPsi Inc. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation
import Accelerate
//import opencv2

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    let manager = CMMotionManager()
    
    @IBOutlet weak var m11: UILabel!
    @IBOutlet weak var m12: UILabel!
    @IBOutlet weak var m13: UILabel!
    @IBOutlet weak var m21: UILabel!
    @IBOutlet weak var m22: UILabel!
    @IBOutlet weak var m23: UILabel!
    @IBOutlet weak var m31: UILabel!
    @IBOutlet weak var m32: UILabel!
    @IBOutlet weak var m33: UILabel!
    
    var yPosition: CGFloat?
    @IBOutlet weak var heightLabel: UILabel!
    @IBAction func sliderChanged(_ sender: AnyObject) {
        if let slider = sender as? UISlider {
            yPosition = view.frame.height * CGFloat(slider.value)
            heightLabel.text = String(format: "%.1f", yPosition!)
        }
    }
    
    let captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    let targetRectangle = CALayer()
    var cameraProjectionMatrix: Array<Double>?
    
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    let xNormalizationFactor = Double(2.0 / UIScreen.main.bounds.size.width)
    let yNormalizationFactor = Double(2.0 / UIScreen.main.bounds.size.height)
    
    var initialAttitude: CMAttitude?
    var initialCoordinate = [0.0, 0.0, 1.0]
    var touchLocation: CGPoint? {
        willSet {
            initialCoordinate[0] = Double(newValue!.x - screenWidth/2) * xNormalizationFactor
            initialCoordinate[1] = Double(newValue!.y - screenHeight/2) * yNormalizationFactor
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialAttitude?.multiply(byInverseOf: CMAttitude())
        
        // Get hold of the device we want
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        let devices = AVCaptureDevice.devices()
        for device in devices! {
            if (device as AnyObject).hasMediaType(AVMediaTypeVideo) {
                if (device as AnyObject).position == AVCaptureDevicePosition.back {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if captureDevice != nil {
            beginSession()
        }
        
        setupTracker()
        
        cameraProjectionMatrix = getCameraProjectionMatrix()
        
        // Start tracking device motion
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 0.01
            manager.deviceMot
//          manager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XTrueNorthZVertical, toQueue: NSOperationQueue.mainQueue())
            manager.startDeviceMotionUpdates(to: OperationQueue.main) {
                [weak self] (data: CMDeviceMotion?, error: NSError?) in
                
                guard let data = data else {return}
                if self?.initialAttitude == nil {
                    self?.initialAttitude = self?.manager.deviceMotion?.attitude
                }
                
                let gravity = data.gravity
                let rotation = atan2(gravity.x, gravity.y) - M_PI
                
                data.attitude.multiply(byInverseOf: self!.initialAttitude!)
                
                let attitude = data.attitude
                self?.m11.text = String(format: "%.1f", attitude.rotationMatrix.m11)
                self?.m12.text = String(format: "%.1f", -attitude.rotationMatrix.m12)
                self?.m13.text = String(format: "%.1f", -attitude.rotationMatrix.m13)
                self?.m21.text = String(format: "%.1f", -attitude.rotationMatrix.m21)
                self?.m22.text = String(format: "%.1f", attitude.rotationMatrix.m22)
                self?.m23.text = String(format: "%.1f", attitude.rotationMatrix.m23)
                self?.m31.text = String(format: "%.1f", -attitude.rotationMatrix.m31)
                self?.m32.text = String(format: "%.1f", attitude.rotationMatrix.m32)
                self?.m33.text = String(format: "%.1f", attitude.rotationMatrix.m33)
                
                let transformMatrix = self!.getTransformMatrix(attitude.rotationMatrix)
                var finalCoordinate = [Double](repeating: 0.0, count: 3)
                vDSP_mmulD(transformMatrix, 1, self!.initialCoordinate, 1, &finalCoordinate, 1, 3, 1, 3)
                
                let newLocation = CGPoint(
                    x: finalCoordinate[0]/finalCoordinate[2] / self!.xNormalizationFactor + Double(self!.screenWidth)/2,
                    y: finalCoordinate[1]/finalCoordinate[2] / self!.yNormalizationFactor + Double(self!.screenHeight)/2
                )
                
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self?.targetRectangle.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(rotation)))
                self?.targetRectangle.position = newLocation
                CATransaction.commit()
            } as! CMDeviceMotionHandler as! CMDeviceMotionHandler as! CMDeviceMotionHandler as! CMDeviceMotionHandler as! CMDeviceMotionHandler as! CMDeviceMotionHandler as! CMDeviceMotionHandler
        }
    }
    
    func beginSession() {
        configureDevice()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        try! captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        
        captureSession.beginConfiguration()
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_24BGR as UInt32)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(dataOutput) == true {
            captureSession.addOutput(dataOutput)
        }
        captureSession.commitConfiguration()
        
        let queue = DispatchQueue(label: "jack.guo", attributes: [])
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = self.view.layer.bounds
        self.view.layer.insertSublayer(previewLayer!, at: 0)
        captureSession.startRunning()
    }
    
    func configureDevice() {
        if let device = captureDevice {
            try! device.lockForConfiguration()
            device.focusMode = .locked
            device.unlockForConfiguration()
        }
    }
 
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchPoint = touches.first{
            touchLocation = touchPoint.location(in: self.view)
            targetRectangle.position = touchLocation!
            initialAttitude = manager.deviceMotion?.attitude
            
            let x = touchLocation!.y / screenHeight
            let y = 1 - touchLocation!.x / screenWidth
            let focusPoint = CGPoint(x: x, y: y)
            
            if let device = captureDevice {
                try! device.lockForConfiguration()
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = AVCaptureExposureMode.continuousAutoExposure
                device.unlockForConfiguration()
            }
        }
    }
    
    func setupTracker() {
        targetRectangle.borderWidth = 1.0
        targetRectangle.borderColor = UIColor.blue.cgColor
        targetRectangle.frame.size = CGSize(width: 100, height: 100)
        targetRectangle.position = self.view.center
        touchLocation = self.view.center
        self.view.layer.addSublayer(targetRectangle)
    }
    
    func getCameraProjectionMatrix() -> Array<Double> {
        let format = captureDevice?.activeFormat
        /*   If you need dimension in terms of pixels
        let formatDescription = format!.formatDescription
        let dimension = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, true, true) 
         */
        let horizontalFOV = Double(format!.videoFieldOfView)
        let verticalFOV = horizontalFOV * Double(screenWidth / screenHeight)
        let fx = abs( 1 / tan( verticalFOV/180*Double(M_PI)/2 ) )
        let fy = abs( 1 / tan( horizontalFOV/180*Double(M_PI)/2 ) )
        return [fx, 0.0, 0.0, 0.0, fy, 0.0, 0.0, 0.0, 1.0]
    }
    
    func getTransformMatrix(_ rotationMatrix: CMRotationMatrix) -> Array<Double> {
        let rotationVector = rotationInAdjustedCoordinate(rotationMatrix)
        var intermediateResult = [Double](repeating: 0.0, count: 9)
        vDSP_mmulD(cameraProjectionMatrix!, 1, rotationVector, 1, &intermediateResult, 1, 3, 3, 3)
        var finalResult = [Double](repeating: 0.0, count: 9)
        vDSP_mmulD(intermediateResult, 1, invert(cameraProjectionMatrix!), 1, &finalResult, 1, 3, 3, 3)
        return finalResult
    }
    
    func invert(_ matrix : [Double]) -> [Double] {
        var inMatrix = matrix
        var N = __CLPK_integer(sqrt(Double(matrix.count)))
        var pivots = [__CLPK_integer](repeating: 0, count: Int(N))
        var workspace = [Double](repeating: 0.0, count: Int(N))
        var error : __CLPK_integer = 0
        dgetrf_(&N, &N, &inMatrix, &N, &pivots, &error)
        dgetri_(&N, &inMatrix, &N, &pivots, &workspace, &N, &error)
        return inMatrix
    }
    
    //IMPORTANT: rotation matrix has been adjusted to our selected coordinate frame
    func rotationInAdjustedCoordinate(_ rotationMatrix: CMRotationMatrix) -> Array<Double> {
        let rotationVector = [
            rotationMatrix.m11,
            -rotationMatrix.m12,
            -rotationMatrix.m13,
            -rotationMatrix.m21,
            rotationMatrix.m22,
            rotationMatrix.m23,
            -rotationMatrix.m31,
            rotationMatrix.m32,
            rotationMatrix.m33
        ]
        return rotationVector
    }
    
    //Just add in code here to begin processing images
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
    
    }
}

