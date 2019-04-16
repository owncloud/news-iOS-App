//
//  ItemProvider.swift
//  iOCNews
//
//  Created by Peter Hedlund on 2/14/19.
//  Copyright © 2019 Peter Hedlund. All rights reserved.
//

import Foundation
import AFNetworking

@objcMembers
class ItemProviderStruct: NSObject {
    var myID: Int = -1
    var title: String?
    var author: String?
    var pubDate: Int = 0
    var body: String?
    var feedId: Int = -1
    var starred: Bool = false
    var unread: Bool = true
    var imageLink: String?
    var favIconLink: String?
    var readable: String?
    var url: String?

    var feedTitle: String?
    var feedPreferWeb: Bool = false
    var feedUseReader: Bool = false
    
    override init() { }
}


@objcMembers
class ItemProvider: NSObject {
    
    var item: ItemProviderStruct
    
    let titleFont = UIFont.preferredFont(forTextStyle: .headline)
    
    var dateFont: UIFont {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        let desc = font.fontDescriptor
        if let italic = desc.withSymbolicTraits(.traitItalic) {
            return UIFont(descriptor: italic, size: 0.0)
        }
        return font
    }
    
    var summaryFont: UIFont {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let desc = font.fontDescriptor
        let smaller = desc.withSize(desc.pointSize - 1)
        return UIFont(descriptor: smaller, size: 0.0)
    }
    
    var title: String = ""
    var dateText: String = ""
    var summaryText: String = ""
    
    var titleColor: UIColor = .black
    var dateColor: UIColor = .black
    var summaryColor: UIColor = .black
    
    var favIcon: UIImage?
    var favIconHidden: Bool = false
    var imageAlpha: CGFloat = 1.0
    
    var thumbnail: UIImage?
    
    var starIcon: UIImage?
    
    var url: String?
    var starred: Bool = false
    var unread: Bool = true
    var myId: Int = -1
    var favIconLink: String?
    var feedTitle: String?
    var imageLink: String?
    
    init(item: ItemProviderStruct) {
        self.item = item
        super.init()
    }
    
    func configure() {
        self.url = item.url
        self.starred = item.starred
        self.unread = item.unread
        self.myId = item.myID
        self.favIconLink = item.favIconLink
        self.feedTitle = item.feedTitle
        self.imageLink = item.imageLink

        if let link = item.imageLink, let url = URL(string: link) {
            let request = URLRequest(url: url)
            AFImageDownloader.defaultInstance().downloadImage(for: request, success: { [weak self] (_, _, image) in
                self?.thumbnail = image
                }, failure: nil)
        }

        if UserDefaults.standard.bool(forKey: "ShowFavicons") == true {
            if let link = self.favIconLink, link != "favicon", let url = URL(string: link) {
                let request = URLRequest(url: url)
                AFImageDownloader.defaultInstance().downloadImage(for: request, success: { [weak self] (_, _, image) in
                    self?.favIcon = image
                    self?.favIconHidden = false
                    }, failure: { [weak self] (_, _, _) in
                        self?.favIconHidden = false
                        self?.favIcon = UIImage(named: "favicon")
                })
            } else {
                self.favIconHidden = false
                self.favIcon = UIImage(named: "favicon")
            }
        }
        else {
            self.favIconHidden = true
        }

        let title = item.title
        self.title = title?.convertingHTMLToPlainText() ?? ""
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
                    dateLabelText = dateLabelText + author.prefix(clipLength)
                } else {
                    dateLabelText = dateLabelText + author
                }
            }
        }
        
        if let title = self.feedTitle {
            if let author = item.author, author.count > 0 {
                if title != author {
                    dateLabelText = dateLabelText + " | "
                }
            }
            dateLabelText = dateLabelText + title
        }
        self.dateText = dateLabelText
        
        
        if var summary = item.body {
            if summary.range(of: "<style>", options: .caseInsensitive) != nil {
                if summary.range(of: "</style>", options: .caseInsensitive) != nil {
                    if let start = summary.range(of:"<style>", options: .caseInsensitive)?.lowerBound , let end = summary.range(of: "</style>", options: .caseInsensitive)?.upperBound {
                        let sub = summary[start..<end]
                        summary = summary.replacingOccurrences(of: sub, with: "")
                    }
                }
            }
            self.summaryText = summary.convertingHTMLToPlainText()
            if item.starred {
                self.starIcon = UIImage(named: "star_icon")
            }
            if item.unread == true {
                self.summaryColor = PHThemeManager.shared().unreadTextColor
                self.titleColor = PHThemeManager.shared().unreadTextColor
                self.dateColor = PHThemeManager.shared().unreadTextColor
                self.imageAlpha = 1.0
            } else {
                self.summaryColor = UIColor.readText()
                self.titleColor = UIColor.readText()
                self.dateColor = UIColor.readText()
                self.imageAlpha = 0.4
            }
        }
        
    }
}
