//
//  ArticleCellView.swift
//  CloudNews
//
//  Created by Peter Hedlund on 11/10/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Cocoa
import SwiftSoup
import Kingfisher

class ArticleCellView: NSTableCellView {
    
    @IBOutlet var thumbnailImage: NSImageView!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var authorLabel: NSTextField!
    @IBOutlet var faviconImage: NSImageView!
    @IBOutlet var summaryLabel: NSTextField!
    @IBOutlet var starImage: NSImageView!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        self.thumbnailImage.wantsLayer = true
        self.thumbnailImage.canDrawSubviewsIntoLayer = true
        self.thumbnailImage.layer?.cornerRadius = 14.0
        self.thumbnailImage.layer?.masksToBounds = true
    }
    
    var item: ItemProtocol? {
        didSet {
            if let item = self.item {
                self.thumbnailImage.image = nil
                if let incoming = item.title {
                    self.titleLabel?.stringValue = self.plainSummary(raw: incoming)
                } else {
                    self.titleLabel?.stringValue = "No Title"
                }

                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .long
                
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
                        let clipLength =  50
                        if author.count > clipLength {
                            dateLabelText = dateLabelText + author.prefix(clipLength) + "…"
                        } else {
                            dateLabelText = dateLabelText + author
                        }
                    }
                }
                
                if let feed = CDFeed.feed(id: item.feedId) {
                    self.faviconImage.image = nil
                    if let faviconLink = feed.faviconLink, let url = URL(string: faviconLink) {
                        self.faviconImage.kf.setImage(with: url, placeholder: NSImage(named: "All Articles"))
                    } else {
                        self.faviconImage.image = NSImage(named: "All Articles")
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
                self.authorLabel.stringValue = dateLabelText;
                
                if var summary = item.body {
                    if summary.range(of: "<style>", options: .caseInsensitive) != nil {
                        if summary.range(of: "</style>", options: .caseInsensitive) != nil {
                            if let start = summary.range(of:"<style>", options: .caseInsensitive)?.lowerBound,
                                let end = summary.range(of: "</style>", options: .caseInsensitive)?.upperBound {
                                let sub = summary[start..<end]
                                summary = summary.replacingOccurrences(of: sub, with: "")
                            }
                        }
                    }
                    self.summaryLabel.stringValue = self.plainSummary(raw: summary)
                    
                    if let imageURL = self.imageURL(summary: summary) {
                        let processor = ResizingImageProcessor(referenceSize: CGSize(width: 72, height: 72), mode: .aspectFill)
                        self.thumbnailImage.kf.setImage(with: imageURL, placeholder: nil, options: [.processor(processor)])
                    }
                    
                    if item.unread == true {
                        self.alphaValue = 1.0
                    } else {
                        self.alphaValue = 0.5
                    }
                    let localRead = CDRead.all()?.contains(item.id) ?? false
                    if localRead == true {
                        self.alphaValue = 0.5
                    }
                    
                    if item.starred == true {
                        self.starImage.image = NSImage(named: "star_icon")
                    } else {
                        self.starImage.image = nil
                    }
                }
            }
        }
    }
    
    func plainSummary(raw: String) -> String {
        guard let doc: Document = try? SwiftSoup.parse(raw) else {
            return raw
        } // parse html
        guard let txt = try? doc.text() else {
            return raw
        }
       return txt
    }
    
    func imageURL(summary: String) -> URL? {
        guard let doc: Document = try? SwiftSoup.parse(summary) else {
            return nil
        } // parse html
        do {
            let srcs: Elements = try doc.select("img[src]")
            let srcsStringArray: [String?] = srcs.array().map { try? $0.attr("src").description }
            if let firstString = srcsStringArray.first, let urlString = firstString, let url = URL(string: urlString) {
                return url
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch {
            print("error")
            
        }
        return nil
    }
    
}
