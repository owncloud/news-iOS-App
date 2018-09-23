//
//  ArticleCellWithWebView.swift
//  iOCNews
//
//  Created by Peter Hedlund on 9/3/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import UIKit
import WebKit

class ArticleCellWithWebView: BaseArticleCell {
    
    var webConfig: WKWebViewConfiguration {
        let result = WKWebViewConfiguration()
        result.allowsInlineMediaPlayback = true
        result.requiresUserActionForMediaPlayback = true
        return result
    }

    var template: String? {
        if let source = Bundle.main.url(forResource: "rss", withExtension: "html") {
            return try? String(contentsOf: source, encoding: .utf8)
        }
        return nil
    }
    
    private var internalWebView: WKWebView?
    var webView: WKWebView? {
        get {
            if internalWebView == nil {
                internalWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), configuration: self.webConfig)
                if let result = internalWebView {
                    result.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
                    result.isOpaque = false
                    result.backgroundColor = UIColor.clear
                }
            }
            return internalWebView
        }
        set(newValue) {
            internalWebView = newValue
        }
    }
    
    func addWebView() {
        if let webView = self.webView {
            self.contentView.addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            
            let topConstraint = NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: 0.0)
            let leadingConstraint = NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1.0, constant: 0.0)
            let bottomConstraint = NSLayoutConstraint(item: self.contentView, attribute: .bottom, relatedBy: .equal, toItem: webView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
            let trailingConstraint = NSLayoutConstraint(item: self.contentView, attribute: .trailing, relatedBy: .equal, toItem: webView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
            self.contentView.addConstraints([topConstraint, leadingConstraint, bottomConstraint, trailingConstraint])
        }
    }
    
    override func prepareForReuse() {
        self.webView?.removeFromSuperview()
        self.webView?.navigationDelegate = nil
        self.webView?.uiDelegate = nil
        self.webView = nil
    }
    
    override func configureView() {
        super.configureView()
        guard let item = self.item else {
            return
        }
        self.addWebView()
        if let feed = OCNewsHelper.shared().feed(withId: Int(item.feedId)) {
            if feed.preferWeb == true {
                if feed.useReader == true {
                    if let readable = item.readable, readable.count > 0 {
                        self.writeAndLoadHtml(html: readable, feedTitle: feed.title)
                    } else {
                        if let urlString = item.url {
                            OCAPIClient.shared().requestSerializer = OCAPIClient.httpRequestSerializer()
                            OCAPIClient.shared().get(urlString, parameters: nil, progress: nil, success: { (task, responseObject) in
                                var html: String
                                if let response = responseObject as? Data, let source = String.init(data: response, encoding: .utf8), let url = task.response?.url {
                                    if let article = SummaryHelper.readble(source, url: url) {
                                        html = article
                                    } else {
                                        html = "<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>"
                                        if let body = item.body {
                                            html = html + body
                                        }
                                    }
                                    item.readable = html
                                    OCNewsHelper.shared().saveContext()
                                } else {
                                    html = "<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>"
                                    if let body = item.body {
                                        html = html + body
                                    }
                                }
                                self.writeAndLoadHtml(html: html, feedTitle: feed.title)
                            }) { (task, error) in
                                var html = "<p style='color: #CC6600;'><i>(There was an error downloading the article. Showing summary instead.)</i></p>"
                                if let body = item.body {
                                    html = html + body
                                }
                                self.writeAndLoadHtml(html: html, feedTitle: feed.title)
                            }
                        }
                    }
                } else {
                    if let url = URL(string: item.url ?? "") {
                        self.webView?.load(URLRequest(url: url))
                    }
                }
            } else {
                if var html = item.body {
                    if let url = URL(string: item.url ?? "") {
                        let baseString = "\(url.scheme ?? "")://\(url.host ?? "")"
                        if baseString.range(of: "youtu", options: .caseInsensitive) != nil {
                            if html.range(of: "iframe", options: .caseInsensitive) != nil {
                                html = SummaryHelper.createYoutubeItem(item)
                            }
                        }
                        html = SummaryHelper.fixRelativeUrl(html, baseUrlString: baseString)
                        self.writeAndLoadHtml(html: html, feedTitle: feed.title)
                    }
                }
            }
        }
    }
    
    func writeAndLoadHtml(html: String, feedTitle: String? = nil) {
        guard let item = self.item else {
            return
        }
        let summary = SummaryHelper.replaceYTIframe(html)
        if var htmlTemplate = self.template {
            var dateText = "";
            let dateNumber = TimeInterval(item.pubDate)
            let date = Date(timeIntervalSince1970: dateNumber)
            let dateFormat = DateFormatter()
            dateFormat.dateStyle = .medium;
            dateFormat.timeStyle = .short;
            dateText += dateFormat.string(from: date)
            
            if let feedTitle = feedTitle {
                htmlTemplate = htmlTemplate.replacingOccurrences(of: "$FeedTitle$", with: feedTitle)
            }
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleDate$", with: dateText)
            
            if let title = item.title {
                htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleTitle$", with: title)
            }
            if let url = item.url {
                htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleLink$", with: url)
            }
            var author = ""
            if let itemAuthor = item.author, itemAuthor.count > 0 {
                author = "By \(itemAuthor)"
            }
            
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleAuthor$", with: author)
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleSummary$", with: summary ?? html)
            
            do {
                let containerURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                var saveUrl = containerURL.appendingPathComponent("summary")
                saveUrl = saveUrl.appendingPathExtension("html")
                try htmlTemplate.write(to: saveUrl, atomically: true, encoding: .utf8)
                self.webView?.loadFileURL(saveUrl, allowingReadAccessTo: containerURL)
                
            } catch {
                //
            }
        }
    }

    func fileUrlInDocumentsDirectory(_ fileName: String, fileExtension: String) -> URL
    {
        do {
            var containerURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            containerURL = containerURL.appendingPathComponent(fileName)
            containerURL = containerURL.appendingPathExtension(fileExtension)
            return containerURL
        } catch {
            return URL.init(string: "")!
        }
    }

}
