//
//  WaveformVisualizerView.swift
//  Chattie
//
//  Created by Ryohei Fushimi on 2016/2/11.
//  Copyright © 2016 R. Fushimi and S. Murakami. All rights reserved.
//


import Cocoa
import AppKit


// volume: 波形の縦幅 size: 横のサイズ

class WaveformVisualizerView: NSView {

    var volume: Double = 1.0
    var size: Double = 1.0
    var dummy = false
    
    var samples: [Double] = []
    
    var active = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NSLog("init coder")
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        NSLog("init frameRect")
        
    }
    
    override func drawRect(rect: NSRect) {
        super.drawRect(rect)

        //             trying to solve this error
        //                <Error>: Error: this application, or a library it uses, has passed an invalid numeric value (NaN, or not-a-number) to CoreGraphics API and this value is being ignored.Please fix this problem.
        if !volume.isFinite || !size.isFinite || !self.bounds.height.isFinite || size == 0 {
            return
        }
        
        let context = NSGraphicsContext.currentContext()?.CGContext
        if NSGraphicsContext.currentContext() == nil {
            AppUtil.alert("ERROR", message: "CGcontext is null")
        }
        
        let height:Double = Double(self.bounds.height)
        let width:Double = Double(self.bounds.width)
        var first = true
        
        for i in 0 ..< 256 {
            if first {
                CGContextMoveToPoint(context, 0, CGFloat(height/2.0))
                first = false
            } else {
                // random value from -1 to 1
                let randv = (Double(arc4random()) / Double(UINT32_MAX / 2) - 1) * volume
                let x = width*Double(i)/256.0
                let y = height/2.0 + gauss(Double(i), average: 128, distribution: 32 * size) * height * 32 * randv
                CGContextAddLineToPoint(context, CGFloat(x), CGFloat(y))
            }
        }
        
        CGContextSetStrokeColorWithColor(context, active ? NSColor.redColor().CGColor : NSColor.lightGrayColor().CGColor)
        CGContextStrokePath(context)
        CGContextFillPath(context)
        
        super.drawRect(rect)
    }

    func gauss(x: Double, average: Double, distribution:Double) -> Double{
        return exp(-pow(x - average, 2) / 2 / pow(distribution, 2)) / sqrt(2 * M_PI) / distribution
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
