//
//  AspectFillImageView.swift
//  CloudNews
//
//  Created by Peter Hedlund on 12/28/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Cocoa

@IBDesignable
class AspectFillImageView: NSImageView {

    @IBInspectable
    var scaleAspectFill : Bool = false

    override func awakeFromNib() {
        // Scaling : .scaleNone mandatory
        if scaleAspectFill {
            self.imageScaling = .scaleNone
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        if scaleAspectFill, let myImage = self.image {
            // Compute new Size
            let imageRatio = myImage.size.height / myImage.size.width
            let viewRatio = self.bounds.size.height / self.bounds.size.width
            var newWidth = myImage.size.width
            var newHeight = myImage.size.height

            if imageRatio > viewRatio {
                newWidth = self.bounds.size.width
                newHeight = self.bounds.size.width * imageRatio
            } else {
                newWidth = self.bounds.size.height / imageRatio
                newHeight = self.bounds.size.height
            }

            self.image?.size.width  = newWidth
            self.image?.size.height = newHeight
        }
        // Draw AFTER resizing
        super.draw(dirtyRect)
    }

}
