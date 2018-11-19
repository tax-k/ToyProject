//
//  ViewController.swift
//  ToyProject
//
//  Created by tax_k on 19/11/2018.
//  Copyright © 2018 tax_k. All rights reserved.
//
import UIKit
import AVFoundation
import CoreImage

class ViewController: UIViewController {
    
    // MARK: - Properties
//    @IBOutlet weak var tmpImageView: UIView!
//    @IBOutlet weak var tmp: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    
    lazy var boxLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5).cgColor
        layer.opacity = 0
        self.view.layer.addSublayer(layer)
        return layer
    }()
    
    lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        return session
    }()
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    let sampleBufferQueue = DispatchQueue.global(qos: .userInteractive)
    
    let ciContext = CIContext()
    
    lazy var rectDetector: CIDetector = {
        return CIDetector(ofType: CIDetectorTypeRectangle,
                          context: self.ciContext,
                          options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])!
    }()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            setupCaptureSession()
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (authorized) in
                DispatchQueue.main.async {
                    if authorized {
                        self.setupCaptureSession()
                    }
                }
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.bounds = view.frame
    }
    
    // MARK: - Rotation
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    // MARK: - Camera Capture
    
    private func findCamera() -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInDualCamera,
            .builtInTelephotoCamera,
            .builtInWideAngleCamera
        ]
        
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                         mediaType: .video,
                                                         position: .back)
        
        return discovery.devices.first
    }
    
    private func setupCaptureSession() {
        guard captureSession.inputs.isEmpty else { return }
        guard let camera = findCamera() else {
            print("No camera found")
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(cameraInput)
            
            let preview = AVCaptureVideoPreviewLayer(session: captureSession)
            
//            preview.frame = view.bounds
            preview.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            
            
            preview.backgroundColor = UIColor.black.cgColor
            preview.videoGravity = .resizeAspect
            view.layer.addSublayer(preview)
            self.previewLayer = preview
            
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: sampleBufferQueue)
            
            captureSession.addOutput(output)
            
            captureSession.startRunning()
            
        } catch let e {
            print("Error creating capture session: \(e)")
            return
        }
    }
    
    private func displayRect(rect: CGRect) {
        /*
         -------------
         ---(layer)---
         ---(preview)-
         ---(rect)----
         ^
         */
        boxLayer.frame = rect
        boxLayer.opacity = 1
    }
    func prepareRectangleDetector() -> CIDetector {
        let options: [String : AnyObject] = [CIDetectorAccuracy: CIDetectorAccuracyHigh as AnyObject, CIDetectorAspectRatio: 1.0 as AnyObject]
        return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)!
    }
    
    func performRectangleDetection(image: CIImage) -> CIImage? {
        var resultImage: CIImage?
        resultImage = image
        let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.6, CIDetectorMaxFeatureCount: 10] )!
        
        // Get the detections
        var halfPerimiterValue = 0.0 as Float;
        let features = detector.features(in: image)
        print("feature \(features.count)")
        for feature in features as! [CIRectangleFeature] {
            
            let p1 = feature.topLeft
            let p2 = feature.topRight
            let width = hypotf(Float(p1.x - p2.x), Float(p1.y - p2.y));

            let p3 = feature.topLeft
            let p4 = feature.bottomLeft
            let height = hypotf(Float(p3.x - p4.x), Float(p3.y - p4.y));
            let currentHalfPerimiterValue = height+width;
            if (halfPerimiterValue < currentHalfPerimiterValue)
            {
                halfPerimiterValue = currentHalfPerimiterValue
                resultImage = drawHighlightOverlayForPoints(image: image, topLeft: feature.topLeft, topRight: feature.topRight, bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
                
//                resultImage = cropBusinessCardForPoints(image: image, topLeft: feature.topLeft, topRight: feature.topRight,
//                                                        bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
                print("perimmeter   \(halfPerimiterValue)")
            }
            
        }
        
        return resultImage
    }
    
    func drawHighlightOverlayForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint,
                                       bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        var overlay = CIImage(color: CIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5))
        overlay = overlay.cropped(to: image.extent)
        overlay = overlay.applyingFilter("CIPerspectiveTransformWithExtent",
                                         parameters: [
                                            "inputExtent": CIVector(cgRect: image.extent),
                                            "inputTopLeft": CIVector(cgPoint: topLeft),
                                            "inputTopRight": CIVector(cgPoint: topRight),
                                            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                                            "inputBottomRight": CIVector(cgPoint: bottomRight)
            ])
        return overlay.composited(over: image)
    }
    
    func cropBusinessCardForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        
        var businessCard: CIImage
        businessCard = image.applyingFilter(
            "CIPerspectiveTransformWithExtent",
            parameters: [
                "inputExtent": CIVector(cgRect: image.extent),
                "inputTopLeft": CIVector(cgPoint: topLeft),
                "inputTopRight": CIVector(cgPoint: topRight),
                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                "inputBottomRight": CIVector(cgPoint: bottomRight)])
        businessCard = image.cropped(to: businessCard.extent)
        
        return businessCard
    }
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let image = CIImage(cvImageBuffer: imageBuffer)
        let res = performRectangleDetection(image: image)
        let tmp = UIImage(ciImage: res!)
        
        let newImage = UIImage(ciImage: res!, scale: tmp.scale , orientation: .up)
        
        
//        let newImage = UIImage(cgImage: res!.cgImage!, scale: res.scale, orientation: .up)
        
        DispatchQueue.main.async {
            self.imageView.image = newImage
        }
        
        
//        print(image)
        
//        let detector = prepareRectangleDetector()
        
//        print(detector)
        
        
        
        let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.6, CIDetectorMaxFeatureCount: 10] )!

        var halfPerimiterValue = 0.0 as Float;
        let features = detector.features(in: image)
        print("feature \(features.count)")
//
        for feature in features as! [CIRectangleFeature] {
            let p1 = feature.topLeft
            let p2 = feature.topRight
            let width = hypotf(Float(p1.x - p2.x), Float(p1.y - p2.y))

            let p3 = feature.topLeft
            let p4 = feature.bottomLeft
            let height = hypotf(Float(p3.x - p4.x), Float(p3.y - p4.y))
            let currentHalfPerimiterValue = height+width


            print("width: \(width), height: \(height)")
            print("x: \(p1.x), y: \(p1.y)")

//            DispatchQueue.main.sync {
//                let size = CGSize(width: CGFloat(width), height: CGFloat(height))
//                let origin = CGPoint(x: p1.x,
//                                     y: p1.y)
//
//                let rect = CGRect(origin: origin, size: size)
//
//                print("fdsafa")
//                self.displayRect(rect: rect)
//            }
        
            
            
            
//            if (halfPerimiterValue < currentHalfPerimiterValue)
//            {
//                halfPerimiterValue = currentHalfPerimiterValue
//
//                var overlay = CIImage(color: CIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5))
//                overlay = overlay.cropped(to: image.extent)
//                overlay = overlay.applyingFilter("CIPerspectiveTransformWithExtent",
//                                                 parameters: [
//                                                    "inputExtent": CIVector(cgRect: image.extent),
//                                                    "inputTopLeft": CIVector(cgPoint: feature.topLeft),
//                                                    "inputTopRight": CIVector(cgPoint: feature.topRight),
//                                                    "inputBottomLeft": CIVector(cgPoint: feature.bottomLeft),
//                                                    "inputBottomRight": CIVector(cgPoint: feature.bottomRight)
//                    ])
//                resultImage = drawHighlightOverlayForPoints(image: image, topLeft: feature.topLeft, topRight: feature.topRight, bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)

//                                resultImage = cropBusinessCardForPoints(image: image, topLeft: feature.topLeft, topRight: feature.topRight,
//                                                                        bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
//                print("perimmeter   \(halfPerimiterValue)")
            }
//        }
        
        
        
//        for feature in rectDetector.features(in: image, options: nil) {
//            guard let rectFeature = feature as? CIRectangleFeature else { continue }
//
//            let imageWidth = image.extent.width
//            let imageHeight = image.extent.height
//            let imageSize = image.extent.size
//
//
//
//
//            let p1 = rectFeature.topLeft
//            let p2 = rectFeature.topRight
//            let width = hypotf(Float(p1.x - p2.x), Float(p1.y - p2.y))
//
//            let p3 = rectFeature.topLeft
//            let p4 = rectFeature.bottomLeft
//            let height = hypotf(Float(p3.x - p4.x), Float(p3.y - p4.y))
//
//            print("imageWidth: \(imageWidth), imageHeight: \(imageHeight)")
//
//            DispatchQueue.main.sync {
//                let imageScale = min(view.frame.size.width / imageWidth,
//                                     view.frame.size.height / imageHeight)
//
//                let widthScale = view.frame.size.width / imageWidth
//                let heightScale = view.frame.size.height / imageHeight
//                print("iWidth: \(widthScale), Height: \(heightScale)")
//                print("imageScale : \(imageScale)")
//                let origin = CGPoint(x: rectFeature.topLeft.x * imageScale,
//                                     y: rectFeature.topLeft.y * imageScale)
//
//                print("rect x : \(rectFeature.topLeft.x), rect y: \(rectFeature.topLeft.y )")
//                let size = CGSize(width: rectFeature.bounds.size.width,
//                                  height: rectFeature.bounds.size.height)
//
//                print("size x: \(rectFeature.bounds.size.width) , y: \(rectFeature.bounds.size.height)")
//
//                let rect = CGRect(origin: origin, size: size)
//                self.displayRect(rect: rect)
        
//                let topLeft = rectFeature.topLeft.scaled(to: imageSize)
//                let topRight = rectFeature.topRight.scaled(to: imageSize)
//                let bottomLeft = rectFeature.bottomLeft.scaled(to: imageSize)
//                let bottomRight = rectFeature.bottomRight.scaled(to: imageSize)
//
//                var overlay = CIImage(color: CIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5))
//                overlay = overlay.cropped(to: image.extent)
//                overlay = overlay.applyingFilter("CIPerspectiveTransformWithExtent",
//                                                 parameters: [
//                                                    "inputExtent": CIVector(cgRect: image.extent),
//                                                    "inputTopLeft": CIVector(cgPoint: topLeft),
//                                                    "inputTopRight": CIVector(cgPoint: topRight),
//                                                    "inputBottomLeft": CIVector(cgPoint: bottomLeft),
//                                                    "inputBottomRight": CIVector(cgPoint: bottomRight)
//                    ])
//
//                overlay.composited(over: image)
//            }
//        }
 
     }
}
