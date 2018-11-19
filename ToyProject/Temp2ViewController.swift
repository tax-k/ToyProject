//
//  Temp2ViewController.swift
//  ToyProject
//
//  Created by tax_k on 19/11/2018.
//  Copyright © 2018 tax_k. All rights reserved.
//

import UIKit
import CoreML
import Vision
import AVFoundation

class Temp2ViewController: UIViewController {
    
    private let session = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()

//        // Do any additional setup after loading the view.
//        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
//        do {
//            let deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
//        } catch {
//            print("Could not create video device input: \(error)")
//            return
//        }
//        
//        session.beginConfiguration()
//        session.sessionPreset = .vga640x480 // Model image size is smaller.
//        
//        guard session.canAddInput(deviceInput) else {
//            print("Could not add video device input to the session")
//            session.commitConfiguration()
//            return
//        }
//        session.addInput(deviceInput)
    }

}
