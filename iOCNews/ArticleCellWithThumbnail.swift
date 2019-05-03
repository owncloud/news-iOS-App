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
    
    override func configureView() {
        super.configureView()
        guard let item = self.item else {
            return
        }
        
        if (item.thumbnail != nil) {
            self.articleImage.image = item.thumbnail
        } else {
            if let link = item.imageLink, let url = URL(string: link) {
                let request = URLRequest(url: url)
                AFImageDownloader.defaultInstance().downloadImage(for: request, success: { [weak self] (_, _, image) in
                    self?.articleImage.image = image
                    }, failure: nil)
            }

        }

        self.articleImage.alpha = item.imageAlpha
    }

}
