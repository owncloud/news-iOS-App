//
//  ArticleHelper.swift
//  CloudNews
//
//  Created by Peter Hedlund on 11/25/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import SwiftSoup

@objcMembers
class ArticleHelper: NSObject {
    
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

    static func readble(html: String, url: URL) -> String? {
//        char *article;
//        article = readable([html cStringUsingEncoding:NSUTF8StringEncoding],
//                           [url.absoluteString cStringUsingEncoding:NSUTF8StringEncoding],
//                           "UTF-8",
//                           READABLE_OPTIONS_DEFAULT);
//        if (article == NULL) {
//    //        html = @"<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>";
//    //        html = [html stringByAppendingString:self.item.body];
//            return nil;
//        } else {
//            html = [NSString stringWithCString:article encoding:NSUTF8StringEncoding];
//            html = [SummaryHelper fixRelativeUrl:html baseUrlString:[NSString stringWithFormat:@"%@://%@/%@", url.scheme, url.host, url.path]];
//            return html;
//        }
        return ""
    }

    static func writeAndLoadHtml(html: String, item: ItemProviderStruct, feedTitle: String? = nil) -> URL? {
        var result: URL? = nil
//        var summary = html

        var summary = ArticleHelper.replaceYTIframe(html: html)
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

        if let urlString = item.url,  let url = URL(string: urlString), let scheme = url.scheme, let host = url.host {
            let baseString = "\(scheme)://\(host)"
            if baseString.contains("youtu") {
                if summary.contains("iframe") {
                    summary = ArticleHelper.createYoutubeItem(html: summary, urlString: urlString)
                }
            }
            summary = ArticleHelper.fixRelativeUrl(html: summary, baseUrlString: baseString)
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
        
        return result
    }
    
    static func updateCss() -> String {
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

    static func fixRelativeUrl(html: String, baseUrlString: String) -> String {
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
    
    static func replaceYTIframe(html: String) -> String {
        guard let doc: Document = try? SwiftSoup.parse(html) else {
            return html
        }
        var result = html
        do {
            let iframes: Elements = try doc.select("iframe")
            for iframe in iframes {
                if let src = try iframe.getElementsByAttribute("src").first()?.attr("src") {
                    if src.contains("youtu"), let videoId = self.extractYoutubeVideoID(urlYoutube: src) {
                        let screenSize = UIScreen.main.nativeBounds.size
                        let margin = UserDefaults.standard.integer(forKey: "MarginPortrait")
                        let currentWidth = (screenSize.width / UIScreen.main.scale) * CGFloat(margin / 100);
                        let newheight = currentWidth * 0.5625;
                        let embed = String(format: "<embed id=\"yt\" src=\"http://www.youtube.com/embed/%@?playsinline=1\" type=\"text/html\" frameborder=\"0\" width=\"%ldpx\" height=\"%ldpdx\"></embed>", videoId, currentWidth, newheight)
                        result = result.replacingOccurrences(of: try iframe.html(), with: embed)
                    }
                    //                    if (src && [src rangeOfString:@"vimeo"].location != NSNotFound) {
                    //                        NSString *videoID = [SummaryHelper extractVimeoVideoID:src];
                    //                        if (videoID) {
                    //                            CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
                    //                            NSInteger margin =[[NSUserDefaults standardUserDefaults] integerForKey:@"MarginPortrait"];
                    //                            double currentWidth = (screenSize.width / [UIScreen mainScreen].scale) * ((double)margin / 100);
                    //                            double newheight = currentWidth * 0.5625;
                    //                            NSString *embed = [NSString stringWithFormat:@"<iframe id=\"vimeo\" src=\"http://player.vimeo.com/video/%@\" type=\"text/html\" frameborder=\"0\" width=\"%ldpx\" height=\"%ldpdx\"></iframe>", videoID, (long)currentWidth, (long)newheight];
                    //                            result = [result stringByReplacingOccurrencesOfString:[inputNode rawContents] withString:embed];
                    //                        }
                }
            }
        } catch { }

        return result
    }

    static func createYoutubeItem(html: String, urlString: String) -> String {
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

// based on http://stackoverflow.com/a/16841070/2036378
// + (NSString *)extractVimeoVideoID:(NSString *)urlVimeo {
//     NSString *regexString = @"([0-9]{2,11})"; // @"(https?://)?(www.)?(player.)?vimeo.com/([a-z]*/)*([0-9]{6,11})[?]?.*";
//     NSError *error = nil;
//     NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
//     NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:urlVimeo options:0 range:NSMakeRange(0, [urlVimeo length])];
//     if(!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
//         NSString *substringForFirstMatch = [urlVimeo substringWithRange:rangeOfFirstMatch];
//         return substringForFirstMatch;
//     }
//
//     return nil;
// }

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

extension String {
    
    // Vimeo VideoID from Link(url)
    
    var vimeoID: String? {
        let pattern = "([0-9]+)"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: count)
        
        guard let result = regex?.firstMatch(in: self, range: range) else {
            return nil
        }
        
        return (self as NSString).substring(with: result.range)
    }
    
}
