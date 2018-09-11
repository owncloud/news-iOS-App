//
//  ArticleCellWithThumbnail.swift
//  iOCNews
//
//  Created by Peter Hedlund on 9/3/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import UIKit

class ArticleCellWithThumbnail: ArticleCellNoThumbnail {
    
    @IBOutlet var thumbnailContainerView: UIView!
    @IBOutlet var articleImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func configureView() {
        super.configureView()
        guard let item = self.item else {
            return
        }
        
        if let link = item.imageLink, let url = URL(string: link) {
            self.articleImage.setImageWith(url)
            if item.unread == true {
                self.articleImage.alpha = 1.0
            } else {
                self.articleImage.alpha = 0.4
            }
        }
    }

}
