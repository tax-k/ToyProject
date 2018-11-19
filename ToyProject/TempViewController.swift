//
//  TempViewController.swift
//  ToyProject
//
//  Created by tax_k on 19/11/2018.
//  Copyright © 2018 tax_k. All rights reserved.
//

import UIKit

class TempViewController: UIViewController {

    @IBOutlet var qrDecodeLabel: UILabel!
    @IBOutlet var detectorModeSelector: UISegmentedControl!
    
    var videoFilter: CoreImageVideoFilter?
    var detector: CIDetector?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Create the video filter
        videoFilter = CoreImageVideoFilter(superview: view, applyFilterCallback: nil)
        
        // Simulate a tap on the mode selector to start the process
        detectorModeSelector.selectedSegmentIndex = 0
        handleDetectorSelectionChange(detectorModeSelector)
    }
    
    @IBAction func handleDetectorSelectionChange(_ sender: UISegmentedControl) {
        if let videoFilter = videoFilter {
            videoFilter.stopFiltering()
            self.qrDecodeLabel.isHidden = true
            
            switch sender.selectedSegmentIndex {
            case 0:
                detector = prepareRectangleDetector()
                videoFilter.applyFilter = {
                    image in
                    return self.performRectangleDetection(image)
                }
            case 1:
                self.qrDecodeLabel.isHidden = false
                detector = prepareQRCodeDetector()
                videoFilter.applyFilter = {
                    image in
                    let found = self.performQRCodeDetection(image)
                    DispatchQueue.main.async {
                        if found.decode != "" {
                            self.qrDecodeLabel.text = found.decode
                        }
                    }
                    return found.outImage
                }
            default:
                videoFilter.applyFilter = nil
            }
            
            videoFilter.startFiltering()
        }
    }
    
    
    //MARK: Utility methods
    func performRectangleDetection(_ image: CIImage) -> CIImage? {
        var resultImage: CIImage?
        print("performRectangleDetection")
        
        if let detector = detector {
            // Get the detections
            let features = detector.features(in: image)
            for feature in features as! [CIRectangleFeature] {
                resultImage = drawHighlightOverlayForPoints(image, topLeft: feature.topLeft, topRight: feature.topRight,
                                                            bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
            }
        }
        return resultImage
    }
    
    func performQRCodeDetection(_ image: CIImage) -> (outImage: CIImage?, decode: String) {
        var resultImage: CIImage?
        var decode = ""
        if let detector = detector {
            let features = detector.features(in: image)
            for feature in features as! [CIQRCodeFeature] {
                resultImage = drawHighlightOverlayForPoints(image, topLeft: feature.topLeft, topRight: feature.topRight,
                                                            bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
                decode = feature.messageString!
            }
        }
        return (resultImage, decode)
    }
    
    func prepareRectangleDetector() -> CIDetector {
        let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.0]
        return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)!
    }
    
    func prepareQRCodeDetector() -> CIDetector {
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        return CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: options)!
    }
    
    func drawHighlightOverlayForPoints(_ image: CIImage, topLeft: CGPoint, topRight: CGPoint,
                                       bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        
        print("drawHighlightOverlayForPoints")
        
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
}
