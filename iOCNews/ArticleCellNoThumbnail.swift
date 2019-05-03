//
//  ArticleCellNoThumbnail.swift
//  iOCNews
//
//  Created by Peter Hedlund on 9/1/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import UIKit
import CoreImage

class ArticleCellNoThumbnail: BaseArticleCell {

    override func configureView() {
        super.configureView()
        guard let item = self.item else {
            return
        }
        
        self.titleLabel.font = item.titleFont
        self.dateLabel.font = item.dateFont
        self.summaryLabel.font = item.summaryFont
                
        self.titleLabel.text = item.title
        self.dateLabel.text = item.dateText
        self.summaryLabel.text = item.summaryText
        
        self.titleLabel.setThemeTextColor(item.titleColor)
        self.dateLabel.setThemeTextColor(item.dateColor)
        self.summaryLabel.setThemeTextColor(item.summaryColor)
        
        self.titleLabel.highlightedTextColor = self.titleLabel.textColor;
        self.dateLabel.highlightedTextColor = self.dateLabel.textColor;
        self.summaryLabel.highlightedTextColor = self.summaryLabel.textColor;

        if item.favIconHidden {
            self.favIconImage.isHidden = true
            self.dateLabelLeadingConstraint.constant = 0.0;
        } else {
            self.favIconImage.image = item.favIcon
            self.favIconImage.isHidden = false
            self.favIconImage.alpha = item.imageAlpha
        }

        self.starImage.image = item.starIcon

        self.isHighlighted = false
    }

}
