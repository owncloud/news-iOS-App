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

        if let urlString = item.url,  let url = URL(string: urlString), let scheme = url.scheme, let host = url.host {
            let baseString = "\(scheme)://\(host)"
            if baseString.contains("youtu") {
                if summary.contains("iframe") {
                    summary = ArticleHelper.createYoutubeItem(html: summary, urlString: urlString)
                }
            }
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
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleLink$", with: "")
            var author = ""
            if let itemAuthor = item.author, itemAuthor.count > 0 {
                author = "By \(itemAuthor)"
            }
            
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleAuthor$", with: author)
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "$ArticleSummary$", with: summary)
            
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

    private static func createYoutubeItem(html: String, urlString: String) -> String {
        guard let doc: Document = try? SwiftSoup.parse(html) else {
            return html
        }
        var result = html
        do {
            let iframes: Elements = try doc.select("iframe")
            for iframe in iframes {
                if let videoId = ArticleHelper.extractYoutubeVideoID(urlYoutube: urlString) {
                    let width = 700
                    let height = 700 * 0.5625
                    let embed = "<embed id=\"yt\" src=\"http://www.youtube.com/embed/\(videoId)?playsinline=1\" type=\"text/html\" frameborder=\"0\" width=\"\(width)px\" height=\"\(height)px\"></embed>"
                    result = try result.replacingOccurrences(of: iframe.outerHtml(), with: embed)
                }
            }
        } catch { }
        
        return result
    }
    
    //based on https://gist.github.com/rais38/4683817
    /**
     @see https://devforums.apple.com/message/705665#705665
     extractYoutubeVideoID: works for the following URL formats:
     www.youtube.com/v/VIDEOID
     www.youtube.com?v=VIDEOID
     www.youtube.com/watch?v=WHsHKzYOV2E&feature=youtu.be
     www.youtube.com/watch?v=WHsHKzYOV2E
     youtu.be/KFPtWedl7wg_U923
     www.youtube.com/watch?feature=player_detailpage&v=WHsHKzYOV2E#t=31s
     youtube.googleapis.com/v/WHsHKzYOV2E
     www.youtube.com/embed/VIDEOID
     */
    
    private static func extractYoutubeVideoID(urlYoutube: String) -> String? {
        let regexString = "(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)|(?<=embed/)([-a-zA-Z0-9_]+)"
        do {
            let regex = try NSRegularExpression(pattern: regexString, options: [.caseInsensitive])
            let firstMatchingRange = regex.rangeOfFirstMatch(in: urlYoutube, options: [], range: NSRange(location: 0, length: urlYoutube.count))
            let startIndex = String.Index(utf16Offset: firstMatchingRange.lowerBound, in: urlYoutube)
            let endIndex = String.Index(utf16Offset: firstMatchingRange.upperBound, in: urlYoutube)
            return String(urlYoutube[startIndex..<endIndex])
        } catch { }
        return nil;
    }

}
