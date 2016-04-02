//
//  ShareCameraViewController.swift
//  Fandomm
//
//  Created by Simon Narang on 12/21/15.
//  Copyright © 2015 Simon Narang. All rights reserved.
//

import UIKit
import AVFoundation

class ShareCameraViewController: UIViewController, /* For capturing barcodes */AVCaptureMetadataOutputObjectsDelegate {
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    var userFandoms = [AnyObject]()
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let devices = AVCaptureDevice.devices()
        func beginSession() {
            
        }
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        print("Capture device found")
                        beginSession()
                    }
                }
            }
        }
    }
}