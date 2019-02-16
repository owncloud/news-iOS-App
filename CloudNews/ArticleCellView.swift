//
//  ArticleCellView.swift
//  CloudNews
//
//  Created by Peter Hedlund on 11/10/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Cocoa
import Kingfisher

class ArticleCellView: NSTableCellView {
    
    @IBOutlet var thumbnailImage: NSImageView!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var authorLabel: NSTextField!
    @IBOutlet var faviconImage: NSImageView!
    @IBOutlet var summaryLabel: NSTextField!
    @IBOutlet var starImage: NSImageView!
    @IBOutlet weak var thumbnailImageWidthContraint: NSLayoutConstraint!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        self.thumbnailImage.wantsLayer = true
        self.thumbnailImage.canDrawSubviewsIntoLayer = true
        self.thumbnailImage.layer?.cornerRadius = 14.0
        self.thumbnailImage.layer?.masksToBounds = true
    }

    var item: CDItem? {
        didSet {
            if let item = self.item {
                self.thumbnailImage.image = nil
                if let imageURL = item.thumbnailURL {
                    let processor = ResizingImageProcessor(referenceSize: CGSize(width: 72, height: 72), mode: .aspectFill)
                    self.thumbnailImage.kf.setImage(with: imageURL, placeholder: nil, options: [.processor(processor)])
                    self.thumbnailImage.isHidden = false
                    self.thumbnailImageWidthContraint.constant = 72
                } else {
                    self.thumbnailImage.isHidden = true
                    self.thumbnailImageWidthContraint.constant = 0
                }
            }
        }
    }

}
