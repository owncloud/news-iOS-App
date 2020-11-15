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
    
    var htmlUrl: URL? {
        do {
            let containerURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            var saveUrl = containerURL.appendingPathComponent("summary")
            saveUrl = saveUrl.appendingPathExtension("html")
            return saveUrl
        } catch { }
        return nil
    }
    
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
                                if let article = SummaryHelper.readble(source, url: url) {
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
                        html = SummaryHelper.createYoutubeItem(html, andLink: urlString)
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
                html = SummaryHelper.fixRelativeUrl(html, baseUrlString: baseString)
                self.writeAndLoadHtml(html: html, feedTitle: item.feedTitle)
            }
        }      
    }
    
    func writeAndLoadHtml(html: String, feedTitle: String? = nil) {
        guard let item = self.item?.item else {
            return
        }
        let summary = SummaryHelper.replaceYTIframe(html)
        var dateText = "";
        let dateNumber = TimeInterval(item.pubDate)
        let date = Date(timeIntervalSince1970: dateNumber)
        let dateFormat = DateFormatter()
        dateFormat.dateStyle = .medium;
        dateFormat.timeStyle = .short;
        dateText += dateFormat.string(from: date)
        let feedTitle = feedTitle ?? ""
        let title = item.title ?? ""
        let url = item.url ?? ""
        var author = ""
        if let itemAuthor = item.author, itemAuthor.count > 0 {
            author = "By \(itemAuthor)"
        }

        let htmlTemplate = """
        <?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <meta name='viewport' content='width=device-width; initial-scale=1.0; minimum-scale=1.0; maximum-scale=2.0; user-scalable=yes' />
                <style>
                    \(self.updateCss())
                </style>
                <link rel="stylesheet" type="text/css" href="rss.css" />
                <title>
                    \(title)
                </title>
            </head>
            <body>
                <div class="header">
                    <div class="titleHeader">
                        <table width="100%" cellpadding="0" cellspacing="0" border="0">
                            <tr>
                                <td>
                                    <div class="feedTitle">
                                        \(feedTitle)
                                    </div>
                                </td>
                                <td>
                                    <div class="articleDate">
                                        \(dateText)
                                    </div>
                                </td>
                            </tr>
                        </table>
                    </div>
                    <div class="articleTitle">
                        <a class="articleTitleLink" href="\(url)">\(title)</a>
                    </div>
                    <div class="articleAuthor">
                        <p>
                            \(author)
                        </p>
                    </div>
                    <div class="content">
                        <p>
                            \(summary)
                        </p>
                    </div>
                    <div class="footer">
                        <p>
                            <a class="footerLink" href="\(url)"><br />View Full Article</a>
                        </p>
                    </div>
                </div>
            </body>
        </html>
        """
        print(htmlTemplate)
        do {
            if let url = htmlUrl {
                try htmlTemplate.write(to: url, atomically: true, encoding: .utf8)
                self.webView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
        } catch { }
    }

    func updateCss() -> String {
        let fontSize = UserDefaults.standard.integer(forKey: "FontSize")
        
        let screenSize = UIScreen.main.nativeBounds.size
        let margin = UserDefaults.standard.integer(forKey: "MarginPortrait")
        let currentWidth = Int((screenSize.width / UIScreen.main.scale) * CGFloat((Double(margin) / 100.0)))
        
        let marginLandscape = UserDefaults.standard.integer(forKey: "MarginLandscape")
        let currentWidthLandscape = (screenSize.height / UIScreen.main.scale) * CGFloat((Double(marginLandscape) / 100.0))
        
        let lineHeight = UserDefaults.standard.double(forKey: "LineHeight")
       
        return ":root {" +
                    "--bg-color: \(UIColor.ph_background.hexString);" +
                    "--text-color: \(UIColor.ph_text.hexString);" +
                    "--font-size: \(fontSize)px;" +
                    "--body-width-portrait: \(currentWidth)px;" +
                    "--body-width-landscape: \(currentWidthLandscape)px;" +
                    "--line-height: \(lineHeight)em;" +
                    "--link-color: \(UIColor.ph_link.hexString);" +
                    "--footer-link: \(UIColor.ph_popoverBackground.hexString);" +
                "}"
    }
    
    func fileUrlInDocumentsDirectory(_ fileName: String, fileExtension: String) -> URL {
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

extension UIColor {
    var hexString: String {
        let colorRef = cgColor.components
        let r = colorRef?[0] ?? 0
        let g = colorRef?[1] ?? 0
        let b = ((colorRef?.count ?? 0) > 2 ? colorRef?[2] : g) ?? 0
        let a = cgColor.alpha
        
        var color = String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255))
        )
        
        if a < 1 {
            color += String(format: "%02lX", lroundf(Float(a)))
        }
        
        return color
    }
}
