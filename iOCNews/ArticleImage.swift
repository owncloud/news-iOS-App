//
//  ArticleImage.swift
//  iOCNews
//
//  Created by Peter Hedlund on 1/8/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import Foundation
import SwiftSoup

@objcMembers
class ArticleImage: NSObject {
    
    @objc
    static func imageURL(summary: String) -> String? {
        guard let doc: Document = try? SwiftSoup.parse(summary) else {
            return nil
        } // parse html
        do {
            let srcs: Elements = try doc.select("img[src]")
            let srcsStringArray: [String?] = srcs.array().map { try? $0.attr("src").description }
            if let firstString = srcsStringArray.first, let urlString = firstString /*, let url = URL(string: urlString)*/ {
                return urlString
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch {
            print("error")

        }
        return nil
    }

}

