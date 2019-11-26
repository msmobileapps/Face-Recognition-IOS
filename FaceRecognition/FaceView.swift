//
//  FaceRectangle.swift
//  FaceRecognition
//
//  Created by Daniel Radshun on 25/11/2019.
//  Copyright © 2019 Daniel Radshun. All rights reserved.
//

import UIKit
import CoreGraphics

class FaceView: UIView {
    
    var boundingBox = CGRect.zero

    var rightEye: [CGPoint] = []
    var leftEye: [CGPoint] = []
    var rightEyebrow: [CGPoint] = []
    var leftEyebrow: [CGPoint] = []
    var faceContour: [CGPoint] = []
    var nose: [CGPoint] = []
    var outerLips: [CGPoint] = []
    var innerLips: [CGPoint] = []
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            print("Context not found")
            return
        }
       
        context.saveGState()
        
        //add blue rect around the face
        context.addRect(boundingBox)
        UIColor.blue.setStroke()

        context.strokePath()

        UIColor.green.setStroke()

        if !rightEye.isEmpty {
          context.addLines(between: rightEye)
          context.closePath()
          context.strokePath()
        }

        if !leftEye.isEmpty {
          context.addLines(between: leftEye)
          context.closePath()
          context.strokePath()
        }

        UIColor.white.setStroke()

        if !rightEyebrow.isEmpty {
          context.addLines(between: rightEyebrow)
          context.strokePath()
        }

        if !leftEyebrow.isEmpty {
          context.addLines(between: leftEyebrow)
          context.strokePath()
        }

        if !nose.isEmpty {
          context.addLines(between: nose)
          context.strokePath()
        }

        if !faceContour.isEmpty {
          context.addLines(between: faceContour)
          context.strokePath()
        }

        UIColor.red.setStroke()

        if !outerLips.isEmpty {
          context.addLines(between: outerLips)
          context.closePath()
          context.strokePath()
        }

        if !innerLips.isEmpty {
          context.addLines(between: innerLips)
          context.closePath()
          context.strokePath()
        }
        
        //MSApps logo
        if !leftEyebrow.isEmpty {
            let point = CGPoint(x: leftEyebrow.first!.x + 20, y: leftEyebrow.first!.y - 40)
            drawImage(point: point)
        }
        
        context.restoreGState()
    }
    
    func drawImage(point:CGPoint) {

        let mouse = UIImage(named: "ms-c-logo")
        mouse?.draw(at: point)
    }
    
    func clearDrawings() {
        boundingBox = .zero

        rightEye = []
        leftEye = []
        rightEyebrow = []
        leftEyebrow = []
        faceContour = []
        nose = []
        outerLips = []
        innerLips = []
            
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }
}
