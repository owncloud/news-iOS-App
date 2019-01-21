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
        self.titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        self.dateLabel.font = self.makeItalic(font: UIFont.preferredFont(forTextStyle: .subheadline))
        self.summaryLabel.font = self.makeSmaller(font: UIFont.preferredFont(forTextStyle: .body))
                
        self.titleLabel.text = item.title?.convertingHTMLToPlainText() ?? ""
        var dateLabelText = ""
        let date = Date(timeIntervalSince1970: TimeInterval(item.pubDate))
        let currentLocale = Locale.current
        let dateComponents = "MMM d"
        let dateFormatString = DateFormatter.dateFormat(fromTemplate: dateComponents, options: 0, locale: currentLocale)
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = dateFormatString
        dateLabelText = dateLabelText + dateFormat.string(from: date)

        if dateLabelText.count > 0 {
            dateLabelText = dateLabelText  + " | "
        }
                
        if let author = item.author {
            if author.count > 0 {
                let clipLength = UIDevice.current.userInterfaceIdiom == .pad ? 50 : 25
                if author.count > clipLength {
                    dateLabelText = dateLabelText + author.prefix(clipLength) + "…"
                } else {
                    dateLabelText = dateLabelText + author
                }
            }
        }
        if let feed = OCNewsHelper.shared().feed(withId: Int(item.feedId)) {            
            if UserDefaults.standard.bool(forKey: "ShowFavicons") == true {
                OCNewsHelper.shared().faviconForFeed(withId: Int(feed.myId), imageView: self.favIconImage)
                self.favIconImage.isHidden = false
            }
            else {
                self.favIconImage.isHidden = true
                self.dateLabelLeadingConstraint.constant = 0.0;
            }
            
            if let title = feed.title {
                if let author = item.author, author.count > 0 {
                    if title != author {
                        dateLabelText = dateLabelText + " | "
                    }
                }
                dateLabelText = dateLabelText + title
            }
        }
        self.dateLabel.text = dateLabelText;
                
        if var summary = item.body {
            if summary.range(of: "<style>", options: .caseInsensitive) != nil {
                if summary.range(of: "</style>", options: .caseInsensitive) != nil {
                    if let start = summary.range(of:"<style>", options: .caseInsensitive)?.lowerBound , let end = summary.range(of: "</style>", options: .caseInsensitive)?.upperBound {
                        let sub = summary[start..<end]
                        summary = summary.replacingOccurrences(of: sub, with: "")
                    }
                }
            }
            self.summaryLabel.text = summary.convertingHTMLToPlainText()
            self.starImage.image = nil;
            if item.starred {
                self.starImage.image = UIImage(named: "star_icon")
            }
            if item.unread == true {
                self.summaryLabel.setThemeTextColor(PHThemeManager.shared().unreadTextColor)
                self.titleLabel.setThemeTextColor(PHThemeManager.shared().unreadTextColor)
                self.dateLabel.setThemeTextColor(PHThemeManager.shared().unreadTextColor)
                self.favIconImage.alpha = 1.0
            } else {
                self.summaryLabel.setThemeTextColor(UIColor.readText())
                self.titleLabel.setThemeTextColor(UIColor.readText())
                self.dateLabel.setThemeTextColor(UIColor.readText())
                self.favIconImage.alpha = 0.4
            }
            self.summaryLabel.highlightedTextColor = self.summaryLabel.textColor;
            self.titleLabel.highlightedTextColor = self.titleLabel.textColor;
            self.dateLabel.highlightedTextColor = self.dateLabel.textColor;
        }
        self.isHighlighted = false
    }

}
