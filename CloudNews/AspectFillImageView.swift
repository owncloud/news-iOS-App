//
//  AspectFillImageView.swift
//  CloudNews
//
//  Created by Peter Hedlund on 11/18/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Cocoa

class AspectFillImageView: NSImageView {

    open override var image: NSImage? {
        set {
            self.layer = CALayer()
            self.layer?.contentsGravity = .resizeAspectFill
            self.layer?.contents = newValue
            self.wantsLayer = true
            super.image = newValue
        }
        get {
            return super.image
        }
    }
    
}
