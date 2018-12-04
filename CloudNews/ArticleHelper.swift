//
//  ArticleHelper.swift
//  CloudNews
//
//  Created by Peter Hedlund on 11/25/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Cocoa
import SwiftSoup

class ArticleHelper {
    
    static var template: String? {
        if let source = Bundle.main.url(forResource: "rss", withExtension: "html") {
            return try? String(contentsOf: source, encoding: .utf8)
        }
        return nil
    }

    static var documentsFolderURL: URL? {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch { }
            return nil
    }

    static func writeAndLoadHtml(html: String, item: ItemProtocol, feedTitle: String? = nil) -> URL? {

//        let summary = SummaryHelper.replaceYTIframe(html)

        var result: URL? = nil
        var summary = html

        if let url = URL(string: item.url ?? "") {
            let baseString = "\(url.scheme ?? "")://\(url.host ?? "")"
//            if baseString.range(of: "youtu", options: .caseInsensitive) != nil {
//                if html.range(of: "iframe", options: .caseInsensitive) != nil {
//                    html = SummaryHelper.createYoutubeItem(item)
//                }
//            }
            summary = ArticleHelper.fixRelativeUrl(html: summary, baseUrlString: baseString)
        }
        
        if var htmlTemplate = ArticleHelper.template {
            var dateText = "";
            let dateNumber = TimeInterval(item.pubDate)
            let date = Date(timeIntervalSince1970: dateNumber)
            let dateFormat = DateFormatter()
            dateFormat.dateStyle = .medium;
            dateFormat.timeStyle = .short;
            dateText += dateFormat.string(from: date)
            
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleStyle$", with: self.updateCss())
            
            if let feedTitle = feedTitle {
                htmlTemplate = htmlTemplate.replacingOccurrences(of: "$FeedTitle$", with: feedTitle)
            }
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleDate$", with: dateText)
            
            if let title = item.title {
                htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleTitle$", with: title)
            }
//            if let url = item.url {
                htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleLink$", with: "")
//            }
            var author = ""
            if let itemAuthor = item.author, itemAuthor.count > 0 {
                author = "By \(itemAuthor)"
            }
            
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleAuthor$", with: author)
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleSummary$", with: summary ?? html)
            
            do {
                if let saveUrl = ArticleHelper.documentsFolderURL?
                    .appendingPathComponent("summary")
                    .appendingPathExtension("html") {
                    try htmlTemplate.write(to: saveUrl, atomically: true, encoding: .utf8)
                    result = saveUrl
                }
            } catch {
                //
            }
        }
        return result
    }
    
    static func updateCss() -> String {
        let fontSize = 12 // UserDefaults.standard.integer(forKey: "FontSize")
        
//        let screenSize = UIScreen.main.nativeBounds.size
//        let margin = UserDefaults.standard.integer(forKey: "MarginPortrait")
        let currentWidth = 90 // Int((screenSize.width / UIScreen.main.scale) * CGFloat((Double(margin) / 100.0)))
        
//        let marginLandscape = UserDefaults.standard.integer(forKey: "MarginLandscape")
//        let currentWidthLandscape = (screenSize.height / UIScreen.main.scale) * CGFloat((Double(marginLandscape) / 100.0))
        
        let lineHeight = 1.5 // UserDefaults.standard.double(forKey: "LineHeight")
        
        return ":root {" +
            "--bg-color: #FFFFFF);" +
            "--text-color: #000000);" +
            "--font-size: \(fontSize)pt;" +
            "--body-width-portrait: \(currentWidth)%;" +
            "--body-width-landscape: \(currentWidth)%;" +
            "--line-height: \(lineHeight)em;" +
            "--link-color: #1F31B9;" +
            "--footer-link: #F0F2F0;" +
        "}"
    }

    static func fileUrlInDocumentsDirectory(_ fileName: String, fileExtension: String) -> URL
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

    private static func fixRelativeUrl(html: String, baseUrlString: String) -> String {
        guard let doc: Document = try? SwiftSoup.parse(html), let baseURL = URL(string: baseUrlString) else {
            return html
        }
        var result = html
        do {
            let srcs: Elements = try doc.select("img[src]")
            let srcsStringArray: [String?] = srcs.array().map { try? $0.attr("src").description }
            for src in srcsStringArray {
                if let src = src, let newSrc = URL(string: src, relativeTo: baseURL) {
                    let newSrcString = newSrc.absoluteString
                    result = result.replacingOccurrences(of: src, with: newSrcString)
                }
            }

            let hrefs: Elements = try doc.select("a[href]")
            let hrefsStringArray: [String?] = hrefs.array().map { try? $0.attr("href").description }
            for href in hrefsStringArray {
                if let href = href, let newHref = URL(string: href, relativeTo: baseURL) {
                    result = result.replacingOccurrences(of: href, with: newHref.absoluteString)
                }
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch {
            print("error")
        }
        return result
    }

}
