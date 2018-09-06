//
//  ArticleCellWithThumbnail.swift
//  iOCNews
//
//  Created by Peter Hedlund on 9/3/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import UIKit

class ArticleCellWithThumbnail: NoThumbnailArticleCell {
    
    @IBOutlet var thumbnailContainerView: UIView!
    @IBOutlet var articleImage: UIImageView!
    @IBOutlet var thumbnailContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var articleImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet var contentContainerLeadingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func configureView() {
        super.configureView()
        guard let item = self.item else {
            return
        }
    
        if UserDefaults.standard.bool(forKey: "ShowThumbnails") == true {
            if let link = item.imageLink, let url = URL(string: link) {
                self.articleImage.setImageWith(url)
                self.articleImage.isHidden = false
                self.thumbnailContainerWidthConstraint.constant = self.articleImage.frame.size.width
                self.articleImageWidthConstraint.constant = self.articleImage.frame.size.width
                self.contentContainerLeadingConstraint.constant = self.articleImage.frame.size.width
                if item.unread == true {
                    self.articleImage.alpha = 1.0
                } else {
                    self.articleImage.alpha = 0.4
                }
            } else {
                self.articleImage.isHidden = true
                self.thumbnailContainerWidthConstraint.constant = 0.0
                self.articleImageWidthConstraint.constant = 0.0
                self.contentContainerLeadingConstraint.constant = 0.0
            }

        } else {
            self.articleImage.isHidden = false
            self.thumbnailContainerWidthConstraint.constant = 0.0
            self.articleImageWidthConstraint.constant = 0.0
            self.contentContainerLeadingConstraint.constant = 0.0
        }
    }
}
