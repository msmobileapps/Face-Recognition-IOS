//
//  ViewController.swift
//  FaceRecognition
//
//  Created by Daniel Radshun on 25/11/2019.
//  Copyright © 2019 Daniel Radshun. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var faceView: FaceView!
    
    var videoPreview = AVCaptureVideoPreviewLayer()
    var sequenceHandler = VNSequenceRequestHandler()
    
    //creating session
    let session = AVCaptureSession()
    
    lazy var accessDeniedAlert: UIAlertController = {
        let ac = UIAlertController(title: "Access Denied", message: "To use the face regognition you must authorize the app using your camera", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Go To Settings", style: .default, handler: { (_) in
            DispatchQueue.main.async {
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {return}
                
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            
        }))
        return ac
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //check if the access to the camera is granted
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] response in
            //must run on main thread
            DispatchQueue.main.async {
                if response {
                    //access granted - set up and start the camera session
                    self?.setUpCaptureSession()
                } else {
                    //access denied - show alert
                    self?.present(self!.accessDeniedAlert, animated: true)
                }
            }
        }
        
    }
    
    let dataOutputQueue = DispatchQueue(
    label: "video data queue",
    qos: .userInitiated,
    attributes: [],
    autoreleaseFrequency: .workItem)
    
    fileprivate func setUpCaptureSession() {
        if let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front){
            
            do{
                let input = try AVCaptureDeviceInput(device: captureDevice)
                session.addInput(input)
            } catch{
                print(error.localizedDescription)
            }
            
            let output = AVCaptureVideoDataOutput()
            session.addOutput(output)
            
            output.setSampleBufferDelegate(self, queue: dataOutputQueue)
            
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            let videoConnection = output.connection(with: .video)
            videoConnection?.videoOrientation = .portrait
            
            videoPreview = AVCaptureVideoPreviewLayer(session: session)
            videoPreview.frame = view.layer.bounds
            
            view.layer.addSublayer(videoPreview)
            
            session.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request, error) in
            
            if error != nil {
                print("FaceDetection error: \(String(describing: error)).")
            }
            
            guard let faceDetectionRequest = request as? VNDetectFaceLandmarksRequest,
                let results = faceDetectionRequest.results as? [VNFaceObservation] else {
                    return
            }
            DispatchQueue.main.async { [unowned self] in

                if let face = results.first  {
                    self.updateFaceView(for: face)
                }
                else{
                    self.faceView.clearDrawings()
                }
                                
                self.view.bringSubviewToFront(self.faceView)
            }
            
        })
        
        do {
            try sequenceHandler.perform(
                [faceDetectionRequest],
                on: imageBuffer,
                orientation: .leftMirrored)
        } catch {
            print(error.localizedDescription)
        }

    }
    
    func convertToLayerPoint(rect: CGRect) -> CGRect {
        //start point
        let startPoint = videoPreview.layerPointConverted(fromCaptureDevicePoint: rect.origin)

        //end point
        let endPoint = videoPreview.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: rect.size.width, y: rect.size.height))

        return CGRect(origin: startPoint, size: CGSize(width: endPoint.x, height: endPoint.y))
    }

    func pointsToDrawFrom(points: [CGPoint]?, to boundingBoxRect: CGRect) -> [CGPoint]? {
        guard let points = points else {
            return nil
        }
        
        return points.compactMap { makeDrawableLandmarkOnLayer(point: $0, rect: boundingBoxRect) }
    }
    
    func makeDrawableLandmarkOnLayer(point: CGPoint, rect: CGRect) -> CGPoint{
        //make points from landmark points to something that can be drawn on the current layer

        let drowablePoint = CGPoint(x: point.x * rect.size.width + rect.origin.x, y: point.y * rect.size.height + rect.origin.y)
        
        return videoPreview.layerPointConverted(fromCaptureDevicePoint: drowablePoint)
    }
    
    func updateFaceView(for result: VNFaceObservation) {

        let boundingBox = result.boundingBox
        //convert boundingBox into points in the current layer and setting the FaceView parameter so the draw func will draw a box
        faceView.boundingBox = convertToLayerPoint(rect: boundingBox)

        guard let landmarks = result.landmarks else {
            return
        }
        
        if let rightEye = pointsToDrawFrom(points: landmarks.rightEye?.normalizedPoints, to: boundingBox) {
            faceView.rightEye = rightEye
        }

        if let leftEye = pointsToDrawFrom(points: landmarks.leftEye?.normalizedPoints, to: boundingBox) {
            faceView.leftEye = leftEye
        }
        
        if let rightEyebrow = pointsToDrawFrom(points: landmarks.rightEyebrow?.normalizedPoints, to: boundingBox) {
            faceView.rightEyebrow = rightEyebrow
        }

        if let leftEyebrow = pointsToDrawFrom(points: landmarks.leftEyebrow?.normalizedPoints, to: boundingBox) {
            faceView.leftEyebrow = leftEyebrow
        }
        
        if let faceContour = pointsToDrawFrom(points: landmarks.faceContour?.normalizedPoints, to: result.boundingBox) {
            faceView.faceContour = faceContour
        }

        if let nose = pointsToDrawFrom(points: landmarks.nose?.normalizedPoints, to: result.boundingBox) {
            faceView.nose = nose
        }

        if let outerLips = pointsToDrawFrom(points: landmarks.outerLips?.normalizedPoints, to: result.boundingBox) {
            faceView.outerLips = outerLips
        }

        if let innerLips = pointsToDrawFrom(points: landmarks.innerLips?.normalizedPoints, to: result.boundingBox) {
            faceView.innerLips = innerLips
        }
        
        DispatchQueue.main.async {
          self.faceView.setNeedsDisplay()
        }
    }

}

