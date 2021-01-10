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
        result.mediaTypesRequiringUserActionForPlayback = [.all]
        return result
    }

    private var internalWebView: WKWebView?
    @objc var webView: WKWebView? {
        get {
            if internalWebView == nil {
                internalWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), configuration: self.webConfig)
                if let result = internalWebView {
                    result.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
                    result.isOpaque = false
                    result.backgroundColor = UIColor.clear
                }
            }
            internalWebView?.scrollView.backgroundColor = UIColor.ph_background
            return internalWebView
        }
        set(newValue) {
            internalWebView = newValue
        }
    }
    
    @objc func addWebView() {
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 12.0, *) {
            if (self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle) {
                configureView()
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func configureView() {
        super.configureView()
        guard let item = self.item else {
            return
        }
        self.bottomBorder.removeFromSuperlayer()
        self.addWebView()
        if item.item.feedPreferWeb == true {
            if item.item.feedUseReader == true {
                if let readable = item.item.readable, readable.count > 0 {
                    self.writeAndLoadHtml(html: readable, feedTitle: item.feedTitle)
                } else {
                    if let urlString = item.url {
                        OCAPIClient.shared().requestSerializer = OCAPIClient.httpRequestSerializer()
                        OCAPIClient.shared().get(urlString, parameters: nil, headers: nil, progress: nil, success: { (task, responseObject) in
                            var html: String
                            if let response = responseObject as? Data, let source = String.init(data: response, encoding: .utf8), let url = task.response?.url {
                                if let article = ArticleHelper.readble(html: source, url: url) {
                                    html = article
                                } else {
                                    html = "<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>"
                                    if let body = item.item.body {
                                        html = html + body
                                    }
                                }
                            } else {
                                html = "<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>"
                                if let body = item.item.body {
                                    html = html + body
                                }
                            }
                            self.writeAndLoadHtml(html: html, feedTitle: item.feedTitle)
                        }) { (task, error) in
                            var html = "<p style='color: #CC6600;'><i>(There was an error downloading the article. Showing summary instead.)</i></p>"
                            if let body = item.item.body {
                                html = html + body
                            }
                            self.writeAndLoadHtml(html: html, feedTitle: item.feedTitle)
                        }
                    }
                }
            } else {
                if let url = URL(string: item.url ?? "") {
                    self.webView?.load(URLRequest(url: url))
                }
            }
        } else {
            if var html = item.item.body,
                let urlString = item.url,
                let url = URL(string: urlString) {
                let baseString = "\(url.scheme ?? "")://\(url.host ?? "")"
                if baseString.range(of: "youtu", options: .caseInsensitive) != nil {
                    if html.range(of: "iframe", options: .caseInsensitive) != nil {
                        html = ArticleHelper.createYoutubeItem(html: html, urlString: urlString)
                    } else if let urlString = item.url, urlString.contains("watch?v="), let equalIndex = urlString.firstIndex(of: "=") {
                        let videoIdStartIndex = urlString.index(after: equalIndex)
                        let videoId = String(urlString[videoIdStartIndex...])
                        let screenSize = UIScreen.main.nativeBounds.size
                        let margin = UserDefaults.standard.integer(forKey: "MarginPortrait")
                        let currentWidth = Double(screenSize.width / UIScreen.main.scale) * (Double(margin) / 100.0)
                        let newheight = currentWidth * 0.5625
                        let embed = "<embed id=\"yt\" src=\"http://www.youtube.com/embed/\(videoId)?playsinline=1\" type=\"text/html\" frameborder=\"0\" width=\"\(Int(currentWidth))px\" height=\"\(Int(newheight))px\"></embed>"
                        html = embed
                    }
                }
                html = ArticleHelper.fixRelativeUrl(html: html, baseUrlString: baseString)
                self.writeAndLoadHtml(html: html, feedTitle: item.feedTitle)
            }
        }      
    }
    
    func writeAndLoadHtml(html: String, feedTitle: String? = nil) {
        guard let item = self.item?.item else {
            return
        }
        if let url = ArticleHelper.writeAndLoadHtml(html: html, item: item, feedTitle: feedTitle) {
            self.webView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

}
