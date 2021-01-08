//
//  ArticleCellWithThumbnail.swift
//  iOCNews
//
//  Created by Peter Hedlund on 9/3/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import UIKit
import Kingfisher

class ArticleCellWithThumbnail: ArticleCellNoThumbnail {
    
    @IBOutlet var thumbnailContainerView: UIView!
    @IBOutlet var articleImage: UIImageView!
    
    override func configureView() {
        super.configureView()
        guard let item = self.item else {
            return
        }
        
        if (item.thumbnail != nil) {
            self.articleImage.image = item.thumbnail
        } else {
            if let link = item.imageLink, let url = URL(string: link) {
                articleImage.kf.setImage(with: url)
            }
        }

        self.articleImage.alpha = item.imageAlpha
    }

}
